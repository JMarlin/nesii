.segment "BOOT_INIT"

CART_SWITCHES    = $d000
INITKEYBOARD     = $f427
LOAD_NEXT_SECTOR = $e27f
IWM_MOTOR_OFF    = $c088
ENTER_MONITOR    = $f2e5
PRINTSTR         = $f4f7
GETKEY           = $f441
STRING_PTR       = $03
data_ptr         = $26

boot_sector_start:

ldy #$00
move_bootsect:
    lda $0400,Y
    sta $8000,Y
    iny
    bne move_bootsect

jmp $800E ;This is new_entry at the new location

new_entry:
    lda #<MESSAGE
    sta STRING_PTR
    lda #>MESSAGE
    sta STRING_PTR+1
    jsr PRINTSTR

load_boot_tracks:
    lda #$00
    sta data_ptr
    lda #$81
    sta data_ptr+1
get_next_boot_track:
    jsr LOAD_NEXT_SECTOR
    inc data_ptr+1
    lda data_ptr+1
    cmp #$90
    bne get_next_boot_track

    jmp boot_tracks_start

MESSAGE:
    .byte $0A, $0D
    .byte "READING NOS DATA..."
    .byte $00

.segment "BOOT_CODE"

boot_tracks_start:

    lda IWM_MOTOR_OFF

    jsr INITKEYBOARD

    lda #<MESSAGE_2
    sta STRING_PTR
    lda #>MESSAGE_2
    sta STRING_PTR+1
    jsr PRINTSTR

    jmp ENTER_MONITOR

MESSAGE_2:
    .byte $0A, $0D
    .byte "DONE"
    .byte $0A, $0D
    .byte "WELCOME TO NOS 0.0.1"
    .byte $0A, $0D, $00
