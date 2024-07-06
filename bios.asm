.segment "CODE"
.include "char_io.inc"
.include "monitor.inc"
.include "rom_floppy_constants.inc"
.include "startup_interface.inc"

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
    LDX #16

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

.GLOBAL init

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
    ldx     #$03
CreateDecTabLoop:
    stx     bits
    txa
    asl     A                 ;shift left, putting high bit in carry
    bit     bits              ;does shifted version overlap?
    beq     reject           ;no, doesn't have two adjacent 1s
    ora     bits              ;merge
    eor     #$ff              ;invert
    and     #$7e              ;clear hi and lo bits
check_dub0:
    bcs     reject           ;initial hi bit set *or* adjacent 0 bits set
    lsr     A                 ;shift right, low bit into carry
    bne     check_dub0       ;if more bits in byte, loop
    tya                       ;we have a winner... store Y-reg to memory
    sta     CONV_TAB,x        ;actual lookup will be on bytes with hi bit set
    iny                       ; so they'll read from CONV_TAB-128
reject:
    inx                       ;try next candidate
    bpl     CreateDecTabLoop

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
rdbyte1:      lda IWM_Q6_OFF,x
              bpl rdbyte1
check_d5:     eor #$d5
              bne rdbyte1
              nop
              nop
              nop
rdbyte2:      lda IWM_Q6_OFF,x
              bpl rdbyte2
              cmp #$aa
              bne check_d5
              nop
              nop
              nop
              nop
rdbyte3:      lda IWM_Q6_OFF,x
              bpl rdbyte3
              cmp #$96
              beq FoundAddress
              plp
              bcc ReadSector
              eor #$ad
              beq FoundData
              bne ReadSector

FoundAddress:
    ldy #$03
hdr_loop:
    sta found_track
    nop
    nop
    nop
adr_hdr_rdbyte1:
    lda IWM_Q6_OFF,x
    bpl adr_hdr_rdbyte1
    rol A
    sta bits
    nop
    nop
    nop
    nop
 adr_hdr_rdbyte2:
    lda IWM_Q6_OFF,x
    bpl adr_hdr_rdbyte2
    and bits
    dey
    bne hdr_loop
    plp
    cmp sector
    bne ReadSector
    lda found_track
    cmp track
    bne ReadSector
    bcs ReadSector_C

FoundData:
    ldy #86
read_twos_loop:
    sty bits
dat_twos_rdbyte1:
    ldy IWM_Q6_OFF,x ;ldy IWM_Q6_OFF,x
    bpl dat_twos_rdbyte1
    eor $02d6,y
    ldy bits
    dey
    sta TWOS_BUFFER,y
    nop
    nop
    nop ;Possibly here is good
    bne read_twos_loop

read_sixes_loop:
    sty bits
sixes_rdbyte2:
    ldy IWM_Q6_OFF,x
    bpl sixes_rdbyte2
    eor CONV_TAB-128,y
    ldy bits
    sta (data_ptr),y
    iny
    nop
    nop
    nop
    nop
    bne read_sixes_loop

checksum_rdbyte3:
    ldy IWM_Q6_OFF,x
    bpl checksum_rdbyte3
    eor CONV_TAB-128,y
another:
    beq Decode
    jmp ReadSector

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

    rts

DiskTestDone:

    JMP init
HALT:
    JMP HALT

MON_WAIT:
    TYA
    LDY #$02 ;NOTE: We do this twice because of the possibility
             ;that we're coming into vblank JUST as we enter this
             ;function and therefore might not end up waiting
             ;any time at all
MON_TOP:
    BIT $2002
    BPL MON_TOP
    DEY
    BNE MON_TOP
    TAY
    LDA #$00
    RTS

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
    sta     sector            
    lda     cur_track
    sta     track
    jsr     ReadSector
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
    rts
    
BOOT_MSG:
    .ASCIIZ "LOADING..."

IRQ_BRK_HANDLE:
    RTI
   
regs:
        .byte $30,$08,$00,$00
        .byte $30,$08,$00,$00
        .byte $80,$00,$00,$00
        .byte $30,$00,$00,$00
        .byte $00,$00,$00,$00

CHAR_TILES:
    .incbin "font.chr"

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

.segment "VECTORS"
.word $0000
.word ENTRY
.word IRQ_BRK_HANDLE

