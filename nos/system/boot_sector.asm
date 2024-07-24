.segment "BOOT_SECTOR"
.include "../rom_constants.inc"
.include "../globals.inc"
.include "system_entry.inc"
.include "console.inc"
.include "../../bios/startup_interface.inc"

basic_cold_start = $e000
apple_ii_cout = $fded 
apple_ii_cr = $fd8e
apple_ii_message_address = apple_ii_message_string + $400 ;NES loads at $400, but Apple II loads at $800 

.byte $01 ;To match apple ][ layout

boot_sector_start:
    lda $fff0
    cmp #'N'
    bne apple_ii_message
    lda $fff1
    cmp #'E'
    bne apple_ii_message
    lda $fff2
    cmp #'S'
    bne apple_ii_message

    print nos_message_string

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

apple_ii_message:
    ;Move cursor down one line
    jsr apple_ii_cr
    ldy #$00
apple_ii_message_loop:
    lda apple_ii_message_address,y
    beq apple_ii_enter_cold_start
    jsr apple_ii_cout
    iny
    clc
    bcc apple_ii_message_loop
apple_ii_enter_cold_start:
    lda #$60
    lda iwm_motor_off,x
    jmp basic_cold_start

nos_message_string:
    .byte "NOS", $00

apple_ii_message_string:
    .byte 'T'+$80, 'H'+$80, 'I'+$80, 'S'+$80, ' '+$80, 'I'+$80, 'S'+$80, ' '+$80, 'A'+$80,  'N'+$80,  ' '+$80,  'N'+$80,  'E'+$80,  'S'+$80,  ' '+$80,  'D'+$80,  'I'+$80,  'S'+$80,  'K'+$80, $00


