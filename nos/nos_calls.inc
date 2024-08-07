.ifndef nos_calls_inc
    nos_calls_inc = 1

    nos_calls_base = $6fee
    nos_call_slot_size = 3

    fs_scan_catalog    = nos_calls_base + (0 * nos_call_slot_size)
    fs_find_file       = nos_calls_base + (1 * nos_call_slot_size)
    fs_open_file       = nos_calls_base + (2 * nos_call_slot_size)
    fs_read_file_byte  = nos_calls_base + (3 * nos_call_slot_size)
    binary_loader_load = nos_calls_base + (4 * nos_call_slot_size)
.endif