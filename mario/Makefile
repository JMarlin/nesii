MARIO_OBJECTS = entry.o launcher.o
MARIO_INCLUDES = launcher.inc ../nos/nos_calls.inc

.PHONY: all
all: MARIO MPD0 MPD1 MCD

mpd0.bin mpd1.bin mcd.bin &: ../split-ines.py ../bin2dos.py
	../split-ines.py ~/mario.nes mpd0.bin mpd1.bin MCD

MPD0: mpd0.bin
	../bin2dos.py 0x8000 mpd0.bin MPD0

MPD1: mpd1.bin
	../bin2dos.py 0x8000 mpd1.bin MPD1


MARIO: ../bin2dos.py mario.bin
	../bin2dos.py 0x0300 mario.bin MARIO

mario.bin: mario.cfg $(MARIO_OBJECTS) 
	ld65 -m mario.map -o mario.bin -C mario.cfg $(MARIO_OBJECTS)

%.o: %.asm $(MARIO_INCLUDES)
	ca65 $<
