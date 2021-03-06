# mkpdx

X680x0 の音源ドライバとして知られている mxdrv 用の pcm データファイル形式である pdx ファイルを作成するための perl スクリプトです。X680x0 以外での環境下でも、エミュレータに頼らずに曲データの開発ができることを目指していますが、今のところ pdx ファイルを作るスクリプトしかできていません。

## 仕様

以下の仕様を目指して作られていますが、その通りになっていないところもあるかも知れません。予めご了承ください。

- 64KB 以上の pcm ファイルに対応しています。
- バンクモードに対応しています。
- -l オプションで、リニア pcm ファイルに対応しています(pcm データ先頭アドレスの偶数境界調整を行います)。
- 同じ pcm ファイルを複数ノートで指定した場合でも、pdx ファイルに入る実体としての pcm ファイルは概ね 1 つだけです(厳密な判定はしていません)。
- pdl ファイルの書式は概ね tpdxm / pdmk 等と同じですが、音程表記による pcm ファイルの定義はできません。また、ポインタコピーの機能もありません(基本的にはデフォルトでポインタコピーした状態と同じになります)。
- エラーチェックは場所にも依りますが、甘め or していません。あなたの大事なファイルやシステムが破壊されないとも限らないので、プログラムの実行に当たってはバックアップを取るなどして、事故のないようにご注意下さい。本プログラムは無保証です。
- バグその他の理由で、tpdxm / pdmk 等と同じ pdx ファイルが生成されないかも知れません。
- 上記以外の仕様はソース(Perl スクリプト)を読むとある程度分かるかも知れませんが、ソースがひどくて読みにくいのも仕様(の一部)です。

## 必要な環境

- perl が動く環境が必要です。作者は cygwin64 上での perl 5.22 で動作確認をしています。

## 使用方法

    $ perl mkpdx.pl [options..] <pdl-file[.pdl/.PDL]>

- pdl ファイルの内容に従って pcm ファイルが読み込まれ、pdx ファイルが生成されます。
- 生成される pdx ファイルのファイル名は、pdl ファイルの拡張子を ".pdx" に置き換えたものです。例えば、"foo.pdl" から "foo.pdx" が生成されます。
- 使用する pcm ファイルは予めカレントディレクトリに置いておく必要があります。そうでない場合は、pdl ファイル内での pcm ファイルをパス名付きで指定してください。
- pdl ファイルの指定で拡張子を省略すると、".pdl" / ".PDL"
が補完されます。
- pdl ファイルを指定せずに起動すると、Usage が表示されます。

### オプション

-  -l : リニア pcm ファイルの配置アドレス補正を有効にします
-  -d : デバッグモード

## 謝辞
pdl ファイルの書式については、tpdxm や pdmk のドキュメントが参考になりました。作者の皆様に感謝いたします。

## 作者

  [ArctanX](https://github.com/arctanx93)

## ライセンス

Copyright (c) 2017-2018, ArctanX  
Perl / Artistic License
