package org.iot.codegenerator.validation

import java.util.List
import java.util.Map

// This class should be in the util folder, but a bug is preventing this
class ESP32 {
		
	// The number of values read from the sensors
	Map<String, Integer> sensorParameterCount = #{
		"light" -> 1,
		"thermometer" -> 2,
		"motion" -> 7
	}
	
	Map<String, List<String>> sensorVariables = #{
		"light" -> newArrayList("lux"),
		"thermometer" -> newArrayList("tmp", "hum"),
		"motion" -> newArrayList("acX", "acY", "acZ", "tmp", "gyX", "gyY", "gyZ")
	}

	def getSensors() {
		this.sensorParameterCount?.keySet
	}

	def int getParameterCount(String sensor) {
		this.sensorParameterCount.getOrDefault(sensor, -1)
	}
	
	def getSensorVariables(String sensor){
		this.sensorVariables.get(sensor)
	}
}
