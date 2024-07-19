.ifndef fs_inc
    fs_inc = 1

    .global fs_scan_catalog
    .global fs_find_file
    .global fs_open_file
    .global fs_read_file_byte
    .global fs_rewind_file

    ;Open file info structure
    ofi_base_ts_track_offset      = 0
    ofi_base_ts_sector_offset     = 1
    ofi_active_ts_track_offset    = 2
    ofi_active_ts_sector_offset   = 3
    ofi_active_data_sector_offset = 4
    ofi_active_data_track_offset  = 5
    ofi_current_byte_offset       = 6
    ofi_current_ts_entry_offset   = 7

    ;TS list sector structure
    tsl_next_ts_track_offset  = 1
    tsl_next_ts_sector_offset = 2
    tsl_first_ts_entry_offset = 12
.endif