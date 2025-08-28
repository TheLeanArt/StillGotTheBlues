; Super Game Boy Sound Mixer
;
; Copyright (c) 2025 Dmitry Shechtman

include "hardware.inc"
include "defs.inc"
include "trans.inc"


SECTION "Shake", ROMX

TryShakeTopLeft::
	bit B_PAD_LEFT, d
	jp z, Main.loop
	; Fall through

ShakeTopLeft::
	; No need to clear arrows since we never shake top from bottom
	call DoShakeTopLeft
	call TiltTopRight
	jp Main.loop

DoShakeTopLeft:
	ld h, HIGH(wShadowOAM)
	call TiltTopLeft
	call TiltTopRight2
	call TiltTopLeft2
	call TiltTopRight2
	; Fall through

TiltTopLeft2:
	call TiltTopLeft
	; Fall through

TiltTopLeft:
	rst WaitVBlank
	rst WaitVBlank
	ldh a, [hTopSCX]
	inc a
	ldh [hTopSCX], a
	ld l, OBJ_TOP_START * OBJ_SIZE + OAMA_X
.loop
	dec [hl]
	ld a, l
	add OBJ_SIZE
	ld l, a
	cp OBJ_TOP_END * OBJ_SIZE + OAMA_X
	jr nz, .loop
	ld l, OBJ_ARROW_UP * OBJ_SIZE + OAMA_X
	dec [hl]
	ld l, OBJ_ARROW_DOWN * OBJ_SIZE + OAMA_X
	dec [hl]
	ret

TryShakeTopDown::
	bit B_PAD_DOWN, d
	jp z, Main.loop
	jr ShakeTopRight

TryShakeTopRight::
	bit B_PAD_RIGHT, d
	jp z, Main.loop
	; Fall through

ShakeTopRight::
	; No need to clear arrows since we never shake top from bottom
	call DoShakeTopRight
	call TiltTopLeft
	jp Main.loop

DoShakeTopRight:
	ld h, HIGH(wShadowOAM)
	call TiltTopRight
	call TiltTopLeft2
	call TiltTopRight2
	call TiltTopLeft2
	; Fall through

TiltTopRight2:
	call TiltTopRight
	; Fall through

TiltTopRight:
	rst WaitVBlank
	rst WaitVBlank
	ldh a, [hTopSCX]
	dec a
	ldh [hTopSCX], a
	ld l, OBJ_TOP_START * OBJ_SIZE + OAMA_X
.loop
	inc [hl]
	ld a, l
	add OBJ_SIZE
	ld l, a
	cp OBJ_TOP_END * OBJ_SIZE + OAMA_X
	jr nz, .loop
	ld l, OBJ_ARROW_UP * OBJ_SIZE + OAMA_X
	inc [hl]
	ld l, OBJ_ARROW_DOWN * OBJ_SIZE + OAMA_X
	inc [hl]
	ret

TryShakeBottomLeft::
	bit B_PAD_LEFT, d
	jp z, Main.loop
	; Fall through

ShakeBottomLeft::
	ldh a, [hSelection]
	bit B_BOTTOM, a
	jr nz, .cont
	CLEAR_ARROWS
.cont
	call DoShakeBottomLeft
	call TiltBottomRight
	jp Main.copyArrows

DoShakeBottomLeft:
	ld h, HIGH(wShadowOAM)
	call TiltBottomLeft
	call TiltBottomRight2
	call TiltBottomLeft2
	call TiltBottomRight2
	; Fall through

TiltBottomLeft2:
	call TiltBottomLeft
	; Fall through

TiltBottomLeft:
	rst WaitVBlank
	rst WaitVBlank
	ldh a, [hShadowWX]
	dec a
	ldh [hShadowWX], a
	ld l, OBJ_BOTTOM_START * OBJ_SIZE + OAMA_X
.loop
	dec [hl]
	ld a, l
	add OBJ_SIZE
	ld l, a
	cp (OBJ_ARROW_DOWN + 1) * OBJ_SIZE + OAMA_X
	jr nz, .loop
	jp hFixedOAMDMA

TryShakeBottomRight::
	bit B_PAD_RIGHT, d
	jp z, Main.loop
	; Fall through

ShakeBottomRight::
	ldh a, [hSelection]
	bit B_BOTTOM, a
	jr nz, .cont
	CLEAR_ARROWS
.cont
	call DoShakeBottomRight
	call TiltBottomLeft
	jp Main.copyArrows

DoShakeBottomRight:
	ld h, HIGH(wShadowOAM)
	call TiltBottomRight
	call TiltBottomLeft2
	call TiltBottomRight2
	call TiltBottomLeft2
	; Fall through

TiltBottomRight2:
	call TiltBottomRight
	; Fall through

TiltBottomRight:
	rst WaitVBlank
	rst WaitVBlank
	ldh a, [hShadowWX]
	inc a
	ldh [hShadowWX], a
	ld l, OBJ_BOTTOM_START * OBJ_SIZE + OAMA_X
.loop
	inc [hl]
	ld a, l
	add OBJ_SIZE
	ld l, a
	cp (OBJ_ARROW_DOWN + 1) * OBJ_SIZE + OAMA_X
	jr nz, .loop
	jp hFixedOAMDMA

ASSERT(OBJ_ARROW_UP == OBJ_BOTTOM_END)
