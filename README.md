# GCC Build Parser
## Create report of build artifacts (MAP, ELF, DWARF)

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
1. Define this variable by copy ".secret.example.mk" to ".secret.mk"
    - "ELF_FILE" file path
    - "MAP_FILE" file path
    - "TOOLCHAIN" path
    - "MOD_FILTER" for module pattern (optional)
2. Run "make" from this directory
    - Or you can atttach as post-build hook
        - $(MAKE) -C ../gcc-build-parser
3. Check the result in "report/*-list.txt"

### Features :
This is example of buil artifact analyzing in generated SMT32CubeIDE project.
Some of the lines are deleted just to simplify this demo.

1. Map of symbols information (tree structure) [SYMBOL_MAP]
    - Same as above
    - Symbol scope (Global/Local)
    - Symbol type (Function/Object)
    - Symbol class (Data/Text/BSS/etc)
    - Memory section
        - Section name
        - Fill/Padding size
        - Section flag (AWX)
        - Section type (RAM/ROM/DBG)
#### **`.out/symbol-map.txt`**
```
===========================================================================
                               SYMBOL TREE                                 
===========================================================================
section : .text
 addr : 080001b0
 mem : ROM
 flag : AX
 fill : 58
 size : 49672
 irom : 1
  group : .text.prvInitialiseNewTask
   addr : 0800a5b8
   symbol_cnt : 1
   src : ./Middlewares/Third_Party/FreeRTOS/Source/tasks.o
   size : 292
    symbol : 0800a5b8
     scope : L
     type : F
     class : T
     name : prvInitialiseNewTask
     size : 292
  group : .text.vListInsertEnd
   addr : 080098de
   symbol_cnt : 1
   src : ./Middlewares/Third_Party/FreeRTOS/Source/list.o
   size : 72
    symbol : 080098de
     scope : G
     type : F
     class : T
     name : vListInsertEnd
     size : 72
section : .bss
 addr : 20000094
 mem : RAM
 flag : WA
 fill : 9
 size : 36216
 irom : 0
  group : .bss.hcrc
   addr : 20000308
   symbol_cnt : 1
   src : ./Core/Src/main.o
   size : 8
    symbol : 20000308
     scope : G
     type : O
     class : B
     name : hcrc
     size : 8
  group : .bss.xTasksWaitingTermination
   addr : 20000690
   symbol_cnt : 1
   src : ./Middlewares/Third_Party/FreeRTOS/Source/tasks.o
   size : 20
    symbol : 20000690
     scope : L
     type : O
     class : B
     name : xTasksWaitingTermination
     size : 20
section : .debug_info
 addr : 00000000
 mem : DBG
 flag : 0
 fill : 0
 size : 176367
 irom : 0
  group : .debug_info
   addr : 00000000
   symbol_cnt : 0
   src : ./Core/Src/freertos.o
   size : 792
  group : .debug_info.10
   addr : 00007d3c
   symbol_cnt : 0
   src : ./Drivers/STM32F4xx_HAL_Driver/Src/stm32f4xx_hal_cortex.o
   size : 3665
```


2. List of symbols information (each symbol per line) [SYMBOL_LIST]
    - Symbol name
    - Symbol address
    - Symbol size
    - Symbol file
#### **`report/symbol-list.txt`**
```
===========================================================================
                               FUNCTION LIST                               
===========================================================================
Function Name                         Address  Size  Object Name           
vListInsertEnd                       080098de    72  list.o                  
prvInitialiseNewTask                 0800a5b8   292  tasks.o                 
HAL_DMA2D_IRQHandler                 08001972   504  stm32f4xx_hal_dma2d.o   
HAL_GPIO_WritePin                    08002010    50  stm32f4xx_hal_gpio.o    
CDC_ProcessReception                 08007792   210  usbh_cdc.o              
SysTick_Handler                      0800b5f8    68  port.o                 

===========================================================================
                               VARIABLE LIST                               
===========================================================================
Variable Name                         Address  Size  Object Name           
APBPrescTable                        0800c434     8  system_stm32f4xx.o      
SystemCoreClock                      20000000     4  system_stm32f4xx.o      
AHBPrescTable                        0800c424    16  system_stm32f4xx.o      
uwTickPrio                           20000004     4  stm32f4xx_hal.o         
impure_data                          20000034    96  lib_a-impure.o          
CDC_Class                            2000000c    32  usbh_cdc.o              
uxCriticalNesting                    2000002c     4  port.o                  
_impure_ptr                          20000030     4  lib_a-impure.o          
uwTickFreq                           20000008     1  stm32f4xx_hal.o         

===========================================================================
                               ASSEMBLY LIST                               
===========================================================================
Assembly Name                         Address  Size  Object Name           

===========================================================================
                                UNKNOWN LIST                               
===========================================================================
Unknown Name                          Address  Size  Object Name           
.rodata                              0800c3b8    40  main.o                  
.rodata.2                            0800c3e0     4  usbh_cdc.o              
.rodata.3                            0800c3e4    56  usbh_core.o             
.rodata.4                            0800c41c     5  tasks.o                 
.init.2                              0800c3a4     8  crtn.o                  
.fini.2                              0800c3b0     8  crtn.o                  
.text                                080001b0    64  crtbegin.o              
.fini_array                          0800c448     4  crtbegin.o              
exidx                                0800c43c     8  _udivmoddi4.o           
.bss                                 20000094    28  crtbegin.o              
.init_array                          0800c444     4  crtbegin.o              
```

3. List of files information (each file per line) [FILE_LIST]
    - Code size
    - RO size
    - RW/Data size
    - ZI/BSS  size
    - Debug size
    - File name
#### **`report/file-list.txt`**
```
===============================================================================
                                  FILE SIZE                                    
===============================================================================
      Code    RO Data    RW Data    ZI Data      Debug  Object Name            
       124          0          0          0       9836  stm32f4xx_it.o           
       168          0          0        997       9940  usb_host.o               
      1932          4         32          0      34699  usbh_cdc.o               
       452          0          0          0      11032  stm32f4xx_hal_cortex.o   
      3582          5          0        300      23984  tasks.o                  
       988          0          0      32800       5962  heap_4.o                 
       288          0          0          0      17146  stm32f4xx_hal_tim_ex.o   
      4036          0          0          0      19229  stm32f4xx_ll_usb.o       
        56          0          0          0       3598  usbh_platform.o          
      1168          0          4          5       6885  port.o                   
       292          0          0          0       8712  usbh_pipes.o             
       396          0          0          0      12206  stm32f4xx_ll_fmc.o       
      2016          0          0          0      36644  stm32f4xx_hal_tim.o      
      2692          0          0          0      18025  queue.o                  
       248          0          0         72       6907  stm32f4xx_hal_timebase_tim.o  
       108          0          0          4      10200  sysmem.o                 
       274          0          0          0      19104  stm32f4xx_hal_spi.o      
      3480         56          0          0      16016  usbh_core.o              
       320          0          0          0       9436  usbh_ioreq.o             
      1958         40          0        608      31638  main.o                   
       896          0          0          0       6718  stm32f4xx_hal_rcc_ex.o   
        64          0          8         28         52  crtbegin.o               
       906          0          0          0       6945  stm32f4xx_hal_gpio.o     
      6164          0          0          0      13274  stm32f4xx_hal_hcd.o      
       982          0          0          0      12586  stm32f4xx_hal_dma2d.o    
      1410          0          0          0      30127  stm32f4xx_hal_uart.o     
      1326          0          0        772      15483  usbh_conf.o              
       104          0          0          0      11288  stm32f4xx_hal_sdram.o    
       648          0          0          0      33343  stm32f4xx_hal_i2c.o      
      2452          0          0          0       8671  stm32f4xx_hal_rcc.o      
       204          0          5          4       9580  stm32f4xx_hal.o          
       102          0          0        600    1069267  freertos.o               
         8          0          0          0         30  crti.o                   
      1724          0          0          4      16583  stm32f4xx_hal_msp.o      
        36         24          4          0       4751  system_stm32f4xx.o       
       246          0          0          0       5021  stm32f4xx_hal_i2c_ex.o   
        16          0          0          0         30  crtn.o                   
      1742          0          0          0      15103  stm32f4xx_hal_ltdc.o     
        82        428          0          0        347  startup_stm32f429zitx.o  
        56          0          0          0       4887  stm32f4xx_hal_crc.o      
       360          0          0          0       3819  list.o                   
       730          0          0          0      19080  cmsis_os.o               
      3338          0          0          0      12995  usbh_ctlreq.o            
-------------------------------------------------------------------------------
     48174        557         53      36194    1611179   Object Totals         
-------------------------------------------------------------------------------
      Code    RO Data    RW Data    ZI Data      Debug  Library Name           
        12          0          0          0         84  lib_a-errno.o            
        32          0          0          0         96  lib_a-sbrkr.o            
        72          0          0          0         96  lib_a-init.o             
        32          0          0          0        100  lib_a-malloc.o           
        24          0          0          0        100  lib_a-mlock.o            
        48          0          0          0         74  _aeabi_uldivmod.o        
        28          0          0          0         92  lib_a-memcpy-stub.o      
       296          0          0          8        128  lib_a-nano-mallocr.o     
         0          0          0          4        144  lib_a-reent.o            
       152          0          0          0        108  lib_a-nano-freer.o       
       720          8          0          0        104  _udivmoddi4.o            
         0          0        100          0         52  lib_a-impure.o           
         4          0          0          0         30  _dvmd_tls.o              
         4          0          0          1        228  lib_a-lock.o             
        16          0          0          0         84  lib_a-memset.o           
-------------------------------------------------------------------------------
      1440          8        100         13       1520   Library Totals        
-------------------------------------------------------------------------------
        58          3          3          9          0   Padding Totals        
-------------------------------------------------------------------------------
     49672        568        156      36216    1612699   Totals                
```

4. List of modules information [MODULE_LIST]
    - Path pattern can be use to filter specific module
    - ROM/RAM size of each file inside module
    - Total ROM/RAM size each module
    - "OTHER" module is used for unmatch pattern
#### **`.secret.mk`**
``` makefile
MOD_FILTER ?= "./Core/ ./Drivers/ ./Middlewares/"
```
#### **`report/module-list.txt`**
```
==============================================================================
                                 MODULE SIZE                                  
==============================================================================
Module               Object Name                           ROM Size   RAM Size
------------------------------------------------------------------------------
MIDDLEWARES          heap_4.o                                   988      32800
                     cmsis_os.o                                 730          0
                     tasks.o                                   3587        300
                     queue.o                                   2692          0
                     usbh_cdc.o                                1968         32
                     list.o                                     360          0
                     port.o                                    1172          9
                                                              11497      33141
------------------------------------------------------------------------------
DRIVERS              stm32f4xx_hal_i2c_ex.o                     246          0
                     stm32f4xx_hal_hcd.o                       6164          0
                     stm32f4xx_hal_sdram.o                      104          0
                     stm32f4xx_hal_rcc_ex.o                     896          0
                     stm32f4xx_hal_tim.o                       2016          0
                     stm32f4xx_hal_tim_ex.o                     288          0
                     stm32f4xx_hal_uart.o                      1410          0
                     stm32f4xx_hal_spi.o                        274          0
                     stm32f4xx_hal_ltdc.o                      1742          0
                     stm32f4xx_hal_gpio.o                       906          0
                     stm32f4xx_ll_fmc.o                         396          0
                     stm32f4xx_ll_usb.o                        4036          0
                     stm32f4xx_hal_i2c.o                        648          0
                     stm32f4xx_hal_cortex.o                     452          0
                     stm32f4xx_hal_rcc.o                       2452          0
                     stm32f4xx_hal_dma2d.o                      982          0
                     stm32f4xx_hal_crc.o                         56          0
                     stm32f4xx_hal.o                            209          9
                                                              23277          9
------------------------------------------------------------------------------
CORE                 sysmem.o                                   108          4
                     usbh_ctlreq.o                             3338          0
                     usbh_core.o                               3536          0
                     usbh_pipes.o                               292          0
                     usbh_ioreq.o                               320          0
                     stm32f4xx_it.o                             124          0
                     stm32f4xx_hal_timebase_tim.o               248         72
                     main.o                                    1998        608
                     startup_stm32f429zitx.o                    510          0
                     system_stm32f4xx.o                          64          4
                     stm32f4xx_hal_msp.o                       1724          4
                     freertos.o                                 102        600
                                                              12364       1292
------------------------------------------------------------------------------
OTHER                usbh_conf.o                               1326        772
                     usbh_platform.o                             56          0
                     usb_host.o                                 168        997
                                                               1550       1769
------------------------------------------------------------------------------
                     TOTAL PADDING                               64         12
------------------------------------------------------------------------------
                     TOTAL ALL                                50396      36372
```