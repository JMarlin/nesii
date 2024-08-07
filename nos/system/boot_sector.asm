.segment "BOOT_SECTOR"
.include "console.inc"
.include "../../bios/startup_interface.inc"
.include "../../bios/floppy_types.inc"
.include "appleii.inc"

apple_ii_message_address = (apple_ii_message_string - *) + $800  ;Recalculate the Apple II address based on offset, AII loads at $800 
nos_message_address = (nos_message_string - *) + $400 ;Recalculate the message string since the boot sector is actually loaded at $400

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

    print nos_message_address

load_boot_tracks:
    lda #$60
    sta global_bios_sector_buffer + fsb_buffer_page_offset
get_next_boot_track:
    jsr bios_load_next_sector
    inc global_bios_sector_buffer + fsb_buffer_page_offset
    lda global_bios_sector_buffer + fsb_buffer_page_offset
    cmp #$70
    bne get_next_boot_track
;Make sure we restore the global bios sector buffer address
    lda #$04
    sta global_bios_sector_buffer + fsb_buffer_page_offset
;Launch into the loaded NOS image
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
    lda #$60 ;TODO: Can't just assume slot 6, come on
    lda apple_ii_iwm_motor_off,x
    jmp apple_ii_basic_cold_start

nos_message_string:
    .byte "NOS", $00

apple_ii_message_string:
    .byte 'T'+$80, 'H'+$80, 'I'+$80, 'S'+$80, ' '+$80, 'I'+$80, 'S'+$80, ' '+$80, 'A'+$80,  'N'+$80,  ' '+$80,  'N'+$80,  'E'+$80,  'S'+$80,  ' '+$80,  'D'+$80,  'I'+$80,  'S'+$80,  'K'+$80, $00


