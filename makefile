-include ./config.mk

$(shell $(MKDIR) -p $(RAW_PATH) $(OUT_PATH))

# All Target
all: $(ELF_INPUT) nm-info readelf-info size-info
	@$(ECHO) 'Invoking: AWK script (Analyzing)'
	$(AWK) -f $(SECTION_PARSER_AWK) $(READELF_SECTION_RAW) | \
		$(TEE) $(SECTION_OUT) >/dev/null
	$(AWK) -f $(NM_PARSER_AWK) $(NM_SYMBOL_RAW) | \
		$(SORT) -nk 1 | \
		$(CUT) -d " " -f 2- | \
		$(TEE) $(SYMBOL_NM_OUT) >/dev/null
	$(AWK) -f $(DWARF_PARSER_AWK) $(DWARF_SYMBOL_RAW) | \
		$(SORT) -nk 1 | \
		$(CUT) -d " " -f 2- | \
		$(TEE) $(SYMBOL_DWARF_OUT) >/dev/null
	$(AWK) -f $(READELF_PARSER_AWK) $(READELF_SYMBOL_RAW)| \
		$(SORT) -nk 1 | \
		$(CUT) -d " " -f 2- | \
		$(TEE) $(SYMBOL_READELF_OUT) >/dev/null
	$(AWK) -f $(PARSER_AWK) \
			-v MAP=$(MAP_INPUT) \
			-v NM=$(SYMBOL_NM_OUT) \
			-v SECTION=$(SECTION_OUT) \
			-v DWARF=$(SYMBOL_DWARF_OUT) \
			-v READELF=$(SYMBOL_READELF_OUT) \
			-v MOD_FILTER=$(MOD_FILTER) \
			$(SECTION_OUT) $(MAP_INPUT) $(SYMBOL_NM_OUT) $(SYMBOL_DWARF_OUT) $(SYMBOL_READELF_OUT) | \
		$(TEE) $(REPORT_OUT) #>/dev/null

nm-info: $(ELF_INPUT)
	@$(ECHO) 'Invoking: NM (symbol listing)'
	$(NM) -l -S -n -f sysv $(ELF_INPUT) > $(NM_SYMBOL_RAW)
	@$(ECHO) 'Finished building: $@'
	@$(ECHO) ' '
	
readelf-info: $(ELF_INPUT)
	@$(ECHO) 'Invoking: Readelf (ELF info listing)'
	$(READELF) -l -S $(ELF_INPUT) > $(READELF_SECTION_RAW)
	$(READELF) -s $(ELF_INPUT) > $(READELF_SYMBOL_RAW)
	$(READELF) --debug-dump=info $(ELF_INPUT) > $(DWARF_SYMBOL_RAW)
	@$(ECHO) 'Finished building: $@'
	@$(ECHO) ' '

size-info: $(ELF_INPUT)
	@$(ECHO) 'Invoking: Size (section size listing)'
	$(SIZE) $(ELF_INPUT) > $(SIZE_RAW)
	@$(ECHO) 'Finished building: $@'
	@$(ECHO) ' '
	
clean:
	$(RM) -rf $(RAW_PATH) $(OUT_PATH)

.PHONY: all clean