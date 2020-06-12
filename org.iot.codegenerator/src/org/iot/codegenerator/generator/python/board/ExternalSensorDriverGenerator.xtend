package org.iot.codegenerator.generator.python.board

import org.iot.codegenerator.codeGenerator.Sensor
import static extension org.iot.codegenerator.util.GeneratorUtil.*

class ExternalSensorDriverGenerator {
		
	def compile(Sensor sensor) {		
		'''
		"""
		Micropython driver for the external sensor «sensor.sensorType»
		This file will not be overwritten by the IoT code generator
		Use this to implement the required driver to read from the external sensor «sensor.sensorType»
		It is required to implement the constructor and the get_values() method
		"""
		
		class «sensor.sensorType.asClass»_driver:
		
			def __int__(self):
				pass
			
			def get_values(self):
				pass
		
		'''
	}
}