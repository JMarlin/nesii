.segment "CODE"
.include "rom_constants.inc"

.global floppy_init
floppy_init:
    ldx #$60
    lda IWM_MOTOR_OFF,X
    rts

.global floppy_seek
floppy_seek:

    ;If we are already at the requested track, nothing to do
    cmp current_track
    beq floppy_seek_done

    ;Step the head forward until the current track is the requested track
    ;TODO: handle backward stepping as well
    pha
    jsr step_forward
    pla
    clc
    bcc floppy_seek

floppy_seek_done:
    rts


step_forward:
    lda     current_track
    and     #$01
    asl     A
    asl     A
    ora     #$62
    tax
    lda     IWM_PH0_ON,x      ;turn on phase 0, 1, 2, or 3
    lda     #86
    jsr     monitor_wait      ;wait 19664 cycles
    lda     IWM_PH0_OFF,x     ;turn phase N off
    inx
    inx
    txa
    and     #$F7
    tax
    lda     IWM_PH0_ON,x
    lda     #86
    jsr     monitor_wait
    lda     IWM_PH0_OFF,x
    inc     current_track
    rts
