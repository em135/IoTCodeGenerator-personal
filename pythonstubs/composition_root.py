# TODO: Only import things that are actually used, keep track
# of an import collection during generation, for instance by
# having an environment object that is being passed around,
# and generating the code templates from the inside-out
# TODO: Choose between importing into namespace or referencing,
# e.g. InterceptorMap1 vs thermistor.InterceptorMap1
# TODO: Make a separate package for python code generators
from mpu6050 import MPU6050
from pipeline import Pipeline
from communication import Serial, Wifi
from thermistor import Thermistor, InterceptorFilter1, InterceptorMap1, InterceptorWindowMean1
from board import Board
import struct

# MicroPython dependencies. The Testing framework can provide stubs
# for the machine module to prevent import errors, and then simply override
# the composition root to return stubs rather than real sensor drivers
from machine import Pin, I2C
# Fall back to the native python library if not running on MicroPython
try:
    import ujson
except ModuleNotFoundError:
    import json as ujson

# To allow for easily modifying the composition, or simply using the generated one
# This is a very basic style of dependency injection framework

class CompositionRoot:

    def __init__(self):
        # Singleton channels
        self._outserial = None
        self._inserial = None
        self._endpoint1 = None

        with open("conf-filled.json", "r") as _conf_file:
            self.configuration = ujson.loads("".join(_conf_file.readlines()))

    # Uses the entire composition root to instantiate the board object
    def provide_board(self):
        # We can generate code that instantiates different types of board if needed
        board = Board()
        board.add_sensor("thermistor", self.provide_sensor_thermistor())
        board.set_input_channel(self.provide_channel_inserial())
        board.add_output_channel(self.provide_channel_outserial())
        board.add_output_channel(self.provide_channel_endpoint1())
        return board

    # A provide method is created for every sensor
    def provide_sensor_thermistor(self):
        _thermistor = Thermistor(self.provide_driver_mpu6050())
        _thermistor.add_pipeline("voltage", self.provide_pipeline_thermistor_voltage_1())
        return _thermistor

    # And for every driver that is referenced somewhere
    # The testing framework simply overrides these driver providers and returns
    # testing stubs
    def provide_driver_mpu6050(self):
        return MPU6050(I2C(-1, scl=Pin(26, Pin.IN), sda=Pin(25, Pin.OUT)))

    # And for every pipeline
    def provide_pipeline_thermistor_voltage_1(self):
        outserial = self.provide_channel_outserial()
        return Pipeline(InterceptorFilter1(InterceptorMap1(InterceptorWindowMean1(
            type('Sink', (object,), {
                "handle": lambda data: outserial.send(struct.pack("f", data)),
                # endpoint1.send(struct.pack("d", data))
                # outserial.send(data.encode("utf-8"))
                "next": None
            })
        ))))
    
    # And for every channel (but only if it is referenced somewhere)
    # TODO: Instantiate channels that are registered in the environment after
    # generating the rest inside-out
    def provide_channel_inserial(self):
        if not self._inserial:
            self._inserial = self.make_channel("inserial")
        return self._inserial
    
    def provide_channel_outserial(self):
        if not self._outserial:
            self._outserial = self.make_channel("outserial")
        return self._outserial
    
    def provide_channel_endpoint1(self):
        if not self._endpoint1:
            self._endpoint1 = self.make_channel("endpoint1")
        return self._endpoint1
    
    def make_channel(self, identifier: str):
        if self.configuration[identifier]["type"] == "serial":
            return Serial(self.configuration["serial"]["baud"],
                          self.configuration["serial"]["databits"],
                          self.configuration["serial"]["paritybits"],
                          self.configuration["serial"]["stopbit"])
        
        elif self.configuration[identifier]["type"] == "wifi":
            return Wifi(self.configuration[identifier]["lane"], 
                        self.configuration["wifi"]["ssid"],
                        self.configuration["wifi"]["password"])

# Users can override methods to modify the objects as the
# dependency graph is constructed.
class CustomCompositionRoot(CompositionRoot):
    
    # For instance, users can inject their own interceptors into an existing
    # pipeline, or provide a different pipeline altogether
    def provide_pipeline_thermistor_voltage_1(self):
        return super().provide_pipeline_thermistor_voltage_1()\
            .add(2, InterceptorMap1(None))
