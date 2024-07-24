DONKEY_OBJECTS = entry.o launcher.o
DONKEY_INCLUDES = launcher.inc ../nos/nos_calls.inc
DONKEY_BIN_TARGETS = DONKEY DPD0 DPD1 DCD
DONKEY_ALL_TARGETS = $(DONKEY_BIN_TARGETS) donkey.map
UTILS = ../build_util
SOURCE_INES = ~/donkey.nes
CIDERPRESS2 = ~/Downloads/cp2_1.0.2_osx-x64_fd

.PHONY: all
all: $(DONKEY_ALL_TARGETS)

.PHONY: ../nos/nos.do
../nos/nos.do:
	make -C ../nos/

install: $(DONKEY_BIN_TARGETS) ../nos/nos.do
	$(CIDERPRESS2)/cp2 add ../nos/nos.do $(DONKEY_BIN_TARGETS)
	for t in $(DONKEY_BIN_TARGETS); do $(CIDERPRESS2)/cp2 sa ../nos/nos.do $$t type=bin; done

.PHONY: clean
clean:
	rm -f $(DONKEY_ALL_TARGETS)
	rm -f $(DONKEY_OBJECTS)
	rm -f *.bin

dpd0.bin dpd1.bin DCD &: $(UTILS)/split_ines.py $(UTILS)/bin2dos.py
	$(UTILS)/split_ines.py $(SOURCE_INES) dpd0.bin dpd1.bin DCD

DPD0: dpd0.bin
	$(UTILS)/bin2dos.py 0x8000 dpd0.bin DPD0

DPD1: dpd1.bin
	$(UTILS)/bin2dos.py 0x8000 dpd1.bin DPD1

DONKEY: $(UTILS)/bin2dos.py donkey.bin
	$(UTILS)/bin2dos.py 0x0300 donkey.bin DONKEY

donkey.bin donkey.map &: donkey.cfg $(DONKEY_OBJECTS) 
	ld65 -m donkey.map -o donkey.bin -C donkey.cfg $(DONKEY_OBJECTS)

%.o: %.asm $(DONKEY_INCLUDES)
	ca65 $<
