<h1>ButtonLED</h1>
This whole content can be found in the <a href="https://github.com/elisa2995/ARM32-64isa/wiki/GPIO-02_Button/">wiki</a> of the project. 
<br>
This program makes a LED blink 5 times when a button is pressed.The source code can be found <a href="https://github.com/elisa2995/ARM32-64isa/tree/master/32bit/GPIO/03_ButtonLED">here 32</a> or <a href="https://github.com/elisa2995/ARM32-64isa/tree/master/64bit/GPIO/03_ButtonLED">here 64</a>.
<h3>Setup</h3>
<table>
<tr>
<td width="50%">The following images show how you have to connect the button and the LED to the board to let the program work. You have to connect four wires. The first goes from one leg of the button through a resistor (here 220 Ohm) to ground. The second goes from the corresponding leg of the button to Vcc (3,3 V). The third connects the first leg of the button to pin 17 which reads the state of the button. When the button is open (unpressed) there is no connection between the two legs of the button, so the pin is connected to ground (through the resistor) and we read a LOW. When the button is closed (pressed), it makes a connection between its two legs, connecting the pin to Vcc, so that we read a HIGH.<br> The cathode of the LED is connected to pin 26, while the anode is linked to Vcc through a resistor (220 Ohm).
Notice that at the beginning the voltage of the LED pin is floating, so it's important to initialize it to Vcc.</td>
<td><a href="https://github.com/elisa2995/ARM32-64isa/blob/master/media/03_ButtonLED.png"><img src="https://github.com/elisa2995/ARM32-64isa/blob/master/media/03_ButtonLED.png"></a></td>
<td width="25%"><a href="https://github.com/elisa2995/ARM32-64isa/blob/master/media/03_ButtonLEDCircuit.png"><img src="https://github.com/elisa2995/ARM32-64isa/blob/master/media/03_ButtonLEDCircuit.png"></td>
</tr>
</table>
<hr>
<h3>How the program works</h3>
This program is the combination of the programs <a href="https://github.com/elisa2995/ARM32-64isa/wiki/GPIO-01_BlinkLED">01_BlinkLED</a> and <a href="https://github.com/elisa2995/ARM32-64isa/wiki/GPIO-02_Button">02_Button</a>. 
You can read the main differences in the implementations between the two architectures at their description pages.

