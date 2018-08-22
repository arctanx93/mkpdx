#!/usr/local/bin/perl -w
use strict;
use warnings;

use Getopt::Std;

use constant FAILED => 1;
use constant PDX_SUFFIX_UC => ".PDX";
use constant PDL_SUFFIX_UC => ".PDL";
use constant PCM_SUFFIX_UC => ".PCM";
use constant PDX_SUFFIX_LC => ".pdx";
use constant PDL_SUFFIX_LC => ".pdl";
use constant PCM_SUFFIX_LC => ".pcm";
use constant PDX_HEADER_SIZE => 8;  # bytes for each note
use constant MAX_PDX_BANK => 85;
use constant MAX_NOTE_MODE_0 => 8255;
use constant MAX_NOTE_MODE_1 => 95;
use constant BUFFER_SIZE => 4096;

use constant VERSION => "0.9.2";
use constant YEAR    => "2017-2018";

use constant CANNOT_OPEN_MSG => "Cannot open";

my %opts = ();
getopts("dl", \%opts);

sub debug_print
{
    if ($opts{'d'}) {
	print @_;
    }
}

sub usage
{
    print STDERR "PDX file maker for MXDRV Ver.".VERSION." Copyright (c) ".YEAR." ArctanX (arctanx\@hauN.org)\n";
    print STDERR "Usage: perl mkpdx.pl [options..] <pdl-file[".PDL_SUFFIX_LC."/".PDL_SUFFIX_UC."]>\n";
    print STDERR "Options:\n";
    print STDERR "    -l    Enable linear PCM file alignment support\n";
    print STDERR "    -d    Debug mode\n";
}

sub create_pdx
{
    my ($pdlfilename, $pdxfilename) = @_;
    my $pdx_bank = 0;
    my $ex_pdx_mode = 0;     # default
    my $note_number = 0;
    my $return_value = 0;
    my @max_note_number = (MAX_NOTE_MODE_0, MAX_NOTE_MODE_1);
    my @pcmfilename = ();
    my %pcmdata_length = ();
    my @pcmfilelist = ();
    my $max_note_number_used = 0;

    print "Building $pdxfilename from $pdlfilename\n";

    open my $fh_pdl, '<', $pdlfilename or die CANNOT_OPEN_MSG." '$pdlfilename': $!";
    while (<$fh_pdl>) {
	debug_print "< $_";
	s/\x0d\x0a$|\x0d$|\x0a$//go;
	if (/^#ex-pdx\s/i) {           # ex-pdx
	    $ex_pdx_mode = (split)[1];
	    debug_print "# Found ex-pdx header. mode = $ex_pdx_mode\n";
	    if ($ex_pdx_mode == 1) {
		$pdx_bank = 0;
	    }
	    elsif ($ex_pdx_mode != 0) {
		print STDERR "#ex-pdx should be 0 or 1: \'$ex_pdx_mode\' specified.\n";
		$return_value = FAILED;
	    }
	}
	elsif (/^#d/i) {               # direct
	    $ex_pdx_mode = 0;
	    debug_print "# Move to direct mode\n";
	}
	elsif (/^#b/i) {               # bank
	    $ex_pdx_mode = 1;
	    $pdx_bank = 0;
	    debug_print "# Move to bank mode\n";
	}
	elsif (/^@/) {
	    next unless ($ex_pdx_mode == 1);
	    s/^@//go;
	    $pdx_bank = sprintf("%d", $_);
	    if (($pdx_bank < 0) || ($pdx_bank > MAX_PDX_BANK)) {
		print STDERR "Bank value should be from 0 to ".MAX_PDX_BANK.": \'$pdx_bank\' specified.\n";
		$return_value = FAILED;
	    }
	    debug_print "# Found bank line. bank = $pdx_bank\n";
	}
	elsif (/^\d/) {
	    s/\s+[\*#].*$//go;
	    my ($tmp_note_number, $tmp_pcmfilename) = split(/\s*[=\s]\s*/);
	    $tmp_note_number = sprintf("%d", $tmp_note_number);
	    
	    if (($tmp_note_number < 0) || ($tmp_note_number > $max_note_number[$ex_pdx_mode])) {
		print STDERR "Note number should be from 0 to $max_note_number[$ex_pdx_mode]: \'$tmp_note_number\' specified.\n";
		$return_value = FAILED;
	    }
	    else {
		if ($ex_pdx_mode == 0) {
		    $note_number = $tmp_note_number;
		}
		elsif ($ex_pdx_mode == 1) {
		    $note_number = $pdx_bank * (MAX_NOTE_MODE_1 + 1) + $tmp_note_number;
		}
		else {
		    print STDERR "note number: #ex-pdx should be 0 or 1: \'$ex_pdx_mode\' specified.\n";
		    $return_value = FAILED;
		    next;
		}
		
		if ($max_note_number_used < $note_number) {
		    $max_note_number_used = $note_number;     # update $max_note_number_used
		    debug_print "max_note_number_used -> $max_note_number_used\n";
		}
		
		if ( ! -f $tmp_pcmfilename) {
		    if ( -f $tmp_pcmfilename.PCM_SUFFIX_LC) {
			$tmp_pcmfilename .= PCM_SUFFIX_LC;
			debug_print "Suffix ".PCM_SUFFIX_LC." complemented.\n";
		    }
		    elsif ( -f $tmp_pcmfilename.PCM_SUFFIX_UC) {
			$tmp_pcmfilename .= PCM_SUFFIX_UC;
			debug_print "Suffix ".PCM_SUFFIX_UC." complemented.\n";
		    }
		    else {
			print STDERR CANNOT_OPEN_MSG." '$tmp_pcmfilename': $!.\n";
			$return_value = FAILED;
			next;
		    }
		}
		debug_print "Note:$note_number($tmp_note_number\@$pdx_bank) -> $tmp_pcmfilename\n";
		$pcmfilename[$note_number] = $tmp_pcmfilename;
		if (! exists($pcmdata_length{$pcmfilename[$note_number]})) {
		    $pcmdata_length{$pcmfilename[$note_number]} = -s $pcmfilename[$note_number];
		    debug_print "pcmdata_length{$pcmfilename[$note_number]} -> $pcmdata_length{$pcmfilename[$note_number]}\n";
		}
		else {
		    debug_print "$pcmfilename[$note_number]: already registered.\n";
		}
	    }
	}
    }
    close $fh_pdl;
    
    if ($return_value != FAILED) {
	my $note_max = (int($max_note_number_used / (MAX_NOTE_MODE_1 + 1)) + 1) * (MAX_NOTE_MODE_1 + 1);
	my $pcmdata_ptr_tail = $note_max * PDX_HEADER_SIZE;
	my %pcmdata_ptr = ();
	my @pcmfilelist = ();

	open my $fh_pdx, '>', $pdxfilename or die CANNOT_OPEN_MSG." '$pdxfilename': $!";
	binmode $fh_pdx;

	# Write header
	for (my $note_number = 0; $note_number < $note_max; $note_number++) {
	    if (defined $pcmfilename[$note_number]) {
		if (! exists($pcmdata_ptr{$pcmfilename[$note_number]})) {
		    if ($opts{'l'} && ($pcmdata_ptr_tail % 2 != 0)) {
			$pcmdata_ptr_tail++;
			debug_print "Linear PCM alignment: $pcmfilename[$note_number]\n";
		    }
		    $pcmdata_ptr{$pcmfilename[$note_number]} = $pcmdata_ptr_tail;
		    $pcmdata_ptr_tail += $pcmdata_length{$pcmfilename[$note_number]};
		    push(@pcmfilelist, $pcmfilename[$note_number]);
		}
		print $fh_pdx pack('N', $pcmdata_ptr{$pcmfilename[$note_number]});
		print $fh_pdx pack('N', $pcmdata_length{$pcmfilename[$note_number]});
	    }
	    else {
		print $fh_pdx pack('N', 0);
		print $fh_pdx pack('N', 0);
	    }
	}
	# Write PCM data
	foreach my $pcmfile (@pcmfilelist) {
	    open my $fh_pcm, '<', $pcmfile or die CANNOT_OPEN_MSG." '$pcmfile': $!";
	    while (read($fh_pcm, my $buffer, BUFFER_SIZE)) {
		print $fh_pdx $buffer;
	    }
	    if ($opts{'l'} && ($pcmdata_length{$pcmfile} % 2 != 0)) {
		print $fh_pdx pack('C', 0);
	    }
	    close $fh_pcm;
	}
	close $fh_pdx;
    }
    else {
	print STDERR "Some error(s) occurred. No pdxfile was created.\n";
    }
    
    return $return_value;
}

#main
{
    if ($#ARGV == -1) {
	usage;
	exit FAILED;
    }

    my ($pdlfilename, $pdxfilename) = ("", "");

    $pdlfilename = shift;

    if ( ! -f $pdlfilename) {
	if ( -f $pdlfilename.PDL_SUFFIX_LC) {
	    $pdlfilename .= PDL_SUFFIX_LC;
	    debug_print "Suffix ".PDL_SUFFIX_LC." complemented.\n";
	}
	elsif ( -f $pdlfilename.PDL_SUFFIX_UC) {
	    $pdlfilename .= PDL_SUFFIX_UC;
	    debug_print "Suffix ".PDL_SUFFIX_UC." complemented.\n";
	}
	else {
	    print STDERR "$pdlfilename not found.\n";
	    exit FAILED;
	}
    }
    if ($pdlfilename =~ /${\(PDL_SUFFIX_LC)}$/) {
	($pdxfilename = $pdlfilename) =~ s/${\(PDL_SUFFIX_LC)}$/${\(PDX_SUFFIX_LC)}/go;
    }
    elsif ($pdlfilename =~ /${\(PDL_SUFFIX_UC)}$/) {
	($pdxfilename = $pdlfilename) =~ s/${\(PDL_SUFFIX_UC)}$/${\(PDX_SUFFIX_UC)}/go;
    }
    else {
	($pdxfilename = $pdlfilename) .= PDX_SUFFIX_LC;
    }
    
    if ( -f $pdxfilename) {
	print STDERR "'$pdxfilename' already exists. Do you want to overwrite it? [y/other] ";
	my $answer = <STDIN>;
	$answer =~ s/\x0d\x0a$|\x0d$|\x0a$//go;
	if ($answer !~ /y/i) {
	    print STDERR "Aborted.\n";
	    exit FAILED;
	}
    }

    exit create_pdx($pdlfilename, $pdxfilename);

}

