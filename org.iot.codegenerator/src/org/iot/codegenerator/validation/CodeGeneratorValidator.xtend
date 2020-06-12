/*
 * generated by Xtext 2.20.0
 */
package org.iot.codegenerator.validation

import com.google.common.collect.Sets
import com.google.inject.Inject
import java.util.ArrayList
import java.util.Collection
import java.util.HashMap
import java.util.HashSet
import java.util.List
import java.util.Set
import java.util.stream.Collectors
import java.util.stream.Stream
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EStructuralFeature
import org.eclipse.xtext.naming.IQualifiedNameProvider
import org.eclipse.xtext.resource.IContainer
import org.eclipse.xtext.resource.IResourceDescriptions
import org.eclipse.xtext.validation.Check
import org.eclipse.xtext.validation.CheckType
import org.iot.codegenerator.codeGenerator.AbstractBoard
import org.iot.codegenerator.codeGenerator.And
import org.iot.codegenerator.codeGenerator.Board
import org.iot.codegenerator.codeGenerator.Channel
import org.iot.codegenerator.codeGenerator.ChannelOut
import org.iot.codegenerator.codeGenerator.CodeGeneratorPackage
import org.iot.codegenerator.codeGenerator.ConcreteBoard
import org.iot.codegenerator.codeGenerator.Conditional
import org.iot.codegenerator.codeGenerator.Data
import org.iot.codegenerator.codeGenerator.DeviceConf
import org.iot.codegenerator.codeGenerator.Div
import org.iot.codegenerator.codeGenerator.Equal
import org.iot.codegenerator.codeGenerator.Exponent
import org.iot.codegenerator.codeGenerator.ExtSensor
import org.iot.codegenerator.codeGenerator.Filter
import org.iot.codegenerator.codeGenerator.GreaterThan
import org.iot.codegenerator.codeGenerator.GreaterThanEqual
import org.iot.codegenerator.codeGenerator.Language
import org.iot.codegenerator.codeGenerator.LessThan
import org.iot.codegenerator.codeGenerator.LessThanEqual
import org.iot.codegenerator.codeGenerator.Map
import org.iot.codegenerator.codeGenerator.Minus
import org.iot.codegenerator.codeGenerator.Mul
import org.iot.codegenerator.codeGenerator.Negation
import org.iot.codegenerator.codeGenerator.Not
import org.iot.codegenerator.codeGenerator.OnbSensor
import org.iot.codegenerator.codeGenerator.Or
import org.iot.codegenerator.codeGenerator.Pipeline
import org.iot.codegenerator.codeGenerator.Plus
import org.iot.codegenerator.codeGenerator.Provider
import org.iot.codegenerator.codeGenerator.Sensor
import org.iot.codegenerator.codeGenerator.SensorData
import org.iot.codegenerator.codeGenerator.SensorDataOut
import org.iot.codegenerator.codeGenerator.SignalSampler
import org.iot.codegenerator.codeGenerator.Transformation
import org.iot.codegenerator.codeGenerator.TransformationData
import org.iot.codegenerator.codeGenerator.TransformationOut
import org.iot.codegenerator.codeGenerator.TuplePipeline
import org.iot.codegenerator.codeGenerator.Unequal
import org.iot.codegenerator.codeGenerator.Variable
import org.iot.codegenerator.codeGenerator.Variables
import org.iot.codegenerator.codeGenerator.Window
import org.iot.codegenerator.codeGenerator.WindowPipeline
import org.iot.codegenerator.typing.TypeChecker

import static org.iot.codegenerator.validation.IssueCodesProvider.*
import static extension org.iot.codegenerator.util.InheritanceUil.*
import static extension org.eclipse.xtext.EcoreUtil2.*

/**
 * This class contains custom validation rules. 
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#validation
 */
class CodeGeneratorValidator extends AbstractCodeGeneratorValidator {

	@Inject extension TypeChecker
	@Inject IQualifiedNameProvider qualifiedNameProvider
	@Inject IContainer.Manager containerManager
	@Inject IResourceDescriptions resourceDescriptions

	@Check
	def checkConcreteBoardCloud (ConcreteBoard concreteBoard){
		val deviceConf = concreteBoard.eContainer?.getContainerOfType(DeviceConf)
		
		if (deviceConf !== null){
			if (deviceConf.cloud.size >1){
				error('''There must be at most 1 cloud definition''', CodeGeneratorPackage.eINSTANCE.board_Name)
			} else if (deviceConf.cloud.size() < 1) {
				warning('''There should be a cloud definition''', CodeGeneratorPackage.eINSTANCE.board_Name)
			}
			if (deviceConf.fog.size > 1){
				error('''There must be at most 1 fog definition''', CodeGeneratorPackage.eINSTANCE.board_Name)
			}
		}
	}
	

	
	@Check
	def checkForDuplicateChannels (Channel channel){
		val board = channel.getContainerOfType(Board)
		for (Channel c: board.channels.filter[it !== channel]){
			if (channel.name.equals(c.name)){
				error('''duplicate channel «channel.name»''', CodeGeneratorPackage.Literals.CHANNEL__NAME)
			}
		}
	}
	
	@Check
	def validateConcreteBoard(DeviceConf configuration){
		val concreteBoards = configuration.board.filter(board | board instanceof ConcreteBoard)
		if (concreteBoards.size>1){
			error('''There must max be 1 concrete board''', concreteBoards.get(0), CodeGeneratorPackage.eINSTANCE.board_Name)
		}
	}
		
	@Check
	def validateBoard(Board board) {
		val b = new ESP32()
		info('''«board.name» supports the following sensors: «String.join(", ", b.sensors)»''', CodeGeneratorPackage.eINSTANCE.board_Name)
	}
	 
	@Check
	def validateOnboardSensor(Sensor sensor) {
		if (sensor instanceof OnbSensor){
			val board = new ESP32()
			sensor.variables.ids
			val parameterCount = board.getParameterCount(sensor.sensortype)

			if (parameterCount == -1) {
				error('''Board does not support sensor: «sensor.sensortype»''', CodeGeneratorPackage.eINSTANCE.sensor_Sensortype)
			} else if (parameterCount < sensor.variables.ids.length) {
				error('''Maximum number of output variables for sensor type «sensor.sensortype» is «parameterCount»''', CodeGeneratorPackage.eINSTANCE.sensor_Sensortype)
			} 
		}
	}
	
	@Check
	def validatePinsMatchesVars(Variables variables) {
		val parent = variables.eContainer
		val board = new ESP32()
		switch parent {
			ExtSensor:
				if (parent.pins.size() < variables.ids.size()) {
					error('''Expected «parent.pins.size()» pin inputs, got «variables.ids.size()»''', CodeGeneratorPackage.eINSTANCE.variables_Ids)
				} else if (parent.pins.size() > variables.ids.size()) {
					warning('''Number of pin inputs shuld match number of variables after "as"''', CodeGeneratorPackage.eINSTANCE.variables_Ids)					
				}
			OnbSensor:
				if(board.sensors.contains(parent.sensortype)){
					val legalVariables = board.getSensorVariables(parent.sensortype)
					for (Variable variable : variables.ids){
						if (!(legalVariables.contains(variable.name))){
							error('''Unsupported variable «variable.name». The «parent.sensortype» sensor supports the variables: «String.join(", ", legalVariables)»''',
								variable, CodeGeneratorPackage.eINSTANCE.variable_Name)
						}
					}
				}
		}
	}
	
	@Check 
	def validateLanguage(Language lang) {
		if (!lang.name.equals("python")) {
			error('''no support for language «lang.name», only "python"''',
				CodeGeneratorPackage.eINSTANCE.language_Name, UNSUPPORTED_LANGUAGE)
		} else {
			info('''generator supports "python"''', CodeGeneratorPackage.eINSTANCE.language_Name)
		}
	} 


	def checkNoDuplicateDataName(List<Data> datas) {
		val dataNameValues = new HashMap<String, Set<Data>>
		for (data : datas) {
			val name = data.name
			if (dataNameValues.containsKey(name)) {
				dataNameValues.get(name).add(data)
			} else {
				dataNameValues.put(name, Sets.newHashSet(data))
			}
		}

		for (Set<Data> dataSet : dataNameValues.values) {
			if (dataSet.size > 1) {
				for (data : dataSet) {
					error('''duplicate «data.name»''', data, CodeGeneratorPackage.eINSTANCE.data_Name)
				}
			}
		}
	}
	
	def checkNoDuplicateSensorName(List<Sensor> sensors) {
		val sensorNameValues = new HashMap<String, Set<Sensor>>
		for (sensor : sensors) {
			val name = sensor.sensortype
			if (sensorNameValues.containsKey(name)) {
				sensorNameValues.get(name).add(sensor)
			} else {
				sensorNameValues.put(name, Sets.newHashSet(sensor))
			}
		}

		for (Set<Sensor> sensorSet : sensorNameValues.values) {
			if (sensorSet.size > 1) {
				for (sensor : sensorSet) {
					error('''duplicate sensor «sensor.sensortype»''', sensor, CodeGeneratorPackage.eINSTANCE.sensor_Sensortype)
				}
			}
		}
	}
	
	@Check
	def validateUsageOfdataDeclaration(SensorData data) {
		val deviceConf = data.eContainer.getContainerOfType(DeviceConf)
		val fog = deviceConf.fog.last
		val cloud = deviceConf.cloud.last
		val list = Stream.concat(fog.transformations.stream(), cloud.transformations.stream()).collect(Collectors.toList());
		if (!list.exists[it.provider == data]) {
			warning('''Unused variable''', data, CodeGeneratorPackage.Literals.DATA__NAME, UNUSED_VARIABLE)
		} 
	}
	
	@Check
	def chackUnusedChannels(){
		
	}

	@Check // TODO
	def validateData(Data data) {
		var datas = new ArrayList<Data>
		var sensors = new ArrayList<Sensor>
		for (EObject eObject : data.eResource.getContents()) {
			if (eObject instanceof DeviceConf) {
				val deviceConf = eObject as DeviceConf
				val board = deviceConf.board
				val cloud = deviceConf.cloud
				val fog = deviceConf.fog

				if (board.size > 0) {
					for (Sensor sensor : board.get(0).sensors) {
						datas.addAll(sensor.datas)
						sensors.add(sensor)
					}
				}

				if (cloud.size > 0) {
					for (Transformation transformation : cloud.get(0).transformations) {
						datas.addAll(transformation.datas)
					}
				}

				if (fog.size > 0) {
					for (Transformation transformation : fog.get(0).transformations) {
						datas.addAll(transformation.datas)
					}
				}

//				checkNoDuplicateDataName(datas)
				checkNoDuplicateSensorName(sensors)
				return
			}
		}
	}	
		
	def private Collection<Data> dfs(Board board, HashSet<Board> visited, HashMap<String, Data> nameData){
		visited.add(board)
		board.sensors.forEach[sensor | sensor.datas.forEach[data | nameData.put(data.name, data)]] 
		for(AbstractBoard abstractBoard: board.superTypes){
			if (!(visited.contains(abstractBoard))){
				dfs(abstractBoard, visited, nameData)
			}
		}
		return nameData.values
	}
	
	
	@Check
	def checkUniqueDataNames(Data data){
		val sensor = data.getContainerOfType(Sensor)
		val board = sensor.getContainerOfType(Board)
		
		val datas = dfs(board, new HashSet<Board>, new HashMap<String, Data>)
		
		for(Data d: datas.filter[it !== data]){
			if (data.name.equals(d.name)){
				error('''duplicate «data.name»''', CodeGeneratorPackage.Literals.DATA__NAME)
			}
		}
		
		for (Sensor s : board.sensors){
			for (d : s.datas.filter[it !== data]){
				if (d.name.equals(data.name)){
				error('''duplicate «data.name»''', CodeGeneratorPackage.Literals.DATA__NAME)
			}
			}
		}
	}
	
	
	
	
	
	
	def checkNoDuplicateVariableNamesInStatement(List<Variable> variables) {
		val variableNameValues = new HashMap<String, Set<Variable>>

		for (variable : variables) {
			val name = variable.name
			if (variableNameValues.containsKey(name)) {
				variableNameValues.get(name).add(variable)
			} else {
				variableNameValues.put(name, Sets.newHashSet(variable))
			}
		}

		for (Set<Variable> variableSet : variableNameValues.values) {
			if (variableSet.size > 1) {
				for (variable : variableSet) {
					error('''duplicate «variable.name»''', variable, CodeGeneratorPackage.eINSTANCE.variable_Name)
				}
			}
		}
	}
	
	@Check
	def validateVariable(Variables variables){	
		val eContainer = variables.eContainer
		if (eContainer instanceof Provider){
			val provider = eContainer as Provider
			checkNoDuplicateVariableNamesInStatement(provider.variables.ids)
		}
	}

	def checkSameTypeOfTransformationOutPipelines(List<TransformationOut> transformationOuts){
		if (transformationOuts.size >1){
			val firstPipelineType = transformationOuts.get(0).pipeline.lastType
			for(TransformationOut transformationOut: transformationOuts){
				val currentPipelineType = transformationOut.pipeline.lastType
				if (firstPipelineType !== currentPipelineType){
					error('''expected «firstPipelineType» got «currentPipelineType»''',
						transformationOut, CodeGeneratorPackage.eINSTANCE.transformationOut_Pipeline
					)
				}
			}
		}
	} 
	
	//TODO SENSORDATAOUT
	def checkSameTypeOfChannelOutPipelines(List<ChannelOut> channelOuts){
		if (channelOuts.size !==0){
			val firstPipelineType = channelOuts.get(0).pipeline.lastType
			for(ChannelOut channelOut: channelOuts){
				val currentPipelineType = channelOut.pipeline.lastType
				if (! firstPipelineType.numberType || ! currentPipelineType.numberType) {
					if (firstPipelineType !== currentPipelineType){
						error('''expected «firstPipelineType» got «currentPipelineType»''',
							channelOut, CodeGeneratorPackage.eINSTANCE.sensorDataOut_Pipeline
						)
					}
				}
			}
		}
	}
	
	@Check
	def checkWindowWidth(Window window){
		if(window.width < 2) {
			error('''window width must be 2 or greater''', window, CodeGeneratorPackage.eINSTANCE.window_Width)
		}
	}
	
	def checkFirstPipeline(Pipeline pipeline) {
		if (pipeline instanceof WindowPipeline) {
			error('''cannot use byWindow on tuple type''', pipeline, CodeGeneratorPackage.eINSTANCE.pipeline_Next)
			return
		}
		var pipe = pipeline
		if (pipeline instanceof TuplePipeline) {
			while(pipe !== null) {
				if (!(pipe instanceof TuplePipeline) && !(pipe instanceof WindowPipeline)){
					return
				} else if (pipe instanceof WindowPipeline) {
					error('''cannot use byWindow on tuple type''', pipe, CodeGeneratorPackage.eINSTANCE.pipeline_Next)
					return
				}
				pipe = pipe.next
			}
		}
	}
	
	
	@Check
	def validateWindowNotUsedOnString(Map map){
		if (map.expression.type == TypeChecker.Type.STRING) {
			var next = map.next
			while (next !== null && next instanceof TuplePipeline){
				next = next.next
			}
			if (next instanceof WindowPipeline){
				error('''cannot use byWindow on string type''', next, CodeGeneratorPackage.eINSTANCE.pipeline_Next)
			}
		}
	}
	
	@Check
	def validatePipelineOutputs(Data data){
		if (data instanceof TransformationData) {
			var transformationOuts = new ArrayList<TransformationOut>
			val transformationDataOutputs = (data as TransformationData).outputs
			
			for (TransformationOut transformationOut : transformationDataOutputs) {
				transformationOuts.add(transformationOut)
				checkFirstPipeline(transformationOut.pipeline)
			}
			checkSameTypeOfTransformationOutPipelines(transformationOuts)	
		} else if (data instanceof SensorData) {
			var channelOuts = new ArrayList<ChannelOut>
			val sensorDataOutputs = (data as SensorData).outputs
			
			for(SensorDataOut sensorDataOut : sensorDataOutputs) {
				if (sensorDataOut instanceof ChannelOut) {
					val channelOut = sensorDataOut as ChannelOut
					channelOuts.add(channelOut)
					checkFirstPipeline(channelOut.pipeline)
				}
			}
			checkSameTypeOfChannelOutPipelines(channelOuts)
		}	
	}
	
	def validateTypes(TypeChecker.Type actual, TypeChecker.Type expected, EStructuralFeature error) {
		if (expected != actual) {
			error('''expected «expected» got «actual»''', error)
		}
	}

	def validateNumbers(TypeChecker.Type type, EStructuralFeature error) {
		if (!type.isNumberType) {
			error('''expected number got «type»''', error)
		}
	}

	@Check
	def validateFilterExpression(Filter filter) {
		filter.expression.type.validateTypes(TypeChecker.Type.BOOLEAN,
			CodeGeneratorPackage.Literals.FILTER__EXPRESSION)
	}

	@Check
	def checkExpression(Conditional conditional) {
		conditional.condition.type.validateTypes(TypeChecker.Type.BOOLEAN,
			CodeGeneratorPackage.Literals.CONDITIONAL__CONDITION)
			if (! conditional.correct.type.numberType || ! conditional.incorrect.type.numberType) {
				conditional.incorrect.type.validateTypes(conditional.correct.type,
				CodeGeneratorPackage.Literals.CONDITIONAL__INCORRECT)
			}
	}

	@Check
	def checkExpression(Or or) {
		or.left.type.validateTypes(TypeChecker.Type.BOOLEAN, CodeGeneratorPackage.Literals.OR__LEFT)
		or.right.type.validateTypes(TypeChecker.Type.BOOLEAN, CodeGeneratorPackage.Literals.OR__RIGHT)
	}

	@Check
	def checkExpression(And and) {
		and.left.type.validateTypes(TypeChecker.Type.BOOLEAN, CodeGeneratorPackage.Literals.AND__LEFT)
		and.right.type.validateTypes(TypeChecker.Type.BOOLEAN, CodeGeneratorPackage.Literals.AND__RIGHT)
	}

	@Check
	def checkExpression(Equal equal) {
		if (!equal.left.type.isNumberType || !equal.right.type.isNumberType) {
			equal.right.type.validateTypes(equal.left.type, CodeGeneratorPackage.Literals.EQUAL__RIGHT)
		}
	}

	@Check
	def checkExpression(Unequal unequal) {
		if (!unequal.left.type.isNumberType || !unequal.right.type.isNumberType) {
			unequal.right.type.validateTypes(unequal.left.type, CodeGeneratorPackage.Literals.UNEQUAL__RIGHT)
		}
	}

	@Check
	def checkExpression(LessThan lessThan) {
		lessThan.left.type.validateNumbers(CodeGeneratorPackage.Literals.LESS_THAN__LEFT)
		lessThan.right.type.validateNumbers(CodeGeneratorPackage.Literals.LESS_THAN__RIGHT)
	}

	@Check
	def checkExpression(LessThanEqual lessThanEqual) {
		lessThanEqual.left.type.validateNumbers(CodeGeneratorPackage.Literals.LESS_THAN_EQUAL__LEFT)
		lessThanEqual.right.type.validateNumbers(CodeGeneratorPackage.Literals.LESS_THAN_EQUAL__RIGHT)
	}

	@Check
	def checkExpression(GreaterThan greaterThan) {
		greaterThan.left.type.validateNumbers(CodeGeneratorPackage.Literals.GREATER_THAN__LEFT)
		greaterThan.right.type.validateNumbers(CodeGeneratorPackage.Literals.GREATER_THAN__RIGHT)
	}

	@Check
	def checkExpression(GreaterThanEqual greaterThanEqual) {
		greaterThanEqual.left.type.validateNumbers(CodeGeneratorPackage.Literals.GREATER_THAN_EQUAL__LEFT)
		greaterThanEqual.right.type.validateNumbers(CodeGeneratorPackage.Literals.GREATER_THAN_EQUAL__RIGHT)
	}

	@Check
	def checkExpression(Plus plus) {
		if (plus.left.type != TypeChecker.Type.STRING && plus.right.type != TypeChecker.Type.STRING) {
			plus.left.type.validateNumbers(CodeGeneratorPackage.Literals.PLUS__LEFT)
			plus.right.type.validateNumbers(CodeGeneratorPackage.Literals.PLUS__RIGHT)
		}
	}

	@Check
	def checkExpression(Minus minus) {
		minus.left.type.validateNumbers(CodeGeneratorPackage.Literals.MINUS__LEFT)
		minus.right.type.validateNumbers(CodeGeneratorPackage.Literals.MINUS__RIGHT)
	}

	@Check
	def checkExpression(Mul mul) {
		mul.left.type.validateNumbers(CodeGeneratorPackage.Literals.MUL__LEFT)
		mul.right.type.validateNumbers(CodeGeneratorPackage.Literals.MUL__RIGHT)
	}

	@Check
	def checkExpression(Div div) {
		div.left.type.validateNumbers(CodeGeneratorPackage.Literals.DIV__LEFT)
		div.right.type.validateNumbers(CodeGeneratorPackage.Literals.DIV__RIGHT)
	}

	@Check
	def checkExpression(Negation negation) {
		negation.value.type.validateNumbers(CodeGeneratorPackage.Literals.NEGATION__VALUE)
	}

	@Check
	def checkExpression(Exponent exponent) {
		exponent.base.type.validateNumbers(CodeGeneratorPackage.Literals.EXPONENT__BASE)
		exponent.power.type.validateNumbers(CodeGeneratorPackage.Literals.EXPONENT__POWER)
	}

	@Check
	def checkPower(Not not) {
		not.value.type.validateTypes(TypeChecker.Type.BOOLEAN, CodeGeneratorPackage.Literals.NOT__VALUE)
	}
	
		
	def boolean hasSensor(Board current){
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
	
	def boolean hasCycle(Board current, HashSet<Board> visited){
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
	
	
	@Check
	def checkBoard(Board board) {
		val visited = new HashSet<Board>
		if (hasCycle(board, visited)){
			error('''cyclic inheritance in hierarchy of board «board.name»''', CodeGeneratorPackage.Literals.BOARD__NAME)
			return
		}
		if (!(board.hasSensor)){
			error('''«board.name» must have atleast 1 sensor''', CodeGeneratorPackage.Literals.BOARD__NAME)
		}
	}
	
	@Check(CheckType.NORMAL)
	def checkUniqueBoardNames(Board board){
		val config = board.getContainerOfType(DeviceConf)
		for (Board b: config.board.filter[it !== board]){
			if (board.name.equals(b.name)){
				error('''duplicate «board.name»''', CodeGeneratorPackage.Literals.BOARD__NAME)
			}
		}
		val boardNames = board.superTypes.map[abstractBoard | abstractBoard.name]
		val uniqueBoardNames = new HashSet<String>
		val duplicated = boardNames.filter[ab | ab !== null && !uniqueBoardNames.add(ab)].toSet
		if (!(duplicated.empty)){
			error('''«board.name» cannot extend from duplicate abstract board «String.join(", ", duplicated)» ''', CodeGeneratorPackage.Literals.BOARD__NAME)
		}
	}

	def visibleContainers(EObject eObject) {
		val resourceDescription = eObject.resourceDescription
		containerManager.getVisibleContainers(resourceDescription, resourceDescriptions)
	}
	
	def resourceDescription(EObject eObject) {
		resourceDescriptions.getResourceDescription(eObject.eResource.URI)
	}
	
	@Check(CheckType.NORMAL)
	def checkDuplicateBoardsInFiles(DeviceConf conf) {
		val boardType = CodeGeneratorPackage.eINSTANCE.board
		val boards = conf.visibleContainers.map[container | container.getExportedObjectsByType(boardType)].flatten
		val exportedBoards = conf.resourceDescription.getExportedObjectsByType(CodeGeneratorPackage.eINSTANCE.board)
		val externalBoards = boards.toSet
		externalBoards.removeAll(exportedBoards.toSet)
		val externalBoardNames= externalBoards.toMap[qualifiedName]
		
		for (board : conf.board) {
			if (externalBoardNames.containsKey(qualifiedNameProvider.getFullyQualifiedName(board))) {
				error("The board " + board.name + " is already defined", board, CodeGeneratorPackage.Literals.BOARD__NAME)}
			}
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
	
	
	@Check
	def checkSampleSignal(ChannelOut channelOut){
		val sampler = channelOut.getContainerOfType(SensorData)?.getContainerOfType(Sensor)?.sampler
		if (sampler !== null && sampler instanceof SignalSampler) {
			val board = channelOut.getContainerOfType(SensorData)?.getContainerOfType(Sensor)?.getContainerOfType(Board)
			if (board !== null){
				val channel = channelOut.channel
				if (channel !== null && !board.inheritedInChannels.contains(channel)){
					error("Channel " + channel.name + " must be an input channel when used with sample signal", channelOut, CodeGeneratorPackage.Literals.CHANNEL_OUT__CHANNEL)
				}
			}
		}
	}
	
}
