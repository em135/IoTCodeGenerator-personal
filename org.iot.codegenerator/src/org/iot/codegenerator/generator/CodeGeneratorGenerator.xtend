/*
 * generated by Xtext 2.20.0
 */
package org.iot.codegenerator.generator

import com.google.inject.Inject
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import org.iot.codegenerator.codeGenerator.Board
import org.iot.codegenerator.codeGenerator.Channel
import org.iot.codegenerator.generator.python.board.BoardGenerator
import org.iot.codegenerator.codeGenerator.AbstractBoard
import java.util.HashSet
import org.iot.codegenerator.codeGenerator.Sensor
import java.util.List
import java.util.Set
import java.util.HashMap

/**
 * Generates code from your model files on save.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#code-generation
 */
class CodeGeneratorGenerator extends AbstractGenerator {

	@Inject extension BoardGenerator


	def HashMap<String, List<Object>> dfs(Board board, HashSet<Board> visited, HashMap<String, List<Object>> nameSensor){ // change list of objects to sensor
		visited.add(board)
		board.sensors.forEach[sensor | if (!(nameSensor.keySet.contains(sensor.sensortype))) nameSensor.put(sensor.sensortype, newArrayList(board.name))] // change list of object to snesor
		for(AbstractBoard abstractBoard: board.superTypes){
			if (!(visited.contains(abstractBoard))){
				dfs(abstractBoard, visited, nameSensor)
			}
		}
		return nameSensor
	}
	
	override void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		val board = resource.allContents.filter(Board).next()
		if (!(board instanceof AbstractBoard)){
			fsa.generateFile("config.json", resource.allContents.toIterable.filter(Channel).compile)
			board.compile(fsa)
		}
		val visited = new HashSet<Board>
		val nameSensor = new HashMap<String, List<Object>> // Change list of objects to sensor
		val inheritedSensors = dfs(board, visited, nameSensor)
		System.out.println(inheritedSensors)
		
//		val sensors = new HashSet<Sensor>
//		if (!(board.superTypes.empty)){ 
//			for (AbstractBoard ab: board.superTypes){
//				
//			}
//		}
	
		//val fog = resource.allContents.filter(Fog).next()
		// TODO
		
		//val cloud = resource.allContents.filter(Cloud).next()
		// TODO
	}

	def String compile(Iterable<Channel> channels) {
		val channelFormat = '": {\n        "type": "",\n        "lane": ""\n    }'
		var compiled = '{\n    "wifi": {\n        "ssid": "",\n        "password": "",\n        "cloud": ""\n    },\n    "serial": {\n        "baud": "",\n        "databits": "",\n        "paritybits": "",\n        "stopbit": ""\n    },\n'
		for (channel : channels) {
			compiled += '    "' + channel.name + channelFormat + ',\n'
		}
		compiled.substring(0, compiled.length - 2) + '\n}\n'
	}
}
