MARIO_OBJECTS = entry.o launcher.o
MARIO_INCLUDES = launcher.inc ../nos/nos_calls.inc
MARIO_BIN_TARGETS = MARIO MPD0 MPD1 MCD
MARIO_ALL_TARGETS = $(MARIO_BIN_TARGETS) mario.map
UTILS = ../build_util
SOURCE_INES = ~/mario.nes
CIDERPRESS2 = ~/Downloads/cp2_1.0.2_osx-x64_fd

.PHONY: all
all: $(MARIO_ALL_TARGETS)

.PHONY: ../nos/nos.do
../nos/nos.do:
	make -C ../nos/

install: $(MARIO_BIN_TARGETS) ../nos/nos.do
	$(CIDERPRESS2)/cp2 add ../nos/nos.do $(MARIO_BIN_TARGETS)
	for t in $(MARIO_BIN_TARGETS); do $(CIDERPRESS2)/cp2 sa ../nos/nos.do $$t type=bin; done

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
