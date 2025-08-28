; Super Game Boy Sound Mixer
;
; Copyright (c) 2025 Dmitry Shechtman

include "hardware.inc"
include "defs.inc"
include "charmap.inc"


SECTION "A Index", ROMX, ALIGN[8]

IndexA::

dw ValuesA._00
dw ValuesA._01
dw ValuesA._02
dw ValuesA._03
dw ValuesA._04
dw ValuesA._05
dw ValuesA._06
dw ValuesA._07
dw ValuesA._08
dw ValuesA._09
dw ValuesA._0A
dw ValuesA._0B
dw ValuesA._0C
dw ValuesA._0D
dw ValuesA._0E
dw ValuesA._0F
dw ValuesA._10
dw ValuesA._11
dw ValuesA._12
dw ValuesA._13
dw ValuesA._14
dw ValuesA._15
dw ValuesA._16
dw ValuesA._17
dw ValuesA._18
dw ValuesA._19
dw ValuesA._1A
dw ValuesA._1B
dw ValuesA._1C
dw ValuesA._1D
dw ValuesA._1E
dw ValuesA._1F
dw ValuesA._20
dw ValuesA._21
dw ValuesA._22
dw ValuesA._23
dw ValuesA._24
dw ValuesA._25
dw ValuesA._26
dw ValuesA._27
dw ValuesA._28
dw ValuesA._29
dw ValuesA._2A
dw ValuesA._2B
dw ValuesA._2C
dw ValuesA._2D
dw ValuesA._2E
dw ValuesA._2F
dw ValuesA._30


SECTION "A Values", ROMX

ValuesA:
._00 db TYPE_NONE
._01 db 3 | TYPE_LOGO
._02 db 3,               0, "Game Over",  0
._03 db 3,               0, "Drop",       0
._04 db 3,               0, "OK A",       0
._05 db 3,               0, "OK B",       0
._06 db 3,               0, "Select A",   0
._07 db 3,               0, "Select B",   0
._08 db 2,               0, "Select C",   0
._09 db 2,               0, "Buzzer",     0
._0A db 2,               0, "Catch Item", 0
._0B db 2, "One Knock",  0, "on door",    0
._0C db 1, "Explosion",  0, "Small",      0
._0D db 1, "Explosion",  0, "Medium",     0
._0E db 1, "Explosion",  0, "Large",      0
._0F db 3,               0, "Defeat A",   0
._10 db 3,               0, "Defeat B",   0
._11 db 0,               0, "Attack A",   0
._12 db 0,               0, "Attack B",   0
._13 db 3,               0, "Breath in",  0
._14 db 3,               0, "Rocket A",   0
._15 db 3,               0, "Rocket B",   0
._16 db 2, "Bubbling",   0, "Water",      0
._17 db 3,               0, "Jump",       0
._18 db 3,               0, "Fast jump",  0
._19 db 0, "Jet/Rocket", 0, "taking off", 0
._1A db 0, "Jet/Rocket", 0, "landing",    0
._1B db 2, "Cup",        0, "breaking",   0
._1C db 1, "Glass",      0, "breaking",   0
._1D db 2,               0, "Level UP",   0
._1E db 1,               0, "Inject air", 0
._1F db 1, "Sword",      0, "wielding",   0
._20 db 2, "Falling in", 0, "water",      0
._21 db 1,               0, "Fire",       0
._22 db 1, "Wall",       0, "collapsing", 0
._23 db 1,               0, "Cancel",     0
._24 db 1,               0, "Walking",    0
._25 db 1, "Blocking",   0, "strike",     0
._26 db 3, "Picture",    0, "floating",   0
._27 db 0, "Screen",     0, "fading in",  0
._28 db 0, "Screen",     0, "fading out", 0
._29 db 1, "Window",     0, "opening",    0
._2A db 0, "Window",     0, "closing",    0
._2B db 3, "Laser",      0, "Large",      0
._2C db 0, "Stone gate", 0, "open/close", 0
._2D db 3,               0, "Teleport",   0
._2E db 0,               0, "Lightning",  0
._2F db 0,               0, "Earthquake", 0
._30 db 2, "Laser",      0, "Small",      0
