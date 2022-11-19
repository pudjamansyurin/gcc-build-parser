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

function call(cmd) {
    resp = ""
    cmd | getline resp
    close(cmd)
    return resp
}
