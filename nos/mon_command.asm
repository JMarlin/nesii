.segment "CODE"
.include "rom_constants.inc"

.global MON_CMD_STR
MON_CMD_STR: .asciiz "MON"

.global MON_CMD_ENTRY
MON_CMD_ENTRY:
    jmp enter_monitor
