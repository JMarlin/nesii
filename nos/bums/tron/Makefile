TRON_OBJECTS = tron.o
TRON_TARGETS = tron.bin TRON.BUM
TRON_INCLUDES = ../../nos_calls.inc ../../system/console.inc
UTILS = ../../../build_util

.PHONY: all
all: TRON.BUM

clean:
	rm -f $(TRON_OBJECTS)
	rm -f $(TRON_TARGETS)

TRON.BUM: tron.bin
	$(UTILS)/bin2dos.py 0x6c00 tron.bin TRON.BUM

tron.bin: tron.cfg $(TRON_OBJECTS)
	ld65 -m tron.map -o tron.bin -C tron.cfg $(TRON_OBJECTS)

%.o: %.asm $(TRON_INCLUDES)
	ca65 $<
