#!/bin/awk -f

BEGIN {
    RS = "Compilation Unit ";
    FS = "\n"
}

/DW_TAG_compile_unit/ {
    split($0, text, /(<[0-9a-fA-F]+>){2}/)

    for (i in text) {
        txt = text[i]

        if (match(txt, /(DW_TAG_compile_unit).*(DW_AT_name)/)) {
            src = getField(txt, "DW_AT_name")
        }
        else if (match(txt, /(DW_TAG_subprogram).*(DW_AT_name).*(DW_AT_low_pc)/)) {
            setSymbol(src, txt, "F")
        }
        else if (match(txt, /(DW_TAG_variable).*(DW_AT_name).*(DW_OP_addr)/)) {
            setSymbol(src, txt, "O")
        }
    }
}

END { 
    for (addr in SYMBOL_ARR) {
        printf("%d ", hexToDec(addr))
        printf("%s ", addr)
        printf("%s ", SYMBOL_ARR[addr]["size"])
        printf("%s ", SYMBOL_ARR[addr]["name"])
        printf("%s ", SYMBOL_ARR[addr]["type"])
        # printf("%s ", SYMBOL_ARR[addr]["src"])
        printf("\n")
    }
}

function setSymbol(src, str, type) {
    if ("F" == type ) {
        size = getField(str, "DW_AT_high_pc")
        addr = getField(str, "DW_AT_low_pc")
    } else {
        size = "0x0"
        addr = getField(str, "DW_OP_addr", ")")
    }
    size = hexToDec(size)
    addr = hexToDec(addr)

    if (0 != addr) {
        addr = decToHex(addr)
        name = getField(str, "DW_AT_name")

        SYMBOL_ARR[addr]["size"] = size
        SYMBOL_ARR[addr]["name"] = name
        SYMBOL_ARR[addr]["type"] = type
        SYMBOL_ARR[addr]["src"] = src
    }
}

function getField(str, start, stop) {
    line = getStrBetween(str, start, stop)
    n = split(line, fields, " ");
    return fields[n]
}