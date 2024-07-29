.segment "CODE"
.include "../nos_calls.inc"
.include "../globals.inc"
.include "../system/console.inc"
.include "run_command.inc"
.include "bumload.inc"

bumload_load_bums:
    ;Stash clobbered registers
    lda r0
    pha
    lda r1
    pha
    ;Scan catalog and load any bums
    lda #<bumload_load_bums_callback
    sta r0
    lda #>bumload_load_bums_callback
    sta r1
    jsr fs_scan_catalog
    ;Restore clobbered registers
    pla
    sta r1
    pla
    sta r0
    rts

bumload_load_bums_callback:
;Start looking at the bytes at the filename offset (one less since we pre-increment)
    ldy #$02
bumload_load_bums_callback_reset_index:
    ldx #$ff
bumload_load_bums_callback_name_check_top:
    inx
    cpx #$05
    beq bumload_load_bums_callback_name_check_success
    iny
    cpy #$1a   ;Did we fall off the end of the filename string?
    beq bumload_load_bums_callback_name_check_fail
    lda (r4),y ;fs_scan_catalog passes entry pointer in r5:r4
    and #$7f   ;Apple DOS uses high-ASCII
    cmp bumload_bum_string,x
    beq bumload_load_bums_callback_name_check_top
    bne bumload_load_bums_callback_reset_index
bumload_load_bums_callback_name_check_success:
    ;TODO: Just set up r0 and r1 and call into the RUN command
    print bumload_found_a_bum_string
bumload_load_bums_callback_name_check_fail:
    lda #$01
    sta r0
    rts 

bumload_found_a_bum_string:
    .byte $0a, $0d, "FOUND UR BUM", $00

bumload_bum_string:
    .byte ".BUM", $20