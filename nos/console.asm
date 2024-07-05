.segment "CODE"
.include "rom_constants.inc"


.global console_init
console_init:
    jsr INITKEYBOARD
    rts


.global console_prints
console_prints:
    jsr PRINTSTR
    rts


.global console_printc
console_printc:
    jsr PRNTCHR
    rts


.global console_getc
console_getc:
    jsr GETKEY
    rts
