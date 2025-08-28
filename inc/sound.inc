; Super Game Boy Sound Mixer
;
; Copyright (c) 2025 Dmitry Shechtman


MACRO SOUND_A_TYPE
	ldh a, [hSoundA.typeLow]   ; Load sound A type lower nibble
	ld b, a                    ; Store in B
	ldh a, [hSoundA.typeHigh]  ; Load sound A type upper nibble
	swap a                     ; Multiply by 16
	or b                       ; Add the lower nibble
	ld d, a                    ; Store the result in register D
ENDM

MACRO SOUND_B_TYPE
	ldh a, [hSoundB.typeLow]   ; Load sound B type lower nibble
	ld b, a                    ; Store in B
	ldh a, [hSoundB.typeHigh]  ; Load sound B type upper nibble
	swap a                     ; Multiply by 16
	or b                       ; Add the lower nibble
	ld e, a                    ; Store the result in register E
ENDM

MACRO SOUND_MUTE
	ld hl, wSound.attrs
	ld a, $03
	ld [hld], a
	ld a, $80
	ld [hld], a
	ld [hld], a
	call SGB_SendPacket
ENDM

MACRO SOUND_A_ATTRS
	ldh a, [hSoundA.vol]       ; Load sound A volume
	xor $03                    ; 0=High, 1=Med, 2=Low, 3=Mute
	add a                      ; Multiply by 4
	add a                      ; ...
	ld b, a                    ; Store the result in register B
	ldh a, [hSoundA.pitch]     ; Load sound A pitch
	or b                       ; Add the inverse of volume
ENDM

MACRO SOUND_B_ATTRS_BASE
	ldh a, [hSoundB.vol]       ; Load sound B volume
	xor $03                    ; 0=High, 1=Med, 2=Low
	add a                      ; Multiply by 4
	add a                      ; ...
	ld c, a                    ; Store the result in register C
	ldh a, [hSoundB.pitch]     ; Load sound B pitch
	or c                       ; Add the inverse of volume
ENDM

MACRO SOUND_B_ATTRS
	SOUND_B_ATTRS_BASE
	swap a                     ; Multiply the result by 16
ENDM

MACRO SOUND_TYPE_LEN
	ldh a, [hSoundA.typeHigh]
	ld b, a
	ldh a, [hSoundB.typeHigh]
	add a
	add a
	or b
	ld b, a
	ldh a, [hCH4.lenHigh]
	swap a
	ld a, d
	ldh a, [hCH4.lenLow]
	or a
	jr z, .\@
	dec a
.\@
	ld d, a
	cpl
	and $01
	swap a                     ; Multiply by 8
	rra                        ; ...
	or b
ENDM

MACRO AUD4LEN
	ldh a, [hCH4.lenHigh]
	swap a
	ld d, a                    ; Store the length in D
	ldh a, [hCH4.lenLow]
	or d
	jr nz, .\@
	ldh [rAUDENA], a
	ret
.\@
	dec a
	ld d, a
	cpl
	and $1F
ENDM

MACRO AUD4_BASE
	ldh a, [hCH4.\1]
	swap a
	rra
IF \3
	or b
ENDC
	ld b, a
	ldh a, [hCH4.\2]
	xor $07
	or b
ENDM

MACRO AUD4ENV_BASE
	AUD4_BASE dir, pace, \1
ENDM

MACRO AUD4ENV
	ldh a, [hCH4.vol]
	swap a
	ld b, a
	AUD4ENV_BASE 1
ENDM

MACRO AUD4POLY_BASE
	AUD4_BASE width, div, \1
ENDM

MACRO AUD4POLY
	ldh a, [hCH4.pitch]
	xor $0F
	swap a
	ld b, a
	AUD4POLY_BASE 1
ENDM

MACRO AUD4GO
	ld a, AUD4GO_RESTART       ; Trigger CH4
	bit 5, d                   ; Infinite length?
	jr nz, .\@                 ; If yes, continue
	set B_AUD4GO_LEN_ENABLE, a ; If not, enable length timer
.\@
ENDM
