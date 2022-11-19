#!/bin/awk -f

BEGIN {
    RS = "Compilation Unit ";
    FS = "\n"
}

/DW_TAG_compile_unit/ {
    split($0, text, /(<[0-9a-fA-F]+>){2}/)

    for (i in text) {
        txt = text[i]

        if (match(txt, /(DW_TAG_compile_unit)(.*)(DW_AT_name)/)) {
            source = getField(txt, "DW_AT_name")
        }
        else if (match(txt, /(DW_TAG_subprogram)(.*)(DW_AT_name)(.*)(DW_AT_low_pc)/)) {
            getInfo(source, txt, "F")
        }
        else if (match(txt, /(DW_TAG_variable)(.*)(DW_AT_name)(.*)(DW_OP_addr)/)) {
            getInfo(source, txt, "O")
        }
    }
}

END { }

function getInfo(source, str, type) {
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
        printf("%s %s %s %s %s\n", addr, size, name, type, source)
    }
}

function getField(str, start, stop) {
    if (0 == length(stop)) {
        stop = "\n"
    }

    # get the line
    i_start = index(str, start)
    line = substr(str, i_start)
    i_stop = index(line, stop)
    line = substr(str, i_start, i_stop-1)

    # split line into fields
    split(line, fields, " ");
    return fields[length(fields)]
}