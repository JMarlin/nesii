.segment "BOOT_INIT"

CART_SWITCHES    = $d000
INITKEYBOARD     = $f427
LOAD_NEXT_SECTOR = $e27f
IWM_MOTOR_OFF    = $c088
ENTER_MONITOR    = $f2e5
PRINTSTR         = $f4f7
PRNTCHR          = $f489
GETKEY           = $f441
STRING_PTR       = $03
data_ptr         = $26
TEXT_BUFFER      = $0400
TEXT_INDEX       = $50
CMP_STRING       = $51
CUR_CMD_INDEX    = $53
COMMAND_ADDRESS  = $54

boot_sector_start:

ldy #$00
move_bootsect:
    lda $0400,Y
    sta $8000,Y
    iny
    bne move_bootsect

jmp $800E ;This is new_entry at the new location

new_entry:
    lda #<MESSAGE
    sta STRING_PTR
    lda #>MESSAGE
    sta STRING_PTR+1
    jsr PRINTSTR

load_boot_tracks:
    lda #$00
    sta data_ptr
    lda #$81
    sta data_ptr+1
get_next_boot_track:
    jsr LOAD_NEXT_SECTOR
    inc data_ptr+1
    lda data_ptr+1
    cmp #$90
    bne get_next_boot_track

    jmp boot_tracks_start

MESSAGE:
    .byte $0A, $0D
    .byte "READING NOS DATA..."
    .byte $00

.segment "BOOT_CODE"

boot_tracks_start:

    lda IWM_MOTOR_OFF

    jsr INITKEYBOARD

    lda #<MESSAGE_2
    sta STRING_PTR
    lda #>MESSAGE_2
    sta STRING_PTR+1
    jsr PRINTSTR

prompt_loop:
    lda #<PROMPT
    sta STRING_PTR
    lda #>PROMPT
    sta STRING_PTR+1
    jsr PRINTSTR
    ldy #$00
    sta TEXT_BUFFER
    sty TEXT_INDEX
type_loop:
    jsr GETKEY
    cmp #$0D
    bne stash_character
    lda #$00
    ldy TEXT_INDEX
    sta TEXT_BUFFER,Y
    jsr process_command
    clc
    bcc prompt_loop
stash_character:
    ldy TEXT_INDEX
    sta TEXT_BUFFER,Y
    iny
    sty TEXT_INDEX
    jsr PRNTCHR
    clc
    bcc type_loop

compare_cmd:
    ldy #$00
compare_next_char:
    lda TEXT_BUFFER,Y
    cmp (CMP_STRING),Y
    bne compare_cmd_no_match
    iny
    cmp #$00
    bne compare_next_char
    lda #$01
    rts
compare_cmd_no_match:
    lda #$00
    rts

process_command:
    ldy #$FF
next_command:
    iny
    ;Load string ptr LSB
    lda COMMAND_TABLE,Y
    sta CMP_STRING
    ;Load string ptr MSB
    iny 
    lda COMMAND_TABLE,Y
    beq process_command_no_match
    sta CMP_STRING+1
    sty CUR_CMD_INDEX
    jsr compare_cmd
    ldy CUR_CMD_INDEX
    cmp #$00
    bne exec_cmd
    iny
    iny
    clc
    bcc next_command
exec_cmd:
    iny
    lda COMMAND_TABLE,Y
    sta COMMAND_ADDRESS
    iny
    lda COMMAND_TABLE,Y
    sta COMMAND_ADDRESS+1
    jmp (COMMAND_ADDRESS)
process_command_no_match:
    lda #<UNKNOWN_COMMAND_STR
    sta STRING_PTR
    lda #>UNKNOWN_COMMAND_STR
    sta STRING_PTR+1
    jsr PRINTSTR
    rts

COMMAND_TABLE:
    .word HELLO_STR
    .word HELLO_CMD
    .word MON_STR
    .word MON_CMD
    .word $0000

HELLO_CMD:
    lda #<HI_MESSAGE
    sta STRING_PTR
    lda #>HI_MESSAGE
    sta STRING_PTR+1
    jsr PRINTSTR
    rts

MON_CMD:
    jmp ENTER_MONITOR

MESSAGE_2:
    .byte "DONE", $0A, $0D
    .byte "WELCOME TO NOS 0.0.1", $00

PROMPT:
    .byte $0A, $0D
    .byte "N] ", $00

UNKNOWN_COMMAND_STR:
    .byte $0A, $0D
    .byte "UNKNOWN COMMAND", $00

HI_MESSAGE:
    .byte $0A, $0D, "HI TO YOU!", $00

HELLO_STR:
    .byte "HELLO", $00

MON_STR:
    .byte "MON", $00
