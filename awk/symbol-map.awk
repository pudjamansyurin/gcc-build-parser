BEGIN{
    ACTIVE = 0
}

/Linker script and memory map/{
    ACTIVE = 1
}

ACTIVE && ($1 ~ /[.](.*)/){
    SECTION = $1

    if (length(PREV)) {
        report(PREV)
    }
    PREV = ""

    if (match(SECTION, /(.rela.|.rel.)/)) {
        next
    }
    if (match(SECTION, /(.comment|.debug)/)) {
        exit
    }
    
}

ACTIVE && ($1 ~ /0x[0-9a-fA-F]+/) && ($2 ~ /0x[0-9a-fA-F]+/) && ($3 ~ /(.*)[.].$/) && strtonum($2) {
    # sum($2, $3)
    PREV = SECTION " " $0
}

ACTIVE && ($2 ~ /0x[0-9a-fA-F]+/) && ($3 ~ /0x[0-9a-fA-F]+/) && ($4 ~ /(.*)[.].$/) && strtonum($3) {
    # sum($3, $4)
    PREV = $0
}

ACTIVE && length(PREV) && ($1 ~ /0x[0-9a-fA-F]+/) && NF==2 {
    report(PREV, $2)
    PREV = ""
}

END{
    # print "==============================="
    # printf("TOTAL SIZE = %d (0x%X)\n", total_size, total_size)
    # print "==============================="
    # printf("%-10s %-10s %-10s\n", "Size", "Size (hex)", " Filename")
    # printf("%-10s %-10s %-10s\n", "====", "==========", " ========")

    # for (file in files){
    #     sizes[files[file]] = sizes[files[file]] " " file
    # }
    # n = asort(files, sorted_sizes)
    # for (i = n; i >= 1; i--){
    #     name = sizes[sorted_sizes[i]]
    #     size = sorted_sizes[i]
    #     printf("%-10d %-10s %-10s\n", size, sprintf("0x%X",size), name) 
    # }
}

function report(line, name) {
    split(line, fields, " ")
    for(i=1; i<length(fields); i++) {
        fields[i] = trim(fields[i])
    }

    section = fields[1]
    addr = fields[2]
    size = hexToDec(fields[3])
    source = fields[4]
    
    if (0 == length(name)) {
        name = section

        # (any).name
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

    printf("%s %6s %-35s %-45s %s\n", addr, size, name, section, source)
}

function sum(size_str, filename){
    if (INCLUDE != "" && (filename !~ INCLUDE)) next
    if (EXCLUDE != "" && (filename ~ EXCLUDE)) next
    size = strtonum(size_str)
    if (size > 0){
        files[filename] += size
        total_size += size
    }
}
