.ifndef char_io_inc
    char_io_inc = 1

    screen_addr             = $00
    string_ptr              = $03
    is_scrolling            = $05
    scroll_value            = $06
    current_keyboard_column = $07
    current_keyboard_row    = $08
    key_was_found           = $09
    last_keyboard_hit       = $0a
    last_pressed_key        = $0b

    .global char_io_init_keyboard
    .global char_io_printchr
    .global char_io_printstr
    .global char_io_getkey
    .global char_io_init_screen
.endif