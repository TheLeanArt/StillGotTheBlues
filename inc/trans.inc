; Super Game Boy Sound Mixer
;
; Copyright (c) 2025 Dmitry Shechtman


MACRO CLEAR_ARROWS_BASE
	xor a
	ld [hl], a
	ld l, OBJ_ARROW_DOWN * OBJ_SIZE
	ld [hl], a
ENDM

MACRO CLEAR_ARROWS
	ld hl, wShadowOAM + OBJ_ARROW_UP * OBJ_SIZE
	CLEAR_ARROWS_BASE
ENDM

MACRO TRANS_VERT_INIT
.loop\@
	ld a, \1
	ld [hl], a
	ld a, l
	add OBJ_SIZE
	ld l, a
	cp \2 * OBJ_SIZE
	jr nz, .loop\@
ENDM

MACRO TRANS_VERT_LYC
IF \1
	ldh a, [rLYC]
IF \1 == 1
	inc a
ELSE
	dec a
ENDC
	ldh [rLYC], a
ENDC
ENDM

MACRO TRANS_VERT
	ld h, HIGH(wDeltaOAM)
	ld d, OBJ_OFFSET * OBJ_SIZE
	ld e, \1
.loop\@
	call hFixedOAMDMA
	rst WaitVBlank
	TRANS_VERT_LYC \1
	ld l, 0
	call TranslateY
	ldh a, [hShadowWY]
	add e
	ldh [hShadowWY], a
	add INIT_SCY - INIT_WY
	ldh [hTopSCY], a
	ldh [hBottomSCY], a
	cp \2
	jr nz, .loop\@
.end\@
ENDM

; @param \1 A/B
; @param \2 Pitch/Vol
; @param \3 Z/NZ
MACRO TRANS_OAM
	swap a                     ; Multiply by 8
	rra                        ; ...
	ld e, a
	ld d, HIGH(\2SelMap)
	add a                      ; Multiply by 4
	add a                      ; ...
	add X_\1
	ld b, a
.loop\@
	ld a, b
	inc l
	ld [hli], a
	add 8
	ld b, a
REPT(2)
	ld a, [de]
	ld [hli], a
	inc e
ENDR
	bit 4, l
	jr \3, .loop\@
ENDM

; @param \1 Sound (A/B)
; @param \2 Subset (A/B)
MACRO TRANS_HORIZ_INIT
.loop\@
	ld a, X_\1_DELTA
	ld [hli], a
	inc l
	ld a, X_\1_FINAL_\2
	ld [hli], a
	ld a, l
	inc l
	cp OBJ_\2_END * OBJ_SIZE
	jr nz, .loop\@
ENDM

; @param \1 A/B/CH4
; @param \2 TOP/BOTTOM
MACRO TRANS_HORIZ
	CLEAR_ARROWS
.loop\@
	rst WaitVBlank
	ldh a, [REG_X_\2]
	cp X_\1_OAM
	jr nz, .notOam
.oam
	ld hl, wShadowOAM + OBJ_\1_PITCH * OBJ_SIZE
	ldh a, [hSound\1.pitch]
	TRANS_OAM \1, Pitch, Z
	ldh a, [hSound\1.vol]
	TRANS_OAM \1, Vol, NZ
	jr .contLoop
.notOam
	cp X_\1_VRAM
	jp z, .vram
.contLoop
	ld hl, wDeltaOAM
	ld de, (OBJ_TOP_END * OBJ_SIZE) << 8 | LOW(X_\1_DELTA)
	rst TranslateX
	ldh a, [REG_X_\2]
	add e
	ldh [REG_X_\2], a
IF X_\1_FINAL
	cp X_\1_FINAL
ENDC
	jr nz, .loop\@
ENDM

; @param \1 Start parameter
; @param \2 End parameter
; @param \3 X/Y/0
; @param \4 TOP/BOTTOM
MACRO TRANS_LOOP
	ld de, ((OBJ_\2) * OBJ_SIZE) << 8 | TRANS_LENGTH
.loop\@
	rst WaitVBlank
	ld l, OBJ_\1 * OBJ_SIZE
IF !STRCMP("\3", "")
	rst Translate\3
ELSE
	call Translate
ENDC
IF !STRCMP("\4", "BOTTOM")
	call hFixedOAMDMA
ENDC
	dec e
	jr nz, .loop\@
ENDM

; @param \1 Parameter
; @param \2 Direction (-1/1)
MACRO TRANS_INIT
	ld a, \2
	jr nz, .cont\@
	ld a, -(WID_\1 - 1) * \2
.cont\@
	ld hl, wDeltaOAM + OBJ_\1 * OBJ_SIZE + OAMA_X
	ld [hli], a
	inc l
	xor a
	ld [hl], a
ENDM

; @param \1 Param
; @param \2 Parameter
; @param \3 Direction (-1/1)
MACRO TRANS_BASE
IF \3 == 1
	inc a
ELSE
	dec a
ENDC
	and MAX_\2
	ldh [c], a
	DO_CH4
	ldh a, [\1]                ; Restore value
IF \3 == 1
	or a
ELSE
	cp MAX_\2
ENDC
	TRANS_INIT \2, \3
	TRANS_LOOP \2, \2 + 1, X, BOTTOM
	ldh a, [\1]                ; Restore value
	ld hl, wShadowOAM + OBJ_\2 * OBJ_SIZE + OAMA_TILEID
ENDM

; @param \1 Direction (-1/1)
MACRO TRANS_CH4_PITCH
	TRANS_BASE hCH4.pitch, CH4_PITCH, \1
	or T_SEL_HEX
	ld [hli], a
ENDM

; @param \1 Direction (-1/1)
MACRO TRANS_CH4_VOL
	TRANS_BASE hCH4.vol, CH4_VOL, \1
	or T_SEL_HEX
	ld [hli], a
ENDM

; @param \1 Direction (-1/1)
MACRO TRANS_CH4_PACE
	TRANS_BASE hCH4.pace, CH4_PACE, \1
	UPDATE_PACE_TILEID
ENDM

; @param \1 Param
; @param \2 Parameter
; @param \3 Value
MACRO CLEAR_HEX
	ldh a, [\1]
IF \3
	sub \3
ENDC
	cpl
	inc a
	ld l, OBJ_\2 * OBJ_SIZE + OAMA_X
	ld [hl], a
IF \3
	ld a, \3
ELSE
	xor a
ENDC
	ldh [\1], a
ENDM

; @param \1 Parameter
; @param \2 X/Y
MACRO TRANS_DBL_INIT
	add a                      ; Multiply by 2
IF !STRCMP("\2", "X")
	add a                      ; Multiply by 2
ENDC
	dec a                      ; Adjust delta
IF !STRCMP("\2", "X")
	dec a                      ; Adjust delta
ENDC
	ld b, a                    ; Store delta in B
	ld hl, wDeltaOAM + OBJ_\1 * OBJ_SIZE + OAMA_\2
FOR I, 0, 2
	ld [hli], a                ; Set dX/dY
	inc l                      ; Advance to X1/Y1
	xor a                      ; Zero
	ld [hli], a                ; Set X1/Y1
	ld a, b                    ; Restore delta
	inc l                      ; Advance next dX/dY
ENDR
ENDM

; @param \1 Param
; @param \2 Parameter
; @param \3 X/Y
; @param \4 Direction
MACRO TRANS_DBL
	xor $01
IF !STRCMP("\4", "Down")
	jr z, TrySelectVertCh4
ELIF !STRCMP("\4", "Left")
	jr nz, TryPrevCh4
ELIF !STRCMP("\4", "Up")
	jr nz, TrySelectUpTopCh4
ELSE
	jp z, TryShakeBottomRight
ENDC
	ldh [c], a
	DO_CH4
	ldh a, [\1]                ; Restore value
	TRANS_DBL_INIT \2, \3
	TRANS_LOOP \2, \2 + 2, \3, \4
	ldh a, [\1]                ; Restore value
	UPDATE_DBL_TILEID_BASE \2
ENDM

MACRO CLEAR_DBL
	ldh a, [\1]
	or a
	jr nz, .cont\@
	xor a
	ld l, OBJ_\2 * OBJ_SIZE + OAMA_\3
	ld [hl], a
	ld l, (OBJ_\2 + 1) * OBJ_SIZE + OAMA_\3
	ld [hl], a
	jr .done\@
.cont\@
	xor a
	ldh [\1], a
	TRANS_DBL_INIT \2, \3
.done\@
ENDM

; @param \1 PITCH/VOL
; @param \2 Param
MACRO TRANS_QUAD_INIT
	ld hl, wShadowOAM + OBJ_\1 * OBJ_SIZE + OAMA_X
	ld a, [hl]
	sub 4 * 8 + 1
	swap a                     ; Divide by 8
	add a                      ; ...
	ld d, a                    ; Store the result in D
	ldh a, [\2]                ; Restore value
	add a                      ; Multiply by 4
	add a                      ; ...
	sub d
FOR I, 0, 4
IF I == 0
	dec h
ELSE
	ld l, (OBJ_\1 + I) * OBJ_SIZE + OAMA_X
ENDC
	ld [hl], a
ENDR
ENDM

; @param \1 PITCH/VOL
; @param \2 Pitch/Vol
; @param \3 Param
MACRO TRANS_QUAD_BASE
	TRANS_QUAD_INIT \1, \3
	TRANS_LOOP \1, \1 + 4, X, TOP
	ldh a, [\3]
	UPDATE_QUAD_MSW \1, \2
ENDM

; @param \1 A/B
MACRO TRANS_SOUND_TYPE
	DO_SOUND_\1
	rst WaitVBlank              ; TODO Too long for VBlank
	call UpdateSound\1
	ldh [hSound\1.pitch], a
	TRANS_QUAD_BASE \1_PITCH, Pitch\1, hSound\1.pitch
ENDM

; @param \1 A/B
; @param \2 PITCH/VOL
; @param \3 Pitch/Vol
; @param \4 pitch/vol
; @param \5 Direction (-1/1)
MACRO TRANS_QUAD

IF \5 == 1

	cp MAX_\1_\2
IF !STRCMP("\1", "A")
	jp z, TrySelectSoundBHoriz
ELSE
	jp z, TryShakeTopRight
ENDC
	inc a

ELSE

IF MIN_\1_\2
	cp MIN_\1_\2
ELSE
	or a
ENDC
IF !STRCMP("\1", "B")
	jp z, TrySelectSoundAHoriz
ELSE
	jp z, TryShakeTopLeft
ENDC
	dec a

ENDC

	ldh [c], a
	DO_SOUND_\1
	TRANS_QUAD_BASE \1_\2, \3, hSound\1.\4

ENDM

; @param \1 A/B
; @param \2 Direction (-1/1)
MACRO TRANS_PITCH
	TRANS_QUAD \1, PITCH, Pitch\1, pitch, \2
ENDM

; @param \1 A/B
; @param \2 Direction (-1/1)
MACRO TRANS_VOL
	TRANS_QUAD \1, VOL, Vol\1, vol, \2
ENDM

MACRO CLEAR_QUAD
	ld a, \4
	ldh [\1], a
	TRANS_QUAD_INIT \2, \1
	ldh a, [\1]
	UPDATE_QUAD_MSW \2, \3
ENDM

MACRO INTERP_DIGIT_INIT
	ldh a, [\1]                ; Load initial value
	swap a                     ; Multiply by 16
	ld \3, a                   ; Save source value
	ld a, DEF_\2 * 16          ; Subtract from destination * 16
	sub \3                     ; ...
	ld [hli], a                ; Store delta
	ld a, \3                   ; Load source * 16
	ld [hli], a                ; Store source * 16
	inc l                      ; Adjust address
	inc l                      ; ...
	ld a, DEF_\2               ; Load destination value
	ldh [\1], a                ; Store destination value
ENDM
