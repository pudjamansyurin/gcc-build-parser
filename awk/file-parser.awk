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

function prepareFile() {
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

function getAreaSize() {
    for(kind in TOTAL_ARR) {
        for(area in TOTAL_ARR[kind]) {
            area_arr[area] += TOTAL_ARR[kind][area]
        }
    }
    for(area in FILL_ARR) {
        area_arr[area] += FILL_ARR[area]
    }
    
    txt = ""
    txt = txt sprintf("%10d ", area_arr["code"])
    txt = txt sprintf("%10d ", area_arr["ro_data"])
    txt = txt sprintf("%10d ", area_arr["rw_data"])
    txt = txt sprintf("%10d ", area_arr["zi_data"])
    txt = txt sprintf("%10d ", area_arr["debug"])
    txt = txt sprintf("  %-22s\n", "Totals")
    return txt
}

function getAreaSizeIn(kind) {
    txt = ""
    
    if ("Padding" == kind) {
        code = FILL_ARR["code"]
        debug = FILL_ARR["debug"]
        ro_data = FILL_ARR["ro_data"]
        rw_data = FILL_ARR["rw_data"]
        zi_data = FILL_ARR["zi_data"]
    } 
    else {
        code = TOTAL_ARR[kind]["code"]
        debug = TOTAL_ARR[kind]["debug"]
        ro_data = TOTAL_ARR[kind]["ro_data"]
        rw_data = TOTAL_ARR[kind]["rw_data"]
        zi_data = TOTAL_ARR[kind]["zi_data"]
    }
    
    txt = txt sprintf("%10d ", code)
    txt = txt sprintf("%10d ", ro_data)
    txt = txt sprintf("%10d ", rw_data)
    txt = txt sprintf("%10d ", zi_data)
    txt = txt sprintf("%10d ", debug)
    txt = txt sprintf("  %-22s\n", kind" Totals")

    txt = txt "-------------------------------------------------------------------------------\n"
    return txt
}

function getFileSizeIn(kind) {
    title = kind
    if ("Library" == kind) {
        title = kind " Member"
    }
    txt = sprintf("%10s %10s %10s %10s %10s  %-23s\n", "Code", "RO Data", "RW Data", "ZI Data", "Debug", title" Name")

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

        txt = txt sprintf("%10d ", SIZE_ARR[src]["code"])
        txt = txt sprintf("%10d ", SIZE_ARR[src]["ro_data"])
        txt = txt sprintf("%10d ", SIZE_ARR[src]["rw_data"])
        txt = txt sprintf("%10d ", SIZE_ARR[src]["zi_data"])
        txt = txt sprintf("%10d ", SIZE_ARR[src]["debug"])

        file = getFileFromPath(src)
        if (match(src, /[.]a\(.*[.].\)$/)) {
            sub(/\(.*[.].\)$/, "", src)
        }

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