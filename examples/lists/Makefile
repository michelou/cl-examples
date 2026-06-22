##
## Copyright (c) 2018-2026 Stéphane Micheloud
##
## Licensed under the MIT License.
##
##############################################################################

DEBUG ?= 0
VERBOSE ?= 0

TOOLSET ?= sbcl

include ../Makefile.inc

SOURCE_DIR     = src
TARGET_DIR     = target
TARGET_SRC_DIR = $(TARGET_DIR)/src

##############################################################################
## main rules

SOURCES = $(shell $(FIND) "$(SOURCE_DIR)" -type f -name "*.lisp")

PROJECT_NAME     = lists
SOURCE_MAIN_FILE = $(SOURCE_DIR)/$(PROJECT_NAME).lisp
TARGET_NAME      = $(PROJECT_NAME)$(TARGET_EXT)
TARGET_FILE      = $(TARGET_DIR)/$(TARGET_NAME)
TARGET_MAIN_FILE = $(TARGET_SRC_DIR)/__main__.lisp

## see https://stackoverflow.com/questions/833314/compiling-binaries-with-clozure-common-lisp
CCL_PATCH = "(ccl:save-application \"$(TARGET_FILE)\"\
    :toplevel-function \#'main\
    :prepend-kernel t)"

SBCL_PATCH = "(sb-ext:save-lisp-and-die \"$(TARGET_FILE)\"\
    :toplevel \#'main\
    :executable t)"

all: build run

clean:
	"$(RM)" -rf "$(TARGET_DIR)"

build: $(TARGET_FILE)

$(TARGET_FILE): $(SOURCES)
	[[ -d "$(TARGET_SRC_DIR)" ]] || "$(MKDIR)" -p "$(TARGET_SRC_DIR)"

	$(eval TARGET_MAIN_FILE := $(TARGET_SRC_DIR)/__main__.lisp)
	@$(CP) "$(SOURCE_MAIN_FILE)" "$(TARGET_MAIN_FILE)"
	$(ECHO) '' >> $(TARGET_MAIN_FILE)  # empty line
	$(ECHO) "; code appended to file \"$(subst $(shell pwd),,$(SOURCE_MAIN_FILE))"\" >> $(TARGET_MAIN_FILE)
ifeq ($(TOOLSET),ccl)
	$(ECHO) $(CCL_PATCH) >> $(TARGET_MAIN_FILE)
	$(eval CL := $(CCL))
	$(eval CL_OPTS := )
else
	$(ECHO) $(SBCL_PATCH) >> $(TARGET_MAIN_FILE)
	$(eval CL := $(SBCL))
	$(eval CL_OPTS := --noinform)
endif
	$(eval FILE_LOADS := --load "$(SOURCE_DIR)/defs.lisp" --load "$(TARGET_MAIN_FILE)")
	$(CL) $(CL_OPTS) $(FILE_LOADS)

eval:
ifeq ($(TOOLSET),ccl)
	$(eval CL := $(CCL))
	$(eval CL_OPTS := )
else
	$(eval CL := $(SBCL))
	$(eval CL_OPTS := --noinform)
endif
    ## main source file is loaded in last position;
    ## if present the other source files are loaded in alphabetic order based on their name
	$(eval FILE_LOADS := --load "$(SOURCE_DIR)/defs.lisp" --load "$(SOURCE_MAIN_FILE)")
	$(CL) $(CL_OPTS) $(FILE_LOADS) --eval "(main)"

run: build
	@[ -f "$(TARGET_FILE)" ] || ( echo "Target file not found"; exit 1 )
	exec "$(TARGET_FILE)"

help:
	@$(ECHO) "Usage: make all|build|clean|help|lint|run|test"
	@$(ECHO) ""
	@$(ECHO) "  Subcommands:"
	@$(ECHO) "    all    alias for build"
	@$(ECHO) "    build  compile Common Lisp source files"
	@$(ECHO) "    clean  delete generated files"
	@$(ECHO) "    eval   evalutes the main function in Common Lisp source files"
	@$(ECHO) "    help   print this help message"
	@$(ECHO) "    run    execute Java main program \"$(TARGET_NAME)\""

##############################################################################
## phony

.PHONY: all build clean help run

.SUFFIXES:
.SUFFIXES: .exe .lisp
