.segment "CODE"
.include "fs.inc"
.include "../rom_constants.inc"
.include "console.inc"
.include "../globals.inc"


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
    lda #<sector_buffer
    sta data_ptr
    lda #>sector_buffer
    sta data_ptr+1
    ldx #$11
    lda #$00
    jsr floppy_read

fs_catalog_chain_next:
    ;Read the next catalog sector
    lda #<sector_buffer
    sta data_ptr
    lda #>sector_buffer
    sta data_ptr+1
    lda sector_buffer+1
    beq fs_catalog_chain_finished_exit
    tax
    lda sector_buffer+2
    jsr floppy_read

    lda #$0B
    sta data_ptr

fs_entry_process:
    ;Check for zero track number, which indicates empty record
    ldy #$00
    lda (data_ptr),y
    beq fs_entry_process_next
    ;Check for FF track number, which indicates deleted record
    tax
    inx
    beq fs_entry_process_next

;Call back to the user with the entry pointer in r5:r4

    ;Stash the register that will be clobbered with the retval
    lda r0
    pha

    lda #>sector_buffer
    sta r5
    lda data_ptr
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
    lda data_ptr
    clc
    adc #$23
    sta data_ptr
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


;Currently takes no arguments and reads the active t/s list sector indicated in
;open file 0 into the global sector buffer
;In the future, should accept an open file info pointer and use the t/s list address
;and sector buffer address from the open file info
_fs_load_active_ts_list_sector:
    lda #<sector_buffer
    sta data_ptr
    lda #>sector_buffer
    sta data_ptr+1
    ldy #ofi_active_ts_track_offset
    lda (open_file_info_ptr_0),y
    tax
    ldy #ofi_active_ts_sector_offset
    lda (open_file_info_ptr_0),y
    jsr floppy_read
    rts


;Expects a pointer to a sector buffer containing the loaded T/S list data in r1:r0
;Gets the current entry offset from open file info 0 and assigns the value to which it
;points to the active data sector fields of open file info 0
_fs_load_data_sector_address_from_loaded_ts_list:
    ldy #ofi_current_ts_entry_offset
    lda (open_file_info_ptr_0),y
    tay
    lda (r0),y
    tax
    iny
    lda (r0),y
    ldy #ofi_active_data_sector_offset
    sta (open_file_info_ptr_0),y
    ldy #ofi_active_data_track_offset
    txa
    sta (open_file_info_ptr_0),y
    rts


;No arguments, returns success(1)/failure(0) in r0 and byte value in r1
.global fs_read_file_byte
fs_read_file_byte:
    ;Set up r1:r0 as a base pointer into the data buffer
    lda #<sector_buffer
    sta r0
    lda #>sector_buffer
    sta r1
    ;Grab the current file info struct's byte cursor
    ldy #ofi_current_byte_offset
    lda (open_file_info_ptr_0),y
    ;Get the byte at the current cursor, stash on the stack for return on exit
    tay
    lda (r0),y
    pha
    ;Update the file info struct's byte cursor
    iny
    tya
    ldy #ofi_current_byte_offset
    sta (open_file_info_ptr_0),y
;If we didn't roll over, exit and return the read value
    cmp #$00
    bne fs_read_file_byte_exit
;Byte offset rolled over, time to load another sector
;Read in the current T/S list sector since we'll need it whether we're doing a normal sector load
;or whether we need to advance to the next T/S list sectors
;TODO: maintain a sector buffer per open file structure rather than globally
    jsr floppy_on
    jsr floppy_motor_wait
    jsr _fs_load_active_ts_list_sector
;Increment (by a word) and load the current T/S list entry index
    ldy #ofi_current_ts_entry_offset
    lda (open_file_info_ptr_0),y
    tax
    inx
    inx
    txa
    sta (open_file_info_ptr_0),y
    bne fs_read_file_byte_load_data ;If we didn't fall off the end of the sector, skip loading the next T/S list
;We ran out of T/S entries in the current T/S sector, time to grab the next one in the chain
    lda #$0C ;Reset the t/s list entry index to the first
    sta (open_file_info_ptr_0),y
    ;Grab the next t/s list address from the currently loaded t/s list
    ;Store it into the open file info and load it
    ldy #tsl_next_ts_track_offset
    lda (r0),y
    ldy #ofi_active_ts_track_offset
    sta (open_file_info_ptr_0),y
    ldy #tsl_next_ts_sector_offset
    lda (r0),y
    ldy #ofi_active_ts_sector_offset
    sta (open_file_info_ptr_0),y
;Check if the track number for the next T/S list sector was zero, indicating end-of-chain
    cmp #$00
    bne fs_read_file_byte_next_list_exists
    ;Hit end-of-ts-chain, return bad info
    pla
    lda #$00
    sta r0
    sta r1
    rts
fs_read_file_byte_next_list_exists:
    jsr _fs_load_active_ts_list_sector
fs_read_file_byte_load_data:
;Proceed to load the data sector based on the active entry in the loaded t/s list
    jsr _fs_load_data_sector_address_from_loaded_ts_list
    jsr _fs_populate_sector_buffer
fs_read_file_byte_exit:
    jsr floppy_off
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
    ;Stash clobbered registers
    lda r0
    pha
    lda r1
    pha
    ;Reset the active t/s list sector to the file's base t/s list sector
    ldy #ofi_base_ts_sector_offset
    lda (r0),y
    ldy #ofi_active_ts_sector_offset
    sta (r0),y
    ldy #ofi_base_ts_track_offset
    lda (r0),y
    ldy #ofi_active_ts_track_offset
    sta (r0),y
    ;Clear the file's current offset into the data buffer and current
    ;offset into the active T/S list entries
    lda #$00
    ldy #ofi_current_byte_offset
    sta (r0),y
    lda #$0C
    ldy #ofi_current_ts_entry_offset
    sta (r0),y
    ;Look up the first T/S list TS entry and copy it into the active
    ;data sector TS address field
    jsr floppy_on
    jsr floppy_motor_wait
    lda #<sector_buffer
    sta r0
    lda #>sector_buffer
    sta r1
    jsr _fs_load_active_ts_list_sector
    jsr _fs_load_data_sector_address_from_loaded_ts_list
    jsr _fs_populate_sector_buffer
    jsr floppy_off
    ;Restore clobbered registers
    pla
    sta r1
    pla
    sta r0
    rts


;Internal function for making sure the data buffer for the open file
;is popultated to match the currently active data sector speficied
;by the passed-in open file info
;Currently just always uses open file info 0
;No return value, assumed to always work
_fs_populate_sector_buffer:
    ldy #ofi_active_data_track_offset
    lda (open_file_info_ptr_0),y
    cmp sector_buffer_loaded_track
    beq _fs_populate_sector_buffer_check_sector
    bne _fs_populate_sector_buffer_load
_fs_populate_sector_buffer_check_sector:
    ldy #ofi_active_data_sector_offset
    lda (open_file_info_ptr_0),y
    cmp sector_buffer_loaded_sector
    beq _fs_populate_sector_buffer_exit
_fs_populate_sector_buffer_load:
    ldy #ofi_active_data_track_offset
    lda (open_file_info_ptr_0),y
    sta sector_buffer_loaded_track
    tax
    ldy #ofi_active_data_sector_offset
    lda (open_file_info_ptr_0),y
    sta sector_buffer_loaded_sector
    tay
    lda #<sector_buffer
    sta data_ptr
    lda #>sector_buffer
    sta data_ptr+1
    tya
    jsr floppy_read
_fs_populate_sector_buffer_exit:
    rts


;Accepts pointer to file name in r1:r0
;Opens the file globally, returns 0 in r0 on failure or 1 in r0 on success
.global fs_open_file
fs_open_file:
    ;Push clobbered registers
    lda r1
    pha
    ;TODO: Shouldn't need to clear this on every file open,
    ;      should be updated when we load T/S sectors and stuff as well
    lda #$00
    sta sector_buffer_loaded_sector
    sta sector_buffer_loaded_track
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
    ldy #ofi_base_ts_track_offset
    sta (open_file_info_ptr_0),y
    ldy #$01
    lda (r0),y
    ldy #ofi_base_ts_sector_offset
    sta (open_file_info_ptr_0),y
    ;Rewind the new file
    lda open_file_info_ptr_0
    sta r0
    lda open_file_info_ptr_0+1
    sta r1
    jsr fs_rewind_file
    lda #$00
    sta r0
fs_open_file_exit:
    ;Restore clobbered registers
    pla
    sta r1
    rts


fs_callback_trampoline:
    jmp (r0)


