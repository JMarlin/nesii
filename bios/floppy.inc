.ifndef floppy_inc
    floppy_inc = 1

    .include "floppy_types.inc"

    .global floppy_init
    .global floppy_seek
    .global floppy_read
    .global floppy_on
    .global floppy_off
    .global floppy_sector_buffer_load
    .global floppy_step_forward
    .global floppy_step_back

    twos_buffer        = $0200   ;holds the 2-bit chunks
    boot1              = $0400   ;buffer for next stage of loader
    iwm_ph0_off        = $e080   ;stepper motor control
    iwm_ph0_on         = $e081   ;stepper motor control
    iwm_ph2_off        = $e084
    iwm_ph2_on         = $e085
    iwm_motor_on       = $e0e9   ;starts drive spinning
    iwm_motor_off      = $e0e8
    iwm_select_drive_1 = $e0ea   ;selects drive 1
    iwm_q6_off         = $e0ec   ;read
    iwm_q7_off         = $e0ee   ;WP sense/read
    cart_switches      = $f000
    data_ptr           = $26     ;pointer to BOOT1 data buffer
    slot_index         = $2b     ;slot number << 4
    bits               = $3c     ;temp storage for bit manipulation
    sector             = $3d     ;sector to read
    found_track        = $40     ;track found
    track              = $41     ;track to read
    cur_track          = $42
    cur_sector         = $43
.endif
