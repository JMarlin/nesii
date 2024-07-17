NOS_OBJECTS = boot_sector.o command_processor.o dir_command.o fs.o mon_command.o run_command.o console.o

all: nos.dsk

nos.dsk: nos.bin ../skew-dsk.py
	../skew-dsk.py nos.bin nos.dsk

nos.bin: nos_link.cfg $(NOS_OBJECTS)
	ld65 -o nos.bin -C nos_link.cfg $(NOS_OBJECTS)

%.o: %.asm
	ca65 $<
