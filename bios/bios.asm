.segment "CODE"
.include "char_io.inc"
.include "monitor.inc"
.include "rom_floppy_constants.inc"
.include "startup_interface.inc"
.include "floppy.inc"
.include "globals.inc"

;I should probably make a note here, since I cleaned up the sources a bunch,
;that this file is an absolute mess and should be broken up
;If you're wondering why, it's because this file was the origin of the
;whole codebase and as such doesn't really serve much purposes now
;aside from being the entry point and a general bucket of old but critical stuff

ENTRY:
;Turn off interrupts and decimal mode
    SEI
    CLD
    LDX #$FF
    TXS

;Initialize PPU state (disable interrupts and rendering)
    LDA #$00
    STA $2000
    STA $2001

;Wait for three vblanks (let PPU state settle?)
    BIT $2002
ppu_vblank_wait1:
    BIT $2002
    BPL ppu_vblank_wait1

    BIT $2002
ppu_vblank_wait2:
    BIT $2002
    BPL ppu_vblank_wait2

    BIT $2002
ppu_vblank_wait3:
    BIT $2002
    BPL ppu_vblank_wait3

;Wait for a vblank
:
    BIT $2002
    BPL :-

;Run the BIOS out of RAM to allow for BIOS updates
;Copy ourself from E000-FFFF to A000-BFFF
lda #$00
sta r0
sta r2
lda #$e0
sta r3
lda #$a0
sta r1
ldy #$00
copy_next_bios_byte:
lda (r2),y
sta (r0),y
inc r2
inc r0
bne copy_next_bios_byte
inc r3
inc r1
lda r1
cmp #$c0
bne copy_next_bios_byte
;Switch to all-RAM mapping
;No need for jumping to any kind of stub code, we should read the exact same thing out of RAM
;after the mapping switch that we would have run out of ROM if the copy happened correctly
lda #$02
sta $d000

RAWF=139

init_apu:
        ; Init $4000-4013
        ldy #$13
@loop:  lda regs,y
        sta $4000,y
        dey
        bpl @loop
 
        ; We have to skip over $4014 (OAMDMA)
        lda #$0f
        sta $4015
        lda #$40
        sta $4017


        lda #<RAWF
        sta $4002
        lda #>RAWF
        sta $4003
        lda #%10111111
        sta $4000

;Set background palette values
;Universal background = black
    LDA #$3F
    STA $2006
    LDA #$00
    STA $2006
    LDA #$20
    STA $2007

    LDA #$3F
    STA $2006
    LDA #$01
    STA $2006
    LDA #$20
    STA $2007

    LDA #$3F
    STA $2006
    LDA #$02
    STA $2006
    LDA #$1D
    STA $2007
    
    LDA #$3F
    STA $2006
    LDA #$03
    STA $2006
    LDA #$1D
    STA $2007

;Fill attribute tables to all be palette zero
    LDX #128
WRITE_ATTR_TOP:
    LDA #$23
    STA $2006
    TXA
    CLC
    ADC #$BF
    STA $2006
    LDA #$00
    STA $2007
    DEX
    BNE WRITE_ATTR_TOP

;Wait for VBLANK
:
    BIT $2002
    BPL :-

;Fill the screen with blank tiles
    LDA #$20
    STA $2006
    LDA #$00
    STA $2006
    LDX #$3C
    LDA #$3F
:
    STA $2007
    STA $2007
    STA $2007
    STA $2007
    STA $2007
    STA $2007
    STA $2007
    STA $2007
    STA $2007
    STA $2007
    STA $2007
    STA $2007
    STA $2007
    STA $2007
    STA $2007
    STA $2007
    DEX
    BNE :-

;Load tileset into pattern RAM
.GLOBAL CHAR_TILES
TILE_PTR=$FE
    LDA #<CHAR_TILES
    STA TILE_PTR
    LDA #>CHAR_TILES
    STA TILE_PTR+1

    LDY #0
    STY $2001
    STY $2006
    STY $2006
    LDX #4

TILE_LOAD_LOOP:
    LDA (TILE_PTR),Y
    STA $2007
    INY
    BNE TILE_LOAD_LOOP
    INC TILE_PTR+1
    DEX
    BNE TILE_LOAD_LOOP

;Set scroll to 0, 0
    LDA #$00
    STA $2005
    STA $2005
    STA SCROLL_VALUE

;Initialize print location to 1,1 on the playfield
    LDA #$21
    STA SCREEN_ADDR
    LDA #$20
    STA SCREEN_ADDR+1

;When we first start, we do not yet need to scroll
    LDA #$00
    STA IS_SCROLLING

;Enable rendering
    LDA #$0E
    STA $2001

    LDA #$00
    STA $4000

lda #<BOOT_MSG
sta $03
lda #>BOOT_MSG
sta $04
jsr PRINTSTR

;Specify load from track 0, sector 0
lda #$00
sta track
sta sector

ldx     #$60
lda     IWM_Q7_OFF,x
lda     IWM_Q6_OFF,x
lda     IWM_SEL_DRIVE_1,x
lda     IWM_MOTOR_ON,x

    ldy     #$00
    sty track
    sty sector

    lda #$60
    sta     slot_index        ;keep this around
    tax
    lda     IWM_Q7_OFF,x      ;set to read mode
    lda     IWM_Q6_OFF,x
    lda     IWM_SEL_DRIVE_1,x ;select drive 1
    lda     IWM_MOTOR_ON,x    ;spin it up

; 
; Blind-seek to track 0.
; 
    ldy     #80               ;80 phases (40 tracks)
seek_loop:
    lda     IWM_PH0_OFF,x     ;turn phase N off
    tya
    and     #$03              ;mod the phase number to get 0-3
    asl     A                 ;double it to 0/2/4/6
    ora     slot_index        ;add in the slot index
    tax
    lda     IWM_PH0_ON,x      ;turn on phase 0, 1, 2, or 3
    lda     #86
    jsr     MON_WAIT          ;wait 19664 cycles
    dey                       ;next phase
    bpl     seek_loop
    lda     IWM_PH0_OFF

    ;Now that we know the drive is initialized, reflect that in the status vars
    lda #$00
    sta cur_sector
    sta cur_track

    jsr system_startup
    jmp init

ReadSector:   clc
.GLOBAL ReadSector
ReadSector_C: php
              lda #$00
              sta r15
rdbyte1_start:
              inc r15
              beq ReadSector_exit_fail_a
              ldx #$00
rdbyte1:      inx
              beq ReadSector_exit_fail_a
b:            lda IWM_Q6_OFF
              bpl rdbyte1
check_d5:     eor #$d5
              bne rdbyte1_start
              nop
rdbyte2_start: ldx #$00
rdbyte2:      inx
              beq ReadSector_exit_fail_a
c:            lda IWM_Q6_OFF
              bpl rdbyte2
              cmp #$aa
              bne check_d5
              nop
              ldx #$00
rdbyte3:      inx
              beq ReadSector_exit_fail_a
d:            lda IWM_Q6_OFF
              bpl rdbyte3
              cmp #$96
              beq FoundAddress
              plp
              bcc ReadSector
              eor #$ad
              beq FoundData
              bne ReadSector
ReadSector_exit_fail_a:
    plp
ReadSector_exit_fail:
    lda #$01
    sta r15
    rts
FoundAddress:
    ldy #$03
hdr_loop:
    sta found_track
    nop
    ldx #$00
adr_hdr_rdbyte1:
    inx
    beq ReadSector_exit_fail_a
e:  lda IWM_Q6_OFF
    bpl adr_hdr_rdbyte1
    rol A
    sta bits
    nop
    nop
    ldx #$00
 adr_hdr_rdbyte2:
    inx
    beq ReadSector_exit_fail_a
j:  lda IWM_Q6_OFF
    bpl adr_hdr_rdbyte2
    and bits
    dey
    bne hdr_loop
    plp
    cmp sector
    bne ReadSector ;TODO: only retry this ~32 times -- after that, we know we've failed to find the sector
    lda found_track
    cmp track
    bne ReadSector_exit_fail_a
    bcs ReadSector_C

FoundData:
    ldy #86
read_twos_loop:
    sty bits
    ldx #$00
dat_twos_rdbyte1:
    inx
    beq ReadSector_exit_fail
g:  ldy IWM_Q6_OFF 
    bpl dat_twos_rdbyte1
    eor conv_tab-128,y
    ldy bits
    dey
    sta TWOS_BUFFER,y
    nop
    nop
    nop 
    bne read_twos_loop

read_sixes_loop:
    sty bits
    ldx #$00
sixes_rdbyte2:
    inx
    beq ReadSector_exit_fail
h:  ldy IWM_Q6_OFF
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
    beq ReadSector_exit_fail
i:  ldy IWM_Q6_OFF
    bpl checksum_rdbyte3
    eor conv_tab-128,y
another:
    beq Decode
    lda #$ea
    sta r14
    jmp ReadSector_exit_fail

; 
; Decode the 6+2 encoding.  The high 6 bits of each byte are in place, now we
; just need to shift the low 2 bits of each in.
; 
Decode:
    ldy     #$00              ;update 256 bytes
init_x:
    ldx     #86               ;run through the 2-bit pieces 3x (86*3=258)
decode_loop:
    dex
    bmi     init_x           ;if we hit $2ff, go back to $355
    lda     (data_ptr),y      ;foreach byte in the data buffer...
    lsr     TWOS_BUFFER,x     ; grab the low two bits from the stuff at $300-$355
    rol     A                 ; and roll them into the low two bits of the byte
    lsr     TWOS_BUFFER,x
    rol     A
    sta     (data_ptr),y
    iny
    bne     decode_loop

    lda #$00
    sta r15
    rts

.global MON_WAIT
MON_WAIT:
    lda #$f0
    sta $da
wait_loop_b:
    lda #$00
    sta $db
wait_loop_a:
    inc $db
    bne wait_loop_a
    inc $da
    bne wait_loop_b
    rts

;NOTE: When the drive is initialized, we are aligned with phase-0
;      Therefore, we need to step to the next ODD numbered step FIRST
step_track:
    lda     cur_track
    and     #$01
    asl     A
    asl     A
    ora     #$62
    tax
    lda     IWM_PH0_ON,x      ;turn on phase 0, 1, 2, or 3
    lda     #86
    jsr     MON_WAIT          ;wait 19664 cycles
    lda     IWM_PH0_OFF,x     ;turn phase N off
    inx
    inx
    txa
    and     #$F7
    tax
    lda     IWM_PH0_ON,x
    lda     #86
    jsr     MON_WAIT
    lda     IWM_PH0_OFF,x
    inc     cur_track
    rts

load_next_sector:
.GLOBAL load_next_sector
    lda     cur_sector
    ldx     cur_track
    jsr     floppy_read
    lda r15
    bne next_sector_done
    inc     cur_sector
    lda     cur_sector
    cmp     #$10
    bne     next_sector_done
    lda     #$00
    sta     cur_sector
    jsr     step_track
next_sector_done:
    rts

.global load_boot_sector
load_boot_sector:
    lda     #$00
    sta     data_ptr          ;Store page-aligned
    lda     #>BOOT1           ;Target is the NES RAM boot area
    sta     data_ptr+1
    jsr     load_next_sector
    lda r15
    beq load_boot_sector_exit
    jsr floppy_off
    lda #<READ_ERROR_MSG
    sta string_ptr
    lda #>READ_ERROR_MSG
    sta string_ptr+1
    jsr PRINTSTR
    jmp init
load_boot_sector_exit:
    rts
    
BOOT_MSG:
    .ASCIIZ "LOADING..."

READ_ERROR_MSG:
    .ASCIIZ "READ ERROR"

IRQ_BRK_HANDLE:
    RTI
   
regs:
    .byte $30,$08,$00,$00
    .byte $30,$08,$00,$00
    .byte $80,$00,$00,$00
    .byte $30,$00,$00,$00
    .byte $00,$00,$00,$00

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

CHAR_TILES:
    .incbin "blob/font.chr"

.segment "CALL_TABLE"
jsr PRINTSTR         ;FFC0
rts
jsr PRNTCHR          ;FFC4
rts
jsr INITKEYBOARD     ;FFC8 
rts
jsr load_next_sector ;FFCC
rts
jmp init             ;FFD0
rts
jsr ReadSector       ;FFD4
rts
jsr MON_WAIT         ;FFD8
rts
jsr GETKEY           ;FFDC
rts
jsr floppy_read     ;FFE0
rts
jsr floppy_init     ;FFE4
rts
jsr floppy_off      ;FFE8
rts
jsr floppy_on       ;FFEC
rts
.byte "NES" ;FFF0

.segment "VECTORS"
.word $0000
.word ENTRY
.word IRQ_BRK_HANDLE

