.segment "CODE"
.include "../system/console.inc"

.global hello_cmd_str
hello_cmd_str: .byte "HELLO", $00

.global hello_cmd_entry
hello_cmd_entry:

    print hi_message

    rts

hi_message:
    .byte $0a, $0d, "HI TO YOU!", $00

