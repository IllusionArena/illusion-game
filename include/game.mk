$(B)/baseia/cgame/bg_%.o: $(GDIR)/bg_%.c
	$(DO_CGAME_CC)

$(B)/baseia/cgame/%.o: $(CGDIR)/%.c
	$(DO_CGAME_CC)

$(B)/baseia/cgame/bg_%.asm: $(GDIR)/bg_%.c $(Q3LCC)
	$(DO_CGAME_Q3LCC)

$(B)/baseia/cgame/%.asm: $(CGDIR)/%.c $(Q3LCC)
	$(DO_CGAME_Q3LCC)

$(B)/baseia/game/%.o: $(GDIR)/%.c
	$(DO_GAME_CC)

$(B)/baseia/game/%.asm: $(GDIR)/%.c $(Q3LCC)
	$(DO_GAME_Q3LCC)

$(B)/baseia/ui/bg_%.o: $(GDIR)/bg_%.c
	$(DO_UI_CC)

$(B)/baseia/ui/%.o: $(Q3UIDIR)/%.c
	$(DO_UI_CC)

$(B)/baseia/ui/bg_%.asm: $(GDIR)/bg_%.c $(Q3LCC)
	$(DO_UI_Q3LCC)

$(B)/baseia/ui/%.asm: $(Q3UIDIR)/%.c $(Q3LCC)
	$(DO_UI_Q3LCC)

$(B)/baseia/qcommon/%.o: $(CMDIR)/%.c
	$(DO_SHLIB_CC)

$(B)/baseia/qcommon/%.asm: $(CMDIR)/%.c $(Q3LCC)
	$(DO_Q3LCC)
