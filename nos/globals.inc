.ifndef globals_inc
    globals_inc = 1

    general_pointer  = $c0
    string_ptr       = $03
    data_ptr         = $26
    sector           = $3d
    track            = $41
    text_buffer      = $0400
    sector_buffer    = $0300
    text_index       = $50
    cmp_string       = $51
    cur_cmd_index    = $53
    command_address  = $54

    fixed_file_info_ptr  = $00e0
    open_file_info_ptr_0 = $60
    sector_buffer_loaded_track  = $62
    sector_buffer_loaded_sector = $63

    ;The following zero-page locations are reserved
    ;for local use by subroutines
    r0  = $d0
    r1  = $d1
    r2  = $d2
    r3  = $d3
    r4  = $d4
    r5  = $d5
    r6  = $d6
    r7  = $d7
    r8  = $d8
    r9  = $d9
    r10 = $da
    r11 = $db
    r12 = $dc
    r13 = $dd
    r14 = $de
    r15 = $df
.endif
