DONKEY_OBJECTS = entry.o launcher.o
DONKEY_INCLUDES = launcher.inc ../nos/nos_calls.inc

.PHONY: all
all: DONKEY DPD0 DPD1 DCD

dpd0.bin dpd1.bin dcd.bin &: ../split-ines.py ../bin2dos.py
	../split-ines.py ~/donkey.nes dpd0.bin dpd1.bin DCD

DPD0: dpd0.bin
	../bin2dos.py 0x8000 dpd0.bin DPD0

DPD1: dpd1.bin
	../bin2dos.py 0x8000 dpd1.bin DPD1


DONKEY: ../bin2dos.py donkey.bin
	../bin2dos.py 0x0300 donkey.bin DONKEY

donkey.bin: donkey.cfg $(DONKEY_OBJECTS) 
	ld65 -m donkey.map -o donkey.bin -C donkey.cfg $(DONKEY_OBJECTS)

%.o: %.asm $(DONKEY_INCLUDES)
	ca65 $<
