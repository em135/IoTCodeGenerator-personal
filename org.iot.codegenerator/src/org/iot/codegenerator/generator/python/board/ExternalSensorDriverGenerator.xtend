package org.iot.codegenerator.generator.python.board

import org.iot.codegenerator.codeGenerator.Sensor
import static extension org.iot.codegenerator.generator.python.GeneratorUtil.*

class ExternalSensorDriverGenerator {
		
	def compile(Sensor sensor) {		
		'''
		"""
		Micropython driver for the external sensor «sensor.sensortype»
		This file will not be overwritten by the IoT code generator
		Use this to implement the required driver to read from the external sensor «sensor.sensortype»
		It is required to implement the constructor and the get_values() method
		"""
		
		class «sensor.sensortype.asClass»_driver:
		
			def __int__(self):
				pass
			
			def get_values(self):
				pass
		
		'''
	}
}