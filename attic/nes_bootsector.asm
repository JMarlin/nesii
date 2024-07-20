.org $0400

;This is no longer really useful for much, but this is a boot sector that can be prepended to
;32k of NES PRG data and 8k of NES CHR data to make a directly bootable NES game disk
;This was used to generate the boot bytes in build_util/new2dsk.py

CART_SWITCHES    = $D000
LOAD_NEXT_SECTOR = $E27F
IWM_MOTOR_OFF    = $c088

data_ptr         = $26
chr_sector_count = $44

boot_game:
    ;Read 8 tracks of PRG data into low-mapped low cart RAM
    jsr load_prg_16k

    ;Switch low cart RAM mapping
    lda #$02
    sta CART_SWITCHES

    ;Read 8 more tracks of PRG data into low-mapped high cart RAM
    jsr load_prg_16k

    ;Read 2 tracks of CHR data and transfer it into CHR-RAM
    jsr load_chr_data

    ;Stop the disk drive
    lda IWM_MOTOR_OFF

    ;Set mirroring and 'all RAM' mode
    lda #$01
    sta CART_SWITCHES

    ;Enter the cart
    jmp ($FFFC)


load_chr_data:
    ;Need to load 8k of CHR data
    ;Do it one sector at a time

    ;Turn off rendering
    lda #$00
    sta $2001

    ;Initialize sector counter and buffer target address
    lda #$00
    sta chr_sector_count

    ;Initialize PPU starting write address
    lda #$00
    sta $2006
    sta $2006

next_chr_sector:
    ;Probably redundant, initialize target CHR buffer address
    lda #$00
    sta data_ptr
    lda #$05
    sta data_ptr+1

    ;Read next sector into CHR buffer
    jsr LOAD_NEXT_SECTOR

    ;Copy CHR buffer into CHR RAM
    ldx #$00
next_chr_byte:
    lda $0500,X
    sta $2007
    inx
    bne next_chr_byte

    ;Increment sector counter 
    inc chr_sector_count

    ;Do next sector if counter is not at 0x20
    lda chr_sector_count
    cmp #$20
    bne next_chr_sector

    ;Turn on rendering
    lda #$0E
    sta $2001

    rts

load_prg_16k:
    lda #$00
    sta data_ptr
    lda #$80
    sta data_ptr+1
next_sector_16k:
    jsr LOAD_NEXT_SECTOR
    inc data_ptr+1
    lda data_ptr+1
    cmp #$C0
    bne next_sector_16k
    rts
