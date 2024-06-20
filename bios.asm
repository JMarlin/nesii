
.SEGMENT "CODE_MAIN"
.INCLUDE "char_io.inc"
.INCLUDE "monitor.inc"
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
@loop:  lda @regs,y
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

        JMP moar
   
@regs:
        .byte $30,$08,$00,$00
        .byte $30,$08,$00,$00
        .byte $80,$00,$00,$00
        .byte $30,$00,$00,$00
        .byte $00,$00,$00,$00

moar:

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

;Indicate that we haven't yet clocked in any bits from the keyboard
    JSR INITKEYBOARD
    LDA #$FF
    STA LAST_KB_BIT
    LDA #$00
    STA CURRENT_KB_COL
    STA CURRENT_KB_ROW

;Enable rendering
    LDA #$0E
    STA $2001

    LDA #$00
    STA $4000

.GLOBAL init

STACK         =    $0100  
TWOS_BUFFER   =     $0300    ;holds the 2-bit chunks
CONV_TAB      =     $0356   ;6+2 conversion table
BOOT1         =     $0800   ;buffer for next stage of loader
IWM_PH0_OFF   =     $c080             ;stepper motor control
IWM_PH0_ON    =     $c081             ;stepper motor control
IWM_MOTOR_ON  =     $c089             ;starts drive spinning
IWM_MOTOR_OFF =     $c088
IWM_SEL_DRIVE_1 =   $c08a             ;selects drive 1
IWM_Q6_OFF    =     $c08c             ;read
IWM_Q7_OFF    =     $c08e             ;WP sense/read
MON_WAIT      =     $fca8             ;delay for (26 + 27*Acc + 5*(Acc*Acc))/2 cycles
MON_IORTS     =     $ff58             ;JSR here to find out where one is

found_track = $40
bits = $3c

lda #'X'
.GLOBAL PRNTCHR
jsr PRNTCHR


ldx     #$60
lda     IWM_Q7_OFF,x
lda     IWM_Q6_OFF,x
lda     IWM_SEL_DRIVE_1,x
lda     IWM_MOTOR_ON,x

ReadSector:   clc
ReadSector_C: php
rdbyte1:      lda IWM_Q6_OFF,x
              bpl rdbyte1
check_d5:     eor #$d5
              bne rdbyte1
              nop
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
JMP init

FoundData:
    beq ReadSector

DiskTestDone:
    lda IWM_MOTOR_OFF,x

    JMP init
HALT:
    JMP HALT

IRQ_BRK_HANDLE:
    RTI

CHAR_TILES:
    .incbin "font.chr"

.SEGMENT "BLANK_AREA"
.REPEAT $C600
.BYTE $00
.ENDREP

.SEGMENT "VECTORS"
.WORD $0000
.WORD ENTRY
.WORD IRQ_BRK_HANDLE

