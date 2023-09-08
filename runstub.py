#!/opt/homebrew/bin/python3

from serial import Serial
import sys
import time

ser = Serial('/dev/cu.usbserial-A5XK3RJT', 115200)
ser.reset_input_buffer()
ser.reset_output_buffer()
ser.write(b"C600 X\r\n")

file = open(sys.argv[1], "rb")
loadAddress = int(sys.argv[2], 16)

print("flushing monitor output")
while True:

    while ser.in_waiting != 0:
        ser.read(1)

    time.sleep(0.5)

    if ser.in_waiting == 0:
        break

print("setting load address...", end="")
sys.stdout.flush()
ser.write(bytes(sys.argv[2] + "+ ", 'ascii'))
print(ser.read(len(sys.argv[2] + "+ ")).decode('ascii'))
sys.stdout.flush()
print("done")

print("sending file", end="")
sys.stdout.flush()

while True:
    byte = file.read(1)

    if byte == b"":
        break

    cmdString = byte.hex() + ", "
    ser.write(bytes(cmdString, 'ascii'))
    readback = ser.read(4).decode('ascii')

    if readback != cmdString:
        print("ERROR: {} != {}")
        quit()

    print(readback, end="")
    sys.stdout.flush()

print("done")

print("jumping to load address...", end="")
sys.stdout.flush()
ser.write(bytes(sys.argv[2] + " G ", 'ascii'))
print(ser.read(len(sys.argv[2] + " G ")).decode('ascii'))
sys.stdout.flush()

print("done")
sys.stdout.flush()

ser.close()
file.close()
