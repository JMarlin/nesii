.ifndef calls_inc
    calls_inc = 1

    bios_prints            = $ffc0
    bios_printc            = $ffc4
    bios_init_keyboard     = $ffc8
    bios_load_next_sector  = $ffcc
    bios_enter_monitor     = $ffd0
    bios_read_sector       = $ffd4
    bios_monitor_wait      = $ffd8
    bios_getc              = $ffdc
    bios_floppy_sector_buffer_load = $ffe0
    bios_floppy_init       = $ffe4
    bios_floppy_off        = $ffe8
    bios_floppy_on         = $ffec
.endif