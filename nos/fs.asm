.segment "CODE"
.include "floppy.inc"
.include "globals.inc"


;Expects A:X to contain a pointer to a callback routine
;Callback routine should expect pointer to file name in A:X
;and should return 0 in A to early exit or non-0 to continue
.global fs_scan_catalog
fs_scan_catalog:

    stx general_pointer
    sta general_pointer+1

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
    beq fs_catalog_chain_done
    tax
    ldy $9002
    lda sector_skew_table,y
    jsr floppy_read

    lda #$0B
    sta floppy_data_ptr

fs_entry_process:
    ldy #$00
    lda (floppy_data_ptr),y
    beq fs_entry_process_next

;Call back to the user with the entry pointer in A:X
    lda #$90
    ldx floppy_data_ptr
    jsr fs_callback_trampoline

;If callback returned 0, exit early
    cmp #$00
    beq fs_catalog_chain_done

fs_entry_process_next:
    lda floppy_data_ptr
    clc
    adc #$23
    sta floppy_data_ptr
    bne fs_entry_process
    beq fs_catalog_chain_next

fs_catalog_chain_done:
    jsr floppy_off

    rts


;Accepts pointer to file name in A:X
;Returns pointer to file info structure in A:X
.global fs_find_file
fs_find_file:
    lda #$00
    ldx #$00
    rts


fs_callback_trampoline:
    jmp (general_pointer)

sector_skew_table:
    .byte $00, $0d, $0b, $09, $07, $05, $03, $01, $0e, $0c, $0a, $08, $06, $04, $02, $0f