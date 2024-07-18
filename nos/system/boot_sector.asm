.segment "BOOT_SECTOR"
.include "../rom_constants.inc"
.include "../globals.inc"
.include "system_entry.inc"
.include "console.inc"
.include "../../startup_interface.inc"

boot_sector_start:

    ldy #$00
move_bootsect:
    lda $0400,Y
    sta $8000,Y
    iny
    bne move_bootsect

jmp $040E ;This is new_entry at the new location

new_entry:
    print message

load_boot_tracks:
    lda #$00
    sta data_ptr
    lda #$05
    sta data_ptr+1
get_next_boot_track:
    jsr load_next_sector
    inc data_ptr+1
    lda data_ptr+1
    cmp #$08
    bne get_next_boot_track

    jmp system_startup

message:
    .byte $0A, $0D
    .byte "LOADING NOS", $00
