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
    lda r2
    pha
    lda r3
    pha

    ;Back-up the argument pointer
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
    bne run_cmd_file_exists
    tay
    lda r1
    cmp #$00
    bne run_cmd_file_exists

    ;Null pointer returned, file not found
    print file_not_found_message

    clc
    bcc run_cmd_entry_exit
    
run_cmd_file_exists:
    print file_found_message

;Check file type and bomb out if it's not a binary
    ldy #$02
    lda (r0),y
    and #$04
    bne run_cmd_entry_load_content

    print file_not_binary_message

    clc
    bcc run_cmd_entry_exit

run_cmd_entry_load_content:
    ;Restore the argument pointer
    lda r2
    sta r0
    lda r3
    sta r1
    jsr fs_open_file

;TESTING: Grab and display the load address and size
    print file_address_message
    jsr fs_read_file_byte
    lda r1
    sta r2
    jsr fs_read_file_byte
    lda r1
    jsr print_hex_byte
    lda r2
    jsr print_hex_byte

    print file_size_message
    jsr fs_read_file_byte
    lda r1
    sta r2
    jsr fs_read_file_byte
    lda r1
    jsr print_hex_byte
    lda r2
    jsr print_hex_byte
;END TESTING

run_cmd_entry_exit:

    ;restore clobbered registers
    pla
    sta r3
    pla
    sta r2
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
