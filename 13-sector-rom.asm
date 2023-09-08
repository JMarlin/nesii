bits = $3c
MONITOR_ENTRY = $e147

.SEGMENT "CODE_MAIN"

.GLOBAL READ_SECTOR
READ_SECTOR:
          LDX #$20
          LDY #$00
LC604:    LDA #$03
          STA bits
          CLC
          DEY
          TYA
LC60B:    BIT bits
          BEQ LC604
          ROL bits
          BCC LC60B
          CPY #$D5
          BEQ LC604
          DEX
          TXA
          STA $0400,Y
          BNE LC604
          LDA #$C6
          PHA
          ASL A
          ASL A
          ASL A
          ASL A
          STA $2B
          TAX
          LDA #$D0
          PHA
          LDA $C08E,X
          LDA $C08C,X
          LDA $C08A,X
          LDA $C089,X
          LDY #$50
LC63E:    LDA $C080,X
          TYA
          AND #$03
          ASL A
          ORA $2B
          TAX
          LDA $C081,X
          LDA #$60
          JSR MON_WAIT
          DEY
          BPL LC63E
          LDA #$03
          STA $27
          LDA #$00
          STA $26
          STA $3D
LC65D:    CLC
LC65E:    PHP
LC65F:    LDA $C08C,X
          BPL LC65F
LC664:    EOR #$D5
          BNE LC65F
LC668:    LDA $C08C,X
          BPL LC668
          CMP #$AA
          BNE LC664
          NOP
LC672:    LDA $C08C,X
          BPL LC672
          CMP #$B5
          BEQ LC684
          PLP
          BCC LC65D
          EOR #$AD
          BEQ LC6A1
          BNE LC65D
LC684:    LDY #$03
          STY $2A
LC688:    LDA $C08C,X
          BPL LC688
          ROL A
          STA bits
LC690:    LDA $C08C,X
          BPL LC690
          AND bits
          DEY
          BNE LC688
          PLP
          CMP $3D
          BNE LC65D
          BCS LC65E
LC6A1:    LDY #$9A
LC6A3:    STY bits
LC6A5:    LDY $C08C,X
          BPL LC6A5
          EOR $0400,Y
          LDY bits
          DEY
          STA $0400,Y
          BNE LC6A3
LC6B5:    STY bits
LC6B7:    LDY $C08C,X
          BPL LC6B7
          EOR $0400,Y
          LDY bits
          STA ($26),Y
          INY
          BNE LC6B5
LC6C6:    LDY $C08C,X
          BPL LC6C6
          EOR $0400,Y
          BNE LC65D
          RTS
          TAY
LC6D2:    LDX #$00
LC6D4:    LDA $0400,Y
          LSR A
          ROL $03CC,X
          LSR A
          ROL $0399,X
          STA bits
          LDA ($26),Y
          ASL A
          ASL A
          ASL A
          ORA bits
          STA ($26),Y
          INY
          INX
          CPX #$33
          BNE LC6D4
          DEC $2A
          BNE LC6D2
          CPY $0300
          BNE LC6FC
          JMP MONITOR_ENTRY ;$0301
LC6FC:    JMP $FF2D

MON_WAIT:
    sec                   ;2: Prepare to Subtract w/o Borrow
MON_WAIT2:
    pha                   ;3: Push Accumulator (Save on STACK)
MON_WAIT3:
    sbc   #1              ;2: Subtract w/o Borrow [A-Data-!C]
    bne   MON_WAIT3       ;2+ Loop Until (A=0) [5 cycles/iteration]
                          ;   ^[4 cycles/iteration when (A=0)]
    pla                   ;4: Pull Accumulator (Retrieve from STACK)
    sbc   #1              ;2: Subtract w/o Borrow [A-Data-!C]
    bne   MON_WAIT2       ;2+ Loop Until (A=0) [~5*(A)+12 cycles/it]
                          ;   ^[~5*(A)+11 cycles/it when (A=0)]
    rts                   ;6: Return to Caller
