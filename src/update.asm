; Super Game Boy Sound Mixer
;
; Copyright (c) 2025 Dmitry Shechtman

include "hardware.inc"
include "defs.inc"
include "common.inc"
include "macros.inc"
include "update.inc"


MACRO UPDATE_SOUND

	ldh a, [hSound\1.typeLow]
	ld b, a
	ldh a, [hSound\1.typeHigh]
	swap a
	add b
	add a
	ld l, a
	ld h, HIGH(Index\1)
	ld a, [hli]
	ld e, a
	ld d, [hl]

	; Read pitch/flags
	ld a, [de]
	bit B_TYPE_NONE, a
	jr z, .cont\@

IF !STRCMP("\1", "A")
	ld a, T_BRD_LEFT
	ld hl, TILEMAP0 + TILEMAP_WIDTH + COL_A_NAME - 1
	ld [hl], a
	ld l, TILEMAP_WIDTH * 2 + COL_A_NAME - 1
	ld [hl], a
ENDC
	ldh a, [hSound\1.pitch]
	ret
.cont\@

ENDM

MACRO UPDATE_NAME

	ldh [hSound\1.pitch], a

	; TODO Optimize
IF !STRCMP("\1", "A")
	ld a, T_BRD_LEFT
	ld hl, TILEMAP0 + TILEMAP_WIDTH * 2 + COL_\1_NAME - 1
	ld [hl], a
	ld l, TILEMAP_WIDTH + COL_\1_NAME - 1
	ld [hli], a
ELSE
	ld hl, TILEMAP0 + TILEMAP_WIDTH + COL_\1_NAME
ENDC

	inc de
.row1
	ld c, LOW(hName\1) + 1
.loop1
	ld a, [de]
	inc de
	or a
	jr z, .row2
	ld [hli], a
	ldh [c], a
	inc c
IF !STRCMP("\1", "B")
	ld a, l
	cp TILEMAP_WIDTH * 2
	jr nz, .loop1
	ld l, TILEMAP_WIDTH
ENDC
	jr .loop1

.row2
	ld b, a                    ; Zero
.loop2
	ld a, [de]
	or a
	jr z, .done
	inc de
	inc b
	jr .loop2

ENDM

MACRO UPDATE_DONE

.loop
	dec de
	rst WaitVRAM
	ld a, [de]
	ld [hld], a
IF !STRCMP("\1", "B")
	ldh [c], a
	dec c
	ld a, l
	cp TILEMAP_WIDTH * 2 - 1
	jr nz, .cont
	ld l, TILEMAP_WIDTH * 3 - 1
.cont
ENDC
	dec b
	jr nz, .loop
	ldh a, [hSound\1.pitch]

ENDM


SECTION "Clear Name", ROMX

ClearNameB::
	ld c, LOW(hNameB)
	; Fall through

ClearName::
	call .row
	; Fall through

.row
	ld a, T_BRD_LEFT
	ld b, 1
	call .loop
	xor a
	ld b, LOGO_WIDTH - 2
	call .loop
	ld a, T_BRD_RIGHT
	inc b                      ; Repeat once
	; Fall through

.loop
	ldh [c], a
	inc c
	dec b
	jr nz, .loop
	ret


SECTION "Update Sound A", ROMX

UpdateSoundA::
	UPDATE_TYPE A

.clearRow1
	ld hl, TILEMAP0 + TILEMAP_WIDTH + COL_A_NAME - 1
	CLEAR_SHORT LOGO_WIDTH - 1
	ld a, T_BRD_RIGHT
	ld [hl], a

.clearRow2
	ld l, TILEMAP_WIDTH * 2 + COL_A_NAME - 1
	CLEAR_SHORT LOGO_WIDTH - 1
	ld a, T_BRD_RIGHT
	ld [hl], a

	ld c, LOW(hNameA)
	call ClearName

	UPDATE_SOUND A
	bit B_TYPE_LOGO, a
	jr nz, .logo

	UPDATE_NAME  A

.logo
	call UpdateLogo

	; Re-read pitch
	ld a, [de]
	and $03
	ldh [hSoundA.pitch], a
	jr .end

.done
	ld l, TILEMAP_WIDTH * 2 + 18
	UPDATE_DONE A

.end
	ret

TryEnableSoundA::
	ldh a, [hSoundA.typeLow]
	ld b, a
	ldh a, [hSoundA.typeHigh]
	or b
	; Fall through

EnableSoundA:
	call EnableSoundVRAM
	ld hl, wShadowOAM + OBJ_A_PITCH * OBJ_SIZE + OAMA_FLAGS
	ld de, (OBJ_A_END * OBJ_SIZE + OAMA_FLAGS) << 8 | (OBJ_B_PITCH + 1) * OBJ_SIZE
	; Fall through

; @param C  Flags
; @param HL Controls OAM start address
; @param D  Controls OAM end address lower byte
; @param E  Labels OAM start address lower byte
EnableSoundOAM:
	ld a, l

.loop
	ld [hl], c
	add OBJ_SIZE
	ld l, a
	cp d
	jr nz, .loop
	ld l, e

.pitchLabel:
	ld b, T_LABEL_PITCH
	ld d, ROW_A_PITCH * 8
	call SetLeftLabel3

.volLabel:
	ld d, ROW_A_VOL * 8
	; Fall through
	
SetLeftLabel3::
	ld e, 9
	; Fall through

SetLabel3::
	call SetObject
	; Fall through

SetLabel2::
	call SetObject
	; Fall through

; @param B  Tile ID (advanced)
; @param C  Flags
; @param D  Y
; @param E  X (advanced)
; @param HL Shadow OAM start address (advanced)
SetObject:
	ld a, d
	ld [hli], a
	ld a, e
	ld [hli], a
	add 8
	ld e, a
	ld a, b
	ld [hli], a
	inc b
	ld a, c
	ld [hli], a
	ret

EnableSoundVRAM:
	ld hl, STARTOF(VRAM) + $1000 + T_PUSHB_LOW * 16
	ld de, PushTiles.quad
	ld bc, (PushTiles.width - PushTiles.quad) << 7
	jr nz, EnableVRAM

.disable
	ld de, DisabledTiles.quad
	ld c, OAM_PAL1
	; Fall through

EnableVRAM::
	push bc
.loop
REPT(2)
	ld a, [de]
	ld c, a
	rst WaitVRAM
	ld [hl], c
	inc hl
	inc de
ENDR
	dec b
	jr nz, .loop
	pop bc
	ret


SECTION "Update Sound B", ROMX

UpdateSoundB::
	UPDATE_TYPE B

.clearRow1
	ld hl, TILEMAP0 + TILEMAP_WIDTH
	CLEAR_SHORT 7
	ld l, TILEMAP_WIDTH + COL_B_NAME
	CLEAR_SHORT 3

.clearRow2
	ld l, TILEMAP_WIDTH * 2
	CLEAR_SHORT 7
	ld l, TILEMAP_WIDTH * 2 + COL_B_NAME
	CLEAR_SHORT 3

	call ClearNameB

	UPDATE_SOUND B
	UPDATE_NAME  B

.done
	ld l, TILEMAP_WIDTH * 2 + 6
	ld c, LOW(hNameB.end) - 2
	UPDATE_DONE B

.end
	ret

TryEnableSoundB::
	ldh a, [hSoundB.typeLow]
	ld b, a
	ldh a, [hSoundB.typeHigh]
	or b
	; Fall through

EnableSoundB:
	call EnableSoundVRAM
	ld hl, wShadowOAM + OBJ_B_PITCH * OBJ_SIZE + OAMA_FLAGS
	ld de, (OBJ_B_END * OBJ_SIZE + OAMA_FLAGS) << 8 | (OBJ_A_PITCH + 1) * OBJ_SIZE
	call EnableSoundOAM
	ld a, b                    ; Replace tile ID with the one sans border
	ld [wShadowOAM + (OBJ_A_VOL + 2) * OBJ_SIZE + OAMA_TILEID], a
	ret


SECTION "Enable/Disable Channel 4", ROMX

TryEnableCh4Dir::
	ldh a, [hCH4.pace]
	cp MAX_CH4_PACE
	; Fall through

EnableCh4Dir::
	ld hl, STARTOF(VRAM) + $1000 + T_PUSHB_DIR * 16
	ld de, PushTiles.dir
	ld bc, (PushTiles.check - PushTiles.dir) << 7
	jr nz, .cont

.disable
	ld de, DisabledTiles.dir
	ld c, OAM_PAL1

.cont
	call EnableVRAM
	ld hl, wShadowOAM + OBJ_CH4_DIR * OBJ_SIZE + OAMA_FLAGS
	call .oam
	ld l, OBJ_LABEL_DIR * OBJ_SIZE + OAMA_FLAGS
	
.oam
	ld [hl], c
	set B_OBJ, l
	ld [hl], c
	ret

MACRO ENABLE_SEL
	ldh a, [\1]
	ld e, a
	sra a
	cp b
	jr nz, .\@
	ld hl, wShadowOAM + OBJ_\2 * OBJ_SIZE + OAMA_TILEID
	ld a, e
IF !STRCMP("\2", "CH4_PACE")
	add a
	ld e, a
	ld d, HIGH(PaceSelMap)
	ld a, [de]
ELSE
	add \3
ENDC
	ld [hli], a
	ld [hl], c
.\@
ENDM

SetCh4Sel:
	ENABLE_SEL hCH4.pitch, CH4_PITCH, T_SEL_HEX
	ENABLE_SEL hCH4.vol,   CH4_VOL,   T_SEL_HEX
	ENABLE_SEL hCH4.pace,  CH4_PACE,  T_SEL_HEX
	ret

SetCh4DirDown:
	ldh a, [hCH4.dir]
	or a
	ret nz
	ld a, T_SEL_CH4_DIR
	jr SetCh4DirUp.cont

SetCh4DirUp:
	ldh a, [hCH4.dir]
	or a
	ret z
	ld a, T_SEL_CH4_DIR + 2

.cont
	ld hl, wShadowOAM + OBJ_CH4_DIR * OBJ_SIZE + OAMA_TILEID
	jr SetCh4Width.dbl

SetCh4Width:
	ldh a, [hCH4.width]
	add a
	add T_SEL_CH4_WIDTH
	ld hl, wShadowOAM + OBJ_CH4_WIDTH * OBJ_SIZE + OAMA_TILEID
.dbl
	call .single
	inc a
	dec l
	set B_OBJ, l
.single
	ld [hli], a
	ld [hl], c
	ret

SetCh4LeftLabels:
	ld hl, wShadowOAM + OBJ_LABEL_PITCH * OBJ_SIZE
	ld b, T_LABEL_PITCH
	ld d, ROW_CH4_PITCH * 8
	call SetLeftLabel3
	ld d, ROW_CH4_VOL   * 8
	call SetLeftLabel3
	inc b
	ld d, ROW_CH4_PACE  * 8
	jp SetLeftLabel3

SetCh4WidthLabel:
	ld b, T_LABEL_BITS
	ld de, (11 * 8 + 4) << 8 | 11 * 8 + 3
	ld hl, wShadowOAM + OBJ_LABEL_BITS * OBJ_SIZE
	jp SetLabel2

SetCh4DirLabel:
	ld b, T_LABEL_DIR
	ld de, (ROW_CH4_PACE * 8) << 8 | (COL_CH4_DIR - 3) * 8 + 3
	ld hl, wShadowOAM + OBJ_LABEL_DIR * OBJ_SIZE
	jp SetLabel2

SetCh4DivLabel:
	ld b, T_LABEL_DIV
	ld de, (11 * 8 + 4) << 8 | 16 * 8 - 1
	ld hl, wShadowOAM + OBJ_LABEL_DIV * OBJ_SIZE
	jp SetLabel2


MACRO TRANS_ENA_CH4

FOR I, 0, 8
	rst WaitVBlank
	ld b, 16
	ld de, PushTiles.hex + (7 - I) * 32
	ld hl, STARTOF(VRAM) + $1000 + (T_PUSHB_HEX + (7 - I) * 2) * 16
	call EnableVRAM

	ld hl, wDeltaOAM + OBJ_DIGIT_\1 * OBJ_SIZE
	ld bc, STARTOF(VRAM) + T_DIGIT_\1 * 16
	ld de, (HIGH(IDiv8LUT) + I) << 8 | (OBJ_DIGIT_LOW + 1) * OBJ_SIZE
	call Interpol8Digits

IF I == 7
	ld c, 0
	call SetCh4LeftLabels
ELIF I == 3
	ld hl, STARTOF(VRAM) + $1000 + T_PUSHB_DISABLE * 16
	ld b, 16
	ld de, PushTiles.check
	call EnableVRAM
	ld c, 0
	call SetCh4WidthLabel
ELIF I == 2
	ld hl, STARTOF(VRAM) + $1000 + T_PUSHB_WIDTH * 16
	ld b, PushTiles.endWidth - PushTiles.width
	ld de, PushTiles.width
	call EnableVRAM
	ld c, 0
	call SetCh4Width
	ldh a, [hCH4.pace]
	cp MAX_CH4_PACE
	call nz, SetCh4DirLabel
ELIF I == 1
	ld c, 0
	ldh a, [hCH4.pace]
	cp MAX_CH4_PACE
	call nz, SetCh4DirDown
	call SetCh4DivLabel
ELIF I == 0
	ldh a, [hCH4.div]
	swap a
	ld hl, STARTOF(VRAM) + T_DIGIT_DIV * 16
	call InitDigit
	ld c, 0
	ldh a, [hCH4.pace]
	cp MAX_CH4_PACE
	call nz, SetCh4DirUp
ENDC

	ld bc, (7 - I) << 8
	call SetCh4Sel

IF \2
	ld hl, wDeltaOAM + OBJ_CH4_WIDTH * OBJ_SIZE
	ld d, OBJ_CH4_SEL_END * OBJ_SIZE
IF I < 7
	call Translate
ELSE
	jp Translate
ENDC
ENDC

ENDR
	ret

ENDM


MACRO TRANS_DIS_CH4

FOR I, 0, 8
	rst WaitVBlank
	ld b, 16
	ld de, DisabledTiles.hex + I * 32
	ld hl, STARTOF(VRAM) + $1000 + (T_PUSHB_HEX + I * 2) * 16
	call EnableVRAM

	ld hl, wDeltaOAM + OBJ_DIGIT_\1 * OBJ_SIZE
	ld bc, STARTOF(VRAM) + T_DIGIT_\1 * 16
	ld de, (HIGH(IDiv8LUT) + I) << 8 | (OBJ_DIGIT_LOW + 1) * OBJ_SIZE
	call Interpol8Digits

IF I == 0
	ld c, OAM_PAL1
	call SetCh4LeftLabels
ELIF I == 4
	ld hl, STARTOF(VRAM) + $1000 + T_PUSHB_DISABLE * 16
	ld b, 16
	ld de, DisabledTiles.check
	call EnableVRAM
	ld c, OAM_PAL1
	call SetCh4WidthLabel
ELIF I == 5
	ld hl, STARTOF(VRAM) + $1000 + T_PUSHB_WIDTH * 16
	ld b, DisabledTiles.endWidth - DisabledTiles.width
	ld de, DisabledTiles.width
	call EnableVRAM
	ld c, OAM_PAL1
	call SetCh4Width
	call SetCh4DirLabel
ELIF I == 6
	ld c, OAM_PAL1
	call SetCh4DirDown
	call SetCh4DivLabel
ELIF I == 7
	ldh a, [hCH4.div]
	swap a
	ld hl, STARTOF(VRAM) + T_DIGIT_DIV * 16
	call InitDigitDarkLeftBorder
	ld c, OAM_PAL1
	call SetCh4DirUp
ENDC

	ld bc, I << 8 | OAM_PAL1
	call SetCh4Sel

IF \2
	ld hl, wDeltaOAM + OBJ_CH4_WIDTH * OBJ_SIZE
	ld d, OBJ_CH4_SEL_END * OBJ_SIZE
IF I < 7
	call Translate
ELSE
	jp Translate
ENDC
ENDC

ENDR
	ret

ENDM


SECTION "Translate CH4", ROM0

TransEnableCh4::
	TRANS_ENA_CH4 DIV, 1

TransEnableCh4Len::
	TRANS_ENA_CH4 HIGH, 0

TransDisableCh4::
	TRANS_DIS_CH4 DIV, 1

TransDisableCh4Len::
	TRANS_DIS_CH4 HIGH, 0
