.segment "CODE"
.include "../../bios/calls.inc"

.global mon_cmd_str
mon_cmd_str: .byte "MON", $00

.global mon_cmd_entry
mon_cmd_entry:
    jmp bios_enter_monitor
