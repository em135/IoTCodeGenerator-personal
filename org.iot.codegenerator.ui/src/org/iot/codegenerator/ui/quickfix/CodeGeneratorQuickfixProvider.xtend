/*
 * generated by Xtext 2.20.0
 */
package org.iot.codegenerator.ui.quickfix

import org.eclipse.xtext.nodemodel.INode
import org.eclipse.xtext.nodemodel.util.NodeModelUtils
import org.eclipse.xtext.ui.editor.quickfix.DefaultQuickfixProvider
import org.eclipse.xtext.ui.editor.quickfix.Fix
import org.eclipse.xtext.ui.editor.quickfix.IssueResolutionAcceptor
import org.eclipse.xtext.validation.Issue
import org.iot.codegenerator.codeGenerator.DeviceConf

import static extension org.eclipse.xtext.EcoreUtil2.*
import static extension org.iot.codegenerator.validation.IssueCodesProvider.*

/**
 * Custom quickfixes.
 * 
 * See https://www.eclipse.org/Xtext/documentation/310_eclipse_support.html#quick-fixes
 */
class CodeGeneratorQuickfixProvider extends DefaultQuickfixProvider {
	
	@Fix(UNSUPPORTED_LANGUAGE)
	def void correctLanguage(Issue issue, IssueResolutionAcceptor acceptor) {
		acceptor.accept(issue, "Use python as language", "Only python is support, please use python", null, [ element, context |
			val deviceConf = element.eContainer.getContainerOfType(DeviceConf)
			
			context.xtextDocument.replace(issue.offset, deviceConf.language.name.length, "python")
		])
	}
}
