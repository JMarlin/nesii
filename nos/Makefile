all: nos.do

.PHONY: system
system: 
	make -C system

.PHONY: shell
shell:
	make -C shell

nos.do: system shell
	~/Downloads/cp2_1.0.2_osx-x64_fd/cp2 cdi --overwrite nos_data.do 140k DOS	
	~/Downloads/cp2_1.0.2_osx-x64_fd/cp2 add nos_data.do shell/SHELL
	~/Downloads/cp2_1.0.2_osx-x64_fd/cp2 sa nos_data.do SHELL type=bin
	dd if=nos_data.do of=nos_data.bin bs=256 skip=16
	dd if=/dev/zero of=nos_boot_padding.bin bs=256 count=556
	cat system/system.bin > nos_boot_only.bin
	cat nos_boot_padding.bin >> nos_boot_only.bin
	../skew-dsk.py nos_boot_only.bin nos_boot_only.do
	dd if=nos_boot_only.do of=nos_boot_track.bin bs=256 count=16
	cat nos_boot_track.bin > nos.do
	cat nos_data.bin >> nos.do
