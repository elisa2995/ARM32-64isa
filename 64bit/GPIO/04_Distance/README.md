<h1>Distance</h1>
This whole content can be found in the <a href="https://github.com/elisa2995/ARM32-64isa/wiki/GPIO-02_Distance/">wiki</a> of the project. 
<br>
The aim of this program is to use an ultrasound distance sensor to detect objects. The source code can be found <a href="https://github.com/elisa2995/ARM32-64isa/tree/master/32bit/GPIO/04_Distance">here32</a> or <a href="https://github.com/elisa2995/ARM32-64isa/tree/master/64bit/GPIO/04_Distance">here 64</a>.
<h3>Setup</h3>
<table>
<tr>
<td width="50%">The following images show how you have to connect the sensor and the board to let the program work. The sensor we used is the Ultrasonic Ranging Module HC-SR04, you can find <a href="https://github.com/elisa2995/ARM32-64isa/blob/master/media/Sensor_HCSR04.pdf">here</a> some documentation.<br>
The sensor has 4 legs. Starting from left to right you have to connect them to GND, pin 11 (ECHO), pin 26(TRIGGER), Vcc respectively.<br>
The sensor works as follow: when the TRIGGER pin is kept HIGH for at leat 10 us the sensor pull up the ECHO pin and starts sending ultrasonic waves. When it receives back the first echo it pull down the ECHO pin .
</td>
<td><a href="https://github.com/elisa2995/ARM32-64isa/blob/master/media/04_Distance.png"><img src="https://github.com/elisa2995/ARM32-64isa/blob/master/media/04_Distance.png"></a></td>
<td width="15%"><a href="https://github.com/elisa2995/ARM32-64isa/blob/master/media/04_DistanceCircuit.png"><img src="https://github.com/elisa2995/ARM32-64isa/blob/master/media/04_DistanceCircuit.png"></td>
</tr>
</table>

<h3>How the program works</h3>
The program is composed of 5 source files and does the following operations:
<ol>
<li>Map the GPIO memory to a main memory location so that we can access it (see <a href="https://github.com/elisa2995/ARM32-64isa/wiki/GPIO-01_BlinkLED#mapping">BlinkLED - Mapping the GPIO memory to a main memory location</a> explanation)</li>
<li>Configure the ECHO pin as input and the TRIGGER pin as output (see <a href="https://github.com/elisa2995/ARM32-64isa/wiki/GPIO-01_BlinkLED#configure">BlinkLED - Configure the pin function</a> explanation)</li>
<li>Pull up the TRIGGER pin for 10 us and then pull down(see <a href="https://github.com/elisa2995/ARM32-64isa/wiki/GPIO-01_BlinkLED">BlinkLED - </a> explanation) </li>
<li>Keep reading the value of the ECHO pin until the first echo signal comes back (see <a href="https://github.com/elisa2995/ARM32-64isa/wiki/GPIO-02_Button#readState">Button - Read the state of a pin </a> explanation) and then it prints it on screen </li>
</ol>
