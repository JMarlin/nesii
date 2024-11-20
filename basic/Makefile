SOURCES = apple_extra.s apple_iscntc.s apple_loadsave.s array.s chrget.s defines.s defines_apple.s error.s eval.s extra.s float.s flow1.s flow2.s header.s init.s inline.s input.s iscntc.s loadsave.s macros.s memory.s message.s misc1.s misc2.s misc3.s poke.s print.s program.s rnd.s string.s token.s trig.s var.s zeropage.s msbasic.s

all: basic.bin

clean:
	rm -f *.o *.lbl *.bin

basic.o: $(SOURCES)
	ca65 -D applesoft msbasic.s -o basic.o
	
basic.bin: basic.o
	ld65 -C applesoft.cfg basic.o -o basic.bin -Ln basic.lbl

