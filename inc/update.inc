; Super Game Boy Sound Mixer
;
; Copyright (c) 2025 Dmitry Shechtman


MACRO UPDATE_DIGIT
	add a
	set B_DIGIT, a
	ld [hl], a
	ld b, a
	ld c, l
	ld a, l
	add TILEMAP_WIDTH
	ld l, a
	ld a, b
	inc a
	ld [hli], a
	set B_DIGIT_RIGHT, a
	ld [hl], a
	dec a
	ld l, c
	inc l
	ld [hli], a
ENDM

; @param \1 Parameter
; @param \2 Value
MACRO UPDATE_TILEID
	ld a, T_SEL_HEX + \2
	ld l, OBJ_\1 * OBJ_SIZE + OAMA_TILEID
	ld [hli], a
ENDM

MACRO UPDATE_PACE_TILEID
	add a                      ; Multiply by 2
	ld e, a
	ld d, HIGH(PaceSelMap)
	ld a, [de]
	ld [hli], a
ENDM

; @param \1 Parameter
MACRO UPDATE_DBL_TILEID_BASE
	add a                      ; Multiply by 4
	add T_SEL_\1
FOR I, 0, 2
IF I == 0
	ld b, a
	ld hl, wShadowOAM + OBJ_\1 * OBJ_SIZE + OAMA_TILEID
ELSE
	ld a, b
	set B_ODD, a
	set B_OBJ, l
ENDC
	ld [hli], a
	xor a
	ld [hld], a
ENDR
ENDM

; @param \1 Parameter
; @param \2 Value
MACRO UPDATE_DBL_TILEID
IF \2
	ld a, \2
ELSE
	xor a
ENDC
	UPDATE_DBL_TILEID_BASE \1
ENDM

MACRO UPDATE_QUAD
	swap a                     ; Multiply by 8
	rra                        ; ...
	ld b, a                    ; Save result
	ld c, 4
.loop\@
	ld a, b                    ; Load value * 8
	add a                      ; Multiply by 4
	add a                      ; ...
	add 4 * 8 + 1              ; Add deltaX
	ld [hli], a                ; Store X coordinate
	ld e, b                    ; Load address
REPT(2)
	ld a, [de]                 ; Load tile ID/attributes
	ld [hli], a                ; Store tile ID/attributes
	inc e                      ; Advance address
ENDR
	ld b, e
	inc l
	dec c
	jr nz, .loop\@
ENDM

MACRO UPDATE_QUAD_MSW
	swap a                     ; Multiply by 8
	rra                        ; ...
	ld c, a                    ; Save result
	ld b, HIGH(\2Map)          ; Set map
	ld hl, wShadowOAM + OBJ_\1 * OBJ_SIZE + OAMA_TILEID
FOR I, 0, 4
REPT(2)
	ld a, [bc]                 ; Load tile ID/attributes
	ld [hli], a                ; Store tile ID/attributes
	inc c
ENDR
	inc l
	inc l
ENDR
ENDM

MACRO UPDATE_PITCH
	; ldh a, [hSound\1.pitch]
	ld d, HIGH(PitchSelMap)
	ld hl, wShadowOAM + OBJ_\1_PITCH * OBJ_SIZE + OAMA_X
	UPDATE_QUAD \1_PITCH
ENDM

MACRO UPDATE_VOL
	ldh a, [hSound\1.vol]
	ld d, HIGH(VolSelMap)
	ld hl, wShadowOAM + OBJ_\1_VOL * OBJ_SIZE + OAMA_X
	UPDATE_QUAD \1_VOL
ENDM

MACRO UPDATE_TYPE
	ldh a, [hSound\1.typeHigh]
	ld hl, TILEMAP0 + TILEMAP_WIDTH + COL_\1_TYPE
	UPDATE_DIGIT
	ldh a, [hSound\1.typeLow]
	UPDATE_DIGIT
ENDM

MACRO UPDATE_CH4_LEN
	ldh a, [hCH4.lenHigh]
	ld hl, TILEMAP1 + TILEMAP_WIDTH + COL_CH4_LEN_HIGH
	UPDATE_DIGIT
	ldh a, [hCH4.lenLow]
	UPDATE_DIGIT
ENDM
