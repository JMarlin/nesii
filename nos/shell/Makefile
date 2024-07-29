UTILS = ../../build_util
SHELL_OBJECTS = entry.o bumload.o command_processor.o dir_command.o echo_command.o hello_command.o mon_command.o run_command.o
SHELL_INCLUDES = bumload.inc command_processor.inc dir_command.inc echo_command.inc hello_command.inc mon_command.inc run_command.inc ../globals.inc ../rom_constants.inc ../nos_calls.inc
SHELL_TARGETS = SHELL

.PHONY: all
all: $(SHELL_TARGETS)

clean:
	rm -f $(SHELL_OBJECTS)
	rm -f $(SHELL_TARGETS)
	rm -f *.bin
	rm -f *.map

SHELL: $(UTILS)/bin2dos.py shell.bin
	$(UTILS)/bin2dos.py 0x8000 shell.bin SHELL

shell.bin: shell.cfg $(SHELL_OBJECTS)
	ld65 -m shell.map -o shell.bin -C shell.cfg $(SHELL_OBJECTS)

%.o: %.asm $(SHELL_INCLUDES)
	ca65 $<
