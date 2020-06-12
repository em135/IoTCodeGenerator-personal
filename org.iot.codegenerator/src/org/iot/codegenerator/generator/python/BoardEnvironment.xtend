package org.iot.codegenerator.generator.python

import org.eclipse.xtend.lib.annotations.Accessors
import java.util.Collection
import org.iot.codegenerator.codeGenerator.Channel
import org.iot.codegenerator.codeGenerator.Sensor
import org.iot.codegenerator.codeGenerator.SensorData
import org.iot.codegenerator.codeGenerator.ScreenOut

class BoardEnvironment {
	
	@Accessors String name
	@Accessors Collection<Channel> inheritedChannels
	@Accessors Collection<Channel> inheritedInputs
	@Accessors Collection<Sensor> inheritedSensors
	
	def usesOled() {
		for (sensor : inheritedSensors){
			for (data : sensor.datas){
				if (data instanceof SensorData){
					for (output: data.outputs){
						if (output instanceof ScreenOut){
							return true
						}
					}
				}
			}
		}
		return false
	}
	
}