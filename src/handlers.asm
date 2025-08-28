; Super Game Boy Sound Mixer
;
; Copyright (c) 2025 Dmitry Shechtman

include "hardware.inc"
include "defs.inc"
include "macros.inc"
include "update.inc"
include "handlers.inc"
include "trans.inc"


SECTION "Copy Handlers", ROMX

CopyHandlers::
	ldh a, [hSelection]
	ld c, a
	ld de, wHandlers
	ld h, HIGH(ABLUT)
	call CopyAddressPair2
	ld h, HIGH(SelectStartLUT)
	call CopyAddressPair2
	ld h, HIGH(RightLeftLUT)
	call CopyAddressPair
	ld h, HIGH(UpDownLUT)
	call CopyAddressPair
	ld h, HIGH(SelectABLUT)
	call CopyAddressPair2
	ld h, HIGH(StartABLUT)
	call CopyAddressPair4
	ld h, HIGH(SelectRightLeftLUT)
	call CopyAddressPair2
	ld h, HIGH(SelectUpDownLUT)
	call CopyAddressPair2
	ld h, HIGH(SelectStartABLUT)
	; Fall through

CopyAddressPair4:
	ld a, c
	and $7C
	jr CopyAddressPair.cont4

CopyAddressPair2:
	ld a, c
	res 0, a
	jr CopyAddressPair.cont2

CopyAddressPair:
	ld a, c
	add a
.cont2
	add a
.cont4
	ld l, a
REPT(4)
	ld a, [hli]
	ld [de], a
	inc e
ENDR
	ret


SECTION "Handlers", ROMX

IncSoundAPitch:
	TRANS_PITCH A, 1
	jp Main.loop
	
DecSoundAPitch:
	TRANS_PITCH A, -1
	jp Main.loop

IncSoundAVol:
	TRANS_VOL A, 1
	jp Main.loop

DecSoundAVol:
	TRANS_VOL A, -1
	jp Main.loop

IncSoundBPitch:
	TRANS_PITCH B, 1
	jp Main.loop

DecSoundBPitch:
	TRANS_PITCH B, -1
	jp Main.loop

IncSoundBVol:
	TRANS_VOL B, 1
	jp Main.loop

DecSoundBVol:
	TRANS_VOL B, -1
	jp Main.loop

IncCh4Div:
	ld d, a
	inc a
	and MAX_CH4_DIV
	ldh [c], a
	jr TransCh4Div

DecCh4Div:
	ld d, a
	dec a
	and MAX_CH4_DIV
	ldh [c], a
	; Fall through

TransCh4Div:
	ld hl, wDeltaOAM + OBJ_DIGIT_DIV * OBJ_SIZE
	swap a
	swap d
	sub d
	ld [hli], a
	ld [hl], d
	ld hl, STARTOF(VRAM) + T_DIGIT_DIV * 16
	call InitDigit

	ldh a, [hCurrentKeys]
	and 1 << B_PAD_START | 1 << B_PAD_B
	jr z, .skip
	bit B_PAD_START, a
	jr z, .ch4
	call DoSoundAB
.ch4
	call DoCh4
.skip

FOR I, 0, 2
IF I == 0
	ld hl, TILEMAP1 + TILEMAP_WIDTH + COL_CH4_DIV
ELSE
	ld l, TILEMAP_WIDTH * (I + 1) + COL_CH4_DIV
ENDC
	rst WaitVRAM
	ld a, T_DIGIT_DIV + I
	ld [hli], a
	set 1, a
	ld [hli], a
ENDR

	ld d, HIGH(IDiv8LUT)
	ld h, HIGH(wDeltaOAM)
.loop
	rst WaitVBlank
	ld bc, STARTOF(VRAM) + T_DIGIT_DIV * 16
	ld e, (OBJ_DIGIT_DIV + 1) * OBJ_SIZE
	ld l, OBJ_DIGIT_DIV * OBJ_SIZE
	call Interpol8Digits
	inc d
	bit 3, d
	jr z, .loop

	; rst WaitVBlank
	; UPDATE_CH4_DIV
	jp Main.loop

IncCh4Pitch:
	TRANS_CH4_PITCH 1
	jp Main.loop

DecCh4Pitch:
	TRANS_CH4_PITCH -1
	jp Main.loop

IncCh4Vol:
	TRANS_CH4_VOL 1
	jp Main.loop

DecCh4Vol:
	TRANS_CH4_VOL -1
	jp Main.loop

PrevNextSoundA:
	DO_SOUND_A
	ldh a, [hSelection]
	xor $01
	jp InterpolateArrows

PrevNextSoundB:
	DO_SOUND_B
	ldh a, [hSelection]
	xor $01
	jp InterpolateArrows

TryPrevCh4:
	bit B_PAD_LEFT, d
	jp z, Main.loop
	; Fall through

PrevCh4:
	DO_CH4
	ldh a, [hSelection]
	dec a
	jp InterpolateArrows

DecCh4Dir:
	TRANS_DBL hCH4.dir, CH4_DIR, X, Left
	jp Main.loop

TryNextCh4:
	bit B_PAD_DOWN, d
	jp z, Main.loop
	ldh a, [hSelection]
	; Fall through

NextCh4:
	DO_CH4
	ldh a, [hSelection]
	inc a
	jp InterpolateArrows

NextCh4LenLow:
	ldh a, [hCH4.lenLow]
	or a
	jr nz, NextCh4
	ldh a, [hCH4.lenHigh]
	or a
	jr nz, NextCh4
	jp ShakeBottomRight
	
NextCh4Pace:
	cp MAX_CH4_PACE
	jr z, TryPasswordDown
	DO_CH4
	ldh a, [hSelection]
	inc a
	jp InterpolateArrows

TryPasswordDown:
	bit B_PAD_DOWN, d
	jp nz, DoPassword
	jp Main.loop

DecSoundALow:
	dec a
	and $0F
	cp $0F
	jr nz, IncSoundALow.cont
.wrap
	ldh a, [hSoundA.typeHigh]
	dec a
	and $03
	ldh [hSoundA.typeHigh], a
	cp $03
	ld a, $0F
	jr nz, IncSoundALow.cont
	jr IncSoundALow.done

IncSoundALow:
	inc a
	and $0F
	jr z, .wrap
	cp $01
	jr nz, .cont
	ldh a, [hSoundA.typeHigh]
	cp $03
	ld a, $01
	jr nz, .cont
.wrap
	ldh a, [hSoundA.typeHigh]
	inc a
	and $03
	ldh [hSoundA.typeHigh], a
.done
	xor a
.cont
	ldh [c], a
	jr TransSoundA

IncSoundAHigh:
	inc a
	and $03
	jp z, TryPasswordUp
.cont
	cp $03
	jr nz, DecSoundAHigh.cont
.wrap
	xor a
	ldh [hSoundA.typeLow], a
	ld a, $03
	jr DecSoundAHigh.cont

DecSoundAHigh:
	dec a
	and $03
	cp $03
	jp z, TrySelectVertSoundA
.cont
	ldh [c], a
	; Fall through

TransSoundA:
	TRANS_SOUND_TYPE A
	call TryEnableSoundA
	jp Main

DecSoundBLow:
	dec a
	and $0F
	cp $0F
	jr nz, .cont
.wrap
	ldh a, [hSoundB.typeHigh]
	xor $01
	ldh [hSoundB.typeHigh], a
	ld a, $0F
	jr z, .cont
	ld a, $09
.cont
	ldh [c], a
	jr DecSoundBHigh.cont2

DecSoundBHigh:
	xor $01
	jp nz, TrySelectVertSoundB
.cont
	ldh [c], a
	jr z, .cont2
.wrap
	ldh a, [hSoundB.typeLow]
	cp 9
	jr c, .cont2
	ld a, 9
	ldh [hSoundB.typeLow], a
.cont2
	jr TransSoundB

IncSoundBLow:
	inc a
	and $0F
	jr z, .wrap
	cp $0A
	jr nz, .cont
	ldh a, [hSoundB.typeHigh]
	cp $01
	jr z, .wrap
	ld a, $0A
	jr .cont
.wrap
	ldh a, [hSoundB.typeHigh]
	xor $01
	ldh [hSoundB.typeHigh], a
	xor a
.cont
	ldh [c], a
	jr TransSoundB

IncSoundBHigh:
	xor $01
	jp z, TryPasswordUp
.cont
	ldh [c], a
	jr z, TransSoundB
.wrap
	ldh a, [hSoundB.typeLow]
	cp 9
	jr c, TransSoundB
	ld a, 9
	ldh [hSoundB.typeLow], a
	; Fall through

TransSoundB:
	TRANS_SOUND_TYPE B
	call TryEnableSoundB
	jp Main

TryPasswordUp:
	bit B_PAD_UP, d
	jp nz, DoPassword
	jp Main.loop

TrySelectVertSoundA:
	bit B_PAD_DOWN, d
	jp z, Main.loop
	ldh a, [hSoundA.typeLow]
	ld c, a
	ldh a, [hSoundA.typeHigh]
	or c
	jr nz, SelectVertSoundA.cont
.cont
	ldh a, [hSelection]
	ldh [hSelection.soundAVert], a
	bit B_PAD_START, d
	call nz, DoSoundAll
	ldh a, [hSelection.ch4Vert]
	jp InterpolateArrows

SelectVertSoundA:
	ldh a, [hSoundA.typeLow]
	ld b, a
	ldh a, [hSoundA.typeHigh]
	or b
	jp z, TryShakeTopDown
.cont
	ldh a, [hSelection]
	ldh [hSelection.soundAVert], a
	DO_SOUND_A
	ldh a, [hSelection.soundAHoriz]
	jp InterpolateArrows

TrySelectHorizSoundA:
	bit B_PAD_UP, d
	jp z, Main.loop
	ldh a, [hSelection]
	; Fall through

SelectHorizSoundA:
	ldh [hSelection.soundAHoriz], a
	DO_SOUND_A
	ldh a, [hSelection.soundAVert]
	jp InterpolateArrows

SelectBottomVertSoundA:
	SELECT_BOTTOM soundAVert
	jp InterpolateArrows

SelectBottomHorizSoundA:
	SELECT_BOTTOM soundAHoriz
	jp InterpolateArrows

TrySelectBottomSoundA:
	bit B_PAD_DOWN, d
	jp z, Main.loop
	; Fall through

SelectDownBottomSoundA:
	bit B_PAD_START, d
	call nz, DoSoundAll
	ldh a, [hSelection]
	ldh [hSelection.soundAHoriz], a
	ld a, LOW(hSelection.soundAHoriz)
	ldh [hSelection.topAddr], a
	ldh a, [hSelection.ch4Vert]
	jp InterpolateArrows

TrySelectVertSoundB:
	bit B_PAD_DOWN, d
	jp z, Main.loop
	ldh a, [hSoundB.typeLow]
	ld c, a
	ldh a, [hSoundB.typeHigh]
	or c
	jr nz, SelectVertSoundB.cont
.cont
	ldh a, [hSelection]
	ldh [hSelection.soundBVert], a
	bit B_PAD_START, d
	call nz, DoSoundAll
	ldh a, [hSelection.ch4Vert]
	jp InterpolateArrows

SelectVertSoundB:
	ldh a, [hSoundB.typeLow]
	ld b, a
	ldh a, [hSoundB.typeHigh]
	or b
	jp z, TryShakeTopDown
.cont
	ldh a, [hSelection]
	ldh [hSelection.soundBVert], a
	DO_SOUND_B
	ldh a, [hSelection.soundBHoriz]
	jp InterpolateArrows

TrySelectHorizSoundB:
	bit B_PAD_UP, d
	jp z, Main.loop
	ldh a, [hSelection]
	; Fall through

SelectHorizSoundB:
	ldh [hSelection.soundBHoriz], a
	DO_SOUND_B
	ldh a, [hSelection.soundBVert]
	jp InterpolateArrows

SelectBottomVertSoundB:
	SELECT_BOTTOM soundBVert
	jp InterpolateArrows

SelectBottomHorizSoundB:
	SELECT_BOTTOM soundBHoriz
	jp InterpolateArrows

TrySelectBottomSoundB:
	bit B_PAD_DOWN, d
	jp z, Main.loop
	; Fall through

SelectDownBottomSoundB:
	bit B_PAD_START, d
	call nz, DoSoundAll
	ldh a, [hSelection]
	ldh [hSelection.soundBHoriz], a
	ld a, LOW(hSelection.soundBHoriz)
	ldh [hSelection.topAddr], a
	ldh a, [hSelection.ch4Vert]
	jp InterpolateArrows

SelectTopVertCh4:
	SELECT_TOP ch4Vert, Left
	jp InterpolateArrows

SelectTopHorizCh4:
	SELECT_TOP ch4Horiz, Right
	jp InterpolateArrows

TrySelectHorizCh4:
	bit B_PAD_UP, d
	jp z, Main.loop
	; Fall through

SelectHorizCh4:
	ldh a, [hSelection]
	ldh [hSelection.ch4Horiz], a
	DO_CH4
	ldh a, [hSelection.ch4Vert]
	jp InterpolateArrows

DecCh4Width:
	TRANS_DBL hCH4.width, CH4_WIDTH, Y, Down
	jp Main.loop

TrySelectVertCh4:
	bit B_PAD_DOWN, d
	jp z, Main.loop
	; Fall through

SelectVertCh4:
	ldh a, [hCH4.lenLow]
	or a
	jr nz, .cont
	ldh a, [hCH4.lenHigh]
	or a
	jr nz, .cont
	jp Main.loop

.cont:
	ldh a, [hSelection]
	ldh [hSelection.ch4Vert], a
	DO_CH4
	ldh a, [hSelection.ch4Horiz]
	jp InterpolateArrows

DecCh4LenLow:
	ld c, a
	ldh a, [hCH4.lenHigh]
	ld b, a
	ld a, c
	dec a
	and $0F
	cp $0F
	jr nz, IncCh4LenLow.cont
	ld a, b
	dec a
	cp $FF
	jr nz, .cont
	ld a, 2
	ldh [hCH4.lenHigh], a
	dec a
	jr IncCh4LenLow.cont
.cont
	ldh [hCH4.lenHigh], a
	ld a, $0F
	jr IncCh4LenLow.cont

IncCh4LenLow:
	ld c, a
	ldh a, [hCH4.lenHigh]
	ld b, a
	ld a, c
	inc a
	cp $10
	jr nz, .cont0
.overflow
	ld a, b
	inc a
	ldh [hCH4.lenHigh], a
	xor a
	jr .cont
.cont0
	cp 2
	jr nz, .cont
	ld a, b
	cp 2
	jr z, .wrap
	ld a, c
	inc a
	jr .cont
.wrap
	xor a
	ldh [hCH4.lenHigh], a
.cont
	ldh [hCH4.lenLow], a
	jr TransCh4Len

DecCh4LenHigh:
	or a
	jr z, TrySelectVertCh4
	ld b, a
	ldh a, [hCH4.lenLow]
	ld c, a
	ld a, b
	dec a
	jr IncCh4LenHigh.cont2

IncCh4LenHigh:
	cp 2
	jp z, TrySelectUpTopCh4
	ld b, a
	ld a, [hCH4.lenLow]
	ld c, a
	ld a, b
	inc a
	cp 2
	jr nz, .cont2
.wrap
	ld a, c
	cp 2
	jr nc, .cont0
	ld a, b
	inc a
	jr .cont2
.cont0
	ld a, 1
	ldh [hCH4.lenLow], a
	inc a
.cont2
	ldh [hCH4.lenHigh], a
	; Fall through

TransCh4Len:
	ld hl, wDeltaOAM + OBJ_DIGIT_HIGH * OBJ_SIZE
	ldh a, [hCH4.lenHigh]
	swap a                     ; Multiply by 16
	swap b                     ; Multiply by 16
	sub b
	ld [hli], a
	ld a, b                    ; Load source * 16
	ld [hli], a
	inc l                      ; Adjust address
	inc l                      ; ...
	ldh a, [hCH4.lenLow]
	swap a                     ; Multiply by 16
	swap c                     ; Multiply by 16
	sub c
	ld [hli], a
	ld a, c
	ld [hli], a

	push bc
	ld hl, STARTOF(VRAM) + T_DIGIT_HIGH * 16
	ld a, b
	call InitDigit
	ld a, c
	call InitDigit

	ldh a, [hCurrentKeys]
	and 1 << B_PAD_START | 1 << B_PAD_B
	jr z, .skip
	bit B_PAD_START, a
	jr z, .ch4
	call DoSoundAB
.ch4
	call DoCh4
.skip

FOR I, 0, 2
IF I == 0
	ld hl, TILEMAP1 + TILEMAP_WIDTH + COL_CH4_LEN_HIGH
ELSE
	ld l, TILEMAP_WIDTH * (I + 1) + COL_CH4_LEN_HIGH
ENDC
FOR J, 0, 2
	rst WaitVRAM
	ld a, T_DIGIT_HIGH + I + J * 4
	ld [hli], a
	set 1, a
	ld [hli], a
ENDR
ENDR

	pop bc
	ld a, b
	or c
	jr z, .enaCh4
	
	ldh a, [hCH4.lenLow]
	ld b, a
	ldh a, [hCH4.lenHigh]
	or b
	jr z, .disCh4

	ld h, HIGH(wDeltaOAM)
	ld d, HIGH(IDiv8LUT)
.loop
	rst WaitVBlank
	ld l, OBJ_DIGIT_HIGH * OBJ_SIZE
	ld bc, STARTOF(VRAM) + T_DIGIT_HIGH * 16
	ld e, (OBJ_DIGIT_LOW + 1) * OBJ_SIZE
	call Interpol8Digits
	inc d
	bit 3, d
	jr z, .loop

.done
	; TODO REMOVE
	rst WaitVBlank
	UPDATE_CH4_LEN
	jp Main.loop

.enaCh4
	call TransEnableCh4Len
	call TryEnableCh4Dir
	jr .done

.disCh4
	call TransDisableCh4Len
	jr .done

TrySelectUpTopCh4:
	bit B_PAD_UP, d
	jp z, Main.loop
	; Fall through

SelectUpTopCh4:
	ldh a, [hSelection.topAddr]
	or a                       ; No SGB?
	jp z, SelectVertCh4
	bit B_PAD_START, d
	call nz, DoSoundAll
	ld a, LOW(hSelection.ch4Vert)
	ldh [hSelection.bottomAddr], a
	ld c, a
	ldh a, [hSelection]
	ldh [c], a
	IS_SOUND_B
	jr nz, .topB
.topA
	ldh a, [hSoundA.typeLow]
	ld b, a
	ldh a, [hSoundA.typeHigh]
	or b
	jr nz, .topAHoriz
	ldh a, [hSelection.soundAVert]
	jp InterpolateArrows
.topAHoriz
	ldh a, [hSelection.soundAHoriz]
	jp InterpolateArrows
.topB
	ldh a, [hSoundB.typeLow]
	ld b, a
	ldh a, [hSoundB.typeHigh]
	or b
	jr nz, .topBHoriz
	ldh a, [hSelection.soundBVert]
	jp InterpolateArrows
.topBHoriz
	ldh a, [hSelection.soundBHoriz]
	jp InterpolateArrows

IncCh4Width:
	TRANS_DBL hCH4.width, CH4_WIDTH, Y, Up
	jp Main.loop

ResetTop:
	ldh a, [hSelection.topAddr]
	or a
	jp z, ShakeTopLeft
	ld c, a
	ldh a, [c]
	IS_SOUND_B
	jr z, ResetSoundA.cont
	jp ClearSoundB.cont

ResetSoundA:
	ldh a, [hSelection.topAddr]
	or a
	jp z, ShakeTopLeft

.cont
	ld a, 1
	jr ClearSoundA.doClear

ClearTop:
	ldh a, [hSelection.topAddr]
	or a
	jp z, ShakeTopLeft
	ld c, a
	ldh a, [c]
	IS_SOUND_B
	jr z, ClearSoundA.cont
	jp ClearSoundB.cont

ClearSoundA:
	ldh a, [hSelection.topAddr]
	or a
	jp z, ShakeTopLeft

.cont
	xor a

.doClear
	ldh [hSoundA.typeLow],  a
	xor a
	ldh [hSoundA.typeHigh], a

	CLEAR_QUAD hSoundA.pitch, A_PITCH, PitchA, 3
	CLEAR_QUAD hSoundA.vol,   A_VOL,   VolA,   3
	
	ld h, HIGH(wDeltaOAM)
	TRANS_LOOP A_START, A_END, X, TOP

	; TODO REMOVE
	rst WaitVBlank
	call UpdateSoundA
	call DoSoundA
	call TryEnableSoundA
	jp Main

SelectTopA:
	call DoSoundA
	jp Main

ResetSoundB:
ClearSoundB:
	ldh a, [hSelection.topAddr]
	or a                       ; No SGB?
	jp z, ShakeTopRight

.cont
	xor a
	ldh [hSoundB.typeLow],  a
	ldh [hSoundB.typeHigh], a

	CLEAR_QUAD hSoundB.pitch, B_PITCH, PitchB, 3
	CLEAR_QUAD hSoundB.vol,   B_VOL,   VolB,   3
	
	ld h, HIGH(wDeltaOAM)
	TRANS_LOOP B_START, B_END, X, TOP

	call UpdateSoundB
	call DoSoundB
	call TryEnableSoundB
	jp Main

SelectTopB:
	call DoSoundB
	jp Main

ResetBottom:
	; Fall through
	
ResetCh4:
	ld b, MAX_CH4_VOL
	jr ClearCh4.doClear

ClearBottom:
	; Fall through

ClearCh4:
	ld b, 0

.doClear
	ld hl, wDeltaOAM + OBJ_CH4_VOL * OBJ_SIZE + OAMA_X
	ldh a, [hCH4.vol]
	sub b                      ; Subtract final value
	cpl
	inc a
	ld [hl], a
	ld a, b
	ldh [hCH4.vol], a

	CLEAR_DBL hCH4.width, CH4_WIDTH, Y
	CLEAR_HEX hCH4.pitch, CH4_PITCH, MAX_CH4_PITCH
	; CLEAR_HEX hCH4.vol,   CH4_VOL,   B
	CLEAR_DBL hCH4.dir,   CH4_DIR,   X
	CLEAR_HEX hCH4.pace,  CH4_PACE,  0

	ld l, OBJ_DIGIT_DIV * OBJ_SIZE
	INTERP_DIGIT_INIT hCH4.div,     CH4_DIV,      d
	INTERP_DIGIT_INIT hCH4.lenHigh, CH4_LEN_HIGH, b
	INTERP_DIGIT_INIT hCH4.lenLow,  CH4_LEN_LOW , c

	push bc
	ld hl, STARTOF(VRAM) + T_DIGIT_DIV * 16
	ld a, d
	call InitDigit
	pop bc
	push bc
	ld a, b
	call InitDigit
	ld a, c
	call InitDigit

FOR I, 0, 2
IF I == 0
	ld hl, TILEMAP1 + TILEMAP_WIDTH + COL_CH4_LEN_HIGH
ELSE
	ld l, TILEMAP_WIDTH * (I + 1) + COL_CH4_LEN_HIGH
ENDC
FOR J, 0, 2
	rst WaitVRAM
	ld a, T_DIGIT_HIGH + I + J * 4
	ld [hli], a
	set 1, a
	ld [hli], a
ENDR
ENDR

	pop bc
	ld a, b
	or c
	jr z, .enaCh4
	
	ldh a, [hCH4.lenLow]
	ld b, a
	ldh a, [hCH4.lenHigh]
	or b
	jr z, .disCh4

	ld h, HIGH(wDeltaOAM)
	ld d, HIGH(IDiv8LUT)
.loop
	rst WaitVBlank
	ld l, OBJ_DIGIT_DIV * OBJ_SIZE
	ld bc, STARTOF(VRAM) + T_DIGIT_DIV * 16
	ld e, (OBJ_DIGIT_LOW + 1) * OBJ_SIZE
	call Interpol8Digits
	ld e, d
	ld l, OBJ_CH4_WIDTH * OBJ_SIZE
	ld d, (OBJ_CH4_PACE + 1) * OBJ_SIZE
	call Translate
	call hFixedOAMDMA
	ld d, e
	inc d
	bit 3, d
	jr z, .loop

	UPDATE_DBL_TILEID CH4_WIDTH, 0
	UPDATE_TILEID     CH4_PITCH, MAX_CH4_PITCH
	
	ldh a, [hCH4.vol]
	add T_SEL_HEX
	ld l, OBJ_CH4_VOL * OBJ_SIZE + OAMA_TILEID
	ld [hl], a
	
	UPDATE_DBL_TILEID CH4_DIR,   0
	UPDATE_TILEID     CH4_PACE,  0

.done	
	call TryEnableCh4Dir
	call DoCh4
	jp Main.loop

.enaCh4
	call TransEnableCh4
	jr .done

.disCh4:
	call TransDisableCh4
	jr .done

IncCh4Pace:
	TRANS_CH4_PACE 1
	call TryEnableCh4Dir
	jp Main.loop

DecCh4Pace:
	TRANS_CH4_PACE -1
	call TryEnableCh4Dir
	jp Main.loop

SelectBottom:
	call DoCh4
	jp Main


SECTION "Select Sound A", ROMX

ToggleSoundVert:
	ldh a, [hSelection.topAddr]
	or a                       ; No SGB?
	jp z, ShakeTopLeft
	ld a, LOW(hSelection.ch4Vert)
	ldh [hSelection.bottomAddr], a
	ld c, a
	ldh a, [hSelection]
	ldh [c], a
	IS_SOUND_B
	jr nz, SelectSoundAHoriz.cont0
	jp SelectSoundBHoriz.cont0

ToggleSoundHoriz:
	ldh a, [hSelection.topAddr]
	or a                       ; No SGB?
	jp z, ShakeTopRight
	ld a, LOW(hSelection.ch4Horiz)
	ldh [hSelection.bottomAddr], a
	ld c, a
	ldh a, [hSelection]
	ldh [c], a
	IS_SOUND_B
	jr nz, SelectSoundAHoriz.cont0
	jp SelectSoundBHoriz.cont0

TrySelectSoundAVert:
	bit B_PAD_LEFT, d
	jp z, Main.loop
	; Fall through

SelectSoundAVert:
	ldh a, [hSelection]
	ldh [hSelection.soundBVert], a
	jr SelectSoundAHoriz.cont0

TrySelectSoundAHoriz:
	bit B_PAD_LEFT, d
	jp z, Main.loop
	; Fall through

SelectSoundAHoriz:
	ldh a, [hSelection]
	ldh [hSelection.soundBHoriz], a

.cont0
	bit B_PAD_START, d
	jr nz, .doSounds
	call DoSoundA
	jr .cont
.doSounds
	call DoSoundAll
.cont
	ld hl, wDeltaOAM + OBJ_TOP_START * OBJ_SIZE + OAMA_X
	TRANS_HORIZ_INIT B, A
	TRANS_HORIZ_INIT B, B
	TRANS_HORIZ A, TOP

	ld a, LOW(hSelection.soundAVert)
	ldh [hSelection.topAddr], a
	ldh a, [hSelection.soundAVert]
	ldh [hSelection], a
	call TryEnableSoundA
	jp Main

.vram
	CIRCLE A, 0, 0
	DIGIT_DBL_TOP
	ld a, T_BRD_TOP
	ld [hli], a

	CIRCLE A, 0, 1
	DIGIT_DBL 0, 0, 0
	ldh a, [hNameA.row1]
	ld [hli], a
	
	CIRCLE A, 0, 2
	DIGIT_DBL 1, 0, 0
	ldh a, [hNameA.row2]
	ld [hli], a

	CIRCLE A, 0, 3
	DIGIT_DBL_BOTTOM
	ld a, T_BRD_BOTTOM
	ld [hli], a

	LABEL PITCH, 4, 0
	PUSHB_BASE PitchA, 0, 7

	BORDER_LEFT 5, 0
	xor a
	ld [hli], a
	SET_SHORT T_BRD_TOP_BOTTOM, 7

	LABEL VOL, 6, 0
	PUSHB_BASE VolA, 0, 7
	
	BORDER_LEFT 7, 0
	xor a
	ld [hli], a
	SET_SHORT T_BRD_TOP, 7
	
	UPDATE_TYPE A
	
	ld a, T_BRD_RIGHT
FOR I, 0, 8
IF I == 0
	ld hl, TILEMAP0 + TILEMAP_WIDTH - 1
ELSE
	ld l, TILEMAP_WIDTH * (I + 1) - 1
ENDC
	ld [hl], a
ENDR

	jp .contLoop



SECTION "Select Bottom", ROMX

ToggleBottomSoundAVert:
	jp ShakeBottomLeft

ToggleBottomSoundAHoriz:
	jp ShakeBottomLeft

ToggleBottomSoundBVert:
	jp ShakeBottomLeft

ToggleBottomSoundBHoriz:
	jp ShakeBottomLeft

IncCh4Dir:
	TRANS_DBL hCH4.dir, CH4_DIR, X, Right
	jp Main.loop


SECTION "Select Sound B", ROMX

TrySelectSoundBVert:
	bit B_PAD_RIGHT, d
	jp z, Main.loop
	; Fall through

SelectSoundBVert:
	ldh a, [hSelection]
	ldh [hSelection.soundAVert], a
	jr SelectSoundBHoriz.cont0

TrySelectSoundBHoriz:
	bit B_PAD_RIGHT, d
	jp z, Main.loop
	; Fall through

SelectSoundBHoriz:
	ldh a, [hSelection]
	ldh [hSelection.soundAHoriz], a

.cont0
	bit B_PAD_START, d
	jr nz, .doSounds
	call DoSoundB
	jr .cont
.doSounds
	call DoSoundAll
.cont
	ld hl, wDeltaOAM + OBJ_TOP_START * OBJ_SIZE + OAMA_X
	TRANS_HORIZ_INIT A, A
	TRANS_HORIZ_INIT A, B
	TRANS_HORIZ B, TOP
	
	ld a, LOW(hSelection.soundBVert)
	ldh [hSelection.topAddr], a
	ldh a, [hSelection.soundBVert]
	ldh [hSelection], a
	call TryEnableSoundB
	jp Main

.vram
	ld hl, TILEMAP0
	SET_SHORT T_BRD_TOP, 7
	ld a, T_BRD_TOP_RIGHT
	ld [hli], a
	BORDER_LEFT_B 0, T_BRD_TOP

	B_END 1
	B_END 2
	
	SET_SHORT T_BRD_BOTTOM, 7
	DOT RIGHT_BTM_LEFT
	BORDER_LEFT_B 3, T_BRD_BOTTOM
	
	PUSHB_BASE PitchB, 9, 7
	BORDER LEFT_RIGHT
	BORDER_LEFT_B 4, T_PUSHB_MED_LOW
	
	SET_SHORT T_BRD_TOP_BOTTOM, 3
	ld l, TILEMAP_WIDTH * 5 + 7
	DOT RIGHT_DBL_LEFT
	BORDER_LEFT_B 5, T_BRD_TOP_BOTTOM

	PUSHB_BASE VolB, 9, 7
	BORDER LEFT_RIGHT
	BORDER_LEFT_B 6, T_PUSHB_MED

	SET_SHORT T_BRD_TOP, 3
	ld l, TILEMAP_WIDTH * 7 + 7
	DOT RIGHT_TOP_LEFT
	BORDER_LEFT_B 7, T_BRD_TOP

	jp .contLoop


SECTION "A/B LUT", ROMX, ALIGN[8]

ABLUT:
.soundA
	dw SelectTopA,        SelectBottomVertSoundA
	dw SelectTopA,        SelectBottomHorizSoundA
.soundB
	dw SelectTopB,        SelectBottomVertSoundB
	dw SelectTopB,        SelectBottomHorizSoundB
.ch4
	dw SelectTopVertCh4,  SelectBottom
	dw SelectTopVertCh4,  SelectBottom
	dw SelectTopHorizCh4, SelectBottom 
	dw SelectTopHorizCh4, SelectBottom

ASSERT (LOW(@) == FIELD_COUNT * 2)


SECTION "Select/Start LUT", ROMX, ALIGN[8]

SelectStartLUT:
.soundA
	dw SelectVertSoundA,  0
	dw SelectHorizSoundA, 0
.soundB
	dw SelectVertSoundB,  0
	dw SelectHorizSoundB, 0
.ch4
	dw SelectVertCh4,     0
	dw SelectVertCh4,     0
	dw SelectHorizCh4,    0
	dw SelectHorizCh4,    0

ASSERT (LOW(@) == FIELD_COUNT * 2)


SECTION "Right/Left LUT", ROMX, ALIGN[8]

RightLeftLUT:
.soundA
	dw PrevNextSoundA,       TryShakeTopLeft
	dw TrySelectSoundBVert,  PrevNextSoundA
	dw IncSoundAPitch,       DecSoundAPitch
	dw IncSoundAVol,         DecSoundAVol
.soundB
	dw PrevNextSoundB,       TrySelectSoundAVert
	dw TryShakeTopRight,     PrevNextSoundB
	dw IncSoundBPitch,       DecSoundBPitch
	dw IncSoundBVol,         DecSoundBVol
.ch4
	dw NextCh4,              TryShakeBottomLeft
	dw NextCh4LenLow,        PrevCh4
	dw NextCh4,              PrevCh4
	dw TryShakeBottomRight,  PrevCh4
	dw IncCh4Pitch,          DecCh4Pitch
	dw IncCh4Vol,            DecCh4Vol
	dw IncCh4Pace,           DecCh4Pace
	dw IncCh4Dir,            DecCh4Dir

ASSERT (LOW(@) == FIELD_COUNT * 4)


SECTION "Up/Down LUT", ROMX, ALIGN[8]

UpDownLUT:
.soundA
	dw IncSoundAHigh,        DecSoundAHigh
	dw IncSoundALow,         DecSoundALow
	dw TrySelectHorizSoundA, PrevNextSoundA
	dw PrevNextSoundA,       TrySelectBottomSoundA
.soundB
	dw IncSoundBHigh,        DecSoundBHigh
	dw IncSoundBLow,         DecSoundBLow
	dw TrySelectHorizSoundB, PrevNextSoundB
	dw PrevNextSoundB,       TrySelectBottomSoundB
.ch4
	dw IncCh4LenHigh,        DecCh4LenHigh
	dw IncCh4LenLow,         DecCh4LenLow
	dw IncCh4Width,          DecCh4Width
	dw IncCh4Div,            DecCh4Div
	dw TrySelectHorizCh4,    NextCh4
	dw PrevCh4,              NextCh4
	dw PrevCh4,              NextCh4Pace
	dw PrevCh4,              TryPasswordDown

ASSERT (LOW(@) == FIELD_COUNT * 4)


SECTION "Select+A/B LUT", ROMX, ALIGN[8]

SelectABLUT:
.soundA
	dw SelectSoundBVert,  ToggleBottomSoundAVert
	dw SelectSoundBHoriz, ToggleBottomSoundAHoriz
.soundB
	dw SelectSoundAVert,  ToggleBottomSoundBVert
	dw SelectSoundAHoriz, ToggleBottomSoundBHoriz
.ch4
	dw ToggleSoundVert,   ShakeBottomLeft
	dw ToggleSoundVert,   ShakeBottomLeft
	dw ToggleSoundHoriz,  ShakeBottomRight
	dw ToggleSoundHoriz,  ShakeBottomRight

ASSERT (LOW(@) == FIELD_COUNT * 2)


SECTION "Start+A/B LUT", ROMX, ALIGN[8]

StartABLUT:
.soundA
	dw ClearSoundA,       ClearBottom
.soundB
	dw ClearSoundB,       ClearBottom
.ch4
	dw ClearTop,          ClearCh4
	dw ClearTop,          ClearCh4

ASSERT (LOW(@) == FIELD_COUNT)


SECTION "Select+Start+A/B LUT", ROMX, ALIGN[8]

SelectStartABLUT:
.soundA
	dw ResetSoundA,       ResetCh4
.soundB
	dw ResetSoundB,       ResetCh4
.ch4
	dw ResetTop,          ResetBottom
	dw ResetTop,          ResetBottom

ASSERT (LOW(@) == FIELD_COUNT)


SECTION "Select+Right/Left LUT", ROMX, ALIGN[8]

SelectRightLeftLUT:
.soundA
	dw SelectSoundBVert,  ShakeTopLeft
	dw SelectSoundBHoriz, ShakeTopLeft
.soundB
	dw ShakeTopRight,     SelectSoundAVert
	dw ShakeTopRight,     SelectSoundAHoriz
.ch4
	dw ShakeBottomRight,  ShakeBottomLeft
	dw ShakeBottomRight,  ShakeBottomLeft
	dw ShakeBottomRight,  ShakeBottomLeft
	dw ShakeBottomRight,  ShakeBottomLeft

ASSERT (LOW(@) == FIELD_COUNT * 2)


SECTION "Select+Up/Down LUT", ROMX, ALIGN[8]

SelectUpDownLUT:
.soundA
	dw TryPasswordUp,        TrySelectVertSoundA
	dw SelectHorizSoundA,    TrySelectBottomSoundA
.soundB
	dw TryPasswordUp,        TrySelectVertSoundB
	dw SelectHorizSoundB,    TrySelectBottomSoundB
.ch4
	dw TrySelectUpTopCh4,    SelectVertCh4
	dw TrySelectUpTopCh4,    SelectVertCh4
	dw SelectHorizCh4,       TryPasswordDown
	dw SelectHorizCh4,       TryPasswordDown

ASSERT (LOW(@) == FIELD_COUNT * 2)


SECTION "Handlers RAM", WRAM0, ALIGN[8]

wHandlers::
	.A           :: dw
	.B           :: dw
	.select      :: dw
	.start       :: dw
	.right       :: dw
	.left        :: dw
	.up          :: dw
	.down        :: dw

	.selectA     :: dw
	.selectB     :: dw
	.startA      :: dw
	.startB      :: dw
	.selectRight :: dw
	.selectLeft  :: dw
	.selectUp    :: dw
	.selectDown  :: dw

	.selectStartA:: dw
	.selectStartB:: dw

ASSERT (LOW(@) == 36)
