package org.iot.codegenerator.generator.python.board

import com.google.inject.Inject
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.iot.codegenerator.codeGenerator.Board
import org.iot.codegenerator.codeGenerator.ScreenOut

import static extension org.iot.codegenerator.generator.python.GeneratorUtil.*

class BoardGenerator {

	@Inject CompositionRootGenerator compositionRootGenerator
	@Inject SensorProviderGenerator sensorProviderGenerator
	@Inject DeviceGenerator deviceGenerator
	@Inject SensorGenerator sensorGenerator 
	
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

		board.sensors.forEach [
			fsa.generateFile('''board/«sensortype».py''', sensorGenerator.compile(it))
		]

		"/libfiles/communication.py".compileAsLibfile()
		"/libfiles/pipeline.py".compileAsLibfile()
		"/libfiles/thread.py".compileAsLibfile()
		
		if (board.usesOled) {
			"/libfiles/ssd1306.py".compileAsLibfile()
			"/libfiles/LICENSE_ssd1306.txt".compileAsLibfile()
		}
	}

	def static compileAsLibfile(String path) {
		try (val stream = BoardGenerator.classLoader.getResourceAsStream(path)) {
			val fileName = BoardGenerator._fsa.getURI(path).deresolve(BoardGenerator._fsa.getURI("libfiles/"))
			BoardGenerator._fsa.generateFile('''board/«fileName.path»''', stream)
		}
	}
	
	def usesOled(Board board) {
		return !board.eContents.filter(ScreenOut).empty
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
				«IF board.input !== null»
					#     board.set_input_channel(...)
				«ENDIF»
				#     board.add_output_channel(...)
				pass
			
			CustomCompositionRoot().provide_«board.name.asModule»().run()
		'''
	}
}
