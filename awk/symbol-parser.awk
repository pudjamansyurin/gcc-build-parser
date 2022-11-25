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
    print getSymbolLineReport()
}

function getTitleByType(type) {
    if ("F" == type) {
        title = "Function"
    }
    else if ("O" == type) {
        title = "Variable"
    }
    else if ("N" == type) {
        title = "Assembly"
    }
    else {
        title = "Unknown"
    }
    return title
}

function getSymbolByType(type) {
    title = getTitleByType(type)

    txt = ""
    txt = txt "===========================================================================\n"
    txt = txt sprintf("                             %10s LIST                               \n", toupper(title))
    txt = txt "===========================================================================\n"
    txt = txt sprintf("%-36s %8s %5s  %-22s\n", title" Name", "Address", "Size", "File")

    for (s in SECTION_ARR) {
        if (match(s, /^(.debug)/)) {
            continue
        }

        for (g in SECTION_ARR[s]["group"]) {
            src = SECTION_ARR[s]["group"][g]["src"]
            file = getFileFromPath(src)

            for (a in SECTION_ARR[s]["group"][g]["symbol"]) {
                typ = SECTION_ARR[s]["group"][g]["symbol"][a]["type"]
                if (type == typ) {
                    name = SECTION_ARR[s]["group"][g]["symbol"][a]["name"]
                    size = SECTION_ARR[s]["group"][g]["symbol"][a]["size"]
                    txt = txt sprintf("%-36s %8s %5s  %-22s  %s\n", name, a, size, file, src)
                }
            }
        }
    }
    txt = txt "\n"

    return txt
}

function getSymbolLineReport() {
    txt = ""
    txt = txt getSymbolByType("F")
    txt = txt getSymbolByType("O")
    txt = txt getSymbolByType("N")
    txt = txt getSymbolByType("?")

    return txt
}