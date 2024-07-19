SYSTEM_OBJECTS = boot_sector.o fs.o binary_loader.o system_entry.o call_map.o

all: system.bin

system.bin: system.cfg $(SYSTEM_OBJECTS)
	ld65 -m system.map -o system.bin -C system.cfg $(SYSTEM_OBJECTS)

%.o: %.asm
	ca65 $<
