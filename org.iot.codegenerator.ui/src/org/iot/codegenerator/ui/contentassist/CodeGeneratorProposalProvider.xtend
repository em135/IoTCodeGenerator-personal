/*
 * generated by Xtext 2.20.0
 */
package org.iot.codegenerator.ui.contentassist

import java.util.List
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.Assignment
import org.eclipse.xtext.RuleCall
import org.eclipse.xtext.ui.editor.contentassist.ContentAssistContext
import org.eclipse.xtext.ui.editor.contentassist.ICompletionProposalAcceptor
import org.iot.codegenerator.codeGenerator.OnbSensor
import org.iot.codegenerator.validation.ESP32

/**
 * See https://www.eclipse.org/Xtext/documentation/310_eclipse_support.html#content-assist
 * on how to customize the content assistant.
 */
class CodeGeneratorProposalProvider extends AbstractCodeGeneratorProposalProvider {
	
	override complete_OnbSensor(EObject model, RuleCall ruleCall, ContentAssistContext context, ICompletionProposalAcceptor acceptor) {
		val acceptedValues = newArrayList("light", "thermometer", "motion")
		accepts(acceptedValues, context, acceptor)
	}
	
	override completeVariables_Ids(EObject model, Assignment assignment, ContentAssistContext context, ICompletionProposalAcceptor acceptor) {
		var container = model.eContainer
		if (container !== null && container instanceof OnbSensor){
			val sensorType = (container as OnbSensor).sensortype
			val esp32 = new ESP32()
			val currentVariablesIds = (container as OnbSensor).variables.ids
			val currentVariableNames = newArrayList
			for (variable : currentVariablesIds){
				if (variable.name !== null){
					currentVariableNames.add(variable.name)
				}
			}
			switch (sensorType) {
				case "thermometer",case "motion", case "light" :  {
					val acceptedValues = esp32.getSensorVariables(sensorType)
					acceptedValues.removeAll(currentVariableNames)
					accepts(acceptedValues, context, acceptor)
				}
			}
		}
	}
	
	def accepts(List<String> values, ContentAssistContext context, ICompletionProposalAcceptor acceptor){
		values.forEach[accept(context, acceptor)]
	}
	
	def accept(String value, ContentAssistContext context, ICompletionProposalAcceptor acceptor){
		acceptor.accept(createCompletionProposal(value, value, null, context))	
	}
	 
}
