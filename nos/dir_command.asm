.segment "CODE"
.include "floppy.inc"
.include "rom_constants.inc"

.global DIR_CMD_STR
DIR_CMD_STR: .asciiz "DIR"

.global DIR_CMD_ENTRY
DIR_CMD_ENTRY:

    ;Turn on the floppy
    ldx #$60
    lda IWM_MOTOR_ON,X

    ldx #$30
motor_wait:
    txa
    pha
    jsr monitor_wait
    pla
    tax
    dex
    bne motor_wait

    ;Read the VTOC (track 0x11, sector 0x0) into a buffer for examination
    lda #$00
    sta data_ptr
    lda #$90
    sta data_ptr+1
    ldx #$11
    lda #$00
    jsr floppy_read

dir_catalog_chain_next:
    ;Read the next catalog sector
    lda #$00
    sta data_ptr
    lda #$90
    sta data_ptr+1
    lda $9001
    beq dir_catalog_chain_done
    tax
    ldy $9002
    lda floppy_skew_table,Y
    jsr floppy_read

    lda #$0B
    sta data_ptr

    lda #$0A
    jsr PRNTCHR
    lda #$0D
    jsr PRNTCHR

dir_entry_show:
    ldy #$00
    lda (data_ptr),Y
    beq dir_entry_show_next

print_name:
    lda #$0A
    jsr PRNTCHR
    lda #$0D
    jsr PRNTCHR
    lda #$20
    jsr PRNTCHR
    lda #$20
    jsr PRNTCHR
    ldy #$03
print_name_next_char:
    tya
    pha
    lda (data_ptr),Y
    and #$7F
    jsr PRNTCHR
    pla
    cmp #$1A
    beq print_name_done
    tay
    iny
    bne print_name_next_char
print_name_done:

dir_entry_show_next:
    lda data_ptr
    clc
    adc #$23
    sta data_ptr
    bne dir_entry_show
    beq dir_catalog_chain_next

dir_catalog_chain_done:
    ldx #$60
    lda IWM_MOTOR_OFF,X

    rts

floppy_skew_table:
    .byte $00, $0d, $0b, $09, $07, $05, $03, $01, $0e, $0c, $0a, $08, $06, $04, $02, $0f