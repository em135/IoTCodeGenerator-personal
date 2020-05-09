package org.iot.codegenerator.generator.python.board

import org.iot.codegenerator.codeGenerator.Board
import org.iot.codegenerator.generator.python.GeneratorEnvironment

import static extension org.iot.codegenerator.generator.python.GeneratorUtil.*
import static extension org.iot.codegenerator.generator.python.ImportGenerator.*

class DeviceGenerator {

	def String compile(Board board) {
		val env = new GeneratorEnvironment()
		val classDef = board.compileClass(env)

		'''
			«env.compileImports»
			
			«classDef»
		'''
	}

	private def String compileClass(Board board, GeneratorEnvironment env) {
		'''
			class «board.name.asClass»:
				
				«board.compileConstructor(env)»
				«board.compileSetupMethods(env)»
				«board.compileInputLoop(env)»
				«board.compileRunMethod(env)»
		'''
	}

	private def String compileConstructor(Board board, GeneratorEnvironment env) {
		'''
			def __init__(self):
				self._sensors = {}
				self._output_channels = []
				«IF board.input !== null»
					self._input_channel = None
					self._in_thread = «env.useImport("thread")».Thread(self._input_loop, "ThreadInput")
				«ENDIF»
			
		'''
	}

	private def String compileSetupMethods(Board board, GeneratorEnvironment env) {
		'''
			def add_sensor(self, identifier: str, sensor):
				self._sensors[identifier] = sensor
			
			def add_output_channel(self, channel):
				self._output_channels.append(channel)
			
			«IF board.input !== null»
				def set_input_channel(self, channel):
					self._input_channel = channel
				
			«ENDIF»
		'''
	}

	private def String compileInputLoop(Board board, GeneratorEnvironment env) {
		'''
			«IF board.input !== null»
				def _input_loop(self, thread: thread.Thread):
					while thread.active:
						command = self._input_channel.receive().decode("utf-8")
						print("Received: " + command)
						elements = command.split(":")
						sensor = self._sensors[elements[0]]
						sensor.signal(elements[1])
				
			«ENDIF»
		'''
	}

	private def String compileRunMethod(Board board, GeneratorEnvironment env) {
		val frequencySensors = board.sensors.filter[isFrequency]

		'''
			def run(self):
				«IF board.input !== null»
					self._in_thread.start()
					
				«ENDIF»
				«env.useImport("thread")».join([
					«IF board.input !== null»
						self._in_thread«IF !frequencySensors.empty»,«ENDIF»
					«ENDIF»
					«FOR sensor : frequencySensors SEPARATOR ","»
						self._sensors["«sensor.sensortype.asModule»"].thread
					«ENDFOR»
					# TODO: Join on threads from output channels
				])
		'''
	}
}
