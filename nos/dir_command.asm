.segment "CODE"
.include "fs.inc"
.include "console.inc"

dir_str_ptr = $c2

.global DIR_CMD_STR
DIR_CMD_STR: .asciiz "DIR"

.global DIR_CMD_ENTRY
DIR_CMD_ENTRY:

    lda #$0A
    jsr console_printc
    lda #$0D
    jsr console_printc

    ldx #<dir_print_name
    lda #>dir_print_name
    jsr fs_scan_catalog

    lda #$0A
    jsr console_printc
    lda #$0D
    jsr console_printc

;TODO: Someday, do error handling
    rts


dir_print_name:

    stx dir_str_ptr
    sta dir_str_ptr+1

    lda #$0A
    jsr console_printc
    lda #$0D
    jsr console_printc
    lda #$20
    jsr console_printc
    lda #$20
    jsr console_printc

    ldy #$03

dir_print_name_next_char:
    tya
    pha
    lda (dir_str_ptr),Y
    and #$7F
    jsr console_printc
    pla
    cmp #$1A
    beq dir_print_name_done
    tay
    iny
    bne dir_print_name_next_char

dir_print_name_done:
    lda #$01
    rts