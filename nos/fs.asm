.segment "CODE"
.include "floppy.inc"
.include "console.inc"
.include "globals.inc"


;Expects r1:r0 to contain a pointer to a callback routine and r3:r2
;to contain an arbitrary word value that will be submitted back to
;the callback
;Returns 0 in r0 if callback indicates exit or 1 otherwise
;Callback routine should expect pointer to file entry in r1:r0,
;and its own arbitrary word in r3:r2
;Callback should return 0 in r0 to early exit or non-0 to continue
.global fs_scan_catalog
fs_scan_catalog:

    ;Stash registers that we clobber
    lda r4
    pha
    lda r5
    pha

    jsr floppy_on
    jsr floppy_motor_wait

    ;Read the VTOC (track 0x11, sector 0x0) into a buffer for examination
    lda #$00
    sta floppy_data_ptr
    lda #$90
    sta floppy_data_ptr+1
    ldx #$11
    lda #$00
    jsr floppy_read

fs_catalog_chain_next:
    ;Read the next catalog sector
    lda #$00
    sta floppy_data_ptr
    lda #$90
    sta floppy_data_ptr+1
    lda $9001
    beq fs_catalog_chain_finished_exit
    tax
    lda $9002
    jsr floppy_read

    lda #$0B
    sta floppy_data_ptr

fs_entry_process:
    ldy #$00
    lda (floppy_data_ptr),y
    beq fs_entry_process_next

;Call back to the user with the entry pointer in r5:r4

    ;Stash the register that will be clobbered with the retval
    lda r0
    pha

    lda #$90
    sta r5
    lda floppy_data_ptr
    sta r4
    jsr fs_callback_trampoline

;If callback returned 0, exit early
    ldx r0
    pla 
    sta r0
    txa
    cmp #$00
    beq fs_catalog_chain_callback_exit

fs_entry_process_next:
    lda floppy_data_ptr
    clc
    adc #$23
    sta floppy_data_ptr
    bne fs_entry_process
    beq fs_catalog_chain_next

fs_catalog_chain_finished_exit:
    lda #$00
    sta r0
    beq fs_catalog_chain_done
fs_catalog_chain_callback_exit:
    lda #$01
    sta r0
fs_catalog_chain_done:
    jsr floppy_off

;Restore clobbered registers
    pla
    sta r5
    pla
    sta r4

    rts


;Accepts pointer to file name in r1:r0
;Returns pointer to file info structure in r1:r0, or null if not found
.global fs_find_file
fs_find_file:

    ;Push clobbered registers
    lda r2
    pha
    lda r3
    pha

    lda r0
    sta r2
    lda r1
    sta r3

    ;Iterate through all the files and check their names against what was passed
    lda #<fs_find_file_callback
    sta r0
    lda #>fs_find_file_callback
    sta r1
    jsr fs_scan_catalog

    lda r0
    cmp #$00
    beq fs_find_file_not_found
    ;Move returned file entry pointer back to the caller
    lda r2
    sta r0
    lda r3
    sta r1

    clc
    bcc fs_find_file_done

fs_find_file_not_found:
    lda #$00
    sta r0
    sta r1

fs_find_file_done:
    ;Restore clobbered registers
    pla
    sta r3
    pla
    sta r2

    rts


fs_find_file_callback:

    ;Push clobbered registers
    lda r7
    pha
    lda r6
    pha

    ;Set r7:r6 to point to the filename
    lda r4
    clc
    adc #$03
    sta r6
    lda r5
    adc #$00
    sta r7

    ldy #$ff
fs_find_file_callback_next_char:
    iny
    lda (r6),y ;Load character from file name
    and #$7f
    tax
    cmp #$20
    bne fs_find_file_callback_no_space_fixup
    lda #$00 ;Treat all spaces as potentially equivalent to end-of-string
fs_find_file_callback_no_space_fixup:
    cmp (r2),y ;Compare to character in command line argument
    bne fs_find_file_callback_double_check_space ;No, but maybe it's because we did a fixup
    cmp #$00 ;Is this the end of the command line string?
    bne fs_find_file_callback_next_char ;No, check next character

    ;They matched up to the end-of-string
    ;Set user data to the current file info pointer and exit early
    lda r4
    sta r2
    lda r5
    sta r3
    lda #$00
    sta r0
    clc
    bcc fs_find_file_exit

fs_find_file_callback_double_check_space:
    txa ;Restore the original pre-fixup filename character
    cmp (r2),y ;And check against the command line string again
    beq fs_find_file_callback_next_char

    ;Nope, still didn't match, time to bail
    lda #$01
    sta r0

fs_find_file_exit:

    ;Restore clobbered registers
    pla
    sta r6
    pla
    sta r7

    rts


;No arguments, returns success(1)/failure(0) in r0 and byte value in r1
;TODO: Currently doesn't traverse past the first T/S sector
.global fs_read_file_byte
fs_read_file_byte:
    lda #<sector_buffer
    sta r0
    lda #>sector_buffer
    sta r1
    ldy open_file_byte_offset
    lda (r0),y
    pha
    iny
    sty open_file_byte_offset
    bne fs_read_file_byte_exit
;Byte offset rolled over, read the next sector
;Read active file's first T/S sector
    lda #<sector_buffer
    sta floppy_data_ptr
    lda #>sector_buffer
    sta floppy_data_ptr+1
    ldx open_file_track
    lda open_file_sector
    jsr floppy_read
;Increment the open file's sector offset and load that sector
    lda #<sector_buffer
    sta floppy_data_ptr
    lda #>sector_buffer
    sta floppy_data_ptr+1
    inc open_file_sector_offset
    lda open_file_sector_offset
    clc
    asl
    clc
    adc #$0C
    tay
    lda (r0),y
    tax
    iny
    lda (r0),y
    jsr floppy_read
fs_read_file_byte_exit:
    pla
    sta r1
    lda #$01
    sta r0
    rts


;Accepts pointer to file name in r1:r0
;Opens the file globally, returns 0 in r0 on failure or 1 in r0 on success
.global fs_open_file
fs_open_file:
    jsr fs_find_file
    lda r0
    cmp #$00
    bne fs_open_file_exists
    lda r1
    cmp #$00
    bne fs_open_file_exists
    beq fs_open_file_exit
fs_open_file_exists:
    ldy #$00
    lda (r0),y
    sta open_file_track
    iny
    lda (r0),y
    sta open_file_sector
    lda #$ff
    sta open_file_byte_offset
    sta open_file_sector_offset
    jsr fs_read_file_byte
    ldy #$00
    sty open_file_byte_offset
    iny
    sty r0
fs_open_file_exit:
    rts


fs_callback_trampoline:
    jmp (r0)


