UTILS = ../build_util
CIDERPRESS2 = ~/Downloads/cp2_1.0.2_osx-x64_fd
SOURCES = apple_extra.s apple_iscntc.s apple_loadsave.s array.s chrget.s defines.s defines_apple.s error.s eval.s extra.s float.s flow1.s flow2.s header.s init.s inline.s input.s iscntc.s loadsave.s macros.s memory.s message.s misc1.s misc2.s misc3.s poke.s print.s program.s rnd.s string.s token.s trig.s var.s zeropage.s msbasic.s

.PHONY: all
all: BASIC

.PHONY: clean
clean:
	rm -f *.o *.lbl *.bin BASIC

.PHONY: ../nos/nos.do
../nos/nos.do:
	make -C ../nos/

install: BASIC ../nos/nos.do
	$(CIDERPRESS2)/cp2 add ../nos/nos.do BASIC
	$(CIDERPRESS2)/cp2 sa ../nos/nos.do BASIC type=bin

BASIC: $(UTILS)/bin2dos.py basic.bin
	$(UTILS)/bin2dos.py 0x9D00 basic.bin BASIC

basic.o: $(SOURCES)
	ca65 -D nesii msbasic.s -o basic.o -l basic.lst
	
basic.bin: basic.o
	ld65 -C nesii.cfg basic.o -o basic.bin -Ln basic.lbl

