#!/usr/bin/env bash
#
# Copyright (c) 2018-2026 Stéphane Micheloud
#
# Licensed under the MIT License.
#

##############################################################################
## Subroutines

getHome() {
    local source="${BASH_SOURCE[0]}"
    while [[ -h "$source" ]]; do
        local linked="$(readlink "$source")"
        local dir="$( cd -P $(dirname "$source") && cd -P $(dirname "$linked") && pwd )"
        source="$dir/$(basename "$linked")"
    done
    ( cd -P "$(dirname "$source")" && pwd )
}

debug() {
    local DEBUG_LABEL="[46m[DEBUG][0m"
    [[ $DEBUG -eq 1 ]] && echo "$DEBUG_LABEL $1" 1>&2
}

warning() {
    local WARNING_LABEL="[46m[WARNING][0m"
    echo "$WARNING_LABEL $1" 1>&2
}

error() {
    local ERROR_LABEL="[91mError:[0m"
    echo "$ERROR_LABEL $1" 1>&2
}

# use variables EXITCODE, TIMER_START
cleanup() {
    [[ $1 =~ ^[0-1]$ ]] && EXITCODE=$1

    if [[ $TIMER -eq 1 ]]; then
        local TIMER_END=$(date +'%s')
        local duration=$((TIMER_END - TIMER_START))
        echo "Total execution time: $(date -d @$duration +'%H:%M:%S')" 1>&2
    fi
    debug "EXITCODE=$EXITCODE"
    exit $EXITCODE
}

args() {
    [[ $# -eq 0 ]] && HELP=1 && return 1

    for arg in "$@"; do
        case "$arg" in
        ## options
        -ccl)         TOOLSET=ccl ;;
        -debug)       DEBUG=1 ;;
        -help)        HELP=1 ;;
        -sbcl)        TOOLSET=sbcl ;;
        -timer)       TIMER=1 ;;
        -verbose)     VERBOSE=1 ;;
        -*)
            error "Unknown option \"$arg\""
            EXITCODE=1 && return 0
            ;;
        ## subcommands
        clean)   COMMANDS+=' clean' ;;
        compile) COMMANDS+=' compile' ;;
        eval)    COMMANDS+=' evaluate' ;;
        help)    HELP=1 ;;
        run)     COMMANDS+=' compile run' ;;
        *)
            error "Unknown subcommand \"$arg\""
            EXITCODE=1 && return 0
            ;;
        esac
    done
    debug "Properties : PROJECT_NAME=$PROJECT_NAME"
    debug "Options    : DEBUG=$DEBUG TIMER=$TIMER TOOLSET=$TOOLSET VERBOSE=$VERBOSE"
    debug "Subcommands: $COMMANDS"
    [[ -n "$CCL_HOME" ]] && debug "Variables  : CCL_HOME=$CCL_HOME"
    debug "Variables  : GIT_HOME=$GIT_HOME"
    debug "Variables  : SBCL_HOME=$SBCL_HOME"
    # See http://www.cyberciti.biz/faq/linux-unix-formatting-dates-for-display/
    [[ $TIMER -eq 1 ]] && TIMER_START=$(date +"%s")
}

help() {
    cat << EOS
Usage: $BASENAME { <option> | <subcommand> }

  Options:
    -ccl         use the Clozure CL compiler if available
    -debug       print commands executed by this script
    -sbcl        use the Steel Bank CL compiler (default)
    -timer       print total execution time
    -verbose     print progress messages

  Subcommands:
    clean        delete generated files
    compile      compile Common Lisp source files
    eval         evaluate the main function in source file
    help         print this help message
    run          execute the generated executable "$TARGET_NAME"
EOS
}

clean() {
    if [[ -d "$TARGET_DIR" ]]; then
        if [[ $DEBUG -eq 1 ]]; then
            debug "rm -rf \"$TARGET_DIR\""
        elif [[ $VERBOSE -eq 1 ]]; then
            echo "Delete directory \"${TARGET_DIR/$ROOT_DIR\//}\"" 1>&2
        fi
        rm -rf "$TARGET_DIR"
        [[ $? -eq 0 ]] || ( EXITCODE=1 && return 0 )
    fi
    if [[ -f "$ROOT_DIR/CMakeCache.txt" ]]; then
        rm -f "$ROOT_DIR/CMakeCache.txt"
        [[ $? -eq 0 ]] || ( EXITCODE=1 && return 0 )
    fi
}

compile() {
    [[ -d "$TARGET_SRC_DIR" ]] || mkdir -p "$TARGET_SRC_DIR"

    local is_required="$(action_required "$TARGET_FILE" "$SOURCE_DIR/" "*.lisp")"
    if [[ $is_required -eq 0 ]]; then return; fi

    local target_main_file="$TARGET_SRC_DIR/__main__.lisp"

    if [[ $DEBUG -eq 1 ]]; then
        debug "cp \"$SOURCE_MAIN_FILE\" \"$target_main_file\""
    elif [[ $VERBOSE -eq 1 ]]; then
        echo "Duplicate main source file before applying patch" 1>&2
    fi
    cp "$SOURCE_MAIN_FILE" "$target_main_file"
    local cl_cmd=
    local cl_opts=
    if [[ $TOOLSET = ccl ]]; then
        ## see https://stackoverflow.com/questions/833314/compiling-binaries-with-clozure-common-lisp
        (
            echo ""
            echo "; code appended to file \"${SOURCE_MAIN_FILE/$ROOT_DIR\//}\""
            echo "(ccl:save-application \"$TARGET_NAME\""
            echo "    :toplevel-function #'main"
            echo "    :prepend-kernel t)"
        ) >> "$target_main_file"
        cl_cmd="$CCL_CMD"
    else
        (
            echo ""
            echo "; code appended to file \"${SOURCE_MAIN_FILE/$ROOT_DIR\//}\""
            echo "(sb-ext:save-lisp-and-die \"$TARGET_NAME\""
            echo "    :toplevel #'main"
            echo "    :executable t)"
        ) >> "$target_main_file"
        cl_cmd="$SBCL_CMD"
        cl_opts="--noinform"
    fi
    ## main source file is loaded in last position;
    ## if present the other source files are loaded in alphabetic order based on their name
    local file_loads=("--load" "\"$target_main_file\"")
    for file in $(find $SOURCE_DIR/ -type f -name "*.lisp" ! -name "*$PROJECT_NAME.lisp" | sort -r); do
       file_loads=("--load" "$file" "${file_loads[@]}")
    done
    file_loads=$( IFS=$' '; echo "${file_loads[*]}" )

    pushd "$TARGET_DIR" 1>/dev/null
    [[ $DEBUG -eq 1 ]] && debug "Current directory is: $PWD" 1>&2

    if [[ $DEBUG -eq 1 ]]; then
        debug "\"$cl_cmd\" $cl_opts $file_loads"
    elif [[ $VERBOSE -eq 1 ]]; then
        echo "Generate executable \"${TARGET_FILE/$ROOT_DIR\//}\" ($TOOLSET)" 1>&2
    fi
    eval "\"$cl_cmd\" $cl_opts $file_loads"
    if [[ $? -ne 0 ]]; then
        popd 1>/dev/null
        error "Failed to executable \"${TARGET_FILE/$ROOT_DIR\//}\" ($TOOLSET)"
        cleanup 1
    fi
    popd 1>/dev/null
}

action_required() {
    local target_file=$1
    local search_path=$2
    local search_pattern=$3
    local source_file=
    for f in $(find "$search_path" -type f -name "$search_pattern" 2>/dev/null); do
        [[ $f -nt $source_file ]] && source_file=$f
    done
    if [[ -z "$source_file" ]]; then
        ## Do not compile if no source file
        echo 0
    elif [[ ! -f "$target_file" ]]; then
        ## Do compile if target file doesn't exist
        echo 1
    else
        ## Do compile if target file is older than most recent source file
        [[ $source_file -nt $target_file ]] && echo 1 || echo 0
    fi
}

evaluate() {
    ## main source file is loaded in last position;
    ## if present the other source files are loaded in alphabetic order based on their name
    local file_loads=("--load" "\"$SOURCE_MAIN_FILE\"")
    for file in $(find $SOURCE_DIR/ -type f -name "*.lisp" ! -name "*$PROJECT_NAME.lisp" | sort -r); do
       file_loads=("--load" "\"$file\"" "${file_loads[@]}")
    done
    file_loads=$( IFS=$' '; echo "${file_loads[*]}" )

    local cl_cmd="$SBCL_CMD"
    local cl_opts="--noinform"
    [[ $TOOLSET = ccl ]] && ( cl_cmd="$CCL_CMD"; cl_opts= )

    if [[ $DEBUG -eq 1 ]]; then
        debug "\"$cl_cmd\" $cl_opts $file_loads --eval \"(main)\""
    elif [[ $VERBOSE -eq 1 ]]; then
       echo "Evaluate program \"$PROJECT_NAME\" ($TOOLSET)"
    fi
    eval "\"$cl_cmd\" $cl_opts $file_loads --eval \"(main)\""
    if [[ $? -ne 0 ]]; then
        error "Failed to evaluate program \"$PROJECT_NAME\" ($TOOLSET)" 1>&2
        cleanup 1
    fi
}

mixed_path() {
    if [[ -x "$CYGPATH_CMD" ]]; then
        $CYGPATH_CMD -am $1
    elif [[ $(($mingw + $msys)) -gt 0 ]]; then
        echo $1 | sed 's|/|\\\\|g'
    else
        echo $1
    fi
}

run() {
    if [[ ! -f "$TARGET_FILE" ]]; then
        error "Executable \"${TARGET_FILE/$ROOT_DIR\//}\" not found"
        cleanup 1
    fi
    if [[ $DEBUG -eq 1 ]]; then
        debug "$TARGET_FILE"
    elif [[ $VERBOSE -eq 1 ]]; then
        echo "Execute \"${TARGET_FILE/$ROOT_DIR\//}\"" 1>&2
    fi
    eval "$TARGET_FILE"
    if [[ $? -ne 0 ]]; then
        error "Failed to execute \"${TARGET_FILE/$ROOT_DIR\//}\"" 1>&2
        cleanup 1
    fi
}

##############################################################################
## Environment setup

BASENAME=$(basename "${BASH_SOURCE[0]}")

EXITCODE=0

ROOT_DIR="$(getHome)"

SOURCE_DIR="$ROOT_DIR/src"
TARGET_DIR="$ROOT_DIR/target"
TARGET_SRC_DIR="$ROOT_DIR/target/src"

## We refrain from using `true` and `false` which are Bash commands
## (see https://man7.org/linux/man-pages/man1/false.1.html)
COMMANDS=
DEBUG=0
HELP=0
TIMER=0
TOOLSET=sbcl
VERBOSE=0

COLOR_START="[32m"
COLOR_END="[0m"

cygwin=0
mingw=0
msys=0
darwin=0
linux=0
case "$(uname -s)" in
    CYGWIN*) cygwin=1 ;;
    MINGW*)  mingw=1 ;;
    MSYS*)   msys=1 ;;
    Darwin*) darwin=1 ;;
    Linux*)  linux=1
esac
unset CYGPATH_CMD
PSEP=":"
TARGET_EXT=
if [[ $(($cygwin + $mingw + $msys)) -gt 0 ]]; then
    CYGPATH_CMD="$(which cygpath 2>/dev/null)"
    [[ -n "$CCL_HOME" ]] && CCL_HOME="$(mixed_path $CCL_HOME)"
    [[ -n "$GIT_HOME" ]] && GIT_HOME="$(mixed_path $GIT_HOME)"
    [[ -n "$SBCL_HOME" ]] && SBCL_HOME="$(mixed_path $SBCL_HOME)"
	PSEP=";"
    TARGET_EXT=".exe"
    CCL_CMD="$(mixed_path $CCL_HOME)/wx86cl64.exe"
    SBCL_CMD="$(mixed_path $SBCL_HOME)/sbcl.exe"
else
    CCL_CMD=wx86cl64
    SBCL_CMD=sbcl
fi

PROJECT_NAME="$(basename $ROOT_DIR)"
SOURCE_MAIN_FILE="$SOURCE_DIR/${PROJECT_NAME}.lisp"
TARGET_NAME="$PROJECT_NAME$TARGET_EXT"
TARGET_FILE="$TARGET_DIR/$TARGET_NAME"

args "$@"
[[ $EXITCODE -eq 0 ]] || cleanup 1

##############################################################################
## Main

[[ $HELP -eq 1 ]] && help && cleanup

for cmd in $COMMANDS; do
   $cmd
   [[ $EXITCODE -eq 0 ]] || cleanup 1
done
cleanup
