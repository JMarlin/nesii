STACK           = $0100  
TWOS_BUFFER     = $0200    ;holds the 2-bit chunks
BOOT1           = $0300   ;buffer for next stage of loader
IWM_PH0_OFF     = $c080             ;stepper motor control
IWM_PH0_ON      = $c081             ;stepper motor control
IWM_PH2_OFF     = $c084
IWM_PH2_ON      = $c085
IWM_MOTOR_ON    = $c089             ;starts drive spinning
IWM_MOTOR_OFF   = $c088
IWM_SEL_DRIVE_1 = $c08a             ;selects drive 1
IWM_Q6_OFF      = $c08c             ;read
IWM_Q7_OFF      = $c08e             ;WP sense/read

CART_SWITCHES   = $d000

data_ptr        = $26       ;pointer to BOOT1 data buffer
slot_index      = $2b       ;slot number << 4
bits            = $3c       ;temp storage for bit manipulation
sector          = $3d       ;sector to read
found_track     = $40       ;track found
track           = $41       ;track to read
cur_track  = $42
cur_sector = $43

.global load_boot_sector
