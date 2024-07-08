.segment "CODE"
.include "fs.inc"
.include "console.inc"

dir_str_ptr = $c2

.global dir_cmd_str
dir_cmd_str: .asciiz "DIR"

.global dir_cmd_entry
dir_cmd_entry:

    lda #$0a
    jsr console_printc
    lda #$0d
    jsr console_printc

    ldx #<dir_print_name
    lda #>dir_print_name
    jsr fs_scan_catalog

    lda #$0a
    jsr console_printc
    lda #$0d
    jsr console_printc

;TODO: Someday, do error handling
    rts


dir_print_name:

    stx dir_str_ptr
    sta dir_str_ptr+1

    lda #$0a
    jsr console_printc
    lda #$0d
    jsr console_printc
    lda #$20
    jsr console_printc
    lda #$20
    jsr console_printc

    ldy #$03

dir_print_name_next_char:
    tya
    pha
    lda (dir_str_ptr),y
    and #$7f
    jsr console_printc
    pla
    cmp #$1a
    beq dir_print_name_done
    tay
    iny
    bne dir_print_name_next_char

dir_print_name_done:
    lda #$01
    rts