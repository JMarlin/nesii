.segment "CODE"
.include "rom_constants.inc"

.global hello_cmd_str
hello_cmd_str: .asciiz "HELLO"

.global hello_cmd_entry
hello_cmd_entry:

    lda #<hi_message
    sta string_ptr
    lda #>hi_message
    sta string_ptr+1
    jsr prints

    rts

hi_message:
    .byte $0a, $0d, "HI TO YOU!", $00

