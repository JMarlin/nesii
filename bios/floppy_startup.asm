.segment "CODE"
.include "floppy.inc"
.include "bios.inc"

;IMPORTANT NOTE: When making the disk image for this, you'll have to skew the sector data
;                in DOS 3.3 format, because apparently ADT skews them when copying onto the disk
system_startup:
.global system_startup

    ;Read boot sector into NES RAM (ultimately, that's where the rest of this code should go too)
    jsr load_boot_sector
    jmp boot1+1

    rts
