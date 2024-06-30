.segment "CODE"
.include "rom_constants.inc"

.global HELLO_CMD_STR
HELLO_CMD_STR: .asciiz "HELLO"

.global HELLO_CMD_ENTRY
HELLO_CMD_ENTRY:

    lda #<HI_MESSAGE
    sta STRING_PTR
    lda #>HI_MESSAGE
    sta STRING_PTR+1
    jsr PRINTSTR

    rts

HI_MESSAGE:
    .byte $0A, $0D, "HI TO YOU!", $00

