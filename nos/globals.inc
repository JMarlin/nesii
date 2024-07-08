.ifdef globals_inc
.else

    globals_inc = 1

    general_pointer = $c0
    string_ptr      = $03
    data_ptr        = $26
    sector          = $3d
    track           = $41
    text_buffer     = $0400
    text_index      = $50
    cmp_string      = $51
    cur_cmd_index   = $53
    command_address = $54
    current_track   = $42
.endif
