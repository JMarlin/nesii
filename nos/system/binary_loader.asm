.segment "CODE"
.include "fs.inc"
.include "../../bios/globals.inc"

.global binary_loader_load
binary_loader_load:
    ;Stash registers that we clobber
    lda r2
    pha
    lda r3
    pha
    ;Back up file name pointer
    lda r0
    sta r2
    lda r1
    sta r3
    ;r1:r0 contains pointer to argument string
    ;fs_find_file expects filename pointer in r1:r0
    jsr fs_find_file
    ;fs_find_file returns pointer to file info block in r1:r0, null if not found
    lda r0
    cmp #$00
    bne binary_loader_load_file_exists
    lda r1
    cmp #$00
    bne binary_loader_load_file_exists
    ;Null pointer returned, file not found
    ;We're expected to return the entry address in r1:r0,
    ;so we're just passing on the existing null there
    jmp binary_loader_load_exit
binary_loader_load_file_exists:
;Check file type and bomb out if it's not a binary
    ldy #$02
    lda (r0),y
    and #$04
    bne binary_loader_load_load_content
    ;Return null in r1:r0
    sta r1
    sta r0
    jmp binary_loader_load_exit
binary_loader_load_load_content:
    ;Restore the argument pointer and open the file
    lda r2
    sta r0
    lda r3
    sta r1
    jsr fs_open_file
    ;Get and stash file load address
    jsr fs_read_file_byte
    lda r1
    pha
    sta r2
    jsr fs_read_file_byte
    lda r1
    pha
    sta r3
    ;Get the file load size
    jsr fs_read_file_byte
    lda r1
    pha
    jsr fs_read_file_byte
    pla
    sta r0
    ;Calculate end-of-load address into r1:r0
    clc
    lda r0
    adc r2
    sta r0
    lda r1
    adc r3
    sta r1
;Copy data to the load address
binary_loader_load_store_next_byte:
    lda r1
    pha
    lda r0
    pha
    jsr fs_read_file_byte
    lda r1
    ldy #$00
    sta (r2),y
    pla
    sta r0
    pla
    sta r1
    inc r2
    bne binary_loader_load_skip_r3_increment
    inc r3
binary_loader_load_skip_r3_increment:
    lda r0
    cmp r2
    bne binary_loader_load_store_next_byte
    lda r1
    cmp r3
    bne binary_loader_load_store_next_byte
;Pull the load address and pass it back to the caller
    pla
    sta r1
    pla
    sta r0
binary_loader_load_exit:
    ;restore clobbered registers
    pla
    sta r3
    pla
    sta r2
    rts
