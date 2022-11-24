#!/bin/awk -f

function ltrim(s) { sub(/^[ \t\r\n]+/, "", s); return s }
function rtrim(s) { sub(/[ \t\r\n]+$/, "", s); return s }
function trim(s)  { return rtrim(ltrim(s)); }

function decToHex(dec) { return sprintf("%08x", dec) }
function hexToDec(hex) {
    if (!match(hex, /^0x/)) {
        hex = sprintf("0x%s", hex)
    }
    return strtonum(hex)
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

function isArray(x) {
  return length(x) > 0 && length(x "") == 0
}

function call(cmd) {
    resp = ""
    cmd | getline resp
    close(cmd)
    return resp
}
