-include ./config.mk

$(shell $(MKDIR) -p $(RAW_PATH) $(OUT_PATH) $(REPORT_PATH)) 

# All Target
all: $(ELF_FILE) nm-info readelf-info size-info
	@$(ECHO) 'Invoking: AWK script (Analyzing)'
	@$(AWK) -f $(SECTION_PARSER_AWK) $(READELF_SECTION_RAW) | \
		$(TEE) $(SECTION_OUT) >/dev/null
	@$(AWK) -f $(NM_PARSER_AWK) $(NM_SYMBOL_RAW) | \
		$(SORT) -nk 1 | \
		$(CUT) -d " " -f 2- | \
		$(TEE) $(SYMBOL_NM_OUT) >/dev/null
	@$(AWK) -f $(DWARF_PARSER_AWK) $(DWARF_SYMBOL_RAW) | \
		$(SORT) -nk 1 | \
		$(CUT) -d " " -f 2- | \
		$(TEE) $(SYMBOL_DWARF_OUT) >/dev/null
	@$(AWK) -f $(READELF_PARSER_AWK) $(READELF_SYMBOL_RAW)| \
		$(SORT) -nk 1 | \
		$(CUT) -d " " -f 2- | \
		$(TEE) $(SYMBOL_READELF_OUT) >/dev/null
	@$(AWK) -f $(MAP_PARSER_AWK) \
			-v SECTION=$(SECTION_OUT) \
			-v NM=$(SYMBOL_NM_OUT) \
			-v MAP=$(MAP_FILE) \
			$(SECTION_OUT) $(SYMBOL_NM_OUT) $(MAP_FILE) | \
		$(TEE) $(SYMBOL_MAP_OUT) >/dev/null
	@$(AWK) -f $(SYMBOL_PARSER_AWK) $(SYMBOL_MAP_OUT) | \
		$(TEE) $(SYMBOL_LIST) >/dev/null
	@$(AWK) -f $(FILE_PARSER_AWK) $(SYMBOL_MAP_OUT) | \
		$(TEE) $(FILE_LIST) >/dev/null
	@$(AWK) -f $(MODULE_PARSER_AWK) \
			-v MOD_FILTER=$(MOD_FILTER) \
			-v MOD_OTHER="OTHER" \
			$(FILE_LIST) | \
		$(TEE) $(MODULE_LIST) #>/dev/null

nm-info: $(ELF_FILE)
	@$(ECHO) 'Invoking: NM (symbol listing)'
	@$(NM) -l -S -n -f sysv $(ELF_FILE) > $(NM_SYMBOL_RAW)
	@$(ECHO) 'Finished building: $@'
	@$(ECHO) ' '
	
readelf-info: $(ELF_FILE)
	@$(ECHO) 'Invoking: Readelf (ELF info listing)'
	@$(READELF) -l -S $(ELF_FILE) > $(READELF_SECTION_RAW)
	@$(READELF) -s $(ELF_FILE) > $(READELF_SYMBOL_RAW)
	@$(READELF) --debug-dump=info $(ELF_FILE) > $(DWARF_SYMBOL_RAW)
	@$(ECHO) 'Finished building: $@'
	@$(ECHO) ' '

size-info: $(ELF_FILE)
	@$(ECHO) 'Invoking: Size (section size listing)'
	@$(SIZE) $(ELF_FILE) > $(SIZE_RAW)
	@$(ECHO) 'Finished building: $@'
	@$(ECHO) ' '
	
clean:
	$(RM) -rf $(RAW_PATH) $(OUT_PATH) $(REPORT_PATH)

.PHONY: all clean