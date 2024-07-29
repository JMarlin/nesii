.segment "CODE"
.include "../../system/console.inc"

tron_entry:
    print tron_message
    rts

tron_message:
    .byte $0a, $0d, "HI FROM TRON", $00