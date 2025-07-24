#
# ioq3 Makefile
# Modified for Illusion Arena
# GNU Make required
#

COMPILE_PLATFORM=$(shell uname|sed -e s/_.*//|tr '[:upper:]' '[:lower:]')

COMPILE_ARCH=$(shell uname -m | sed -e s/i.86/i386/)

ifeq ($(COMPILE_PLATFORM),sunos)
  # Solaris uname and GNU uname differ
  COMPILE_ARCH=$(shell uname -p | sed -e s/i.86/i386/)
endif
ifeq ($(COMPILE_PLATFORM),darwin)
  # Apple does some things a little differently...
  COMPILE_ARCH=$(shell uname -p | sed -e s/i.86/i386/)
endif

ifeq ($(COMPILE_PLATFORM),mingw32)
  ifeq ($(COMPILE_ARCH),i386)
    COMPILE_ARCH=x86
  endif
endif

#############################################################################
#
# If you require a different configuration from the defaults below, create a
# new file named "Makefile.local" in the same directory as this file and define
# your parameters there. This allows you to change configuration without
# causing problems with keeping up to date with the repository.
#
#############################################################################
-include Makefile.local

ifndef PLATFORM
PLATFORM=$(COMPILE_PLATFORM)
endif
export PLATFORM

ifeq ($(COMPILE_ARCH),powerpc)
  COMPILE_ARCH=ppc
endif
ifeq ($(COMPILE_ARCH),powerpc64)
  COMPILE_ARCH=ppc64
endif
ifeq ($(COMPILE_ARCH),amd64)
  COMPILE_ARCH=x86_64
endif

ifndef ARCH
ARCH=$(COMPILE_ARCH)
endif
export ARCH

ifneq ($(PLATFORM),$(COMPILE_PLATFORM))
  CROSS_COMPILING=1
else
  CROSS_COMPILING=0

  ifneq ($(ARCH),$(COMPILE_ARCH))
    CROSS_COMPILING=1
  endif
endif
export CROSS_COMPILING

ifndef COPYDIR
COPYDIR="/usr/local/games/illusion"
endif

ifndef MOUNT_DIR
MOUNT_DIR=code
endif

ifndef BUILD_DIR
BUILD_DIR=build
endif

ifndef GENERATE_DEPENDENCIES
GENERATE_DEPENDENCIES=1
endif

ifneq ($(MOD_OA),1)
  ifneq ($(MOD_Q3),0)
    MOD_Q3=1
    CFLAGS+=-DMOD_Q3A    
  endif   
endif

ifneq ($(MOD_Q3),1)
  ifneq ($(MOD_OA),0)
   MOD_OA=1
   CFLAGS+=-DMOD_OA
  endif
endif

#############################################################################

BD=$(BUILD_DIR)/debug-$(PLATFORM)-$(ARCH)
BR=$(BUILD_DIR)/release-$(PLATFORM)-$(ARCH)
RDIR=$(MOUNT_DIR)/renderer
CMDIR=$(MOUNT_DIR)/qcommon
GDIR=$(MOUNT_DIR)/game
CGDIR=$(MOUNT_DIR)/cgame
BLIBDIR=$(MOUNT_DIR)/botlib
UIDIR=$(MOUNT_DIR)/ui
Q3UIDIR=$(MOUNT_DIR)/q3_ui
Q3ASMDIR=$(MOUNT_DIR)/tools/asm
LBURGDIR=$(MOUNT_DIR)/tools/lcc/lburg
Q3CPPDIR=$(MOUNT_DIR)/tools/lcc/cpp
Q3LCCETCDIR=$(MOUNT_DIR)/tools/lcc/etc
Q3LCCSRCDIR=$(MOUNT_DIR)/tools/lcc/src
TEMPDIR=/tmp

# version info
VERSION=$(shell git rev-list --all | wc -l)


#############################################################################
# SETUP AND BUILD -- LINUX
#############################################################################

## Defaults
LIB=lib

INSTALL=install
MKDIR=mkdir

ifeq ($(PLATFORM),linux)

  ifeq ($(ARCH),alpha)
    ARCH=axp
  else
  ifeq ($(ARCH),x86_64)
    LIB=lib64
  else
  ifeq ($(ARCH),ppc64)
    LIB=lib64
  else
  ifeq ($(ARCH),s390x)
    LIB=lib64
  endif
  endif
  endif
  endif

  BASE_CFLAGS = -Wall -fno-strict-aliasing -Wimplicit -Wstrict-prototypes -pipe -DUSE_ICON

  OPTIMIZE = -O3 -ffast-math -funroll-loops -fomit-frame-pointer

  ifeq ($(ARCH),x86_64)
    OPTIMIZE = -O3 -fomit-frame-pointer -ffast-math -funroll-loops \
      -falign-loops=2 -falign-jumps=2 -falign-functions=2 \
      -fstrength-reduce
    # experimental x86_64 jit compiler! you need GNU as
    HAVE_VM_COMPILED = true
  else
  ifeq ($(ARCH),i386)
    OPTIMIZE = -O3 -march=i586 -fomit-frame-pointer -ffast-math \
      -funroll-loops -falign-loops=2 -falign-jumps=2 \
      -falign-functions=2 -fstrength-reduce
    HAVE_VM_COMPILED=true
  else
  ifeq ($(ARCH),ppc)
    BASE_CFLAGS += -maltivec
    HAVE_VM_COMPILED=true
  endif
  ifeq ($(ARCH),ppc64)
    BASE_CFLAGS += -maltivec
    HAVE_VM_COMPILED=true
  endif
  ifeq ($(ARCH),sparc)
    OPTIMIZE += -mtune=ultrasparc3 -mv8plus
    HAVE_VM_COMPILED=true
  endif
  endif
  endif

  ifneq ($(HAVE_VM_COMPILED),true)
    BASE_CFLAGS += -DNO_VM_COMPILED
  endif

  SHLIBEXT=so
  SHLIBCFLAGS=-fPIC
  SHLIBLDFLAGS=-shared $(LDFLAGS)

  THREAD_LIBS=-lpthread
  LIBS=-ldl -lm

  ifeq ($(ARCH),i386)
    # linux32 make ...
    BASE_CFLAGS += -m32
  else
  ifeq ($(ARCH),ppc64)
    BASE_CFLAGS += -m64
  endif
  endif

  DEBUG_CFLAGS = $(BASE_CFLAGS) -g -O0
  RELEASE_CFLAGS=$(BASE_CFLAGS) -DNDEBUG $(OPTIMIZE)

else # ifeq Linux

#############################################################################
# SETUP AND BUILD -- MAC OS X
#############################################################################

ifeq ($(PLATFORM),darwin)
  HAVE_VM_COMPILED=true
  CLIENT_LIBS=
  OPTIMIZE=
  
  BASE_CFLAGS = -Wall -Wimplicit -Wstrict-prototypes

  ifeq ($(ARCH),ppc)
    BASE_CFLAGS += -faltivec
    OPTIMIZE += -O3
  endif
  ifeq ($(ARCH),ppc64)
    BASE_CFLAGS += -faltivec
  endif
  ifeq ($(ARCH),i386)
    OPTIMIZE += -march=prescott -mfpmath=sse
    # x86 vm will crash without -mstackrealign since MMX instructions will be
    # used no matter what and they corrupt the frame pointer in VM calls
    BASE_CFLAGS += -mstackrealign
  endif

  BASE_CFLAGS += -fno-strict-aliasing -DMACOS_X -fno-common -pipe
  BASE_CFLAGS += -D_THREAD_SAFE=1

  OPTIMIZE += -ffast-math -falign-loops=16

  ifneq ($(HAVE_VM_COMPILED),true)
    BASE_CFLAGS += -DNO_VM_COMPILED
  endif

  DEBUG_CFLAGS = $(BASE_CFLAGS) -g -O0
  RELEASE_CFLAGS=$(BASE_CFLAGS) -DNDEBUG $(OPTIMIZE)

  SHLIBEXT=dylib
  SHLIBCFLAGS=-fPIC -fno-common
  SHLIBLDFLAGS=-dynamiclib $(LDFLAGS)

  NOTSHLIBCFLAGS=-mdynamic-no-pic

  TOOLS_CFLAGS += -DMACOS_X

else # ifeq darwin


#############################################################################
# SETUP AND BUILD -- MINGW32
#############################################################################

ifeq ($(PLATFORM),mingw32)

  ifndef WINDRES
    WINDRES=windres
  endif

  ARCH=x86

  BASE_CFLAGS = -Wall -fno-strict-aliasing -Wimplicit -Wstrict-prototypes -DUSE_ICON

  # In the absence of wspiapi.h, require Windows XP or later
  ifeq ($(shell test -e $(CMDIR)/wspiapi.h; echo $$?),1)
    BASE_CFLAGS += -DWINVER=0x501
  endif

  OPTIMIZE = -O3 -march=i586 -fno-omit-frame-pointer -ffast-math \
    -falign-loops=2 -funroll-loops -falign-jumps=2 -falign-functions=2 \
    -fstrength-reduce

  HAVE_VM_COMPILED = true

  SHLIBEXT=dll
  SHLIBCFLAGS=
  SHLIBLDFLAGS=-shared $(LDFLAGS)

  LIBS= -lws2_32 -lwinmm
  CLIENT_LDFLAGS = -mwindows
  CLIENT_LIBS = -lgdi32 -lole32 -lopengl32

  ifeq ($(ARCH),x86)
    # build 32bit
    BASE_CFLAGS += -m32
  endif

  DEBUG_CFLAGS=$(BASE_CFLAGS) -g -O0
  RELEASE_CFLAGS=$(BASE_CFLAGS) -DNDEBUG $(OPTIMIZE)

else # ifeq mingw32

#############################################################################
# SETUP AND BUILD -- FREEBSD
#############################################################################

ifeq ($(PLATFORM),freebsd)

  ifneq (,$(findstring alpha,$(shell uname -m)))
    ARCH=axp
  else #default to i386
    ARCH=i386
  endif #alpha test


  BASE_CFLAGS = -Wall -fno-strict-aliasing -Wimplicit -Wstrict-prototypes \
    -DUSE_ICON $(SDL_CFLAGS)

  ifeq ($(ARCH),axp)
    BASE_CFLAGS += -DNO_VM_COMPILED
    RELEASE_CFLAGS=$(BASE_CFLAGS) -DNDEBUG -O3 -ffast-math -funroll-loops \
      -fomit-frame-pointer -fexpensive-optimizations
  else
  ifeq ($(ARCH),i386)
    RELEASE_CFLAGS=$(BASE_CFLAGS) -DNDEBUG -O3 -mtune=pentiumpro \
      -march=pentium -fomit-frame-pointer -pipe -ffast-math \
      -falign-loops=2 -falign-jumps=2 -falign-functions=2 \
      -funroll-loops -fstrength-reduce
    HAVE_VM_COMPILED=true
  else
    BASE_CFLAGS += -DNO_VM_COMPILED
  endif
  endif

  DEBUG_CFLAGS=$(BASE_CFLAGS) -g

  SHLIBEXT=so
  SHLIBCFLAGS=-fPIC
  SHLIBLDFLAGS=-shared $(LDFLAGS)

  THREAD_LIBS=-lpthread
  # don't need -ldl (FreeBSD)
  LIBS=-lm

else # ifeq freebsd

#############################################################################
# SETUP AND BUILD -- OPENBSD
#############################################################################

ifeq ($(PLATFORM),openbsd)

  #default to i386, no tests done on anything else
  ARCH=i386

  BASE_CFLAGS = -Wall -fno-strict-aliasing -Wimplicit -Wstrict-prototypes -DUSE_ICON $(SDL_CFLAGS)

  BASE_CFLAGS += -DNO_VM_COMPILED -I/usr/X11R6/include -I/usr/local/include
  RELEASE_CFLAGS=$(BASE_CFLAGS) -DNDEBUG -O3 \
    -march=pentium -fomit-frame-pointer -pipe -ffast-math \
    -falign-loops=2 -falign-jumps=2 -falign-functions=2 \
    -funroll-loops -fstrength-reduce
  HAVE_VM_COMPILED=false

  DEBUG_CFLAGS=$(BASE_CFLAGS) -g

  SHLIBEXT=so
  SHLIBCFLAGS=-fPIC
  SHLIBLDFLAGS=-shared $(LDFLAGS)

  THREAD_LIBS=-lpthread
  LIBS=-lm

else # ifeq openbsd

#############################################################################
# SETUP AND BUILD -- NETBSD
#############################################################################

ifeq ($(PLATFORM),netbsd)

  ifeq ($(shell uname -m),i386)
    ARCH=i386
  endif
  ifeq ($(shell uname -m),amd64)
   ARCH=x86_64
  endif
  
  LIBS=-lm
  SHLIBEXT=so
  SHLIBCFLAGS=-fPIC
  SHLIBLDFLAGS=-shared $(LDFLAGS)
  THREAD_LIBS=-lpthread

  BASE_CFLAGS = -Wall -fno-strict-aliasing -Wimplicit -Wstrict-prototypes

  DEBUG_CFLAGS=$(BASE_CFLAGS) -g

else # ifeq netbsd

#############################################################################
# SETUP AND BUILD -- IRIX
#############################################################################

ifeq ($(PLATFORM),irix64)

  ARCH=mips  #default to MIPS

  CC = c99
  MKDIR = mkdir -p

  BASE_CFLAGS=-Dstricmp=strcasecmp -Xcpluscomm -woff 1185 \
    -I. -I$(ROOT)/usr/include -DNO_VM_COMPILED
  RELEASE_CFLAGS=$(BASE_CFLAGS) -O3
  DEBUG_CFLAGS=$(BASE_CFLAGS) -g

  SHLIBEXT=so
  SHLIBCFLAGS=
  SHLIBLDFLAGS=-shared

  LIBS=-ldl -lm -lgen
  # FIXME: The X libraries probably aren't necessary?
  CLIENT_LIBS=-L/usr/X11/$(LIB) $(SDL_LIBS) -lGL \
    -lX11 -lXext -lm

else # ifeq IRIX

#############################################################################
# SETUP AND BUILD -- SunOS
#############################################################################

ifeq ($(PLATFORM),sunos)

  CC=gcc
  INSTALL=ginstall
  MKDIR=gmkdir
  COPYDIR="/usr/local/share/games/illusion"

  ifneq (,$(findstring i86pc,$(shell uname -m)))
    ARCH=i386
  else #default to sparc
    ARCH=sparc
  endif

  ifneq ($(ARCH),i386)
    ifneq ($(ARCH),sparc)
      $(error arch $(ARCH) is currently not supported)
    endif
  endif

  BASE_CFLAGS = -Wall -fno-strict-aliasing -Wimplicit -Wstrict-prototypes -pipe -DUSE_ICON

  OPTIMIZE = -O3 -ffast-math -funroll-loops

  ifeq ($(ARCH),sparc)
    OPTIMIZE = -O3 -ffast-math \
      -fstrength-reduce -falign-functions=2 \
      -mtune=ultrasparc3 -mv8plus -mno-faster-structs \
      -funroll-loops #-mv8plus
    HAVE_VM_COMPILED=true
  else
  ifeq ($(ARCH),i386)
    OPTIMIZE = -O3 -march=i586 -fomit-frame-pointer -ffast-math \
      -funroll-loops -falign-loops=2 -falign-jumps=2 \
      -falign-functions=2 -fstrength-reduce
    HAVE_VM_COMPILED=true
    BASE_CFLAGS += -m32
    BASE_CFLAGS += -I/usr/X11/include/NVIDIA
    CLIENT_LDFLAGS += -L/usr/X11/lib/NVIDIA -R/usr/X11/lib/NVIDIA
  endif
  endif

  ifneq ($(HAVE_VM_COMPILED),true)
    BASE_CFLAGS += -DNO_VM_COMPILED
  endif

  DEBUG_CFLAGS = $(BASE_CFLAGS) -ggdb -O0

  RELEASE_CFLAGS=$(BASE_CFLAGS) -DNDEBUG $(OPTIMIZE)

  SHLIBEXT=so
  SHLIBCFLAGS=-fPIC
  SHLIBLDFLAGS=-shared $(LDFLAGS)

  THREAD_LIBS=-lpthread
  LIBS=-lsocket -lnsl -ldl -lm

  BOTCFLAGS=-O0

else # ifeq sunos

#############################################################################
# SETUP AND BUILD -- GENERIC
#############################################################################
  BASE_CFLAGS=-DNO_VM_COMPILED
  DEBUG_CFLAGS=$(BASE_CFLAGS) -g
  RELEASE_CFLAGS=$(BASE_CFLAGS) -DNDEBUG -O3

  SHLIBEXT=so
  SHLIBCFLAGS=-fPIC
  SHLIBLDFLAGS=-shared

endif #Linux
endif #darwin
endif #mingw32
endif #FreeBSD
endif #OpenBSD
endif #NetBSD
endif #IRIX
endif #SunOS

TARGETS =

ifneq ($(BUILD_GAME_SO),0)
  TARGETS += \
    $(B)/baseia/cgame$(ARCH).$(SHLIBEXT) \
    $(B)/baseia/qagame$(ARCH).$(SHLIBEXT) \
    $(B)/baseia/ui$(ARCH).$(SHLIBEXT)
endif

ifneq ($(BUILD_GAME_QVM),0)
  ifneq ($(CROSS_COMPILING),1)
    TARGETS += \
      $(B)/baseia/vm/cgame.qvm \
      $(B)/baseia/vm/qagame.qvm \
      $(B)/baseia/vm/ui.qvm
  endif
endif

ifneq ($(BUILD_GAME_PK3),0)
  TARGETS += $(B)/baseia/pak0.pk3
endif

ifdef DEFAULT_BASEDIR
  BASE_CFLAGS += -DDEFAULT_BASEDIR=\\\"$(DEFAULT_BASEDIR)\\\"
endif

ifeq ($(GENERATE_DEPENDENCIES),1)
  DEPEND_CFLAGS = -MMD
else
  DEPEND_CFLAGS =
endif

BASE_CFLAGS += -DPRODUCT_VERSION=\\\"$(VERSION)\\\"

ifeq ($(V),1)
echo_cmd=@:
Q=
else
echo_cmd=@echo
Q=@
endif

ifeq ($(GENERATE_DEPENDENCIES),1)
  DO_QVM_DEP=cat $(@:%.o=%.d) | sed -e 's/\.o/\.asm/g' >> $(@:%.o=%.d)
endif

define DO_SHLIB_CC
$(echo_cmd) "SHLIB_CC $<"
$(Q)$(CC) $(CFLAGS) $(SHLIBCFLAGS) -o $@ -c $<
$(Q)$(DO_QVM_DEP)
endef

define DO_GAME_CC
$(echo_cmd) "GAME_CC $<"
$(Q)$(CC) -DQAGAME $(CFLAGS) $(SHLIBCFLAGS) -o $@ -c $<
$(Q)$(DO_QVM_DEP)
endef

define DO_CGAME_CC
$(echo_cmd) "CGAME_CC $<"
$(Q)$(CC) -DCGAME $(CFLAGS) $(SHLIBCFLAGS) -o $@ -c $<
$(Q)$(DO_QVM_DEP)
endef

define DO_UI_CC
$(echo_cmd) "UI_CC $<"
$(Q)$(CC) -DUI $(CFLAGS) $(SHLIBCFLAGS) -o $@ -c $<
$(Q)$(DO_QVM_DEP)
endef

define DO_AS
$(echo_cmd) "AS $<"
$(Q)$(CC) $(CFLAGS) -x assembler-with-cpp -o $@ -c $<
endef

#############################################################################
# MAIN TARGETS
#############################################################################

default: release
all: debug release

debug:
	@$(MAKE) targets B=$(BD) CFLAGS="$(CFLAGS) $(DEPEND_CFLAGS) \
		$(DEBUG_CFLAGS)" V=$(V)

release:
	@$(MAKE) targets B=$(BR) CFLAGS="$(CFLAGS) $(DEPEND_CFLAGS) \
		$(RELEASE_CFLAGS)" V=$(V)

# Create the build directories, check libraries and print out
# an informational message, then start building
targets: makedirs
	@echo ""
	@echo "Building Illusion Arena in $(B):"
	@echo "  PLATFORM: $(PLATFORM)"
	@echo "  ARCH: $(ARCH)"
	@echo "  VERSION: $(VERSION)"
	@echo "  COMPILE_PLATFORM: $(COMPILE_PLATFORM)"
	@echo "  COMPILE_ARCH: $(COMPILE_ARCH)"
	@echo "  CC: $(CC)"
	@echo ""
ifneq ($(TARGETS),)
	@$(MAKE) $(TARGETS) V=$(V)
endif

makedirs:
	@if [ ! -d $(BUILD_DIR) ];then $(MKDIR) $(BUILD_DIR);fi
	@if [ ! -d $(B) ];then $(MKDIR) $(B);fi
	@if [ ! -d $(B)/baseia ];then $(MKDIR) $(B)/baseia;fi
	@if [ ! -d $(B)/baseia/cgame ];then $(MKDIR) $(B)/baseia/cgame;fi
	@if [ ! -d $(B)/baseia/game ];then $(MKDIR) $(B)/baseia/game;fi
	@if [ ! -d $(B)/baseia/ui ];then $(MKDIR) $(B)/baseia/ui;fi
	@if [ ! -d $(B)/baseia/qcommon ];then $(MKDIR) $(B)/baseia/qcommon;fi
	@if [ ! -d $(B)/baseia/vm ];then $(MKDIR) $(B)/baseia/vm;fi
	@if [ ! -d $(B)/tools ];then $(MKDIR) $(B)/tools;fi
	@if [ ! -d $(B)/tools/asm ];then $(MKDIR) $(B)/tools/asm;fi
	@if [ ! -d $(B)/tools/etc ];then $(MKDIR) $(B)/tools/etc;fi
	@if [ ! -d $(B)/tools/rcc ];then $(MKDIR) $(B)/tools/rcc;fi
	@if [ ! -d $(B)/tools/cpp ];then $(MKDIR) $(B)/tools/cpp;fi
	@if [ ! -d $(B)/tools/lburg ];then $(MKDIR) $(B)/tools/lburg;fi

#############################################################################
# QVM BUILD TOOLS
#############################################################################
include include/qvm.mk

#############################################################################
## BASEQ3 CGAME
#############################################################################

Q3CGOBJ_ = \
  $(B)/baseia/cgame/cg_main.o \
  $(B)/baseia/game/bg_misc.o \
  $(B)/baseia/game/bg_lib.o \
  $(B)/baseia/game/bg_pmove.o \
  $(B)/baseia/game/bg_slidemove.o \
  $(B)/baseia/cgame/cg_challenges.o \
  $(B)/baseia/cgame/cg_consolecmds.o \
  $(B)/baseia/cgame/cg_draw.o \
  $(B)/baseia/cgame/cg_drawtools.o \
  $(B)/baseia/cgame/cg_effects.o \
  $(B)/baseia/cgame/cg_ents.o \
  $(B)/baseia/cgame/cg_event.o \
  $(B)/baseia/cgame/cg_info.o \
  $(B)/baseia/cgame/cg_localents.o \
  $(B)/baseia/cgame/cg_marks.o \
  $(B)/baseia/cgame/cg_players.o \
  $(B)/baseia/cgame/cg_playerstate.o \
  $(B)/baseia/cgame/cg_predict.o \
  $(B)/baseia/cgame/cg_scoreboard.o \
  $(B)/baseia/cgame/cg_servercmds.o \
  $(B)/baseia/cgame/cg_snapshot.o \
  $(B)/baseia/cgame/cg_unlagged.o \
  $(B)/baseia/cgame/cg_view.o \
  $(B)/baseia/cgame/cg_weapons.o \
  \
  $(B)/baseia/qcommon/q_math.o \
  $(B)/baseia/qcommon/q_shared.o

Q3CGOBJ = $(Q3CGOBJ_) $(B)/baseia/cgame/cg_syscalls.o
Q3CGVMOBJ = $(Q3CGOBJ_:%.o=%.asm)

$(B)/baseia/cgame$(ARCH).$(SHLIBEXT): $(Q3CGOBJ)
	$(echo_cmd) "LD $@"
	$(Q)$(CC) $(CFLAGS) $(SHLIBLDFLAGS) -o $@ $(Q3CGOBJ)

$(B)/baseia/vm/cgame.qvm: $(Q3CGVMOBJ) $(CGDIR)/cg_syscalls.asm $(Q3ASM)
	$(echo_cmd) "Q3ASM $@"
	$(Q)$(Q3ASM) -o $@ $(Q3CGVMOBJ) $(CGDIR)/cg_syscalls.asm

#############################################################################
## BASEQ3 GAME
#############################################################################

Q3GOBJ_ = \
  $(B)/baseia/game/g_main.o \
  $(B)/baseia/game/ai_chat.o \
  $(B)/baseia/game/ai_cmd.o \
  $(B)/baseia/game/ai_dmnet.o \
  $(B)/baseia/game/ai_dmq3.o \
  $(B)/baseia/game/ai_main.o \
  $(B)/baseia/game/ai_team.o \
  $(B)/baseia/game/bg_misc.o \
  $(B)/baseia/game/bg_lib.o \
  $(B)/baseia/game/bg_pmove.o \
  $(B)/baseia/game/bg_slidemove.o \
  $(B)/baseia/game/g_active.o \
  $(B)/baseia/game/g_arenas.o \
  $(B)/baseia/game/g_admin.o \
  $(B)/baseia/game/g_bot.o \
  $(B)/baseia/game/g_client.o \
  $(B)/baseia/game/g_cmds.o \
  $(B)/baseia/game/g_cmds_cs.o \
  $(B)/baseia/game/g_cmds_ext.o \
  $(B)/baseia/game/g_combat.o \
  $(B)/baseia/game/g_items.o \
  $(B)/baseia/game/bg_alloc.o \
  $(B)/baseia/game/g_fileops.o \
  $(B)/baseia/game/g_killspree.o \
  $(B)/baseia/game/g_misc.o \
  $(B)/baseia/game/g_missile.o \
  $(B)/baseia/game/g_mover.o \
  $(B)/baseia/game/g_playerstore.o \
  $(B)/baseia/game/g_session.o \
  $(B)/baseia/game/g_spawn.o \
  $(B)/baseia/game/g_svcmds.o \
  $(B)/baseia/game/g_svcmds_ext.o \
  $(B)/baseia/game/g_target.o \
  $(B)/baseia/game/g_team.o \
  $(B)/baseia/game/g_trigger.o \
  $(B)/baseia/game/g_unlagged.o \
  $(B)/baseia/game/g_utils.o \
  $(B)/baseia/game/g_vote.o \
  $(B)/baseia/game/g_weapon.o \
  \
  $(B)/baseia/qcommon/q_math.o \
  $(B)/baseia/qcommon/q_shared.o

Q3GOBJ = $(Q3GOBJ_) $(B)/baseia/game/g_syscalls.o
Q3GVMOBJ = $(Q3GOBJ_:%.o=%.asm)

$(B)/baseia/qagame$(ARCH).$(SHLIBEXT): $(Q3GOBJ)
	$(echo_cmd) "LD $@"
	$(Q)$(CC) $(CFLAGS) $(SHLIBLDFLAGS) -o $@ $(Q3GOBJ)

$(B)/baseia/vm/qagame.qvm: $(Q3GVMOBJ) $(GDIR)/g_syscalls.asm $(Q3ASM)
	$(echo_cmd) "Q3ASM $@"
	$(Q)$(Q3ASM) -o $@ $(Q3GVMOBJ) $(GDIR)/g_syscalls.asm

#############################################################################
## BASEQ3 UI
#############################################################################

Q3UIOBJ_ = \
  $(B)/baseia/ui/ui_main.o \
  $(B)/baseia/game/bg_misc.o \
  $(B)/baseia/game/bg_lib.o \
  $(B)/baseia/ui/ui_addbots.o \
  $(B)/baseia/ui/ui_atoms.o \
  $(B)/baseia/ui/ui_cdkey.o \
  $(B)/baseia/ui/ui_challenges.o \
  $(B)/baseia/ui/ui_cinematics.o \
  $(B)/baseia/ui/ui_confirm.o \
  $(B)/baseia/ui/ui_connect.o \
  $(B)/baseia/ui/ui_controls2.o \
  $(B)/baseia/ui/ui_credits.o \
  $(B)/baseia/ui/ui_demo2.o \
  $(B)/baseia/ui/ui_display.o \
  $(B)/baseia/ui/ui_firstconnect.o \
  $(B)/baseia/ui/ui_gameinfo.o \
  $(B)/baseia/ui/ui_ingame.o \
  $(B)/baseia/ui/ui_loadconfig.o \
  $(B)/baseia/ui/ui_menu.o \
  $(B)/baseia/ui/ui_mfield.o \
  $(B)/baseia/ui/ui_mods.o \
  $(B)/baseia/ui/ui_network.o \
  $(B)/baseia/ui/ui_options.o \
  $(B)/baseia/ui/ui_password.o \
  $(B)/baseia/ui/ui_playermodel.o \
  $(B)/baseia/ui/ui_players.o \
  $(B)/baseia/ui/ui_playersettings.o \
  $(B)/baseia/ui/ui_preferences.o \
  $(B)/baseia/ui/ui_qmenu.o \
  $(B)/baseia/ui/ui_removebots.o \
  $(B)/baseia/ui/ui_saveconfig.o \
  $(B)/baseia/ui/ui_serverinfo.o \
  $(B)/baseia/ui/ui_servers2.o \
  $(B)/baseia/ui/ui_setup.o \
  $(B)/baseia/ui/ui_sound.o \
  $(B)/baseia/ui/ui_sparena.o \
  $(B)/baseia/ui/ui_specifyserver.o \
  $(B)/baseia/ui/ui_splevel.o \
  $(B)/baseia/ui/ui_sppostgame.o \
  $(B)/baseia/ui/ui_spskill.o \
  $(B)/baseia/ui/ui_startserver.o \
  $(B)/baseia/ui/ui_team.o \
  $(B)/baseia/ui/ui_teamorders.o \
  $(B)/baseia/ui/ui_video.o \
  $(B)/baseia/ui/ui_votemenu.o \
  $(B)/baseia/ui/ui_votemenu_fraglimit.o \
  $(B)/baseia/ui/ui_votemenu_timelimit.o \
  $(B)/baseia/ui/ui_votemenu_gametype.o \
  $(B)/baseia/ui/ui_votemenu_kick.o \
  $(B)/baseia/ui/ui_votemenu_map.o \
  $(B)/baseia/ui/ui_votemenu_custom.o \
  \
  $(B)/baseia/qcommon/q_math.o \
  $(B)/baseia/qcommon/q_shared.o

Q3UIOBJ = $(Q3UIOBJ_)
Q3UIVMOBJ = $(Q3UIOBJ_:%.o=%.asm)

$(B)/baseia/ui$(ARCH).$(SHLIBEXT): $(Q3UIOBJ)
	$(echo_cmd) "LD $@"
	$(Q)$(CC) $(CFLAGS) $(SHLIBLDFLAGS) -o $@ $(Q3UIOBJ)

$(B)/baseia/vm/ui.qvm: $(Q3UIVMOBJ) $(UIDIR)/ui_syscalls.asm $(Q3ASM)
	$(echo_cmd) "Q3ASM $@"
	$(Q)$(Q3ASM) -o $@ $(Q3UIVMOBJ) $(UIDIR)/ui_syscalls.asm

#############################################################################
## GAME MODULE RULES
#############################################################################
include include/game.mk

#############################################################################
# GAME DATA FILES
#############################################################################
include include/pk3.mk

#############################################################################
# MISC
#############################################################################

OBJ = $(Q3OBJ) $(Q3POBJ) $(Q3POBJ_SMP) $(Q3DOBJ) \
  $(MPGOBJ) $(Q3GOBJ) $(Q3CGOBJ) $(MPCGOBJ) $(Q3UIOBJ) $(MPUIOBJ) \
  $(MPGVMOBJ) $(Q3GVMOBJ) $(Q3CGVMOBJ) $(MPCGVMOBJ) $(Q3UIVMOBJ) $(MPUIVMOBJ)
TOOLSOBJ = $(LBURGOBJ) $(Q3CPPOBJ) $(Q3RCCOBJ) $(Q3LCCOBJ) $(Q3ASMOBJ)


copyfiles: release
	@if [ ! -d $(COPYDIR)/code ]; then echo "You need to set COPYDIR to where your I::A data is!"; fi
	-$(MKDIR) -p -m 0755 $(COPYDIR)/code

ifneq ($(BUILD_GAME_SO),0)
	$(INSTALL) -s -m 0755 $(BR)/baseia/cgame$(ARCH).$(SHLIBEXT) \
					$(COPYDIR)/baseia/.
	$(INSTALL) -s -m 0755 $(BR)/baseia/qagame$(ARCH).$(SHLIBEXT) \
					$(COPYDIR)/baseia/.
	$(INSTALL) -s -m 0755 $(BR)/baseia/ui$(ARCH).$(SHLIBEXT) \
					$(COPYDIR)/baseia/.
endif

clean: clean-debug clean-release

clean-debug:
	@$(MAKE) clean2 B=$(BD)

clean-release:
	@$(MAKE) clean2 B=$(BR)

clean2:
	@echo "CLEAN $(B)"
	@rm -f $(OBJ)
	@rm -f $(OBJ_D_FILES)
	@rm -f $(TARGETS)

toolsclean: toolsclean-debug toolsclean-release

toolsclean-debug:
	@$(MAKE) toolsclean2 B=$(BD)

toolsclean-release:
	@$(MAKE) toolsclean2 B=$(BR)

toolsclean2:
	@echo "TOOLS_CLEAN $(B)"
	@rm -f $(TOOLSOBJ)
	@rm -f $(TOOLSOBJ_D_FILES)
	@rm -f $(LBURG) $(DAGCHECK_C) $(Q3RCC) $(Q3CPP) $(Q3LCC) $(Q3ASM)

distclean: clean toolsclean
	@rm -rf $(BUILD_DIR)

dist:
	rm -rf ia-$(VERSION)
	svn export . ia-$(VERSION)
	tar --owner=root --group=root --force-local -cjf ia-$(VERSION).tar.bz2 ia-$(VERSION)
	rm -rf ia-$(VERSION)

#############################################################################
# DEPENDENCIES
#############################################################################

OBJ_D_FILES=$(filter %.d,$(OBJ:%.o=%.d))
TOOLSOBJ_D_FILES=$(filter %.d,$(TOOLSOBJ:%.o=%.d))
-include $(OBJ_D_FILES) $(TOOLSOBJ_D_FILES)

.PHONY: all clean clean2 clean-debug clean-release copyfiles \
	debug default dist distclean installer makedirs \
	release targets \
	toolsclean toolsclean2 toolsclean-debug toolsclean-release
