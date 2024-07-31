.ifndef floppy_types_inc
    floppy_types_inc = 1

    global_bios_sector_buffer = $00c0

    ;Floppy sector buffer structure
    fsb_current_track_offset  = $00
    fsb_current_sector_offset = $01
    fsb_buffer_page_offset    = $02
.endif