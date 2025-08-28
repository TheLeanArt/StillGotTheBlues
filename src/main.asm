; Super Game Boy Sound Mixer
;
; Copyright (c) 2025 Dmitry Shechtman

include "hardware.inc"
include "defs.inc"
include "common.inc"
include "intro.inc"
include "macros.inc"
include "update.inc"
include "trans.inc"
include "charmap.inc"


SECTION "Clear Rows", ROM0

ClearThreeRows:
	call ClearRow
	; Fall through

ClearTwoRows:
	call ClearRow
	; Fall through

ClearRow:
	BORDER LEFT
	CLEAR_SHORT SCREEN_WIDTH - 2
	BORDER RIGHT
	BORDER LEFT                ; For prettier shake
	ld a, l
	add TILEMAP_WIDTH - SCREEN_WIDTH - 2
	ld l, a
	BORDER RIGHT               ; For prettier shake
	ret


SECTION "Set Message", ROM0

SetMessage:
	ld de, Message
	call .row
	; Fall through

.row
	BORDER LEFT
	CLEAR_SHORT 2
	ld b, MSG_WIDTH

.loop
	ld a, [de]
	ld [hli], a
	inc e
	dec b
	jr nz, .loop

	CLEAR_SHORT 2
	BORDER RIGHT
	BORDER LEFT                ; For prettier shake
	ld a, l
	add TILEMAP_WIDTH - SCREEN_WIDTH - 2
	ld l, a
	BORDER RIGHT               ; For prettier shake
	ret


SECTION "Update Logo", ROM0

UpdateLogo::
.row1
	ld a, T_LOGO1
	ld hl, TILEMAP0 + TILEMAP_WIDTH + COL_A_NAME - 1
	ld bc, LOGO_WIDTH << 8 | LOW(hNameA)
	call .loop

.row2
	ld l, TILEMAP_WIDTH * 2 + COL_A_NAME - 1
	ld b, LOGO_WIDTH

.loop
	ld [hli], a
	ldh [c], a
	inc a
	inc c
	dec b
	jr nz, .loop
	ret


; Adapted from Simple GB ASM Examples by Dave VanEe 2022
; License: CC0 1.0 (https://creativecommons.org/publicdomain/zero/1.0/)

SECTION "Start", ROM0[$0100]
    di                  ; Disable interrupts during setup
    jr EntryPoint       ; Jump past the header space to our actual code
    ds $150 - @, 0      ; Allocate space for RGBFIX to insert our ROM header

EntryPoint:
    ld sp, $E000        ; Set the stack pointer to the end of WRAM

    cp BOOTUP_A_CGB     ; GBC/GBA?
	jr z, .GBC          ; If yes, handle

.notGBC:
	ld a, c             ; Load the initial value of C into A
	cp BOOTUP_C_SGB     ; SGB?
	jr nz, .notSGB      ; If not, skip

.SGB:
	ld b, FLAG_SUPER    ; Set flags to Super
	jr .flags           ; Skip to setting the flags

.notSGB:
	ld a, b             ; Load the initial value of B into A
	cp BOOTUP_B_DMG0    ; DMG0?
	jr z, .DMG0         ; If yes, handle
    jr .flags           ; Skip to setting the flags

.GBC:
    ld b, FLAG_COLOR    ; Set flags to Color
    jr z, .flags        ; If not, skip to setting the flags

.DMG0:
	ld b, FLAG_DMG0     ; Set flags to DMG0

.flags:
	ld a, b
	ldh [hFlags], a

	ld a, c             ; Load the initial value of C into A
	cp BOOTUP_C_SGB     ; SGB?
	ld a, LOW(hSelection.soundAVert)
	jr z, .contSGB

.SGB2
	xor a

.contSGB
	ldh [hSelection.topAddr], a

	xor a
	ldh [hSoundA.typeLow],  a
	ldh [hSoundA.typeHigh], a
	ldh [hSoundA.pitch],    a
	ldh [hSoundB.typeLow],  a
	ldh [hSoundB.typeHigh], a
	ldh [hSoundB.pitch],    a
	ldh [hCH4.width],       a
	ldh [hCH4.div],         a
	ldh [hCH4.dir],         a
	ldh [hCH4.pace],        a
	inc a
	ldh [hCH4.lenLow],      a
	inc a
	ldh [hCH4.lenHigh],     a
	inc a
	ldh [hSoundA.vol],      a
	ldh [hSoundB.vol],      a
	ld a, $0F
	ldh [hCH4.pitch],       a
	ldh [hCH4.vol],         a

	ld a, LOW(hSoundA.typeLow)
	ldh [hSelection], a
	ldh [hSelection.soundAVert], a
	ld a, LOW(hSoundA.pitch)
	ldh [hSelection.soundAHoriz], a
	ld a, LOW(hSoundB.typeLow)
	ldh [hSelection.soundBVert], a
	ld a, LOW(hSoundB.pitch)
	ldh [hSelection.soundBHoriz], a
	ld a, LOW(hSelection.ch4Vert)
	ldh [hSelection.bottomAddr], a
	ld a, LOW(hCH4.lenLow)
	ldh [hSelection.ch4Vert], a
	ld a, LOW(hCH4.pitch)
	ldh [hSelection.ch4Horiz], a

    xor a                      ; Once we exit the loop we're safely in VBlank
    ldh [rIE], a               ; Disable all interrupts
	ldh [hCurrentKeys], a      ; Clear current keys
	ldh [hActiveKeys], a       ; Clear active keys
	ldh [hTopSCX], a           ; Clear top SCX
	ldh [hBottomSCX], a        ; Clear bottom SCX

	ld a, Y_INTRO_TOP          ; Load the initial Y value into A
	ldh [hTopSCY], a           ; Set the background's top Y coordinate
	ldh [hBottomSCY], a        ; Set the background's bottom Y coordinate
	ldh [hShadowWY], a         ; Set the window's Y coordinate

	ld a, WX_OFS               ; Load the window's X value into A
	ldh [hShadowWX], a         ; Set the window's X coordinate

	; Copy the OAMDMA routine to HRAM
    ld hl, FixedOAMDMA         ; Load the source address of our routine into HL
    ld bc, (FixedOAMDMA.end - FixedOAMDMA) << 8 | LOW(hFixedOAMDMA)
.copyLoop
	ld a, [hli]
	ldh [c], a
	inc c
	dec b
	jr nz, .copyLoop

	ld a, BANK_INTRO
	ld [rROMB0], a
	call Intro
	ld a, 1
	ld [rROMB0], a

	ld hl, wDeltaOAM
	CLEAR_LONG 2

	ld hl, wDeltaOAM + OBJ_A_PITCH * OBJ_SIZE

	; Sound A pitch
FOR I, 0, 4
	SET_OBJ_TOP ROW_A_PITCH   << 3, 0, 0
ENDR

	; Sound A volume
FOR I, 0, 4
	SET_OBJ_TOP ROW_A_VOL     << 3, 0, 0
ENDR

	; Sound B pitch
	SET_OBJ_TOP ROW_A_PITCH   << 3, 0, 0
FOR I, 0, 3
	SET_OBJ_TOP ROW_A_PITCH   << 3, 0, 0
	; SET_OBJ_TOP ROW_A_PITCH   << 3, (I * 8) + 9, T_LABEL_PITCH + I
ENDR

	; Sound B volume
FOR I, 0, 3
	; SET_OBJ_TOP ROW_A_VOL     << 3, (I * 8) + 9, T_LABEL_VOL + I
	SET_OBJ_TOP ROW_A_VOL     << 3, 0, 0
ENDR
	SET_OBJ_TOP ROW_A_VOL     << 3, 0, 0

	; Channel 4
	SET_OBJ_BTM ROW_CH4_WIDTH << 3, (COL_CH4_WIDTH)      << 3 + 13, T_SEL_CH4_WIDTH
	SET_OBJ_BTM ROW_CH4_WIDTH << 3, (COL_CH4_WIDTH +  1) << 3 + 13, T_SEL_CH4_WIDTH + 1
	SET_OBJ_BTM ROW_CH4_PITCH << 3, (COL_CH4_PITCH + 15) << 3 + 1,  T_SEL_CH4_PITCH + $0F
	SET_OBJ_BTM ROW_CH4_VOL   << 3, (COL_CH4_VOL   + 15) << 3 + 1,  T_SEL_CH4_VOL   + $0F
	SET_OBJ_BTM ROW_CH4_DIR   << 3, COL_CH4_DIR          << 3,      T_SEL_CH4_DIR
	SET_OBJ_BTM ROW_CH4_DIR   << 3, (COL_CH4_DIR   +  1) << 3,      T_SEL_CH4_DIR   + 1
	SET_OBJ_BTM ROW_CH4_PACE  << 3, COL_CH4_PACE         << 3 + 1,  T_SEL_CH4_PACE

FOR I, OBJ_LABEL_PITCH, OBJ_LABEL_BITS
	SET_OBJ_BTM 0, 0, 0, 0
ENDR

	SET_OBJ_BTM 11 * 8 + 4, 11                << 3 + 3, T_LABEL_BITS
	SET_OBJ_BTM 11 * 8 + 4, 12                << 3 + 3, T_LABEL_BITS + 1
	SET_OBJ_BTM 11 * 8 + 4, 16                << 3 - 1, T_LABEL_DIV
	SET_OBJ_BTM 11 * 8 + 4, 17                << 3 - 1, T_LABEL_DIV  + 1

.loop
    ldh a, [rLY]               ; Read the LY register to check the current scanline
    cp SCREEN_HEIGHT_PX        ; Compare the current scanline to the first scanline of VBlank
    jr c, .loop                ; Loop as long as the carry flag is set

	xor a
    ldh [rLCDC], a             ; Disable the LCD (must be done during VBlank to protect the LCD)

	ld a, INIT_SCY
	ldh [hTopSCY], a           ; Set top SCY
	ldh [hBottomSCY], a        ; Set bottom SCX

	ld a, INIT_WY
	ldh [hShadowWY], a         ; Set window Y

	; Clear the first 64 tiles in VRAM
	ld hl, STARTOF(VRAM)
	CLEAR_LONG 4

	; Copy our tiles to the remaining VRAM
	ld de, ObjTiles
	COPY_2BPP Obj
	COPY_1BPP Prim
	ld de, PushTiles
	COPY_2BPP Push

	ldh a, [hSelection.topAddr]
	or a
	jr nz, .setSoundAB

	ld a, LOW(hCH4.lenLow)
	ldh [hSelection], a

	BORDER TOP_LEFT
	SET_SHORT T_BRD_TOP, SCREEN_WIDTH - 2
	BORDER TOP_RIGHT
	BORDER LEFT                ; For prettier shake
	ld l, TILEMAP_WIDTH - 1
	BORDER RIGHT               ; For prettier shake

	call ClearTwoRows
	call SetMessage
	call ClearThreeRows

	jp .clearTop

.setSoundAB
	CIRCLE AB, 0, 0
	DIGIT_DBL_TOP
	SET_SHORT T_BRD_TOP, 10
	BORDER TOP_RIGHT
	CIRCLE_BASE
	DIGIT_DBL_TOP
	SET_SHORT T_BRD_TOP, 2
	BORDER RIGHT               ; For prettier shake

	CIRCLE_BASE
	DIGIT_DBL 0, 0, 1
	INC_SHORT T_LOGO1, 12
	B_START 1
	
	CIRCLE_BASE
	DIGIT_DBL 1, 0, 1
	INC_SHORT T_LOGO2, 12
	B_START 2

	CIRCLE_BASE
	DIGIT_DBL_BOTTOM
	SET_SHORT T_BRD_BOTTOM, 10
	DOT RIGHT_BTM_LEFT
	CIRCLE_BASE 1, 3
	DIGIT_DBL_BOTTOM
	SET_SHORT T_BRD_BOTTOM, 2
	BORDER RIGHT               ; For prettier shake

	LABEL_BASE PITCH, 1
	PUSHB PitchA
	LABEL_BASE PITCH, 1
	COPY_SHORT 8
	BORDER RIGHT               ; For prettier shake

	BORDER_LEFT_BASE
	CLEAR_SHORT 1
	SET_SHORT T_BRD_TOP_BOTTOM, 16
	DOT RIGHT_DBL_LEFT
	BORDER_LEFT_BASE
	CLEAR_SHORT 1
	SET_SHORT T_BRD_TOP, 4
	SET_SHORT T_BRD_TOP_BOTTOM, 4
	BORDER RIGHT               ; For prettier shake

	LABEL_BASE VOL, 1
	PUSHB VolA
	LABEL_BASE VOL, 1
	COPY_SHORT 8
	BORDER RIGHT               ; For prettier shake
	
	BORDER_LEFT_BASE
	CLEAR_SHORT 1
	SET_SHORT T_BRD_TOP, 16
	DOT RIGHT_TOP_LEFT
	BORDER_LEFT_BASE
	CLEAR_SHORT 5
	SET_SHORT T_BRD_TOP, 4
	BORDER RIGHT               ; For prettier shake

	ld a, $01
	ldh [hSoundA.typeLow], a
	set 1, a                   ; 3
	ldh [hSoundA.pitch],   a
	ldh [hSoundB.pitch],   a

	call UpdateLogo
	call ClearNameB

	ldh a, [hSoundA.pitch]
	UPDATE_PITCH A
	UPDATE_VOL A

.clearTop
	ld hl, TILEMAP0 + TILEMAP_WIDTH * 8
	SET_SHORT T_BRD_TOP, TILEMAP_WIDTH

.clearLogo
	ld l, TILEMAP_WIDTH
	CLEAR_SHORT SCREEN_WIDTH

.setCh4
	CIRCLE 4, 1, 0
	SET_SHORT T_BRD_TOP, 2
	DIGIT_DBL_TOP
	BORDER TOP
	ld a, $D0
	ld [hli], a
	BORDER TOP_BOTTOM
	ld a, $D1
	ld [hli], a
	BORDER TOP
	DIGIT_TOP
	DOT TOP_RIGHT
	BORDER LEFT                ; For prettier shake

	CIRCLE 4, 1, 1
	LABEL_BASE LEN, 1
	DIGIT_DBL 0, DEF_CH4_LEN_HIGH, DEF_CH4_LEN_LOW
	BORDER LEFT
	CLEAR_SHORT 1
	PUSHB_WIDTH 1
	CLEAR_SHORT 2
	DIGIT 0
	BORDER LEFT_RIGHT
	BORDER LEFT                ; For prettier shake
	
	CIRCLE 4, 1, 2
	LABEL_BASE LEN, 2
	DIGIT_DBL 1, DEF_CH4_LEN_HIGH, DEF_CH4_LEN_LOW
	BORDER LEFT
	CLEAR_SHORT 1
	PUSHB_WIDTH 2
	CLEAR_SHORT 2
	DIGIT 1
	BORDER LEFT_RIGHT
	BORDER LEFT                ; For prettier shake

	CIRCLE 4, 1, 3
	SET_SHORT T_BRD_BOTTOM, 2
	DIGIT_DBL_BOTTOM
	BORDER BOTTOM
	ld a, $D2
	ld [hli], a
	BORDER TOP_BOTTOM
	ld a, $D3
	ld [hli], a
	SET_SHORT T_BRD_BOTTOM, 2
	SET_SHORT T_BRD_TOP_BOTTOM, 2
	DOT RIGHT_DBL_LEFT
	BORDER LEFT                ; For prettier shake

	BORDER_LEFT 4, 0
	CLEAR_SHORT 1
	PUSHB_HEX
	BORDER LEFT                ; For prettier shake

	BORDER_LEFT 5, 0
	xor a
	ld [hli], a
	SET_SHORT T_BRD_TOP_BOTTOM, 16
	DOT RIGHT_DBL_LEFT
	BORDER LEFT                ; For prettier shake

	BORDER_LEFT 6, 0
	CLEAR_SHORT 1
	PUSHB_HEX
	BORDER LEFT                ; For prettier shake
	
	BORDER_LEFT 7, 0
	CLEAR_SHORT 1
	SET_SHORT T_BRD_TOP_BOTTOM, 8
	DOT TOP_BTM_LEFT
	SET_SHORT T_BRD_TOP, 2
	DOT TOP_BTM_RIGHT
	SET_SHORT T_BRD_TOP_BOTTOM, 4
	DOT RIGHT_DBL_LEFT
	BORDER LEFT                ; For prettier shake

	ld hl, TILEMAP1 + TILEMAP_WIDTH * 8
	BORDER LEFT
	CLEAR_SHORT 2
	COPY_SHORT 8
	BORDER LEFT
	CLEAR_SHORT 2
	BORDER RIGHT
	PUSHB_DIR
	BORDER LEFT                ; For prettier shake
	
	ld l, TILEMAP_WIDTH
	BORDER BOTTOM_LEFT
	SET_SHORT T_BRD_BOTTOM, 2
	SET_SHORT T_BRD_TOP_BOTTOM, 8
	DOT BTM_TOP_LEFT
	SET_SHORT T_BRD_BOTTOM, 2
	BORDER TOP_BTM_RIGHT
	SET_SHORT T_BRD_TOP_BOTTOM, 4
	BORDER DOT_BTM_RIGHT
	BORDER LEFT                ; For prettier shake

	ld hl, rSTAT               ; Prepare to set registers consecutively
	ld a, STAT_LYC             ; Trigger on LYC
	ld [hli], a                ; Store STAT and advance to rSCY
	ld a, INIT_SCY             ; Set background X coordinate
	ld [hli], a                ; Store SCY and advance to rSCX
	xor a                      ; Set background Y coordinate
	ld [hli], a                ; Set SCX and andvance to rLY
	inc l                      ; Advance to rLYC
	ld a, FINAL_WY             ; Set LYC
	ld [hli], a                ; Store LYC and advance to rDMA
	inc l                      ; Skip to rBGP
	ld a, %11_10_00_00         ; Set color 01 to 00 (white) to:
	                           ; 1. make selection objects opaque,
	                           ; 2. hide animated arrows behind push buttons, and
	                           ; 3. colorize selection (since color 0 is shared within PAL01).
	ld [hli], a                ; Set BGP and advance to rOBP0
	ld a, %11_11_00_00         ; Set color 10 to 11 (black)
	ld [hli], a                ; Set OBP0 and advance to rOBP1
	ld a, %10_11_00_00         ; Set color 11 to 10 (dark gray) to disable controls
	ld [hli], a                ; Set OBP1 and advance to rWY

    ; Setup the VBlank interrupt
    ld a, IE_VBLANK | IE_STAT  ; Load the flag to enable the VBlank and STAT interrupts into A
    ldh [rIE], a               ; Load the prepared flag into the interrupt enable register
    xor a                      ; Set A to zero
    ldh [rIF], a               ; Clear any lingering flags from the interrupt flag register to avoid false interrupts

    call VBlank                ; This saves us:
	                           ; 1. setting background and window coordinates,
	                           ; 2. calling the OAM DMA routine, and, finally,
	                           ; 3. enabling the interrupts.
	
	ld a, LCDC_ON | LCDC_BG_ON | LCDC_BLOCK21 | LCDC_WIN_ON | LCDC_WIN_9C00 | LCDC_OBJ_ON
	ldh [rLCDC], a             ; Enable and configure the LCD

	; Prepare SGB sound packet data
	ld hl, wSound
	ld a, SGB_SOUND | 1
	ld [hli], a
	CLEAR_SHORT 15

	call DoSoundAll

	ld d, OBJ_OFFSET * OBJ_SIZE
.animLoop
	; Animate top
	rst WaitVBlank

	ldh a, [hTopSCY]
	ld h, HIGH(EntryAnimLUT)
	ld l, a
	ld a, [hli]
	ld h, [hl]
	ld l, a
	jp hl

.do30:
	ld hl, wShadowOAM + OBJ_LABEL_PITCH * OBJ_SIZE
	ld b, T_LABEL_PITCH
	ld d, SCREEN_WIDTH_PX
	call SetLeftLabel3
	jr .cont

.do10
	ld hl, wShadowOAM + OBJ_LABEL_ENV * OBJ_SIZE
	ld b, T_LABEL_ENV + 1
	ld d, SCREEN_WIDTH_PX
	call SetLeftLabel3
	ld e, (COL_CH4_DIR - 3) * 8 + 3
	call SetLabel2
	jr .cont

.do20
	ld hl, wShadowOAM + OBJ_LABEL_VOL * OBJ_SIZE
	ld b, T_LABEL_VOL
	ld d, SCREEN_WIDTH_PX
	call SetLeftLabel3

.cont
	ld h, HIGH(wDeltaOAM)
	ld l, OBJ_TOP_START * OBJ_SIZE
	ld d, OBJ_TOP_END * OBJ_SIZE
	call TranslateY

	; Animate bottom
	rst WaitLYC
	ld d, OBJ_BOTTOM_END * OBJ_SIZE
	call TranslateY
	
	ldh a, [hShadowWY]
	sub 2
	ldh [hShadowWY], a
	add INIT_SCY - INIT_WY
	ldh [hTopSCY], a
	ldh [hBottomSCY], a
	jr nz, .animLoop

.initCh4Div
	; Permanently set DIV to its digit tiles
FOR I, 0, 2
IF I == 0
	ld a, T_DIGIT_DIV
	ld hl, TILEMAP1 + TILEMAP_WIDTH + COL_CH4_DIV
ELSE
	dec a
	ld l, LOW(TILEMAP_WIDTH * 2 + COL_CH4_DIV)
ENDC
	ld [hli], a
	inc a
	inc a
	ld [hl], a
ENDR
	jr DoBorder

InterpolateArrows::
	ldh [hSelection], a        ; Store selection
	INIT_ARROWS
FOR I, 0, 2                    ; Up/Down
FOR J, 0, 2                    ; Y/X
	ld a, [de]                 ; Load destination Y/X
	ld b, [hl]                 ; Load source Y/X
	sub b                      ; Subtract source Y/X
	dec h                      ; Move to wDeltaOAM
	ld [hl], b                 ; Store source Y/X
	set 1, l                   ; Move to DY/DX
	ld [hl], a                 ; Store DY/DX (and advance)
	inc e                      ; Move to X/tile ID
	inc h                      ; Move to wShadowOAM
	res 1, l                   ; Move to source Y/X
	inc l                      ; ...
ENDR
FOR J, 0, 2                    ; Tile ID/flags
	ld a, [de]                 ; Load tile ID/flags
	ld [hli], a                ; Store tile ID/flags and advance
	inc e                      ; Advance
ENDR
ENDR
	ld b, HIGH(IDiv8LUT)
	dec h                      ; Move to wDeltaOAM
.loop
	rst WaitVBlank
	ld l, OBJ_ARROW_UP * OBJ_SIZE
	rst Interpol8
	ld l, OBJ_ARROW_DOWN * OBJ_SIZE
	rst Interpol8
	inc b
	bit 3, b
	jr z, .loop
	call CopyHandlers
	jr Main.loop

DoBorder::
	rst WaitVBlank

	ld a, T_BRD_LEFT
FOR I, 9, 20
IF I == 9 || I == 16
	ld hl, TILEMAP0 + TILEMAP_WIDTH * I
ELSE
	ld l, LOW(TILEMAP_WIDTH * I)
ENDC
	ld [hl], a
	ld l, LOW(TILEMAP_WIDTH * I + SCREEN_WIDTH)
	ld [hl], a
ENDR

	ld a, 16
	ldh [hBottomSCY], a
	; Fall through

Main::
	call CopyHandlers

.copyArrows::
	ldh a, [hSelection]        ; Load selection
	INIT_ARROWS
	ld c, 2 * OBJ_SIZE
.copyLoop
	ld a, [de]
	ld [hli], a
	inc e
	dec c
	jr nz, .copyLoop

.loop::
	call HaltJoypad
	ldh a, [hSelection]        ; Load selection
	bit B_PAD_A, d             ; A pushed?
	jr nz, .A
	bit B_PAD_B, d             ; B pushed?
	jr nz, .B
	bit B_PAD_RIGHT, b         ; RIGHT held?
	jr nz, .right
	bit B_PAD_LEFT, b          ; LEFT held?
	jr nz, .left
	bit B_PAD_UP, b            ; UP held?
	jr nz, .up
	bit B_PAD_DOWN, b          ; DOWN held?
	jr nz, .down
	bit B_PAD_SELECT, d        ; SELECT pushed?
	jr z, .trySelect           ; If not, try to handle SELECT

.setSelect
	ldh a, [hActiveKeys]       ; Load active keys
	set B_PAD_SELECT, a        ; Activate SELECT
	ldh [hActiveKeys], a       ; ...
	jr .loop                   ; Loop

.trySelect
	ld hl, wHandlers.select
	bit B_PAD_SELECT, b        ; SELECT held?
	jr nz, .tryStart           ; If not, try to handle START
	ldh a, [hActiveKeys]       ; Load active keys
	bit B_PAD_SELECT, a        ; SELECT active?
	jr z, .tryStart            ; If not, try to handle START
	                           ; Fall through

.select
	res B_PAD_SELECT, a        ; Deactivate SELECT
	ldh [hActiveKeys], a       ; ...
	jr .doSelect               ; Handle SELECT

.tryStart
	bit B_PAD_START, d         ; START pushed?
	jr z, .loop                ; If not, loop
	bit B_PAD_A, b             ; A held?
	jr nz, .startA             ; If yes, handle START+A
	bit B_PAD_B, b             ; B held?
	jr nz, .startB             ; If yes, handle START+B
	call DoSoundAll
	jr .loop

.A
	bit B_PAD_B, b             ; B held?
	jr nz, DoPassword          ; If yes, handle A+B
	ld hl, wHandlers.A         ; Prepare to handle A
	bit B_PAD_START, b         ; START held?
	jr z, .handle              ; If not, handle A
	                           ; Fall through

.startA
	ld l, LOW(wHandlers.startA); Prepare to handle START+A
	bit B_PAD_SELECT, b        ; SELECT held?
	jr z, .doSelect            ; If not, handle START+A

.selectStartA
	ldh a, [hActiveKeys]       ; Deactivate SELECT
	res B_PAD_SELECT, a        ; ...
	ldh [hActiveKeys], a       ; ...
	ld l, LOW(wHandlers.selectStartA)
	jr .doSelect

.B
	bit B_PAD_A, b             ; A held?
	jr nz, DoPassword          ; If yes, handle A+B
	ld hl, wHandlers.B         ; Prepare to handle B
	bit B_PAD_START, b         ; START held?
	jr z, .handle              ; If not, handle B
	                           ; Fall through

.startB
	ld l, LOW(wHandlers.startB); Prepare to handle START+B
	bit B_PAD_SELECT, b        ; SELECT held?
	jr z, .doSelect            ; If not, handle START+B

.selectStartB
	ldh a, [hActiveKeys]       ; Deactivate SELECT
	res B_PAD_SELECT, a        ; ...
	ldh [hActiveKeys], a       ; ...
	ld l, LOW(wHandlers.selectStartB)
	jr .doSelect

.right
	ld hl, wHandlers.right
	jr .handle

.left
	ld hl, wHandlers.left
	jr .handle

.up
	ld hl, wHandlers.up
	jr .handle

.down
	ld hl, wHandlers.down
	; Fall through

.handle
	bit B_PAD_SELECT, b
	jr nz, .handleSelect
	ld c, a                    ; Store selection into C
	ld a, [hli]                ; Load lower byte
	ld h, [hl]                 ; Load upper byte into H
	ld l, a                    ; Load lower byte into L
	ldh a, [c]                 ; Load current value
	jp hl

.handleSelect
	ldh a, [hActiveKeys]
	res B_PAD_SELECT, a
	ldh [hActiveKeys], a
	set 4, l
	; Fall through

.doSelect
	ld a, [hli]                ; Load lower byte
	ld h, [hl]                 ; Load upper byte into H
	ld l, a                    ; Load lower byte into L
	ldh a, [hSelection]        ; Load selection
	jp hl


SECTION "Opening Translation Routine LUT", ROMX, ALIGN[8]

EntryAnimLUT:

FOR I, 0, -INIT_SCY, 2
IF I == $10
	dw EntryPoint.do10
ELIF I == $20
	dw EntryPoint.do20
ELIF I == $30
	dw EntryPoint.do30
ELSE
	dw EntryPoint.cont
ENDC
ENDR

ASSERT (LOW(@) == -INIT_SCY)


SECTION "Message Text", ROMX

Message:
	.row1 db "Super Game Boy"
	.row2 db " not detected "


SECTION "HRAM Parameters", HRAM, ALIGN[7]

hSoundA:
.vert::
	.typeHigh   :: ds 1
	.typeLow    :: ds 1
.horiz::
	.pitch      :: ds 1
	.vol        :: ds 1

hSoundB:
.vert::
	.typeHigh   :: ds 1
	.typeLow    :: ds 1
.horiz::
	.pitch      :: ds 1
	.vol        :: ds 1

hCH4:
.vert::
	.lenHigh    :: ds 1
	.lenLow     :: ds 1
	.width      :: ds 1
	.div        :: ds 1
.horiz::
	.pitch      :: ds 1
	.vol        :: ds 1
	.pace       :: ds 1
	.dir        :: ds 1

ASSERT (@ == STARTOF(HRAM) + FIELD_COUNT)

hSelection::
	.current    :: ds 1 ; .hSoundA.typeHigh-hCh4.pace
	.soundAVert :: ds 1
	.soundAHoriz:: ds 1
	.soundBVert :: ds 1
	.soundBHoriz:: ds 1
	.ch4Vert    :: ds 1
	.ch4Horiz   :: ds 1
	.topAddr    :: ds 1 ; .soundAVert/.soundAHoriz/.soundBVert/.soundBHoriz
	.bottomAddr :: ds 1 ; .ch4Vert/.ch4Horiz


SECTION "Sound Name Buffers", HRAM

hNameA::
	.row1::   ds LOGO_WIDTH
	.row2::   ds LOGO_WIDTH
	.end::

hNameB::
	.row1::   ds LOGO_WIDTH
	.row2::   ds LOGO_WIDTH
	.end::


SECTION "Arrows LUT", ROMX, ALIGN[8]

ArrowsLUT:
.soundA
	ARROWS_DIGIT A_TYPE_HIGH, 0
	ARROWS_DIGIT A_TYPE_LOW,  0
	ARROWS_PUSHB A_PITCH
	ARROWS_PUSHB A_VOL
.soundB
	ARROWS_DIGIT A_TYPE_HIGH, 0
	ARROWS_DIGIT A_TYPE_LOW,  0
	ARROWS_PUSHB A_PITCH
	ARROWS_PUSHB B_VOL
.ch4vert
	ARROWS_DIGIT CH4_LEN_HIGH, 1
	ARROWS_DIGIT CH4_LEN_LOW,  1
	ARROWS_WIDTH CH4_WIDTH,    1
	ARROWS_DIGIT CH4_DIV,      1
.ch4horiz
	ARROWS_PUSHB CH4_PITCH
	ARROWS_PUSHB CH4_VOL
	ARROWS_PUSHB CH4_PACE
	ARROWS_DIR

ASSERT (LOW(@) == FIELD_COUNT * 8)


SECTION "Signed Multiply by J/8 LUT", ROM0, ALIGN[11]

IDiv8LUT::
FOR I, 1, 9
	FOR J, 0, 128
		db I * J / 8
	ENDR
	FOR J, -128, 0
		db I * J / 8
	ENDR
ENDR

ASSERT (@ - IDiv8LUT == 8 * 256)
