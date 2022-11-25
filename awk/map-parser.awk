BEGIN {
    RS = "\n";
    FS = " "
}

(FILENAME == SECTION) {
    section = $1
    SECTION_ARR[section]["mem"] = $2
    SECTION_ARR[section]["irom"] = $3
    SECTION_ARR[section]["flag"] = $6
    next
}

(FILENAME == NM) {
    name = $3
    NM_ARR[name]["type"] = $4
    NM_ARR[name]["scope"] = $5
    NM_ARR[name]["class"] = $6
}

/Allocating common symbols/ {
    PART = "CMN"
    next
}

# 1 column - separated line
(PART == "CMN") && (1 == NF) {
    COMMON = $1
    next
}

# 2 column - cont'd of previous line
(PART == "CMN") && COMMON && (2 == NF) && ($1~/0x/) && ($2~/.*[.].$/) {
    setCommon(COMMON, $1, $2)
    COMMON = ""
    next
}

# 3 column - complete line
(PART == "CMN") && (3 == NF) && ($2~/0x/) && ($3~/.*[.].$/) {
    setCommon($1, $2, $3)
    next
}

/Discarded input sections/ {
    PART = "DIS"
    next
}

/Linker script and memory map/{
    PART = "MEM"
    SECTION = ""
    next
}

PART != "MEM" {
    next
} 

# 1 column - separated section line
(1 == NF) && ($0 !~ /^[ ]/) {
    SECTION = $1
    next
}

# 2/5 column - cont'd of previous section line
SECTION && (2 == NF || 5 == NF) && ($1~/0x/) && ($2~/0x/) {
    if (0 == strtonum($2)) {
        SECTION = ""
    } else {
        setSection(SECTION, $1, $2)
    }
    next
}

# 3/6 column - complete section line
(3 == NF || 6 == NF) && ($0 !~ /^[ ]/) && ($2~/0x/) && ($3~/0x/) {
    if (0 == strtonum($3)) {
        SECTION = ""
    } else {
        SECTION = $1
        setSection(SECTION, $2, $3)
    }
    next
}

!SECTION {
    next
}

# filled memory (padding)
(3 == NF) && ($1~/(*fill*)/) && ($2~/0x/) && ($3~/0x/) {
    if (SECTION) {
        size = strtonum($3)
        SECTION_ARR[SECTION]["fill"] += size
    }
    next
}

# 1 column - separated group line
(1 == NF) && ($0~/^[ ]/) && ($1 !~ /^[*]/) {
    GROUP = getUniqueGroupName($1)
    next
}

# 3 column - cont'd of previous group line
GROUP && (3 == NF) && ($1~/0x/) && ($2~/0x/) && ($3~/.*[.].*$/) {
    setGroup(SECTION, GROUP, $1, $2, $3)
    next
}

# 4 column - complete group line
(4 == NF) && ($0~/^[ ]/) && ($2~/0x/) && ($3~/0x/) && ($4~/.*[.].*$/) {
    GROUP = getUniqueGroupName($1)
    setGroup(SECTION, GROUP, $2, $3, $4)
    next
}

!GROUP {
    next
}

(2 == NF) && ($1~/0x/) && ($2 !~ /0x/) {
    symbol = $2
    addr = hexToHex($1)
    setSymbol(SECTION, GROUP, addr, symbol)
    next
}

END {
    prepareSymbol()
    print getSymbolTreeReport()
}

function setCommon(name, size, src) {
    COMMON_ARR[name]["size"] = hexToDec(size)
    COMMON_ARR[name]["src"] = src
}

function setSection(section, addr, size) {
    SECTION_ARR[section]["addr"] = hexToHex(addr)
    SECTION_ARR[section]["size"] = hexToDec(size)
    SECTION_ARR[section]["fill"] = 0
}

function setGroup(section, name, addr, size, src) {
    SECTION_ARR[section]["group"][name]["addr"] = hexToHex(addr)
    SECTION_ARR[section]["group"][name]["size"] = hexToDec(size)
    SECTION_ARR[section]["group"][name]["src"] = src
    SECTION_ARR[section]["group"][name]["symbol_cnt"] = 0
}

function setSymbol(section, group, addr, symbol) {
    group_size = SECTION_ARR[section]["group"][group]["size"]
    group_addr = SECTION_ARR[section]["group"][group]["addr"]

    # reject overflowed address
    group_end = hexToDec(group_addr) + group_size
    if (group_end == hexToDec(addr)) {
        return
    }
    
    # reject similar address
    if ((SECTION_ARR[section]["group"][group]["symbol"][addr]["name"])) {
        return
    }

    # assign size to COMMON symbol 
    size = COMMON_ARR[symbol]["size"]
    if (0 == size) {
        size = "?"
    }

    SECTION_ARR[section]["group"][group]["symbol"][addr]["name"] = symbol
    SECTION_ARR[section]["group"][group]["symbol"][addr]["size"] = size
    SECTION_ARR[section]["group"][group]["symbol_cnt"]++
}

function getUniqueGroupName(group) {
    if (SEEN[group]++) {
        group = group"."SEEN[group]
    }
    return group
}

function getSymbolFromGroup(group) {
    name = group

    # (any).name
    if (!match(name, /^([.][a-zA-Z0-9_]+)([.][0-9]+)$/)) { 
        if (match(name, /^([.][a-zA-Z0-9_]+){2}/)) {
            sub(/^[.][a-zA-Z0-9_]+[.]/,"", name)
        } 

        # name(any).(0-9)
        if (match(name, /[.][0-9]+$/)) {
            sub(/[.][0-9]+$/,"", name)
        } 

        # name.(isra|part)
        if (match(name, /[.](isra|part)$/)) {
            sub(/[.](isra|part)$/,"", name)
        }
    }

    return name
}

function prepareSymbol() {
    for (s in SECTION_ARR) {
        if (match(s, /^(.comment)/)) {
            delete SECTION_ARR[s]
            continue
        }

        if (0 == length(SECTION_ARR[s]["group"])) {
            delete SECTION_ARR[s]
            continue
        }

        if (match(s, /^(.debug)/)) {
            continue
        }

        for (g in SECTION_ARR[s]["group"]) {
            if (0 == SECTION_ARR[s]["group"][g]["symbol_cnt"]) {
                addr = SECTION_ARR[s]["group"][g]["addr"]
                symbol = getSymbolFromGroup(g)
                setSymbol(s, g, addr, symbol)
            }

            symbol_cnt = SECTION_ARR[s]["group"][g]["symbol_cnt"]
            if (0 == symbol_cnt) {
                delete SECTION_ARR[s]["group"][g]
                continue
            }

            for (a in SECTION_ARR[s]["group"][g]["symbol"]) {
                name = SECTION_ARR[s]["group"][g]["symbol"][a]["name"]
                if (length(NM_ARR[name])) {
                    type = NM_ARR[name]["type"]
                    scope = NM_ARR[name]["scope"]
                    class = NM_ARR[name]["class"]
                } else {
                    type = "?"
                    scope = "?"
                    class = "?"
                }

                size = SECTION_ARR[s]["group"][g]["symbol"][a]["size"]
                if ("?" == size) {
                    if (1 == symbol_cnt) {
                        size = SECTION_ARR[s]["group"][g]["size"]
                    }
                }

                SECTION_ARR[s]["group"][g]["symbol"][a]["size"] = size
                SECTION_ARR[s]["group"][g]["symbol"][a]["type"] = type
                SECTION_ARR[s]["group"][g]["symbol"][a]["scope"] = scope
                SECTION_ARR[s]["group"][g]["symbol"][a]["class"] = class
            }
        }
    }

    return txt
}

function getSymbolTreeReport() {
    txt = ""
    txt = txt "===========================================================================\n"
    txt = txt "                               SYMBOL TREE                                 \n"
    txt = txt "===========================================================================\n"

    for (s in SECTION_ARR) {
        txt = txt sprintf("section : %s\n", s)

        for (f in SECTION_ARR[s]) {
            if (f != "group") {
                v = SECTION_ARR[s][f]
                txt = txt sprintf(" %s : %s\n", f, v)
            } 
        }

        for (g in SECTION_ARR[s]["group"]) {
            txt = txt sprintf("  group : %s\n", g)

            for (f in SECTION_ARR[s]["group"][g]) {
                if (!match(f, /^(symbol)$/)) {
                    v = SECTION_ARR[s]["group"][g][f]
                    txt = txt sprintf("   %s : %s\n", f, v)
                } 
            }

            if (0 == length(SECTION_ARR[s]["group"][g]["symbol"])) {
                continue
            }

            for (a in SECTION_ARR[s]["group"][g]["symbol"]) {
                txt = txt sprintf("    symbol : %s\n", a)

                for (f in SECTION_ARR[s]["group"][g]["symbol"][a]) {
                    v = SECTION_ARR[s]["group"][g]["symbol"][a][f]
                    txt = txt sprintf("     %s : %s\n", f, v)
                }
            }
        }
    }

    return txt
}
