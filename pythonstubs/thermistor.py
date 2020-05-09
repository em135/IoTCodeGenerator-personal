import thread
from collections import namedtuple
from pipeline import Pipeline, Interceptor

try:
    import utime
except ModuleNotFoundError:
    import time as utime

class Thermistor:  # Name from sensor ID

    # Begin frequency
    def __init__(self, sensor):
        # If sampling type is frequency, we run a loop in a thread specific to the sensor
        # Alternatively we can have a central timer dispatch thread
        # For all sensors that have a frequency technique, we must acquire their state locks in connection.py and join on them
        self.thread = thread.Thread(self.__timer, "ThreadThermistor")
        self.thread.start()

        self.sensor = sensor
        self.variables = {}
    
    #This is the timer loop
    def __timer(self, thread: thread.Thread):
        while thread.active:
            utime.sleep(2)  # 2 seconds
            # Perform sampling
            # I2C example with motion sensor
            _vals = self.sensor.get_values()
            tup = namedtuple("x", "ax ay az t gx hy gz")
            x = tup(_vals["AcX"],_vals["AcY"],_vals["AcZ"],_vals["Tmp"],_vals["GyX"],_vals["GyY"],_vals["GyZ"])

            for variable in self.variables:
                for pipeline in self.variables[variable]:
                    pipeline.handle(x)
    # End frequency

    # We always have a signal method for handling the kill command
    def signal(self, command: str):
        if command == "kill":
            self.thread.interrupt()
        # Begin signal
        # If sampling type is signal, then we have a signal method that handles the signal command
        elif command == "signal":
            # Perform sampling
            # I2C example with motion sensor
            _vals = self.sensor.get_values()
            tup = namedtuple("x", "ax ay az t gx hy gz")
            x = tup(_vals["AcX"],_vals["AcY"],_vals["AcZ"],_vals["Tmp"],_vals["GyX"],_vals["GyY"],_vals["GyZ"])

            for variable in self.variables:
                for pipeline in self.variables[variable]:
                    pipeline.handle(x)
        # End signal
    
    # Begin testing
    # For testing purposes, allows ud so hook into the middle of pipelines
    # We might only want to generate this is a certain argument is passed to the generator?
    def add_pipeline(self, identifier: str, pipeline: Pipeline):
        if not identifier in self.variables:
            self.variables[identifier] = [pipeline]
        else:
            self.variables[identifier].append(pipeline)
    
    def get_pipeline(self, identifier: str, index: int):
        return self.variables[identifier][index]
    # End testing

# Begin generated
# An interceptor class is generated for every segment of every pipeline
class InterceptorFilter1(Interceptor):

    def handle(self, x):
        print("Filter")
        should_continue = x.ax < 1000 and x.ay > 0
        if should_continue:
            self.next.handle(x)

class InterceptorMap1(Interceptor):

    def handle(self, x):
        print("Map")
        newValue = x.ay * 5 + 3
        self.next.handle(newValue)

class InterceptorWindowMean1(Interceptor):

    def __init__(self, next: Interceptor):
        super().__init__(next)
        self.buffer = []
    
    def handle(self, x):
        print("Window")
        self.buffer.append(x)
        if len(self.buffer) == 3:
            result = sum(self.buffer) / len(self.buffer)
            self.buffer = []
            self.next.handle(result)
# End generated
