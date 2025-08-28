; Super Game Boy Sound Mixer
;
; Copyright (c) 2025 Dmitry Shechtman

include "hardware.inc"
include "defs.inc"
include "sound.inc"


SECTION "Sound Subroutines", ROMX

DoSoundA::
	SOUND_MUTE
	SOUND_A_TYPE
	ret z                      ; If sound A type is zero, we're done

	ld hl, wSound.attrs        ; Set the packet bytes in reverse
	SOUND_A_ATTRS
	ld [hld], a                ; Set attributes
	ld a, $80                  ; Mute sound B
	ld [hld], a                ; Set sound B type
	ld a, d                    ; Load sound A type
	ld [hld], a                ; Set sound A type
	jp SGB_SendPacket

DoSoundB::
	SOUND_MUTE
	SOUND_B_TYPE
	ret z                      ; If sound B type is zero, we're done

	ld hl, wSound.attrs        ; Set the packet bytes in reverse
	SOUND_B_ATTRS
	ld [hld], a                ; Set attributes
	ld a, e                    ; Load sound B type
	ld [hld], a                ; Set sound B type
	ld a, $80                  ; Mute sound A
	ld [hld], a                ; Set sound A type
	jp SGB_SendPacket

DoSoundAB::
	SOUND_MUTE
	SOUND_A_TYPE
	SOUND_B_TYPE
	or d                       ; If both sound A and sound B types are zero
	ret z                      ; ... we're done

	ld hl, wSound.attrs        ; Set the packet bytes in reverse
	SOUND_A_ATTRS
	ld b, a                    ; Store sound A attributes in register B
	SOUND_B_ATTRS
	or b                       ; Add sound A pitch/volume
	ld [hld], a                ; Set attributes
	ld a, e                    ; Load sound B type
	or a                       ; Is it zero?
	jr nz, .setA               ; If not, continue
	set B_SOUND_MUTE, a        ; Otherwise, mute sound A
.setA
	ld [hld], a                ; Set sound B type
	ld a, d                    ; Load sound A type
	or a                       ; Is it zero?
	jr nz, .setB               ; If not, continue
	set B_SOUND_MUTE, a        ; Otherwise, mute sound B
.setB
	ld [hld], a                ; Set sound A type
	jp SGB_SendPacket

DoSoundAll::
	call DoSoundAB
	; Fall through

DoCh4::
	; Must be first for any the rest to have effect
	ld a, AUDENA_ON | AUDENA_CH4_ON
	ldh [rAUDENA], a
	ld a, AUDVOL_LEFT | AUDVOL_RIGHT
	ldh [rAUDVOL], a
	ld a, AUDTERM_4_LEFT | AUDTERM_4_RIGHT
	ldh [rAUDTERM], a
	AUD4LEN
	ldh [rAUD4LEN], a
	AUD4ENV
	ldh [rAUD4ENV], a
	AUD4POLY
	ldh [rAUD4POLY], a
	AUD4GO
	ldh [rAUD4GO], a
	ret

SECTION "SGB Packet Buffer", WRAM0

wSound::
	.command ds 1
	.soundA  ds 1
	.soundB  ds 1
	.attrs   ds 1
	.padding ds wSound - @ + 16
