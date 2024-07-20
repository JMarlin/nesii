#!/usr/bin/env python3

import sys

load_address = int(sys.argv[1], 0)
input_file = open(sys.argv[2], "rb")
input_data = input_file.read()
input_file.close()
input_length = len(input_data)
output_file = open(sys.argv[3], "wb")

output_file.write(bytes([
    (load_address >> 0) & 0xFF, (load_address >> 8) & 0xFF,
    (input_length >> 0) & 0xFF, (input_length >> 8) & 0xFF
]))

output_file.write(input_data)

output_file.close()
