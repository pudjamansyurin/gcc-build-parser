#!/bin/awk -f

function ltrim(s) { sub(/^[ \t\r\n]+/, "", s); return s }
function rtrim(s) { sub(/[ \t\r\n]+$/, "", s); return s }
function trim(s)  { return rtrim(ltrim(s)); }

function isPath(s) { return match( s, /^[.]*\// ) }
function isLibPath(path) { return match(path, /[.]a\(.*[.].\)$/) }

function decToHex(dec) { return sprintf("%08x", dec) }
function hexToDec(hex) {
    if (!match(hex, /^0x/)) {
        hex = sprintf("0x%s", hex)
    }
    return strtonum(hex)
}
function hexToHex(str) {
    str = hexToDec(str)
    str = decToHex(str)
    return str
}

function getStrBetween(str, start, stop) {
    if (0 == length(stop)) {
        stop = "\n"
    }

    # get the line
    i_start = index(str, start)
    line = substr(str, i_start)
    i_stop = index(line, stop)
    line = substr(str, i_start+1, i_stop-2)

    return line
}

function call(cmd) {
    resp = ""
    cmd | getline resp
    close(cmd)
    return resp
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

function getLastPathDir(path) {
    n = split(path, arr, "/")
    file = arr[n] ? arr[n] : arr[n-1]
    file = toupper(file)
    gsub("_", " ", file)
    return file
}