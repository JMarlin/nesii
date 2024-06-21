.SEGMENT "CODE_MAIN"
.INCLUDE "char_io.inc"

INITKEYBOARD:
.GLOBAL INITKEYBOARD
    ;Loop over each column and check the 7th row to see if we are at column 1
KB_INIT_COLUMN_LOOP:
    LDA #$01
    STA $4016
    LDA $4016
    LDA #$00
    STA $4016
    LDY #$06
KB_ROW_SKIP_LOOP:
    LDA $4016
    DEY
    BNE KB_ROW_SKIP_LOOP
    AND #$01
    BNE KB_INIT_COLUMN_LOOP
KB_COL_ONE_FOUND:
    RTS

GETKEY:
.GLOBAL GETKEY
    LDA #0
    STA KEY_WAS_FOUND
    LDX #0
NEXT_KB_COLUMN_LOOP:
    LDY #6
    LDA #01
CLK_KB_BIT_LOOP:
    STA $4016
    LDA $4016
    STA LAST_KB_BIT
    LDA KEY_WAS_FOUND
    BNE CONTINUE_KB_BIT_LOOP
    LDA LAST_KB_BIT
    AND #$01
    BNE CONTINUE_KB_BIT_LOOP
    LDA KEY_LUT,X
    PHA 
    LDA #$01
    STA KEY_WAS_FOUND
    CLC
    BCC CONTINUE_KB_BIT_LOOP
DO_ANOTHER_INNER_KB_LOOP:
    LDA #$00
    CLC
    BCC CLK_KB_BIT_LOOP
CONTINUE_KB_BIT_LOOP:
    INX
    DEY
    BNE DO_ANOTHER_INNER_KB_LOOP
    TXA
    CMP #48
    BNE NEXT_KB_COLUMN_LOOP
    LDA KEY_WAS_FOUND
    BNE RETURN_STACK_KEY_VALUE
    LDA #$FF
    STA LAST_PRESSED_KEY
    CLC
    BCC GETKEY
RETURN_STACK_KEY_VALUE:
    PLA
    CMP LAST_PRESSED_KEY
    BEQ GETKEY
    STA LAST_PRESSED_KEY
    RTS

;PRINT CHARACTER SUBROUTINE
;Wait for VBLANK
PRNTCHR:
.GLOBAL PRNTCHR
:
    BIT $2002
    BPL :-

    ;Look up the tile number of this character, print nothing if it was zero
    TAX
    LDA CHR_LUT,X
    CMP #$FF
    BEQ CHECK_CTL

    ;Non-zero tile number found, write it to the PPU and increment the cursor
    LDY SCREEN_ADDR+1
    STY $2006
    LDX SCREEN_ADDR
    STX $2006
    STA $2007

    ;Character was successfully printed, so advance the cursor
STEP_CHARACTER:
    INX
    STX SCREEN_ADDR
    BNE CHECK_END_OF_SREEN
    INY
    STY SCREEN_ADDR+1
CHECK_END_OF_SREEN:
    TXA
    AND #$1F
    CMP #$1F
    BNE PRNTCHR_END
STEP_OVER_MARGIN:
    INX
    BNE KEEP_ON_STEPPIN
    INY
    STY SCREEN_ADDR+1
KEEP_ON_STEPPIN:   
    INX
    STX SCREEN_ADDR
DO_WRAP_SCROLL:
    TXA
    AND #$E0
    JSR CHECK_AND_SCROLL
    CLC
    BCC PRNTCHR_END

CHECK_CTL:
    TXA
    CMP #$0D
    BNE CHECK_LINEFEED
    LDA SCREEN_ADDR
    AND #$E0
    TAX
    INX
    TXA
    STA SCREEN_ADDR
    CLC
    BCC PRNTCHR_END

CHECK_LINEFEED:
    CMP #$0A
    BNE PRNTCHR_END
    LDA SCREEN_ADDR
    CLC
    ADC #$20
    STA SCREEN_ADDR
    AND #$E0
    BNE DO_LF_SCROLL
    LDX SCREEN_ADDR+1
    INX
    STX SCREEN_ADDR+1

DO_LF_SCROLL:
    JSR CHECK_AND_SCROLL

PRNTCHR_END:
    LDA #$00
    STA $2005
    LDA SCROLL_VALUE
    STA $2005

    RTS

;PRINT STRING SUBROUTINE
.GLOBAL PRINTSTR
PRINTSTR:
.GLOBAL PRINTSTR
    LDY #$00
:
    LDA (STRING_PTR),Y
    BEQ PRINTSTR_END
    TAX
    TYA
    PHA
    TXA
    JSR PRNTCHR
    PLA
    TAY
    INY
    CLC
    BCC :-
PRINTSTR_END:
    RTS

;SUBROUTINE FOR SOFTWARE LINE SCROLLING
CHECK_AND_SCROLL:
    TAX
    LDA SCREEN_ADDR+1
    CMP #$23
    BNE CHECK_SCROLL_FLAG
    TXA
    CMP #$C0
    BNE CHECK_AT_BOTTOM

    ;If we are at the end of the nametable, wrap to the beginning
    LDA SCREEN_ADDR
    AND #$1F
    STA SCREEN_ADDR
    LDA #$20
    STA SCREEN_ADDR+1
    LDA #$01
    CLC
    BCC CHECK_SCROLL_FLAG

CHECK_AT_BOTTOM:
    CMP #$A0
    BNE CHECK_SCROLL_FLAG
    STA IS_SCROLLING
CHECK_SCROLL_FLAG:
    LDA IS_SCROLLING
    BEQ PRNTCHR_END

DO_SCREEN_SCROLL:
    LDA SCREEN_ADDR+1
    STA $2006
    LDA SCREEN_ADDR
    AND #$E0
    STA $2006
    LDX #$20
    LDA #$3F
LINE_CLEAR_TOP:
    STA $2007
    DEX
    BNE LINE_CLEAR_TOP

    LDA SCROLL_VALUE
    CLC
    ADC #$08
    CMP #$F0
    BEQ WRAP_SCROLL
    STA SCROLL_VALUE

    RTS

WRAP_SCROLL:
    LDA #$00
    STA SCROLL_VALUE

    RTS

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
.BYTE $FF ; 0x0 
.BYTE $FF ; 0x1
.BYTE $FF ; 0x2
.BYTE $FF ; 0x3
.BYTE $FF ; 0x4
.BYTE $FF ; 0x5
.BYTE $FF ; 0x6
.BYTE $FF ; 0x7
.BYTE $FF ; 0x8
.BYTE $FF ; 0x9
.BYTE $FF ; 0xa
.BYTE $FF ; 0xb
.BYTE $FF ; 0xc
.BYTE $FF ; 0xd
.BYTE $FF ; 0xe
.BYTE $FF ; 0xf
.BYTE $FF ; 0x10
.BYTE $FF ; 0x11
.BYTE $FF ; 0x12
.BYTE $FF ; 0x13
.BYTE $FF ; 0x14
.BYTE $FF ; 0x15
.BYTE $FF ; 0x16
.BYTE $FF ; 0x17
.BYTE $FF ; 0x18
.BYTE $FF ; 0x19
.BYTE $FF ; 0x1a
.BYTE $FF ; 0x1b
.BYTE $FF ; 0x1c
.BYTE $FF ; 0x1d
.BYTE $FF ; 0x1e
.BYTE $FF ; 0x1f
.BYTE $3F ; 0x20
.BYTE $24 ; 0x21
.BYTE $2D ; 0x22
.BYTE $27 ; 0x23
.BYTE $25 ; 0x24
.BYTE $2E ; 0x25
.BYTE $2F ; 0x26
.BYTE $29 ; 0x27
.BYTE $30 ; 0x28
.BYTE $31 ; 0x29
.BYTE $32 ; 0x2a
.BYTE $33 ; 0x2b
.BYTE $2A ; 0x2c
.BYTE $27 ; 0x2d
.BYTE $28 ; 0x2e
.BYTE $34 ; 0x2f
.BYTE $00 ; 0x30
.BYTE $01 ; 0x31
.BYTE $02 ; 0x32
.BYTE $03 ; 0x33
.BYTE $04 ; 0x34
.BYTE $05 ; 0x35
.BYTE $06 ; 0x36
.BYTE $07 ; 0x37
.BYTE $08 ; 0x38
.BYTE $09 ; 0x39
.BYTE $26 ; 0x3a
.BYTE $35 ; 0x3b
.BYTE $36 ; 0x3c
.BYTE $38 ; 0x3d
.BYTE $37 ; 0x3e
.BYTE $39 ; 0x3f
.BYTE $3A ; 0x40
.BYTE $0A ; 0x41
.BYTE $0B ; 0x42
.BYTE $0C ; 0x43
.BYTE $0D ; 0x44
.BYTE $0E ; 0x45
.BYTE $0F ; 0x46
.BYTE $10 ; 0x47
.BYTE $11 ; 0x48
.BYTE $12 ; 0x49
.BYTE $13 ; 0x4a
.BYTE $14 ; 0x4b
.BYTE $15 ; 0x4c
.BYTE $16 ; 0x4d
.BYTE $17 ; 0x4e
.BYTE $18 ; 0x4f
.BYTE $19 ; 0x50
.BYTE $1A ; 0x51
.BYTE $1B ; 0x52
.BYTE $1C ; 0x53
.BYTE $1D ; 0x54
.BYTE $1E ; 0x55
.BYTE $1F ; 0x56
.BYTE $20 ; 0x57
.BYTE $21 ; 0x58
.BYTE $22 ; 0x59
.BYTE $23 ; 0x5a
.BYTE $3B ; 0x5b
.BYTE $3D ; 0x5c
.BYTE $3C ; 0x5d
.BYTE $3E ; 0x5e
.BYTE $2C ; 0x5f
.BYTE $2B ; 0x60
.BYTE $0A ; 0x61
.BYTE $0B ; 0x62
.BYTE $0C ; 0x63
.BYTE $0D ; 0x64
.BYTE $0E ; 0x65
.BYTE $0F ; 0x66
.BYTE $10 ; 0x67
.BYTE $11 ; 0x68
.BYTE $12 ; 0x69
.BYTE $13 ; 0x6a
.BYTE $14 ; 0x6b
.BYTE $15 ; 0x6c
.BYTE $16 ; 0x6d
.BYTE $17 ; 0x6e
.BYTE $18 ; 0x6f
.BYTE $19 ; 0x70
.BYTE $1A ; 0x71
.BYTE $1B ; 0x72
.BYTE $1C ; 0x73
.BYTE $1D ; 0x74
.BYTE $1E ; 0x75
.BYTE $1F ; 0x76
.BYTE $20 ; 0x77
.BYTE $21 ; 0x78
.BYTE $22 ; 0x79
.BYTE $23 ; 0x7a
.BYTE $3F ; 0x7b
.BYTE $3F ; 0x7c
.BYTE $3F ; 0x7d
.BYTE $3F ; 0x7e

