package org.iot.codegenerator.validation

import java.util.Map
import java.util.List
import java.util.Arrays

class ESP32 {

	// The number of values read from the sensors
	Map<String, Integer> sensorParameterCount = #{
		"light" -> 1,
		"thermometer" -> 2,
		"motion" -> 7
	}
	
	Map<String, List<String>> sensorVariables = #{
		"light" -> Arrays.asList("lux"),
		"thermometer" -> Arrays.asList("tmp", "hum"),
		"motion" -> Arrays.asList("acX", "acY", "acZ", "tmp", "gyX", "gyY", "gyZ")
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
