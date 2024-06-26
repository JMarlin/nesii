
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

STACK           = $0100  
TWOS_BUFFER     = $0300    ;holds the 2-bit chunks
CONV_TAB        = $0356   ;6+2 conversion table
BOOT1           = $0400   ;buffer for next stage of loader
IWM_PH0_OFF     = $c080             ;stepper motor control
IWM_PH0_ON      = $c081             ;stepper motor control
IWM_PH2_OFF     = $c084
IWM_PH2_ON      = $c085
IWM_MOTOR_ON    = $c089             ;starts drive spinning
IWM_MOTOR_OFF   = $c088
IWM_SEL_DRIVE_1 = $c08a             ;selects drive 1
IWM_Q6_OFF      = $c08c             ;read
IWM_Q7_OFF      = $c08e             ;WP sense/read

CART_SWITCHES   = $d000

data_ptr        = $26       ;pointer to BOOT1 data buffer
slot_index      = $2b       ;slot number << 4
bits            = $3c       ;temp storage for bit manipulation
sector          = $3d       ;sector to read
found_track     = $40       ;track found
track           = $41       ;track to read
cur_track  = $42
cur_sector = $43

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

    jsr boot_game
    jmp init

ReadSector:   clc
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
    bne TEST_mon ;ReadSector
    bcs ReadSector_C

TEST_mon:
    jmp init

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

    ;JMP BOOT1

    JMP init
HALT:
    JMP HALT

MON_WAIT:
    TYA
    LDY #$02
MON_TOP:
    BIT $2002
    BPL MON_TOP
    DEY
    BNE MON_TOP
    TAY
    LDA #$00
    RTS

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

load_boot_sector:
    lda     #$00
    sta     data_ptr          ;Store page-aligned
    lda     #>BOOT1           ;Target is the NES RAM boot area
    sta     data_ptr+1
    jsr     load_next_sector
    rts

target_page = $44

load_chr_data:
    ;TODO
    rts

load_prg_16k:
    lda #$00
    sta data_ptr
    lda #$80
    sta data_ptr+1
next_sector_16k:
    jsr load_next_sector
    inc data_ptr+1
    lda data_ptr+1
    cmp #$C0
    bne next_sector_16k
    rts

;IMPORTANT NOTE: When making the disk image for this, you'll have to skew the sector data
;                in DOS 3.3 format, because apparently ADT skews them when copying onto the disk
boot_game:
    ;Make sure we're reset to the first sector
    lda #$00
    sta cur_sector
    sta cur_track

    ;Read boot sector into NES RAM (ultimately, that's where the rest of this code should go too)
    jsr load_boot_sector

    ;Read 8 tracks of PRG data into low-mapped low cart RAM
    jsr load_prg_16k

    ;Switch low cart RAM mapping
    lda #$02
    sta CART_SWITCHES

    ;Read 8 more tracks of PRG data into low-mapped high cart RAM
    jsr load_prg_16k
    lda IWM_MOTOR_OFF
    rts

    ;Read 2 tracks of CHR data and transfer it into CHR-RAM
    jsr load_chr_data

    ;Stop the disk drive
    lda $C0F8

    ;Jump to the boot code
    jmp BOOT1

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

.SEGMENT "BLANK_AREA"
.REPEAT $C600
.BYTE $00
.ENDREP

.SEGMENT "VECTORS"
.WORD $0000
.WORD ENTRY
.WORD IRQ_BRK_HANDLE

