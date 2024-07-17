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
    floppy_motor_wait = $fff0

    cart_switches    = $d000
    iwm_ph0_off      = $c080
    iwm_ph0_on       = $c081
    iwm_ph2_off      = $c084
    iwm_ph2_on       = $c085
    iwm_motor_on     = $c089
    iwm_motor_off    = $c088
    iwm_sel_drive_1  = $c08a
    iwm_q6_off       = $c08c
    iwm_q7_off       = $c08e
.endif