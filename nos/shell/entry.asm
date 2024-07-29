.segment "ENTRY"
.include "command_processor.inc"
.include "bumload.inc"
jmp nos_startup

.segment "CODE"
nos_startup:
    jsr bumload_load_bums
    jmp command_processor_entry