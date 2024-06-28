#!/usr/bin/env python3

import sys

in_path = sys.argv[1]
in_file = open(in_path, "rb")
unskewed_disk_buffer = in_file.read()
in_file.close()

if len(unskewed_disk_buffer) != 0x23000:
    print("Input file is not the correct size")
    exit()

out_path = sys.argv[2]
out_file = open(out_path, "wb")

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
                out_file.write(bytes([0x00]))
            else:
                out_file.write(bytes([unskewed_disk_buffer[skewed_index]]))

out_file.close()

