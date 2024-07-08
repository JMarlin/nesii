.segment "CODE"
.include "console.inc"
.include "fs.inc"

.global run_cmd_str
run_cmd_str: .asciiz "RUN"

.global run_cmd_entry
run_cmd_entry:

    ;X contains offset into the command buffer of the passed application name
    ;fs_find_file expects a filename pointer in A:X
    lda #>text_buffer
    jsr fs_find_file

    ;fs_find_file returns pointer to file info block in A:X, null if not found
    cmp #$00
    bne run_cmd_file_exists
    tay
    txa
    cmp #$00
    bne run_cmd_file_exists

    ;Null pointer returned, file not found
    lda #<file_not_found_message
    sta string_ptr
    lda #>file_not_found_message
    sta string_ptr+1
    jsr console_prints

    rts
    
run_cmd_file_exists:
    lda #<file_found_message
    sta string_ptr
    lda #>file_found_message
    sta string_ptr+1
    jsr console_prints

    rts

file_found_message:
    .byte $0a, $0d, "FILE FOUND", $00

file_not_found_message:
    .byte $0a, $0d, "FILE NOT FOUND", $00