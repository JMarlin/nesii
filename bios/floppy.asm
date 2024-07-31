.segment "CODE"
.include "floppy.inc"
.include "bios.inc"
.include "globals.inc"


.global floppy_init
floppy_init:
;Initialize drive state values
    ldy #$00
    sty track
    sty cur_track
    sty sector
    sty cur_sector
;Reset controller switches
    lda #$60
    sta slot_index        ;keep this around
    tax
    lda iwm_q7_off        ;set to read mode
    lda iwm_q6_off
    lda iwm_select_drive_1   ;select drive 1
    lda iwm_motor_on      ;spin it up
; Blind-seek to track 0.
    ldy #80               ;80 phases (40 tracks)
seek_loop:
    lda iwm_ph0_off,x     ;turn phase N off
    tya
    and #$03              ;mod the phase number to get 0-3
    asl                   ;double it to 0/2/4/6
    ora slot_index        ;add in the slot index
    tax
    lda iwm_ph0_on,x      ;turn on phase 0, 1, 2, or 3
    lda #86
    jsr mon_wait          ;wait 19664 cycles
    dey                   ;next phase
    bpl seek_loop
    lda iwm_ph0_off 
    lda iwm_motor_off
    rts


.global floppy_on
floppy_on:
    lda iwm_motor_on
    rts


.global floppy_off
floppy_off:
    lda iwm_motor_off
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
    jsr read_sector
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
    lda     iwm_ph0_on,x      
    jsr     mon_wait      
    lda     iwm_ph0_off,x     
    inx
    inx
    txa
    and     #$F7
    tax
    lda     iwm_ph0_on,x
    jsr     mon_wait
    lda     iwm_ph0_off,x
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
    lda     iwm_ph0_on,x      
    jsr     mon_wait      
    lda     iwm_ph0_off,x     
    dex
    dex
    txa
    and     #$f7
    tax
    lda     iwm_ph0_on,x
    jsr     mon_wait
    lda     iwm_ph0_off,x
    dec     cur_track
step_back_done:
    rts


.GLOBAL read_sector
read_sector:
    clc
read_sector_c:
    php
    lda #$00
    sta r15
rdbyte1_start:
    inc r15
    beq read_sector_exit_fail_a
    ldx #$00
rdbyte1:
    inx
    beq read_sector_exit_fail_a
    lda iwm_q6_off
    bpl rdbyte1
check_d5:
    eor #$d5
    bne rdbyte1_start
    nop
rdbyte2_start:
    ldx #$00
rdbyte2:
    inx
    beq read_sector_exit_fail_a
    lda iwm_q6_off
    bpl rdbyte2
    cmp #$aa
    bne check_d5
    nop
    ldx #$00
rdbyte3:
    inx
    beq read_sector_exit_fail_a
    lda iwm_q6_off
    bpl rdbyte3
    cmp #$96
    beq found_address
    plp
    bcc read_sector
    eor #$ad
    beq found_data
    bne read_sector
read_sector_exit_fail_a:
    plp
read_sector_exit_fail:
    lda #$01
    sta r15
    rts
found_address:
    ldy #$03
hdr_loop:
    sta found_track
    nop
    ldx #$00
adr_hdr_rdbyte1:
    inx
    beq read_sector_exit_fail_a
    lda iwm_q6_off
    bpl adr_hdr_rdbyte1
    rol A
    sta bits
    nop
    nop
    ldx #$00
 adr_hdr_rdbyte2:
    inx
    beq read_sector_exit_fail_a
    lda iwm_q6_off
    bpl adr_hdr_rdbyte2
    and bits
    dey
    bne hdr_loop
    plp
    cmp sector
    bne read_sector
    lda found_track
    cmp track
    bne read_sector_exit_fail_a
    bcs read_sector_c
found_data:
    ldy #86
read_twos_loop:
    sty bits
    ldx #$00
dat_twos_rdbyte1:
    inx
    beq read_sector_exit_fail
    ldy iwm_q6_off 
    bpl dat_twos_rdbyte1
    eor conv_tab-128,y
    ldy bits
    dey
    sta twos_buffer,y
    nop
    nop
    nop 
    bne read_twos_loop
read_sixes_loop:
    sty bits
    ldx #$00
sixes_rdbyte2:
    inx
    beq read_sector_exit_fail
    ldy iwm_q6_off
    bpl sixes_rdbyte2
    eor conv_tab-128,y
    ldy bits
    sta (data_ptr),y
    iny
    nop
    nop
    bne read_sixes_loop
    ldx #$00
checksum_rdbyte3:
    inx 
    beq read_sector_exit_fail
    ldy iwm_q6_off
    bpl checksum_rdbyte3
    eor conv_tab-128,y
another:
    beq decode
    lda #$ea
    sta r14
    jmp read_sector_exit_fail
; 
; Decode the 6+2 encoding.  The high 6 bits of each byte are in place, now we
; just need to shift the low 2 bits of each in.
; 
decode:
    ldy     #$00    ;update 256 bytes
init_x:
    ldx     #86     ;run through the 2-bit pieces 3x (86*3=258)
decode_loop:
    dex
    bmi     init_x          ;if we hit $2ff, go back to $355
    lda     (data_ptr),y    ;foreach byte in the data buffer...
    lsr     twos_buffer,x   ; grab the low two bits from the stuff at $300-$355
    rol                     ; and roll them into the low two bits of the byte
    lsr     twos_buffer,x
    rol     A
    sta     (data_ptr),y
    iny
    bne     decode_loop
    lda #$00
    sta r15
    rts


conv_tab:
    .byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
    .byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
    .byte $ff,$ff,$ff,$ff,$ff,$ff,$00,$01
    .byte $ff,$ff,$02,$03,$ff,$04,$05,$06
    .byte $ff,$ff,$ff,$ff,$ff,$ff,$07,$08
    .byte $ff,$ff,$ff,$09,$0a,$0b,$0c,$0d
    .byte $ff,$ff,$0e,$0f,$10,$11,$12,$13
    .byte $ff,$14,$15,$16,$17,$18,$19,$1a
    .byte $ff,$ff,$ff,$ff,$ff,$ff,$ff,$ff
    .byte $ff,$ff,$ff,$1b,$ff,$1c,$1d,$1e
    .byte $ff,$ff,$ff,$1f,$ff,$ff,$20,$21
    .byte $ff,$22,$23,$24,$25,$26,$27,$28
    .byte $ff,$ff,$ff,$ff,$ff,$29,$2a,$2b
    .byte $ff,$2c,$2d,$2e,$2f,$30,$31,$32
    .byte $ff,$ff,$33,$34,$35,$36,$37,$38
    .byte $ff,$39,$3a,$3b,$3c,$3d,$3e,$3f


sector_skew_table:
    .byte $00, $0d, $0b, $09, $07, $05, $03, $01, $0e, $0c, $0a, $08, $06, $04, $02, $0f
