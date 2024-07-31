SYSTEM_INCLUDES = ../../bios/startup_interface.inc ../../bios/globals.inc ../../bios/calls.inc ../nos_calls.inc binary_loader.inc console.inc fs.inc system_entry.inc
SYSTEM_OBJECTS = boot_sector.o fs.o binary_loader.o system_entry.o call_map.o
SYSTEM_TARGETS = system.bin

.PHONY: all
all: $(SYSTEM_TARGETS)

clean:
	rm -f $(SYSTEM_OBJECTS)
	rm -f $(SYSTEM_TARGETS)
	rm -f *.map

system.bin: system.cfg $(SYSTEM_OBJECTS) 
	ld65 -m system.map -o system.bin -C system.cfg $(SYSTEM_OBJECTS)

%.o: %.asm $(SYSTEM_INCLUDES)
	ca65 $<
