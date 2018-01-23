<h1>DistanceTimer</h1>
This whole content can be found in the <a href="https://github.com/elisa2995/ARM32-64isa/wiki/GPIO-05-DistanceTimer">wiki</a> of the project. <br>
This program integrates the program <a href="https://github.com/elisa2995/ARM32-64isa/wiki/GPIO-04_Distance">04_Distance</a>, exploiting the functionalities of the System Timer. In fact,  counting the time between the moment in which the ultrasonic wave is sent and the echo is received back, it's possible to calculate the distance of the object.

<h3>Setup</h3>
The setup is the same discussed in <a href="https://github.com/elisa2995/ARM32-64isa/wiki/GPIO-04_Distance">Distance</a>:
<table>
<tr>
<td width="50%">The following images show how you have to connect the sensor and the board to let the program work. The sensor we used is the Ultrasonic Ranging Module HC-SR04, you can find <a href="https://github.com/elisa2995/ARM32-64isa/blob/master/media/Sensor_HCSR04.pdf">here</a> some documentation.<br>
The sensor has 4 legs. Starting from left to right you have to connect them to GND, pin 11 (ECHO), pin 26(TRIGGER) and Vcc respectively.<br>
The sensor works as follow: when the TRIGGER pin is kept HIGH for at leat 10 μs the sensor pulls up the ECHO pin and starts sending ultrasonic waves. When it receives back the first echo it pulls down the ECHO pin.
</td>
<td><a href="https://github.com/elisa2995/ARM32-64isa/blob/master/media/04_Distance.png"><img src="https://github.com/elisa2995/ARM32-64isa/blob/master/media/04_Distance.png"></a></td>
<td width="15%"><a href="https://github.com/elisa2995/ARM32-64isa/blob/master/media/04_DistanceCircuit.png"><img src="https://github.com/elisa2995/ARM32-64isa/blob/master/media/04_DistanceCircuit.png"></td>
</tr>
</table>

<h3>How the program works</h3>
The program follows the steps of the program <a href="https://github.com/elisa2995/ARM32-64isa/wiki/GPIO-04_Distance">Distance</a> but it also counts the round trip time of the echo, in order to retrieve the distance of the detected object. <br>
It exploits the System Timer of the Raspberry Pi and we found some useful tips at <a href="https://www.cl.cam.ac.uk/projects/raspberrypi/tutorials/os/ok04.html">Baking Pi – Operating Systems Development</a>.
<h4>System Timer</h4>
For counting the time, we had to map the registers of the System Timer in the main memory. To do so we had to access <code>/dev/mem</code> both in AArch32 and in AArch64, hence to let this program work <b>it is mandatory</b> to run it as <code>root</code>.
The mapping process is the same discussed at <a href="https://github.com/elisa2995/ARM32-64isa/wiki/GPIO-01_BlinkLED#mapping">BlinkLED - Mapping the GPIO memory to a main memory location</a>. Since we had to do the mapping twice (once for the GPIO memory and once for the System Timer memory) we created a source file in both architectures <code><a href="https://github.com/elisa2995/ARM32-64isa/blob/master/32bit/GPIO/05_Timer/map32.s">map32.s</a></code><code><a href="https://github.com/elisa2995/ARM32-64isa/blob/master/64bit/GPIO/05_Timer/map64.s">map64.s</a></code> which
implements the whole mapping logic.
The functions that use the System Timer are implemented in <code><a href="https://github.com/elisa2995/ARM32-64isa/blob/master/32bit/GPIO/05_Timer/systemTimer32.s">SystemTimer32</a></code> and  <code><a href="https://github.com/elisa2995/ARM32-64isa/blob/master/64bit/GPIO/05_Timer/systemTimer64.s">SystemTimer64</a></code>.
These functions are:
<ul>
<li><code>getTimestamp</code><br> This function returns the current timestamp. This value is represented as a 64 bit number so to store the whole content in AArch32 we have to use two registers. Even if it could seem easier to get this value in AArch64, trying to load it with a single <code>ldr</code> would lead to a segmentation fault because the address is not a multiple of 8 bytes. To solve this problem it is necessary to load the higher and lower part separately and then combine them in a single 64 register. 
<table>
<tr>
<td>32 bit</td>
<td>64 bit</td>
</tr>
<tr>
<td><pre><code>
ldr  r0, progMemAddr	       @ pointer to the address 
                               @ of TIMER regs
ldr  r0, [r0]		       @ address of TIMER regs
ldrd r0, r1, [r0, #CLO_OFFSET]
</code></pre></td>
<td><pre><code>
ldr  x0, progMemAddr         // pointer to the address 
                             // of TIMER regs
ldr  x0, [x0]                // address of TIMER regs
ldrsw  x1, [x0, #CLO_OFFSET] // lower 32 bits of the 
                             // system timer
ldrsw  x2, [x0, #CHI_OFFSET] // higher 32 bits of the
                             // system timer
lsl  x2, x2, #32				
orr x0, x1, x2               // combine the two parts 
                             // in a single dword
</code></pre></td>
</tr>
</table>
</li>
<li><code>getElapsedTime</code> <br>
This function receives in input two timestamps and it computes the difference between them. In AArch64 it is a simple subtraction whereas in AArch32 things are more complex because each timestamp is represented by two different registers. To do the operation correctly you have to subtract first the two lower parts and then the higher parts. This last subtraction has to take into account the possible borrow generated by the first operation, so you have to use <code>sbc</code> instruction.
<table>
<tr>
<td>32 bit</td>
<td>64 bit</td>
</tr>
<tr>
<td><pre><code>
subs  r0, r2, r0  @ subtract the lower part of the two timestamps
sbc  r1, r3, r1	  @ subtract the higher part of the two timestamps, 
                  @ eventually subtracting the borrow generated by
                  @ the previous sub
</code></pre></td>
<td><pre><code>
sub 	x0, x1, x0
</code></pre></td>
</tr>
</table>
</li>
<li><code>delay</code><br>
This function receives as input how many microsecods you want to wait for. First, <code>getTimestamp</code> is called to get the start time and then a loop begins. For each iteration the current timestamp is compared with the start time (with the function <code>getElapsedTime</code>) and when their difference exceeds the input delay the function ends.
<table>
<tr>
<td>32 bit</td>
<td>64 bit</td>
</tr>
<tr>
<td><pre><code>
mov  r4, r0        @ time to wait for
bl  getTimestamp
mov  r5, r0
mov  r6, r1

delayLoop:
bl  getTimestamp
mov  r2, r0        @ lower 32 bits of current timestamp
mov  r3, r1	   @ higher 32 bits of current timestamp
mov  r0, r5	   @ lower 32 bits of start time
mov  r1, r6	   @ higher 32 bits of start time
bl  getElapsedTime
cmp  r0, r4
blt  delayLoop	   @ if the elapsed time is less 
                   @ than the time we have to wait for
</code></pre></td>
<td><pre><code>
mov  x19, x0     // time to wait for
bl  getTimestamp
mov  x20, x0	 // start time	

// Wait until the timer exceeds	
delayLoop:	
bl  getTimestamp
mov  x1, x0	// current time
mov  x0, x20	// start time
bl  getElapsedTime
cmp  x0, x19
blt  delayLoop	// if the elapsed time is less
                // than the time to wait for
</code></pre></td>
</tr>
</table>
</li>
</ul>

<h4>Where is the object?</h4>
The Ultrasonic Sensor sends out a high-frequency sound pulse. As the wave hits an object it is reflected back. 
The speed of sound is 340 meters per second in air, so we can determine the distance of the detected object with this simple calculation:<br><br>

distance [cm]= (sound_speed[cm/μs] * elapsed_time[μs])/2 = 
<br>= (340 *10^-4 [cm/μs]) * (elapsed_time[μs]) /2 =
<br>= 170 * 10^-4 *elapsed_time [cm] ≃ elapsed_time/58 [cm]

You have to divide by 2 because the sound wave has to travel to the object and back.
The time that we have to use is the elapsed time between when an ultrasonic wave is transmitted and when it is received.


