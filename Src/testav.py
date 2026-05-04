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

for i in range(0, 10):
    # simple write test
    for j in range(0, 4):
        ca = 1 << 6 | j << 4
        frwr = b'\xAF' + ca.to_bytes(1, 'big')

        testarr = [0]*16
        for k in range(0, len(testarr)):
            testarr[k] = rand.randint(0,255)  # .to_bytes(1, 'big')
            frwr = frwr + testarr[k].to_bytes(1, 'big');
    
        ser.write(frwr)
        ca = 0 << 6 | j << 4
        frrq = b'\xAF' + ca.to_bytes(1, 'big')
        ser.write(frrq)
        time.sleep(0.2)
        frrd = ser.read(18)
        resarr = list(frrd)[2:]

        if resarr == testarr:
            print("ok")
        else:
            print("error", i, j)

    # or-write test
    for j in range(0, 4):
        ca = 1 << 6 | j << 4
        frwr = b'\xAF' + ca.to_bytes(1, 'big')

        testarr = [0]*16
        oparr = [0]*16
        for k in range(0, len(testarr)):
            testarr[k] = rand.randint(0,255)
            oparr[k] = rand.randint(0,255)
            frwr = frwr + testarr[k].to_bytes(1, 'big');
    
        # print(frwr.hex())
        ser.write(frwr)
         
        ca = 2 << 6 | j << 4
        frwr = b'\xAF' + ca.to_bytes(1, 'big')
        for k in range(0, len(testarr)):
            testarr[k] = testarr[k] | oparr[k]
            frwr = frwr + oparr[k].to_bytes(1, 'big');
        
        ser.write(frwr)
        ca = 0 << 6 | j << 4
        frrq = b'\xAF' + ca.to_bytes(1, 'big')
        ser.write(frrq)
        time.sleep(0.2)
        frrd = ser.read(18)
#         print(frrd.hex())
        resarr = list(frrd)[2:]
        if resarr == testarr:
            print("ok")
        else:
            print("error", i, j)

    # and-write test
    for j in range(0, 4):
        ca = 1 << 6 | j << 4
        frwr = b'\xAF' + ca.to_bytes(1, 'big')

        testarr = [0]*16
        oparr = [0]*16
        for k in range(0, len(testarr)):
            testarr[k] = rand.randint(0,255)
            oparr[k] = rand.randint(0,255)
            frwr = frwr + testarr[k].to_bytes(1, 'big');
    
#         print(frwr.hex())
        ser.write(frwr)       
        ca = 3 << 6 | j << 4
        frwr = b'\xAF' + ca.to_bytes(1, 'big')
        for k in range(0, len(testarr)):
            testarr[k] = testarr[k] &  oparr[k]
            frwr = frwr + oparr[k].to_bytes(1, 'big');
        
        ser.write(frwr)
        ca = 0 << 6 | j << 4
        frrq = b'\xAF' + ca.to_bytes(1, 'big')
        ser.write(frrq)
        time.sleep(0.2)
        frrd = ser.read(18)
#         print(frrd.hex())
        resarr = list(frrd)[2:]
        if resarr == testarr:
            print("ok")
        else:
            print("error", i, j)

ser.close()
