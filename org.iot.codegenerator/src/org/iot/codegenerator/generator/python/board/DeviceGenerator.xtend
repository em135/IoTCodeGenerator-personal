package org.iot.codegenerator.generator.python.board

import org.iot.codegenerator.generator.python.BoardEnvironment
import org.iot.codegenerator.generator.python.GeneratorEnvironment

import static extension org.iot.codegenerator.generator.python.ImportGenerator.*
import static extension org.iot.codegenerator.util.GeneratorUtil.*

class DeviceGenerator {
	
	def String compile(BoardEnvironment boardEnv) {
		val genEnv = new GeneratorEnvironment()
		val classDef = boardEnv.compileClass(genEnv)

		'''
			«genEnv.compileImports»
			
			«classDef»
		'''
	}

	private def String compileClass(BoardEnvironment boardEnv, GeneratorEnvironment genEnv) {
		'''
			class «boardEnv.name.asClass»:
				
				«boardEnv.compileConstructor(genEnv)»
				«boardEnv.compileSetupMethods(genEnv)»
				«boardEnv.compileInputLoop(genEnv)»
				«boardEnv.compileRunMethod(genEnv)»
		'''
	}

	private def String compileConstructor(BoardEnvironment boardEnv, GeneratorEnvironment genEnv) {
		'''
			def __init__(self):
				self._sensors = {}
				self._output_channels = []
				«IF !boardEnv.inheritedInputs.empty»
					self._input_channels = []
					self._in_thread = «genEnv.useImport("thread")».Thread(self._input_loop, "ThreadInput")
				«ENDIF»
			
		'''
	}

	private def String compileSetupMethods(BoardEnvironment boardEnv, GeneratorEnvironment genEnv) {
		'''
			def add_sensor(self, identifier: str, sensor):
				self._sensors[identifier] = sensor
			
			def add_output_channel(self, channel):
				self._output_channels.append(channel)
			
			«IF !boardEnv.inheritedInputs.empty»
				def add_input_channel(self, channel):
					self._input_channels.append(channel)
				
			«ENDIF»
		'''
	}

	private def String compileInputLoop(BoardEnvironment boardEnv, GeneratorEnvironment genEnv) {
		'''
			«IF !boardEnv.inheritedInputs.empty»
				def _input_loop(self, thread: thread.Thread):
					while thread.active:
						for input_channel in self._input_channels:
							command = input_channel.receive().decode("utf-8")
							print("Received: " + command)
							elements = command.split(":")
							sensor = self._sensors[elements[0]]
							sensor.signal(elements[1])
			«ENDIF»
			
		'''
	}

	private def String compileRunMethod(BoardEnvironment boardEnv, GeneratorEnvironment genEnv) {
		val frequencySensors = boardEnv.inheritedSensors.filter[isFrequency]

		'''
			def run(self):
				«IF !boardEnv.inheritedInputs.empty»
					self._in_thread.start()
					
				«ENDIF»
				«genEnv.useImport("thread")».join([
					«IF !boardEnv.inheritedInputs.empty»
						self._in_thread«IF !frequencySensors.empty»,«ENDIF»
					«ENDIF»
					«FOR sensor : frequencySensors SEPARATOR ","»
						self._sensors["«sensor.sensorType.asModule»"].thread
					«ENDFOR»
					# TODO: Join on threads from output channels
				])
		'''
	}
}
