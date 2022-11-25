ELF_FILE 	?= something.elf
MAP_FILE 	?= something.map

TOOLCHAIN	?= arm-none-eabi-
# AWK 		?= bin/awk/awk

MOD_FILTER 	?= $\
	"./Src/ModuleA/ "$\
	"./Src/ModuleB/ "$\
	"./Src/ModuleC/ "$\