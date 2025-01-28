STACK           = $0100  
TWOS_BUFFER     = $0200    ;holds the 2-bit chunks
BOOT1           = $0400   ;buffer for next stage of loader
IWM_PH0_OFF     = $e080             ;stepper motor control
IWM_PH0_ON      = $e081             ;stepper motor control
IWM_PH2_OFF     = $e084
IWM_PH2_ON      = $e085
IWM_MOTOR_ON    = $e0e9             ;starts drive spinning
IWM_MOTOR_OFF   = $e0e8
IWM_SEL_DRIVE_1 = $e0ea             ;selects drive 1
IWM_Q6_OFF      = $e0ec             ;read
IWM_Q7_OFF      = $e0ee             ;WP sense/read

CART_SWITCHES   = $f000

data_ptr        = $26       ;pointer to BOOT1 data buffer
slot_index      = $2b       ;slot number << 4
bits            = $3c       ;temp storage for bit manipulation
sector          = $3d       ;sector to read
found_track     = $40       ;track found
track           = $41       ;track to read
cur_track  = $42
cur_sector = $43

.global load_boot_sector
.global init
