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

    ;Seek the floppy to the VTOC/Catalog track
    lda #$11
    jsr floppy_seek

    ;Test: seek it back to track 2
    lda #$02
    jsr floppy_seek

    ;Test: finally go forward to the VTOC
    lda #$11
    jsr floppy_seek

    ;Read the VTOC (track 0x11, sector 0x0) into a buffer for examination
    lda #$00
    sta data_ptr
    sta sector
    lda current_track
    sta track
    lda #$90
    sta data_ptr+1
    jsr read_sector

    ldx #$60
    lda IWM_MOTOR_OFF,X

    jmp ENTER_MONITOR

    rts