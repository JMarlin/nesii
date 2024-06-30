.segment "CODE"
.include "rom_constants.inc"
.include "hello_command.inc"
.include "mon_command.inc"
.include "dir_command.inc"

.global command_processor_entry
command_processor_entry:

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
    .word HELLO_CMD_STR, HELLO_CMD_ENTRY
    .word MON_CMD_STR,   MON_CMD_ENTRY
    .word DIR_CMD_STR,   DIR_CMD_ENTRY
    .word $0000

MESSAGE_2:
    .byte "DONE", $0A, $0D
    .byte "WELCOME TO NOS 0.0.1", $00

PROMPT:
    .byte $0A, $0D
    .byte "N] ", $00

UNKNOWN_COMMAND_STR:
    .byte $0A, $0D
    .byte "UNKNOWN COMMAND", $00

MON_STR:
    .byte "MON", $00
