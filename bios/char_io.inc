.ifndef char_io_inc
    char_io_inc = 1

    SCREEN_ADDR = $00
    STRING_PTR = $03
    IS_SCROLLING = $05
    SCROLL_VALUE = $06
    SHIFT_OFFSET = $07
    CURRENT_KB_ROW = $08
    KEY_WAS_FOUND = $09
    LAST_KB_BIT = $0A
    LAST_PRESSED_KEY = $0B

    chrin_buffer      = $0240   ; chrin is a 16-char ring buffer for storing typed but unread chars
    chrout_buffer     = $0250   ; chrout is a 16-char ring buffer for storing written but undisplayed chars
    key_matrix_buffer = $0260   ; 6-byte buffer holding last read state of the keyboard matrix
    chrin_read_ptr    = $50
    chrin_write_ptr   = $51
    chrout_read_ptr   = $53
    chrout_write_ptr  = $54

    .GLOBAL INITKEYBOARD
    .GLOBAL PRNTCHR
    .GLOBAL PRINTSTR
    .GLOBAL GETKEY
    .GLOBAL render_character
.endif
