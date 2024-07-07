.segment "CODE"
.include "rom_constants.inc"
.include "hello_command.inc"
.include "mon_command.inc"
.include "dir_command.inc"
.include "echo_command.inc"
.include "floppy.inc"

.global system_startup
system_startup:
    jsr floppy_init

.global command_processor_entry
command_processor_entry:

    jsr init_keyboard

    lda #<MESSAGE_2
    sta STRING_PTR
    lda #>MESSAGE_2
    sta STRING_PTR+1
    jsr prints

prompt_loop:

    lda #<PROMPT
    sta STRING_PTR
    lda #>PROMPT
    sta STRING_PTR+1
    jsr prints

    ldy #$00
    sta TEXT_BUFFER
    sty TEXT_INDEX
type_loop:
    jsr getc
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
    jsr printc
    clc
    bcc type_loop

compare_cmd:
    ldy #$ff
compare_next_char:
    iny
    lda TEXT_BUFFER,Y
    cmp (CMP_STRING),Y
    bne compare_cmd_no_match
    cmp #$00
    bne compare_next_char
    lda #$01
    rts
compare_cmd_no_match:
    lda #$00
    rts

process_command:
    ldy $ff
process_space_check:
    iny
    lda TEXT_BUFFER,Y
    cmp #$20
    beq process_fixup_space
    cmp #$00
    bne process_space_check
    beq process_command_continue
process_fixup_space:
    lda #$00
    sta TEXT_BUFFER,Y
    iny
process_command_continue:
    tya
    tax ;Stash pointer to arguments
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
    jmp (COMMAND_ADDRESS) ;Note: Callee should expect offset to any args in X

process_command_no_match:

    lda #<UNKNOWN_COMMAND_STR
    sta STRING_PTR
    lda #>UNKNOWN_COMMAND_STR
    sta STRING_PTR+1
    jsr prints

    lda #<TEXT_BUFFER
    sta STRING_PTR
    lda #>TEXT_BUFFER
    sta STRING_PTR+1
    jsr prints

    rts

COMMAND_TABLE:
    .word HELLO_CMD_STR, HELLO_CMD_ENTRY
    .word MON_CMD_STR,   MON_CMD_ENTRY
    .word DIR_CMD_STR,   DIR_CMD_ENTRY
    .word ECHO_CMD_STR,  ECHO_CMD_ENTRY
    .word $0000

MESSAGE_2:
    .byte "DONE", $0A, $0D
    .byte "WELCOME TO NOS 0.0.1", $00

PROMPT:
    .byte $0A, $0D
    .byte " N]", $00

UNKNOWN_COMMAND_STR:
    .byte $0A, $0D
    .byte "UNKNOWN COMMAND: ", $00

MON_STR:
    .byte "MON", $00
