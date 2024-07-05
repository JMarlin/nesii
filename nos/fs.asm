.segment "CODE"
.include "floppy.inc"


.global fs_start_listing
fs_start_listing:

    jsr floppy_on
    jsr floppy_motor_wait

    rts

;HERE - in progress
;       my general goal is to pass some kind of
;       value back to the caller that can be used
;       to resume iterating the entries

    ;Read the VTOC (track 0x11, sector 0x0) into a buffer for examination
    lda #$00
    sta floppy_data_ptr
    lda #$90
    sta floppy_data_ptr+1
    ldx #$11
    lda #$00
    jsr floppy_read

dir_catalog_chain_next:
    ;Read the next catalog sector
    lda #$00
    sta floppy_data_ptr
    lda #$90
    sta floppy_data_ptr+1
    lda $9001
    beq dir_catalog_chain_done
    tax
    ldy $9002
    lda sector_skew_table,Y
    jsr floppy_read

    lda #$0B
    sta floppy_data_ptr

dir_entry_show:
    ldy #$00
    lda (floppy_data_ptr),Y
    beq dir_entry_show_next

print_name:
    lda #$0A
    jsr console_printc
    lda #$0D
    jsr console_printc
    lda #$20
    jsr console_printc
    lda #$20
    jsr console_printc
    ldy #$03
print_name_next_char:
    tya
    pha
    lda (floppy_data_ptr),Y
    and #$7F
    jsr console_printc
    pla
    cmp #$1A
    beq print_name_done
    tay
    iny
    bne print_name_next_char
print_name_done:

dir_entry_show_next:
    lda floppy_data_ptr
    clc
    adc #$23
    sta floppy_data_ptr
    bne dir_entry_show
    beq dir_catalog_chain_next

dir_catalog_chain_done:
    jsr floppy_off

    rts

sector_skew_table:
    .byte $00, $0d, $0b, $09, $07, $05, $03, $01, $0e, $0c, $0a, $08, $06, $04, $02, $0f