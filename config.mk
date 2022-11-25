-include ./.secret.mk

MKDIR 		= mkdir
ECHO 		= echo
CP 			= cp
RM 			= rm
AWK 		= awk
TEE			= tee
TAC			= tac
CAT 		= cat
CUT			= cut
SORT 		= sort

NM 			= $(TOOLCHAIN)nm
SIZE 		= $(TOOLCHAIN)size
READELF 	= $(TOOLCHAIN)readelf

AWK_PATH 			= awk
COMMON_AWK 			= $(AWK_PATH)/common.awk
NM_PARSER_AWK 		= $(AWK_PATH)/nm-parser.awk -i $(COMMON_AWK)
DWARF_PARSER_AWK 	= $(AWK_PATH)/dwarf-parser.awk -i $(COMMON_AWK)
READELF_PARSER_AWK 	= $(AWK_PATH)/readelf-parser.awk -i $(COMMON_AWK)
SECTION_PARSER_AWK 	= $(AWK_PATH)/section-parser.awk -i $(COMMON_AWK)
MAP_PARSER_AWK 		= $(AWK_PATH)/map-parser.awk -i $(COMMON_AWK)

SYMBOL_PARSER_AWK 	= $(AWK_PATH)/symbol-parser.awk -i $(COMMON_AWK)
FILE_PARSER_AWK 	= $(AWK_PATH)/file-parser.awk -i $(COMMON_AWK)
MODULE_PARSER_AWK 	= $(AWK_PATH)/module-parser.awk -i $(COMMON_AWK)

RAW_PATH 			= .raw
SIZE_RAW 			= $(RAW_PATH)/.PHONY.size
NM_SYMBOL_RAW 		= $(RAW_PATH)/nm-symbol.txt
DWARF_SYMBOL_RAW 	= $(RAW_PATH)/dwarf-symbol.txt
READELF_SECTION_RAW = $(RAW_PATH)/readelf-section.txt
READELF_SYMBOL_RAW 	= $(RAW_PATH)/readelf-symbol.txt

OUT_PATH 			= .out
SECTION_OUT 		= $(OUT_PATH)/section.txt
SYMBOL_NM_OUT 		= $(OUT_PATH)/symbol-nm.txt
SYMBOL_DWARF_OUT 	= $(OUT_PATH)/symbol-dwarf.txt
SYMBOL_READELF_OUT 	= $(OUT_PATH)/symbol-readelf.txt
SYMBOL_MAP_OUT 		= $(OUT_PATH)/symbol-map.txt

REPORT_PATH 		= report
SYMBOL_LIST			= $(REPORT_PATH)/symbol-list.txt
FILE_LIST			= $(REPORT_PATH)/file-list.txt
MODULE_LIST			= $(REPORT_PATH)/module-list.txt