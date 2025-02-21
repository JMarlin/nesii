.segment "CODE"
.include "rom_floppy_constants.inc"
.include "globals.inc"
.global MON_WAIT
.global ReadSector

.global floppy_init
floppy_init:
    jsr floppy_off
    rts


.global floppy_on
floppy_on:
    lda IWM_MOTOR_ON
    rts


.global floppy_off
floppy_off:
    lda IWM_MOTOR_OFF
    rts


;Expects track number in X, sector number in A
;data_ptr is the target it will read into
.global floppy_read 
floppy_read:
    pha
    jsr floppy_on
    txa 
    jsr floppy_seek
    sta track
    pla
    tay
    lda sector_skew_table,y
    sta sector
;Stash clobbered registers
    lda r0
    pha
    lda #$00
    sta r0
floppy_read_retry:
    inc r0
    beq floppy_read_exit
    jsr ReadSector
    lda r15
    bne floppy_read_retry
floppy_read_exit:
    jsr floppy_off
;Restore clobbered register
    pla
    sta r0
    rts


.global floppy_seek
floppy_seek:
    pha
floppy_seek_top:
    ;If we are already at the requested track, nothing to do
    pla
    cmp cur_track
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
    lda     cur_track
    cmp     #$23
    beq     step_forward_done
    and     #$01
    asl     A
    asl     A
    ora     #$62
    tax
    lda     IWM_PH0_ON,x      
    jsr     MON_WAIT      
    lda     IWM_PH0_OFF,x     
    inx
    inx
    txa
    and     #$F7
    tax
    lda     IWM_PH0_ON,x
    jsr     MON_WAIT
    lda     IWM_PH0_OFF,x
    inc     cur_track
step_forward_done:
    rts


step_back:
    lda     cur_track
    beq     step_back_done
    and     #$01
    asl     
    asl     
    ora     #$60
    tax
    lda     IWM_PH0_ON,x      
    jsr     MON_WAIT      
    lda     IWM_PH0_OFF,x     
    dex
    dex
    txa
    and     #$f7
    tax
    lda     IWM_PH0_ON,x
    jsr     MON_WAIT
    lda     IWM_PH0_OFF,x
    dec     cur_track
step_back_done:
    rts

sector_skew_table:
    .byte $00, $0d, $0b, $09, $07, $05, $03, $01, $0e, $0c, $0a, $08, $06, $04, $02, $0f
