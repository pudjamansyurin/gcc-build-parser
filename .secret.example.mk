ELF_FILE 	?= ../Debug/*.elf
MAP_FILE 	?= ../Debug/*.map

TOOLCHAIN	?= arm-none-eabi-
AWK 		?= bin/awk/awk

MOD_FILTER 	?= $\
	"./Drivers/ "$\
	"./Middlewares/ "$\
	"./Core/ "$\