.ifndef globals_inc
    globals_inc = 1

    general_pointer   = $c0
    string_ptr        = $03
    sector_buffer     = $0400

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
