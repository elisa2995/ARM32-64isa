<h1>Button</h1>
This whole content can be found in the <a href="https://github.com/elisa2995/ARM32-64isa/wiki/GPIO-02_Button/">wiki</a> of the project. 
<br>
The goal of this program is decrementing a counter each time a button is pressed. The source code can be found <a href="https://github.com/elisa2995/ARM32-64isa/tree/master/32bit/GPIO/02_Button">here 32</a> or <a href="https://github.com/elisa2995/ARM32-64isa/tree/master/64bit/GPIO/02_Button">here 64</a>.

<h3>Setup</h3>
<table>
<tr>
<td width="50%">The following images show how you have to connect the button to the board to let the program work. You have to connect three wires. The first goes from one leg of the button through a resistor (here 220 Ohm) to ground. The second goes from the corresponding leg of the button to Vcc (3,3 V). The third connects the first leg of the button to pin17 which reads the state of the button. When the button is open (unpressed) there is no connection between the two legs of the button, so the pin is connected to ground (through the resistor) and we read a LOW.
<br> When the button is closed (pressed), it makes a connection between its two legs, connecting the pin to Vcc, so that we read a HIGH.</td>
<td><a href="https://github.com/elisa2995/ARM32-64isa/blob/master/media/02_Button.png"><img src="https://github.com/elisa2995/ARM32-64isa/blob/master/media/02_Button.png"></a></td>
<td width="15%"><a href="https://github.com/elisa2995/ARM32-64isa/blob/master/media/02_ButtonCircuit.png"><img src="https://github.com/elisa2995/ARM32-64isa/blob/master/media/02_ButtonCircuit.png"></a></td>
</tr>
</table>
<hr>
<h3>How the program works</h3>
The program consists of 3 source files, each of them implementing a different functionality. 
In this program we need to :
<ol>
<li>Map the GPIO memory to a main memory location so that we can access it (see <a href="https://github.com/elisa2995/ARM32-64isa/wiki/GPIO-01_BlinkLED#mapping">blinkLED - Mapping the GPIO memory to a main memory location</a> explanation)</li>
<li>Configure the pin function to input (see <a href="https://github.com/elisa2995/ARM32-64isa/wiki/GPIO-01_BlinkLED#configure">blinkLED - Configure the pin function</a> explanation)</li>
<li>Read the state of the button and decrement consequently a counter</li>
</ol>

<h3 id="readState"> Read the state of a pin </h3>
The implementation of the read function is made in gpioPinRead.s files (<a href="https://github.com/elisa2995/ARM32-64isa/blob/master/32bit/GPIO/02_Button/gpioPinRead32.s">32bit</a>, <a href="https://github.com/elisa2995/ARM32-64isa/blob/master/64bit/GPIO/02_Button/gpioPinRead64.s">64bit</a>).
This function needs as input the address of the GPIO in mapped memory and the number of the pin of which you want to read the state.<br>
First of all, you have to find the address of GPLEV0-GPLEV1 registers, the registers in which the states of the pins are saved (see <a href="https://github.com/elisa2995/ARM32-64isa/wiki/GPIO#pinSetting">GPIO introduction</a>). To do so you simply have to add the offset of GPLEV (you can find it in Broadcom documentation) to the GPIO address in mapped memory.

<table>
<tr>
<th><a href="https://github.com/elisa2995/ARM32-64isa/blob/master/32bit/GPIO/02_Button/gpioPinRead32.s">32 bit</a></th>
<th><a href="https://github.com/elisa2995/ARM32-64isa/blob/master/64bit/GPIO/02_Button/gpioPinRead64.s">64 bit</a></th>
</tr>
<tr>
<td><code> add     r4, r0, GPLEV0    @ pointer to GPLEV regs.</code></td>
<td><code> add     x19, x0, GPLEV0  // pointer to GPSET regs.</code></td>
</tr>
</table>

Then you have to find in which GPLEV registers (GPLEV0 or GPLEV1) there is the field of the pin of interest and the position of this field.
The number of the GPLEV register can be found dividing the number of the pin by 32 (in every register there are 32 bit, each one dedicated to a single pin). The relative pin position within the register is given by the remainder of this division. In this part of the code, there are not many differences between the implementations in the two different architectures, the only thing to point out is that in AArch64 we use Wn registers, which allow accessing only the lower 32 bits of Xn registers (NB: when using Wn registers, the higher bits of the double word are not preserved).
<table>
<tr>
<th><a href="https://github.com/elisa2995/ARM32-64isa/blob/master/32bit/GPIO/02_Button/gpioPinRead32.s">32 bit</a></th>
<th><a href="https://github.com/elisa2995/ARM32-64isa/blob/master/64bit/GPIO/02_Button/gpioPinRead64.s">64 bit</a></th>
</tr>
<tr>
<td><pre><code> 
lsr r0, r5, #DIV_32 @ pinNumber/32 = GPLEV number
lsl r1, r0, #DIV_32 @ r1 = GPLEV number * 32 to 
                    @ compute the remainder
sub r1, r5, r1      @ for relative pin position
lsl r0, r0, #W_SHIFT@ 4 bytes in a register, 
                    @ r0 = offset
add r0, r0, r4      @ address of GPLEVn, 
                    @ r0 = base + offset</code></pre></td>

<td><pre><code> 
lsr w15, w20, #DIV_32 // pinNumber/32 = GPLEV number
lsl w16, w15, #DIV_32 // w16= GPLEV number * 32  
                      // to compute the remainder
sub w16, w20, w16     // for relative pin position        
lsl w15, w15, #W_SHIFT// 4 bytes in a register, 
                      // w15=offset			
add x15, x15, x19     // address of GPSETn, 
                      // w15=base+offset</code></pre></td>
</tr>
</table>

The only thing left to do is reading the state of the pin of interest. To do so we load the entire register of which we want to retrieve a single bit (suppose it is bit N), and for this purpose, we perform N shifts right on the register: in this way we put the bit of interest in the less significant bit of the word.
<a href="https://github.com/elisa2995/ARM32-64isa/blob/master/media/PinRead01.png"><img src="https://github.com/elisa2995/ARM32-64isa/blob/master/media/PinRead01.png"></a>
At this point, we need to clear all the other bits in the registers: therefore we perform AND operation with the mask 0x1. In this way, we obtain the value we are looking for.
<a href="https://github.com/elisa2995/ARM32-64isa/blob/master/media/PinRead02.png"><img src="https://github.com/elisa2995/ARM32-64isa/blob/master/media/PinRead02.png"></a>

It is important to notice that in AArch64 the load is performed with the instruction <code>ldrsw   x17, [x15]</code>. <br><code>ldrsw   Xn, [Xm]</code> is a very useful instruction that you can use when you need to retrieve only a word (32 bit) from the memory. In fact, it goes to the address specified by Xm, that can also not be a multiple of 8 bytes(normal <code>ldr</code> gives segmentation fault with this type of addresses) and retrieves only a word that is saved in the lowest part of Xn, so Wn.

<table>
<tr>
<th><a href="https://github.com/elisa2995/ARM32-64isa/blob/master/32bit/GPIO/02_Button/gpioPinRead32.s">32 bit</a></th>
<th><a href="https://github.com/elisa2995/ARM32-64isa/blob/master/64bit/GPIO/02_Button/gpioPinRead64.s">64 bit</a></th>
</tr>
<tr>
<td><pre><code> 
ldr r2, [r0]    @ get entire register
lsr r2, r2, r1	@ move the pin of interest in 
                @ the lowest bit of the register
and r2, r2, #0x1@ keep only the bit of interest		
mov r0, r2      @ return if the pin is high/low
</code></pre>

<td><pre><code> 
ldrsw x17, [x15]  // get entire 32 bit register
lsr x17, w17, w16 // move the pin of interest in 
                  // the lowest bit of the register
and w17, w17, #0x1// keep only the bit of interest
mov w0, w17       // return if the pin is high/low
</code></pre></td>
</tr>
</table>

The function gpioPinRead is called from the main function in both implementations (<a href="https://github.com/elisa2995/ARM32-64isa/blob/master/32bit/GPIO/02_Button/button32.s">32bit</a>, <a href="https://github.com/elisa2995/ARM32-64isa/blob/master/64bit/GPIO/02_Button/button64.s">64bit</a>).
In the main there are two loops:
<ul>
<li>an outer loop (countLoop) that  each time the button is pushed prints on screen the value od the counter and decrements it</li>
<li>an inner loop (readAgain) that keeps reading the state of the button and ends only when an HIGH level is detected</li>
</ul>
The implementations in the two architectures are pretty much the same.
<table>
<tr>
<th><a href="https://github.com/elisa2995/ARM32-64isa/blob/master/32bit/GPIO/02_Button/button32.s">32 bit</a></th>
<th><a href="https://github.com/elisa2995/ARM32-64isa/blob/master/64bit/GPIO/02_Button/button64.s">64 bit</a></th>
</tr>
<tr>
<td><pre><code> 
countLoop:
readAgain:
  ldr     r0, =100000	@ wait 100 ms
  bl	usleep 
  mov 	r0, r5		@ GPIO programming memory
  mov 	r1, PIN_BTN	@ pin to read
  bl 	gpioPinRead
  cmp	r0, #1		@ r0=1 if the button is pressed
  bne	readAgain
@ Print the value of the counter		
  mov	r1, r6
  sub	r1, r1, #1
  ldr	r0, messageAddr
  bl	printf	 
  subs    r6, r6, 1      @ decrement counter
  bgt     countLoop      @ loop until 0
</code></pre>
<td><pre><code> 
countLoop:
readAgain:
  ldr	x0, =100000	// wait 0.1 s
  bl 	usleep
  mov 	x0, x20		// programming memory
  mov 	x1, #PIN_BTN 	// pin to read
  bl 	gpioPinRead
  cmp	x0, #1		// x0=1 if the button is pressed
  bne	readAgain
// Print the value of the counter
  ldr 	x0, messageAddr
  mov	x1, x21
  sub	x1, x1, #1
  bl 	printf		
  subs    x21, x21, #1  // decrement counter
  bgt     countLoop   	// loop until 0
        
</code></pre></td>
</tr>
</table>
