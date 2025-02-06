; configuration
CONFIG_11 := 1

;CONFIG_PRINT_CR := 1 ; print CR when line end reached
;CONFIG_SAFE_NAMENOTFOUND := 1
CONFIG_SCRTCH_ORDER := 3
CONFIG_NO_LINE_EDITING := 1
;
; zero page
ZP_START1 = $60
ZP_START2 = $6A
ZP_START3 = $70
ZP_START4 = $7B
;
;;extra ZP variables
USR				:= $0050
;
;; inputbuffer
INPUTBUFFER     := $0200
;
;; constants
STACK_TOP		:= $F8
SPACE_FOR_GOSUB := $36
;CRLF_1 := CR
;CRLF_2 := $80
WIDTH			:= 30
WIDTH2			:= 14
;
;; memory layout
RAMSTART2	:= $B000
;
;; monitor functions
;MONRDKEY        := $FFDC
;MONCOUT         := $FFC4
;LF689			:= $F689
;LF800			:= $F800
;LF819			:= $F819
;LF828			:= $F828
;LF864			:= $F864
;TEX				:= $FB2F
;LFB40			:= $FB40
;LFD0C			:= $FD0C
;LFD6A			:= $FD6A
;LFECD			:= $FECD
;LFEFD			:= $FEFD
;
