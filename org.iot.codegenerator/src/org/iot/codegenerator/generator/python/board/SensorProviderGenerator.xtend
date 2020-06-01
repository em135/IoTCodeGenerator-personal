package org.iot.codegenerator.generator.python.board

import org.iot.codegenerator.generator.python.GeneratorEnvironment
import org.iot.codegenerator.codeGenerator.Board
import org.iot.codegenerator.codeGenerator.Sensor
import org.iot.codegenerator.codeGenerator.OnbSensor
import java.util.Arrays
import static extension org.iot.codegenerator.generator.python.GeneratorUtil.*

class SensorProviderGenerator { 
	
	// Changed with sensor
	def compile(Board board) {
		val env = new GeneratorEnvironment()
		
		'''
		from machine import Pin, I2C
		i2c = I2C(-1, Pin(26, Pin.IN), Pin(25, Pin.OUT))
		 
		class default_wrapper:
			# TODO: implement your external sensor
			
			# init your library
			def __init__(self):
				pass
			
			# returns data value(s)
			def read_data(self):
				return -1
        «FOR sensor : board.inheritedSensors»
        «IF sensor instanceof OnbSensor»

		class «sensor.sensortype»_wrapper:
		
			def __init__(self):
				«sensor.getInitDriver(env)»
			
			def read_data(self):
				«sensor.getReadDriver(env)»
		«ENDIF»
        «ENDFOR»
		'''
	}
	
	private def String getInitDriver(Sensor sensor, GeneratorEnvironment env){
		if (!Arrays.asList("thermometer", "motion", "light").contains(sensor.sensortype)) {
			return '''
			# TODO: not yet supported
			pass'''
		} else if (sensor.sensortype == "thermometer") {
			return '''
			from hts221 import HTS221
			self.driver = HTS221(i2c)'''
		} else if (sensor.sensortype == "light") {
			return '''
			from bh1750 import BH1750
			self.driver = BH1750(i2c)'''
		} else if (sensor.sensortype == "motion") {
			return '''
			from mpu6050 import MPU6050
			self.driver = MPU6050(i2c)'''
		} 
	}
	
	private def String getReadDriver(Sensor sensor, GeneratorEnvironment env){
		if (!Arrays.asList("thermometer", "motion", "light").contains(sensor.sensortype)) {
			return '''
			# TODO: not yet supported
			return -1'''
		} else if(sensor.sensortype == "thermometer") {
			return ''' 
			return dict(tmp=int(self.driver.read_temp()),hum=int(self.driver.read_humi()))'''
		} else if (sensor.sensortype == "light") {
			return '''return dict(lux=int(self.driver.luminance(0x10)))'''
		} else if (sensor.sensortype == "motion") {
			return '''
			# return a dictionary with 7 keys
			return self.driver.get_values()'''
		} 
	}
	
}