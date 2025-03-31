.ifndef console_inc
    console_inc = 1

    .include "../rom_constants.inc"
    .include "../globals.inc"

    text_buffer = $0200 ;64-byte buffer for incoming command

    console_init   = init_keyboard
    console_prints = prints
    console_printc = printc
    console_getc   = getc

    .global print_hex_byte
    .global print_hex_nybble

    .macro print pointer
        lda #<pointer
        sta string_ptr
        lda #>pointer
        sta string_ptr+1
        jsr prints
    .endmacro
.endif
