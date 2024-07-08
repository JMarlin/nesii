.segment "CODE"
.include "console.inc"

.global echo_cmd_str
echo_cmd_str: .asciiz "ECHO"

.global echo_cmd_entry
echo_cmd_entry:

    txa
    pha
    
    lda #$0a
    jsr console_printc
    lda #$0d
    jsr console_printc

    pla
    sta string_ptr
    lda #>text_buffer
    sta string_ptr+1
    jsr console_prints

    rts