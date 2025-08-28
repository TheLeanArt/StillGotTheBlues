; Super Game Boy Sound Mixer
;
; Copyright (c) 2025 Dmitry Shechtman


MACRO COPY_SHORT
	ld c, \1
.loop\@
	ld a, [de]
	ld [hli], a
	inc e
	dec c
	jr nz, .loop\@
ENDM

; @param \1 Parameter
; @param \2 Offset
; @param \3 Count
MACRO PUSHB_BASE
	ld de, \1Map + \2
	COPY_SHORT \3
ENDM

MACRO PUSHB
	PUSHB_BASE \1, 0, 16
	BORDER LEFT_RIGHT
ENDM

MACRO PUSHB_HEX
	ld a, T_PUSHB_HEX
	ld c, 16
.loop\@
	ld [hli], a
	inc a
	dec c
	jr nz, .loop\@
	BORDER LEFT_RIGHT
ENDM

MACRO PUSHB_WIDTH
	ld a, T_PUSHB_WIDTH
	ld [hli], a
IF \1 == 1
	inc a
ELSE
	ld a, T_PUSHB_WIDTH + 3
ENDC
	ld [hli], a
	inc a
	ld [hli], a
ENDM

MACRO PUSHB_DIR
	INC_BASE T_PUSHB_DIR, 4
	BORDER LEFT_RIGHT
ENDM

; @param \1 0/1/2
; @param \2 Row
MACRO CIRCLE_BASE
	COPY_SHORT 4
ENDM

; @param \1 Type (AB/4)
; @param \2 Index (0/1)
; @param \3 Row
MACRO CIRCLE
IF \3 == 0
	ld de, Circle\1Map
; IF \2 != 0
	ld hl, TILEMAP\2
; ENDC
ELSE
	ld l, TILEMAP_WIDTH * \3
ENDC
CIRCLE_BASE
ENDM

MACRO INC_SHORT
	ld a, \1
.\@
	ld [hli], a
	inc a
IF \1 + \2 == 256
	or a
ELSE
	cp \1 + \2
ENDC
	jr nz, .\@
ENDM

; @param \1 Tile ID
; @param \2 Count
MACRO INC_BASE
	ld a, \1
REPT(\2 - 1)
	ld [hli], a
	inc a
ENDR
	ld [hli], a
ENDM

; @param \1 Name
; @param \2 Row (1/2)
MACRO LABEL_BASE
	INC_BASE T_LABEL_\1\2, LABEL_\1_SIZE
ENDM

; @param \1 Name
; @param \2 Row
; @param \3 Column
MACRO LABEL
IF \2
	ld l, TILEMAP_WIDTH * \2 + \3
ENDC
	INC_BASE T_LABEL_\1, 3
ENDM

MACRO BORDER_LEFT_BASE
	ld a, T_BRD_LEFT
	ld [hli], a
	xor a
	ld [hli], a
ENDM

MACRO BORDER_LEFT
	ld l, TILEMAP_WIDTH * \1 + \2
	BORDER_LEFT_BASE
ENDM

MACRO BORDER_LEFT_B
	ld a, T_BRD_LEFT
	ld [hl], a
	ld l, TILEMAP_WIDTH * (\1 + 1) - 1
	ld a, \2
	ld [hli], a
ENDM

MACRO BORDER
	ld a, T_BRD_\1
	ld [hli], a
ENDM

MACRO DOT
	ld a, T_DOT_\1
	ld [hli], a
ENDM

; @param \1 Row (0/1)
MACRO DIGIT
	ld a, T_DIGIT + \1
	ld [hli], a
	set B_DIGIT_RIGHT, a
	ld [hli], a
ENDM

; @param \1 Row (0/1)
MACRO DIGIT_DBL
	DIGIT \1 + \2 * 2
	DIGIT \1 + \3 * 2
ENDM

MACRO DIGIT_TOP
	ld a, T_BRD_TOP
	ld [hli], a
	ld a, T_BRD_TOP_BOTTOM
	ld [hli], a
	ld [hli], a
ENDM

MACRO DIGIT_DBL_TOP
	SET_SHORT T_BRD_TOP_BOTTOM, 4
	DOT TOP_BTM_LEFT
ENDM

MACRO DIGIT_BOTTOM
	ld a, T_BRD_TOP
	ld [hli], a
	ld [hli], a
ENDM

MACRO DIGIT_DBL_BOTTOM
	SET_SHORT T_BRD_TOP_BOTTOM, 4
	DOT BTM_TOP_LEFT
ENDM

MACRO SET_BASE
IF \1 <= 4
	REPT(\1)
		ld [hli], a
	ENDR
ELSE
	ld c, \1
.loop\@
	ld [hli], a
	dec c
	jr nz, .loop\@
ENDC
ENDM

MACRO SET_SHORT
	ld a, \1
	SET_BASE \2
ENDM

MACRO CLEAR_SHORT
	xor a
	SET_BASE \1
ENDM

MACRO CLEAR_RIGHT
	CLEAR_SHORT \1
	BORDER RIGHT
ENDM

MACRO SET_OBJ
	; dY
	ld a, \4
	ld [hl], a
	inc h
	; Y
	ld a, \1
	ld [hli], a
	dec h
	; dX
	xor a
	ld [hl], a
	inc h
	; X
	ld a, \2
	ld [hli], a
	dec h
	; Y1
	ld a, \5
	ld [hl], a
	inc h
	; Tile ID
	ld a, \3
	ld [hli], a
	dec h
	; X1
	xor a
	ld [hl], a
	inc h
	; Attrs
	ld [hli], a                ; Zero
	dec h
ENDM

MACRO SET_OBJ_TOP
	SET_OBJ \1 - INIT_SCY, \2, \3, 2, \1
ENDM

MACRO SET_OBJ_BTM
	SET_OBJ \1 + INIT_SCY, \2, \3, -2, \1
ENDM

MACRO B_START
	CIRCLE_BASE 1, \1
	DIGIT_DBL \1 - 1, 0, 0
	; ld c, LOW(hNameB.row\1)
	BORDER LEFT
	xor a
REPT(2)
	ld [hli], a
ENDR
	BORDER RIGHT
ENDM

MACRO B_END
	ld bc, 8 << 8 | LOW(hNameB.row\1 + 4)
.loop\@
	ldh a, [c]
	ld [hli], a
	inc c
	dec b
	jr nz, .loop\@
	BORDER_LEFT_B \1, [hNameB.row\1 + 3]
ENDM

MACRO ARROWS_DIGIT
	db (ROW_\1 - \2)     * 8, COL_\1 * 8 + 13, T_ARROW_UP, OAM_PRIO
	db (ROW_\1 - \2 + 3) * 8, COL_\1 * 8 + 13, T_ARROW_UP, OAM_PRIO | OAM_YFLIP
ENDM

MACRO ARROWS_WIDTH
	db (ROW_\1 - \2)     * 8, COL_\1 * 8 + 17, T_ARROW_UP, OAM_PRIO
	db (ROW_\1 - \2 + 3) * 8, COL_\1 * 8 + 17, T_ARROW_UP, OAM_PRIO | OAM_YFLIP
ENDM

MACRO ARROWS_PUSHB
	db ROW_\1 * 8,  COL_\1           * 8 - 5, T_ARROW_LEFT, OAM_PRIO
	db ROW_\1 * 8, (COL_\1 + WID_\1) * 8 - 2, T_ARROW_LEFT, OAM_PRIO | OAM_XFLIP
ENDM

MACRO ARROWS_DIR
	db ROW_CH4_DIR * 8,  COL_CH4_DIR                * 8 - 6, T_ARROW_LEFT, OAM_PRIO
	db ROW_CH4_DIR * 8, (COL_CH4_DIR + WID_CH4_DIR) * 8 - 2, T_ARROW_LEFT, OAM_PRIO | OAM_XFLIP
ENDM

MACRO ARROWS_VERT
	db (ROW_\1)     * 8, COL_\1 * 8 + 7, T_ARROW_UP, OAM_PRIO
	db (ROW_\1 + 9) * 8, COL_\1 * 8 + 7, T_ARROW_UP, OAM_PRIO | OAM_XFLIP
ENDM

MACRO INIT_ARROWS
	res 7, a                   ; Clear upper bit
	swap a                     ; Multiply by 8
	rra                        ; ...
	ld e, a
	ld d, HIGH(ArrowsLUT)
	ld hl, wShadowOAM + OBJ_ARROW_UP * OBJ_SIZE
ENDM

MACRO WAIT_JOYP
.loop\@
	call HaltJoypad
	or a
	jr \1, .loop\@
ENDM
