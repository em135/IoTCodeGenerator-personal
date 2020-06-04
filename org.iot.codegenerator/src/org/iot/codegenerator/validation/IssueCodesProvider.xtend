package org.iot.codegenerator.validation

interface IssueCodesProvider {
		
		static val ISSUE_CODE_PREFIX = "org.iot.codegenerator.";
		static val UNSUPPORTED_LANGUAGE = ISSUE_CODE_PREFIX + "UnsupportedLanguage"
		static val UNUSED_VARIABLE = ISSUE_CODE_PREFIX + "UnusedVariable"
		
}