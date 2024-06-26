#!/usr/bin/env python3

import sys

unskewed_disk_buffer = []
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
prg_buffer = nes_file.read(0x4000 * prg_size)

#Get CHR data
chr_buffer = nes_file.read(0x2000)

nes_file.close()

# Write boot sector (TODO)
for i in range(0, 0x100):
    unskewed_disk_buffer.append(0xAA)

# Write PRG ROM data
for i in range(0, 0x4000 * prg_size):
    unskewed_disk_buffer.append(int(prg_buffer[i]))

# Write it again if we're only 16k
if prg_size == 1:
    for i in range(0, 0x4000):
        unskewed_disk_buffer.append(int(prg_buffer[i]))

# Write CHR ROM data
for i in range(0, 0x2000):
    unskewed_disk_buffer.append(int(chr_buffer[i]))

#
#for track in range(0, 0x23):
#    for sector in range(0, 0x10):
#        for byte in range(0, 0x80):
#            buffer.append(track)
#            buffer.append(sector)

dsk_file = open("st.dsk", "wb")

reverse_skewed_sector_number = [
    0x0, 0xD, 0xB, 0x9,
    0x7, 0x5, 0x3, 0x1,
    0xE, 0xC, 0xA, 0x8,
    0x6, 0x4, 0x2, 0xF
]

#Skew the data in DOS 3.3 format
for track in range(0, 0x23):
    for sector in range(0, 0x10):
        for byte in range(0, 0x100):
            skewed_index = track*0x1000 + reverse_skewed_sector_number[sector]*0x100 + byte
            if(skewed_index >= len(unskewed_disk_buffer)):
                dsk_file.write(bytes([0x00]))
            else:
                dsk_file.write(bytes([unskewed_disk_buffer[skewed_index]]))

dsk_file.close()

