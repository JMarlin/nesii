.segment "BOOT_SECTOR"
.include "../rom_constants.inc"
.include "../globals.inc"
.include "system_entry.inc"
.include "console.inc"
.include "../../bios/startup_interface.inc"

boot_sector_start:
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
    .byte "NOS", $00
