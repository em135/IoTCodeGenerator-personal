package org.iot.codegenerator.generator.python.board

import org.iot.codegenerator.codeGenerator.ChannelOut
import org.iot.codegenerator.codeGenerator.Filter
import org.iot.codegenerator.codeGenerator.FrequencySampler
import org.iot.codegenerator.codeGenerator.Map
import org.iot.codegenerator.codeGenerator.Pipeline
import org.iot.codegenerator.codeGenerator.ScreenOut
import org.iot.codegenerator.codeGenerator.Sensor
import org.iot.codegenerator.codeGenerator.TransformationOut
import org.iot.codegenerator.codeGenerator.Variables
import org.iot.codegenerator.codeGenerator.Window
import org.iot.codegenerator.generator.python.GeneratorEnvironment

import static extension org.eclipse.xtext.EcoreUtil2.*
import static extension org.iot.codegenerator.generator.python.ExpressionGenerator.*
import static extension org.iot.codegenerator.generator.python.GeneratorUtil.*
import static extension org.iot.codegenerator.generator.python.ImportGenerator.*

class SensorGenerator {

	def String compile(Sensor sensor) {
		val env = new GeneratorEnvironment()
		val classDef = sensor.compileClass(env)

		'''
			«env.compileImports»
			
			«classDef»
		'''
	}

	private def String compileClass(Sensor sensor, GeneratorEnvironment env) {
		// TODO: Only generate testing utilities if we pass a testing flag to the generator
		'''
			class «sensor.sensortype.asClass»:
				
				«sensor.compileConstructor(env)»
				«sensor.compileTimerLoop(env)»
				«sensor.compileSignalHandler(env)»
				«compileTestUtilities()»
			
			«sensor.compileInterceptors(env)»
		'''
	}

	private def String compileConstructor(Sensor sensor, GeneratorEnvironment env) {
		'''
			def __init__(self, sensor):
				self.sensor = sensor
				self.variables = {}
				«IF sensor.isFrequency»
					self.thread = «env.useImport("thread")».Thread(self.__timer, "Thread«sensor.sensortype.asClass»")
					self.thread.start()
				«ENDIF»
				
		'''
	}

	private def String compileTimerLoop(Sensor sensor, GeneratorEnvironment env) {
		'''
			«IF sensor.isFrequency»
				def __timer(self, thread: thread.Thread):
					while thread.active:
						«env.useImport("utime")».sleep(«(sensor.sampler as FrequencySampler).delay»)
						«sensor.compileSensorSampling(env)»
				
			«ENDIF»
		'''
	}

	private def String compileSignalHandler(Sensor sensor, GeneratorEnvironment env) {
		'''
			def signal(self, command: str):
				«IF sensor.isFrequency»
					if command == "kill":
						self.thread.interrupt()
				«ENDIF»
				«IF sensor.isSignal»
					«IF sensor.isFrequency»el«ENDIF»if command == "signal":
						«sensor.compileSensorSampling(env)»
				«ENDIF»
			
		'''
	}

	private def String compileSensorSampling(Sensor sensor, GeneratorEnvironment env) {
		'''
		# TODO: Unsupported
		pass
		'''
	}

	private def String compileTestUtilities() {
		'''
			def add_pipeline(self, identifier: str, pipeline):
				if not identifier in self.variables:
					self.variables[identifier] = [pipeline]
				else:
					self.variables[identifier].append(pipeline)
				
			def get_pipeline(self, identifier: str, index: int):
				return self.variables[identifier][index]
			
		'''
	}

	private def String compileInterceptors(Sensor sensor, GeneratorEnvironment env) {
		'''
			«FOR data : sensor.sensorDatas»
				«FOR out : data.outputs»
					«out.compileOut(env)»
				«ENDFOR»
			«ENDFOR»
		'''
	}
	
	private dispatch def String compileOut(ChannelOut out, GeneratorEnvironment env) {
		'''«out.pipeline.compileInterceptors(env)»'''
	}

	private def String compileInterceptors(Pipeline pipeline, GeneratorEnvironment env) {
		'''
			«pipeline.compileInterceptor(env)»
			«IF pipeline.next !== null»
				«pipeline.next.compileInterceptors(env)»
			«ENDIF»
		'''
	}

	private def dispatch String compileInterceptor(Filter filter, GeneratorEnvironment env) {
		'''
			class «filter.interceptorName»(«env.useImport("pipeline", "Interceptor")»):
				def handle(self, «filter.source.name.asInstance»):
					print("Filter")
					_should_continue = «filter.expression.compile»
					if _should_continue:
						self.next.handle(«filter.source.name.asInstance»)
			
		'''
	}

	private def dispatch String compileInterceptor(Map map, GeneratorEnvironment env) {
		'''
			class «map.interceptorName»(«env.useImport("pipeline", "Interceptor")»):
				def handle(self, «map.source.name.asInstance»):
					print("Map")
					_newValue = «map.expression.compile»
					self.next.handle(_newValue)
			
		'''
	}

	private def dispatch String compileInterceptor(Window window, GeneratorEnvironment env) {
		'''
			class «window.interceptorName»(«env.useImport("pipeline", "Interceptor")»):
				def __init__(self, next: Interceptor):
					super().__init__(next)
					self._buffer = []
				
				def handle(self, «window.source.name.asInstance»):
					print("Window")
					self._buffer.append(«window.source.name.asInstance»)
					if len(self._buffer) == «window.width»:
						_result = None # TODO: Unsupported
						self._buffer = []
						self.next.handle(_result)
			
		'''
	}

	private def Variables getSource(Pipeline pipeline) {
		val channelContainer = pipeline.getContainerOfType(ChannelOut)
		if (channelContainer === null) {
			return pipeline.getContainerOfType(TransformationOut).source
		}
		return channelContainer.source
	}
	
	private dispatch def String compileOut(ScreenOut out, GeneratorEnvironment env) {
		'''# TODO: Write to OLED'''
	}
}