package org.iot.codegenerator.validation

import java.util.Map

class ESP32 {

	// The number of values read from the sensors
	Map<String, Integer> sensorParameterCount = #{
		"temperature" -> 1,
		"humidity" -> 1,
		"light" -> 1,
		"motion" -> 7
	}

	def getSensors() {
		this.sensorParameterCount?.keySet
	}

	def int getParameterCount(String sensor) {
		this.sensorParameterCount.getOrDefault(sensor, -1)
	}

}
