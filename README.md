# IoTCodeGenerator-personal
Individual Model-driven Software Development Project: IoT Code Generation with Abstract Boards.
The intitial commit of this project is based the group project: https://github.com/Xitric/IoTCodeGenerator/

This project has developed a domain specific language (DSL) for generation code to ESP32 IoT devices.
The generated code samples and processes data from various sensors on the IoT device.

A concrete board can be defined using the DSL. This board which can inherit abstract boards. For instance the .iot file for a concrete esp32 board:
```
language python

board esp32 extends AB_B, AB_C	
	channel radio
	// Onboard sensor linked with I2C
	sensor thermometer as t(tmp, hum)
		sample frequency 1
		
		data temperature
			out oled t.map(tmp > 5**2 ? "hot" : "cold" -> s)
		
		data humidity
			out radio t.filter(hum > 0 && hum != 100)
	// Onboard sensor linked with I2C
	sensor motion as m(acX, acY, acZ)
		sample frequency 1
		 
		data accelerometer
			out endpoint m	

fog
	transformation accelerometer as a(x, y, z)
		data accValues
			out a.filter(x > -10 && y > z/2 && z > y*2)
			
	transformation bLight as l(lux)
		data light
			out l.filter(lux == 0 || lux < 100)
			
cloud
	transformation accValues as a(x, y, z)
		data x
			out a.filter(!(x==0)) 
```

And the .iot file for the inherited abstract boards:
```
language python

abstract board AB_B extends AB_D
	channel bus
	in bus
	// Onboard sensor linked with I2C
	sensor light as light(lux)
		sample signal
		data bLight
			out bus light.map(lux + " B" -> B)
	
abstract board AB_C extends AB_D, AB_E

	sensor light as light(lux)
		sample frequency 2
		data cLight
			out endpoint light.map(lux + " C" -> C)
				
	sensor thermometer as t(tmp, hum)
		sample frequency 1
		
		data values
			out oled t.filter(tmp > 0 && hum < 50)
			
abstract board AB_D
	channel endpoint
	
	sensor light as light(lux)
		sample frequency 1
		data dLight
			out endpoint light.map(lux + " D" -> D)


abstract board AB_E  
	channel radio
	// External sensor reads from pin 12 and 13
	sensor thermistor (12, 13) as t(tmp, hum)
		sample frequency 1 
		
		data thermistorValues
			out radio t.map(tmp -> c).byWindow(100, max -> m)
			out radio t.map(hum -> h).byWindow(10, mean -> m)
```
