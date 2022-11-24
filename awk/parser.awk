BEGIN {
    RS = "\n";
    FS = " "
}

(FILENAME == SECTION) {
    section = $1
    SECTION_ARR[section]["mem"] = $2
    SECTION_ARR[section]["use_rom"] = $3
    SECTION_ARR[section]["flag"] = $6
    next
}

(FILENAME == NM) {
    name = $3
    NM_ARR[name]["type"] = $4
    NM_ARR[name]["scope"] = $5
    NM_ARR[name]["class"] = $6
}

(FILENAME == DWARF) {
    # nothing todo yet
}

(FILENAME == READELF) {
    # nothing todo yet
}

(FILENAME != MAP) {
    PART = ""
    next
}

/Allocating common symbols/ {
    PART = "CMN"
    next
}

# 1 column - separated line
(PART == "CMN") && (1 == NF) {
    COMMON_NAME = $1
    next
}

# 2 column - cont'd of previous line
(PART == "CMN") && (2 == NF) && ($1~/0x/) && ($2~/.*[.].$/) {
    setCommon(COMMON_NAME, $1, $2)
    next
}

# 3 column - complete line
(PART == "CMN") && (3 == NF) && ($2~/0x/) && ($3~/.*[.].$/) {
    COMMON_NAME = $1
    setCommon(COMMON_NAME, $2, $3)
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
    GROUP = getGroupName($1)
    next
}

# 3 column - cont'd of previous group line
GROUP && (3 == NF) && ($1~/0x/) && ($2~/0x/) && ($3~/.*[.].*$/) {
    setGroup(SECTION, GROUP, $1, $2, $3)
    next
}

# 4 column - complete group line
(4 == NF) && ($0~/^[ ]/) && ($2~/0x/) && ($3~/0x/) && ($4~/.*[.].*$/) {
    GROUP = getGroupName($1)
    setGroup(SECTION, GROUP, $2, $3, $4)
    next
}

!GROUP {
    next
}

(2 == NF) && ($1~/0x/) && ($2 !~ /0x/) {
    symbol = $2
    addr = hexToDec($1)
    addr = decToHex(addr)
    setGroupSymbol(SECTION, GROUP, addr, symbol)
    next
}

END {
    processSymbol()
    calcAreaSize()

    print getModulesReport()
    print getFilesReport()
    print getSymbolLineReport()
    # print getSymbolTreeReport()
}

function setCommon(name, size, src) {
    size = hexToDec(size)
    COMMON_ARR[name]["size"] = size
    COMMON_ARR[name]["src"] = src
}

function setSection(section, addr, size) {
    addr = hexToDec(addr)
    addr = decToHex(addr)
    size = hexToDec(size)
    SECTION_ARR[section]["addr"] = addr
    SECTION_ARR[section]["size"] = size
    SECTION_ARR[section]["fill"] = 0
}

function setGroup(section, name, addr, size, src) {
    addr = hexToDec(addr)
    addr = decToHex(addr)
    size = hexToDec(size)

    SECTION_ARR[section]["group"][name]["addr"] = addr
    SECTION_ARR[section]["group"][name]["size"] = size
    SECTION_ARR[section]["group"][name]["src"] = src
    SECTION_ARR[section]["group"][name]["symbol_cnt"] = 0
}

function setGroupSymbol(section, group, addr, symbol) {
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

function getGroupName(group) {
    # add numeric suffix
    if (SEEN[group]++) {
        group = group"."SEEN[group]
    }
    return group
}

function getSymbolFromGroup(section) {
    name = section

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

function getFileFromPath(path) {
    n = split(path, arr, "/")
    file = arr[n]
    if (match(file, /[.]a\(.*[.].\)$/)) {
        sub(/^.*\(/, "", file)
        sub(/\)$/, "", file)
    }
    return file
}

function getModuleFromPath(path) {
    n = split(path, arr, "/")
    file = arr[n]
    if (!file) {
        file = arr[n-1]
    }
    sub("_", " ", file)
    return toupper(file)
}

function processSymbol() {
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
                setGroupSymbol(s, g, addr, symbol)
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

function addAreaSize(area, size, src, kind) {
    if (src && kind) {
        TOTAL_ARR[kind][area] += size
        SIZE_ARR[src][area] += size
    } else {
        FILL_ARR[area] += size
    }
}

function getAreaType(mem, flag, use_rom) {
    area = "debug"
    if ("ROM" == mem) {
        area = "ro_data"
        if (match(flag, /X/)) {
            area = "code"
        }
    }
    else if ("RAM" == mem) {
        area = "zi_data"
        if (use_rom) {
            area = "rw_data"
        }
    }
    return area
}

function calcAreaSize() {
    for (s in SECTION_ARR) {
        mem = SECTION_ARR[s]["mem"]
        fill = SECTION_ARR[s]["fill"]
        flag = SECTION_ARR[s]["flag"]
        use_rom = SECTION_ARR[s]["use_rom"]

        area = getAreaType(mem, flag, use_rom)
        addAreaSize(area, fill)

        for (g in SECTION_ARR[s]["group"]) {
            size = SECTION_ARR[s]["group"][g]["size"]
            src = SECTION_ARR[s]["group"][g]["src"]
            if (match(src, /\(.*[.].\)$/)) {
                kind = "Library"
            } else {
                kind = "Object"
            }

            addAreaSize(area, size, src, kind)
        }
    }
}

function getAreaTotal() {
    for(kind in TOTAL_ARR) {
        for(area in TOTAL_ARR[kind]) {
            area_arr[area] += TOTAL_ARR[kind][area]
        }
    }
    for(area in FILL_ARR) {
        area_arr[area] += FILL_ARR[area]
    }
    
    txt = ""
    txt = txt sprintf("%10d", area_arr["code"])
    txt = txt sprintf("%10d", area_arr["ro_data"])
    txt = txt sprintf("%10d", area_arr["rw_data"])
    txt = txt sprintf("%10d", area_arr["zi_data"])
    txt = txt sprintf("%10d", area_arr["debug"])
    txt = txt sprintf("  %-23s\n", "Totals")
    return txt
}

function getAreaTotalIn(kind) {
    txt = ""
    txt = txt sprintf("%10d", TOTAL_ARR[kind]["code"])
    txt = txt sprintf("%10d", TOTAL_ARR[kind]["ro_data"])
    txt = txt sprintf("%10d", TOTAL_ARR[kind]["rw_data"])
    txt = txt sprintf("%10d", TOTAL_ARR[kind]["zi_data"])
    txt = txt sprintf("%10d", TOTAL_ARR[kind]["debug"])
    txt = txt sprintf("  %-23s\n", kind" Totals")

    if ("Object" == kind) {
        txt = txt sprintf("%10d", FILL_ARR["code"])
        txt = txt sprintf("%10d", FILL_ARR["ro_data"])
        txt = txt sprintf("%10d", FILL_ARR["rw_data"])
        txt = txt sprintf("%10d", FILL_ARR["zi_data"])
        txt = txt sprintf("%10d", FILL_ARR["debug"])
        txt = txt sprintf("  %-23s\n", "(incl. Padding)")
    }
    return txt
}

function getFileSizeIn(kind) {
    title = kind
    if ("Library" == kind) {
        title = kind " Member"
    }
    txt = sprintf("%10s%10s%10s%10s%10s  %-23s\n\n", "Code", "RO Data", "RW Data", "ZI Data", "Debug", title" Name")

    for (src in SIZE_ARR) {
        lib = match(src, /[.]a\(.*[.].\)$/)
        if (kind == "Object") {
            if (lib) {
                continue
            }
        } else {
            if (!lib) {
                continue
            }
        }

        txt = txt sprintf("%10d", SIZE_ARR[src]["code"])
        txt = txt sprintf("%10d", SIZE_ARR[src]["ro_data"])
        txt = txt sprintf("%10d", SIZE_ARR[src]["rw_data"])
        txt = txt sprintf("%10d", SIZE_ARR[src]["zi_data"])
        txt = txt sprintf("%10d", SIZE_ARR[src]["debug"])

        file = getFileFromPath(src)
        if (match(src, /[.]a\(.*[.].\)$/)) {
            sub(/\(.*[.].\)$/, "", src)
        }

        txt = txt sprintf("  %-23s", file)
        # txt = txt sprintf("  %s", src)
        txt = txt "\n"
    }

    return txt
}

function calcModuleSize(other) {
    split(MOD_FILTER, mod_arr, " ")

    for (src in SIZE_ARR) {
        mod = other
        for(i in mod_arr) {
            if (src ~ mod_arr[i]) {
                mod = mod_arr[i]
            }
        }

        rom  = SIZE_ARR[src]["code"]
        rom += SIZE_ARR[src]["ro_data"]
        rom += SIZE_ARR[src]["rw_data"]
        ram  = SIZE_ARR[src]["rw_data"]
        ram += SIZE_ARR[src]["zi_data"]

        FILTERED_ARR[mod][src]["ROM"] = rom
        FILTERED_ARR[mod][src]["RAM"] = ram
    }
}

function getModuleReport(mod) {
    txt = ""

    mod_name = getModuleFromPath(mod)
    total["ROM"] = 0
    total["RAM"] = 0
    line = 0

    txt = txt "---------------------------------------------------------------------------\n"
    for (src in FILTERED_ARR[mod]) {
        related = 0
        if (other == mod) {
            for (s in FILTERED_ARR[other]) {
                if (src == s) {
                    related = 1
                    break
                }
            }
        } else {
            related = src ~ mod
        }

        if (!related) {
            continue
        }

        rom = FILTERED_ARR[mod][src]["ROM"]
        total["ROM"] += rom

        ram = FILTERED_ARR[mod][src]["RAM"]
        total["RAM"] += ram

        file = getFileFromPath(src)
        title = mod_name
        if (line++) {
            title = ""
        }

        txt = txt sprintf("%-20s%-35s%10s%10s\n", title, file, rom, ram)
    }
    txt = txt sprintf("%-20s%-35s%10s%10s\n", "", "", total["ROM"], total["RAM"])

    return txt
}

function getModulesReport() {
    other = "other"
    calcModuleSize(other)

    txt = ""
    txt = txt "===========================================================================\n"
    txt = txt "                               MODULE SIZE                                 \n"
    txt = txt "===========================================================================\n"
    txt = txt sprintf("%-20s%-35s%10s%10s\n\n", "Module", "File Name", "ROM Size", "RAM Size")
    for (mod in FILTERED_ARR) {
        if (other != mod) {
            txt = txt getModuleReport(mod)
        }
    }
    txt = txt getModuleReport(other)

    return txt
}

function getFilesReport() {
    txt = ""
    txt = txt "===========================================================================\n"
    txt = txt "                                FILE SIZE                                  \n"
    txt = txt "===========================================================================\n"

    txt = txt getFileSizeIn("Object")
    txt = txt "\n---------------------------------------------------------------------------\n"
    txt = txt getAreaTotalIn("Object")
    txt = txt "\n---------------------------------------------------------------------------\n"
    txt = txt getFileSizeIn("Library")
    txt = txt "\n---------------------------------------------------------------------------\n"
    txt = txt getAreaTotalIn("Library")
    txt = txt "\n---------------------------------------------------------------------------\n"
    txt = txt getAreaTotal()
    return txt
}

function getSymbolLineReport() {
    txt = ""
    txt = txt "===========================================================================\n"
    txt = txt "                               SYMBOL LINE                                 \n"
    txt = txt "===========================================================================\n"
    txt = txt sprintf("%-36s %8s %5s  %-22s\n\n", "Symbol Name", "Address", "Size", "File")

    for (s in SECTION_ARR) {
        if (match(s, /^(.debug)/)) {
            continue
        }

        for (g in SECTION_ARR[s]["group"]) {
            if (0 == length(SECTION_ARR[s]["group"][g]["symbol"])) {
                continue
            }
            src = SECTION_ARR[s]["group"][g]["src"]
            # src = getFileFromPath(src)

            for (a in SECTION_ARR[s]["group"][g]["symbol"]) {
                name = SECTION_ARR[s]["group"][g]["symbol"][a]["name"]
                size = SECTION_ARR[s]["group"][g]["symbol"][a]["size"]
                txt = txt sprintf("%-36s %8s %5s  %-22s\n", name, a, size, src)
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
        if (match(s, /^(.debug)/)) {
            continue
        }

        txt = txt "section:\n"
        txt = txt sprintf("  name: %s\n", s)

        for (f in SECTION_ARR[s]) {
            if (f != "group") {
                v = SECTION_ARR[s][f]
                txt = txt sprintf("  %s: %s\n", f, v)
            } 
        }

        for (g in SECTION_ARR[s]["group"]) {
            txt = txt "\tgroup:\n"
            txt = txt sprintf("\t  name: %s\n", g)

            for (f in SECTION_ARR[s]["group"][g]) {
                if (!match(f, /^(symbol)$/)) {
                    v = SECTION_ARR[s]["group"][g][f]
                    txt = txt sprintf("\t  %s: %s\n", f, v)
                } 
            }

            if (0 == length(SECTION_ARR[s]["group"][g]["symbol"])) {
                continue
            }

            for (a in SECTION_ARR[s]["group"][g]["symbol"]) {
                txt = txt "\t\tsymbol:\n"
                txt = txt sprintf("\t\t  addr: %s\n", a)

                for (f in SECTION_ARR[s]["group"][g]["symbol"][a]) {
                    v = SECTION_ARR[s]["group"][g]["symbol"][a][f]
                    txt = txt sprintf("\t\t  %s: %s\n", f, v)
                }
            }
        }
    }

    return txt
}
