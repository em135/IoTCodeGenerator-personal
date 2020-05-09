package org.iot.codegenerator.validation

import java.util.Set
import org.iot.codegenerator.codeGenerator.Board

class UtilityBoard {

	def static GenericBoard getBoard(Board b) {
		getBoard(b.name, b.version)
	}

	def static GenericBoard getBoard(String model, String version) {
		val lowerCaseModel = model?.toLowerCase
		val lowerCaseVersion = version?.toLowerCase

		if (lowerCaseModel == "esp32") {
			return new ESP32(lowerCaseVersion)
		}

		return null
	}
}

abstract class GenericBoard {

	def String getVersion()

	def Set<String> getSensors()

	def int getVariableCount(String sensor)

	override String toString()
}
