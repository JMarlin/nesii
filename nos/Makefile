UTILS = ../build_util
CIDERPRESS2 = ~/Downloads/cp2_1.0.2_osx-x64_fd

.PHONY: all
all: nos.do

.PHONY: clean
clean:
	make clean -C system
	make clean -C shell
	rm -f *.bin *.do

.PHONY: system
system: 
	make -C system

.PHONY: shell
shell:
	make -C shell

nos.do: system shell
	$(CIDERPRESS2)/cp2 cdi --overwrite nos_data.do 140k DOS	
	$(CIDERPRESS2)/cp2 add nos_data.do shell/SHELL
	$(CIDERPRESS2)/cp2 sa nos_data.do SHELL type=bin
	dd if=nos_data.do of=nos_data.bin bs=256 skip=16
	dd if=/dev/zero of=nos_boot_padding.bin bs=256 count=12
	cat system/system.bin > nos.do
	cat nos_boot_padding.bin >> nos.do
	cat nos_data.bin >> nos.do
