MONRDKEY:
  sty $0700
  stx $0701
  jsr $FFDC
  ldx $0701
  ldy $0700

MONCOUT:
  sty $0700
  stx $0701
  sta $0702
  jsr $FFC4
  lda $0702
  ldx $0701
  ldy $0700
  rts
 
