.segment "CODE"
.include "../globals.inc"
.include "console.inc"
.include "hello_command.inc"
.include "mon_command.inc"
.include "dir_command.inc"
.include "echo_command.inc"
.include "run_command.inc"

.global command_processor_entry
command_processor_entry:

    jsr console_init
    print startup_message

prompt_loop:

    print prompt

    ldy #$00
    sta text_buffer
    sty text_index
type_loop:
    jsr getc
    cmp #$0d
    bne stash_character
    lda #$00
    ldy text_index
    sta text_buffer,y
    jsr process_command
    clc
    bcc prompt_loop
stash_character:
    ldy text_index
    sta text_buffer,y
    iny
    sty text_index
    jsr printc
    clc
    bcc type_loop

compare_cmd:
    ldy #$ff
compare_next_char:
    iny
    lda text_buffer,y
    cmp (cmp_string),y
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
    lda text_buffer,y
    cmp #$20
    beq process_fixup_space
    cmp #$00
    bne process_space_check
    beq process_command_continue
process_fixup_space:
    lda #$00
    sta text_buffer,Y
    iny
process_command_continue:
    tya
    tax ;Stash pointer to arguments
    ldy #$FF
next_command:
    iny
    ;Load string ptr LSB
    lda command_table,y
    sta cmp_string
    ;Load string ptr MSB
    iny 
    lda command_table,y
    beq process_command_no_match
    sta cmp_string+1
    sty cur_cmd_index
    jsr compare_cmd
    ldy cur_cmd_index
    cmp #$00
    bne exec_cmd
    iny
    iny
    clc
    bcc next_command
exec_cmd:
    iny
    lda command_table,y
    sta command_address
    iny
    lda command_table,y
    sta command_address+1
    stx r0
    lda #>text_buffer
    sta r1
    jmp (command_address) ;Note: Callee should expect pointer to args in r1:r0

process_command_no_match:
    print unknown_command_message
    print text_buffer
    rts

command_table:
    .word hello_cmd_str, hello_cmd_entry
    .word mon_cmd_str,   mon_cmd_entry
    .word dir_cmd_str,   dir_cmd_entry
    .word echo_cmd_str,  echo_cmd_entry
    .word run_cmd_str,   run_cmd_entry
    .word $0000

startup_message:
    .byte $0a, $0d, " NOS 0.0.2", $00

prompt:
    .byte $0a, $0d
    .byte " N]", $00

unknown_command_message:
    .byte $0A, $0D
    .byte " UNKNOWN COMMAND ", $00
