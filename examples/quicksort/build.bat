@echo off
setlocal enabledelayedexpansion

@rem only for interactive debugging !
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
for %%c in (%_COMMANDS%) do (
    call :%%c
    if not !_EXITCODE!==0 goto end
)

goto end

@rem #########################################################################
@rem ## Subroutines

@rem output parameters: _DEBUG_LABEL, _ERROR_LABEL, _WARNING_LABEL
:env
set _BASENAME=%~n0
set "_ROOT_DIR=%~dp0"

set "_SOURCE_DIR=%_ROOT_DIR%src"
set "_TARGET_DIR=%_ROOT_DIR%target"
set "_TARGET_SRC_DIR=%_ROOT_DIR%target\src"

call :env_colors
set _DEBUG_LABEL=%_NORMAL_BG_CYAN%[%_BASENAME%]%_RESET%
set _ERROR_LABEL=%_STRONG_FG_RED%Error%_RESET%:
set _WARNING_LABEL=%_STRONG_FG_YELLOW%Warning%_RESET%:

for /f "delims=" %%f in ("%~dp0\.") do set "_PROJECT_NAME=%%~nf"
set "_SOURCE_MAIN_FILE=%_SOURCE_DIR%\%_PROJECT_NAME%.lisp"
set "_TARGET_NAME=%_PROJECT_NAME%.exe"
set "_TARGET_FILE=%_TARGET_DIR%\%_TARGET_NAME%"

@rem optional (option -ccl)
set _CCL_CMD=
if exist "%CCL_HOME%\wx86cl64.exe" (
    set "_CCL_CMD=%CCL_HOME%\wx86cl64.exe"
)
set "_SBCL_CMD=%SBCL_HOME%\sbcl.exe"
if not exist "%_SBCL_CMD%" (
    echo %_ERROR_LABEL% Steel Bank CL command not found 1>&2
    set _EXITCODE=1
    goto :eof
)
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
@rem output parameters: _CLEAN, _COMPILE, _RUN, _DEBUG, _TOOLSET, _VERBOSE
:args
set _COMMANDS=
set _HELP=0
set _TIMER=0
set _TOOLSET=sbcl
set _VERBOSE=0
set __N=0
:args_loop
set "__ARG=%~1"
if not defined __ARG (
    if !__N!==0 set _HELP=1
    goto args_done
)
if "%__ARG:~0,1%"=="-" (
    @rem option
    if "%__ARG%"=="-ccl" ( set _TOOLSET=ccl
    ) else if "%__ARG%"=="-debug" ( set _DEBUG=1
    ) else if "%__ARG%"=="-help" ( set _HELP=1
    ) else if "%__ARG%"=="-sbcl" ( set _TOOLSET=sbcl
    ) else if "%__ARG%"=="-timer" ( set _TIMER=1
    ) else if "%__ARG%"=="-verbose" ( set _VERBOSE=1
    ) else (
        echo %_ERROR_LABEL% Unknown option "%__ARG%" 1>&2
        set _EXITCODE=1
        goto args_done
    )
) else (
    @rem subcommand
    if "%__ARG%"=="clean" ( set _COMMANDS=!_COMMANDS! clean
    ) else if "%__ARG%"=="compile" ( set _COMMANDS=!_COMMANDS! compile
    ) else if "%__ARG%"=="eval" ( set _COMMANDS=!_COMMANDS! evaluate
    ) else if "%__ARG%"=="help" ( set _HELP=1
    ) else if "%__ARG%"=="run" ( set _COMMANDS=!_COMMANDS! compile run
    ) else (
        echo %_ERROR_LABEL% Unknown subcommand "%__ARG%" 1>&2
        set _EXITCODE=1
        goto args_done
    )
    set /a __N+=1
)
shift
goto args_loop 1>&2
:args_done
if %_TOOLSET%==ccl if not defined _CCL_CMD (
    echo %_WARNING_LABEL% Clozure CL command not found ^(use SBCL instead^) 1>&2
    set _TOOLSET=sbcl
)
if %_DEBUG%==1 (
    echo %_DEBUG_LABEL% Properties : _PROJECT_NAME=%_PROJECT_NAME% 1>&2
    echo %_DEBUG_LABEL% Options    : _DEBUG=%_DEBUG% _TIMER=%_TIMER% _TOOLSET=%_TOOLSET% _VERBOSE=%_VERBOSE% 1>&2
    echo %_DEBUG_LABEL% Subcommands: %_COMMANDS% 1>&2
    if defined CCL_HOME echo %_DEBUG_LABEL% Variables  : "CCL_HOME=%CCL_HOME%" 1>&2
    echo %_DEBUG_LABEL% Variables  : "GIT_HOME=%GIT_HOME%" 1>&2
    echo %_DEBUG_LABEL% Variables  : "SBCL_HOME=%SBCL_HOME%" 1>&2
)
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
echo     %__BEG_O%-ccl%__END%        use the Clozure CL compiler if available
echo     %__BEG_O%-debug%__END%      print commands executed by this script
echo     %__BEG_O%-sbcl%__END%       use the Steel Bank CL compiler ^(default^)
echo     %__BEG_O%-timer%__END%      print total execution time
echo     %__BEG_O%-verbose%__END%    print progress messages
echo.
echo   %__BEG_P%Subcommands:%__END%
echo     %__BEG_O%clean%__END%       delete generated files
echo     %__BEG_O%compile%__END%     generate executable "%__BEG_O%%_TARGET_NAME%%__END%"
echo     %__BEG_O%eval%__END%        evaluate the main function in source file
echo     %__BEG_O%help%__END%        print this help message
echo     %__BEG_O%run%__END%         run the generated executable "%__BEG_O%%_TARGET_NAME%%__END%"
goto :eof

:clean
call :rmdir "%_TARGET_DIR%"
goto :eof

@rem input parameter: %1=directory path
:rmdir
set "__DIR=%~1"
if not exist "%__DIR%\" goto :eof
if %_DEBUG%==1 ( echo %_DEBUG_LABEL% rmdir /s /q "%__DIR%" 1>&2
) else if %_VERBOSE%==1 ( echo Delete directory "!__DIR:%_ROOT_DIR%=!" 1>&2
)
rmdir /s /q "%__DIR%"
if not %ERRORLEVEL%==0 (
    echo %_ERROR_LABEL% Failed to delete directory "!__DIR:%_ROOT_DIR%=!" 1>&2
    set _EXITCODE=1
    goto :eof
)
goto :eof

:compile
if not exist "%_TARGET_SRC_DIR%" mkdir "%_TARGET_SRC_DIR%"

call :action_required "%_TARGET_FILE%" "%_SOURCE_DIR%\*.lisp"
if %_ACTION_REQUIRED%==0 goto :eof

set "__TARGET_MAIN_FILE=%_TARGET_SRC_DIR%\__main__.lisp"

if %_DEBUG%==1 ( echo %_DEBUG_LABEL% copy "%_SOURCE_MAIN_FILE%" "%__TARGET_MAIN_FILE%" 1>&2
) else if %_VERBOSE%==1 ( echo Duplicate main source file before applying patch 1>&2
)
copy "%_SOURCE_MAIN_FILE%" "%__TARGET_MAIN_FILE%" 1>NUL
if %_TOOLSET%==ccl (
    @rem see https://stackoverflow.com/questions/833314/compiling-binaries-with-clozure-common-lisp
    (
        echo.
        echo ; code appended to file "!_SOURCE_MAIN_FILE:%_ROOT_DIR%=!"
        echo ^(ccl:save-application "%_TARGET_NAME%"
        echo    :toplevel-function #'main
        echo    :prepend-kernel t^)
    ) >> "%__TARGET_MAIN_FILE%"
    set "__CL_CMD=%_CCL_CMD%"
    set __CL_OPTS=--eval "(require :asdf)"
) else (
    (
        echo.
        echo ; code appended to file "!_SOURCE_MAIN_FILE:%_ROOT_DIR%=!"
        echo ^(sb-ext:save-lisp-and-die "%_TARGET_NAME%"
        echo     :toplevel #'main
        echo     :executable t^)
    ) >> "%__TARGET_MAIN_FILE%"
    set "__CL_CMD=%_SBCL_CMD%"
    set __CL_OPTS=--noinform --eval "(require :asdf)"
)
@rem main source file is loaded in last position;
@rem if present the other source files are loaded in alphabetic order based on their name
set __FILE_LOADS=--load "%__TARGET_MAIN_FILE%"
for /f "delims=" %%f in ('dir /s /b /o-n "%_SOURCE_DIR%\*.lisp" ^| findstr /v "%_PROJECT_NAME%.lisp"') do (
    set __FILE_LOADS=--load "%%f" !__FILE_LOADS!
)
pushd "%_TARGET_DIR%"
if %_DEBUG%==1 echo %_DEBUG_LABEL% Current directory is: %CD% 1>&2

if %_DEBUG%==1 ( echo %_DEBUG_LABEL% "%__CL_CMD%" %__CL_OPTS% %__FILE_LOADS% 1>&2
) else if %_VERBOSE%==1 ( echo Generate executable "!_TARGET_FILE:%_ROOT_DIR%=!" ^(%_TOOLSE%^) 1>&2
)
call "%__CL_CMD%" %__CL_OPTS% %__FILE_LOADS%
if not %ERRORLEVEL%==0 (
    popd
    echo %_ERROR_LABEL% Failed to generate executable "!_TARGET_FILE:%_ROOT_DIR%=!" ^(%_TOOLSET%^) 1>&2
    set _EXITCODE=1
    goto :eof
)
popd
goto :eof

@rem input parameter: 1=target file 2,3,..=path (wildcards accepted)
@rem output parameter: _ACTION_REQUIRED
:action_required
set "__TARGET_FILE=%~1"

if not exist "%__TARGET_FILE%" set _ACTION_REQUIRED=1 & goto :eof

set __PATH_ARRAY=
set __PATH_ARRAY1=
:action_path
shift
set "__PATH=%~1"
if not defined __PATH goto action_next
set __PATH_ARRAY=%__PATH_ARRAY%,'%__PATH%'
set __PATH_ARRAY1=%__PATH_ARRAY1%,'!__PATH:%_ROOT_DIR%=!'
goto action_path

:action_next
set __TARGET_TIMESTAMP=00000000000000
for /f "usebackq" %%i in (`call "%_PWSH_CMD%" -c "gci -path '%__TARGET_FILE%' -ea Stop | select -last 1 -expandProperty LastWriteTime | Get-Date -uformat %%Y%%m%%d%%H%%M%%S" 2^>NUL`) do (
     set __TARGET_TIMESTAMP=%%i
)
set __SOURCE_TIMESTAMP=00000000000000
for /f "usebackq" %%i in (`call "%_PWSH_CMD%" -c "gci -recurse -path %__PATH_ARRAY:~1% -ea Stop | sort LastWriteTime | select -last 1 -expandProperty LastWriteTime | Get-Date -uformat %%Y%%m%%d%%H%%M%%S" 2^>NUL`) do (
    set __SOURCE_TIMESTAMP=%%i
)
call :newer %__SOURCE_TIMESTAMP% %__TARGET_TIMESTAMP%
set _ACTION_REQUIRED=%_NEWER%
if %_DEBUG%==1 (
    echo %_DEBUG_LABEL% %__TARGET_TIMESTAMP% Target : '%__TARGET_FILE%' 1>&2
    echo %_DEBUG_LABEL% %__SOURCE_TIMESTAMP% Sources: %__PATH_ARRAY:~1% 1>&2
    echo %_DEBUG_LABEL% _ACTION_REQUIRED=%_ACTION_REQUIRED% 1>&2
) else if %_VERBOSE%==1 if %_ACTION_REQUIRED%==0 if %__SOURCE_TIMESTAMP% gtr 0 (
    echo No action required ^("%__PATH_ARRAY1:~1%"^) 1>&2
)
goto :eof

@rem input parameters: %1=file timestamp 1, %2=file timestamp 2
@rem output parameter: _NEWER
:newer
set __TIMESTAMP1=%~1
set __TIMESTAMP2=%~2

set __DATE1=%__TIMESTAMP1:~0,8%
set __TIME1=%__TIMESTAMP1:~-6%

set __DATE2=%__TIMESTAMP2:~0,8%
set __TIME2=%__TIMESTAMP2:~-6%

if %__DATE1% gtr %__DATE2% ( set _NEWER=1
) else if %__DATE1% lss %__DATE2% ( set _NEWER=0
) else if %__TIME1% gtr %__TIME2% ( set _NEWER=1
) else ( set _NEWER=0
)
goto :eof

:evaluate
@rem main source file is loaded in last position;
@rem if present the other source files are loaded in alphabetic order based on their name
set __FILE_LOADS=--load "%_SOURCE_MAIN_FILE%"
for /f "delims=" %%f in ('dir /s /b /o-n "%_SOURCE_DIR%\*.lisp" ^| findstr /v "%_PROJECT_NAME%.lisp"') do (
    set __FILE_LOADS=--load "%%f" !__FILE_LOADS!
)
if %_TOOLSET%==ccl (
   set "__CL_CMD=%_CCL_CMD%"
   set __CL_OPTS=
) else (
   set "__CL_CMD=%_SBCL_CMD%"
   set __CL_OPTS=--noinform
)
if %_DEBUG%==1 ( echo %_DEBUG_LABEL% "%__CL_CMD%" %__CL_OPTS% %__FILE_LOADS% --eval "(main)" 1>&2
) else if %_VERBOSE%==1 ( echo Evaluate program "%_PROJECT_NAME%" ^(%_TOOLSET%^) 1>&2
)
call "%__CL_CMD%" %__CL_OPTS% %__FILE_LOADS% --eval "(main)"
if not %ERRORLEVEL%==0 (
    popd
    echo %_ERROR_LABEL% Failed to evaluate program "%_PROJECT_NAME%" ^(%_TOOLSET%^) 1>&2
    set _EXITCODE=1
    goto :eof
)
goto :eof

:run
if not exist "%_TARGET_FILE%" (
    echo %_ERROR_LABEL% Executable "!_TARGET_FILE:%_ROOT_DIR%=!" not found 1>&2
    set _EXITCODE=1
    goto :eof
)
if %_DEBUG%==1 ( echo %_DEBUG_LABEL% "%_TARGET_FILE%" 1>&2
) else if %_VERBOSE%==1 ( echo Execute "!_TARGET_FILE:%_ROOT_DIR%=!" 1>&2
)
call "%_TARGET_FILE%"
if not %ERRORLEVEL%==0 (
    echo %_ERROR_LABEL% Failed to execute "!_TARGET_FILE:%_ROOT_DIR%=!" ^(status: %ERRORLEVEL%^) 1>&2
    set _EXITCODE=1
    goto :eof
)
goto :eof

@rem #########################################################################
@rem ## Cleanups

:end
if %_DEBUG%==1 echo %_DEBUG_LABEL% _EXITCODE=%_EXITCODE% 1>&2
exit /b %_EXITCODE%
endlocal
