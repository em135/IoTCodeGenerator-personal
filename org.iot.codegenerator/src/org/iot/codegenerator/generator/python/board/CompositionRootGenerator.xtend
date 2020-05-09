package org.iot.codegenerator.generator.python.board

import org.iot.codegenerator.codeGenerator.Board
import org.iot.codegenerator.codeGenerator.Channel
import org.iot.codegenerator.codeGenerator.ChannelOut
import org.iot.codegenerator.codeGenerator.Pipeline
import org.iot.codegenerator.codeGenerator.ScreenOut
import org.iot.codegenerator.codeGenerator.Sensor
import org.iot.codegenerator.codeGenerator.SensorData
import org.iot.codegenerator.codeGenerator.SensorDataOut
import org.iot.codegenerator.generator.python.GeneratorEnvironment

import static extension org.eclipse.xtext.EcoreUtil2.*
import static extension org.iot.codegenerator.generator.python.GeneratorUtil.*
import static extension org.iot.codegenerator.generator.python.ImportGenerator.*
import com.google.inject.Inject
import org.iot.codegenerator.codeGenerator.OnbSensor
import java.util.Arrays

class CompositionRootGenerator {
	
	@Inject extension org.iot.codegenerator.typing.TypeChecker
	var compile_wrapper = true
	
	def String compile(Board board) {
		val env = new GeneratorEnvironment()
		val classDef = board.compileClass(env)

		'''
			«env.compileImports»
			
			«classDef»
		'''
	}

	private def String compileClass(Board board, GeneratorEnvironment env) {
		val sensorProviders = board.compileSensorProviders(env)
		val pipelineProviders = board.compilePipelineProviders(env)
		val boardProvider = board.compileBoardProvider(env)
		env.useImport("sensor_provider", "default_wrapper")

		'''
			class CompositionRoot:
				
				«board.compileConstructor(env)»
				«boardProvider»
				«sensorProviders»
				«pipelineProviders»
				«board.compileChannelProviders(env)»
				«compileMakeChannel(env)»
				«board.computeSensorProviders(env)»
				
				def provide_driver_default(self):
					return default_wrapper()
		'''
	}

	private def String compileConstructor(Board board, GeneratorEnvironment env) {
		env.useImport("ujson")

		'''
			def __init__(self):
				«FOR channel : env.channels»
					self.«channel.name.asInstance» = None
				«ENDFOR»
				
				with open("conf-filled.json", "r") as _conf_file:
					self.configuration = ujson.loads("".join(_conf_file.readlines()))
			
		'''
	}

	private def String compileBoardProvider(Board board, GeneratorEnvironment env) {
		'''
			def «board.providerName»(self):
				«board.name.asInstance» = «env.useImport(board.name.asModule, board.name.asClass)»()
				«FOR sensor : board.sensors»
					«board.name.asInstance».add_sensor("«sensor.sensortype.asModule»", self.«sensor.providerName»())
				«ENDFOR»
				«IF board.input !== null»«board.name.asInstance».set_input_channel(self.«env.useChannel(board.input).providerName»())«ENDIF»
				«FOR channel : env.channels.filter[it != board.input]»
					«board.name.asInstance».add_output_channel(self.«channel.providerName»())
				«ENDFOR»
				return «board.name.asInstance»
		'''
	}

	private def String compileSensorProviders(Board board, GeneratorEnvironment env) {
		'''
			«FOR sensor : board.sensors» 
				def «sensor.providerName»(self):
					«sensor.sensortype.asInstance» = «env.useImport(sensor.sensortype.asModule)».«sensor.sensortype.asClass»«IF sensor instanceof OnbSensor»(self.provide_driver_«sensor.sensortype»())«ELSE»(self.provide_driver_default())«ENDIF»
					«FOR data : sensor.sensorDatas»
						«FOR out : data.outputs»
							«sensor.sensortype.asInstance».add_pipeline("«data.name.asModule»", self.«out.providerName»())
						«ENDFOR»
					«ENDFOR»
					return «sensor.sensortype.asInstance»
				
			«ENDFOR»
		'''
	}
	
	private def String computeSensorProviders(Board board, GeneratorEnvironment env){
		'''
			«FOR sensor : board.sensors»
				«IF sensor instanceof OnbSensor»«sensor.compileSensorProvider(env)»«ENDIF»
			«ENDFOR»
		'''
	}
	
	private def String compileSensorProvider(Sensor sensor, GeneratorEnvironment env){
		determineSensorDriverLib(sensor.sensortype)
		env.useImport("sensor_provider", sensor.sensortype+"_wrapper")
		'''
		
		def provide_driver_«sensor.sensortype»(self):
			return «sensor.sensortype»_wrapper()
		'''				
	}
	
	private def determineSensorDriverLib(String sensortype){
		if (sensortype == "thermometer")
			BoardGenerator.compileAsLibfile("/libfiles/hts221.py")
		if(sensortype == "lux")
			BoardGenerator.compileAsLibfile("/libfiles/bh1750.py")
		if(sensortype == "motion")
			BoardGenerator.compileAsLibfile("/libfiles/mpu6050.py")
	}

	// TODO: Driver provider
	private def String compilePipelineProviders(Board board, GeneratorEnvironment env) {
		'''
			«FOR sensor : board.sensors»
				«FOR data : sensor.sensorDatas»
					«FOR out : data.outputs»
						«out.compilePipelineProvider(env)»
						
					«ENDFOR»
				«ENDFOR»
			«ENDFOR»
		'''
	}

	private def dispatch String compilePipelineProvider(ChannelOut out, GeneratorEnvironment env) {
		env.useImport("pipeline", "Pipeline")
		env.useImport("struct")

		val sink = '''
		type('Sink', (object,), {
			"handle": lambda data: «out.channel.name.asInstance».send(«out.pipeline.compileDataConversion»),
			"next": None
		})'''

		'''
			def «out.providerName»(self):
				«env.useChannel(out.channel).name.asInstance» = self.«out.channel.providerName»()
				return Pipeline(
					«out.pipeline.compilePipelineComposition(sink, env)»
				)
		'''
	}
	
	private def String compileDataConversion(Pipeline pipeline) {
		switch pipeline.lastType {
			case INT: {
				'''struct.pack("i", data)'''
			}
			case DOUBLE: {
				'''struct.pack("f", data)'''
			}
			case BOOLEAN: {
				'''struct.pack("?", data)'''
			}
			case STRING: {
				'''data.encode("utf-8")'''
			}
			case INVALID: {
				throw new IllegalStateException("Encountered INVALID type in grammar during code generation")
			}
		}
	}

	private def String compilePipelineComposition(Pipeline pipeline, String sink, GeneratorEnvironment env) {
		val inner = pipeline.next === null ? sink : pipeline.next.compilePipelineComposition(sink, env)
		val sensorName = pipeline.getContainerOfType(Sensor).sensortype
		val interceptorName = pipeline.interceptorName
		
		'''
		«env.useImport(sensorName.asModule)».«interceptorName»(
			«inner»
		)
		'''
	}

	private def dispatch String compilePipelineProvider(ScreenOut out, GeneratorEnvironment env) {
		'''
			def «out.providerName»(self):
				# TODO: Unsupported
				return None
		'''
	}

	private def String compileChannelProviders(Board board, GeneratorEnvironment env) {
		'''
			«FOR channel : env.channels»
				def «channel.providerName»(self):
					if not self.«channel.name.asInstance»:
						self.«channel.name.asInstance» = self.make_channel("«channel.name»")
					return self.«channel.name.asInstance»
				
			«ENDFOR»
		'''
	}

	private def String compileMakeChannel(GeneratorEnvironment env) {
		env.useImport("communication", "Serial")
		env.useImport("communication", "Wifi")

		'''
			def make_channel(self, identifier: str):
				if self.configuration[identifier]["type"] == "serial":
					return Serial(self.configuration["serial"]["baud"],
								  self.configuration["serial"]["databits"],
								  self.configuration["serial"]["paritybits"],
								  self.configuration["serial"]["stopbit"])
				
				elif self.configuration[identifier]["type"] == "wifi":
					return Wifi(self.configuration[identifier]["lane"], 
								self.configuration["wifi"]["ssid"],
								self.configuration["wifi"]["password"])
		'''
	}

	/*
	 * Utility extension methods
	 */
	private def String providerName(Board board) {
		'''provide_«board.name.asModule»'''
	}

	private def String providerName(Sensor sensor) {
		'''provide_sensor_«sensor.sensortype.asModule»'''
	}

	private def String providerName(Channel channel) {
		'''provide_channel_«channel.name.asModule»'''
	}

	private def String providerName(SensorDataOut out) {
		val sensor = out.getContainerOfType(Sensor)
		val data = out.getContainerOfType(SensorData)
		val index = data.outputs.takeWhile [
			it != out
		].size + 1

		'''provide_pipeline_«sensor.sensortype.asModule»_«data.name.asModule»_«index»'''
	}
}