# GCC Build Parser
## Create report of build artifacts (MAP, ELF, DWARF)

### Features :
1. List of symbols information (each symbol per line) [SYMBOL_LIST]
    - Symbol name
    - Symbol address
    - Symbol size
    - Symbol file
2. Map of symbols information (tree structure) [SYMBOL_MAP]
    - Same as above
    - Symbol scope (Global/Local)
    - Symbol type (Function/Object)
    - Symbol class (Data/Text/BSS/etc)
    - Memory section
        - Section name
        - Fill/Padding size
        - Section flag (AWX)
        - Section type (RAM/ROM/DBG)
3. List of files information (each file per line) [FILE_LIST]
    - Code size
    - RO size
    - RW/Data size
    - ZI/BSS  size
    - Debug size
    - File name
4. List of modules information [MODULE_LIST]
    - Path pattern can be use to filter specific module
    - ROM/RAM size of each file inside module
    - Total ROM/RAM size each module
    - "OTHER" module is used for unmatch pattern

### Requirements :
- Resource path: ELF file & MAP file
- GCC Binutils (ex: arm-none-eabi-)
  - arm-none-eabi-nm
  - arm-none-eabi-size
  - arm-none-eabi-readelf
- POSIX-like terminal system (ex: CYGWIN, MSYS, BusyBox)
- AWK script support
- Makefile support

### How To Use :
1. Copy ".secret.example.mk" to ".secret.mk"
    - Change "ELF_FILE" file path
    - Change "MAP_FILE" file path
    - Change "TOOLCHAIN" path
    - Change "MOD_FILTER" for module pattern (optional)
2. Run "make" from this directory
3. Check the result in "report/*-list.txt"