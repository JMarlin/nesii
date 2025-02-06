		.segment "HEADER"
.ifdef KBD
        jmp     LE68C
        .byte   $00,$13,$56
.endif
        jmp     COLD_START
        jmp     RESTART
        .word   AYINT,GIVAYF
.ifdef SYM1
        jmp     PR_WRITTEN_BY
.endif
