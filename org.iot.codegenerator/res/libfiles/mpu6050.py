"""
Driver taken from: https://github.com/m-rtijn/mpu6050

This program handles the communication over I2C
between a Raspberry Pi and a MPU-6050 Gyroscope / Accelerometer combo.
Made by: MrTijn/Tijndagamer
Released under the MIT License
Copyright (c) 2015, 2016, 2017 MrTijn/Tijndagamer

This file has been modified by Kasper Schultz Davidsen by changing the name of
the class and removing the method val_test().

This file has been modified by Emil Nielsen by changing the names of the
variables returned from the dict in get_values().
"""


class MPU6050:
    def __init__(self, i2c, addr=0x68):
        self.iic = i2c
        self.addr = addr
        self.iic.start()
        self.iic.writeto(self.addr, bytearray([107, 0]))
        self.iic.stop()

    def get_raw_values(self):
        self.iic.start()
        a = self.iic.readfrom_mem(self.addr, 0x3B, 14)
        self.iic.stop()
        return a

    def get_ints(self):
        b = self.get_raw_values()
        c = []
        for i in b:
            c.append(i)
        return c

    def bytes_toint(self, firstbyte, secondbyte):
        if not firstbyte & 0x80:
            return firstbyte << 8 | secondbyte
        return - (((firstbyte ^ 255) << 8) | (secondbyte ^ 255) + 1)

    def get_values(self):
        raw_ints = self.get_raw_values()
        vals = {}
        vals["acX"] = self.bytes_toint(raw_ints[0], raw_ints[1])
        vals["acY"] = self.bytes_toint(raw_ints[2], raw_ints[3])
        vals["acZ"] = self.bytes_toint(raw_ints[4], raw_ints[5])
        vals["tmp"] = self.bytes_toint(raw_ints[6], raw_ints[7]) / 340.00 + 36.53
        vals["gyX"] = self.bytes_toint(raw_ints[8], raw_ints[9])
        vals["gyY"] = self.bytes_toint(raw_ints[10], raw_ints[11])
        vals["gyZ"] = self.bytes_toint(raw_ints[12], raw_ints[13])
        return vals  # returned in range of Int16
        # -32768 to 32767
