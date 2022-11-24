#!/bin/awk -f

BEGIN {
    RS = "\n";
    FS = " "
}

(8 == NF) && (/^[ ]+[0-9]+: [0-9a-fA-F]+/) && ($4 !~ /FILE/) && ($8 !~ /^[$]/) {
    if (match($3, /^0x/)) {
        $3 = hexToDec($3)
    } 

    # parse properties    
    addr = $2
    SYMBOL_ARR[addr]["size"] = $3
    SYMBOL_ARR[addr]["name"] = $8
    SYMBOL_ARR[addr]["type"] = substr($4,1,1)
    SYMBOL_ARR[addr]["scope"] = substr($5,1,1)
}

END { 
    for (addr in SYMBOL_ARR) {
        printf("%d ", hexToDec(addr))
        printf("%s ", addr)
        printf("%s ", SYMBOL_ARR[addr]["size"])
        printf("%s ", SYMBOL_ARR[addr]["name"])
        printf("%s ", SYMBOL_ARR[addr]["type"])
        printf("%s ", SYMBOL_ARR[addr]["scope"])
        printf("\n")
    }
}