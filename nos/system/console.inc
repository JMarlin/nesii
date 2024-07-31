.ifndef console_inc
    console_inc = 1

    .include "../../bios/globals.inc"
    .include "../../bios/calls.inc"

    string_pointer = $03

    console_init   = bios_init_keyboard
    console_prints = bios_prints
    console_printc = bios_printc
    console_getc   = bios_getc

    .global print_hex_byte
    .global print_hex_nybble

    .macro print pointer
        lda #<pointer
        sta string_pointer
        lda #>pointer
        sta string_pointer+1
        jsr bios_prints
    .endmacro
.endif