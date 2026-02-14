import serial
import time
import random as rand

# Configure the serial connection (adjust port and baud rate as needed)
ser = serial.Serial(
    port='/dev/ttyUSB0',  # Replace with your port (e.g., 'COM3' on Windows)
    baudrate=9600,
    parity=serial.PARITY_NONE,
    stopbits=serial.STOPBITS_ONE,
    bytesize=serial.EIGHTBITS,
    timeout=1 # Set a timeout for read operations
)

ser.isOpen()
print("Connected to: " + ser.portstr)

testarr = [b'\x00']*256

for i in range(0, 256):
    testarr[i] = rand.randint(0,255).to_bytes()

input('writing to dev')
for i in range(0,256):
    frame = b'\x55\x01' + i.to_bytes() + testarr[i]
    ser.write(frame) # The 'b' prefix indicates bytes
    time.sleep(0.25)

resarr = [b'\x00']*256
input('reading from dev')

for i in range(0,256):
    frame = b'\x55\x00' + i.to_bytes()
    ser.write(frame)
    time.sleep(0.25)
    resarr[i] = ser.read()
    time.sleep(0.25)

input('compare')
for i in range(0,256):
    if testarr[i] != resarr[i]:
        print(i, testarr[i], resarr[i])

ser.close()
