# mkpdx

mkpdx (mkpdx.pl) is the perl script which makes a pdx-file from pcm-file(s) as described in a pdl-file for MXDRV, known as sound driver for Sharp X680x0.

## Features

- Support pcm-files over 64KB
- Support multi-note-bank
- Support linear pcm-files alignment with -l option so that linear pcm-files are placed on an even numbered address
- Roughly compatibile with the syntax of pdl-file for tpdxm / pdmk
- Perform limited error-checks (Please back up your important files in advance, just in case)

## Requirement

- Perl
  - The author tested the script on the perl 5.22 / cygwin64 (Windows7).

## Usage

    $ perl [options..] mkpdx.pl <pdl-file>

- A pdx-file will be created according to the pdl-file.
- For example, "foo.pdx" will be created from "foo.pdl".
- The pcm-files should be placed on the current directory in advance, or please specify the pcm-files with pathname(s) in the pdl-file.
- The suffix, ".pdl" / ".PDL", will be complemented for no-suffix pdl-files.
- When no pdl-file is specified, usage will show up.

### Options

-  -l : Enable linear PCM file alignment support
-  -d : Debug mode

## Author

  [ArctanX](https://github.com/arctanx93)

## License

Copyright (c) 2017-2018, ArctanX  
Perl / Artistic License
