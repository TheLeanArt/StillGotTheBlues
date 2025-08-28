; Super Game Boy Sound Mixer
;
; Copyright (c) 2025 Dmitry Shechtman

include "hardware.inc"
include "defs.inc"
include "charmap.inc"


SECTION "B Index", ROMX, ALIGN[8]

IndexB::

dw ValuesB._00
dw ValuesB._01
dw ValuesB._02
dw ValuesB._03
dw ValuesB._04
dw ValuesB._05
dw ValuesB._06
dw ValuesB._07
dw ValuesB._08
dw ValuesB._09
dw ValuesB._0A
dw ValuesB._0B
dw ValuesB._0C
dw ValuesB._0D
dw ValuesB._0E
dw ValuesB._0F
dw ValuesB._10
dw ValuesB._11
dw ValuesB._12
dw ValuesB._13
dw ValuesB._14
dw ValuesB._15
dw ValuesB._16
dw ValuesB._17
dw ValuesB._18
dw ValuesB._19


SECTION "B Values", ROMX

ValuesB:

._00 db TYPE_NONE
._01 db 2, "Applause",   0, "Small",      0
._02 db 2, "Applause",   0, "Medium",     0
._03 db 2, "Applause",   0, "Large",      0
._04 db 1,               0, "Wind",       0
._05 db 1,               0, "Rain",       0
._06 db 1,               0, "Storm",      0
._07 db 2, "Storm with", 0, "wind",       0
._08 db 0,               0, "Lightning",  0
._09 db 0,               0, "Earthquake", 0
._0A db 0,               0, "Avalanche",  0
._0B db 0,               0, "Wave",       0
._0C db 3,               0, "River",      0
._0D db 2,               0, "Waterfall",  0
._0E db 3, "Running",    0, "Small",      0
._0F db 3, "Running",    0, "Large",      0
._10 db 1,               0, "Warning",    0
._11 db 0, "Car",        0, "Approachin", 0
._12 db 1,               0, "Jet flying", 0
._13 db 2,               0, "UFO flying", 0
._14 db 0, "Electromag", 0, "netic wave", 0
._15 db 3,               0, "Score UP",   0
._16 db 2,               0, "Fire",       0
._17 db 3, "Camera",     0, "Shutter",    0
._18 db 0,               0, "Write",      0
._19 db 0,               0, "Show title", 0
