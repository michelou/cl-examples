@echo off
setlocal enabledelayedexpansion

@rem only for interactive debugging
set _DEBUG=0

@rem #########################################################################
@rem ## Environment setup

set _EXITCODE=0

call :env
if not %_EXITCODE%==0 goto end

call :args %*
if not %_EXITCODE%==0 goto end

@rem #########################################################################
@rem ## Main

if %_HELP%==1 (
    call :help
    exit /b !_EXITCODE!
)
set _CLAUDE_PATH=
set _GIT_PATH=
set _MAKE_PATH=
set _VSCODE_PATH=

call :ccl
if not %_EXITCODE%==0 (
    @rem optional
    set _EXITCODE=0
)
if %_USE_CLAUDE%==1 (
    call :claude
    if not !_EXITCODE!==0 (
        @rem optional
        echo %_WARNING_LABEL% Claude not installed 1>&2
        set _EXITCODE=0
    )
)
call :git
if not %_EXITCODE%==0 goto end

call :make
if not %_EXITCODE%==0 goto end

call :sbcl
if not %_EXITCODE%==0 goto end

call :vscode
if not %_EXITCODE%==0 (
    @rem optional
    set _EXITCODE=0
)
goto end

@rem #########################################################################
@rem ## Subroutines

@rem output parameters: _DEBUG_LABEL, _ERROR_LABEL, _WARNING_LABEL
:env
set _BASENAME=%~n0
set "_ROOT_DIR=%~dp0"

call :env_colors
set _DEBUG_LABEL=%_NORMAL_BG_CYAN%[%_BASENAME%]%_RESET%
set _ERROR_LABEL=%_STRONG_FG_RED%Error%_RESET%:
set _WARNING_LABEL=%_STRONG_FG_YELLOW%Warning%_RESET%:
goto :eof

:env_colors
@rem ANSI colors in standard Windows 10 shell
@rem see https://gist.github.com/mlocati/#file-win10colors-cmd

@rem normal foreground colors
set _NORMAL_FG_BLACK=[30m
set _NORMAL_FG_RED=[31m
set _NORMAL_FG_GREEN=[32m
set _NORMAL_FG_YELLOW=[33m
set _NORMAL_FG_BLUE=[34m
set _NORMAL_FG_MAGENTA=[35m
set _NORMAL_FG_CYAN=[36m
set _NORMAL_FG_WHITE=[37m

@rem normal background colors
set _NORMAL_BG_BLACK=[40m
set _NORMAL_BG_RED=[41m
set _NORMAL_BG_GREEN=[42m
set _NORMAL_BG_YELLOW=[43m
set _NORMAL_BG_BLUE=[44m
set _NORMAL_BG_MAGENTA=[45m
set _NORMAL_BG_CYAN=[46m
set _NORMAL_BG_WHITE=[47m

@rem strong foreground colors
set _STRONG_FG_BLACK=[90m
set _STRONG_FG_RED=[91m
set _STRONG_FG_GREEN=[92m
set _STRONG_FG_YELLOW=[93m
set _STRONG_FG_BLUE=[94m
set _STRONG_FG_MAGENTA=[95m
set _STRONG_FG_CYAN=[96m
set _STRONG_FG_WHITE=[97m

@rem strong background colors
set _STRONG_BG_BLACK=[100m
set _STRONG_BG_RED=[101m
set _STRONG_BG_GREEN=[102m
set _STRONG_BG_YELLOW=[103m
set _STRONG_BG_BLUE=[104m

@rem we define _RESET in last position to avoid crazy console output with type command
set _BOLD=[1m
set _UNDERSCORE=[4m
set _INVERSE=[7m
set _RESET=[0m
goto :eof

@rem input parameter: %*
@rem output parameters: _BASH, _HELP, _VERBOSE
:args
set _BASH=0
set _HELP=0
set _USE_CLAUDE=0
set _VERBOSE=0
:args_loop
set "__ARG=%~1"
if not defined __ARG goto args_done

if "%__ARG:~0,1%"=="-" (
    @rem option
    if "%__ARG%"=="-bash" ( set _BASH=1
    ) else if "%__ARG%"=="-debug" ( set _DEBUG=1
    ) else if "%__ARG%"=="-help" ( set _HELP=1
    ) else if "%__ARG%"=="-claude" ( set _USE_CLAUDE=1
    ) else if "%__ARG%"=="-verbose" ( set _VERBOSE=1
    ) else (
        echo %_ERROR_LABEL% Unknown option "%__ARG%" 1>&2
        set _EXITCODE=1
        goto args_done
    )
) else (
    @rem subcommand
    if "%__ARG%"=="help" ( set _HELP=1
    ) else (
        echo %_ERROR_LABEL% Unknown subcommand "%__ARG%" 1>&2
        set _EXITCODE=1
        goto args_done
    )
)
shift
goto args_loop
:args_done
call :drive_name "%_ROOT_DIR%"
if not %_EXITCODE%==0 goto :eof
if %_DEBUG%==1 (
    echo %_DEBUG_LABEL% Options    : _BASH=%_BASH% _USE_CLAUDE=%_USE_CLAUDE% _VERBOSE=%_VERBOSE% 1>&2
    echo %_DEBUG_LABEL% Subcommands: _HELP=%_HELP% 1>&2
    echo %_DEBUG_LABEL% Variables  : _DRIVE_NAME=%_DRIVE_NAME% 1>&2
)
goto :eof

@rem input parameter: %1: path to be substituted
@rem output parameter: _DRIVE_NAME (2 characters: letter + ':')
:drive_name
set "__GIVEN_PATH=%~1"
@rem remove trailing path separator if present
if "%__GIVEN_PATH:~-1,1%"=="\" set "__GIVEN_PATH=%__GIVEN_PATH:~0,-1%"

@rem https://serverfault.com/questions/62578/how-to-get-a-list-of-drive-letters-on-a-system-through-a-windows-shell-bat-cmd
set __DRIVE_NAMES=F:G:H:I:J:K:L:M:N:O:P:Q:R:S:T:U:V:W:X:Y:Z:
@rem deprecated since Windows 11
@rem for /f %%i in ('wmic logicaldisk get deviceid ^| findstr :') do (
@rem     set "__DRIVE_NAMES=!__DRIVE_NAMES:%%i=!"
@rem )
@rem alternative in Windows 11
for /f "delims=" %%i in ('fsutil fsinfo drives') do (
    set "__LINE=%%i"
    set "__DRIVES=!__LINE:Drives:=!"
    set "__DRIVES=!__DRIVES:\=!"
    for %%d in (!__DRIVES!) do (
        set "__DRIVE_NAMES=!__DRIVE_NAMES:%%d=!"
    )
)
if %_DEBUG%==1 echo %_DEBUG_LABEL% __DRIVE_NAMES=%__DRIVE_NAMES% ^(fsutil^) 1>&2
if not defined __DRIVE_NAMES (
    echo %_ERROR_LABEL% No more free drive name 1>&2
    set _EXITCODE=1
    goto :eof
)
for /f "tokens=1,2,*" %%f in ('subst') do (
    set "__SUBST_DRIVE=%%f"
    set "__SUBST_DRIVE=!__SUBST_DRIVE:~0,2!"
    set "__SUBST_PATH=%%h"
    @rem Windows local file systems are not case sensitive (by default)
    if /i "!__SUBST_DRIVE!"=="!__GIVEN_PATH:~0,2!" (
        set _DRIVE_NAME=!__SUBST_DRIVE:~0,2!
        if %_DEBUG%==1 ( echo %_DEBUG_LABEL% Select drive !_DRIVE_NAME! for which a substitution already exists 1>&2
        ) else if %_VERBOSE%==1 ( echo Select drive !_DRIVE_NAME! for which a substitution already exists 1>&2
        )
        goto :eof
    ) else if "!__SUBST_PATH!"=="!__GIVEN_PATH!" (
        set "_DRIVE_NAME=!__SUBST_DRIVE!"
        if %_DEBUG%==1 ( echo %_DEBUG_LABEL% Select drive !_DRIVE_NAME! for which a substitution already exists 1>&2
        ) else if %_VERBOSE%==1 ( echo Select drive !_DRIVE_NAME! for which a substitution already exists 1>&2
        )
        goto :eof
    )
)
for /f "tokens=1,2,*" %%i in ('subst') do (
    set __USED=%%i
    call :drive_names "!__USED:~0,2!"
)
if %_DEBUG%==1 echo %_DEBUG_LABEL% __DRIVE_NAMES=%__DRIVE_NAMES% ^(SUBST^) 1>&2

set "_DRIVE_NAME=!__DRIVE_NAMES:~0,2!"
if /i "%_DRIVE_NAME%"=="%__GIVEN_PATH:~0,2%" goto :eof

if %_DEBUG%==1 ( echo %_DEBUG_LABEL% subst "%_DRIVE_NAME%" "%__GIVEN_PATH%" 1>&2
) else if %_VERBOSE%==1 ( echo Assign drive %_DRIVE_NAME% to path "!__GIVEN_PATH:%USERPROFILE%=%%USERPROFILE%%!" 1>&2
)
subst "%_DRIVE_NAME%" "%__GIVEN_PATH%"
if not %ERRORLEVEL%==0 (
    echo %_ERROR_LABEL% Failed to assign drive %_DRIVE_NAME% to path "!__GIVEN_PATH:%USERPROFILE%=%%USERPROFILE%%!" 1>&2
    set _EXITCODE=1
    goto :eof
)
goto :eof

@rem input parameter: %1=Used drive name
@rem output parameter: __DRIVE_NAMES
:drive_names
set "__USED_NAME=%~1"
set "__DRIVE_NAMES=!__DRIVE_NAMES:%__USED_NAME%=!"
goto :eof

:help
if %_VERBOSE%==1 (
    set __BEG_P=%_STRONG_FG_CYAN%
    set __BEG_O=%_STRONG_FG_GREEN%
    set __BEG_N=%_NORMAL_FG_YELLOW%
    set __END=%_RESET%
) else (
    set __BEG_P=
    set __BEG_O=
    set __BEG_N=
    set __END=
)
echo Usage: %__BEG_O%%_BASENAME% { ^<option^> ^| ^<subcommand^> }%__END%
echo.
echo   %__BEG_P%Options:%__END%
echo     %__BEG_O%-bash%__END%       start Git bash shell instead of Windows command prompt
echo     %__BEG_O%-claude%__END%     add Claude command to the project environment
echo     %__BEG_O%-debug%__END%      print commands executed by this script
echo     %__BEG_O%-verbose%__END%    print progress messages
echo.
echo   %__BEG_P%Subcommands:%__END%
echo     %__BEG_O%help%__END%        print this help message
goto :eof

@rem output parameters: _CCL_HOME
:ccl
set _CCL_HOME=

set __CCL_CMD=
for /f "delims=" %%f in ('where wx86cl64.exe 2^>NUL') do set "__CCL_CMD=%%f"
if defined __CCL_CMD (
    for /f "delims=" %%i in ("%__CCL_CMD%") do set "_CCL_HOME=%%~dpf"
    if %_DEBUG%==1 echo %_DEBUG_LABEL% Using path of Clozure CL executable found in PATH 1>&2
    @rem keep _CCL_PATH undefined since executable already in path
    goto :eof
) else if defined CCL_HOME (
    set "_CCL_HOME=%CCL_HOME%"
    if %_DEBUG%==1 echo %_DEBUG_LABEL% Using environment variable CCL_HOME 1>&2
) else (
    set "__PATH=C:\opt"
    if exist "!__PATH!\ccl" set "_CCL_HOME=!__PATH!\ccl"
    if defined _CCL_HOME (
        if %_DEBUG%==1 echo %_DEBUG_LABEL% Using default Clozure CL installation directory "!_CCL_HOME!" 1>&2
    )
)
if not exist "%_CCL_HOME%\wx86cl64.exe" (
    echo %_ERROR_LABEL% Clozure CL executable not found ^("%_CCL_HOME%"^) 1>&2
    set _EXITCODE=1
    goto :eof
)
goto :eof


@rem output parameters: _CLAUDE_HOME, _CLAUDE_PATH
:claude
set _CLAUDE_HOME=
set _CLAUDE_PATH=

set __CLAUDE_CMD=
for /f "delims=" %%f in ('where claude.exe 2^>NUL') do set "__CLAUDE_CMD=%%f"
if defined __CLAUDE_CMD (
    for /f "delims=" %%i in ("%__CLAUDE_CMD%") do set "__CLAUDE_BIN_DIR=%%~dpi"
    for /f "delims=" %%f in ("!__CLAUDE_BIN_DIR!\.") do set "_CLAUDE_HOME=%%~dpf"
    if %_DEBUG%==1 echo %_DEBUG_LABEL% Using path of Claude executable found in PATH 1>&2
    @rem keep _CLAUDE_PATH undefined since executable already in path
    goto :eof
) else if defined CLAUDE_HOME (
    set "_CLAUDE_HOME=%CLAUDE_HOME%"
    if %_DEBUG%==1 echo %_DEBUG_LABEL% Using environment variable CLAUDE_HOME 1>&2
) else (
    if exist "%USERPROFILE%\.local\bin" set "_CLAUDE_HOME=%USERPROFILE%\.local"
    if defined _CLAUDE_HOME (
        if %_DEBUG%==1 echo %_DEBUG_LABEL% Using default Claude installation directory "!_CLAUDE_HOME!" 1>&2
    )
)
if not exist "%_CLAUDE_HOME%\bin\claude.exe" (
    echo %_ERROR_LABEL% Claude executable not found ^("%_CLAUDE_HOME%"^) 1>&2
    set _EXITCODE=1
    goto :eof
)
set "_CLAUDE_PATH=;%_CLAUDE_HOME%\bin"
goto :eof

@rem output parameters: _MAKE_HOME, _MAKE_PATH
:make
set _MAKE_HOME=
set _MAKE_PATH=

set __MAKE_CMD=
for /f "delims=" %%f in ('where make.exe 2^>NUL') do set "__MAKE_CMD=%%f"
if defined __MAKE_CMD (
    if %_DEBUG%==1 echo %_DEBUG_LABEL% Using path of Make executable found in PATH 1>&2
    @rem keep _MAKE_PATH undefined since executable already in path
    goto :eof
) else if defined MAKE_HOME (
    set "_MAKE_HOME=%MAKE_HOME%"
    if %_DEBUG%==1 echo %_DEBUG_LABEL% Using environment variable MAKE_HOME 1>&2
) else (
    set __PATH=C:\opt
    if exist "!__PATH!\make\" ( set "_MAKE_HOME=!__PATH!\make"
    ) else (
        for /f "delims=" %%f in ('dir /ad /b "!__PATH!\make-3*" 2^>NUL') do set "_MAKE_HOME=!__PATH!\%%f"
    )
    if defined _MAKE_HOME (
        if %_DEBUG%==1 echo %_DEBUG_LABEL% Using default Make installation directory "!_MAKE_HOME!" 1>&2
    )
)
if not exist "%_MAKE_HOME%\bin\make.exe" (
    echo %_ERROR_LABEL% Make executable not found ^("%_MAKE_HOME%"^) 1>&2
    set _EXITCODE=1
    goto :eof
)
set "_MAKE_PATH=;%_MAKE_HOME%\bin"
goto :eof

@rem output parameters: _GIT_HOME, _GIT_PATH
:git
set _GIT_HOME=
set _GIT_PATH=

set __GIT_CMD=
for /f "delims=" %%f in ('where git.exe 2^>NUL') do set "__GIT_CMD=%%f"
if defined __GIT_CMD (
    for /f "delims=" %%i in ("%__GIT_CMD%") do set "__GIT_BIN_DIR=%%~dpi"
    for /f "delims=" %%f in ("!__GIT_BIN_DIR!\.") do set "_GIT_HOME=%%~dpf"
    @rem Executable git.exe is present both in bin\ and \mingw64\bin\
    if not "!_GIT_HOME:mingw=!"=="!_GIT_HOME!" (
        for /f "delims=" %%f in ("!_GIT_HOME!\.") do set "_GIT_HOME=%%~dpf"
    )
    if %_DEBUG%==1 echo %_DEBUG_LABEL% Using path of Git executable found in PATH 1>&2
    @rem keep _GIT_PATH undefined since executable already in path
    goto :eof
) else if defined GIT_HOME (
    set "_GIT_HOME=%GIT_HOME%"
    if %_DEBUG%==1 echo %_DEBUG_LABEL% Using environment variable GIT_HOME 1>&2
) else (
    set __PATH=C:\opt
    if exist "!__PATH!\Git\" ( set "_GIT_HOME=!__PATH!\Git"
    ) else (
        for /f "delims=" %%f in ('dir /ad /b "!__PATH!\Git*" 2^>NUL') do set "_GIT_HOME=!__PATH!\%%f"
        if not defined _GIT_HOME (
            set "__PATH=%ProgramFiles%"
            for /f "delims=" %%f in ('dir /ad /b "!__PATH!\Git*" 2^>NUL') do set "_GIT_HOME=!__PATH!\%%f"
        )
    )
    if defined _GIT_HOME (
        if %_DEBUG%==1 echo %_DEBUG_LABEL% Using default Git installation directory "!_GIT_HOME!" 1>&2
    )
)
if not exist "%_GIT_HOME%\bin\git.exe" (
    echo %_ERROR_LABEL% Git executable not found ^("%_GIT_HOME%"^) 1>&2
    set _EXITCODE=1
    goto :eof
)
set "_GIT_PATH=;%_GIT_HOME%\bin;%_GIT_HOME%\mingw64\bin;%_GIT_HOME%\usr\bin"
goto :eof

@rem output parameters: _SBCL_HOME
:sbcl
set _SBCL_HOME=

set __SBCL_CMD=
for /f "delims=" %%f in ('where sbcl.exe 2^>NUL') do set "__SBCL_CMD=%%f"
if defined __SBCL_CMD (
    if %_DEBUG%==1 echo %_DEBUG_LABEL% Using path of SBCL executable found in PATH 1>&2
    @rem keep _SBCL_PATH undefined since executable already in path
    goto :eof
) else if defined SBCL_HOME (
    set "_SBCL_HOME=%SBCL_HOME%"
    if %_DEBUG%==1 echo %_DEBUG_LABEL% Using environment variable SBCL_HOME 1>&2
) else (
    set __PATH=C:\opt
    if exist "!__PATH!\sbcl\" ( set "_SBCL_HOME=!__PATH!\sbcl"
    ) else (
        for /f "delims=" %%f in ('dir /ad /b "!__PATH!\sbcl-*" 2^>NUL') do set "_SBCL_HOME=!__PATH!\%%f"
        if not defined _SBCL_HOME (
            set "__PATH=%ProgramFiles%"
            for /f "delims=" %%f in ('dir /ad /b "!__PATH!\sbcl-*" 2^>NUL') do set "_SBCL_HOME=!__PATH!\%%f"
        )
    )
)
if not exist "%_SBCL_HOME%\sbcl.exe" (
    echo %_ERROR_LABEL% SBCL executable not found ^("%_SBCL_HOME%"^) 1>&2
    set _EXITCODE=1
    goto :eof
)
goto :eof

@rem output parameters: _VSCODE_HOME, _VSCODE_PATH
:vscode
set _VSCODE_HOME=
set _VSCODE_PATH=

set __CODE_CMD=
for /f "delims=" %%f in ('where code.exe 2^>NUL') do set "__CODE_CMD=%%f"
if defined __CODE_CMD (
    if %_DEBUG%==1 echo %_DEBUG_LABEL% Using path of VSCode executable found in PATH 1>&2
    @rem keep _VSCODE_PATH undefined since executable already in path
    goto :eof
) else if defined VSCODE_HOME (
    set "_VSCODE_HOME=%VSCODE_HOME%"
    if %_DEBUG%==1 echo %_DEBUG_LABEL% Using environment variable VSCODE_HOME 1>&2
) else (
    set __PATH=C:\opt
    if exist "!__PATH!\VSCode\" ( set "_VSCODE_HOME=!__PATH!\VSCode"
    ) else (
        for /f "delims=" %%f in ('dir /ad /b "!__PATH!\VSCode-*" 2^>NUL') do set "_VSCODE_HOME=!__PATH!\%%f"
        if not defined _VSCODE_HOME (
            set "__PATH=%ProgramFiles%"
            for /f "delims=" %%f in ('dir /ad /b "!__PATH!\VSCode-*" 2^>NUL') do set "_VSCODE_HOME=!__PATH!\%%f"
        )
    )
)
if not exist "%_VSCODE_HOME%\code.exe" (
    echo %_WARNING_LABEL% VSCode executable not found ^("%_VSCODE_HOME%"^) 1>&2
    if exist "%_VSCODE_HOME%\Code - Insiders.exe" (
        echo %_WARNING_LABEL% It looks like you've installed an Insider version of VSCode 1>&2
    )
    set _EXITCODE=1
    goto :eof
)
set "_VSCODE_PATH=;%_VSCODE_HOME%"
goto :eof

@rem input parameter: %1=verbose flag
:print_env
set __USE_CLAUDE=%~1
set __VERBOSE=%~2
set __VERSIONS_LINE1=
set __VERSIONS_LINE2=
set __WHERE_ARGS=
where /q "%CCL_HOME%:wx86cl64.exe"
if %ERRORLEVEL%==0 (
    for /f "tokens=1,2,3,4,5,*" %%i in ('call "%CCL_HOME%\wx86cl64.exe" --version') do set "__VERSIONS_LINE1=%__VERSIONS_LINE1% ccl %%m,"
    set __WHERE_ARGS=%__WHERE_ARGS% "%CCL_HOME%:wx86cl64.exe"
)
if %__USE_CLAUDE%==0 goto print_next
where /q "%CLAUDE_HOME%\bin:claude.exe"
if %ERRORLEVEL%==0 (
    for /f "tokens=1,*" %%i in ('call "%CLAUDE_HOME%\bin\claude.exe" --version') do set "__VERSIONS_LINE1=%__VERSIONS_LINE1% Claude %%i,"
    set __WHERE_ARGS=%__WHERE_ARGS% "%CLAUDE_HOME%\bin:claude.exe"
)
:print_next
where /q "%SBCL_HOME%:sbcl.exe"
if %ERRORLEVEL%==0 (
    for /f "tokens=1,*" %%i in ('call "%SBCL_HOME%\sbcl.exe" --version') do set "__VERSIONS_LINE1=%__VERSIONS_LINE1% sbcl %%j,"
    set __WHERE_ARGS=%__WHERE_ARGS% "%SBCL_HOME%:sbcl.exe"
)
where /q "%MAKE_HOME%\bin:make.exe"
if %ERRORLEVEL%==0 (
    for /f "tokens=1,2,*" %%i in ('"%MAKE_HOME%\bin\make.exe" --version 2^>^&1 ^| findstr Make') do set "__VERSIONS_LINE1=%__VERSIONS_LINE1% make %%k,"
    set __WHERE_ARGS=%__WHERE_ARGS% "%MAKE_HOME%\bin:make.exe"
)
where /q "%GIT_HOME%\bin:git.exe"
if %ERRORLEVEL%==0 (
    for /f "tokens=1,2,*" %%i in ('call "%GIT_HOME%\bin\git.exe" --version') do (
        for /f "delims=. tokens=1,2,3,*" %%a in ("%%k") do set "__VERSIONS_LINE2=%__VERSIONS_LINE2% git %%a.%%b.%%c,"
    )
    set __WHERE_ARGS=%__WHERE_ARGS% "%GIT_HOME%\bin:git.exe"
)
where /q "%GIT_HOME%\usr\bin:diff.exe"
if %ERRORLEVEL%==0 (
   for /f "tokens=1-3,*" %%i in ('diff.exe --version ^| findstr diff') do set "__VERSIONS_LINE2=%__VERSIONS_LINE2% diff %%l,"
    set __WHERE_ARGS=%__WHERE_ARGS% diff.exe
)
where /q "%GIT_HOME%\bin:bash.exe"
if %ERRORLEVEL%==0 (
    for /f "tokens=1-3,4,*" %%i in ('"%GIT_HOME%\bin\bash.exe" --version ^| findstr bash') do (
        set "__VERSION=%%l"
        setlocal enabledelayedexpansion
        set "__VERSIONS_LINE2=%__VERSIONS_LINE2% bash !__VERSION:-release=!"
    )
    set __WHERE_ARGS=%__WHERE_ARGS% "%GIT_HOME%\bin:bash.exe"
)
echo Tool versions:
echo   %__VERSIONS_LINE1%
echo   %__VERSIONS_LINE2%
if %__VERBOSE%==1 (
    echo Tool paths: 1>&2
    for /f "tokens=*" %%p in ('where %__WHERE_ARGS%') do (
        set "__LINE=%%p"
        setlocal enabledelayedexpansion
        echo    !__LINE:%USERPROFILE%=%%USERPROFILE%%! 1>&2
    )
    echo Environment variables: 1>&2
    if defined CCL_HOME echo    "CCL_HOME=%CCL_HOME%" 1>&2
    if defined CLAUDE_HOME echo    "CLAUDE_HOME=%CLAUDE_HOME%" 1>&2
    if defined GIT_HOME echo    "GIT_HOME=%GIT_HOME%" 1>&2
    if defined MAKE_HOME echo    "MAKE_HOME=%MAKE_HOME%" 1>&2
    if defined SBCL_HOME echo    "SBCL_HOME=%SBCL_HOME%" 1>&2
    if defined VSCODE_HOME echo    "VSCODE_HOME=%VSCODE_HOME%" 1>&2
    echo Path associations: 1>&2
    for /f "delims=" %%i in ('subst') do (
        set "__LINE=%%i"
        setlocal enabledelayedexpansion
        echo    !__LINE:%USERPROFILE%=%%USERPROFILE%%! 1>&2
    )
)
goto :eof

@rem #########################################################################
@rem ## Cleanups

:end
endlocal & (
    if %_EXITCODE%==0 (
        if not defined CCL_HOME set "CCL_HOME=%_CCL_HOME%"
        if %_USE_CLAUDE%==1 (
            if not defined CLAUDE_HOME set "CLAUDE_HOME=%_CLAUDE_HOME%"
        )
        if not defined GIT_HOME set "GIT_HOME=%_GIT_HOME%"
        if not defined MAKE_HOME set "MAKE_HOME=%_MAKE_HOME%"
        if not defined SBCL_HOME set "SBCL_HOME=%_SBCL_HOME%"
        if not defined VSCODE_HOME set "VSCODE_HOME=%_VSCODE_HOME%"
        @rem We prepend %_GIT_HOME%\bin to hide C:\Windows\System32\bash.exe and C:\Windows\System32\curl.exe
        set "PATH=%_GIT_HOME%\bin;%PATH%%_CLAUDE_PATH%%_MAKE_PATH%%_GIT_PATH%%_VSCODE_PATH%;%~dp0bin"
        call :print_env %_USE_CLAUDE% %_VERBOSE%
        if not "%CD:~0,2%"=="%_DRIVE_NAME%" (
            if %_DEBUG%==1 echo %_DEBUG_LABEL% cd /d "%_DRIVE_NAME%" 1>&2
            cd /d "%_DRIVE_NAME%"
        )
        if %_BASH%==1 (
            @rem see https://conemu.github.io/en/GitForWindows.html
            if %_DEBUG%==1 echo %_DEBUG_LABEL% "%_GIT_HOME%\bin\bash.exe" --login 1>&2
            call "%_GIT_HOME%\bin\bash.exe" --login
        )
    )
    @rem see https://wiip.fr/en/blog/claude-code-powershell-tool
    set CLAUDE_CODE_USE_POWERSHELL_TOOL=1
    if %_DEBUG%==1 echo %_DEBUG_LABEL% _EXITCODE=%_EXITCODE% 1>&2
    for /f "delims==" %%i in ('set ^| findstr /b "_"') do set %%i=
)
