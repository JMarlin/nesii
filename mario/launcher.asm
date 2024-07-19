.segment "CODE"
.include "../nos/globals.inc"
.include "../nos/nos_calls.inc"

.global launcher_entry
launcher_entry:
    ;Load the first prg block to $8000
    lda #<prg0_str
    sta r0
    lda #>prg0_str
    sta r1
    jsr binary_loader_load
    ;Switch low cart RAM mapping
    lda #$02
    sta $d000
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
    sta $d000
    jmp ($fffc)

prg0_str:
    .asciiz "MPD0"

prg1_str:
    .asciiz "MPD1"

chr_str:
    .asciiz "MCD"