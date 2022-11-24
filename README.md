# GCC Build Parser
## Create report of build artifacts (MAP, ELF, DWARF)

### Requirements :
- Resource path: ELF file & MAP file
- GCC Compiler Toolchain (ex: arm-none-eabi-)
- GCC Binutils (ex: arm-none-eabi-)
  - arm-none-eabi-nm
  - arm-none-eabi-size
  - arm-none-eabi-readelf
- POSIX-like terminal system (ex: CYGWIN, MSYS, BusyBox)
- AWK script support
- Makefile support

### Features :
1. List of symbols information (each symbol per line)
    - Symbol name
    - Symbol address
    - Symbol size
    - Symbol file
2. Tree of symbols information
    - Same as above
    - Symbol scope (Global/Local)
    - Symbol type (Function/Object)
    - Symbol class (Data/Text/BSS/etc)
    - Memory section
        - Section name
        - Fill/Padding size
        - Section flag (AWX)
        - Section type (RAM/ROM/DBG)
3. List of files information (each file per line)
    - Code size
    - RO size
    - RW/Data size
    - ZI/BSS  size
    - Debug size
    - File name
4. List of modules information
    - Path pattern can be use to filter specific module
    - ROM/RAM size of each file inside module
    - Total ROM/RAM size each module
    - "OTHER" module is used for unmatch pattern

### How To Use :
1. Copy ".secret.example.mk" to ".secret.mk"
    - Change "ELF_INPUT" file path
    - Change "MAP_INPUT" file path
    - Change "TOOLCHAIN" path
    - Change "MOD_FILTER" for module pattern (optional)
2. Run "make" from this directory
3. Check the result in "out/report.txt"