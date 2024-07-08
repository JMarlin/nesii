.include "rom_constants.inc"
.include "globals.inc"

console_init   = init_keyboard
console_prints = prints
console_printc = printc
console_getc   = getc

.macro print pointer
    lda #<pointer
    sta string_ptr
    lda #>pointer
    sta string_ptr+1
    jsr prints
.endmacro