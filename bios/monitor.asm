.segment "CODE"
.include "monitor.inc"
.include "char_io.inc"

; C'mon, the Compact MONitor
; written by Bruce Clark and placed in the public domain
;
; minor tweaks and porting by Ed Spittles
; port to NESII by Joe Marlin
;
; To the extent possible under law, the owners have waived all
; copyright and related or neighboring rights to this work. 
;
; retrieved from http://www.lowkey.comuf.com/cmon.htm
; archived documentation at http://biged.github.io/6502-website-archives/lowkey.comuf.com/cmon.htm
;
; ported to ca65 from dev65 assembler
; /opt/cc65/bin/ca65 --listing -DSINGLESTEP cmon.a65 
; /opt/cc65/bin/ld65 -t none -o cmon.bin cmon.o
;
; ported to 6502 from 65Org16
; ported to a6502 emulator

width  = 4         ;must be a power of 2
height = 20

.macro putc
       tax
       tya
       pha
       php
       txa
       pha
       jsr char_io_printchr
       pla
       tax
       plp 
       pla
       tay
       txa
.endmacro

.macro getc
       tya
       pha
       php
       jsr char_io_getkey
       tax
       PLP
       pla
       tay
       txa
.endmacro

dump_byte:
       ldy #$00
       lda (address),Y
       jsr print_hex
       inc address
       bne mon_2
       inc address+1
       jmp mon_2

.global monitor_start
monitor_start:
       jsr char_io_init_keyboard
mon:
       cld
mon_1:
       jsr print_cr
       lda #$2d       ;output dash prompt
       putc
mon_2:
       lda #0
       sta number+1
       sta number
mon_3:
       and #$0f
mon_4:
       ldy #4         ;accumulate digit
mon_5:
       asl number
       rol number+1
       dey
       bne mon_5
       ora number
       sta number
mon_6:
       getc
       cmp #$0d
       beq mon_1         ;branch if cr
;
; Insert additional store_commandnds for characters (e.g. control characters)
; outside the range $20 (space) to $7E (tilde) here
;
       cmp #$20       ;don't output if outside $20-$7E
       bcc mon_6
       cmp #$7f
       bcs mon_6
       putc
       cmp #$2c
       beq store_command
       cmp #'+'
       beq set_address_command
       cmp #'/'
       beq dump_byte
;
; Insert additional store_commandnds for non-letter characters (or case-sensitive
; letters) here
;
; now dealing with letters
       eor #$30
       cmp #$0A
       bcc mon_4         ;branch if digit
       ora #$20       ;convert to upper case
       sbc #$77
;
; mapping:
;   A-F -> $FFFA-$FFFF
;   G-O -> $0000-$0008
;   P-Z -> $FFE9-$FFF3
;
       beq user_jump_command
       cmp #$FA ; #$FA or #$FFFA
       bcs mon_3
;
; Insert additional store_commandnds for (case-insensitive) letters here
;
       cmp #$f1 ; #$F1 or  #$FFF1
       bne mon_6
dump_memory_command:
       jsr print_cr
       tya
       pha
       clc            ;output address
       adc number
       pha
       lda #0
       adc number+1
       jsr print_hex
       pla
       jsr print_hex_and_space
dump_memory_command_1:
       lda (number),Y ;output hex bytes
       jsr print_hex_and_space
       iny
       tya
       and #width-1
       bne dump_memory_command_1
       pla
       tay
dump_memory_command_2:
       lda (number),Y ;output characters
       and #$7f
       cmp #$20
       bcc dump_memory_command_3
       cmp #$7f
       bcc dump_memory_command_4
dump_memory_command_3:
       eor #$40
dump_memory_command_4:
       putc
       iny
       tya
       and #width-1
       bne dump_memory_command_2
       cpy #width*height
       bcc dump_memory_command
mon_2_jump:
       jmp mon_2		; branches out of range for 6502 when putc is 3 bytes
store_command:
       lda number
       sta (address),Y
       inc address
       bne mon_2_jump
       inc address+1
       bcs mon_2_jump
set_address_command:
       lda number
       sta address
       lda number+1
       sta address+1
       bcs mon_2_jump
user_jump_command:
       jsr user_jump_command_1
       jmp mon_2		; returning after a 'go'
user_jump_command_1:
       jmp (number)
print_hex:
       ;jsr print_hex_1		; for 16-bit bytes
print_hex_1:
       jsr print_hex_2
print_hex_2:
       asl
       adc #0
       asl
       adc #0
       asl
       adc #0
       asl
       adc #0
       pha
       and #$0f
       cmp #$0a
       bcc print_hex_3
       adc #$66
print_hex_3:
       eor #$30
       putc
       pla
       rts
print_hex_and_space:
       jsr print_hex
       lda #$20
print_lf:
       putc
       rts
print_cr:
       lda #$0d
       putc
       lda #$0a
       bne print_lf        ;always

label_nmi:
        .byte 1,2
 
label_reset:
        .word monitor_start

label_irq_brk:
        .byte 5,6
        
label_end:
