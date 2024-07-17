.segment "CODE"
.include "fs.inc"
.include "console.inc"

dir_str_ptr = $c2

.global dir_cmd_str
dir_cmd_str: .asciiz "DIR"

.global dir_cmd_entry
dir_cmd_entry:

    ;Stash clobbered registers
    lda r0
    pha
    lda r1
    pha

    lda #$0a
    jsr console_printc
    lda #$0d
    jsr console_printc

    lda #<dir_print_name
    sta r0
    lda #>dir_print_name
    sta r1
    jsr fs_scan_catalog

    lda #$0a
    jsr console_printc
    lda #$0d
    jsr console_printc

;TODO: Someday, do error handling

    ;Restore clobbered registers
    pla
    sta r1
    pla
    sta r0

    rts


dir_print_name:

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
    lda (r4),y ;fs_scan_catalog passes entry pointer in r5:r4
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
    sta r0
    rts