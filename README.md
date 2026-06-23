# <span id="top">Playing with Common Lisp on Windows</span>

<table style="font-family:Helvetica,Arial;line-height:1.6;">
  <tr>
  <td style="border:0;padding:0 10px 0 0;min-width:120px;"><a href="https://lisp-lang.org/" rel="external"><img src="docs/images/Lisp_logo.svg" width="100" alt="Common Lisp"/></a></td>
  <td style="border:0;padding:0;vertical-align:text-top;">This repository gathers <a href="https://lisp-lang.org/" rel="external">Common Lisp</a> (CL) code examples coming from various websites and books.<br/>
  It also includes several build scripts (<a href="https://tldp.org/LDP/Bash-Beginners-Guide/html/sect_02_01.html" rel="external">Bash scripts</a>, <a href="https://en.wikibooks.org/wiki/Windows_Batch_Scripting" rel="external">batch files</a>, <a href="https://makefiletutorial.com/" rel="external">Make scripts</a>, <a href="https://learn.microsoft.com/en-us/powershell/scripting/overview" rel="external" title="https://learn.microsoft.com/en-us/powershell/scripting/overview">PowerShell scripts</a>) for experimenting with <a href="https://lisp-lang.org/" rel="external">Common Lisp</a> on a Windows machine.
  </td>
  </tr>
</table>

[Ada][ada_examples], [Akka][akka_examples], [C++][cpp_examples], [COBOL][cobol_examples], [Component&nbsp;Pascal][component_pascal_examples], [Dafny][dafny_examples], [Dart][dart_examples], [Deno][deno_examples], [Docker][docker_examples], [Erlang][erlang_examples], [Flix][flix_examples], [Go][golang_examples], [GraalVM][graalvm_examples], [Haskell][haskell_examples], [Kafka][kafka_examples], [Kotlin][kotlin_examples], [LLVM][llvm_examples], [Modula-2][m2_examples], [PowerShell][powershell_examples], [Rust][rust_examples], [Scala 3][scala3_examples], [Spark][spark_examples], [Spring][spring_examples], [Standard&nbsp;ML][sml_examples], [TruffleSqueak][trufflesqueak_examples], [WiX&nbsp;Toolset][wix_examples] and [Zig][zig_examples] are other topics we are continuously monitoring.

## <span id="proj_deps">Project dependencies</span>


This project depends on the following external software for the **Microsoft Windows** platform:

- [Git 2.54][git_downloads] ([*release notes*][git_relnotes])
- [SBCL 2.6][sbcl_downloads]  ([*release notes*][sbcl_relnotes]) (fork of [CMUCL])

Optionally one may also install the following software:

- [Clozure CL 1.13][clozure_downloads] ([*change log*][clozure_changelog])
- [ConEmu 2023][conemu_downloads] ([*release notes*][conemu_relnotes])
- [MSYS2 2024][msys2_downloads] <sup id="anchor_01">[1](#footnote_01)</sup> ([*changelog*][msys2_changelog])
- [Visual Studio Code 1.125][vscode_downloads] ([*release notes*][vscode_relnotes])

<!--
- [GNU CLISP][clisp_downloads] ([*release notes*][clisp_relnotes])
-->

> **:mag_right:** [Git for Windows][git_win] provides a BASH emulation used to run [**`git`**][git_docs] from the command line (as well as over 250 Unix commands like [**`awk`**][man1_awk], [**`diff`**][man1_diff], [**`file`**][man1_file], [**`grep`**][man1_grep], [**`more`**][man1_more], [**`mv`**][man1_mv], [**`rmdir`**][man1_rmdir], [**`sed`**][man1_sed] and [**`wc`**][man1_wc]).

For instance our development environment looks as follows (*June 2026*) <sup id="anchor_02"><a href="#footnote_02">2</a></sup>:

<pre style="font-size:80%;">
C:\opt\ccl\                      <i>( 75 MB)</i>
C:\opt\ConEmu\                   <i>( 26 MB)</i>
C:\opt\Git\                      <i>(391 MB)</i>
C:\opt\sbcl\                     <i>( 51 MB)</i>
C:\opt\VSCode\                   <i>(381 MB)</i>
</pre>

> **&#9755;** ***Installation policy***<br/>
> When possible we install software from a [Zip archive][zip_archive] rather than via a Windows installer. In our case we defined **`C:\opt\`** as the installation directory for optional software tools (*in reference to* the [**`/opt/`**][linux_opt] directory on Unix).

## <span id="structure">Directory structure</span> [**&#x25B4;**](#top)

This project is organized as follows:
<pre style="font-size:80%;">
bin\
docs\
examples\{<a href="./examples/README.md">README.md</a>, <a href="./eamples/lists/">lists</a>, ..}
README.md
<a href="RESOURCES.md">RESOURCES.md</a>
<a href="setenv.bat">setenv.bat</a>
</pre>

where

- directory [**`bin\`**](bin/) contains utility batch scripts.
- directory [**`docs\`**](docs/) contains [Common Lisp][common_lisp] related papers/articles.
- directory [**`examples\`**](./examples/README.md#top) contains [Common Lisp][common_lisp] code examples.
- file **`README.md`** is the [Markdown][github_markdown] document for this page.
- file [**`RESOURCES.md`**](RESOURCES.md#top) gathers [Common Lisp][common_lisp] related informations.
- file [**`setenv.bat`**](setenv.bat) is the batch script for setting up our environment.

We also define a virtual drive &ndash; e.g. drive **`N:`** &ndash; in our working environment in order to reduce/hide the real path of our project directory (see article ["Windows command prompt limitation"][windows_limitation] from Microsoft Support).

> **:mag_right:** We use the Windows external command [**`subst`**][windows_subst] to create virtual drives; for instance:
>
> <pre style="font-size:80%;">
> <b>&gt; <a href="https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/subst">subst</a> N: <a href="https://en.wikipedia.org/wiki/Environment_variable#Default_values">%USERPROFILE%</a>\workspace-perso\cl-examples</b>
> </pre>

In the next section we give a brief description of the batch files present in this project.

## <span id="batch_commands">Batch commands</span> [**&#x25B4;**](#top)

We distinguish different sets of batch commands:

1. [**`setenv.bat`**](setenv.bat) - This batch command makes the external tools such as [**`code.exe`**][vscode_cli] and [**`git.exe`**][git_cli] directly available from the command prompt (we rely on the environment variables `SBCL_HOME` to invoke the command line tool [**`sbcl.exe`**][sbcl_cli]).

    <pre style="font-size:80%;">
    <b>&gt; <a href="setenv.bat">setenv</a> help</b>
    Usage: setenv { &lt;option&gt; | &lt;subcommand&gt; }
    &nbsp;
      Options:
        -debug      print commands executed by this script
        -verbose    print progress messages
    &nbsp;
      Subcommands:
        help        print this help message
    &nbsp;
    <b>&gt; <a href="https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/where_1" rel="external" title="https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/where_1" rel="external" title="https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/where_1">where</a> code git</b>
    C:\opt\VSCode\Code.exe
    C:\opt\Git\bin\git.exe</pre>


<!--========================================================-->

## <span id="footnotes">Footnotes</span> [**&#x25B4;**](#top)

<span id="footnote_01">[1]</span> ***SBCL in M2SYS2*** [↩](#anchor_01)

<dl><dd>
The <a href="https://packages.msys2.org/packages/" rel="external">MSYS64</a> software distribution also includes the <a href="https://packages.msys2.org/packages/mingw-w64-ucrt-x86_64-sbcl/" rel="external">SBCL package</a> whose version may differ from the <a href="https://sbcl.org/platform-table.html" rel="external" title="https://sbcl.org/platform-table.html">SBCL distribution</a> :
<pre style="font-size:80%;max-width:484px;">
<b>&gt; <a href="https://pacman.archlinux.page/pacman.8.html" rel="external" title="https://pacman.archlinux.page/pacman.8.html">pacman</a> -Syu mingw-w64-ucrt-x86_64-sbcl</b>
:: Synchronizing package databases...
[...]
:: Starting core system upgrade...
 there is nothing to do
:: Starting full system upgrade...
[...]
Packages (28) binutils-2.46.1-1  bsdtar-3.8.7-2  file-5.48-1  gcc-15.3.0-1
              [...]
              wget-1.25.0-2  mingw-w64-ucrt-x86_64-sbcl-2.6.5-1

Total Download Size:   113.41 MiB
Total Installed Size:  807.71 MiB
Net Upgrade Size:       59.68 MiB

:: Proceed with installation? [Y/n]
:: Retrieving packages...
[...]
[##################################] 100% ( 5/28) installing mingw-w64-ucrt-x86_64-sbcl                   
(1/1) Updating the info directory file...
&nbsp;
<b>&gt; <a href="https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/where" rel="external" title="https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/where">where</a> /r c:\opt\msys64 sbcl.exe</b>
c:\opt\msys64\ucrt64\bin\sbcl.exe
&nbsp;
<b>&gt; c:\opt\msys64\ucrt64\bin\sbcl.exe --version</b>
SBCL 2.6.5-85913ede1
</pre>
</dd></dl>

<span id="footnote_02">[2]</span> ***Downloads*** [↩](#anchor_02)

<dl><dd>
In our case we downloaded the following installation files (see <a href="#proj_deps">section 1</a>):
</dd>
<dd>
<pre style="font-size:80%;">
<a href="https://github.com/Clozure/ccl/releases" rel="external" title="https://github.com/Clozure/ccl/releases">ccl-1.13-windowsx86.zip</a>               <i>( 20 MB)</i>
<a href="https://repo.msys2.org/distrib/x86_64/">msys2-x86_64-20260611.exe</a>             <i>( 90 MB)</i>
<a href="https://git-scm.com/download/win" rel="external" title="https://git-scm.com/download/win">PortableGit-2.54.0-64-bit.7z.exe</a>      <i>( 42 MB)</i>
<a href="https://sbcl.org/platform-table.html" rel="external" title="https://sbcl.org/platform-table.html">sbcl-2.6.5-x86-64-windows-binary.msi</a>  <i>( 16 MB)</i>
<a href="https://code.visualstudio.com/Download#" rel="external">VSCode-win32-x64-1.125.1.zip</a>          <i>(131 MB)</i>
</pre>
</dd></dl>

<!--
<a href="https://sourceforge.net/projects/clisp/files/clisp/" rel="external" title="https://sourceforge.net/projects/clisp/files/clisp/">clisp-2.49-win32-mingw-big.zip</a>        <i>(  9 MB)</i>
-->

***

*[mics](https://lampwww.epfl.ch/~michelou/)/June 2026* [**&#9650;**](#top)
<span id="bottom">&nbsp;</span>

<!-- link refs -->

[ada_examples]: https://github.com/michelou/ada-examples#top
[akka_examples]: https://github.com/michelou/akka-examples#top
[clisp_downloads]: https://sourceforge.net/projects/clisp/files/clisp/ "https://sourceforge.net/projects/clisp/files/clisp/"
[clisp_relnotes]: https://ftp.gnu.org/pub/gnu/clisp/NEWS "https://ftp.gnu.org/pub/gnu/clisp/NEWS"
[clozure_changelog]: https://github.com/Clozure/ccl/compare/v1.12.2...v1.13 "https://github.com/Clozure/ccl/compare/v1.12.2...v1.13"
[clozure_downloads]: https://github.com/Clozure/ccl/releases "https://github.com/Clozure/ccl/releases"
[cmucl]: https://cmucl.org/ "https://cmucl.org/"
[cobol_examples]: https://github.com/michelou/cobol-examples#top
[common_lisp]: https://lisp-lang.org/ "https://lisp-lang.org/"
[component_pascal_examples]: https://github.com/michelou/compondent-pascal-examples#top
[conemu_downloads]: https://github.com/Maximus5/ConEmu/releases "https://github.com/Maximus5/ConEmu/releases"
[conemu_relnotes]: https://conemu.github.io/blog/2023/07/24/Build-230724.html "https://conemu.github.io/blog/2023/07/24/Build-230724.html"
[cpp_examples]: https://github.com/michelou/cpp-examples#top
[dafny_examples]: https://github.com/michelou/dafny-examples#top
[dart_examples]: https://github.com/michelou/dart-examples#top
[deno_examples]: https://github.com/michelou/deno-examples#top
[docker_examples]: https://github.com/michelou/docker-examples#top
[erlang_examples]: https://github.com/michelou/erlang-examples#top
[flix_examples]: https://github.com/michelou/flix-examples#top
[git_cli]: https://git-scm.com/docs/git "https://git-scm.com/docs/git"
[git_docs]: https://git-scm.com/docs/git "https://git-scm.com/docs/git"
[git_downloads]: https://git-scm.com/download/win "https://git-scm.com/download/win"
[git_relnotes]: https://raw.githubusercontent.com/git/git/master/Documentation/RelNotes/2.54.0.txt
[git_win]: https://git-scm.com/download/win "https://git-scm.com/download/win"
[github_markdown]: https://github.github.com/gfm/ "https://github.github.com/gfm/"
[golang_examples]: https://github.com/michelou/golang-examples#top
[graalvm_examples]: https://github.com/michelou/graalvm-examples#top
[haskell_examples]: https://github.com/michelou/haskell-examples#top
[kafka_examples]: https://github.com/michelou/kafka-examples#top
[kotlin_examples]: https://github.com/michelou/kotlin-examples#top
[linux_opt]: https://tldp.org/LDP/Linux-Filesystem-Hierarchy/html/opt.html "https://tldp.org/LDP/Linux-Filesystem-Hierarchy/html/opt.html"
[llvm_examples]: https://github.com/michelou/llvm-examples#top
[m2_examples]: https://github.com/michelou/m2-examples#top
[man1_awk]: https://www.linux.org/docs/man1/awk.html "https://www.linux.org/docs/man1/awk.html"
[man1_diff]: https://www.linux.org/docs/man1/diff.html "https://www.linux.org/docs/man1/diff.html"
[man1_file]: https://www.linux.org/docs/man1/file.html "https://www.linux.org/docs/man1/file.html"
[man1_grep]: https://www.linux.org/docs/man1/grep.html
[man1_more]: https://www.linux.org/docs/man1/more.html
[man1_mv]: https://www.linux.org/docs/man1/mv.html "https://www.linux.org/docs/man1/mv.html"
[man1_rmdir]: https://www.linux.org/docs/man1/rmdir.html "https://www.linux.org/docs/man1/rmdir.html"
[man1_sed]: https://www.linux.org/docs/man1/sed.html "https://www.linux.org/docs/man1/sed.html"
[man1_wc]: https://www.linux.org/docs/man1/wc.html "https://www.linux.org/docs/man1/wc.html"
[msys2_changelog]: https://github.com/msys2/setup-msys2/blob/main/CHANGELOG.md
[msys2_downloads]: http://repo.msys2.org/distrib/x86_64/ "http://repo.msys2.org/distrib/x86_64/"
[powershell_examples]: https://github.com/michelou/powershell-examples#top
[rust_examples]: https://github.com/michelou/rust-examples#top
[sbcl_cli]: https://www.sbcl.org/manual/#Command-Line-Options "https://www.sbcl.org/manual/#Command-Line-Options"
[sbcl_downloads]: https://sbcl.org/platform-table.html "https://sbcl.org/platform-table.html"
[sbcl_relnotes]: https://sbcl.org/news.html#2.6.5 "https://sbcl.org/news.html#2.6.5"
[scala3_examples]: https://github.com/michelou/dotty-examples#top
[sml_examples]: https://github.com/michelou/sml-examples#top
[spark_examples]: https://github.com/michelou/spark-examples#top
[spring_examples]: https://github.com/michelou/spring-examples#top
[trufflesqueak_examples]: https://github.com/michelou/trufflesqueak-examples#top
[vscode_cli]: https://code.visualstudio.com/docs/configure/command-line "https://code.visualstudio.com/docs/configure/command-line"
[vscode_downloads]: https://code.visualstudio.com/Download "https://code.visualstudio.com/Download"
[vscode_relnotes]: https://code.visualstudio.com/updates "https://code.visualstudio.com/updates"
[windows_limitation]: https://support.microsoft.com/en-gb/help/830473/command-prompt-cmd-exe-command-line-string-limitation "https://support.microsoft.com/en-gb/help/830473/command-prompt-cmd-exe-command-line-string-limitation"
[windows_subst]: https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/subst "https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/subst"
[wix_examples]: https://github.com/michelou/wix-examples#top
[zig_examples]: https://github.com/michelou/zig-examples#top
[zip_archive]: https://www.howtogeek.com/178146/htg-explains-everything-you-need-to-know-about-zipped-files/ "https://www.howtogeek.com/178146/htg-explains-everything-you-need-to-know-about-zipped-files/"
