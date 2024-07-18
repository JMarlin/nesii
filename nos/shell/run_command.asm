.segment "CODE"
.include "console.inc"
.include "nos_calls.inc"

.global run_cmd_str
run_cmd_str: .asciiz "RUN"

.global run_cmd_entry
run_cmd_entry:
    ;Stash clobbered registers
    lda r0
    pha
    lda r1
    pha
    ;r1:r0 contains pointer to argument string
    ;binary_loader_load expects filename pointer in r1:r0
    jsr binary_loader_load
    ;Binary_loader_load returns the pointer to the binary
    ;entry in r1:r0
    ;Jump into the trampoline to execute it
    jsr _run_cmd_trampoline
run_cmd_entry_exit:
    ;Restore clobbered registers
    pla
    lda r1
    pla
    lda r0
    rts

_run_cmd_trampoline:
    jmp (r0)

file_not_found_message:
    .byte $0a, $0d, "NO SUCH BINARY", $00
