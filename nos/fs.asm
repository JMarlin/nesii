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
    jsr floppy_on
    jsr floppy_motor_wait
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
    jsr floppy_off
fs_read_file_byte_exit:
    pla
    sta r1
    lda #$01
    sta r0
    rts


;Reset all of the internal accounting info for the open file
;back to the first byte in the stream
;Accepts an open file info pointer in r1:r0
;No return value, assumed to always work
.global fs_rewind_file
fs_rewind_file:
    ;Reset the active t/s list sector to the file's base t/s list sector
    ldy ofi_base_ts_sector_offset
    lda (r0),y
    ldy ofi_active_ts_sector_offset
    sta (r0),y
    ldy ofi_base_ts_track_offset
    lda (r0),y
    ldy ofi_active_ts_track_offset
    sta (r0),y
    ;Clear the file's current offset into the data buffer and current
    ;offset into the active T/S list entries
    lda #$00
    ldy ofi_current_byte_offset
    sta (r0),y
    ldy ofi_current_sector_offset
    sta (r0),y
    ;Look up the first T/S list TS entry and copy it into the active
    ;data sector TS address field
    rts


;Internal function for making sure the data buffer for the open file
;is popultated to match the currently active data sector speficied
;by the passed-in open file info
;Accepts zero-page address of an open file info pointer in r0
;No return value, assumed to always work
_fs_populate_sector_buffer:
    rts


;Accepts pointer to file name in r1:r0
;Opens the file globally, returns 0 in r0 on failure or 1 in r0 on success
.global fs_open_file
fs_open_file:
    ;Push clobbered registers
    lda r1
    pha
    ;Attempt to find the file from the passed-in name pointer
    jsr fs_find_file
    lda r0
    cmp #$00
    bne fs_open_file_exists
    lda r1
    cmp #$00
    bne fs_open_file_exists
    beq fs_open_file_exit
fs_open_file_exists:
    ;Make sure the open file info pointer is initialized to our
    ;current fixed file info block
    lda #<fixed_file_info_ptr
    sta open_file_info_ptr_0
    lda #>fixed_file_info_ptr
    sta open_file_info_ptr_0+1
    ;Stash initial T/S-list TS address in the open file info struct
    ldy #$00
    lda (r0),y
    ldy ofi_active_ts_track_offset
    sta (open_file_info_ptr_0),y
    ldy #$01
    lda (r0),y
    ldy ofi_active_ts_sector_offset
    sta (open_file_info_ptr_0),y
    lda #$ff
    ldy ofi_current_byte_offset
    sta (open_file_info_ptr_0),y
    ldy ofi_current_sector_offset
    sta (open_file_info_ptr_0),y
    ;Rewind the new file
    lda #open_file_info_ptr_0
    sta r0
    lda #$00
    sta r1
    jsr fs_rewind_file
    ;Make sure the file's initial buffer is loaded
    jsr _fs_populate_sector_buffer
    lda #$00
    sta r0
fs_open_file_exit:
    ;Restore clobbered registers
    pla
    sta r1
    rts


fs_callback_trampoline:
    jmp (r0)


