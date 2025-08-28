; Super Game Boy Sound Mixer
;
; Copyright (c) 2025 Dmitry Shechtman


DEF X_TOP_A         EQU    0
DEF X_TOP_B         EQU SCREEN_WIDTH_PX
DEF X_BOTTOM_OFS    EQU WX_OFS

DEF X_A             EQU -119
DEF X_A_DELTA       EQU   -4
DEF X_A_OAM         EQU  152
DEF X_A_VRAM        EQU   96
DEF X_A_FINAL       EQU X_TOP_A
DEF X_A_FINAL_A     EQU  -31
DEF X_A_FINAL_B     EQU    0

DEF X_B             EQU  145
DEF X_B_DELTA       EQU    4
DEF X_B_OAM         EQU   48
DEF X_B_VRAM        EQU   96
DEF X_B_FINAL       EQU X_TOP_B
DEF X_B_FINAL_A     EQU    0
DEF X_B_FINAL_B     EQU   -7

; TODO Magic
DEF REG_X_TOP       EQU $FFFA 
DEF REG_X_BOTTOM    EQU $FFFE 

MACRO IS_SOUND_B
	ldh a, [hSelection.topAddr]
	ld c, a
	ldh a, [c]
	bit B_SOUND_B, a
ENDM

MACRO SELECT_TOP
	ldh a, [hSelection.topAddr]
	or a
	jp z, ShakeTop\2
	ld a, LOW(hSelection.\1)
	ldh [hSelection.bottomAddr], a
	ld c, a
	ldh a, [hSelection]
	ldh [c], a
	IS_SOUND_B
	jr nz, .topB
.topA
	call DoSoundA
	ldh a, [hSelection.topAddr]
	cp LOW(hSelection.soundAHoriz)
	jr nz, .cont
	ldh a, [hSoundA.typeLow]
	ld b, a
	ldh a, [hSoundA.typeHigh]
	or b
	jr nz, .cont
	ld a, LOW(hSelection.soundAVert)
	jr .cont
.topB
	call DoSoundB
	ldh a, [hSelection.topAddr]
	cp LOW(hSelection.soundBHoriz)
	jr nz, .cont
	ldh a, [hSoundB.typeLow]
	ld b, a
	ldh a, [hSoundB.typeHigh]
	or b
	jr nz, .cont
	ld a, LOW(hSelection.soundBVert)
.cont
	ld c, a
	ldh a, [c]
ENDM

MACRO SELECT_BOTTOM
	ld a, LOW(hSelection.\1)
	ldh [hSelection.topAddr], a
	ld c, a
	ldh a, [hSelection]
	ldh [c], a
	call DoCh4
	ldh a, [hSelection.bottomAddr]
	ld c, a
	ldh a, [c]
ENDM

MACRO DO_SOUND_A
	bit B_PAD_START, b
	jr z, .cont\@
	call DoSoundAB
	call DoCh4
	jr .end\@
.cont\@
	bit B_PAD_A, b
	jr z, .end\@
	call DoSoundA
.end\@
ENDM

MACRO DO_SOUND_B
	bit B_PAD_START, b
	jr z, .cont\@
	call DoSoundAB
	call DoCh4
	jr .end\@
.cont\@
	bit B_PAD_A, b
	jr z, .end\@
	call DoSoundB
.end\@
ENDM

MACRO DO_CH4
	ld a, b
	and 1 << B_PAD_START | 1 << B_PAD_B
	jr z, .end\@
	bit B_PAD_START, a
	jr z, .ch4\@
	call DoSoundAB
.ch4\@
	call DoCh4
.end\@
ENDM
