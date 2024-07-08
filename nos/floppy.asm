.segment "CODE"
.include "rom_constants.inc"

.global floppy_init
floppy_init:
    jsr floppy_off
    rts


.global floppy_motor_wait
floppy_motor_wait:
    ldx #$30
floppy_motor_wait_top:
    txa
    pha
    jsr monitor_wait
    pla
    tax
    dex
    bne floppy_motor_wait_top


.global floppy_on
floppy_on:
    ldx #$60
    lda iwm_motor_on,X
    rts


.global floppy_off
floppy_off:
    ldx #$60
    lda iwm_motor_off,X
    rts


;Expects track number in X, sector number in A
;data_ptr is the target it will read into
.global floppy_read
floppy_read:
    pha
    txa
    jsr floppy_seek
    tax
    sta track
    pla
    sta sector
    ldx #$60
    jsr read_sector
    rts


.global floppy_seek
floppy_seek:
    pha
floppy_seek_top:
    ;If we are already at the requested track, nothing to do
    pla
    cmp current_track
    pha
    beq floppy_seek_done
    bcc floppy_seek_step_back
    jsr step_forward
    clc
    bcc floppy_seek_top
floppy_seek_step_back:
    jsr step_back
    clc
    bcc floppy_seek_top

floppy_seek_done:
    pla
    rts

print_hex_byte:
    pha
    pha
    lsr
    lsr
    lsr
    lsr
    jsr print_hex_nybble
    pla
    and #$0F
    jsr print_hex_nybble
    pla
    rts

print_hex_nybble:
    pha
    adc #$30
    cmp #$3A
    bcc print_hex_nybble_done
    clc
    adc #$07
print_hex_nybble_done:
    jsr prints
    pla
    rts


step_forward:
    lda     current_track
    cmp     #$23
    beq     step_forward_done
    and     #$01
    asl     A
    asl     A
    ora     #$62
    tax
    lda     iwm_ph0_on,x      
    jsr     monitor_wait      
    lda     iwm_ph0_off,x     
    inx
    inx
    txa
    and     #$F7
    tax
    lda     iwm_ph0_on,x
    jsr     monitor_wait
    lda     iwm_ph0_off,x
    inc     current_track
step_forward_done:
    rts


step_back:
    lda     current_track
    beq     step_back_done
    and     #$01
    asl     
    asl     
    ora     #$60
    tax
    lda     iwm_ph0_on,x      
    jsr     monitor_wait      
    lda     iwm_ph0_off,x     
    dex
    dex
    txa
    and     #$f7
    tax
    lda     iwm_ph0_on,x
    jsr     monitor_wait
    lda     iwm_ph0_off,x
    dec     current_track
step_back_done:
    rts
