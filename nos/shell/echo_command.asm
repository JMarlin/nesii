.segment "CODE"
.include "../system/console.inc"

.global echo_cmd_str
echo_cmd_str: .byte "ECHO", $00

.global echo_cmd_entry
echo_cmd_entry:

    txa
    pha
    
    lda #$0a
    jsr console_printc
    lda #$0d
    jsr console_printc

    pla
    sta string_pointer
    lda #>text_buffer
    sta string_pointer+1
    jsr console_prints

    rts