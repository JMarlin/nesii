.segment "CODE"
.include "rom_constants.inc"

.global floppy_init
floppy_init:
    ldx #$60
    lda IWM_MOTOR_OFF,X
    rts

.global floppy_seek
floppy_seek:
    pha
floppy_seek_top:

    ;If we are already at the requested track, nothing to do
    pla
    cmp current_track
    beq floppy_seek_done
    bcc floppy_seek_step_forward
    jsr step_back
    clc
    bcc floppy_seek_continue
floppy_seek_step_forward:
    jsr step_forward
floppy_seek_continue:
    pha
    clc
    bcc floppy_seek

floppy_seek_done:
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
    lda     IWM_PH0_ON,x      
    jsr     monitor_wait      
    lda     IWM_PH0_OFF,x     
    inx
    inx
    txa
    and     #$F7
    tax
    lda     IWM_PH0_ON,x
    jsr     monitor_wait
    lda     IWM_PH0_OFF,x
    inc     current_track
step_forward_done:
    rts


step_back:
    lda     current_track
    beq     step_back_done
    and     #$01
    asl     A
    asl     A
    ora     #$60
    tax
    lda     IWM_PH0_ON,x      
    jsr     monitor_wait      
    lda     IWM_PH0_OFF,x     
    dex
    dex
    txa
    and     #$F7
    tax
    lda     IWM_PH0_ON,x
    jsr     monitor_wait
    lda     IWM_PH0_OFF,x
    dec     current_track
step_back_done:
    rts
