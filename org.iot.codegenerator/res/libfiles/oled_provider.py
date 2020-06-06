from machine import Pin, I2C

from ssd1306 import SSD1306_I2C

i2c = I2C(-1, Pin(26, Pin.IN), Pin(25, Pin.OUT))


class OledWrapper:

    def __init__(self):
        self.oled = SSD1306_I2C(128, 32, i2c)

    def send(self, data):
        self.oled.push_line(str(data))
