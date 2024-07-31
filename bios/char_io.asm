.segment "CODE"
.include "char_io.inc"


.global char_io_init_screen
char_io_init_screen:
;Initialize pointer into tile table
tile_ptr=$fe
    lda #<char_tiles
    sta tile_ptr
    lda #>char_tiles
    sta tile_ptr+1
;Initialize PPU write counter
    ldy #0
    sty $2001
    sty $2006
    sty $2006
    ldx #4
tile_load_loop:
    lda (tile_ptr),Y
    sta $2007
    iny
    bne tile_load_loop
    inc tile_ptr+1
    dex
    bne tile_load_loop
;Set scroll to 0, 0
    lda #$00
    sta $2005
    sta $2005
    sta scroll_value
;Initialize print location to 1,1 on the playfield
    lda #$21
    sta screen_addr
    lda #$20
    sta screen_addr+1
;When we first start, we do not yet need to scroll
    lda #$00
    sta is_scrolling
;Enable rendering
    lda #$0e
    sta $2001
    rts


char_io_init_keyboard:
.global char_io_init_keyboard
    ;Loop over each column and check the 7th row to see if we are at column 1
keyboard_init_column_loop:
    lda #$01
    sta $4016
    lda $4017
    lda #$00
    sta $4016
    ldy #$06
keyboard_row_skip_loop:
    lda $4017
    dey
    bne keyboard_row_skip_loop
    and #$01
    bne keyboard_init_column_loop
keyboard_column_one_found:
    rts


.global char_io_getkey
char_io_getkey:
    lda #0
    sta key_was_found
    ldx #0
next_keyboard_column_loop:
    ldy #6
    lda #01
clock_keyboard_bit_loop:
    sta $4016
    lda $4017
    sta last_keyboard_bit
    lda key_was_found
    bne continue_keyboard_bit_loop
    lda last_keyboard_bit
    and #$01
    bne continue_keyboard_bit_loop
    lda key_lut,x
    pha 
    lda #$01
    sta key_was_found
    clc
    bcc continue_keyboard_bit_loop
do_another_inner_keyboard_loop:
    lda #$00
    clc
    bcc clock_keyboard_bit_loop
continue_keyboard_bit_loop:
    inx
    dey
    bne do_another_inner_keyboard_loop
    txa
    cmp #48
    bne next_keyboard_column_loop
    lda key_was_found
    bne return_stack_key_value
    lda #$FF
    sta last_pressed_key
    clc
    bcc char_io_getkey
return_stack_key_value:
    pla
    cmp last_pressed_key
    beq char_io_getkey
    sta last_pressed_key
    rts


char_io_printchr:
.global char_io_printchr
;Wait for VBLANK
:
    bit $2002
    bpl :-
    ;Look up the tile number of this character, print nothing if it was zero
    tax
    lda chr_lut,X
    cmp #$FF
    beq check_ctl
    ;Non-zero tile number found, write it to the PPU and increment the cursor
    ldy screen_addr+1
    sty $2006
    ldx screen_addr
    stx $2006
    sta $2007
    ;Character was successfully printed, so advance the cursor
step_character:
    inx
    stx screen_addr
    bne check_end_of_screen
    iny
    sty screen_addr+1
check_end_of_screen:
    txa
    and #$1f
    cmp #$1f
    bne char_io_printchr_end
step_over_margin:
    inx
    bne keep_on_steppin
    iny
    sty screen_addr+1
keep_on_steppin:   
    inx
    stx screen_addr
do_wrap_scroll:
    txa
    and #$e0
    jsr check_and_scroll
    clc
    bcc char_io_printchr_end
check_ctl:
    txa
    cmp #$0d
    bne check_linefeed
    lda screen_addr
    and #$e0
    tax
    inx
    txa
    sta screen_addr
    clc
    bcc char_io_printchr_end
check_linefeed:
    cmp #$0a
    bne char_io_printchr_end
    lda screen_addr
    clc
    adc #$20
    sta screen_addr
    and #$e0
    bne do_lf_scroll
    ldx screen_addr+1
    inx
    stx screen_addr+1
do_lf_scroll:
    jsr check_and_scroll
char_io_printchr_end:
    lda #$00
    sta $2005
    lda scroll_value
    sta $2005
    rts


.global char_io_printstr
char_io_printstr:
.global char_io_printstr
    ldy #$00
:
    lda (string_pointer),y
    beq char_io_printstr_end
    tax
    tya
    pha
    txa
    jsr char_io_printchr
    pla
    tay
    iny
    clc
    bcc :-
char_io_printstr_end:
    rts


check_and_scroll:
    tax
    lda screen_addr+1
    cmp #$23
    bne check_scroll_flag
    txa
    cmp #$C0
    bne check_scroll_flag
    lda #$01
    sta is_scrolling
    ;If we are at the end of the nametable, wrap to the beginning
    lda screen_addr
    and #$1f
    sta screen_addr
    lda #$20
    sta screen_addr+1
    lda #$01
check_scroll_flag:
    lda is_scrolling
    beq char_io_printchr_end
do_screen_scroll:
    lda screen_addr+1
    sta $2006
    lda screen_addr
    and #$e0
    sta $2006
    ldx #$20
    lda #$3f
line_clear_top:
    sta $2007
    dex
    bne line_clear_top
    lda scroll_value
    clc
    adc #$08
    cmp #$f0
    beq wrap_scroll
    sta scroll_value
    rts
wrap_scroll:
    lda #$00
    sta scroll_value
    rts


char_tiles:
    .incbin "blob/font.chr"
    

.segment "KEY_LUT"
key_lut:
.byte ';'
.byte 'L'
.byte 'K'
.byte 'J'
.byte 'H'
.byte $20
.byte 'P'
.byte 'O'
.byte 'I'
.byte 'U'
.byte 'Y'
.byte $0D
.byte '0'
.byte '9'
.byte '8'
.byte '7'
.byte '6'
.byte $00
.byte 'Z'
.byte 'X'
.byte 'C'
.byte 'V'
.byte 'B'
.byte $00
.byte 'A'
.byte 'S'
.byte 'D'
.byte 'F'
.byte 'G'
.byte $00
.byte 'Q'
.byte 'W'
.byte 'E'
.byte 'R'
.byte 'T'
.byte $00
.byte '1'
.byte '2'
.byte '3'
.byte '4'
.byte '5'
.byte $00
.byte '/'
.byte '.'
.byte ','
.byte 'M'
.byte 'N'
.byte '+'


.segment "CHR_LUT"
chr_lut:
.byte $ff ; 0x0 
.byte $ff ; 0x1
.byte $ff ; 0x2
.byte $ff ; 0x3
.byte $ff ; 0x4
.byte $ff ; 0x5
.byte $ff ; 0x6
.byte $ff ; 0x7
.byte $ff ; 0x8
.byte $ff ; 0x9
.byte $ff ; 0xa
.byte $ff ; 0xb
.byte $ff ; 0xc
.byte $ff ; 0xd
.byte $ff ; 0xe
.byte $ff ; 0xf
.byte $ff ; 0x10
.byte $ff ; 0x11
.byte $ff ; 0x12
.byte $ff ; 0x13
.byte $ff ; 0x14
.byte $ff ; 0x15
.byte $ff ; 0x16
.byte $ff ; 0x17
.byte $ff ; 0x18
.byte $ff ; 0x19
.byte $ff ; 0x1a
.byte $ff ; 0x1b
.byte $ff ; 0x1c
.byte $ff ; 0x1d
.byte $ff ; 0x1e
.byte $ff ; 0x1f
.byte $3f ; 0x20
.byte $24 ; 0x21
.byte $2d ; 0x22
.byte $27 ; 0x23
.byte $25 ; 0x24
.byte $2e ; 0x25
.byte $2f ; 0x26
.byte $29 ; 0x27
.byte $30 ; 0x28
.byte $31 ; 0x29
.byte $32 ; 0x2a
.byte $33 ; 0x2b
.byte $2a ; 0x2c
.byte $27 ; 0x2d
.byte $28 ; 0x2e
.byte $34 ; 0x2f
.byte $00 ; 0x30
.byte $01 ; 0x31
.byte $02 ; 0x32
.byte $03 ; 0x33
.byte $04 ; 0x34
.byte $05 ; 0x35
.byte $06 ; 0x36
.byte $07 ; 0x37
.byte $08 ; 0x38
.byte $09 ; 0x39
.byte $26 ; 0x3a
.byte $35 ; 0x3b
.byte $36 ; 0x3c
.byte $38 ; 0x3d
.byte $37 ; 0x3e
.byte $39 ; 0x3f
.byte $3a ; 0x40
.byte $0a ; 0x41
.byte $0b ; 0x42
.byte $0c ; 0x43
.byte $0d ; 0x44
.byte $0e ; 0x45
.byte $0f ; 0x46
.byte $10 ; 0x47
.byte $11 ; 0x48
.byte $12 ; 0x49
.byte $13 ; 0x4a
.byte $14 ; 0x4b
.byte $15 ; 0x4c
.byte $16 ; 0x4d
.byte $17 ; 0x4e
.byte $18 ; 0x4f
.byte $19 ; 0x50
.byte $1a ; 0x51
.byte $1b ; 0x52
.byte $1c ; 0x53
.byte $1d ; 0x54
.byte $1e ; 0x55
.byte $1f ; 0x56
.byte $20 ; 0x57
.byte $21 ; 0x58
.byte $22 ; 0x59
.byte $23 ; 0x5a
.byte $3b ; 0x5b
.byte $3d ; 0x5c
.byte $3c ; 0x5d
.byte $3e ; 0x5e
.byte $2c ; 0x5f
.byte $2b ; 0x60
.byte $0a ; 0x61
.byte $0b ; 0x62
.byte $0c ; 0x63
.byte $0d ; 0x64
.byte $0e ; 0x65
.byte $0f ; 0x66
.byte $10 ; 0x67
.byte $11 ; 0x68
.byte $12 ; 0x69
.byte $13 ; 0x6a
.byte $14 ; 0x6b
.byte $15 ; 0x6c
.byte $16 ; 0x6d
.byte $17 ; 0x6e
.byte $18 ; 0x6f
.byte $19 ; 0x70
.byte $1a ; 0x71
.byte $1b ; 0x72
.byte $1c ; 0x73
.byte $1d ; 0x74
.byte $1e ; 0x75
.byte $1f ; 0x76
.byte $20 ; 0x77
.byte $21 ; 0x78
.byte $22 ; 0x79
.byte $23 ; 0x7a
.byte $3f ; 0x7b
.byte $3f ; 0x7c
.byte $3f ; 0x7d
.byte $3f ; 0x7e

