$(B)/baseia/pak0.pk3: $(B)/baseia/vm/cgame.qvm $(B)/baseia/vm/qagame.qvm $(B)/baseia/vm/ui.qvm
	@rm -f $@
	$(echo_cmd) "ZIP $@"
	@cd $(B)/baseia && zip -0r $(notdir $@) vm
