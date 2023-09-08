.SEGMENT "CODE_MAIN"

MONITOR_ENTRY = $E147

.GLOBAL RWTS

MAIN:
LDA #$00
STA $FF
LDY #<FORMATBLK
LDA #>FORMATBLK
JSR RWTS
JMP MONITOR_ENTRY

.GLOBAL FORMATBLK
FORMATBLK:
.BYTE $01 ;00 Table type . must be $01
.BYTE $60 ;01 Slot number times 16 (sO: s = slot. Example: $60)
.BYTE $01 ;02 Drive number ($01 or $02)
.BYTE $00 ;03 Volume number expected ($00  any volume)
.BYTE $00 ;04 Track number (SOD through 522)
.BYTE $00 ;05 Sector number ($00 through SOP)
.WORD DEVICE_CHARACTERISTICS ;06-07 Address (LO/ HI) of the Device Characteristics Table
.WORD $0000 ;08-09 Address (LO/ HI) of the 256 byte buffer for READ/ WRITE
.BYTE $00 ;0A Not used
.BYTE $00 ;0B Byte count for partial sector ($00 for 256 bytes)
.BYTE $04 ;0C Command code $00 - SEEK
          ;                $01 - READ
          ;                $02 - WRITE
          ;               $04 - FORMAT
.BYTE $00 ;0D Return code - The processor CARRY flag is set upon
          ;                 return from RWTS if there is a
          ;                 non-zero return code:
          ;                 $00 - No errors
          ;                 $08 - Error during initialization
          ;                 $10 - Write protect error
          ;                 $20 - Volume mismatch error
          ;                 $40 - Drive ercor
          ;                 $80 - Read error (obsolete)
.BYTE $00 ;0E Volume number of last access (must be initialized)
.BYTE $60 ;0F Slot number of last access * 16 (must be initialized)
.BYTE $01 ;10 Drive nuaber of last access (must be initialized)

DEVICE_CHARACTERISTICS:
.BYTE $00   ;00 Device type (should be $00 for DISK II)
.BYTE $01   ;01 Phaaes per track (should be $01 for DISK II)
.WORD $EFD8 ;02-03 Motor on time count (should be $EFD8 for DISK II)
