all: nos.dsk

nos.dsk: nos.bin ../skew-dsk.py
	../skew-dsk.py nos.bin nos.dsk

nos.bin: nos_link.cfg boot_sector.o command_processor.o hello_command.o mon_command.o dir_command.o floppy.o
	ld65 -o nos.bin -C nos_link.cfg boot_sector.o command_processor.o hello_command.o mon_command.o dir_command.o floppy.o

boot_sector.o: boot_sector.asm rom_constants.inc floppy.inc
	ca65 boot_sector.asm

command_processor.o: command_processor.asm rom_constants.inc hello_command.inc mon_command.inc dir_command.inc
	ca65 command_processor.asm

hello_command.o: hello_command.asm rom_constants.inc
	ca65 hello_command.asm

mon_command.o: mon_command.asm rom_constants.inc
	ca65 mon_command.asm

dir_command.o: dir_command.asm rom_constants.inc floppy.inc
	ca65 dir_command.asm

floppy.o: floppy.asm rom_constants.inc
	ca65 floppy.asm
