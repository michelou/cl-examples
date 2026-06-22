# <span id="top">Common Lisp Examples</span> <span style="font-size:90%;">[⬆](../README.md#top)</span>

<table style="font-family:Helvetica,Arial;line-height:1.6;">
  <tr>
  <td style="border:0;padding:0 10px 0 0;min-width:25%;"><a href="https://lisp-lang.org/" rel="external" title="https://lisp-lang.org/"><img src="../docs/images/Lisp_logo.svg" width="100" alt="Common Lisp"/></a></td>
  <td style="border:0;padding:0;vertical-align:text-top;">Directory <a href="."><strong><code>examples\</code></strong></a> contains <a href="https://lisp-lang.org/" rel="external" title="https://lisp-lang.org/">Common Lisp</a> (CL) code examples coming from various websites - mostly from the <a href="https://lisp-lang.org/" rel="external" title="https://lisp-lang.org/">Common Lisp</a> project.<br/>
  It also includes build scripts (<a href="https://tldp.org/LDP/Bash-Beginners-Guide/html/sect_02_01.html" rel="external">Bash scripts</a>, <a href="https://en.wikibooks.org/wiki/Windows_Batch_Scripting" rel="external">batch files</a>, <a href="https://makefiletutorial.com/" rel="external">Make scripts</a>, <a href="https://learn.microsoft.com/en-us/powershell/scripting/overview" rel="external" title="https://learn.microsoft.com/en-us/powershell/scripting/overview">PowerShell scripts</a>) for experimenting with <a href="https://lisp-lang.org/" rel="external" title="https://lisp-lang.org/">Common Lisp</a> on a Windows machine.</td>
  </tr>
</table>

The code examples presented below can be built/run with the following command line tools :

| Build&nbsp;tool | Build&nbsp;file | Parent&nbsp;file | Environment(s) |
|:----------------|:----------------|:-----------------|:---------------|
| [**`cmd.exe`**][cmd_cli] | [`build.bat`](./lists/build.bat) | &nbsp; | Windows only |
| [**`make.exe`**][make_cli] | [`Makefile`](./lists/Makefile) |[`Makefile.inc`](./Makefile.inc) | Any <sup><b>a)</b></sup> |
| [**`pwsh.exe`**][pwsh_cli] | [`build.ps1`](./lists/build.ps1) | &nbsp; | Any <sup><b>a)</b></sup> |
| [**`sh.exe`**][sh_cli] | [`build.sh`](./lists/build.sh) | &nbsp; | Any <sup><b>a)</b></sup> |
<div style="margin:0 0 0 10px;font-size:80%;">
<sup><b>a)</b></sup> Here "Any" means "tested on Windows, Cygwin, MSYS2 and UNIX".<br/>&nbsp;
</div>

## <span id="lists">`lists` Example</span> [**&#x25B4;**](#top)

The directory structure of project `lists` looks as follows:
<pre style="font-size:80%;">
<b>&gt; <a href="https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/tree" rel="external" title="https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/tree">tree</a> /a /f . | <a href="https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/findstr" rel="external" title="https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/findstr">findstr</a> /v "^[A-Z]"</b>
|   <a href="./lists/build.bat" title="Batch file">build.bat</a>
|   <a href="./lists/build.ps1" title="PowerShell script">build.ps1</a>
|   <a href="./lists/build.sh" title="Bash script">build.sh</a>
|   <a href="./lists/Makefile" title="Make script">Makefile</a>
\---<b>src</b>
        <a href="./lists/src/defs.lisp" title="More definitions">defs.lisp</a>
        <a href="./lists/src/lists.lisp" title="Source file with main function">lists.lisp</a>  <i>(with main function)</i>
</pre>

Running [**`build.bat`**](./lists/build.bat) with no parameter prints the help message :
<pre style="font-size:80%;">
<b>&gt; <a href="./lists/build.bat">build</a></b>
Usage: build { &lt;option&gt; | &lt;subcommand&gt; }

  Options:
    -ccl        use the Clozure CL compiler if available
    -debug      print commands executed by this script
    -sbcl       use the Steel Bank CL compiler (default)
    -verbose    print progress messages

  Subcommands:
    clean       delete generated files
    compile     generate executable "lists.exe"
    eval        evaluate the main function in source file
    help        print this help message
    run         run the generated executable "lists.exe"
</pre>

Command [**`build.bat`**](./lists/build.bat)`-verbose eval` evaluates (interprets) the Common Lisp programs found in directory [`src\`](./lists/src/) (we use options `-ccl` and `-sbcl`<sup id="anchor_01">[1](#footnote_01)</sup> select either Clozure CL or Steel Bank CL toolsets) :

<pre style="font-size:80%;">
<b>&gt; <a href="./lists/build.bat">build</a> -verbose eval</b>
Evaluate program "lists" (sbcl)
Length of list: 4
Length of list: 4
&nbsp;
<b>&gt; <a href="./lists/build.bat">build</a> -verbose eval -ccl</b>
Evaluate program "lists" (ccl)
Length of list: 4
Length of list: 4
</pre>

Command [**`build.bat`**](./lists/build.bat)`clean run`<sup id="anchor_02">[2](#footnote_02)</sup> generates and executes the Common Lisp program `target\lists.exe` :

<pre style="font-size:80%;">
<b>&gt; <a href="./lists/build.bat">build</a> clean run</b>
Length of list: 4
</pre>

<!--=======================================================================-->

## <span id="quicksort">`quicksort` Example</span> [**&#x25B4;**](#top)
<!--
; Source - https://stackoverflow.com/a/54169156
; Posted by Orm Finnendahl, modified by community. See post 'Timeline' for change history
-->
The directory structure of project `quicksort` looks as follows:
<pre style="font-size:80%;">
<b>&gt; <a href="https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/tree" rel="external" title="https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/tree">tree</a> /a /f . | <a href="https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/findstr" rel="external" title="https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/findstr">findstr</a> /v "^[A-Z]"</b>
|   <a href="./quicksort/build.bat" title="Batch file">build.bat</a>
|   <a href="./quicksort/build.ps1" title="PowerShell script">build.ps1</a>
|   <a href="./quicksort/build.sh" title="Bash script">build.sh</a>
|   <a href="./quicksort/Makefile" title="Make script">Makefile</a>
\---<b>src</b>
        <a href="./quicksort/src/quicksort.lisp" title="Source file with main function">quicksort.lisp</a>  <i>(with main function)</i>
</pre>

Command `sh`[**`build.sh`**](./quicksort/build.sh)`-verbose clean run` generates and executes the Common Lisp program `target/quicksort.exe` (we use options `-ccl` and `-sbcl`<sup>[1](#footnote_01)</sup> select either Clozure CL or Steel Bank CL toolsets) :

<pre style="font-size:80%;">
<b>&gt; <a href="https://man7.org/linux/man-pages/man1/sh.1p.html" rel="external" title="https://man7.org/linux/man-pages/man1/sh.1p.html">sh</a> <a href="./quicksort/build.sh">build.sh</a> -verbose clean run</b>
Delete directory "target"
Duplicate main source file before applying patch
Generate executable "target/quicksort.exe" (sbcl)
Execute "target/quicksort.exe"
Unsorted: (92 44 95 5 97 58 43 99 37 68 26 95 16 89 33 17 51 55 42 82)
Sorted  : (5 16 17 26 33 37 42 43 44 51 55 58 68 82 89 92 95 95 97 99)
&nbsp;
<b>&gt; <a href="https://man7.org/linux/man-pages/man1/sh.1p.html" rel="external" title="https://man7.org/linux/man-pages/man1/sh.1p.html">sh</a> <a href="./quicksort/build.sh">build.sh</a> -verbose -ccl clean run</b>
Delete directory "target"
Duplicate main source file before applying patch
Generate executable "target/quicksort.exe" (ccl)
Execute "target/quicksort.exe"
Unsorted: (77 72 17 56 75 22 50 76 20 49 29 16 4 61 33 71 87 65 56 92)
Sorted  : (4 16 17 20 22 29 33 49 50 56 56 61 65 71 72 75 76 77 87 92)
</pre>

<!--=======================================================================-->

## <span id="footnotes">Footnotes</span> [**&#x25B4;**](#top)


<span id="footnote_01">[1]</span> ***Steel Bank CL Help*** [↩](#anchor_01)

<dl><dd>
<pre style="font-size:80%;">
<b>&gt; <a href="">sbcl</a> --help</b>
Usage: sbcl [runtime-options] [toplevel-options] [user-options]
Common runtime options:
  --help                     Print this message and exit.
  --version                  Print version information and exit.
  --core &lt;filename>          Use the specified core file instead of the default.
  --dynamic-space-size &lt;MiB> Size of reserved dynamic space in megabytes.
  --control-stack-size &lt;MiB> Size of reserved control stack in megabytes.
  --tls-limit                Maximum number of thread-local symbols.
&nbsp;
Common toplevel options:
  --sysinit &lt;filename>       System-wide init-file to use instead of default.
  --userinit &lt;filename>      Per-user init-file to use instead of default.
  --no-sysinit               Inhibit processing of any system-wide init-file.
  --no-userinit              Inhibit processing of any per-user init-file.
  --disable-debugger         Invoke sb-ext:disable-debugger.
  --noprint                  Run a Read-Eval Loop without printing results.
  --script [&lt;filename>]      Skip #! line, disable debugger, avoid verbosity.
  --quit                     Exit with code 0 after option processing.
  --non-interactive          Sets both --quit and --disable-debugger.
Common toplevel options that are processed in order:
  --eval &lt;form>              Form to eval when processing this option.
  --load &lt;filename>          File to load when processing this option.
&nbsp;
User options are not processed by SBCL. All runtime options must
appear before toplevel options, and all toplevel options must
appear before user options.
&nbsp;
For more information please refer to the SBCL User Manual, which
should be installed along with SBCL, and is also available from the
website <http://www.sbcl.org/>.
</pre>
</dd></dl>

<!--=======================================================================-->

<span id="footnote_02">[2]</span> ***Using the `-debug` option*** [↩](#anchor_02)

<dl><dd>
Running command <a ref="./lists/build.bat"><code>build.bat</code>(</a> with option <code>-debug</code> prints the executed instructions to generate and execute <code>target\lists.exe</code> :

<pre style="font-size:80%;">
<b>&gt; <a href="./lists/build.bat">build</a> -debug clean run</b>
[build] Options    : _DEBUG=1 _VERBOSE=0
[build] Subcommands:  clean compile run
[build] Variables  : "GIT_HOME=C:\opt\Git"
[build] Variables  : "SBCL_HOME=C:\opt\sbcl"
[build] rmdir /s /q "O:\examples\lists\target"
[build] copy "O:\examples\lists\src\lists.lisp" "O:\examples\lists\target\src\__main__.lisp"
[build] Current directory is: O:\examples\lists\target
[build] "C:\opt\sbcl\sbcl.exe" --noinform --load "O:\examples\lists\src\defs.lisp" --load "O:\examples\lists\target\src\__main__.lisp"
[build] "O:\examples\lists\target\lists.exe"
Length of list: 4
Length of list: 4
[build] _EXITCODE=0
</pre>
</dd></dl>

***

*[mics](https://lampwww.epfl.ch/~michelou/)/June 2026* [**&#9650;**](#top)
<span id="bottom">&nbsp;</span>

<!-- link refs -->

[cmd_cli]: https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/cmd "https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/cmd"
[make_cli]: https://man7.org/linux/man-pages/man1/make.1.html "https://man7.org/linux/man-pages/man1/make.1.html"
[pwsh_cli]: https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_pwsh "https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_pwsh"
[sh_cli]: https://man7.org/linux/man-pages/man1/sh.1p.html "https://man7.org/linux/man-pages/man1/sh.1p.html"
