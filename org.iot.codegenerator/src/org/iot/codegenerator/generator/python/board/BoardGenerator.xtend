package org.iot.codegenerator.generator.python.board

import com.google.inject.Inject
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.iot.codegenerator.codeGenerator.Board
import org.iot.codegenerator.codeGenerator.ScreenOut

import static extension org.iot.codegenerator.generator.python.GeneratorUtil.*
import org.iot.codegenerator.codeGenerator.SensorData

class BoardGenerator {
	@Inject CompositionRootGenerator compositionRootGenerator
	@Inject SensorProviderGenerator sensorProviderGenerator
	@Inject DeviceGenerator deviceGenerator
	@Inject SensorGenerator sensorGenerator 
	@Inject ExternalSensorDriverGenerator externalSensorDriverGenerator
	
	static IFileSystemAccess2 _fsa
	
	def compile(Board board, IFileSystemAccess2 fsa) {
		BoardGenerator._fsa = fsa
		fsa.generateFile('''board/composition_root.py''', compositionRootGenerator.compile(board))
		fsa.generateFile('''board/sensor_provider.py''', sensorProviderGenerator.compile(board))
		fsa.generateFile('''board/«board.name.asModule».py''', deviceGenerator.compile(board))
		if (fsa.isFile("board/main.py")) {
			val mainContents = fsa.readTextFile("board/main.py")
			fsa.generateFile('''board/main.py''', mainContents)
		} else {
			fsa.generateFile('''board/main.py''', compileMain(board))
		}
		
		for (sensor : board.inheritedSensors){
			val sensorType = sensor.sensortype
			val sensorFileName = '''board/«sensorType»'''
			switch (sensor.sensortype) {
				case "thermometer", case "motion", case "light": {
					fsa.generateFile('''«sensorFileName».py''', sensorGenerator.compile(sensor))
				}
				default: {
					val driverFile = '''«sensorFileName»_driver.py'''
					fsa.generateFile('''«sensorFileName».py''', sensorGenerator.compile(sensor))
					if (fsa.isFile(driverFile)) {
						val driverContents = fsa.readTextFile(driverFile)
						fsa.generateFile(driverFile, driverContents)
					} else {					
						fsa.generateFile(driverFile, externalSensorDriverGenerator.compile(sensor))
					}
				}
			}
		}

		"/libfiles/communication.py".compileAsLibfile()
		"/libfiles/pipeline.py".compileAsLibfile()
		"/libfiles/by_window_utils.py".compileAsLibfile()
		"/libfiles/thread.py".compileAsLibfile()
		
		if (board.usesOled) {
			"/libfiles/ssd1306.py".compileAsLibfile()
//			"/libfiles/LICENSE_ssd1306.txt".compileAsLibfile()
			"/libfiles/oled_provider.py".compileAsLibfile()
		}
	}

	def static compileAsLibfile(String path) {
		try (val stream = BoardGenerator.classLoader.getResourceAsStream(path)) {
			val fileName = BoardGenerator._fsa.getURI(path).deresolve(BoardGenerator._fsa.getURI("libfiles/"))
			BoardGenerator._fsa.generateFile('''board/«fileName.path»''', stream)
		}
	}

	def String compileMain(Board board) {
		'''
			from composition_root import CompositionRoot
			
			class CustomCompositionRoot(CompositionRoot):
				# This file will not be overwritten by the IoT code generator.
				# 
				# To adapt the generated code, override the methods from CompositionRoot
				# inside this class, for instance:
				# 
				# def provide_«board.name.asModule»(self):
				#     board = super().provide_«board.name.asModule»()
				#     board.add_sensor(...)
				«IF !board.inheritedInChannels.empty»
					#     board.add_input_channel(...)
				«ENDIF»
				#     board.add_output_channel(...)
				pass
			
			CustomCompositionRoot().provide_«board.name.asModule»().run()
		'''
	}
}
