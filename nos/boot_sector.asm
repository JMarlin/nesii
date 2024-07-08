.segment "BOOT_SECTOR"
.include "rom_constants.inc"
.include "globals.inc"
.include "command_processor.inc"
.include "../startup_interface.inc"
.include "floppy.inc"

boot_sector_start:

    ldy #$00
move_bootsect:
    lda $0400,Y
    sta $8000,Y
    iny
    bne move_bootsect

jmp $800E ;This is new_entry at the new location

new_entry:
    lda #<message
    sta string_ptr
    lda #>message
    sta string_ptr+1
    jsr prints

load_boot_tracks:
    lda #$00
    sta data_ptr
    lda #$81
    sta data_ptr+1
get_next_boot_track:
    jsr load_next_sector
    inc data_ptr+1
    lda data_ptr+1
    cmp #$90
    bne get_next_boot_track

    jmp system_startup

message:
    .byte $0A, $0D
    .byte "READING NOS DATA...", $00
