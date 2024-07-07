.segment "CODE"
.include "console.inc"

.global ECHO_CMD_STR
ECHO_CMD_STR: .asciiz "ECHO"

.global ECHO_CMD_ENTRY
ECHO_CMD_ENTRY:

    txa
    pha
    
    lda #$0A
    jsr console_printc
    lda #$0D
    jsr console_printc

    pla
    sta STRING_PTR
    lda #>TEXT_BUFFER
    sta STRING_PTR+1
    jsr console_prints

    rts