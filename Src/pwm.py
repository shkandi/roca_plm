# source testve/bin/activate

import serial
import time
import random as rand

# Configure the serial connection (adjust port and baud rate as needed)
ser = serial.Serial(
    port='/dev/ttyUSB0',  # Replace with your port (e.g., 'COM3' on Windows)
    baudrate=115200,
    parity=serial.PARITY_NONE,
    stopbits=serial.STOPBITS_ONE,
    bytesize=serial.EIGHTBITS,
    timeout=1 # Set a timeout for read operations
)

ser.isOpen()
print("Connected to: " + ser.portstr)


ca = 1 << 6 | 1 << 4 | 8
frwr = b'\xA0' + ca.to_bytes(1, 'big') + b'\x00'
ser.write(frwr)

ca = 1 << 6 | 1 << 4 | 1
frwr = b'\xA1' + ca.to_bytes(1, 'big') + b'\xF0' + b'\x01'
ser.write(frwr)

for i in range(1, 9):
    input()
    ca = 1 << 6 | 1 << 4 | 8
    d = 2**i - 1
    frwr = b'\xA0' + ca.to_bytes(1, 'big') + d.to_bytes(1, 'big')
    ser.write(frwr)
ser.close()
