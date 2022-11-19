-include ./config.mk

$(shell $(MKDIR) -p $(RAW_PATH) $(OUT_PATH))

# All Target
all: $(ELF_INPUT) nm-info readelf-info size-info
	@$(ECHO) 'Invoking: AWK script (Analyzing)'
	$(AWK) -f $(SYMBOL_MAP_AWK) $(MAP_INPUT) | \
		$(TEE) $(SYMBOL_MAP_OUT) >/dev/null
	$(AWK) -f $(SYMBOL_DWARF_AWK) $(DWARF_SYMBOL_RAW) | \
		$(TEE) $(SYMBOL_DWARF_OUT) >/dev/null
	$(TAC) $(NM_SYMBOL_RAW) | \
		$(AWK) -f $(SYMBOL_NM_AWK) | \
		$(TAC) | \
		# $(AWK) '$$3 ~ /(T|D|R|B|S)/' | \
		# $(AWK) '!($$3 == "S" && $$6 == "N")' | \
		# $(AWK) 'seen[$$1]++' \
		# $(AWK) '$$6 !~ /(N)/' | \
		$(TEE) $(SYMBOL_NM_OUT) >/dev/null
	$(CAT) $(READELF_SYMBOL_RAW) | \
		$(AWK) -f $(SYMBOL_READELF_AWK) | \
		$(SORT) -nk 1 | \
		$(AWK) '{$$1=""}1' | $(AWK) '{$$1=$$1}1' | \
		$(TEE) $(SYMBOL_READELF_OUT) >/dev/null

nm-info: $(ELF_INPUT)
	@$(ECHO) 'Invoking: NM (symbol listing)'
	$(NM) -l -S -n -f sysv $(ELF_INPUT) > $(NM_SYMBOL_RAW)
	@$(ECHO) 'Finished building: $@'
	@$(ECHO) ' '
	
readelf-info: $(ELF_INPUT)
	@$(ECHO) 'Invoking: Readelf (ELF info listing)'
	$(READELF) -l $(ELF_INPUT) > $(READELF_HEADER_RAW)
	$(READELF) -s $(ELF_INPUT) > $(READELF_SYMBOL_RAW)
	$(READELF) -S $(ELF_INPUT) > $(READELF_SECTION_RAW)
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