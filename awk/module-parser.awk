BEGIN {
    RS = "\n";
    FS = " "
}

(4 > NR) {
    next
}

($1~/^[0-9]+$/) && ($2~/^[0-9]+$/) && ($3~/^[0-9]+$/) && ($4~/^[0-9]+$/) && ($5~/^[0-9]+$/) {
    if (isPath($7)) {
        src = $7
        SIZE_ARR[src]["code"] = $1
        SIZE_ARR[src]["ro_data"] = $2
        SIZE_ARR[src]["rw_data"] = $3
        SIZE_ARR[src]["zi_data"] = $4
        SIZE_ARR[src]["debug"] = $5
    }
    else {
        type = ""
        if ($6 ~ /^Padding/) {
            type = "padding"
        }
        else if ($6 ~ /^Totals/) {
            type = "all"
        }
        
        if (type) {
            TOTAL_ARR[type]["code"] = $1
            TOTAL_ARR[type]["ro_data"] = $2
            TOTAL_ARR[type]["rw_data"] = $3
            TOTAL_ARR[type]["zi_data"] = $4
            TOTAL_ARR[type]["debug"] = $5
        }
    }
    next
}


END {
    prepareModule()
    print getModulesReport()
}

function isRelatedFile(mod, src) {
    related = 0

    if (MOD_OTHER == mod) {
        for (s in FILTERED_ARR[MOD_OTHER]) {
            if (src == s) {
                related = 1
                break
            }
        }
    } else {
        related = src ~ mod
    }

    return related
}

function prepareModule() {
    split(MOD_FILTER, mod_arr, " ")

    for (src in SIZE_ARR) {
        mod = MOD_OTHER
        for(i in mod_arr) {
            if (isRelatedFile(mod_arr[i], src)) {
                mod = mod_arr[i]
                break
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

function getTotal(type) {
    rom  = TOTAL_ARR[type]["code"]
    rom += TOTAL_ARR[type]["ro_data"]
    rom += TOTAL_ARR[type]["rw_data"]
    ram  = TOTAL_ARR[type]["rw_data"]
    ram += TOTAL_ARR[type]["zi_data"]

    txt = "------------------------------------------------------------------------------\n"
    txt = txt sprintf("%-20s %-35s %10s %10s\n", "", "TOTAL "toupper(type), rom, ram)

    return txt
}

function getModuleReport(mod) {
    module = getLastPathDir(mod)
    trom = 0
    tram = 0

    txt = "------------------------------------------------------------------------------\n"
    for (src in FILTERED_ARR[mod]) {
        if (!isRelatedFile(mod, src)) {
            continue
        }

        rom = FILTERED_ARR[mod][src]["ROM"]
        ram = FILTERED_ARR[mod][src]["RAM"]
        trom += rom
        tram += ram

        file = getFileFromPath(src)
        txt = txt sprintf("%-20s %-35s %10s %10s\n", module, file, rom, ram)

        if (module) {
            module = ""
        }
    }
    txt = txt sprintf("%-20s %-35s %10s %10s\n", "", "", trom, tram)

    return txt
}

function getModulesReport() {
    txt = ""

    txt = txt "==============================================================================\n"
    txt = txt "                                 MODULE SIZE                                  \n"
    txt = txt "==============================================================================\n"
    txt = txt sprintf("%-20s %-35s %10s %10s\n", "Module", "Object Name", "ROM Size", "RAM Size")
    for (mod in FILTERED_ARR) {
        if (MOD_OTHER != mod) {
            txt = txt getModuleReport(mod)
        }
    }
    txt = txt getModuleReport(MOD_OTHER)
    txt = txt getTotal("padding")
    txt = txt getTotal("all")

    return txt
}