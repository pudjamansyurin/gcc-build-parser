BEGIN {
    RS = "\n";
    FS = " "
}

(4 > NR) {
    next
}

/^[ ]{0}(section :)/ {
    SECTION = $3
    next
}

length(SECTION) && /^[ ]{1}[a-z_]+ :/ {
    SECTION_ARR[SECTION][$1] = $3
    next
}

length(SECTION) && /^[ ]{2}(group :)/ {
    GROUP = $3
    next
}

length(GROUP) && /^[ ]{3}[a-z_]+ :/ {
    SECTION_ARR[SECTION]["group"][GROUP][$1] = $3
    next
}

length(GROUP) && /^[ ]{4}(symbol :)/ {
    SYMBOL = $3
    next
}

length(SYMBOL) && /^[ ]{5}[a-z_]+ :/ {
    SECTION_ARR[SECTION]["group"][GROUP]["symbol"][SYMBOL][$1] = $3
    next
}

{
    SECTION = ""
    GROUP = ""
    SYMBOL = ""
}

END {
    prepareFile()
    print getFilesReport()
}

function addAreaSize(area, size, src, kind) {
    if (src && kind) {
        TOTAL_ARR[kind][area] += size
        SIZE_ARR[src][area] += size
    } else {
        FILL_ARR[area] += size
    }
}

function getAreaType(mem, flag, irom) {
    area = "debug"
    if ("ROM" == mem) {
        area = match(flag, /X/) ? "code" : "ro_data"
    }
    else if ("RAM" == mem) {
        area = irom ? "rw_data" : "zi_data"
    }
    return area
}

function prepareFile() {
    for (s in SECTION_ARR) {
        mem = SECTION_ARR[s]["mem"]
        fill = SECTION_ARR[s]["fill"]
        flag = SECTION_ARR[s]["flag"]
        irom = SECTION_ARR[s]["irom"]

        area = getAreaType(mem, flag, irom)
        addAreaSize(area, fill)

        for (g in SECTION_ARR[s]["group"]) {
            size = SECTION_ARR[s]["group"][g]["size"]
            src = SECTION_ARR[s]["group"][g]["src"]
            kind = isLibPath(src) ? "Library" : "Object"
            addAreaSize(area, size, src, kind)
        }
    }
}

function getAreaLine(code, ro, rw, zi, debug) {
    txt = ""
    txt = txt sprintf("%10d ", code)
    txt = txt sprintf("%10d ", ro)
    txt = txt sprintf("%10d ", rw)
    txt = txt sprintf("%10d ", zi)
    txt = txt sprintf("%10d ", debug)
    return txt
}

function getAreaSize() {
    for(kind in TOTAL_ARR) {
        for(area in TOTAL_ARR[kind]) {
            area_arr[area] += TOTAL_ARR[kind][area]
        }
    }
    for(area in FILL_ARR) {
        area_arr[area] += FILL_ARR[area]
    }
    
    code = area_arr["code"]
    ro = area_arr["ro_data"]
    rw = area_arr["rw_data"]
    zi = area_arr["zi_data"]
    debug = area_arr["debug"]
    
    txt = getAreaLine(code, ro, rw, zi, debug)
    txt = txt sprintf("  %-22s\n", "Totals")

    return txt
}

function getAreaSizeIn(kind) {    
    if ("Padding" == kind) {
        code = FILL_ARR["code"]
        ro = FILL_ARR["ro_data"]
        rw = FILL_ARR["rw_data"]
        zi = FILL_ARR["zi_data"]
        debug = FILL_ARR["debug"]
    } 
    else {
        code = TOTAL_ARR[kind]["code"]
        ro = TOTAL_ARR[kind]["ro_data"]
        rw = TOTAL_ARR[kind]["rw_data"]
        zi = TOTAL_ARR[kind]["zi_data"]
        debug = TOTAL_ARR[kind]["debug"]
    }
    
    txt = getAreaLine(code, ro, rw, zi, debug)
    txt = txt sprintf("  %-22s\n", kind" Totals")
    txt = txt "-------------------------------------------------------------------------------\n"
    
    return txt
}

function getFileSizeIn(kind) {
    txt = sprintf("%10s %10s %10s %10s %10s  %-23s\n", "Code", "RO Data", "RW Data", "ZI Data", "Debug", kind" Name")

    for (src in SIZE_ARR) {
        lib = isLibPath(src)
        if (kind == "Object") {
            if (lib) {
                continue
            }
        } else {
            if (!lib) {
                continue
            }
        }

        code = SIZE_ARR[src]["code"]
        ro = SIZE_ARR[src]["ro_data"]
        rw = SIZE_ARR[src]["rw_data"]
        zi = SIZE_ARR[src]["zi_data"]
        debug = SIZE_ARR[src]["debug"]

        file = getFileFromPath(src)
        if (lib) {
            sub(/\(.*[.].\)$/, "", src)
        }

        txt = txt getAreaLine(code, ro, rw, zi, debug)
        txt = txt sprintf(" %-23s", file)
        txt = txt sprintf("  %s", src)
        txt = txt "\n"
    }

    txt = txt "-------------------------------------------------------------------------------\n"
    return txt
}

function getFilesReport() {
    txt = ""

    txt = txt "===============================================================================\n"
    txt = txt "                                  FILE SIZE                                    \n"
    txt = txt "===============================================================================\n"

    txt = txt getFileSizeIn("Object")
    txt = txt getAreaSizeIn("Object")
    txt = txt getFileSizeIn("Library")
    txt = txt getAreaSizeIn("Library")
    txt = txt getAreaSizeIn("Padding")
    txt = txt getAreaSize()

    return txt
}