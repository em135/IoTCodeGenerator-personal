package org.iot.codegenerator.generator.python.board

import org.iot.codegenerator.codeGenerator.Channel
import org.iot.codegenerator.codeGenerator.ChannelOut
import org.iot.codegenerator.codeGenerator.Pipeline
import org.iot.codegenerator.codeGenerator.ScreenOut
import org.iot.codegenerator.codeGenerator.Sensor
import org.iot.codegenerator.codeGenerator.SensorData
import org.iot.codegenerator.codeGenerator.SensorDataOut
import org.iot.codegenerator.generator.python.BoardEnvironment
import org.iot.codegenerator.generator.python.GeneratorEnvironment

import static extension org.eclipse.xtext.EcoreUtil2.*
import static extension org.iot.codegenerator.generator.python.ImportGenerator.*
import static extension org.iot.codegenerator.util.GeneratorUtil.*

class CompositionRootGenerator {
	
	def String compile(BoardEnvironment boardEnv) {
		val genEnv = new GeneratorEnvironment()
		val classDef = boardEnv.compileClass(genEnv)

		'''
			«genEnv.compileImports»
			
			«classDef»
		'''
	}

	private def String compileClass(BoardEnvironment boardEnv, GeneratorEnvironment genEnv) {
		val sensorProviders = boardEnv.compileSensorProviders(genEnv)
		val pipelineProviders = boardEnv.compilePipelineProviders(genEnv)
		val boardProvider = boardEnv.compileBoardProvider(genEnv)

		'''
			class CompositionRoot:
				
				«boardEnv.compileConstructor(genEnv)»
				«boardProvider»
				«sensorProviders»
				«pipelineProviders»
				«boardEnv.compileChannelProviders(genEnv)»
				«compileMakeChannel(genEnv)»
				«boardEnv.computeSensorProviders(genEnv)»


		'''
	}


	private def String compileConstructor(BoardEnvironment boardEnv, GeneratorEnvironment genEnv) {
		genEnv.useImport("ujson")

		'''
			def __init__(self):
				«FOR channel : boardEnv.inheritedChannels»
					self.«channel.name.asInstance» = None
					«boardEnv.compileOledProvider(genEnv)»
				«ENDFOR»
				
				with open("config.json", "r") as _conf_file:
					self.configuration = ujson.loads("".join(_conf_file.readlines()))
			
		'''
	}
	
	private def compileOledProvider(BoardEnvironment boardEnv, GeneratorEnvironment genEnv){
		if (boardEnv.usesOled){
			genEnv.useImport("oled_provider", "OledWrapper")
			'''self._oled = OledWrapper()'''
		}
	}

	private def String compileBoardProvider(BoardEnvironment boardEnv, GeneratorEnvironment genEnv) {
		'''
			def «boardEnv.providerName»(self):
				«boardEnv.name.asInstance» = «genEnv.useImport(boardEnv.name.asModule, boardEnv.name.asClass)»()
				«FOR sensor : boardEnv.inheritedSensors»
					«addSensor(boardEnv, sensor)»
				«ENDFOR»
				«FOR channel : boardEnv.inheritedInputs»
					«boardEnv.name.asInstance».add_input_channel(self.«genEnv.useChannel(channel).providerName»())
				«ENDFOR»
				«FOR channel : boardEnv.inheritedChannels»
					«boardEnv.name.asInstance».add_output_channel(self.«channel.providerName»())
				«ENDFOR»
				return «boardEnv.name.asInstance»
				
		'''
	}
	
	private def addSensor(BoardEnvironment boardEnv, Sensor sensor){
		'''«boardEnv.name.asInstance».add_sensor("«sensor.sensorType.asModule»", self.«sensor.providerName»())'''
	}

	private def String compileSensorProviders(BoardEnvironment boardEnv, GeneratorEnvironment genEnv) {
		'''
			«FOR sensor : boardEnv.inheritedSensors» 
				def «sensor.providerName»(self):
					«sensor.sensorType.asInstance» = «genEnv.useImport(sensor.sensorType.asModule)».«sensor.sensorType.asClass»(self.provide_driver_«sensor.sensorType»())
					«FOR data : sensor.sensorDatas»
						«FOR out : data.outputs»
							«sensor.sensorType.asInstance».add_pipeline(«providerPipelineName(data, out)»())
						«ENDFOR»
					«ENDFOR»
					return «sensor.sensorType.asInstance»
				
			«ENDFOR»
		'''
	}
	
	private def String computeSensorProviders(BoardEnvironment boardEnv, GeneratorEnvironment genEnv){
		'''
			«FOR sensor : boardEnv.inheritedSensors»
				«sensor.compileSensorProvider(genEnv)»
			«ENDFOR»
		'''
	}
	
	private def String compileSensorProvider(Sensor sensor, GeneratorEnvironment genEnv){
		determineSensorDriverLib(sensor.sensorType)
		genEnv.useImport("sensor_provider", sensor.sensorType+"_wrapper")
		'''
		
		def provide_driver_«sensor.sensorType»(self):
			return «sensor.sensorType»_wrapper()
		'''				
	}
	
	private def determineSensorDriverLib(String sensortype){
		if (sensortype == "thermometer" )
			BoardGenerator.compileAsLibfile("/libfiles/hts221.py")
			BoardGenerator.compileAsLibfile("/libfiles/usmbus.py")
		if(sensortype == "light")
			BoardGenerator.compileAsLibfile("/libfiles/bh1750.py")
		if(sensortype == "motion")
			BoardGenerator.compileAsLibfile("/libfiles/mpu6050.py")
	}

	private def String compilePipelineProviders(BoardEnvironment boardEnv, GeneratorEnvironment genEnv) {
		'''
			«FOR sensor : boardEnv.inheritedSensors»
				«FOR data : sensor.sensorDatas»
					«FOR out : data.outputs»
						«out.compilePipelineProvider(genEnv)»
						
					«ENDFOR»
				«ENDFOR»
			«ENDFOR»
		'''
	}

	private def dispatch String compilePipelineProvider(ChannelOut out, GeneratorEnvironment genEnv) {
		genEnv.useImport("pipeline", "Pipeline")
		val variables = out.eContainer.getContainerOfType(Sensor).variables.ids
	
		val tupleSink = '''
		type('Sink', (object,), {
			"handle": lambda data: «out.channel.name.asInstance».send((«FOR v: variables SEPARATOR ', '»data['«v.name»']«ENDFOR»)),
			"next": None
		})'''
		
		val sink = '''
		type('Sink', (object,), {
			"handle": lambda data: «out.channel.name.asInstance».send(data),
			"next": None
		})'''

		'''
			def «out.providerName»(self):
				«genEnv.useChannel(out.channel).name.asInstance» = self.«out.channel.providerName»()
				return Pipeline(
					«IF out.pipeline === null»«tupleSink»«ELSE»«out.pipeline.compilePipelineComposition(sink, genEnv)»«ENDIF»
				)
		'''
	}

	private def String compilePipelineComposition(Pipeline pipeline, String sink, GeneratorEnvironment genEnv) {
		val inner = pipeline.next === null ? sink : pipeline.next.compilePipelineComposition(sink, genEnv)
		val sensorName = pipeline.getContainerOfType(Sensor).sensorType
		val interceptorName = pipeline.interceptorName
		
		'''
		«genEnv.useImport(sensorName.asModule)».«interceptorName»(
			«inner»
		)
		'''
	}

	private def dispatch String compilePipelineProvider(ScreenOut out, GeneratorEnvironment genEnv) {
		genEnv.useImport("pipeline", "Pipeline")
				val variables = out.eContainer.getContainerOfType(Sensor).variables.ids
		
		val tupleSink = '''
		type('Sink', (object,), {
			"handle": lambda data: self._oled.send((«FOR v: variables SEPARATOR ', '»data['«v.name»']«ENDFOR»)),
			"next": None
		})'''
		
		val sink = '''
		type('Sink', (object,), {
			"handle": lambda data: self._oled.send(data),
			"next": None
		})'''

		'''
			def «out.providerName»(self):
				return Pipeline(
					«IF out.pipeline === null»«tupleSink»«ELSE»«out.pipeline.compilePipelineComposition(sink, genEnv)»«ENDIF»
				)
		'''
	}

	private def String compileChannelProviders(BoardEnvironment boardEnv, GeneratorEnvironment genEnv) {
		'''
			«FOR channel : boardEnv.inheritedChannels»
				def «channel.providerName»(self):
					if not self.«channel.name.asInstance»:
						self.«channel.name.asInstance» = self.make_channel("«channel.name»")
					return self.«channel.name.asInstance»
				
			«ENDFOR»
		'''
	}

	private def String compileMakeChannel(GeneratorEnvironment genEnv) {
		genEnv.useImport("communication", "Serial")
		genEnv.useImport("communication", "Wifi")

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
	private def String providerName(BoardEnvironment boardEnv) {
		'''provide_«boardEnv.name.asModule»'''
	}

	private def String providerName(Sensor sensor) {
		'''provide_sensor_«sensor.sensorType.asModule»'''
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
	
		'''provide_pipeline_«sensor.sensorType.asModule»_«data.name.asModule»_«index»'''
	}
	
	private def String providerPipelineName(SensorData data, SensorDataOut out) {
		val sensor = out.getContainerOfType(Sensor)
		val index = data.outputs.takeWhile [
			it != out
		].size + 1
	
		'''"«data.name.asModule»_«index»", self.provide_pipeline_«sensor.sensorType.asModule»_«data.name.asModule»_«index»'''
	}

}