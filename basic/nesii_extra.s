MONRDKEY:
  sty $0700
  stx $0701
  jsr $FFDC
  ldx $0701
  ldy $0700
  rts

MONCOUT:
  sty $0700
  stx $0701
  jsr $FFC4
  ldx $0701
  ldy $0700
  rts
 
