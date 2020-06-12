package org.iot.codegenerator.generator.python.board

import org.iot.codegenerator.codeGenerator.Board
import org.iot.codegenerator.codeGenerator.Sensor
import org.iot.codegenerator.generator.python.GeneratorEnvironment

import static extension org.iot.codegenerator.util.GeneratorUtil.*
import static extension org.iot.codegenerator.util.InheritanceUtil.*

class SensorProviderGenerator { 
	
	def compile(Board board) {
		val env = new GeneratorEnvironment()
		
		'''
		from machine import Pin, I2C
		i2c = I2C(-1, Pin(26, Pin.IN), Pin(25, Pin.OUT))
		 
        «FOR sensor : board.inheritedSensors»

		class «sensor.sensorType»_wrapper:
		
			def __init__(self):
				«sensor.getInitDriver(env)»
			
			def read_data(self):
				«sensor.getReadDriver(env)»
        «ENDFOR»
		'''
	}
	
	private def String getInitDriver(Sensor sensor, GeneratorEnvironment env){
		val sensorType = sensor.sensorType
		switch (sensorType) {
			case "thermometer": {
			'''
			# Onboard sensor
			from hts221 import HTS221
			self.driver = HTS221(i2c)
			'''
			}
			case "motion" : {
			'''
			# Onboard sensor
			from mpu6050 import MPU6050
			self.driver = MPU6050(i2c)
			'''
			}
			case "light" : {
			'''
			# Onboard sensor
			from bh1750 import BH1750
			self.driver = BH1750(i2c)
			'''
			}
			default: {
			'''
			# External sensor
			from «sensorType»_driver import «sensorType.asClass»_driver
			self.driver = «sensorType.asClass»_driver()'''
		
			}
		}
	}
	
	private def String getReadDriver(Sensor sensor, GeneratorEnvironment env){
			val sensorType = sensor.sensorType
		switch (sensorType) {
			case "thermometer": {
				'''return dict(tmp=int(self.driver.read_temp()),hum=int(self.driver.read_humi()))'''
			}
			case "motion" : {
				'''return self.driver.get_values()'''
			}
			case "light" : {
				'''return dict(lux=int(self.driver.luminance(0x10)))'''
			}
			default: {
				'''return self.driver.get_values()'''
			}
		}
	}
	
}