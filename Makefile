all: nesii_trunc.bin

nesii_trunc.bin: nesii.bin
	dd if=nesii.bin of=nesii_trunc.bin bs=1024 skip=32

nesii.bin: link.cfg bios.o char_io.o floppy_rom.o monitor.o
	ld65 -m nesii.map -o nesii.bin -C link.cfg bios.o monitor.o char_io.o floppy_rom.o
	ld65 -o nesii.o -C link.cfg bios.o monitor.o char_io.o floppy_rom.o

bios.o: bios.asm
	ca65 -l bios.lst bios.asm

char_io.o: char_io.asm
	ca65 char_io.asm

monitor.o: monitor.asm
	ca65 monitor.asm

floppy_rom.o: floppy_rom.asm
	ca65 floppy_rom.asm
