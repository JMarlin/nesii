.segment "CODE"
.include "../nos/globals.inc"
.include "../nos/nos_calls.inc"

basic_cold_start = $e000
apple_ii_cout = $fded 
apple_ii_cr = $fd8e

.global launcher_entry
launcher_entry:
    ;Check for valid hardware
    lda $fff0
    cmp #'N'
    bne apple_ii_message
    lda $fff1
    cmp #'E'
    bne apple_ii_message
    lda $fff2
    cmp #'S'
    bne apple_ii_message

    ;Load the first prg block to $8000
    lda #<prg0_str
    sta r0
    lda #>prg0_str
    sta r1
    jsr binary_loader_load
    ;Switch low cart RAM mapping
    lda #$02
    sta $f000
    ;Load the second prg block to $8000
    lda #<prg1_str
    sta r0
    lda #>prg1_str
    sta r1
    jsr binary_loader_load
    ;Turn off rendering
    lda #$00
    sta $2001
    ;Initialize PPU starting write address
    sta $2006
    sta $2006
    ;Initialize the byte counter
    sta r2
    sta r3
    ;Load the chr block to CHR RAM
    lda #<chr_str
    sta r0
    lda #>chr_str
    sta r1
    jsr fs_open_file
write_next_chr_byte:
    jsr fs_read_file_byte
    lda r1
    sta $2007
    inc r2
    bne write_next_chr_byte
    inc r3
    lda r3
    cmp #$20
    bne write_next_chr_byte
;Everything should be loaded now, hop on into the cart
    lda #$01
    sta $f000
    jmp ($fffc)

apple_ii_message:
    ;Move cursor down one line
    jsr apple_ii_cr
    ldy #$00
apple_ii_message_loop:
    lda apple_ii_message_string,y
    beq apple_ii_enter_cold_start
    jsr apple_ii_cout
    iny
    clc
    bcc apple_ii_message_loop
apple_ii_enter_cold_start:
    jmp basic_cold_start

apple_ii_message_string:
    .byte 'T'+$80, 'H'+$80, 'I'+$80, 'S'+$80, ' '+$80, 'I'+$80, 'S'+$80, ' '+$80, 'A'+$80,  'N'+$80,  ' '+$80,  'N'+$80,  'E'+$80,  'S'+$80,  ' '+$80,  'G'+$80,  'A'+$80,  'M'+$80,  'E'+$80, $00

prg0_str:
    .asciiz "DPD0"

prg1_str:
    .asciiz "DPD1"

chr_str:
    .asciiz "DCD"
