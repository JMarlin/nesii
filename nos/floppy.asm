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


step_forward:

;TESTING
    lda #<FORWARD_MESSAGE
    sta STRING_PTR
    lda #>FORWARD_MESSAGE
    sta STRING_PTR+1
    jsr PRINTSTR

    inc current_track

    rts
;TESTING

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

;TESTING
    lda #<BACK_MESSAGE
    sta STRING_PTR
    lda #>BACK_MESSAGE
    sta STRING_PTR+1
    jsr PRINTSTR

    dec current_track

    rts
;TESTING

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

FORWARD_MESSAGE:
    .byte "STEPPING FORWARD", $0A, $0D, $00

BACK_MESSAGE:
    .byte "STEPPING BACK", $0A, $0D, $00
