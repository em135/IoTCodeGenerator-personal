import thread
import sys

# An abstraction over Wifi vs serial communication
class Communication:

    def send(self, data: bytes):
        pass
    
    def receive(self) -> bytes:
        pass

# Communication over USB
class Serial(Communication):

    def __init__(self, baud: int, databits: int, paritybits: int, stopbit: int):
        # MicroPython - and I'm not the only one
        pass

    def send(self, data: bytes):
        print(data)
    
    def receive(self) -> bytes:
        data = sys.stdin.readline().replace("\r", "").replace("\n", "")
        return data.encode("utf-8")

# Wireless communication
class Wifi(Communication):

    def __init__(self, host: str, ssid: str, password: str):
        pass

    def send(self, data: bytes):
        print(data)
    
    def receive(self) -> bytes:
        pass
