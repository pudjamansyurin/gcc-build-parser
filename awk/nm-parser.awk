#!/bin/awk -f

BEGIN {
    RS = "\n";
    FS = "|"
}

(/(.*\|){6}/) && ($3 !~ /(u|U)/) {
    # trim all fields
    for(i=1; i<=NF; i++) {
        $i = trim($i)
    }

    # parse properties
    split($7, arr, " ")
    addr = $2
    name = removeSuffix($1)

    SYMBOL_ARR[addr][name]["size"] = hexToDec($5)
    SYMBOL_ARR[addr][name]["type"] = substr($4, 1, 1)
    SYMBOL_ARR[addr][name]["scope"] = getScope($3)
    SYMBOL_ARR[addr][name]["class"] = toupper($3)
    SYMBOL_ARR[addr][name]["section"] = trim(arr[1])
    SYMBOL_ARR[addr][name]["src"] = trim(arr[2])
}

END {
    for (addr in SYMBOL_ARR) {
        for (name in SYMBOL_ARR[addr]) {
            printf("%d ", hexToDec(addr))
            printf("%s ", addr)
            printf("%s ", SYMBOL_ARR[addr][name]["size"])
            printf("%s ", name)
            printf("%s ", SYMBOL_ARR[addr][name]["type"])
            printf("%s ", SYMBOL_ARR[addr][name]["scope"])
            printf("%s ", SYMBOL_ARR[addr][name]["class"])
            # printf("%s ", SYMBOL_ARR[addr][name]["section"])
            # printf("%s ", SYMBOL_ARR[addr][name]["src"])
            printf("\n")
        }
    }
}

function getScope(class) {
    return match(class, /[A-Z]/) ? "G" : "L"
}

function removeSuffix(name) {
    # name(any).(0-9)
    if (match(name, /[.][0-9]+$/)) {
        sub(/[.][0-9]+$/,"", name)
    } 
    return name
}