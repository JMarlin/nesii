.include "console.inc"

;.global print_hex_byte
;print_hex_byte:
;    pha
;    pha
;    lsr
;    lsr
;    lsr
;    lsr
;    jsr print_hex_nybble
;    pla
;    and #$0F
;    jsr print_hex_nybble
;    pla
;    rts

;.global print_hex_nybble
;print_hex_nybble:
;    pha
;    clc
;    adc #$30
;    cmp #$3A
;    bcc print_hex_nybble_done
;    clc
;    adc #$07
;print_hex_nybble_done:
;    jsr console_printc
;    pla
;    rts
