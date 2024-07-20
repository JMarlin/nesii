#!/usr/bin/env python3

import sys

nes_path = sys.argv[1]
nes_file = open(nes_path, "rb")

nes_magic = nes_file.read(4)
if nes_magic != b'NES\x1A':
    print("Could not find NES magic number")
    quit()

prg_size = int(nes_file.read(1)[0])
print("PRG ROM size is {}KB".format(prg_size * 16))

if prg_size != 1 and prg_size != 2:
    print("Only PRG sizes up to 32k are supported")
    quit()

chr_size = int(nes_file.read(1)[0])
print("CHR ROM size is {}KB".format(chr_size * 8))

if chr_size != 1:
    print("Only 8KB of CHR is supported")
    quit()

is_horizontal = (nes_file.read(1)[0] & 0x01) == 0x01

#Dump the rest of the header data, we don't care about it
flags_7  = nes_file.read(9)[0]

#Get PRG data
prg0_buffer = nes_file.read(0x4000)
prg1_buffer = bytes(prg0_buffer) if prg_size == 1 else nes_file.read(0x4000)

#Get CHR data
chr_buffer = nes_file.read(0x2000)

nes_file.close()

prg0_file = open(sys.argv[2], "wb")
prg0_file.write(prg0_buffer)
prg0_file.close()

prg1_file = open(sys.argv[3], "wb")
prg1_file.write(prg1_buffer)
prg1_file.close()

chr_file = open(sys.argv[4], "wb")
chr_file.write(chr_buffer)
chr_file.close()