package org.iot.codegenerator.util

import org.eclipse.xtend.lib.annotations.Accessors
import org.iot.codegenerator.codeGenerator.ExecutePipeline
import org.iot.codegenerator.codeGenerator.Filter
import org.iot.codegenerator.codeGenerator.FrequencySampler
import org.iot.codegenerator.codeGenerator.Map
import org.iot.codegenerator.codeGenerator.Maximum
import org.iot.codegenerator.codeGenerator.Mean
import org.iot.codegenerator.codeGenerator.Median
import org.iot.codegenerator.codeGenerator.Minimum
import org.iot.codegenerator.codeGenerator.Pipeline
import org.iot.codegenerator.codeGenerator.Sensor
import org.iot.codegenerator.codeGenerator.SensorData
import org.iot.codegenerator.codeGenerator.SignalSampler
import org.iot.codegenerator.codeGenerator.StDev
import org.iot.codegenerator.codeGenerator.Var
import org.iot.codegenerator.codeGenerator.Window

import static extension org.eclipse.xtext.EcoreUtil2.*

class GeneratorUtil {
	
	@Accessors static Boolean firstReferanceProcessed
	
	static def String asInstance(String name) {
		'''_«name»'''
	}
	
	static def String asModule(String name) {
		if (name.toLowerCase.equals("esp32")){
			"esp_32" // A module named ESP32 can give problems when using MicroPython
		} else {
			name.toLowerCase
		}
	}

	static def String asClass(String name) {
		if (name.toLowerCase.equals("esp32")){
			"Esp_32" // A class named ESP32 can give problems when using MicroPython
		} else {
			name.toFirstUpper
		}
	}

	static def boolean isFrequency(Sensor sensor) {
		sensor.sampler instanceof FrequencySampler
	}

	static def boolean isSignal(Sensor sensor) {
		sensor.sampler instanceof SignalSampler
	}

	static def Iterable<SensorData> sensorDatas(Sensor sensor) {
		return sensor.eAllOfType(SensorData)
	}
	
	static def String interceptorName(Pipeline pipeline) {
		val type = switch (pipeline) {
			Filter: "Filter"
			Map: "Map"
			Window: "Window"
		}

		val sensor = pipeline.getContainerOfType(Sensor)
		val index = sensor.eAllContents.filter [
			it.class == pipeline.class
		].takeWhile [
			it != pipeline
		].size + 1

		'''Interceptor«type»«index»'''
	}
	
	static def String executePipelineMethod(ExecutePipeline executePipeline){
		val type = switch (executePipeline) {
			Mean: "mean"
		    Median: "median"
		    Var: "var"
		    StDev: "stdev"
		    Minimum: "minimum" 
		    Maximum: "maximum"
		}
		'''«type»'''
	}
	
}
