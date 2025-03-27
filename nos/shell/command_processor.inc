.ifndef command_processor_inc
    command_processor_inc = 1

    .global command_processor_entry

    text_index       = $8000
    cmp_string       = $8001
    cur_cmd_index    = $8002
    command_address  = $8003
.endif
