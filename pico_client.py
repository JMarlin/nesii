from machine import Pin, UART
import rp2
import time
import sys
import select

shifts = 3
sendValue = 0x00
irqHappened = False
sendString = list(map(ord, "C600 X\r\nC800 X\r\n"))
sendStringIdx = -1

in0 = Pin(0, Pin.IN, Pin.PULL_UP)
in1 = Pin(1, Pin.IN, Pin.PULL_UP)
in2 = Pin(2, Pin.IN, Pin.PULL_UP)
in3 = Pin(3, Pin.IN, Pin.PULL_UP)

power = Pin(8, Pin.OUT)
power.value(True)

uart1 = UART(0, baudrate=115200, tx=Pin(12), rx=Pin(13))

@rp2.asm_pio(set_init=(rp2.PIO.OUT_LOW, rp2.PIO.OUT_LOW))
def getBits():
    wrap_target()
    pull()
    mov(osr, y)
    set(x, 3)
    label("get_byte")
    jmp(not_y, "dont_set_rx_ready")
    set(pins, 2)
    jmp("move_on")
    label("dont_set_rx_ready")
    set(pins, 3)
    label("move_on")
    wait(1, pin, 0) 
    wait(0, pin, 0) [31]
    in_(pins, 4)
    jmp(pin, "tx_ratchet")
    jmp(x_dec, "get_byte")
    label("tx_ratchet")
    set(pins, 0)
    push()
    irq(rel(0))
    wrap()
    
def appendBits(stateMachine):
    global irqHappened
    irqHappened = True
    
sm = rp2.StateMachine(0, getBits, in_base=Pin(0), set_base=Pin(4), jmp_pin=Pin(1))
sm.irq(appendBits)
sm.active(1)

out2 = Pin(6, Pin.OUT)
out3 = Pin(7, Pin.OUT)

def loadNextTxValue():
    global sm
    global out2
    global out3
    global shifts
    global sendStringIdx
    global sendString
    global sendValue
    
    if shifts == 3:
        
        if len(sendString) == 0:
            sendValue = 0
        else:
            sendString.reverse()
            sendValue = sendString.pop()
            sendString.reverse()
        
    shifts = (shifts + 1) % 4
    
    out2.value((sendValue >> ((3 - shifts) * 2)) & 0x01)
    out3.value((sendValue >> ((3 - shifts) * 2)) & 0x02)
    
    sm.put(len(sendString) != 0)
    
loadNextTxValue()

while True:
    time.sleep_us(1)
    
    if not irqHappened:
        continue
    
    if uart1.any():
        sendString.append(int(uart1.read(1)[0]))

    smValue = sm.get()
    
    if (smValue & 0x02) != 0:
        loadNextTxValue()
        continue
    
    convertedValue = ((smValue & 0xC000) >> 14) + ((smValue & 0xC00) >> 8) + ((smValue & 0xC0) >> 2) + ((smValue & 0xC) << 4)
    uart1.write(bytes([convertedValue]))
    sm.put(len(sendString) != 0)

