; Game Boy Object Animation Subsystem
;
; Copyright (c) 2025 Dmitry Shechtman

include "hardware.inc"


SECTION "TranslateY", ROM0

; Verically translate objects
;
; @param BC Clobbered
; @param D  End of delta OAM lower byte
; @param HL Start of delta OAM
TranslateY::
.loop
.objY
	ld a, [hl]
	inc h
	add [hl]
	ld b, a
	ld [hli], a
	dec h
	inc l
.cpY
	ld a, [hl]
	sub b                      ; Compare to Y1 (clears A if equal)
	jr nz, .contY
.clearDeltaY
	res 1, l                   ; Back to dY
	ld [hli], a
	inc l
.contY
	inc l
	inc l
	ld a, l
	cp d
	jr nz, .loop
	ret


SECTION "TranslateX", ROM0[$10]

; Horizontally translate objects
;
; @param BC Clobbered
; @param D  End of delta OAM lower byte
; @param HL Start of delta OAM
TranslateX::
.loop
	inc l
.objX
	ld a, [hl]
	inc h
	add [hl]
	ld c, a
	ld [hli], a
	dec h
	inc l
.cpX
	ld a, [hl]
	sub c                      ; Compare to X1 (clears A if equal)
	jr nz, .contX
.clearDeltaX
	dec l
	dec l
	ld [hli], a
	inc l
.contX
	inc l
	ld a, l
	cp d
	jr nz, .loop
	ret


SECTION "Translate", ROM0

; Linearly translate objects
;
; @param BC Clobbered
; @param D  End of delta OAM lower byte
; @param HL Start of delta OAM
Translate::
.loop
.objY
	ld a, [hl]
	inc h
	add [hl]
	ld b, a
	ld [hli], a
	dec h
.objX
	ld a, [hl]
	inc h
	add [hl]
	ld c, a
	ld [hli], a
	dec h
.cpY
	ld a, [hl]
	sub b                      ; Compare to Y1 (clears A if equal)
	jr nz, .contY
.clearDeltaY
	res 1, l                   ; Back to dY
	ld [hli], a
	inc l
.contY
	inc l
.cpX
	ld a, [hl]
	sub c                      ; Compare to X1 (clears A if equal)
	jr nz, .contX
.clearDeltaX
	dec l
	dec l
	ld [hli], a
	inc l
.contX
	inc l
	ld a, l
	cp d
	jr nz, .loop
	ret


SECTION "Interpol8", ROM0[$00]
	
; Linearly interpolate a single object
;
; @param B  Interpolation step (0-7)
; @param C  Clobbered
; @param HL DY/DX address
Interpol8::
	call .coord
	; Fall through

.coord:
	set 1, l                   ; Move to coordinate
	ld c, [hl]                 ; Load DY/DX address
	ld a, [bc]                 ; Load DY/DX
	res 1, l                   ; Move to source Y/X
	add [hl]                   ; Add source Y/X
	inc h                      ; Move to wShadowOAM
	ld [hli], a                ; Store Y/X and advance
	dec h                      ; Move to wDeltaOAM
	ret


SECTION "Interpol8Digits", ROM0
	
; Linearly interpolate digits
;
; @param BC Tile address (advanced)
; @param D  IDiv8LUT upper byte
; @param E  End of delta OAM lower byte
; @param HL Start of delta OAM
Interpol8Digits::
	push de                    ; Save LUT upper byte and end of delta OAM lower byte
	ld a, [hli]                ; Load delta address
	ld e, a                    ; Store delta address
	ld a, [de]                 ; Load delta
	add [hl]                   ; Add source value
	push hl                    ; Save delta OAM address
	ld l, c                    ; Store tile address lower byte
	ld h, b                    ; Store tile address upper byte
	call InitDigit
	ld b, h                    ; Load tile address upper byte
	ld c, l                    ; Load tile address lower byte
	pop hl                     ; Restore delta OAM address
	ld a, l                    ; Load delta OAM lower byte
	add OBJ_SIZE - 1           ; Advance to next delta
	ld l, a                    ; Store delta OAM lower byte
	pop de                     ; Restore LUT upper byte and end of delta OAM lower byte
	cp e                       ; End of delta OAM reached?
	jr nz, Interpol8Digits     ; If not, proceed to loop
	ret


; Initialize linearly interpolated digit
;
; @param A  Swapped digit
; @param B  Clobbered
; @param DE Clobbered
; @param HL Tile address (advanced)
InitDigit::
	ld b, a
FOR I, 0, 2
	ld e, b
IF I == 0
	ld d, HIGH(DigitTiles)
ELSE
	inc d
ENDC
.loop\@
	rst WaitVRAM               ; Wait for accessible VRAM
	ld a, [de]                 ; Load current byte
	ld [hli], a                ; Store lower bitplane
	ld [hli], a                ; Store upper bitplane
	inc e                      ; Move to next byte
	bit 5, l                   ; Are we within the same 32 bytes?
IF I == 0
	jr z, .loop\@              ; Left tile pair; proceed to loop
ELSE
	jr nz, .loop\@             ; Right tile pair; proceed to loop
ENDC
ENDR
	ret


; Initialize linearly interpolated digit
;
; @param A  Swapped digit
; @param B  Clobbered
; @param DE Clobbered
; @param HL Tile address (advanced)
InitDigitDarkLeftBorder::
	ld b, a                    ; Save address
FOR I, 0, 2
	ld e, b                    ; Restore address
IF I == 0
	ld d, HIGH(DigitTiles)
ELSE
	inc d                      ; Move to right half
ENDC
.loop\@
	rst WaitVRAM
IF I == 0
	ld a, $80                 ; Black left border
ENDC
	ld [hli], a
	ld a, [de]
	ld [hli], a
	inc e
	bit 5, l
IF I == 0
	jr z, .loop\@
ELSE
	jr nz, .loop\@
ENDC
ENDR
	ret


; Adapted from Simple GB ASM Examples by Dave VanEe
; License: CC0 (https://creativecommons.org/publicdomain/zero/1.0/)

SECTION "WaitVRAM", ROM0[$28]
WaitVRAM::
    ldh a, [rSTAT]      ; Check the STAT register to figure out which mode the LCD is in
    and STAT_BUSY       ; AND the value to see if VRAM access is safe
	ret z               ; Return when VRAM access is safe
	jr WaitVRAM


SECTION "WaitVBlank" , ROM0[$30]
WaitVBlank::
	halt                ; Wait for interrupt
    ldh a, [rLY]        ; Read the LY register to check the current scanline
    cp SCREEN_HEIGHT_PX ; Compare the current scanline to the first scanline of VBlank
	ret nc              ; Return as soon as the carry flag is clear
	jr WaitVBlank


SECTION "WaitLYC", ROM0[$38]
WaitLYC::
	halt                ; Wait for interrupt
	ldh a, [rLY]        ; Read the LY register to check the current scanline
	cp 64               ; Compare the current scanline to the first scanline of bottom half
	ret nc              ; Return as soon as the carry flag is clear
	jr WaitLYC


; The VBlank vector is where execution is passed when the VBlank interrupt fires
SECTION "VBlank Vector", ROM0[$40]
VBlank::
	push af
	call hFixedOAMDMA
	ld a, LOW(hTopSCY)
	jr STAT.cont


SECTION "STAT Vector", ROM0[$48]
STAT:
	push af
	ld a, LOW(hBottomSCY)

.cont
	push bc
	ld c, a

	ldh a, [c]
	ldh [rSCY], a
	inc c
	ldh a, [c]
	ldh [rSCX], a

	ldh a, [hShadowWY]
	ldh [rWY], a
	ldh a, [hShadowWX]
	ldh [rWX], a

	pop bc
	pop af
	reti                ; Return and enable interrupts (ret + ei)


SECTION "Shadow OAM", WRAM0, ALIGN[8]

; Aligned with wShadowOAM, but preceeds it to save space
; Only doesn't due to wShadowOAM being overrun by something
wDeltaOAM::
	ds 256

; Reserve page-aligned space for a Shadow OAM buffer, to which we can safely write OAM data at any time, 
;  and then use our OAM DMA routine to copy it quickly to OAMRAM when desired. OAM DMA can only operate
;  on a block of data that starts at a page boundary, which is why we use ALIGN[8].
wShadowOAM::
	ds 256 ; TODO OBJ_SIZE


SECTION "OAM DMA Routine", ROMX
; Initiate OAM DMA and then wait until the operation is complete, then return
; @param A High byte of the source data to DMA to OAM
FixedOAMDMA::
	ld a, HIGH(wShadowOAM)
    ldh [rDMA], a
    ld a, OAM_COUNT
.waitLoop
    dec a
    jr nz, .waitLoop
    ret
.end::


SECTION "OAM DMA", HRAM
; Reserve space in HRAM for the OAMDMA routine, equal in length to the routine
hFixedOAMDMA::
    ds FixedOAMDMA.end - FixedOAMDMA


SECTION "HRAM", HRAM[$FFF9] ; TODO Magic

hTopSCY::    ds 1 ; FFF9
hTopSCX::    ds 1 ; FFFA
hBottomSCY:: ds 1 ; FFFB
hBottomSCX:: ds 1 ; FFFC
hShadowWY::  ds 1 ; FFFD
hShadowWX::  ds 1 ; FFFE
