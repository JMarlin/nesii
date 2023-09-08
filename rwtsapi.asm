.SEGMENT "CODE_MAIN"

MONITOR_ENTRY = $E147

;ITEMS IN RWTS.ASM
.GLOBAL WRITADR
.GLOBAL RWTSBUF1
.GLOBAL SEEKABS
.GLOBAL WRITESEC
.GLOBAL POSTNB16
.GLOBAL READATA
.GLOBAL RDADDR
.GLOBAL PRENIBL
.GLOBAL DELAY

FRMTSEC = $4B
FRMTKCTR =$41
TRKPERDSK = $23
SYNCNTR = $45
HOLDAA = $3E
FRMTVOL = $41
TRK4DRV2 = $4F8
TRK4DRV1 = $478
DESTRK = $2A
MTROFF = $C088
PROSCRTH = $26
SECDSK = $2D
VOLDSK = $2F
TRKDSK = $2E
PRESTRK = $478
READCNTR = $578
DRVZPG = $35
SELDRV2 = $C08B
SELDRV1 = $C08A
MTRTIME = $46
PTR2DCT = $3C
MTRON = $C089
SLOTPG5 = $5F8
Q6L = $C08C
Q7L = $C08E
RSEEKCNT = $4F8
RECLBCNT = $6F8
PTR2IOB = $48

                                ; =================================
                                ; READ/WRITE TRACK/SECTOR (RWTS).
                                ; (ENTER WITH (Y)/(A) POINTING AT
                                ; RWTSS INPUT/OUTPUT BLOCK (IOB).
                                ; =================================
.GLOBAL RWTS
RWTS:


                STY PTR2IOB     ; SET UP A Z-PG PTR TO RWTSS IOB.
                STA PTR2IOB+1
                
                LDY #2          ; INITIALIZE CNTR FOR MAXIMUM
                STY RECLBCNT    ; NUMBER OF RECALIBRATION TRIES.
                LDY #4          ; INITIALIZE COUNTER FOR MAXIMUM
                STY RSEEKCNT    ; # OF RE-SEEKS BTWN RECALIBS.
                
                LDY #1          ; (Y) = INDEX TO RWTSS IOB.
                LDA (PTR2IOB),Y ; GET SLOT*16 FROM IOB IN (X), SO
                TAX             ; CAN USE IT TO INDEX BASE ADRS
                                ; FOR DRIVE FUNCTIONS.

                

                                ; CHK IF WANTED SLOT*16 = LAST SLOT*16?

                LDY #15         ; INDEX FOR VAL OF LAST SLOT USED.
                CMP (PTR2IOB),Y ; WANTED*16 VS LAST*16.
                BEQ SAMESLOT    ; SLOT WANTED=SLOT LAST ACCESSED.

                                ; WANT TO USE A DIFFERENT SLOT SO
                                ; RESET (X) BACK TO INDEX OLD SLOT
                                ; SO CAN TEST OLD MOTOR.

                TXA             ; SAVE SLOT*16 WANTED ON STK.
                PHA
                LDA (PTR2IOB),Y ; GET OLD SLOT*16 BACK.
                TAX             ; PUT IT IN (X) TO INDEX BASE ADRS.
                PLA             ; PUT SLOT*16 WANTED IN (A) AND
                PHA             ; KEEP IT SAVED ON STK.
                STA (PTR2IOB),Y ; UPDATE LAST-USED SLOT*16 FOR
                                ; NEXT TIME AROUND.

                                ; CHECK TO SEE IF LAST-USED DRIVE
                                ; ASSOC WITH LAST-USED SLOT IS
                                ; STILL SPINNING.  IF IT IS, WAIT
                                ; FOR IT TO STOP.

                LDA Q7L,X       ; PREP LATCH FOR INPUT.
CKSPIN:         LDY #8          ; SET CNTR TO INSURE AT LEAST 8 CKS
                LDA Q6L,X       ; STROBE LATCH TO READ.
CHKCHNG:        CMP Q6L,X       ; READ AGAIN & CMP TO LAST READ.
                BNE CKSPIN      ; DATA CHANGED, SO STILL SPINNING.
                DEY             ; NO CHANGE, SO CHK WITH SOME
                BNE CHKCHNG     ; DELAYS JUST TO MAKE SURE.

                                ; GET INDEX FOR SLOT WANTED.

                PLA             ; GET SLOT*16 BAK OFF STK & PUT IT
                TAX             ; IN (X) SO WE CAN NDX BASE ADRS.

                                ; CHECK TO SEE IF A DRIVE ASSOC
                                ; WITH SLOT WANTED IS STILL
                                ; SPINNING.  (AS SOON AS GET A
                                ; CHANGE, KNOW IT IS SPINNING.
                                ; IF NO CHANGE, CHK AT LEAST 8
                                ; TIMES TO BE CERTAIN IT IS OFF.)

SAMESLOT:       LDA Q7L,X       ; SET READ MODE.
                LDA Q6L,X       ; STROBE LATCH TO READ.
                
                LDY #8          ; SET CNTR FOR 8 CHKS IF NEEDED.
                
STRBAGN:        LDA Q6L,X       ; STROBE LATCH AGAIN.
                PHA             ; DELAY 14 MACHINE CYCLES.
                PLA
                
                PHA
                PLA
                
                STX SLOTPG5     ; SAVE SLOT*16 WANTED IN PAGE5.
                CMP Q6L,X       ; HAS DATA CHANGED YET?

                
                BNE DONETEST    ; YES - DATA CHANGED, SO SPINNING.
                DEY             ; NO - NO CHANGE, SEE IF CHKD
                                ; ENOUGH TIMES YET.
                BNE STRBAGN     ; CHK AT LEAST 8 TIMES.
                
DONETEST:       PHP             ; SAVE TEST RESULTS ON STK SO CAN
                                ; LATER CHK IF NEED EXTRA DELAY
                                ; OR NOT.

                                ; TURN MOTOR ON IN A DRIVE ASSOC
                                ; WITH SLOT WANTED (JUST IN CASE
                                ; IT WASNT ALREADY SPINNING).
                                ; NOTE:  THIS USES DRIVE WITH SAME
                                ; # AS LAST DRIVE USED.  THIS MAY
                                ; OR MAY NOT BE THE SPECIFIC DRIVE
                                ; # WE WANT.  HOWEVER, WE MUST USE
                                ; THIS INSTRUC TO SEND POWER VIA
                                ; THE CONTROLLER.  ONCE SWITCH IS
                                ; THROWN, WE CAN LATER RE-ROUTE
                                ; THAT POWER TO WHICHEVER DRIVE WE
                                ; WANT BY THROWING ANOTHER SWITCH
                                ; TO SELECT DRIVE1 OR DRIVE2.

                LDA MTRON,X     ; TURN MOTOR ON.

                                ; ESTABLISH Z-PAGE POINTERS TO
                                ; DEVICE CHARACTERISTIC TABLE &
                                ; RWTSS I/O BUFFER (SO WE CAN
                                ; USE Z-PAGE INDIRECT ADDRESSING):
                                ; IBDCTP --> PTR2DCT (3C,3D).
                                ; IBBUFP --> PTR2BUF (3E,3F).

                LDY #6
MOVPTRS:        LDA (PTR2IOB),Y ; GET PTRS FROM RWTSS IOB.
                STA PTR2DCT-6,Y ; PUT THEM IN Z-PAGE.  (":" USED
                INY             ; TO FORCE A 3-BYTE ZERO-PAGE ADR.)
                CPY #10         ; 4 BYTES TO COPY (6 TO 9).
                BNE MOVPTRS

                                ; CHECK DRIVE STATUS.

                
                LDY #3          ; SAVE HI BYTE OF MOTOR-ON-TIME
                LDA (PTR2DCT),Y ; COUNT IN Z-PAGE.
                STA MTRTIME+1
                
                LDY #2          ; GET DRIVE # WANTED.
                LDA (PTR2IOB),Y
                LDY #16         ; SET (Y) = INDEX TO LAST-USED DRV.
                CMP (PTR2IOB),Y ; DRV# WANTED VS DRV# LAST USED.
                BEQ SAMEDRV
                STA (PTR2IOB),Y ; DESIGNATE DRV# WANTED AS LAST-
                                ; USED DRV# FOR NEXT TIME AROUND.
                PLP             ; GET STATUS BACK OFF STK.
                LDY #0          ; RESET STATUS (Z-FLAG OFF) TO
                                ; SIGNAL THAT SPECIFIC DRV # WE
                                ; WANT IN SPECIFIC SLOT WANTED WAS
                                ; NOT ORIGINALLY SPINNING.
                PHP             ; PUSH UPDATED STATUS BACK ON STK.
SAMEDRV:        ROR             ; PUT LOW BIT OF DRV WNTED IN (C).
                
                BCC USEDRV2     ; BRANCH IF WANT DRIVE 2.
                
                LDA SELDRV1,X   ; ROUTE POWER TO SELECT DRIVE 1.
                BCS USEDRV1     ; ALWAYS.

USEDRV2:        LDA SELDRV2,X   ; ROUTE POWER TO SELECT DRIVE 2.
USEDRV1:        ROR DRVZPG      ; PUT SIGN BIT FOR WHICH DRIVE
                                ; USING IN Z-PAGE:  NEG = DRIVE1.
                                ; POS = DRIVE2.

                
                                ; CHK TO SEE IF A SPECIFIC DRIVE
                                ; WANTED IN SPECIFIC SLOT WANTED
                                ; WAS ORIGINALLY ON OR NOT.

                PLP             ; GET PREVIOUS TEST RESULT.
                PHP             ; PUT IT BACK ON STK FOR LATER USE.
                BNE WASON       ; ORIG DRV IN ORIG SLOT WAS ON.

                                ; SPECIFIC DRIVE WANTED IN SPECIFIC
                                ; SLOT WANTED WAS ORIGINALLY OFF,
                                ; SO DELAY A BIT TO AVOID POSNING
                                ; HEAD DURING THE PERIOD OF HEAVY
                                ; CURRENT FLOW THAT OCCURS WHEN
                                ; MOTOR IS TURNED ON.  (THAT IS,
                                ; GIVE LINE/CAPACITOR TIME TO BLEED
                                ; DOWN BECAUSE MOTOR ON/OFF SWITCH
                                ; REQUIRES MORE CURRENT THAN THE
                                ; STEPPER MOTOR.)
                                ;
                                ; (AMOUNT OF DELAY IS NOT CONSTANT
                                ; BECAUSE IT DEPENDS ON WHAT IS IN
                                ; ACCUMULATOR & WE DONT KNOW
                                ; BECAUSE WE WERE JUST ACCESSING
                                ; HARDWARE.)

                LDY #7
WAIT4MTR:       JSR DELAY       ; STALL.
                DEY
                BNE WAIT4MTR    ; GO STALL SOME MORE.
                LDX SLOTPG5     ; RESTORE (X) = SLOT*16.
WASON:          LDY #4          ; GET TRK WANTED.
                

                LDA (PTR2IOB),Y
                JSR SEEKTRK     ; GO MOVE ARM TO CORRECT TRK.

                                ; CHECK TO SEE IF MOTOR WAS
                                ; ORIGINALLY ON.

                PLP             ; GET EARLIER RESULT OF MOTOR TEST
                BNE BEGINCMD    ; BRANCH IF DRV WAS ORIGINALLY ON.

                
                LDY MTRTIME+1   ; MOTOR WASNT ORIGNALLY ON.
                                ; HOWEVER, WE HAVE SINCE TURNED IT
                                ; ON.  NOW CHECK IF IT HAS BEEN ON
                                ; LONG ENOUGH.
                BPL BEGINCMD    ; YES -NO NEED TO WAIT ANY LONGER.
                

                                ; ALTHOUGH MOTOR IS TURNED ON, IT
                                ; HASNT BEEN ON LONG ENOUGH TO DO
                                ; ACCURATE READING OF BYTES. THERE4
                                ; DELAY UNTIL MOTOR ON TIME IS ONE
                                ; SECOND (AT WHICH TIME MTRTIME
                                ; COUNT IS 0).  (PART OF TIME WAS
                                ; TAKEN UP TO SEEK TRACK.)

TIME1:		

                LDY #18
TIME2:          DEY
                BNE TIME2
                INC MTRTIME
                BNE TIME1
                INC MTRTIME+1
                BNE TIME1

                


                                ; =================================
                                ; MOTOR IS UP TO SPEED SO NOW
                                ; PROCESS COMMAND (SEEK=00,
                                ; READ=01, WRITE=02, FORMAT=04).
                                ; ---------------------------------

                                ; USE THE FOLLOWING COUNTERS:
                                ; READCNTR = ALLOW UP TO 48 TIMES
                                ; TO FIND CORRECT ADR
                                ; PROLOGUE BETWEEN
                                ; RE-SEEKING.
                                ; RSEEKCNT = ALLOW UP TO 4 RE-SEEKS
                                ; BTWN RECALIBRATIONS.
                                ; RECLBCNT = ALLOW UP TO 2 RECALIBRATIONS.
                                ;
                                ; (THERE4, IF NECESSARY, ALLOW UP
                                ; TO 384 ATTEMPTS TO FIND CORRECT
                                ; PROLOGUE ADDR.)

                                ; BEGIN RWTS COMMAND PROCESSING.

BEGINCMD:       LDY #12         ; GET CMD FROM IOB.
                LDA (PTR2IOB),Y
                BEQ WASEEK      ; BRANCH IF CMD WAS "SEEK".
                CMP #4          ; WAS CMD "FORMAT"?
                BEQ FORMDSK     ; BRANCH IF CMD WAS  "FORMAT".


                                ; ---------------------------------
                                ; COMMAND WAS READ OR WRITE
                                ; (OPCODES $01 OR $02)
                                ; ---------------------------------

                ROR             ; (C)=1 IF READ (OPCODE %00000001)
                                ; (C)=0 IF WRIT (OPCODE %00000010)
                PHP             ; SAVE (C) DENOTING CMD ON STK.
                BCS RESETCNT    ; READING - SO SKIP PRENIBBLING.

                                ; COMMAND WAS WRITE

WASWRITE:       JSR PRENIBL     ; CONVERT 256 MEMORY BYTES TO 342
                                ; 6-BIT NIBBLES NEEDED FOR WRITING.

                                ; COMMON TO READ OR WRITE.

RESETCNT:       LDY #48         ; INIT COUNT TO READ ADR HEADER.
                STY READCNTR
SETXSLT:        LDX SLOTPG5     ; SET (X)=SLOT*16.
                JSR RDADDR      ; GO READ ADDR HEADER TO FIND SEC
                                ; THAT WE WANT TO READ OR WRITE.
                BCC RDRIGHT     ; ADDR READ WAS GOOD.

                                ; BAD ADDRESS (OR DATA) READ.

REDUCERD:       DEC READCNTR    ; REDUCE READ COUNT.
                BPL SETXSLT     ; TRY AGAIN.

                                ; DO A RECALIBRATION BECAUSE WE HAVE
                                ; EXHAUSTED ALL ATTEMPTS TO GET A
                                ; GOOD READ.

DORECALB:       LDA PRESTRK     ; SAVE TRK WANTED ON STK.
                PHA
                LDA #96         ; PRETEND PRESENTLY ON TRK #96 SO
                                ; WE FORCE HEAD AGAIN STOP.
                                ; (REPEATEDLY BANGING HEAD AGAINST
                                ; STOP = FAMILIAR DISK CLATTER.)
                JSR SETTRK      ; GO SELECT DRV & PUT TRK WANTED
                                ; IN MEM LOCATION SPECIFIC TO DRV.
                
                DEC RECLBCNT    ; REDUCE RECALIBRATION COUNTER.
                BEQ DRVERR      ; ERROR -EXHAUSTED RECALIBRATIONS.
                LDA #4          ; INDICATE 4 CHANCES TO RESEEK TRK
                STA RSEEKCNT    ; BETWEEN RECALIBRATIONS.
                
                LDA #0          ; SEEK TRACK 0.
                JSR SEEKTRK     ; GO MOVE ARM TO TRK 0.
                PLA             ; GET TRK WANTED FROM STK.
RESEEK:         JSR SEEKTRK     ; NOW, MOVING OUT FROM TRK 0, TRY
                                ; TO LOCATE TRK WANTED.
                JMP RESETCNT    ; GO BACK & TRY TO DO READ AGAIN.

                                ; GOT A GOOD READ.

RDRIGHT:        LDY TRKDSK      ; (Y) = TRK# FOUND IN HEADER.
                CPY PRESTRK     ; TRK FOUND = TRK WANTED?
                BEQ RTTRK       ; YES - SEEEKED TO CORRECT TRK.

                                ; BAD SEEK (OR ELSE SOME KIND
                                ; OF PROTECTION SCHEME) BECAUSE
                                ; TRK WANTED < > TRK FOUND.

                LDA PRESTRK     ; SAVE TRK WANTED ON STK.
                PHA
                TYA             ; SET (A) =PRESENT TRK =TRK FOUND.
                JSR SETTRK      ; GO SELECT DRV & PUT TRK WANTED N
                                ; MEMORY LOCATION SPECIFIC TO DRV.
                PLA             ; GET TRK WANTED BACK OFF STACK.
                
                DEC RSEEKCNT    ; ALLOW 4 ATTEMPTS TO FIND CORRECT
                                ; TRK BETWEEN RECALIBRATIONS.
                BNE RESEEK      ; MORE ATTEMPTS LEFT TO FIND TRK.
                BEQ DORECALB
                


                                ; ---------------------------------
                                ; GOT A DRIVE ERROR.
                                ; ---------------------------------

DRVERR:         PLA
                LDA #$40        ; ERROR CODE FOR BAD DRIVE.
TOERRWTS:       PLP
                JMP RWTSERR


                                ; ---------------------------------
                                ; RWTS COMMAND WAS SEEK (NULL).
                                ; ---------------------------------

WASEEK:         BEQ RWTSEXIT    ; IF CMD WAS SEEK, THEN GO EXIT
                                ; RWTS BECAUSE JUST COMPLETED MOVE.


                                ; ---------------------------------
                                ; RWTS COMMAND WAS FORMAT ($04).
                                ; ---------------------------------

FORMDSK:                

                JMP FORMAT      ; GO DO THE FORMAT.


                                ; ---------------------------------
                                ; FOUND CORRECT TRK FOR RWTSS
                                ; READ OR WRITE COMMANDS.
                                ; ---------------------------------



RTTRK:          LDY #3          ; GET VOL WANTED FROM IOB.
                LDA (PTR2IOB),Y
                PHA             ; SAVE IT ON THE STACK.
                LDA VOLDSK      ; GET VOL FOUND AND SAV IT IN IOB.
                LDY #14
                STA (PTR2IOB),Y
                PLA             ; RETRIEVE VOL WANTED OFF STK.
                BEQ CRCTVOL     ; VOLUME 0 GOOD FOR ALL.
                CMP VOLDSK      ; VOL WANTED = VOL FOUND?
                BEQ CRCTVOL     ; YES - GOT CORRECT VOL#.

                                ; GOT A VOLUME MISMATCH.

                LDA #$20        ; SET CODE FOR VOL MISMATCH.
                BNE TOERRWTS    ; ALWAYS.

                                ; FOUND CORRECT VOLUME SO NOW CHK
                                ; IF THE SECTOR IS ALSO CORRECT.

CRCTVOL:        LDY #5          ; GET LOGICAL SECTOR # WANTED.
                
                LDA (PTR2IOB),Y
                TAY             ; SET (Y) = LOGICAL SECTOR# WANTED.
                LDA PHYSECTR,Y  ; (A) = PHYSICAL SECTOR # WANTED.
                CMP SECDSK      ; PHYS SEC WANTED=PHYS SEC FOUND?
                BNE REDUCERD    ; NO - GO TRY AGAIN.
                

                PLP             ; GET TYPE OF OPERATION FROM STK:
                                ; (C)=0=WRITE, (C)=1=READ.
                BCC WRITE       ; BRANCH IF RWTS OPCODE WAS WRITE.

                                ; READ DATA SEC INTO RWTSS BUFFERS.

                JSR READATA     ; GO READ A SECTOR.
                PHP             ; SAVE STATUS OF READ ON STACK JUST
                                ; IN CASE WE NEED TO RE-READ.
                BCS REDUCERD    ; BAD READ - GO TRY AGAIN.  LEAVE
                                ; SET (C) ON STK TO DENOTE READING.
                                ; (WE PREVIOUSLY PULLED THE SAVED
                                ; STATUS OFF THE STK.  THERE4, WE
                                ; BETTER PUT A SET (C) BACK ON STK
                                ; BECAUSE WE ARE READING AND WE ARE
                                ; ABOUT TO BRANCH BACK TO A ROUTINE
                                ; THAT EXPECTS THE READ (C=1) OR
                                ; WRITE (C=0) FLAG ON THE STACK.
                PLP             ; GOOD READ -NOT BRANCHING BACK SO
                                ; NO NEED TO PRESERVE FLAG ON STK.

                                ; POSTNIBBLE DATA & SHUT DOWN.

                
                LDX #0
                STX PROSCRTH
                
                JSR POSTNB16    ; CONVERT 6- & 2-ENCODED BYTES IN
                                ; RWTS BUFS TO NORMAL MEMORY BYTES
                                ; (USUALLY PLACED IN DOS DATA
                                ; SECTOR BUFFER).
                LDX SLOTPG5     ; SET (X) = SLOT*16 FROM PAGE 5.


                                ; ----------------------------------
                                ; SIGNAL SUCCESS OR FAILURE
                                ; AND THEN SHUT DOWN.
                                ; ----------------------------------

                                ; SEVERAL REFERENCES ERRONEOUSLY
                                ; STATE THAT THE RETURN CODE IS
                                ; ZERO IF NO ERRORS OCCURRED.
                                ; HOWEVER, A LONE SEEK OPERATION
                                ; ALWAYS SETS THE RTN CODE TO ZERO.
                                ; EVEN IF A READ OR WRITE OPERATION
                                ; WAS SUCCESSFUL, THE IOB RTN CODE
                                ; WILL ACQUIRE A RANDOM VALUE (AS
                                ; A RESULT OF ACCESSING A HARDWARE
                                ; SWITCH PRIOR TO ENTERING THIS
                                ; ROUTINE).  THERE4, THE RTN CODE
                                ; IS ONLY RELEVANT IF AN ERROR IS
                                ; DENOTED (CARRY SET).

RWTSEXIT:       CLC             ; (C)=0, SIGNL SUCCESSFUL OPERATN
                .BYTE $24          ; "BIT $38" TO IGNORE "SEC" INSTRUC
RWTSERR:        SEC             ; (C)=1, SIGNL UNSUCCESSFUL OPERN
                LDY #13         ; STORE RETURN CODE IN IOB.
                STA (PTR2IOB),Y
                LDA MTROFF,X    ; TURN MOTOR OFF.
                RTS


                                ; ---------------------------------
                                ; WRITE SECTOR.
                                ; ---------------------------------

WRITE:          JSR WRITESEC    ; WRITE SYNC GAP AFTR ADR EPILOGUE
                                ; & THEN WRITE DATA PROLOGUE, DATA
                                ; PROPER AND DATA EPILOGUE.
                BCC RWTSEXIT    ; GOOD WRITE - GO EXIT.
                LDA #$10        ; WRITE PROTECT ERROR CODE.
                BCS RWTSERR     ; BAD WRITE - HANDLE THE ERROR.


                                ; =================================
                                ; DETERMINE DRIVE TYPE & MOVE
                                ; DISK ARM TO DESIRED TRK.
                                ; =================================

SEEKTRK:        PHA             ; SAVE # OF TRK WANTED ON STK.
                LDY #1          ; GET DRIVE TYPE (EVEN VAL=2PHASE,
                LDA (PTR2DCT),Y ; ODD VAL=1PHASE) FROM DCT.
                                ; (PS. THE "II" IN THE "DISK II"
                                ; LOGO STAMPED ON APPLES DISK
                                ; DRIVE DENOTES A 2-PHASE MOTOR.)
                ROR             ; PUT LOW BYTE OF DRV TYPE IN (C).
                PLA             ; GET TRK# WANTED BACK IN (A).
                BCC SEEKIT      ; NOT USING STANDARD DRIVE II,
                                ; USING A ONE-PHASE DRIVE INSTEAD,
                                ; THERE4 SKIP DOUBLING OF TRK# AND
                                ; USE SEEKIT AS PART OF ROUTINE
                                ; INSTEAD OF AS A SEPERATE SUBRTN.

                                ; USING A TWO-PHASE DRIVE.

                ASL             ; 2*TRK# WANTED=1/2TRACK# WANTED.
                JSR SEEKIT      ; MOVE THE DISK ARM TO DESIRED TRK.
                LSR PRESTRK     ; CONVERT HALFTRACK VALUE BACK TO
                RTS             ; WHOLE TRACK VALUE.


                                ; =====================================
                                ; ROUTINE/SUBROUTINE TO MOVE DRIVE
                                ; ARM TO A SPECIFIC TRK POSN.
                                ; =====================================

                                ; USED AS A SUBROUTINE WHEN USING
                                ; APPLES DISK DRIVE II.  NOTE WHEN
                                ; SEEKIT IS USED AS A SUBROUTINE,
                                ; DESTRK, PRESTRK, TRK4DRV1, TRK4DR2,
                                ; STPSDONE AND HOLDPRES ARE ALL
                                ; EXPRESSED IN TERMS OF HALFTRACKS:
                                ; DESTRK = DESTINATION HALF-TRACK POSN.
                                ; PRESTRK = PRESENT HALF-TRACK POSN.
                                ; HOLDPRES = PRESENT HALF-TRACK POSN.
                                ; TRK4DRV1 = BASE ADR (INDEXED BY SLOT*16)
                                ; TO POINT TO THE ADR THAT
                                ; CONTAINS THE LAST HALF-
                                ; TRACK # THAT DRIVE1 WAS
                                ; ALIGNED ONE.
                                ; TRK4DRV2 = BASE ADR (INDEXED BY SLOT*16)
                                ; TO POINT TO THE ADR THAT
                                ; CONTAINS THE LAST HALF-
                                ; TRACK # THAT DRIVE2 WAS
                                ; ALIGNED ON.
                                ; STPSDONE = NUMBER OF HALFTRACKS
                                ; MOVED SO FAR.
                                ; (NOTE:  IF NOT USING A II-PHASE
                                ; DRIVE, CHANGE ALL THE COMMENTS
                                ; BELOW THAT REFER TO HALFTRACKS
                                ; TO REFER TO FULLTRACKS INSTEAD.)

SEEKIT:                
                STA DESTRK      ; (A) = HALFTRACK# WANTED.
                

                JSR SLOTX2Y     ; CONVERT (X)=SLOT*16-->(Y)=SLOT.
                LDA TRK4DRV1,Y  ; PRES HALFTRK # ASSOC WITH DRV1.
                BIT DRVZPG      ; CONTAINS:  NEG=DRV1, POS=DRV2.
                BMI SETPRSTK    ; BRANCH IF USING DRIVE1.
                LDA TRK4DRV2,Y  ; USING DRIVE2 SO GET PRESENT
                                ; HALFTRACK # ASSOC WITH DRIVE 2.
SETPRSTK:       STA PRESTRK     ; SAVE PRESENT HALFTRK#.

                                ; DESIGNATE HALFTRK WE ARE ABOUT
                                ; TO SEEK AS PRESENT HALFTRK FOR
                                ; NEXT TIME AROUND.  (PUT HALFTRK
                                ; INFO IN SLOT-DEPENDENT LOCATIONS.)
                
                LDA DESTRK      ; HALFTRK WANTED.
                
                BIT DRVZPG      ; CHK WHICH DRIVE WERE USING.
                BMI DRV1USG     ; BRANCH IF USING DRIVE 1.
                STA TRK4DRV2,Y  ; USING DRIVE2 -STORE HALFTRK INFO
                                ; FOR NEXT TIME AROUND.
                BPL DRV2USG     ; ALWAYS.

DRV1USG:        STA TRK4DRV1,Y  ; USING DRIVE1. STORE HALFTRK INFO
                                ; FOR NEXT TIME AROUND.
DRV2USG:        JMP SEEKABS     ; GO MOVE DRIVE ARM.


                                ; ===================================
                                ; TRANSLATE (X)=SLOT*16 TO (Y)=SLOT.
                                ; ===================================

SLOTX2Y:        TXA             ; GET SLOT*16 FROM (X).
                LSR             ; DIVIDE IT BY 16.
                LSR  
                LSR  
                LSR  
                TAY             ; PUT SLOT# IN (Y).
                RTS


                                ; =================================
                                ; GO SELECT DRIVE AND PUT TRACK #
                                ; WANTED IN MEMORY LOCATION ASSOC
                                ; WITH THE # OF THE DRIVE WERE
                                ; USING.
                                ; =================================

SETTRK:         PHA             ; SAVE PRESENT TRK # ON STK.
                LDY #2          ; GET DRV # WANTED FROM IOB.
                LDA (PTR2IOB),Y
                ROR             ; CONDITION CARRY:
                                ; (C)=0=DRV1, (C)=1=DRV2.
                ROR DRVZPG      ; CONDITION ZERO-PAGE LOCATION:
                                ; NEG=DRV1, POS=DRV2.
                JSR SLOTX2Y     ; USE (X)=SLOT*16 TO GET (Y)=SLOT.
                PLA             ; GET TRK # WANTED OFF STK.
                ASL             ; TIMES TWO FOR 1/2TRACK # WANTED.
                BIT DRVZPG      ; CHK WHICH DRIVE TO USE.
                BMI STORDRV1    ; BRANCH IF USING DRIVE 1.
                STA TRK4DRV2,Y  ; SAV HALFTRK # WANTED FOR DRIVE2.
                BPL RTNSETRK    ; ALWAYS.
STORDRV1:       STA TRK4DRV1,Y  ; SAVE HALFTRK # WANTED FOR DRIVE1.
RTNSETRK:       RTS


FORMAT:                





                                ; =================================
                                ; RWTSS FORMAT COMMAND.
                                ; =================================

                                ; INITIALIZE ZERO-PAGE LOCATIONS.

                LDY #3          ; GET VOL FRM IOB, STORE IN Z-PAGE.
                LDA (PTR2IOB),Y
                STA FRMTVOL
                LDA #$AA        ; STORE "AA" AS CONSTANT IN Z-PAGE.
                STA HOLDAA
                LDY #$56        ; INITIALIZE INDEX TO BUFFER.
                LDA #0          ; INITIALIZE TRK COUNTER.
                STA FRMTKCTR    ; NOTE:  ALWAYS BEGIN FORMATTING
                                ; WITH TRACK $00.

                                ; ZERO OUT THE RWTS BUFFERS.
                                ; (NOTE:  WHEN FORMATTING, THESE
                                ; "$00" BUFFER BYTES WILL LATER BE
                                ; TRANSLATED AND WRITTEN TO THE
                                ; DISK AS "$96" DISK BYTES.)

                                ; ZERO OUT RWTS BUFFER THAT NORMALLY
                                ; CONTAINS 2-ENCODED NIBBLES.
                                ; (RWTSBUF2, $BC00 <--- $BC55.)

ZBUF2:          STA RWTSBUF1+$FF,Y
                                ; ($BC55 --> $BC00.)
                DEY
                BNE ZBUF2

                                ; ZERO OUT RWTS BUFFER THAT NORMALLY
                                ; CONTAINS 6-ENCODED NIBBLES.
                                ; (RWTSBUF1, $BB00 ---> $BBFF.)

ZBUF1:          STA RWTSBUF1,Y
                DEY
                BNE ZBUF1

                                ; PREPARE TO DO A RECALIBRATION.

                LDA #80         ; PRETEND WERE ON TRK #80.
                JSR SETTRK      ; GO SELECT DRV & PUT HALFTRACK #
                                ; WANTED IN MEMORY LOCATION ASSOC
                                ; WITH THE # OF DRV BEING USED.
		;LDA #40 ;ORIGINAL
	;TEST REMOVE
                LDA #$80         ; SET UP FOR 40 SYNCS BTWN SECS
	;TEST REMOVE
                STA SYNCNTR     ; ON TRK0.  NOTE THAT THIS # WILL
                                ; LATER BE REDUCED AS WE WRITE
                                ; SUBSEQUENT TRKS.(HIGHER NUMBERED
                                ; TRKS ARE CLOSER TO THE CENTER OF
                                ; THE DSK & THERE4 ARE REPRESENTED
                                ; BY SMALLER CIRCLES. WE CAN CROWD
                                ; ALL THE SECS INTO A SMALLER
                                ; CIRCUMFERENCE BY REDUCING THE #
                                ; OF SYNC BYTES BETWEEN SECS.

                                ; FORMAT THE NEXT TRACK.

FRMNXTRK:       LDA FRMTKCTR    ; USE TRK COUNTER AS TRK TO SEEK.
                JSR SEEKTRK     ; POSN ARM OVER CORRECT TRK.

                                ; GO FORMAT A SPECIFIC TRACK.

                JSR FORMATRK    ; FORMAT A TRACK.
                LDA #8          ; SET (A) AS DEFAULT VALUE IN CASE
                                ; COULDNT FORMAT.  NOTE THAT ANY
                                ; TYPE OF ERROR ENCOUNTERED WHEN
                                ; FORMATTING YEILDS AN I/O-ERROR
                                ; MESSAGE.
                BCS ERRFRMT     ; BRANCH IF COULDNT FORMAT.
;TEST REMOVE
;LDA #$01
;STA $FF
;JMP MONITOR_ENTRY
;TEST REMOVE

                                ; DO A READ CHK OF TRK JUST FORMATTED.
                                ; (EVENTHOUGH TRACK VERIFIED, READ
                                ; IT AGAIN UNTIL LOCATE TRK0.
                                ; (PRESUMABLY, THIS (PARTIALLY)
                                ; DOUBLE CHECKS VERIFICATION AND
                                ; KEEPS SECTORS IN DIFFERENT TRACKS
                                ; SOMEWHAT ADJACENT?)

                LDA #48         ; SET 48 ATTEMPTS TO READ.
                STA READCNTR
RDAGAIN:        SEC             ; DEFAULT (C)=1 TO SIGNAL ERROR.
                DEC READCNTR    ; REDUCE CHANCES TO READ.
                BEQ ERRFRMT     ; EXHAUSTED ALL CHANCES.
                JSR RDADDR      ; GO READ ADDR HEADER TO FIND SEC
                                ; THAT WE WANT TO READ OR WRITE.
                BCS RDAGAIN     ; BAD READ - TRY AGAIN.
                LDA SECDSK      ; WAS IT SECTOR 0?
                BNE RDAGAIN     ; NO - TRY AGAIN.
                JSR READATA     ; LAST CHANCE TO READ DATA.
                BCS RDAGAIN     ; LAST CHANCE BOMBED OUT!!!
                INC FRMTKCTR    ; KICK UP TRK COUNTER.
                LDA FRMTKCTR    ; SET (A) FOR NEXT TRK COUNT.
                CMP #TRKPERDSK  ; DONE ALL TRACKS YET (#0 TO #34)?
                BCC FRMNXTRK    ; NO - GO FORMAT THE NEXT TRACK.
                CLC             ; SIGNAL FINISHED ALL TRACKS.
                BCC DONEFRMT    ; ALWAYS - ONLY GOOD EXIT.

                                ; NOTE:  NO MATTER WHAT KIND OF ERROR
                                ; WE MIGHT HAVE ENCOUNTERED WHEN
                                ; FORMATTING, THE IOB ERROR CODE IS
                                ; SET TO $08.  THIS IS LATER TRANSLATED
                                ; TO AN FM ERROR CODE (ALSO $08) WHICH
                                ; DOS DISPLAYS AS AN I/O ERROR MSG.
                                ; (THIS IS WHY TRYING TO FORMAT A
                                ; WRITE-PROTECTED DISK RESULTS IN AN
                                ; I/O ERROR MSG INSTEAD OF A DISK-
                                ; WRITE-PROTECTED MSG.)
                                ; IF NO ERROR OCCURRED, THE IOB RETURN
                                ; CODE WILL BE SET TO SOME RANDOM
                                ; NUMBER (FROM REFERENCING A HARD-
                                ; WARE SWITCH ADDRESS).

ERRFRMT:        LDY #13         ; INDEX TO RETURN CODE IN IOB.
                STA (PTR2IOB),Y ; STORE RETURN CODE.
                SEC             ; SIGNAL THAT AN ERROR OCCURRED.
DONEFRMT:       LDA MTROFF,X    ; TURN THE MOTOR OFF, XIT WITH (C)
                RTS             ; DENOTING SUCCESS STATUS.


                                ; ------------------------------------
                                ; SUBROUTINE TO FORMAT A SPECIFIC TRK.
                                ; ------------------------------------

                                ; SECTORS ARE WRITTEN IN ASCENDING
                                ; ORDER FROM SEC $00 TO SEC $0F.
                                ; (NOTE THAT THE FORMAT ROUTINE ONLY
                                ; DEALS WITH PHYSICAL SECTOR NUMBERS.)

FORMATRK:       LDA #0          ; ALWAYS START WITH SEC $00.
                STA FRMTSEC
                LDY #128        ; USE 128 SYNC BYTS BEFORE SEC$00.
                                ; NOTE: THIS GAP WILL BE PARTIALLY
                                ; OVERWRITTEN BY SEC $0F.
                BNE DOADDR      ; ALWAYS.

FRMTASEC:       LDY SYNCNTR     ; SET (Y)= # OF 40-CYCLE SELF-SYNC
                                ; BYTES TO BE WRITTEN BTWN SECS.
                                ; (THIS # VARIES DEPENDING ON THE
                                ; SPEED OF THE SPECIFIC DRV BEING
                                ; USED & THE # OF THE TRK BEING
                                ; WRITTEN.)
DOADDR:         JSR WRITADR     ; WRITE SYNC BYTES & ADDR HEADER.

                BCS VRFYRTN     ; ERROR -DISK WAS WRITE PROTECTED.

;TEST REMOVE
;LDA #$02
;STA $FF
;JMP MONITOR_ENTRY
;TEST REMOVE

                JSR WRITESEC    ; WRITE SYNC GAP BTWN ADDR & DATA
                                ; FIELDS, WRT DATA & WRITE A SYNC
                                ; BYTE AFTER DATA EPILOGUE.
                BCS VRFYRTN     ; IRRELEVANT - NEVER TAKEN BECAUSE
                                ; WE ALREADY CHECKED THE WRITE-
                                ; PROTECT SWTCH WHEN WE WROTE ADR.

;TEST REMOVE
;LDA #$03
;STA $FF
;JMP MONITOR_ENTRY
;TEST REMOVE

                INC FRMTSEC     ; INCREASE SEC #.
                LDA FRMTSEC
                CMP #$10        ; DONE ALL 16 SECS YET?
                BCC FRMTASEC    ; NO - GO DO SOME MORE.


                                ; ......................................
                                ; VERIFY A SINGLE TRACK.
                                ; ......................................

                                ; NOTE WE JUST FINISHED FORMATTING
                                ; SEC $0F.  BECAUSE SEC $0F SHOULDNT
                                ; OVERWRITE TOO MUCH OF OF THE SYNC GAP
                                ; (ORIGINALLY 128 SYNC LONG) THAT WAS
                                ; WAS WRITTEN PRIOR TO SEC $00, AND BECAUSE
                                ; WE DONT WASTE TOO MUCH TIME BETWEEN
                                ; WRITING THE LAST BYTE OF SEC $0F AND
                                ; LOOKING FOR THE NEXT ADDR HEADER,
                                ; WE EXPECT TO BEGIN OUR VERIFICATION
                                ; WITH SEC $00.


                                ; INTIALIZE COUNTERS.

                LDY #$0F        ; SET COUNTER 4 # OF SECS VERIFIED
                STY FRMTSEC
                LDA #48         ; SET COUNTER FOR # OF ATTEMPTS.
                STA READCNTR

                                ; FILL SECTOR MAP WITH POSITIVE NUMBERS.

FILSECMP:       STA SECFLGS,Y
                DEY
                BPL FILSECMP

                                ; DELAY TO LET SOME SYNCS PASS BY.

                LDY SYNCNTR     ; INITIALIZE  (Y).

;TEST REMOVE
;LDA #$07
;STA $FF
;JMP MONITOR_ENTRY
;TEST REMOVE

BYPSYNCS:       JSR VRFYRTN     ; (12 CYC)
                JSR VRFYRTN     ; (12 CYC)
                JSR VRFYRTN     ; (12 CYC)
                PHA             ; (3 CYC)
                PLA             ; (4 CYC)
                NOP             ; (2 CYC)
                DEY             ; (2 CYC)
                BNE BYPSYNCS    ; (3 CYC ON BRNCH, 2 ON FALL THRU)

                                ; READ ADDRESS OF FIRST SEC ENCOUNTERED.
                                ; (THIS BETTER BE SEC $00!!!!  IF IT
                                ; ISNT, OUR DRIVE IS TOO FAST & WE
                                ; WILL EVENTUALLY HAVE TO REFORMAT
                                ; THE TRACK.)

                JSR RDADDR      ; READ ADR OF 1ST SEC ENCOUNTERED
                BCS REREADDR    ; BAD READ, TRY AGAIN.

;TEST REMOVE
;LDA #$04
;STA $FF
;JMP MONITOR_ENTRY
;TEST REMOVE

                LDA SECDSK      ; WAS SEC READ = SEC00?
                BEQ RDNXTDAT    ; YES - GO READ NEXT DATA SEC.

;TEST REMOVE
;LDA #$05
;STA $FF
;JMP MONITOR_ENTRY
;TEST REMOVE


                                ; DIDNT FIND SECTOR $00 WHEN EXPECTED!!!!

                                ; DRIVE MUST BE FASTER THAN ANTICIPATED
                                ; BECAUSE SEC $0F OVERLAID TOO MUCH OF
                                ; THE LONG SYNC GAP (GAP1) THAT WAS
                                ; ORIGINALLY WRITTEN BEFORE SEC $00.
                                ; WE WILL EVENTUALLY HAVE TO REFORMAT
                                ; THIS TRK USING 128 SELF-SYNCS BEFORE
                                ; SEC $00 (GAP1) AND LESS SYNC BYTES
                                ; BETWEEN OTHER SECS (GAP3).  THIS
                                ; WILL INSURE THAT LESS GAP-1 SYNCS
                                ; WILL BE OVERWRITTEN BY SEC $OF.
                                ; NOTE THAT DEPENDING ON JUST HOW
                                ; MUCH TOO FAST THE DRIVE IS, WE MAY
                                ; HAVE TO REFORMAT THIS TRK SEVERAL
                                ; TIMES BEFORE WE GET IT RIGHT.  EACH
                                ; TIME WE REFORMAT, WE REDUCE THE #
                                ; OF GAP-3 SYNCS.  IF THE SYNC COUNTER
                                ; IS > = 16, WE WRITE 2 LESS SYNCS.
                                ; IF THE COUNTER IS < 16, WE ONLY REDUCE
                                ; GAP-3 BY ONE SYNC.  IN ORDER TO GIVE
                                ; THE MACHINE TIME TO DECODE INFO, WE
                                ; WONT ALLOW A GAP LESS THAN 5 SYNCS
                                ; LONG.  (NOTE THAT WE WONT REFORMAT
                                ; THE TRACK UNTIL WE FIND THE ADR HEADER
                                ; FOR SEC $0F.  THIS PRESUMABLY KEEPS
                                ; LIKE-NUMBERED SECS IN ADJACENT TRKS
                                ; IN SOME SEMBLANCE OF ORDER.)

;TEST REMOVE
LDA #$08
STA $FF
JMP MONITOR_ENTRY
;TEST REMOVE

                LDA #16
                CMP SYNCNTR     ; CONDITION CARRY.
                LDA SYNCNTR     ; IF SYNC COUNT < 16, SUBTRACT 1,
                SBC #1          ; ELSE SUBTRACT 2.
                STA SYNCNTR
                CMP #5          ; DO WE HAVE AT LEAST 5 SYNCS?
                BCS REREADDR    ; YES.
                SEC             ; NO - SIGNAL ERROR BECAUSE NEED AT
                RTS             ; LEAST 5 SYNCS.  DRIVE IS SO FAST
                                ; ===             ;THAT IT IS USELESS.  WE CANT
                                ; EVEN COMPENSATE FOR IT BY REDUCING
                                ; THE NUMBER OF GAP-3 SYNCS.

                                ; READ THE SEC ADDR & DATA PROPER.

RDNXTADR:       JSR RDADDR      ; READ THE ADDR HEADER.
                BCS BADREAD     ; BRANCH IF BAD ADDRESS READ.
RDNXTDAT:       

;TEST REMOVE
;LDA #$06
;STA $FF
;JMP MONITOR_ENTRY
;TEST REMOVE

		JSR READATA     ; READ THE DATA PROPER.
                BCC CKSECMAP    ; READ WAS GOOD -SO GO CHK IF THIS
                                ; SEC HAS ALREADY BEEN READ.

BADREAD:        DEC READCNTR    ; EITHER GOT A BAD READ OR ELSE
                                ; WE ALREADY VERIFIED THIS SEC.
                                ; REDUCE THE # OF CHANCES LEFT.
                BNE RDNXTADR    ; MORE CHANCES LEFT -GO TRY AGAIN.

                                ; DOING A RE-READ.  WILL DEFINITELY
                                ; HAVE TO REFORMAT.

REREADDR:       JSR RDADDR      ; READ AN ADDR HEADER.
                BCS NOTLAST     ; GOT A BAD READ.

                                ; WE WILL REFORMAT BUT WE DONT WANT
                                ; TO DO SO UNTIL WE READ SEC $0F.

                                ; HAVE WE FOUND SEC $0F YET?

                LDA SECDSK      ; GET PHYS # OF SEC JUST READ.
                CMP #$0F        ; WAS IT SEC 15?
                BNE NOTLAST     ; NO, SO GO LOOK SOME MORE.
                JSR READATA     ; YES - READ THE DATA IN SEC $0F.
                BCC FORMATRK    ; GOOD READ ON SEC15 SO NOW TIMING
                                ; IS RIGHT TO GO REFORMAT THIS TRK
NOTLAST:        DEC READCNTR    ; BAD READ, CK IF MORE CHANCES LFT
                BNE REREADDR    ; YES - GO TRY AGAIN.
;TEST REMOVE
LDA #$09
STA $FF
JMP MONITOR_ENTRY
;TEST REMOVE

                SEC             ; EXHAUSTED ALL CHANCES, SO SET
VRFYRTN:        RTS             ; (C) AS ERROR FLAG & EXIT.
                                ; ===

                                ; CHECK IF THIS SEC WAS PREVIOUSLY
                                ; VERIFIED.  IF NOT, UPDATE SECTOR
                                ; VERIFICATION MAP.  (IF TIMING IS
                                ; RIGHT, SHOULD NEVER ENCOUNTER AN
                                ; ALREADY VERIFIED SEC BEFORE FRMTSEC
                                ; DECREMENTS FROM $0F DOWN TO $FF.)

CKSECMAP:       LDY SECDSK      ; USE # OF SEC FOUND AS INDEX TO
                                ; THE VERIFICATION MAP.
                LDA SECFLGS,Y   ; GET MAP BYT (NEG=PREV VERIFIED).
                BMI BADREAD     ; OH!OH! ALREADY VERIFIED THIS ONE
                LDA #$FF        ; SET BYTE IN MAP TO SIGNAL THAT
                STA SECFLGS,Y   ; THIS SEC WAS JUST VERIFIED.
                DEC FRMTSEC     ; ANY SECS LEFT TO VERIFY?
                BPL RDNXTADR    ; YES - GO DO SOME MORE.

                                ; ALL SECS VERIFIED, SO CHECK
                                ; IF WE JUST DID TRACK $00.

                LDA FRMTKCTR    ; WAS TRK JUST FORMATTED =TRK $00?
                BNE NOTRK0      ; NO - SO EXIT CLEANLY.

                                ; JUST FORMATTED & VERIFIED TRK $00.
                                ; TRK $00 IS THE OUTSIDE TRK AND THERE4
                                ; HAS THE LARGEST LENGTH IN WHICH TO
                                ; WRITE BYTES.  BECAUSE SUBSEQUENT
                                ; TRKS HAVE A SMALLER CIRCUMFERENCE,
                                ; WE MUST REDUCE THE NUMBER OF SYNCS
                                ; TO WRITE BETWEEN SECS (GAP3) SO WE
                                ; CAN GET ALL THE NEEDED INFO INTO
                                ; A SMALLER SPACE.

                LDA SYNCNTR     ; CHECK SYNC COUNT.
                CMP #16         ; LESS THAN 16 SYNCS?
                BCC VRFYRTN     ; YES - EXIT CLEANLY.
                                ; DONT WANT TO START OFF WITH A
                                ; SMALLER GAP SO SKIP CODE BELOW.

                                ; REDUCE THE SIZE OF GAP3.

                DEC SYNCNTR     ; GAP > = 16 SYNCS LONG, SO CAN
                DEC SYNCNTR     ; AFFORD TO REDUCE IT BY 2 IN ORDER
NOTRK0:         CLC             ; TO ACCOMMODATE A TIGHTER TRACK.
                RTS             ; EXIT CLENALY.


                                ; =================================
                                ; FLAGS FOR SECTOR VERIFICATION.
                                ; ($BFA8 - $BFB7)
                                ; - NEG VAL = SECTOR VERIFIED.
                                ; - TABLE IS INDEXED BY (Y),
                                ; WHERE (Y) = SECTOR NUMBER.
                                ; =================================
SECFLGS:
    .REPEAT $10
    .BYTE $FF
    .ENDREP


                                ; =================================
                                ; PHYSICAL SECTOR NUMBERS
                                ; ($BFB8 - $BFC7)
                                ; - LISTED IN LOGICAL ORDER.
                                ; =================================

                                ; CORRESPONDING LOGICAL SECTOR#.
PHYSECTR:       .BYTE $00          ; 00
                .BYTE $0D          ; 01
                .BYTE $0B          ; 02
                .BYTE $09          ; 03
                .BYTE $07          ; 04
                .BYTE $05          ; 05
                .BYTE $03          ; 06
                .BYTE $01          ; 07
                .BYTE $0E          ; 08
                .BYTE $0C          ; 09
                .BYTE $0A          ; 0A
                .BYTE $08          ; 0B
                .BYTE $06          ; 0C
                .BYTE $04          ; 0D
                .BYTE $02          ; 0E
                .BYTE $0F          ; 0F


DOSLIM:                         ; ********************************
                                ; END OF DOS
                                ; ********************************
