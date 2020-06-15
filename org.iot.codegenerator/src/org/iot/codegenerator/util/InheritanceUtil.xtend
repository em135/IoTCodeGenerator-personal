package org.iot.codegenerator.util

import java.util.Collection
import java.util.HashMap
import java.util.HashSet
import org.iot.codegenerator.codeGenerator.AbstractBoard
import org.iot.codegenerator.codeGenerator.Board
import org.iot.codegenerator.codeGenerator.Channel
import org.iot.codegenerator.codeGenerator.Data
import org.iot.codegenerator.codeGenerator.Sensor

class InheritanceUtil {
	
	static def inheritedSensors(Board board){
		val visited = new HashSet<Board>
		val nameSensor = new HashMap<String, Sensor>
		dfsSensors(board, visited, nameSensor)
	}
	
	static def Collection<Sensor> dfsSensors(Board board, HashSet<Board> visited, HashMap<String, Sensor> nameSensor){
		visited.add(board)
		
		for (sensor: board.sensors){
			if (!nameSensor.keySet.contains(sensor.sensorType)){
				nameSensor.put(sensor.sensorType, sensor)
			}
		}
				
		for(abstractBoard: board.superTypes){
			if (!visited.contains(abstractBoard)){
				dfsSensors(abstractBoard, visited, nameSensor)
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
	
	static def inheritedInputs(Board board){
		val visited = new HashSet<Board>
		val nameInput = new HashMap<String, Channel>
		dfsInputs(board, visited, nameInput)
		
	}
	
	static def private Collection<Channel> dfsInputs(Board board, HashSet<Board> visited, HashMap<String, Channel> nameInput){
		visited.add(board)
		board.inputs.forEach[channel | nameInput.put(channel.name, channel)]
		for(AbstractBoard abstractBoard: board.superTypes){
			if (!(visited.contains(abstractBoard))){
				dfsInputs(abstractBoard, visited, nameInput)
			}
		}
		return nameInput.values
	}
	
	static def inheritedData(Board board){
		dfsData(board, new HashSet<Board>, new HashMap<String, Data>)
	}
	
	static def private Collection<Data> dfsData(Board board, HashSet<Board> visited, HashMap<String, Data> nameData){
		visited.add(board)
		board.sensors.forEach[sensor | sensor.datas.forEach[data | nameData.put(data.name, data)]] 
		for(AbstractBoard abstractBoard: board.superTypes){
			if (!(visited.contains(abstractBoard))){
				dfsData(abstractBoard, visited, nameData)
			}
		}
		return newArrayList(nameData.values)
	}
	
	static def boolean hasSensor(Board current){
		if (current.sensors.size !== 0){
			return true
		}
		
		for(Board board : current.superTypes){
			if (board.hasSensor){
				return true
			}
		}
		return false
	}
	
	static def boolean hasCycle(Board current, HashSet<Board> visited){
		if (visited.contains (current)){
			return true
		}
		visited.add(current)
	
		for (Board board: current.superTypes){
			if (board.name === current.name || hasCycle(board, visited)){
				return true
			}
		}
		visited.remove(current)
		return false
	}
}
