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

ca = 0 << 6 | 0
frrq = b'\xA2' + ca.to_bytes(1, 'big')
ser.write(frrq)
time.sleep(0.2)
frrd = ser.read(5)
print(frrd.hex())

for i in range(0,3):
    ca = 0 << 6 | i 
    frrq = b'\xA0' + ca.to_bytes(1, 'big')
    ser.write(frrq)
    time.sleep(0.1)
    frrd = ser.read(3)
    print(frrd.hex())

ser.close()
