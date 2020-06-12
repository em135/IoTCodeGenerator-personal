package org.iot.codegenerator.typing

import org.iot.codegenerator.codeGenerator.BooleanLiteral
import org.iot.codegenerator.codeGenerator.Conditional
import org.iot.codegenerator.codeGenerator.Div
import org.iot.codegenerator.codeGenerator.Exponent
import org.iot.codegenerator.codeGenerator.Expression
import org.iot.codegenerator.codeGenerator.Filter
import org.iot.codegenerator.codeGenerator.Map
import org.iot.codegenerator.codeGenerator.Minus
import org.iot.codegenerator.codeGenerator.Mul
import org.iot.codegenerator.codeGenerator.Negation
import org.iot.codegenerator.codeGenerator.NumberLiteral
import org.iot.codegenerator.codeGenerator.Pipeline
import org.iot.codegenerator.codeGenerator.Plus
import org.iot.codegenerator.codeGenerator.Reference
import org.iot.codegenerator.codeGenerator.Sensor
import org.iot.codegenerator.codeGenerator.StringLiteral
import org.iot.codegenerator.codeGenerator.Window

import static extension org.eclipse.xtext.EcoreUtil2.*

class TypeChecker {

	enum Type {
		INT,
		DOUBLE,
		BOOLEAN,
		STRING,
		INVALID,
		VOID
	}

	def dispatch Type type(NumberLiteral number) {
		val value = number.value
		switch (value) {
			case value.contains('.'):
				Type.DOUBLE
			case value.contains('0x'):
				Type.INT
			case value.toLowerCase.contains('e'):
				Type.DOUBLE
			default:
				Type.INT
		}
	}

	def dispatch Type type(StringLiteral _) {
		Type.STRING
	}

	def dispatch Type type(BooleanLiteral _) {
		Type.BOOLEAN
	}

	def dispatch Type type(Expression _) {
		Type.BOOLEAN
	}
	
	def dispatch Type type(Void _) {
		Type.VOID
	}
	
	def dispatch Type type(Conditional conditional) {
		val correctType = conditional.correct.type
		val incorrectType = conditional.incorrect.type
		val numberType = evaluateNumeralTypes(correctType, incorrectType)

		if (numberType == Type.INVALID) {
			if (correctType == incorrectType) {
				correctType
			} else {
				Type.INVALID
			}
		} else {
			numberType
		}
	}

	def isNumberType(Type type) {
		return type == Type.INT || type == Type.DOUBLE
	}

	def evaluateNumeralTypes(Type type1, Type type2) {
		if (! (type1.isNumberType && type2.isNumberType)) {
			Type.INVALID
		} else if (type1 == Type.DOUBLE || type2 == Type.DOUBLE) {
			Type.DOUBLE
		} else {
			Type.INT
		}
	}
	
	def Type lastType(Pipeline pipeline){	
		var pipe = pipeline
		while(pipe.next !== null){
			pipe = pipe.next
		}
		pipe.typeOfPipeline
	}
	
	def Pipeline lastPipeline(Pipeline pipeline){
		var pipe = pipeline
		while (pipe.next !== null){
			pipe = pipe.next
		}
		return pipe
	}
	
	def dispatch Type typeOfPipeline(Filter filter) {
		filter.inputTypeOfPipeline
	}

	def dispatch Type typeOfPipeline(Map map) {
		map.expression.type
	}

	def dispatch Type typeOfPipeline(Window window) {
		Type.DOUBLE
	}

	def inputTypeOfPipeline(Pipeline pipeline) {
		val precedingPipeline = pipeline.eContainer
		switch precedingPipeline {
			Pipeline: precedingPipeline.typeOfPipeline
			default: Type.INT
		}
	}
	
	
	def dispatch Type type(Plus plus) {
		if (plus.left.type == Type.STRING || plus.right.type == Type.STRING) {
			Type.STRING
		} else {
			evaluateNumeralTypes(plus.left.type, plus.right.type)
		}
	}

	def dispatch Type type(Minus minus) {
		evaluateNumeralTypes(minus.left.type, minus.right.type)
	}

	def dispatch Type type(Mul multiply) {
		evaluateNumeralTypes(multiply.left.type, multiply.right.type)
	}

	def dispatch Type type(Div division) {
		evaluateNumeralTypes(division.left.type, division.right.type)
	}

	def dispatch Type type(Negation negation) {
		if (! negation.value.type.isNumberType) {
			Type.INVALID
		} else {
			negation.value.type
		}
	}

	def dispatch Type type(Exponent exponent) {
		if (evaluateNumeralTypes(exponent.base.type, exponent.power.type) == Type.INVALID) {
			Type.INVALID
		} else {
			Type.DOUBLE
		}
	}

	def dispatch Type type(Reference reference) {
		if (reference?.variable?.name === null) {
			return Type.INVALID
		}

		return reference.typeOf(this)
	}
	
	def typeOf(Reference ref, TypeChecker typeChecker) {
		val variable = ref.variable
		
		val map = variable.getContainerOfType(Map)
		if (map !== null) {
			return typeChecker.type(map.expression)
		}

		val baseSensor = variable.getContainerOfType(Sensor)
		if (baseSensor !== null) {
			return Type.INT
		}

		Type.INVALID
	}
}
