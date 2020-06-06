/*
 * generated by Xtext 2.20.0
 */
package org.iot.codegenerator.scoping

import java.util.Collections
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.xtext.scoping.IScope
import org.eclipse.xtext.scoping.Scopes
import org.iot.codegenerator.codeGenerator.Board
import org.iot.codegenerator.codeGenerator.Cloud
import org.iot.codegenerator.codeGenerator.CodeGeneratorPackage
import org.iot.codegenerator.codeGenerator.Data
import org.iot.codegenerator.codeGenerator.Fog
import org.iot.codegenerator.codeGenerator.ModifyPipeline
import org.iot.codegenerator.codeGenerator.Pipeline
import org.iot.codegenerator.codeGenerator.Provider

import static extension org.eclipse.emf.ecore.util.EcoreUtil.*
import static extension org.eclipse.xtext.EcoreUtil2.*
import org.iot.codegenerator.codeGenerator.DeviceConf
import org.iot.codegenerator.codeGenerator.Channel
import java.util.HashSet
import java.util.HashMap
import java.util.Collection
import org.iot.codegenerator.codeGenerator.AbstractBoard
import org.iot.codegenerator.codeGenerator.ConcreteBoard
import org.eclipse.emf.ecore.EClassifier
import org.iot.codegenerator.codeGenerator.Sensor

/**
 * This class contains custom scoping description.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#scoping
 * on how and when to use it.
 */
class CodeGeneratorScopeProvider extends AbstractCodeGeneratorScopeProvider {

	override getScope(EObject context, EReference reference) {
		val codeGen = CodeGeneratorPackage.eINSTANCE
		switch (reference) {
			case codeGen.reference_Variable:
				context.variableScope
			case codeGen.transformationOut_Source,
			case codeGen.sensorDataOut_Source:
				context.variablesScope
			case codeGen.transformation_Provider:
				context.transInIdScope
			case codeGen.channelOut_Channel:
				context.channelsScope
			case codeGen.board_Inputs:
				context.inChannelsScope
			default:
				super.getScope(context, reference)
		}
	}
		
	def private IScope getVariableScope(EObject context) {
		val mapContainer = context.getContainerOfType(Pipeline)?.eContainer()?.getContainerOfType(ModifyPipeline)
		if (mapContainer !== null) {
			Scopes.scopeFor((Collections.singleton(mapContainer.output)))
		} else {
			val providerContainer = context.eContainer.getContainerOfType(Provider)
			Scopes.scopeFor(providerContainer.variables.ids)
		}
	}
	
	def private IScope getVariablesScope(EObject context) {
		Scopes.scopeFor(Collections.singleton(context.getContainerOfType(Provider).variables))
	}

	def private IScope getTransInIdScope(EObject context) {
		val visited = new HashSet<Board>
		val nameSensor = new HashMap<String, Sensor>
		var fog = context.getContainerOfType(Fog)
		var cloud = context.getContainerOfType(Cloud)
		var deviceConf = fog?.getContainerOfType(DeviceConf)
		val datas = new HashSet<Data>
		if (deviceConf === null){
			deviceConf = cloud?.getContainerOfType(DeviceConf)
			fog = deviceConf.fog.get(0) 
			if (fog !== null){
				fog.transformations.forEach[transformation | datas.addAll(transformation.datas)]
			}
		}
		val board = deviceConf?.board?.getObjectByType(CodeGeneratorPackage.eINSTANCE.concreteBoard)
		
		if (board !== null){
			val sensors = dfs(board as Board, visited, nameSensor)
			sensors.forEach[sensor | sensor.datas.forEach[data | datas.add(data)]]
			val scope = Scopes.scopeFor(datas)

			if(scope !== null){
				return scope
			}
		}
		
		return IScope.NULLSCOPE
	}

	def private IScope channelsScope(EObject context){
		val visited = new HashSet<Board>
		val nameChannel = new HashMap<String, Channel> 
		val board = context.eContainer.getContainerOfType(Board)
		val channels = dfsChannels(board, visited, nameChannel)
		if (!channels.empty){
			return Scopes.scopeFor(channels)
		}
		return IScope.NULLSCOPE
	}
	
	def private IScope inChannelsScope(EObject context){
		val visited = new HashSet<Board>
		val nameChannel = new HashMap<String, Channel> 
		if (context instanceof Board){
			val channels = dfsChannels(context, visited, nameChannel)
			if (!channels.empty){
				return Scopes.scopeFor(channels)
			}
		}
		return IScope.NULLSCOPE
	}
		
	def private Collection<Channel> dfsChannels(Board board, HashSet<Board> visited, HashMap<String, Channel> nameChannel){
		visited.add(board)
		board.channels.forEach[channel | nameChannel.put(channel.name, channel)]
		for(AbstractBoard abstractBoard: board.superTypes){
			if (!(visited.contains(abstractBoard))){
				dfsChannels(abstractBoard, visited, nameChannel)
			}
		}
		return nameChannel.values
	}
	
		
	def private Collection<Sensor> dfs(Board board, HashSet<Board> visited, HashMap<String, Sensor> nameSensor){
		visited.add(board)
		board.sensors.forEach[sensor |if (!(nameSensor.keySet.contains(sensor.sensortype))) nameSensor.put(sensor.sensortype, sensor)] 
		for(AbstractBoard abstractBoard: board.superTypes){
			if (!(visited.contains(abstractBoard))){
				dfs(abstractBoard, visited, nameSensor)
			}
		}
		return nameSensor.values
	}
	

}
