package org.iot.codegenerator.validation

import java.util.Map

class ESP32 extends GenericBoard {

	// Different configurations for different versions
	static Map<String, Integer> wrover = #{
		"thermometer" -> 2,
		"barometer" -> 1,
		"lux" -> 1,
		"motion" -> 7,
		"magnetometer" -> 3
	}

	String version
	Map<String, Integer> sensors

	new(String version) {
		this.version = version

		switch version {
			case "wrover": sensors = wrover
			case "default": sensors = null
		}
	}

	override getVersion() {
		version
	}

	override getSensors() {
		this.sensors?.keySet
	}

	override int getVariableCount(String sensor) {
		if (this.sensors === null) {
			-1
		} else {
			this.sensors.getOrDefault(sensor, -1)
		}
	}

	override toString() {
		'''ESP-32-«this.version»'''
	}
}
