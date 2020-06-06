package org.iot.codegenerator.util

import java.util.Collection
import java.util.HashMap
import java.util.HashSet
import org.iot.codegenerator.codeGenerator.AbstractBoard
import org.iot.codegenerator.codeGenerator.Board
import org.iot.codegenerator.codeGenerator.Channel
import org.iot.codegenerator.codeGenerator.Sensor
import org.iot.codegenerator.codeGenerator.SensorData
import org.iot.codegenerator.codeGenerator.ScreenOut

class InheritanceUil {
	
	static def inheritedSensors(Board board){
		val visited = new HashSet<Board>
		val nameSensor = new HashMap<String, Sensor> // Change list of objects to sensor
		dfs(board, visited, nameSensor)
	}
	
	static def Collection<Sensor> dfs(Board board, HashSet<Board> visited, HashMap<String, Sensor> nameSensor){ // change list of objects to sensor
		visited.add(board)
		//TODO does it have to be a map? (can it be a set?)
		board.sensors.forEach[sensor | if (!(nameSensor.keySet.contains(sensor.sensortype))) nameSensor.put(sensor.sensortype, sensor)] // change list of object to snesor
		for(AbstractBoard abstractBoard: board.superTypes){
			if (!(visited.contains(abstractBoard))){
				dfs(abstractBoard, visited, nameSensor)
			}
			}
			return nameSensor.values
	}
	
	static def inheritedChannels(Board board){
		val visited = new HashSet<Board>
		val nameChannel = new HashMap<String, Channel> 
		dfsChannels(board, visited, nameChannel)
	}
	
		
	static def private Collection<Channel> dfsChannels(Board board, HashSet<Board> visited, HashMap<String, Channel> nameChannel){
		visited.add(board)
		board.channels.forEach[channel | nameChannel.put(channel.name, channel)]
		for(AbstractBoard abstractBoard: board.superTypes){
			if (!(visited.contains(abstractBoard))){
				dfsChannels(abstractBoard, visited, nameChannel)
			}
		}
		return nameChannel.values
	}
	
	static def inheritedInChannels(Board board){
		val visited = new HashSet<Board>
		val nameInChannel = new HashMap<String, Channel>
		dfsInChannels(board, visited, nameInChannel)
		
	}
	
	static def private Collection<Channel> dfsInChannels(Board board, HashSet<Board> visited, HashMap<String, Channel> nameInChannel){
		visited.add(board)
		board.inputs.forEach[channel | nameInChannel.put(channel.name, channel)]
		for(AbstractBoard abstractBoard: board.superTypes){
			if (!(visited.contains(abstractBoard))){
				dfsInChannels(abstractBoard, visited, nameInChannel)
			}
		}
		return nameInChannel.values
	}
	
	static def usesOled(Board board) {
		for (sensor : board.inheritedSensors){
			for (data : sensor.datas){
				if (data instanceof SensorData){
					for (output: data.outputs){
						if (output instanceof ScreenOut){
							return true
						}
					}
				}
			}
		}
		return false
	}
}
