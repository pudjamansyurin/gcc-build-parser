#!/bin/awk -f

BEGIN {
    RS = "\n";
    FS = " "
}

(/^(.*)([0-9]+): ([0-9a-fA-F]+)/) && ($2 !~ /(0){8}/) && (0 < $3) {
    if (match($3, /^0x/)) {
        $3 = hexToDec($3)
    } 

    # parse properties
    name = $8
    addr = $2
    size = $3
    type = substr($4,1,1)
    visible = substr($5,1,1)

    printf("%d %s %s %s %s %s\n", hexToDec(addr), addr, size, name, type, visible) 
}

END { 

}