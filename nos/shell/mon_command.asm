.segment "CODE"
.include "../rom_constants.inc"

.global mon_cmd_str
mon_cmd_str: .byte "MON", $00

.global mon_cmd_entry
mon_cmd_entry:
    jmp enter_monitor
