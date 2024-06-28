all: nesii_trunc.bin nos_bootsect.bin

nesii_trunc.bin: nesii.bin
	dd if=nesii.bin of=nesii_trunc.bin bs=1024 skip=32

nesii.bin: link.cfg bios.o char_io.o floppy_rom.o monitor.o
	ld65 -m nesii.map -o nesii.bin -C link.cfg bios.o monitor.o char_io.o floppy_rom.o
	ld65 -o nesii.o -C link.cfg bios.o monitor.o char_io.o floppy_rom.o

nos.dsk: nos.bin skew-dsk.py
	./skew-dsk.py nos.bin nos.dsk

nos.bin: nos_link.cfg nos_bootsect.o
	ld65 -o nos.bin -C nos_link.cfg nos_bootsect.o

bios.o: bios.asm
	ca65 bios.asm

char_io.o: char_io.asm
	ca65 char_io.asm

monitor.o: monitor.asm
	ca65 monitor.asm

floppy_rom.o: floppy_rom.asm
	ca65 floppy_rom.asm

nos_bootsect.o: nos_bootsect.asm
	ca65 nos_bootsect.asm
