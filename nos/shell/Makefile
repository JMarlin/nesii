SYSTEM_OBJECTS = boot_sector.o fs.o

all: system.bin

system.bin: system.cfg $(SYSTEM_OBJECTS)
	ld65 -o system.bin -C system.cfg $(SYSTEM_OBJECTS)

%.o: %.asm
	ca65 $<
