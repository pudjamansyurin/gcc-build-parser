#!/bin/awk -f

BEGIN {
    RS = "\n";
    FS = "|"

    PREV_ADDR = ""
    PREV_SIZE = ""
}

(/(.*\|.*){6}/) && ($3 !~ /(u|U)/) {
    # trim all fields
    for(i=1; i<=NF; i++) {
        $i = trim($i)
    }

    # split last field into section & source
    split($7, arr, " ")
    $7 = trim(arr[1])
    $8 = trim(arr[2])

    # parse properties
    name = $1
    addr = $2
    section = $7
    source = $8
    class = toupper($3)
    type = substr($4, 1, 1)
    size = hexToDec($5)
    visible = getVisible($3)

    # transform zero size
    nocalc = "Y"
    if ((0 == size) && (length(PREV_ADDR))) {
        nocalc = "X"
        size = tfrmSize(addr, PREV_ADDR, PREV_SIZE)
    }
    PREV_ADDR = addr
    PREV_SIZE = size

    # transform source source
    source = tfrmSource(source)

    # print information
    printf("%s %d %s %s %s %s %s %s %s\n", addr, size, name, type, visible, class, nocalc, section, source)
}

END { 

}

function getVisible(class) {
    visible = "L"
    if (match(class, /[A-Z]/)) {
        visible = "G"
    }
    return visible
}

function tfrmSource(source) {
    if (match(source, /:[0-9]+$/)) {
        if (match(source, /[.](s|S):[0-9]+$/)) {
            # remove line number for asm source
            sub(/:[0-9]+$/, "", source)
        } else {
            # invalid source, non asm with line number
            source = ""
        }
    }
    return source
}

function tfrmSize(curr_addr, prev_addr, prev_size) {
    size = 0

    if (curr_addr == prev_addr) {
        # assign same size for same address
        size = prev_size
    } 
    else if (prev_addr > curr_addr) {
        # calculate address difference
        prv_addr = hexToDec(prev_addr)
        cur_addr = hexToDec(curr_addr)
        size = prv_addr - cur_addr
    }

    return size
}