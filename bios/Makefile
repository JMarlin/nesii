BIOS_OBJECTS = bios.o char_io.o monitor.o floppy.o
NOS_OBJECTS = nos/command_processor.o nos/dir_command.o nos/fs.o nos/mon_command.o nos/run_command.o nos/console.o
ROM_EMU_DEVICE = /dev/cu.usbmodem21401
ROM_EMU_TOOL = ~/code/28pi256/upload.py

.PHONY: all
all: nesii_trunc.bin

.PHONY: clean
clean:
	rm -f *.o *.bin *.map *.nes

#This builds the bios as an iNES ROM image that can be loaded
#and debugged in an emulator
nesii_bios.nes: nesii_trunc.bin blob/bios_ines_header.bin
	cat blob/bios_ines_header.bin > nesii_bios.nes
	cat nesii_trunc.bin >> nesii_bios.nes

romemu: nesii_trunc.bin
	$(ROM_EMU_TOOL) $(ROM_EMU_DEVICE) nesii_trunc.bin

nos_romemu: nosrom_trunc.bin
	$(ROM_EMU_TOOL) $(ROM_EMU_DEVICE) nosrom_trunc.bin

#This is a ROM that runs NOS code out of the ROM rather
#than trying to load and boot from the floppy
#It is intended for rapid development usage with
#the 28PI256 ROM emulator
nosrom_trunc.bin: nosrom.bin
	dd if=nosrom.bin of=nosrom_trunc.bin bs=1024 skip=32

nosrom.bin: nosrom_link.cfg $(BIOS_OBJECTS) $(NOS_OBJECTS)
	ld65 -m nosrom.map -o nosrom.bin -C nosrom_link.cfg $(BIOS_OBJECTS) $(NOS_OBJECTS)

#This is the final 32k ROM image for the 28C256 boot ROM
#on the NES][ cartridge
nesii_trunc.bin: nesii.bin
	dd if=nesii.bin of=nesii_trunc.bin bs=1024 skip=32

nesii.bin: link.cfg $(BIOS_OBJECTS) floppy_startup.o
	ld65 -m nesii.map -o nesii.bin -C link.cfg $(BIOS_OBJECTS) floppy_startup.o

%.o: %.asm
	ca65 $<
