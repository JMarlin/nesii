.segment "CODE"
.include "console.inc"
.include "fs.inc"
.include "floppy.inc"

.global run_cmd_str
run_cmd_str: .asciiz "RUN"

.global run_cmd_entry
run_cmd_entry:

    ;Stash registers that we clobber
    lda r0
    pha
    lda r1
    pha

    ;r1:r0 contains pointer to argument string
    ;fs_find_file expects filename pointer in r1:r0
    jsr fs_find_file

    ;fs_find_file returns pointer to file info block in r1:r0, null if not found
    lda r0
    cmp #$00
    bne run_cmd_file_exists
    tay
    txa
    lda r1
    cmp #$00
    bne run_cmd_file_exists

    ;Null pointer returned, file not found
    print file_not_found_message

    clc
    bcc run_cmd_entry_exit
    
run_cmd_file_exists:
    print file_found_message

;TODO: switch this to using some nice higher-level open and read routines

    ;Check file type and bomb out if it's not a binary
    ldy #$02
    lda (r0),y
    and #$04
    bne run_cmd_entry_load_content

    print file_not_binary_message

    clc
    bcc run_cmd_entry_exit

run_cmd_entry_load_content:
;TESTING: Dump the initial T/S sector of the found file
    lda #$00
    sta floppy_data_ptr
    lda #$90
    sta floppy_data_ptr+1
    ldy #$00
    lda (r0),y
    tax
    iny
    lda (r0),y
    jsr floppy_read

;TESTING: Load the first sector specified in the initial T/S sector
    lda #$00
    sta floppy_data_ptr
    lda #$90
    sta floppy_data_ptr+1
    lda $900C
    tax
    lda $900D
    jsr floppy_read

;TESTING: Grab and display the load address and size
    print file_address_message
    lda $9001
    jsr print_hex_byte
    lda $9000
    jsr print_hex_byte

    print file_size_message
    lda $9003
    jsr print_hex_byte
    lda $9002
    jsr print_hex_byte

;END TESTING

run_cmd_entry_exit:

    ;restore clobbered registers
    pla
    sta r1
    pla
    sta r0

    rts

file_found_message:
    .byte $0a, $0d, " FILE FOUND", $00

file_not_found_message:
    .byte $0a, $0d, " FILE NOT FOUND", $00

file_not_binary_message:
    .byte ", NOT A BIN!", $00

file_address_message:
    .byte $0a, $0d, " ADDR: ", $00

file_size_message:
    .byte $0a, $0d, " SIZE: ", $00
