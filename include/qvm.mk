TOOLS_CFLAGS = -g -O2 -Wall -fno-strict-aliasing \
		 -DSYSTEM=\"\" -DTEMPDIR=\"${TEMPDIR}\" \
		 -I${Q3LCCSRCDIR} -I${LBURGDIR}
TOOLS_LDFLAGS =
TOOLS_LIBS =

ifeq ($(GENERATE_DEPENDENCIES),1)
    TOOLS_CFLAGS += -MMD
endif

define DO_TOOLS_CC
$(echo_cmd) "TOOLS_CC $<"
$(Q)$(CC) $(TOOLS_CFLAGS) -o $@ -c $<
endef

define DO_TOOLS_CC_DAGCHECK
$(echo_cmd) "TOOLS_CC_DAGCHECK $<"
$(Q)$(CC) $(TOOLS_CFLAGS) -Wno-unused -o $@ -c $<
endef

LBURG       = $(B)/tools/lburg/lburg$(BINEXT)
DAGCHECK_C  = $(B)/tools/rcc/dagcheck.c
Q3RCC       = $(B)/tools/q3rcc$(BINEXT)
Q3CPP       = $(B)/tools/q3cpp$(BINEXT)
Q3LCC       = $(B)/tools/q3lcc$(BINEXT)
Q3ASM       = $(B)/tools/q3asm$(BINEXT)

LBURGOBJ= \
	  $(B)/tools/lburg/lburg.o \
	  $(B)/tools/lburg/gram.o

$(B)/tools/lburg/%.o: $(LBURGDIR)/%.c
	$(DO_TOOLS_CC)

$(LBURG): $(LBURGOBJ)
	$(echo_cmd) "LD $@"
	$(Q)$(CC) $(TOOLS_CFLAGS) $(TOOLS_LDFLAGS) -o $@ $^ $(TOOLS_LIBS)


Q3RCCOBJ = \
	   $(B)/tools/rcc/alloc.o \
	   $(B)/tools/rcc/bind.o \
	   $(B)/tools/rcc/bytecode.o \
	   $(B)/tools/rcc/dag.o \
	   $(B)/tools/rcc/dagcheck.o \
	   $(B)/tools/rcc/decl.o \
	   $(B)/tools/rcc/enode.o \
	   $(B)/tools/rcc/error.o \
	   $(B)/tools/rcc/event.o \
	   $(B)/tools/rcc/expr.o \
	   $(B)/tools/rcc/gen.o \
	   $(B)/tools/rcc/init.o \
	   $(B)/tools/rcc/inits.o \
	   $(B)/tools/rcc/input.o \
	   $(B)/tools/rcc/lex.o \
	   $(B)/tools/rcc/list.o \
	   $(B)/tools/rcc/main.o \
	   $(B)/tools/rcc/null.o \
	   $(B)/tools/rcc/output.o \
	   $(B)/tools/rcc/prof.o \
	   $(B)/tools/rcc/profio.o \
	   $(B)/tools/rcc/simp.o \
	   $(B)/tools/rcc/stmt.o \
	   $(B)/tools/rcc/string.o \
	   $(B)/tools/rcc/sym.o \
	   $(B)/tools/rcc/symbolic.o \
	   $(B)/tools/rcc/trace.o \
	   $(B)/tools/rcc/tree.o \
	   $(B)/tools/rcc/types.o

$(DAGCHECK_C): $(LBURG) $(Q3LCCSRCDIR)/dagcheck.md
	$(echo_cmd) "LBURG $(Q3LCCSRCDIR)/dagcheck.md"
	$(Q)$(LBURG) $(Q3LCCSRCDIR)/dagcheck.md $@

$(B)/tools/rcc/dagcheck.o: $(DAGCHECK_C)
	$(DO_TOOLS_CC_DAGCHECK)

$(B)/tools/rcc/%.o: $(Q3LCCSRCDIR)/%.c
	$(DO_TOOLS_CC)

$(Q3RCC): $(Q3RCCOBJ)
	$(echo_cmd) "LD $@"
	$(Q)$(CC) $(TOOLS_CFLAGS) $(TOOLS_LDFLAGS) -o $@ $^ $(TOOLS_LIBS)

Q3CPPOBJ = \
	   $(B)/tools/cpp/cpp.o \
	   $(B)/tools/cpp/lex.o \
	   $(B)/tools/cpp/nlist.o \
	   $(B)/tools/cpp/tokens.o \
	   $(B)/tools/cpp/macro.o \
	   $(B)/tools/cpp/eval.o \
	   $(B)/tools/cpp/include.o \
	   $(B)/tools/cpp/hideset.o \
	   $(B)/tools/cpp/getopt.o \
	   $(B)/tools/cpp/unix.o

$(B)/tools/cpp/%.o: $(Q3CPPDIR)/%.c
	$(DO_TOOLS_CC)

$(Q3CPP): $(Q3CPPOBJ)
	$(echo_cmd) "LD $@"
	$(Q)$(CC) $(TOOLS_CFLAGS) $(TOOLS_LDFLAGS) -o $@ $^ $(TOOLS_LIBS)

Q3LCCOBJ = \
	$(B)/tools/etc/lcc.o \
	$(B)/tools/etc/bytecode.o

$(B)/tools/etc/%.o: $(Q3LCCETCDIR)/%.c
	$(DO_TOOLS_CC)

$(Q3LCC): $(Q3LCCOBJ) $(Q3RCC) $(Q3CPP)
	$(echo_cmd) "LD $@"
	$(Q)$(CC) $(TOOLS_CFLAGS) $(TOOLS_LDFLAGS) -o $@ $(Q3LCCOBJ) $(TOOLS_LIBS)


define DO_Q3LCC
$(echo_cmd) "Q3LCC $<"
$(Q)$(Q3LCC) -o $@ $<
endef

define DO_CGAME_Q3LCC
$(echo_cmd) "CGAME_Q3LCC $<"
$(Q)$(Q3LCC) -DCGAME -o $@ $<
endef

define DO_GAME_Q3LCC
$(echo_cmd) "GAME_Q3LCC $<"
$(Q)$(Q3LCC) -DQAGAME -o $@ $<
endef

define DO_UI_Q3LCC
$(echo_cmd) "UI_Q3LCC $<"
$(Q)$(Q3LCC) -DUI -o $@ $<
endef

Q3ASMOBJ = \
	   $(B)/tools/asm/q3asm.o \
	   $(B)/tools/asm/cmdlib.o

$(B)/tools/asm/%.o: $(Q3ASMDIR)/%.c
	$(DO_TOOLS_CC)

$(Q3ASM): $(Q3ASMOBJ)
	$(echo_cmd) "LD $@"
	$(Q)$(CC) $(TOOLS_CFLAGS) $(TOOLS_LDFLAGS) -o $@ $^ $(TOOLS_LIBS)
