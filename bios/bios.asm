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

    jsr floppy_init
    jsr system_startup
    jmp init

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
jsr read_sector      ;FFD4
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

