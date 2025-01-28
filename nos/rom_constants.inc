.ifndef rom_constants_inc
    rom_constants_inc = 1

    prints            = $ffc0
    printc            = $ffc4
    init_keyboard     = $ffc8
    load_next_sector  = $ffcc
    enter_monitor     = $ffd0
    read_sector       = $ffd4
    monitor_wait      = $ffd8
    getc              = $ffdc
    floppy_read       = $ffe0
    floppy_init       = $ffe4
    floppy_off        = $ffe8
    floppy_on         = $ffec

    cart_switches    = $f000
    iwm_ph0_off      = $e080
    iwm_ph0_on       = $e081
    iwm_ph2_off      = $e084
    iwm_ph2_on       = $e085
    iwm_motor_on     = $e089
    iwm_motor_off    = $e088
    iwm_sel_drive_1  = $e08a
    iwm_q6_off       = $e08c
    iwm_q7_off       = $e08e
.endif
