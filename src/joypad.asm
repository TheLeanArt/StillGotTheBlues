; Adapted from https://github.com/tbsp/simple-gb-asm-examples/blob/master/src/joypad/joypad.asm
;
; License: CC0 (https://creativecommons.org/publicdomain/zero/1.0/)
;
; by Dave VanEe 2022

include "hardware.inc"


SECTION "Joypad", ROM0

HaltJoypad::
	halt

UpdateJoypad::
    ld a, JOYP_GET_BUTTONS ; Load a flag into A to select reading the buttons
    ldh [rJOYP], a      ; Write the flag to P1 to select which buttons to read
REPT 6
    ldh a, [rJOYP]      ; Perform a few dummy reads to allow the inputs to stabilize
ENDR
    or $F0              ; Set the upper 4 bits, and leave the action button states in the lower 4 bits
    ld b, a             ; Store the state of the action buttons in B

    ld a, JOYP_GET_CTRL_PAD ; Load a flag into A to select reading the dpad
    ldh [rJOYP], a      ; Write the flag to P1 to select which buttons to read
    call .knownRet      ; Call a known `ret` instruction to give the inputs to stabilize
REPT 6
    ldh a, [rJOYP]      ; Perform a few dummy reads to allow the inputs to stabilize
ENDR
    or $F0              ; Set the upper 4 bits, and leave the dpad state in the lower 4 bits

    swap a              ; Swap the high/low nibbles, putting the dpad state in the high nibble
    xor b               ; A now contains the pressed action buttons and dpad directions
    ld b, a             ; Move the key states to B

    ld a, JOYP_GET_NONE ; Load a flag into A to read nothing
    ldh [rJOYP], a      ; Write the flag to P1 to disable button reading

    ldh a, [hCurrentKeys] ; Load the previous button+dpad state from HRAM
    xor b               ; A now contains the keys that changed state
    and b               ; A now contains keys that were just pressed
    ld d, a             ; Store the newly pressed keys in D
    ld a, b             ; Move the current key state back to A
    ldh [hCurrentKeys], a ; Store the current key state in HRAM

.knownRet
    ret


SECTION "Current/Active Keys", HRAM

hCurrentKeys:: ds 1
hActiveKeys::  ds 1
