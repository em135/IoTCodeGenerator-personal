package org.iot.codegenerator.validation

import java.util.Map

class ESP32 {

	// The number of values read from the sensors
	Map<String, Integer> sensorParameterCount = #{
		"light" -> 1,
		"thermometer" -> 2,
		"motion" -> 7
	}

	def getSensors() {
		this.sensorParameterCount?.keySet
	}

	def int getParameterCount(String sensor) {
		this.sensorParameterCount.getOrDefault(sensor, -1)
	}

}
