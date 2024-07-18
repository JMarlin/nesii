SHELL_OBJECTS = entry.o command_processor.o dir_command.o echo_command.o hello_command.o mon_command.o run_command.o
SHELL_INCLUDES = command_processor.inc dir_command.inc echo_command.inc hello_command.inc mon_command.inc run_command.inc ../globals.inc ../rom_constants.inc

all: SHELL

SHELL: ../../bin2dos.py shell.bin
	../../bin2dos.py 0x8000 shell.bin SHELL

shell.bin: shell.cfg $(SHELL_OBJECTS)
	ld65 -m shell.map -o shell.bin -C shell.cfg $(SHELL_OBJECTS)

%.o: %.asm $(SHELL_INCLUDES)
	ca65 $<
