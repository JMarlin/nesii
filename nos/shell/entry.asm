.segment "ENTRY"
.include "command_processor.inc"
jmp nos_startup

.segment "CODE"
nos_startup:
    jmp command_processor_entry
