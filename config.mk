# ELF_INPUT = ../Debug/vt-andes.elf
ELF_INPUT 	= ../Project/Touch/NDS32/Touch.elf
MAP_INPUT 	= ../Project/Touch/NDS32/output.map

TOOLCHAIN	= nds32le-elf-
NM 			= $(TOOLCHAIN)nm
SIZE 		= $(TOOLCHAIN)size
READELF 	= $(TOOLCHAIN)readelf
OBJDUMP 	= $(TOOLCHAIN)objdump

MKDIR 		= mkdir
ECHO 		= echo
RM 			= rm
AWK 		= awk
TEE			= tee
TAC			= tac
CAT 		= cat
CUT			= cut
SORT 		= sort

AWK_PATH 			= awk
COMMON_AWK 			= $(AWK_PATH)/common.awk
SYMBOL_MAP_AWK 		= $(AWK_PATH)/symbol-map.awk -i $(COMMON_AWK)
SYMBOL_NM_AWK 		= $(AWK_PATH)/symbol-nm.awk -i $(COMMON_AWK)
SYMBOL_DWARF_AWK 	= $(AWK_PATH)/symbol-dwarf.awk -i $(COMMON_AWK)
SYMBOL_READELF_AWK 	= $(AWK_PATH)/symbol-readelf.awk -i $(COMMON_AWK)

OUT_PATH 			= out
SYMBOL_MAP_OUT 		= $(OUT_PATH)/symbol-map.txt
SYMBOL_NM_OUT 		= $(OUT_PATH)/symbol-nm.txt
SYMBOL_DWARF_OUT 	= $(OUT_PATH)/symbol-dwarf.txt
SYMBOL_READELF_OUT 	= $(OUT_PATH)/symbol-readelf.txt

RAW_PATH 			= .raw
SIZE_RAW 			= $(RAW_PATH)/.PHONY.size
NM_SYMBOL_RAW 		= $(RAW_PATH)/nm-symbol.txt
DWARF_SYMBOL_RAW 	= $(RAW_PATH)/dwarf-symbol.txt
READELF_HEADER_RAW 	= $(RAW_PATH)/readelf-header.txt
READELF_SECTION_RAW = $(RAW_PATH)/readelf-section.txt
READELF_SYMBOL_RAW 	= $(RAW_PATH)/readelf-symbol.txt