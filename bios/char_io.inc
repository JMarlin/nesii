.ifndef char_io_inc
    char_io_inc = 1

    SCREEN_ADDR = $00
    STRING_PTR = $03
    IS_SCROLLING = $05
    SCROLL_VALUE = $06
    SHIFT_OFFSET = $07
    CURRENT_KB_ROW = $08
    KEY_WAS_FOUND = $09
    LAST_KB_BIT = $0a
    LAST_PRESSED_KEY = $0b

    chrin_buffer      = $0240   ; chrin is an 8-char ring buffer for storing typed but unread chars
    chrout_buffer     = $0248   ; chrout is an 8-char ring buffer for storing written but undisplayed chars
    key_matrix_buffer = $0250   ; 6-byte buffer holding last read state of the keyboard matrix

    chrin_index_mask = $07
    chrin_read_index    = $50
    chrin_write_index   = $51

    chrout_index_mask = $07
    chrout_read_index   = $53
    chrout_write_index  = $54

    .GLOBAL INITKEYBOARD
    .GLOBAL PRNTCHR
    .GLOBAL PRINTSTR
    .GLOBAL GETKEY
    .global process_chrout_buffer
.endif
