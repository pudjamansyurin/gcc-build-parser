#!/bin/awk -f

BEGIN {
    RS = "\n";
    FS = " "
    
    HEADER = ""
}

/Section Headers:/ {
    HEADER = "SECTION"
    next
}

HEADER == "SECTION" && /\[[ 0-9]+\][ ][a-zA-Z.]+/ && sub(/\[.*\]/, "", $0) {
    name = $1
    SECTION_ARR[name]["addr"] = $3
    SECTION_ARR[name]["size"] = $5
    SECTION_ARR[name]["flag"] = $7
    SECTION_ARR[name]["mem"] = getMemType($7)
    next
}

/Program Headers:/ {
    HEADER = "PROGRAM"
    SEGMENT = 0
    next
}

HEADER == "PROGRAM" && /LOAD/ {
    SEGMENT_ARR[SEGMENT]["rom"] = $5
    SEGMENT_ARR[SEGMENT]["ram"] = $6
    SEGMENT++
    next
}

/Section to Segment mapping:/ {
    HEADER = "SEGMENT"
    SEGMENT = 0
    next
}

HEADER == "SEGMENT" && (1 < NF) && ($0 !~ /Segment Sections/) {
    for(i=2; i<=NF; i++) {
        SEGMENT_ARR[SEGMENT]["section"][i-2] = $i
    }
    SEGMENT++
    next
}

END {     
    for (name in SECTION_ARR) {
        printf("%s ", name)
        printf("%s ", SECTION_ARR[name]["mem"])
        printf("%s ", isSectionUseROM(name))
        printf("%s ", SECTION_ARR[name]["addr"])
        printf("%s ", SECTION_ARR[name]["size"])
        printf("%s ", SECTION_ARR[name]["flag"])
        printf("\n")
    }
}

function isSectionUseROM(name) {
    irom = 0

    for (segment in SEGMENT_ARR) {
        rom = SEGMENT_ARR[segment]["rom"]

        if (0 < strtonum(rom)) {
            for (i in SEGMENT_ARR[segment]["section"]) {
                section = SEGMENT_ARR[segment]["section"][i]
                if (section == name) {
                    irom = 1
                    break
                }
            }
        }

        if (irom) {
            break
        }
    }

    return irom
}

function getMemType(flag) {
    if (!match(flag, /(W|A|X|M|S|I|L|G|T|E|O|x|o|p)+/)) {
        flag = ""
    }

    if (match(flag, /A/)) {
        mem = match(flag, /W/) ? "RAM" : "ROM"
    } else {
        mem = "DBG"
    }
    
    return mem
}