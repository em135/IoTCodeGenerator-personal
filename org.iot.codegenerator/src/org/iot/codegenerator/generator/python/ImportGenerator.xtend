package org.iot.codegenerator.generator.python

import java.util.Map

class ImportGenerator {

	static final Map<String, String> importFallbacks = #{
		"ujson" -> "json",
		"utime" -> "time"
	}

	static def String compileImports(GeneratorEnvironment env) {
		'''
			«FOR module : env.definitionImports»
				«module.compileDefinitionImport(env.getDefinitionsFor(module))»
			«ENDFOR»
			«FOR module : env.moduleImports»
				«module.compileModuleImport»
			«ENDFOR»
		'''
	}
	
	static def String compileDefinitionImport(String module, Iterable<String> definitions) {
		'''from «module» import «FOR definition : definitions SEPARATOR ", "»«definition»«ENDFOR»'''
	}

	static def String compileModuleImport(String module) {
		if (importFallbacks.containsKey(module)) {
			'''
				try:
				    import «module»
				except ModuleNotFoundError:
				    import «importFallbacks.get(module)» as «module»
			'''
		} else {
			'''import «module»'''
		}
	}
}