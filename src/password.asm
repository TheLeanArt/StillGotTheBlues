; Super Game Boy Sound Mixer
;
; Copyright (c) 2025 Dmitry Shechtman

include "hardware.inc"
include "defs.inc"
include "macros.inc"
include "sound.inc"
include "update.inc"
include "trans.inc"


SECTION "Display Password", ROM0

DoPassword::
	ld hl, hPassword
	SOUND_TYPE_LEN
	ld [hli], a
	ldh a, [hSoundA.typeLow]
	ld [hli], a
	ldh a, [hSoundB.typeLow]
	ld [hli], a
	SOUND_A_ATTRS
	ld [hli], a
	SOUND_B_ATTRS_BASE
	ld [hli], a
	ld a, d
	xor $0F
	ld [hli], a
	ldh a, [hCH4.vol]
	ld [hli], a
	AUD4ENV_BASE 0
	ld [hli], a
	ldh a, [hCH4.pitch]
	xor $0F
	ld [hli], a
	AUD4POLY_BASE 0
	ld [hli], a

	rst WaitVBlank
	ld hl, TILEMAP0 + 7 * TILEMAP_WIDTH
	ldh a, [hSelection.topAddr]
	or a
	jr z, .preNone
	ld c, a
	ldh a, [c]
	bit B_SOUND_B, a
	ld a, T_BRD_BOTTOM_LEFT
	jr nz, .preB

.preA
	ld [hli], a
	SET_SHORT T_BRD_BOTTOM, 2
	ld a, T_BRD_TOP_BOTTOM
	ld bc, T_BRD_DOT_BTM_RIGHT << 8 | 16
	jr .preLoop

.preB
	ld l, 7 * TILEMAP_WIDTH + SCREEN_WIDTH
	ld [hli], a
	SET_SHORT T_BRD_BOTTOM, 5
	BORDER BOTTOM
	SET_SHORT T_BRD_TOP_BOTTOM, 5
	ld hl, TILEMAP0 + 7 * TILEMAP_WIDTH
	ld bc, T_BRD_DOT_BTM_RIGHT << 8 | 7
	jr .preLoop

.preNone
	BORDER BOTTOM_LEFT
	ld a, T_BRD_BOTTOM
	ld bc, T_BRD_BOTTOM_RIGHT << 8 | (SCREEN_WIDTH - 2)
	; Fall through

.preLoop
	ld [hli], a
	dec c
	jr nz, .preLoop
	ld [hl], b

.preCont
	ld hl, wDeltaOAM
	TRANS_VERT_INIT -1, OBJ_TOP_END
	TRANS_VERT_INIT  1, OBJ_OFFSET

ASSERT (OBJ_ARROW_UP == OBJ_OFFSET)
	inc h                      ; Move to wShadowOAM
	ldh a, [hCH4.lenHigh]      ; Load CH4 length high nibble
	bit 1, a                   ; Infinite length?
	jr z, .preSet              ; If not, set left border

.preClear
	CLEAR_ARROWS_BASE
	jr .preDone

.preSet
FOR I, 0, 2
	ld a, 72 + I * 8
	ld [hli], a
	ld a, SCREEN_WIDTH_PX
	ld [hli], a
	ld a, T_BRD_RIGHT
	ld [hli], a
	xor a
	ld [hli], a
ENDR

.preDone
	rst WaitVBlank
	ld de, hPassword
	ld hl, TILEMAP0 + 8 * TILEMAP_WIDTH
	ldh a, [hSelection.topAddr]
	or a
	jr z, .loop
	ld c, a
	ldh a, [c]
	bit B_SOUND_B, a
	jr z, .loop
	ld l, SCREEN_WIDTH

.loop
	ld a, [de]
	UPDATE_DIGIT
	ld a, l
	cp SCREEN_WIDTH + 12
	jr nz, .cont
	ld l, 0
.cont
	inc e
	ld a, e
	cp LOW(hPassword.end)
	jr nz, .loop

	TRANS_VERT       1, PASS_SCY

	WAIT_JOYP nz
	WAIT_JOYP z

	ld hl, wDeltaOAM
	TRANS_VERT_INIT  1, OBJ_TOP_END
	TRANS_VERT_INIT -1, OBJ_OFFSET
	TRANS_VERT      -1, FINAL_SCY

	rst WaitVBlank
	ld hl, TILEMAP0 + 7 * TILEMAP_WIDTH
	ldh a, [hSelection.topAddr]
	or a
	jr z, .postNone
	ld c, a
	ldh a, [c]
	bit B_SOUND_B, a
	ld a, T_BRD_LEFT
	jr nz, .postB

.postA	
	ld [hli], a
	CLEAR_SHORT 2
	ld a, T_BRD_TOP
	ld bc, T_DOT_RIGHT_TOP_LEFT << 8 | 16
	jr .postLoop

.postB
	ld l, 7 * TILEMAP_WIDTH + SCREEN_WIDTH
	ld [hli], a

	CLEAR_SHORT 6
	SET_SHORT T_BRD_TOP, 5
	ld hl, TILEMAP0 + 7 * TILEMAP_WIDTH
	ld bc, T_DOT_RIGHT_TOP_LEFT << 8 | 7
	jr .postLoop

.postNone
	BORDER LEFT
	xor a
	ld bc, T_BRD_RIGHT << 8 | (SCREEN_WIDTH - 2)
	; Fall through

.postLoop
	ld [hli], a
	dec c
	jr nz, .postLoop
	ld [hl], b
	jp DoBorder


SECTION "Password Data", HRAM

hPassword:
	ds 10
.end
