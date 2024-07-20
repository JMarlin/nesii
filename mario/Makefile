MARIO_OBJECTS = entry.o launcher.o
MARIO_INCLUDES = launcher.inc ../nos/nos_calls.inc
MARIO_ALL_TARGETS = MARIO MPD0 MPD1 MCD mario.map
UTILS = ../build_util
SOURCE_INES = ~/mario.nes

.PHONY: all
all: $(MARIO_ALL_TARGETS)

.PHONY: clean
clean:
	rm -f $(MARIO_ALL_TARGETS)
	rm -f $(MARIO_OBJECTS)
	rm -f *.bin

mpd0.bin mpd1.bin MCD &: $(UTILS)/split_ines.py $(UTILS)/bin2dos.py
	$(UTILS)/split_ines.py $(SOURCE_INES) mpd0.bin mpd1.bin MCD

MPD0: mpd0.bin
	$(UTILS)/bin2dos.py 0x8000 mpd0.bin MPD0

MPD1: mpd1.bin
	$(UTILS)/bin2dos.py 0x8000 mpd1.bin MPD1

MARIO: $(UTILS)/bin2dos.py mario.bin
	$(UTILS)/bin2dos.py 0x0300 mario.bin MARIO

mario.bin mario.map &: mario.cfg $(MARIO_OBJECTS) 
	ld65 -m mario.map -o mario.bin -C mario.cfg $(MARIO_OBJECTS)

%.o: %.asm $(MARIO_INCLUDES)
	ca65 $<
