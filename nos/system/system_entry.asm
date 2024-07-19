.segment "CODE"
.include "../globals.inc"
.include "../rom_constants.inc"
.include "binary_loader.inc"

.global system_startup
system_startup:
    lda #<shell_string
    sta r0
    lda #>shell_string
    sta r1
    jsr binary_loader_load
;TODO: Check to see if the page number returned was zero and bail if so
    jsr _shell_entry_trampoline
    jmp system_startup

_shell_entry_trampoline:
    jmp (r0)

shell_string:
    .asciiz "SHELL"
