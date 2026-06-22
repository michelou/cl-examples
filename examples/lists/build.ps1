#!/usr/bin/env pwsh
#
# Copyright (c) 2018-2026 Stéphane Micheloud
#
# Licensed under the MIT License.
#

## https://powershellisfun.com/2023/04/24/using-the-requires-statement-in-powershell/
#Requires -Version 5.1

## only for interactive debugging !
$DEBUG = $false

#########################################################################
## Environment setup

$EXITCODE = 0

$EXE = ""
if ($PSVersionTable.PSVersion -lt "6.0" -or $IsWindows) {
  # Fix case when both the Windows and Linux builds of this program
  # are installed in the same directory.
  $EXE = '.exe'
}

$BASENAME = (Get-Item $PSScriptRoot).Basename
$ROOT_DIR = $PSScriptRoot
$PATH_SEP = [IO.Path]::PathSeparator
$SEP      = [IO.Path]::DirectorySeparatorChar

$SOURCE_DIR     = Join-Path -Path $ROOT_DIR   -ChildPath 'src'
$TARGET_DIR     = Join-Path -Path $ROOT_DIR   -ChildPath 'target'
$TARGET_SRC_DIR = Join-Path -Path $TARGET_DIR -ChildPath 'src'

$CCL_CMD = $Env:CCL_HOME + $SEP + 'wx86cl64' + $EXE
if (! (Test-Path -PathType Leaf -Path $CCL_CMD)) {
    $CCL_CMD = $null
}
$SBCL_CMD = $Env:SBCL_HOME + $SEP + 'sbcl' + $EXE
if (! (Test-Path -PathType Leaf -Path $SBCL_CMD)) {
    Write-Error "Steel Bank CL compiler not found (check variable ""SBCL_HOME"")"
    Cleanup 1
}

$PS_VERSION = $PSVersionTable.PSVersion.ToString() 
$PROJECT_NAME = $BASENAME
$PROJECT_VERSION = '1.0-SNAPSHOT'

$SOURCE_MAIN_FILE = $SOURCE_DIR + $SEP + $PROJECT_NAME + '.lisp'
$TARGET_NAME = $PROJECT_NAME + $EXE
$TARGET_FILE = $TARGET_DIR + $SEP + $TARGET_NAME

#########################################################################
## Script arguments

$COMMANDS = @()

## Possible values: SilentlyContinue, Stop, Continue, Inquire, Ignore, Suspend
$DebugPreference   = 'SilentlyContinue'
$VerbosePreference = 'SilentlyContinue'
$WarningPreference = 'Continue'

$TIMER = $false
$TOOLSET = 'sbcl'
$VERBOSE = $false
$N = 0
foreach ($ARG in $args) {
    if ($ARG.StartsWith('-')) {
        ## option
        if ($ARG -ieq '-ccl') { $TOOLSET = 'ccl'
        } elseif ($ARG -ieq '-debug') { $DEBUG = $true; $DebugPreference='Continue'
        } elseif ($ARG -ieq '-help'   ) { $COMMANDS = 'Print-Help'
        } elseif ($ARG -ieq '-sbcl'   ) { $TOOLSET = 'sbcl'
        } elseif ($ARG -ieq '-timer'  ) { $TIMER = $true
        } elseif ($ARG -ieq '-verbose') { $VERBOSE = $true; $VerbosePreference = 'Continue'
        } else {
            Write-Error "Unknown option ""$ARG"""
            $EXITCODE = 1
            break
        }
    } else {
        ## subcommand
        if ($ARG -ieq 'clean') { $COMMANDS += 'Clean'
        } elseif ($ARG -ieq 'compile') { $COMMANDS += 'Compile'
        } elseif ($ARG -ieq 'eval') { $COMMANDS += 'Evaluate'
        } elseif ($ARG -ieq 'help') { $COMMANDS = 'Print-Help'
        } elseif ($ARG -ieq 'run' ) { $COMMANDS += 'Compile', 'Run'
        } else {
            Write-Error "Unknown subcommand ""$ARG"""
            $EXITCODE = 1
            break
        }
        $N++
    }
}
if ($TOOLSET -eq 'ccl' -and ! $CCL_CMD) {
    Write-Warning "Clozure CL command not found ^(use SBCL instead^)"
    $TOOLSET = 'sbcl'
}
Write-Debug "Properties : PROJECT_NAME=$PROJECT_NAME PROJECT_VERSION=$PROJECT_VERSION PS_VERSION=$PS_VERSION"
Write-Debug "Options    : DEBUG=$DEBUG TIMER=$TIMER TOOLSET=$TOOLSET VERBOSE=$VERBOSE"
Write-Debug "Subcommands: $COMMANDS"
if ($CCL_CMD) { Write-Debug "Variables  : ""CCL_HOME=$Env:CCL_HOME""" }
Write-Debug "Variables  : ""GIT_HOME=$Env:GIT_HOME"""
Write-Debug "Variables  : ""SBCL_HOME=$Env:SBCL_HOME"""

if ($TIMER) { $TIMER_START = Get-Date }

#########################################################################
## Subroutines

function Main
{
    foreach($COMMAND in $COMMANDS) {
        &$COMMAND
        if ($EXITCODE -ne 0) { exit $EXITCODE }
    }
    if ($TIMER) {
        $DURATION = New-TimeSpan -Start $TIMER_START -End (Get-Date)
        Write-Output "Total execution time: $DURATION"
    }
    Cleanup $EXITCODE
}

function Print-Help
{
    Write-Output "Usage: $BASENAME { <option> | <subcommand> }"
    Write-Output ""
    Write-Output "   Options:"
    Write-Output "     -ccl        use the Clozure CL compiler if available"
    Write-Output "     -debug      print commands executed by this script"
    Write-Output "     -sbcl       use the Steel Bank CL compiler (default)"
    Write-Output "     -timer      print total execution time"
    Write-Output "     -verbose    print progress messages"
    Write-Output ""
    Write-Output "   Subcommands:"
    Write-Output "     clean       delete generated files"
    Write-Output "     compile     compile Common Lisp source files"
    Write-Output "     eval        evaluate the main function in source files"
    Write-Output "     help        print this help message"
    Write-Output "     run         execute main program ""$TARGET_NAME"""
}

function Clean
{
    Delete-Directory -DirPath $TARGET_DIR
}

function Delete-Directory
{
    param (
        [string] $DirPath
    )
    if (Test-Path -PathType Container -Path $DirPath) {
        Write-Debug "[System.IO.Directory]::Delete('$DirPath', $true)"
        Write-Verbose "Delete directory ""$($DirPath.Replace($ROOT_DIR + $SEP, ''))"""
        try {
            #[System.IO.Directory]::Delete($DirPath, $true)
            Remove-Item -Path $DirPath -Force -Recurse
        } catch {
            Write-Error "Failed to delete directory ""$($DirPath.Replace($ROOT_DIR + $SEP, ''))"""
            $EXITCODE = 1
            return
        }
    }
}

function Compile
{
    if (! (Test-Path -PathType Container -Path $TARGET_SRC_DIR)) {
        $_ = New-Item -ItemType Directory -Path $TARGET_SRC_DIR
    }
    if (! (Test-Action-Required -FilePath "$TARGET_FILE" -DirPath "$SOURCE_DIR" -Pattern '*.lisp')) {
       return
    }
    $TARGET_MAIN_FILE = $TARGET_SRC_DIR + $SEP + '__main__.lisp'

    Write-Debug "Copy-Item -Path ""$SOURCE_MAIN_FILE"" -Destination ""$TARGET_MAIN_FILE"""
    Write-Verbose "Duplicate main source file before applying patch"
    Copy-Item -Force -Path "$SOURCE_MAIN_FILE" -Destination "$TARGET_MAIN_FILE"
    if ($TOOLSET -eq 'ccl') {
        Add-Content -Path "$TARGET_MAIN_FILE" -Value @"

; code appended to file "$($SOURCE_MAIN_FILE.Replace($ROOT_DIR, ''))"
(ccl:save-application "$TARGET_NAME"
    :toplevel-function #'main
    :prepend-kernel t)
"@
        $CL_CMD = $CCL_CMD
        $CL_OPTS = @()
    } else {
        Add-Content -Path "$TARGET_MAIN_FILE" -Value @"

; code appended to file "$($SOURCE_MAIN_FILE.Replace($ROOT_DIR, ''))"
(sb-ext:save-lisp-and-die "$TARGET_NAME"
    :toplevel #'main
    :executable t)
"@
        $CL_CMD = $SBCL_CMD
        $CL_OPTS = @('--noinform')
    }
    ## main source file is loaded in last position;
    ## if present the other source files are loaded in alphabetic order based on their name
    $FILE_LOADS = @('--load', "$TARGET_MAIN_FILE")
    Get-ChildItem -Path $SOURCE_DIR -recurse -exclude $('*' + $PROJECT_NAME + '.lisp') | Sort-Object -Descending | Foreach-Object {
        $FILE_LOADS = $(@('--load', "$_"); $FILE_LOADS)
    }
    pushd "$TARGET_DIR"
    Write-Debug "Current directory is: $((Get-Item .).FullName)"

    Write-Debug """$CL_CMD"" $CL_OPTS $FILE_LOADS"
    Write-Verbose "Generate program ""$($TARGET_FILE.Replace($ROOT_DIR, ''))"" ($TOOLSET)"
    &"$CL_CMD" $CL_OPTS $FILE_LOADS
    if ($LASTEXITCODE -ne 0) {
        popd
        Write-Error "Failed to generate program ""$($TARGET_FILE.Replace($ROOT_DIR, ''))"" ($TOOLSET)"
        Cleanup 1
    }
    popd
}

function Test-Action-Required
{
    param (
        [string] $FilePath,
        [string] $DirPath,
        [string] $Pattern
    )
    $REQUIRED = $false
    if (Test-Path -PathType Container -Path $DirPath) {
        if (Test-Path -PathType Leaf -Path $FilePath) {
            $FILE_LAST_TIME = (Get-Item $FilePath).LastWriteTime
            $DIR_LAST_TIME = (Get-ChildItem -Path $DirPath -Include $Pattern -Recurse | Sort LastWriteTime | Select -Last 1).LastWriteTime
            $REQUIRED = $FILE_LAST_TIME -lt $DIR_LAST_TIME
        } else {
            $REQUIRED = $true
        }
    }
    Write-Debug "REQUIRED=$REQUIRED ($Pattern)"
    return $REQUIRED
}

function Evaluate
{
    ## main source file is loaded in last position;
    ## if present the other source files are loaded in alphabetic order based on their name
    $FILE_LOADS = @('--load', "$SOURCE_MAIN_FILE")
    Get-ChildItem -Path $SOURCE_DIR -recurse -exclude $($PROJECT_NAME + '.lisp') | Sort-Object -Descending | Foreach-Object {
        $FILE_LOADS = $(@('--load', "$_"); $FILE_LOADS)
    }
    if ($TOOLSET -eq 'ccl') {
        $CL_CMD =  $CCL_CMD
        $CL_OPTS = @()
    } else {
        $CL_CMD  = $SBCL_CMD
        $CL_OPTS = @('--noinform')
    }
    Write-Debug """$CL_CMD"" $CL_OPTS $FILE_LOADS --eval ""(main)"""
    Write-Verbose "Evaluate program ""$PROJECT_NAME"" ($TOOLSET)"
    &"$CL_CMD" $CL_OPTS $FILE_LOADS --eval "(main)"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to evaluate program ""$PROJECT_NAME"" ($TOOLSET)"
        Cleanup 1
    }
}

function Run
{
    if (! (Test-Path -PathType Leaf -Path $TARGET_FILE)) {
        Write-Error "Common Lisp program ""$TARGET_NAME"" not found"
    }
    Write-Debug "$TARGET_FILE"
    Write-Verbose "Execute Common Lisp program ""$($TARGET_FILE.Replace($ROOT_DIR + $SEP, ''))"""
    &"$TARGET_FILE"
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to execute Common Lisp program ""$($TARGET_FILE.Replace($ROOT_DIR + $SEP, ''))"""
        Cleanup 1
    }
}

function Cleanup
{
    param (
        [int] $ExitCode
    )
    Write-Debug "ExitCode=$ExitCode"
    exit $ExitCode
}

#########################################################################
## Entry-point

Main
