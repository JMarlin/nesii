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

    jmp enter_monitor
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