; Super Game Boy Sound Mixer
;
; Copyright (c) 2025 Dmitry Shechtman

include "hardware.inc"
include "defs.inc"


SECTION "Tile Data", ROMX, ALIGN[8]

ObjTiles::
	INCBIN "sel_hex.2bpp"
	INCBIN "sel_quad.2bpp"
	INCBIN "sel_width.2bpp"
	INCBIN "arrows.2bpp"
	INCBIN "sel_dir.2bpp"
	INCBIN "sel_check.2bpp"
.endSel
	INCBIN "obj_labels.2bpp"
.end::

ASSERT (LOW(@) == 0)

DigitTiles::
PrimTiles::
	INCBIN "digits.1bpp"
	INCBIN "borders.1bpp",  0,                      224
	INCBIN "digits.1bpp",   DEF_CH4_DIV * 16,        16
	INCBIN "digits.1bpp",   DEF_CH4_DIV * 16 + 256,  16
	ds 64, 0
	INCBIN "logo2.1bpp"
.alpha
	INCBIN "alpha.1bpp"
	INCBIN "circles.1bpp", 0, 256
.end::


SECTION "Push Tile Data", ROMX, ALIGN[8]

PushTiles::
.hex::
	INCBIN "pushb_hex.2bpp"
.quad::
	INCBIN "pushb_quad.2bpp"
	INCBIN "pushb_quad.2bpp", 0, 16
.width::
	INCBIN "pushb_width.2bpp"
.endWidth::
.dir::
	INCBIN "pushb_dir.2bpp"
.check::
	INCBIN "pushb_check.2bpp"
.endPush::
.labels
	INCBIN "labels.2bpp"
.end::

DisabledTiles:
.hex::
	INCBIN "dis_hex.2bpp"
.quad::
	INCBIN "dis_quad.2bpp"
.width::
	INCBIN "dis_width.2bpp"
.endWidth::
.dir::
	INCBIN "dis_dir.2bpp"
.check::
	INCBIN "dis_check.2bpp"
.end

ASSERT (ObjTiles.endSel   - ObjTiles)      == (PushTiles.endPush - PushTiles)
ASSERT (DisabledTiles.end - DisabledTiles) == (PushTiles.endPush - PushTiles)
ASSERT (LOW(DisabledTiles) == LOW(PushTiles))
	


SECTION "Circle Maps", ROMX, ALIGN[8]

CircleABMap::
	INCBIN "circles.tilemap", 0, 32

CircleAMap::
	INCBIN "circles.tilemap",  0, 4
	INCBIN "circles.tilemap",  8, 4
	INCBIN "circles.tilemap", 16, 4
	INCBIN "circles.tilemap", 24, 4


SECTION "Pitch Button Map", ROMX, ALIGN[8]

; Page-aligned for fast lookup
PitchSelMap::
FOR I, 0, 16
	INCBIN "sel_quad.tilemap",  I, 1
	db 0
ENDR

PitchAMap::
	INCBIN "dis_quad.tilemap",  0, 16

PitchBMap::
	INCBIN "dis_quad.tilemap", 32, 16

; Make sure we're on the same page
ASSERT (LOW(@) == 64)


SECTION "Volume Button Map", ROMX, ALIGN[8]

; Page-aligned for fast lookup
VolSelMap::
FOR I, 0, 16
	INCBIN "sel_quad.tilemap", I + 16, 1
	db 0
ENDR

VolAMap::
	INCBIN "dis_quad.tilemap", 16, 16

VolBMap::
	ds 4, 0
	INCBIN "dis_quad.tilemap", 52, 12

; Make sure we're on the same page
ASSERT (LOW(@) == 64)


SECTION "Pace Button Map", ROMX, ALIGN[8]

; Page-aligned for fast lookup
PaceSelMap::
FOR I, 0, 7
	dw T_SEL_HEX + I
ENDR
	dw T_SEL_DISABLE

Circle4Map::
	INCBIN "circles.tilemap", 32, 4
	INCBIN "circles.tilemap", 40, 4
	INCBIN "circles.tilemap", 48, 4
	INCBIN "circles.tilemap", 56, 4

; Save space
PaceMap::
FOR I, 0, 7
	db T_PUSHB_HEX + I
ENDR
	db T_PUSHB_DISABLE

; Make sure we're on the same page
ASSERT (LOW(@) == 40)
