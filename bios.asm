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

;Fill first attribute table to all be palette zero
    LDX #64
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
    LDA #$7E
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
    LDA #$FF
    STA LAST_KB_BIT
    LDA #$00
    STA CURRENT_KB_COL
    STA CURRENT_KB_ROW

;Enable rendering
    LDA #$0E
    STA $2001

JMP HALT

; bit 0 low and bit 1 low (in) = read next half-nybble from bits 2 and 3 (in)
; bit 0 low and bit 1 high (in) = load next half-nybble into bits 2 and 3 (out)
; bit 0 high (out) = incoming data is available in bits 2 and 3 (out) 
.GLOBAL PICO_TX
PICO_TX:
    LDY #$04
NEXT_TX_BIT:
    TAX
    AND #$03
    ROR
    BCC NO_TX_ADD
    CLC
    ADC #$02
NO_TX_ADD:
    PHA
WAIT_TX_READY:
    LDA $8000
    AND #$04
    BEQ WAIT_TX_READY
    PLA
    STA $8000
    TXA
    LSR
    LSR
    DEY
    BNE NEXT_TX_BIT
    
    RTS

;TODO: figure out how to tell pico that we want more data
.GLOBAL PICO_RX
PICO_RX:
    LDX #$00
    LDY #$04
NEXT_RX_BIT:
    LDA $8000
    AND #$08
    BEQ NEXT_RX_BIT
    LDA $8000
    AND #$03
    ROR
    BCC NO_RX_ADD
    CLC
    ADC #$02
NO_RX_ADD:
    STA $00
    TXA
    ASL
    ASL
    ADC $00
    TAX
    LDA #$04
    STA $8000
    DEY
    BNE NEXT_RX_BIT

    TXA
    RTS

.GLOBAL init
HALT:
    JMP init
    JMP HALT

IRQ_BRK_HANDLE:
    RTI

.SEGMENT "KEY_LUT"
KEY_LUT:
.BYTE ';'
.BYTE 'L'
.BYTE 'K'
.BYTE 'J'
.BYTE 'H'
.BYTE $20
.BYTE 'P'
.BYTE 'O'
.BYTE 'I'
.BYTE 'U'
.BYTE 'Y'
.BYTE $0D
.BYTE '0'
.BYTE '9'
.BYTE '8'
.BYTE '7'
.BYTE '6'
.BYTE $00
.BYTE 'Z'
.BYTE 'X'
.BYTE 'C'
.BYTE 'V'
.BYTE 'B'
.BYTE $00
.BYTE 'A'
.BYTE 'S'
.BYTE 'D'
.BYTE 'F'
.BYTE 'G'
.BYTE $00
.BYTE 'Q'
.BYTE 'W'
.BYTE 'E'
.BYTE 'R'
.BYTE 'T'
.BYTE $00
.BYTE '1'
.BYTE '2'
.BYTE '3'
.BYTE '4'
.BYTE '5'
.BYTE $00
.BYTE '/'
.BYTE '>'
.BYTE '<'
.BYTE 'M'
.BYTE 'N'
.BYTE '+'

.SEGMENT "CHR_LUT"
CHR_LUT:
.BYTE $00 ; 0x0 
.BYTE $00 ; 0x1
.BYTE $00 ; 0x2
.BYTE $00 ; 0x3
.BYTE $00 ; 0x4
.BYTE $00 ; 0x5
.BYTE $00 ; 0x6
.BYTE $00 ; 0x7
.BYTE $00 ; 0x8
.BYTE $00 ; 0x9
.BYTE $00 ; 0xa
.BYTE $00 ; 0xb
.BYTE $00 ; 0xc
.BYTE $00 ; 0xd
.BYTE $00 ; 0xe
.BYTE $00 ; 0xf
.BYTE $00 ; 0x10
.BYTE $00 ; 0x11
.BYTE $00 ; 0x12
.BYTE $00 ; 0x13
.BYTE $00 ; 0x14
.BYTE $00 ; 0x15
.BYTE $00 ; 0x16
.BYTE $00 ; 0x17
.BYTE $00 ; 0x18
.BYTE $00 ; 0x19
.BYTE $00 ; 0x1a
.BYTE $00 ; 0x1b
.BYTE $00 ; 0x1c
.BYTE $00 ; 0x1d
.BYTE $00 ; 0x1e
.BYTE $00 ; 0x1f
.BYTE $7D ; 0x20
.BYTE $6A ; 0x21
.BYTE $BD ; 0x22
.BYTE $27 ; 0x23
.BYTE $6C ; 0x24
.BYTE $E8 ; 0x25
.BYTE $67 ; 0x26
.BYTE $2B ; 0x27
.BYTE $64 ; 0x28
.BYTE $66 ; 0x29
.BYTE $7B ; 0x2a
.BYTE $8F ; 0x2b
.BYTE $1A ; 0x2c
.BYTE $65 ; 0x2d
.BYTE $69 ; 0x2e
.BYTE $7A ; 0x2f
.BYTE $70 ; 0x30
.BYTE $71 ; 0x31
.BYTE $72 ; 0x32
.BYTE $73 ; 0x33
.BYTE $74 ; 0x34
.BYTE $75 ; 0x35
.BYTE $76 ; 0x36
.BYTE $77 ; 0x37
.BYTE $78 ; 0x38
.BYTE $79 ; 0x39
.BYTE $F7 ; 0x3a
.BYTE $DC ; 0x3b
.BYTE $2E ; 0x3c
.BYTE $C7 ; 0x3d
.BYTE $2F ; 0x3e
.BYTE $6B ; 0x3f
.BYTE $6D ; 0x40
.BYTE $30 ; 0x41
.BYTE $31 ; 0x42
.BYTE $32 ; 0x43
.BYTE $33 ; 0x44
.BYTE $34 ; 0x45
.BYTE $35 ; 0x46
.BYTE $36 ; 0x47
.BYTE $37 ; 0x48
.BYTE $38 ; 0x49
.BYTE $39 ; 0x4a
.BYTE $3A ; 0x4b
.BYTE $3B ; 0x4c
.BYTE $3C ; 0x4d
.BYTE $3D ; 0x4e
.BYTE $3E ; 0x4f
.BYTE $3F ; 0x50
.BYTE $40 ; 0x51
.BYTE $41 ; 0x52
.BYTE $42 ; 0x53
.BYTE $43 ; 0x54
.BYTE $44 ; 0x55
.BYTE $45 ; 0x56
.BYTE $46 ; 0x57
.BYTE $47 ; 0x58
.BYTE $48 ; 0x59
.BYTE $49 ; 0x5a
.BYTE $98 ; 0x5b
.BYTE $E7 ; 0x5c
.BYTE $9A ; 0x5d
.BYTE $6E ; 0x5e
.BYTE $8C ; 0x5f
.BYTE $81 ; 0x60
.BYTE $50 ; 0x61
.BYTE $51 ; 0x62
.BYTE $52 ; 0x63
.BYTE $53 ; 0x64
.BYTE $54 ; 0x65
.BYTE $55 ; 0x66
.BYTE $56 ; 0x67
.BYTE $57 ; 0x68
.BYTE $58 ; 0x69
.BYTE $59 ; 0x6a
.BYTE $5A ; 0x6b
.BYTE $5B ; 0x6c
.BYTE $5C ; 0x6d
.BYTE $5D ; 0x6e
.BYTE $5E ; 0x6f
.BYTE $5F ; 0x70
.BYTE $4A ; 0x71
.BYTE $4B ; 0x72
.BYTE $4C ; 0x73
.BYTE $4D ; 0x74
.BYTE $4E ; 0x75
.BYTE $4F ; 0x76
.BYTE $01 ; 0x77
.BYTE $08 ; 0x78
.BYTE $0C ; 0x79
.BYTE $0F ; 0x7a
.BYTE $A0 ; 0x7b
.BYTE $5B ; 0x7c
.BYTE $A1 ; 0x7d
.BYTE $1C ; 0x7e

.SEGMENT "BLANK_AREA"
.REPEAT $C600
.BYTE $00
.ENDREP

.SEGMENT "VECTORS"
.WORD $0000
.WORD ENTRY
.WORD IRQ_BRK_HANDLE

