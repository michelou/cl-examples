ifndef CCL_HOME
$(warning Variable CCL_HOME is not set)
endif
ifndef SBCL_HOME
$(error Variable SBCL_HOME is not set)
endif

ifeq ($(OS),Windows_NT)
ifdef CCL_HOME
CCL        = $(subst \,/,$(CCL_HOME))/wx86cl64.exe
endif
SBCL       = $(subst \,/,$(SBCL_HOME))/sbcl.exe
PSEP       = ;
TARGET_EXT = .exe
## $(MSYS_HOME)\usr\bin\{cp.exe, make.exe, wget.exe}
CP         = /usr/bin/cp.exe
ECHO       = /usr/bin/echo.exe
FIND       = /usr/bin/find.exe
MKDIR      = /usr/bin/mkdir.exe
RM         = /usr/bin/rm.exe
TOUCH      = /usr/bin/touch.exe
else
SBCL       = $(SBCL_HOME)/sbcl
PSEP       = :
TARGET_EXT =
CP         = cp
ECHO       = echo
FIND       = find
MKDIR      = mkdir
MVN        = mvn
RM         = rm
TOUCH      = touch
endif
