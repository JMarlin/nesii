.segment "CODE"
.include "char_io.inc"
.include "monitor.inc"
.include "startup_interface.inc"
.include "floppy.inc"
.include "bios.inc"
.include "globals.inc"

entry:
;Turn off interrupts and decimal mode
    sei
    cld
    ldx #$FF
    txs

;Initialize PPU state (disable interrupts and rendering)
    lda #$00
    sta $2000
    sta $2001

;Wait for three vblanks (let PPU state settle?)
    bit $2002
ppu_vblank_wait1:
    bit $2002
    bpl ppu_vblank_wait1
    bit $2002
ppu_vblank_wait2:
    bit $2002
    bpl ppu_vblank_wait2
    bit $2002
ppu_vblank_wait3:
    bit $2002
    bpl ppu_vblank_wait3

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
    sta $5000

rawf=139
;Initialize the APU so we can make a debug beep
init_apu:
        ; Copy values into APU registers
        ldy #$13
@loop:  lda apu_regs,y
        sta $4000,y
        dey
        bpl @loop
        ; We have to skip over $4014 (OAMDMA)
        lda #$0f
        sta $4015
        lda #$40
        sta $4017
        ;Turn on a channel for a boot-up beep
        lda #<rawf
        sta $4002
        lda #>rawf
        sta $4003
        lda #%10111111
        sta $4000

;Set background palette values
;Universal background = black
    lda #$3f
    sta $2006
    lda #$00
    sta $2006
    lda #$20
    sta $2007
;Palette 1
    lda #$3f
    sta $2006
    lda #$01
    sta $2006
    lda #$20
    sta $2007
;Palette 2
    lda #$3f
    sta $2006
    lda #$02
    sta $2006
    lda #$1d
    sta $2007
;Palette 3
    lda #$3f
    sta $2006
    lda #$03
    sta $2006
    lda #$1d
    sta $2007

;Fill attribute tables to all be palette zero
    ldx #128
write_attr_top:
    lda #$23
    sta $2006
    txa
    clc
    adc #$BF
    sta $2006
    lda #$00
    sta $2007
    dex
    bne write_attr_top

;Wait for VBLANK
:
    bit $2002
    bpl :-
;Fill the screen with blank tiles
    lda #$20
    sta $2006
    lda #$00
    sta $2006
    ldx #$3C
    lda #$3F
:
    sta $2007
    sta $2007
    sta $2007
    sta $2007
    sta $2007
    sta $2007
    sta $2007
    sta $2007
    sta $2007
    sta $2007
    sta $2007
    sta $2007
    sta $2007
    sta $2007
    sta $2007
    sta $2007
    dex
    bne :-

;Initialize text mode
    jsr char_io_init_screen

;Turn off beep
    lda #$00
    sta $4000
;Print startup banner
    lda #<boot_message
    sta $03
    lda #>boot_message
    sta $04
    jsr char_io_printstr
;Init floppy and try to boot
    jsr floppy_init
    jsr system_startup
    jmp monitor_start

.global mon_wait
mon_wait:
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

.global load_next_sector
load_next_sector:
    lda cur_track
    sta r0
    lda cur_sector
    sta r1
    lda #<global_bios_sector_buffer
    sta r2
    lda #>global_bios_sector_buffer
    sta r3
    jsr floppy_sector_buffer_load
    lda r15 ;TODO: this is currently a global success flag for floppy read that needs to be done better
    bne next_sector_done
    inc cur_sector
    lda cur_sector
    cmp #$10
    bne next_sector_done
    lda #$00
    sta cur_sector
    jsr floppy_step_forward
next_sector_done:
    rts

.global load_boot_sector
load_boot_sector:
    jsr load_next_sector
    lda r15
    beq load_boot_sector_exit
    jsr floppy_off
    lda #<read_error_message
    sta string_pointer
    lda #>read_error_message
    sta string_pointer+1
    jsr char_io_printstr
    jmp monitor_start
load_boot_sector_exit:
    rts
    
boot_message:
    .asciiz "LOADING..."

read_error_message:
    .asciiz "READ ERROR"

irq_brk_handle:
    rti
   
apu_regs:
    .byte $30,$08,$00,$00
    .byte $30,$08,$00,$00
    .byte $80,$00,$00,$00
    .byte $30,$00,$00,$00
    .byte $00,$00,$00,$00

.segment "CALL_TABLE"
jsr char_io_printstr          ;FFC0
rts
jsr char_io_printchr          ;FFC4
rts
jsr char_io_init_keyboard     ;FFC8 
rts
jsr load_next_sector          ;FFCC
rts
jmp monitor_start             ;FFD0
rts
jsr floppy_sector_buffer_load ;FFD4 
rts
jsr mon_wait                  ;FFD8
rts
jsr char_io_getkey            ;FFDC
rts
jsr monitor_start             ;FFE0 - temporary fail-if-tried (used to be direct read sector call we don't want to expose anymore)
rts
jsr floppy_init               ;FFE4
rts
jsr floppy_off                ;FFE8
rts
jsr floppy_on                 ;FFEC
rts
.byte "NES"                   ;FFF0

.segment "VECTORS"
.word $0000
.word entry
.word irq_brk_handle

