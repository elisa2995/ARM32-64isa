<h1>BlinkLED</h1>
This whole content can be found in the <a href="https://github.com/elisa2995/ARM32-64isa/wiki/GPIO-01_BlinkLED/">wiki</a> of the project. 
<br>The aim of this program is to blink 5 times a led connected to pin 17. The source code can be found <a href="https://github.com/elisa2995/ARM32-64isa/tree/master/32bit/GPIO/01_BlinkLED">here 32</a> or <a href="https://github.com/elisa2995/ARM32-64isa/tree/master/64bit/GPIO/01_BlinkLED">here 64</a>.
<h3>Setup</h3>
<table>
<tr>
<td width="50%">
The following images show how you have to connect the led to the board. Starting from Vcc (3.3V) you have to connect a resistor (we used 220Ohm resistors) to the anode(+) of the LED, while its cathode is connected to pin 17. <br>A LED is a Diode, so to be turned on a suitable voltage has to be applied to its leads. Since the anode is at 3.3V, we need to connect the cathode to ground if we want to light the LED. 
<br>Notice that at the beginning the voltage of the pin is floating, therefore it may happen that your LED is already on before the program even starts. It's important to initialize the pin to Vcc so that at the beginning the LED is off since the difference of potential at its leads is 0V.
</td>
<td >
<a href="https://raw.githubusercontent.com/elisa2995/ARM32-64isa/master/media/01_BlinkLED.png?token=AY_nOW1C0tEoTdkg6mP7Dl1MxVtHrbI0ks5abvXvwA%3D%3D"><img width="100%" src="https://github.com/elisa2995/ARM32-64isa/blob/master/media/01_BlinkLED.png"  ></a>
</td>
<td width="15%">
<img src="https://github.com/elisa2995/ARM32-64isa/blob/master/media/01_BlinkLEDCircuit.png">
</td>
</tr>
</table>
<br>

<hr>
<h3> How the program works </h3>
The program consists of 4 source files, each of them implementing a different functionality. As you may already have understood from the <a href="https://github.com/elisa2995/ARM32-64isa/wiki/GPIO">GPIO introduction</a>, in this program we will need to : 

<ol>
<li><a href="#mapping">Map the GPIO memory to a main memory location so that we can access it</a></li>
<li><a href="#configure">Configure the pin function</a></li>
<li><a href="#initialize">Initialize the voltage of the pin to Vcc, to be sure that our LED is initially off</a></li>
<li><a href="#blink">Switch 5 times between LOW and HIGH voltage, waiting 1 second in each state, to make the LED blink</a></li>
</ol>

We now analyze how each of these functionalities is implemented:

<h4 id="mapping">1 - Mapping the GPIO memory to a main memory location</h4>

This functionality is implemented in the assembly file blinkLEDxx.s.
As explained in the intro, we first need to open the device file, which in case we're working with Raspbian (32bits) is <code>dev/gpiomem</code>, while in Gentoo (64bits) is <code>dev/mem</code>. 
Calling the open function is straightforward: since it needs 2 parameters, we need to load them in the first two registers (r0,r1 - x0,x1) as established by the Procedure Call Standard. Then we just branch and link to the function, which will return in register r0(/x0) the file descriptor.

<table>
<tr>
<th><a href="https://github.com/elisa2995/ARM32-64isa/blob/7b6539b6a37b7b2ddbf0a719d9b15fc2110857a9/32bit/GPIO/01_BlinkLED/blinkLED32.s#L53-L64">32bits</a></th>
<th><a href="https://github.com/elisa2995/ARM32-64isa/blob/7b6539b6a37b7b2ddbf0a719d9b15fc2110857a9/64bit/GPIO/01_BlinkLED/blinkLED64.s#L52-L61">64bits</a></th>
</tr>
<tr>
<td><code>
<pre>
 ldr     r0, deviceAddr  @ address of /dev/gpiomem
 ldr     r1, openMode    @ flags for accessing device
 bl      open
</pre>
</code></td>
<td>
<code>
<pre>
ldr     x0, deviceAddr  // address of /dev/mem	 
ldr     x1, openMode    // flags for accessing device
bl      open
</pre>
</code>
</td>
</tr>
</table>

The instructions following the reported ones, check whether the file was opened correctly or not (open returns a -1 if an error occurred) and eventually print a message on the screen and exit the program.

<br><br>
Once the file is opened correctly, we can use the file descriptor returned by <code>open</code> to map the memory to a main memory location. As we have already seen in the intro, the <code>mmap</code> function requires 6 arguments, but the calling procedure for AARCH32 reserves only 4 register to pass parameters. This means that the function will look for the last two parameters at the top 2 positions of the stack. Therefore when working with the 32bit OS we will need to push them into the stack and pop them once the function is called, while with 64 bits we can use x0,...,x5 with no problem:

<table>
<tr>
<th><a href="https://github.com/elisa2995/ARM32-64isa/blob/7b6539b6a37b7b2ddbf0a719d9b15fc2110857a9/32bit/GPIO/01_BlinkLED/blinkLED32.s#L63-L79">32bits</a></th>
<th><a href="https://github.com/elisa2995/ARM32-64isa/blob/7b6539b6a37b7b2ddbf0a719d9b15fc2110857a9/64bit/GPIO/01_BlinkLED/blinkLED64.s#L63-L77">64bits</a></th>
</tr>
<tr>
<td><code><pre>
    mov     r4, r0          @ use r4 for file descriptor
    ldr	    r5, gpio	    @ address of the GPIO
    <b>push    {r4, r5}</b>
    mov     r0, #NO_PREF    @ let kernel pick memory
    mov     r1, #PAGE_SIZE  @ get 1 page of memory
    mov     r2, #PROT_RDWR  @ read/write this memory
    mov     r3, #MAP_SHARED @ share with other processes
    bl      mmap
    <b>pop     {r4, r5}</b>
    cmp     r0, -1          @ check for error
    bne     mmapOK          @ no error, continue
    ldr     r0, memErrAddr  @ error, tell user
    bl      printf
    b       closeDev        @ and close /dev/gpiomem
</pre></code></td>
<td><code><pre>
    mov     x19, x0         // use x19 for file descriptor
    mov     x0, #NO_PREF    // let kernel pick memory
    mov     x1, #PAGE_SIZE  // get 1 page of memory	
    mov     x2, #PROT_RDWR  // read/write this memory
    mov     x3, #MAP_SHARED // share with other processes	
    <b>mov     x4, x19	    // <b>/dev/mem</b> file descriptor</b>
    <b>ldr     x5, gpio        // address of GPIO</b>
    bl      mmap	
    cmp     x0, -1          // check for error
    bne     mmapOK          // no error, continue
    ldr     x0, memErrAddr  // error, tell user
    bl      printf
    b       closeDev        // and close /dev/mem
</pre></code></td>
</tr>
</table>

<h4 id="configure">2 - Configure the pin function</h4>
Now that we can access the GPIO registers, we need to configure the function of the pin, hence we need to modify the GPFSEL registers, which can be found at the beginning of the GPIO memory (see <a href="https://github.com/elisa2995/ARM32-64isa/wiki/GPIO#pinSetting">here</a>).
<br>
The part of the program that is in charge of configuring the pin functions is implemented in the assembly files gpioPinFSelectxx.s (<a href="https://github.com/elisa2995/ARM32-64isa/blob/7b6539b6a37b7b2ddbf0a719d9b15fc2110857a9/32bit/GPIO/01_BlinkLED/gpioPinFSelect32.s">32bit</a>, <a href="https://github.com/elisa2995/ARM32-64isa/blob/7b6539b6a37b7b2ddbf0a719d9b15fc2110857a9/64bit/GPIO/01_BlinkLED/gpioPinFSelect64.s">64bit</a>). This file basically consist of a single routine, which takes as input the address of the GPIO in mapped memory, the pin number and the desired function, and updates the right register accordingly. This routine will be called outside this file, hence it is made global through the global directive (<code>.global gpioPinFselect</code> (<a href="https://github.com/elisa2995/ARM32-64isa/blob/7b6539b6a37b7b2ddbf0a719d9b15fc2110857a9/32bit/GPIO/01_BlinkLED/gpioPinFSelect32.s#L18">32bit</a>,<a href="https://github.com/elisa2995/ARM32-64isa/blob/7b6539b6a37b7b2ddbf0a719d9b15fc2110857a9/64bit/GPIO/01_BlinkLED/gpioPinFSelect64.s#L15">64bit</a>)).
<br> The first thing to do here is to find out the address of the register that we want to modify. Each GPFsel register configures up to 10 pins, and reserver 3 bits for each pin (hence bit 30-31 are not used). As reported in the BCM2835 documentation at page 92, the function codes are:
<ul>
<li>000 = input</li>
<li>001 = output</li>
<li>100 = alternate function 0</li>
<li>101 = alternate function 1</li>
<li>110 = alternate function 2</li>
<li>111 = alternate function 3</li>
<li>011 = alternate function 4</li>
<li>010 = alternate function 5</li>
</ul>
For the aim of this program we need to configure pin 17 as an ouput, therefore the third parameter passed to the function is 1 (<a href="https://github.com/elisa2995/ARM32-64isa/blob/7b6539b6a37b7b2ddbf0a719d9b15fc2110857a9/32bit/GPIO/01_BlinkLED/blinkLED32.s#L86">32bits</a>, <a href="https://github.com/elisa2995/ARM32-64isa/blob/7b6539b6a37b7b2ddbf0a719d9b15fc2110857a9/64bit/GPIO/01_BlinkLED/blinkLED64.s#L87">64bits</a>). 

<br>The first thing to do now, is to find out the address of the register we're going to modify, which will be a base + an offset calculated as follows:
<br><code>offset = (pinNumber/pins_per_regs)*4 (bytes for each register)</code> <br>
(which in our case is (17/10)\*4 = 1\*4=4, you can see in the <a href="#pin17fsel">image</a> that this is the correct offset that we need to access GPFSEL1). At this point, we can load the register of interest, in order to modify its value and store it back. 

<br>Next we have to find out which bits we have to modify, the "internal offset" in the register. To do so we calculate the remainder of the previous division 
<br><code>remainder = pinNumber - pinNumber\*offset</code><br>
 and multiply it by 3, because each pin is configured by 3 bits (in our case remainder = 17-1*10=7 hence the internal offset will be 21, as you can see from the figure below). The internal offset indicates the number of shifts that we have to perform to place the function number in the right position.

<br>The following images will make it all clearer:
<a id="pin17fsel" href="https://github.com/elisa2995/ARM32-64isa/blob/master/media/pin17FSEL.png"><img src="https://github.com/elisa2995/ARM32-64isa/blob/master/media/pin17FSEL.png"></a>
At this point we can clear the 3 bits of intereset (<code>bic</code>) and then insert the new function with an <code>orr</code> instruction. Once we've done this, we're ready to store the value back into the memory.
Here's the code to perform these operations:
<table>
<tr>
<th>
<a href="https://github.com/elisa2995/ARM32-64isa/blob/7b6539b6a37b7b2ddbf0a719d9b15fc2110857a9/32bit/GPIO/01_BlinkLED/gpioPinFSelect32.s#L34-L54">32bits</a>
</th>
<th>
<a href="https://github.com/elisa2995/ARM32-64isa/blob/7b6539b6a37b7b2ddbf0a719d9b15fc2110857a9/64bit/GPIO/01_BlinkLED/gpioPinFSelect64.s#L33-L55">64bits</a>
</th>
</tr>
<tr>
<td><code><pre>
@Compute address of GPFSEL register and pin field        
  mov   r3, #10         @ divisor
  udiv  r0, r5, r3      @ GPFSEL number

  mul   r1, r0, r3      @ compute remainder
  sub   r1, r5, r1      @     for GPFSEL pin  
        
@ Set up the GPIO pin function register in programming memory
  lsl   r0, r0, #W_SHIFT@ 4 bytes in a register, r0 = offset	 
  add   r0, r4, r0      @ GPFSELn address, r0 = base + offset
  ldr   r2, [r0]        @ get entire register
        
  mov   r3, r1          @ need to multiply pin
  add   r1, r1, r3, lsl 1 @    position by 3
  mov   r3, PIN_FIELD   @ gpio pin field (0b111)
  lsl   r3, r3, r1      @ shift to pin position
  bic   r2, r2, r3      @ clears the 3 bits related
                        @   to the pin of interest

  lsl   r6, r6, r1      @ shift function code to pin position	 
  orr   r2, r2, r6      @ enter function code		
  str   r2, [r0]        @ update register
</pre></code></td>
<td><code><pre>
// Compute address of GPFSEL register and pin field        
  mov   w18, #PINS_IN_REG  // divisor
  udiv  w15, w20, w18      // GPFSEL number
      
  mul   w16, w15, w18      // compute remainder
  sub   w16, w20, w16      //     for GPFSEL pin	  

// Set up the GPIO pin function register in programming memory
  lsl   w15, w15, #W_SHIFT// 4 bytes in a register , x15=offset 
  add   x15, x19, x15     // GPFSELn address , x15=base+offset
  <a href="#loadSingle"><b>ldrsw x17, [x15]	  // get entire 32 bit register</b></a>
        
  mov   w18, w16          // need to multiply pin
  add   w16, w16, w18, lsl #1//    position by 3
  mov   w18, PIN_FIELD   // gpio pin field (0b111)

  lsl   w18, w18, w16    // shift to pin position
  bic   w17, w17, w18    // clears the 3 bits related to the pin of interest 

  lsl   w21, w21, w16    // shift function code to pin position
  orr   w17, w17, w21    // enter function code
  str   w17, [x15]	 // update register
</pre></code></td>
</tr>
</table>
<h5 id="loadSingle">NB:</h5> we need to load a 32 bit register, using the simple <code>ldr</code> here would be a mistake, since it loads 64 bits and therefore cannot perform a misaligned memory access, as the one in our case (an address ending with -04 cannot be directly accessed in a 64bits architecture). Trying to do this will probably result in a segmentation fault. The instruction ldrsw (load single word) makes all the work for you. </div><br>
Now that we have selected the function of the pin, we're ready to modify the pin level.
<br>
<h4 id="initialize">3 - Initialize the voltage of the pin to Vcc, to be sure that our LED is initially off</h4>
The code in charge to modify the value of the pin is implemented in gpioPinSetxx.s. This file basically consist of a single routine, which takes as input the address of the GPIO in mapped memory and the pin number, and updates the right register accordingly. This routine will be called outside this file, hence it is made global through the global directive (<code>.global gpioPinSet</code>). To modify the value of a pin, we need to write the GPSET registers, which are 2 32-bit registers which contain 1 bit per pin, that if set to one will pull up the pin to HIGH.
<br> The GPSET registers are found at an offset of 0x1c from the beginning of the GPIO. To find the address of the registers which we have to modify, we perform this division:
<br><code>offset = (pinNumber/pin_in_regs)*4 </code><br>
which in our case will result in (17/32)*4=0*4=0, hence pointing to GPSET0, as we expected.
<br> As in the GPFSEL case, we need to compute the offset of the bit within the register, and we do it just as before, computing the remainder of the previous division:
<br><code>internal_offset=pinNumber-offset*pin_in_regs</code><br>
which in our case will result in 17-0*32=17 as expected. This number indicates the number left shift we have to perform in order to pull our pin up.
<br>The following figure will clarify it all:
<img src="https://github.com/elisa2995/ARM32-64isa/blob/master/media/pin17FSET.png">
<br>
Now that we have the address of the register we just need to load the word, modify it and store the value back as we did before. The code to perform these operations is the following:
<table>
<tr>
<th><a href="https://github.com/elisa2995/ARM32-64isa/blob/7b6539b6a37b7b2ddbf0a719d9b15fc2110857a9/32bit/GPIO/01_BlinkLED/gpioPinSet32.s">32bit</a>
</th>
<th>
<a href="https://github.com/elisa2995/ARM32-64isa/blob/7b6539b6a37b7b2ddbf0a719d9b15fc2110857a9/64bit/GPIO/01_BlinkLED/gpioPinSet64.s">64bit</a>
</th>
</tr>
<tr>
<td>
<code> <pre>  

  add  r4, r0, GPSET0  	@ pointer to GPSET regs.
  mov  r5, r1          	@ save pin number
        <br>
@ Compute address of GPSET register and pin field   
  lsr  r0, r5, #DIV_32	@ pinNumber/32 = GPSET number
  lsl  r1, r0, #DIV_32	@ r1 = GPSET number * 32 to 
.                       @ compute the remainder
  sub  r1, r5, r1      	@ 	for relative pin position
  lsl  r0, r0, #W_SHIFT	@ 4 bytes in a register r0 = offset
  add  r0, r0, r4      	@ address of GPSETn r0 = base + offset
<br>              
@ Set up the GPIO pin function register in programming memory
  ldr  r2, [r0]        	@ get entire register
  mov  r3, PIN         	@ one pin
  lsl  r3, r3, r1      	@ shift to pin position
  orr  r2, r2, r3      	@ set bit
  str  r2, [r0]        	@ update register
</pre></code>
</td>
<td>
<code><pre>

  add  x19, x0, GPSET0    // pointer to GPSET regs.
  mov  w20, w1            // save pin number
 <br>       
// Compute address of GPSET register and pin field  
  lsr  w15, w20, #DIV_32  // pinNumber/32 = GPSET number
  lsl  w16, w15, #DIV_32  // w16= GPSET number * 32  
                          // to compute the remainder
  sub  w16, w20, w16      //     for relative pin position
  lsl  w15, w15, #W_SHIFT // 8 bytes in a register, w15=offset
  add  x15, x15, x19      // address of GPSETn, w15= base+offset
<br><br>
  ldrsw	x17, [x15]	  // get entire 32 bit register
  mov  w18, PIN           // one pin
  lsl  w18, w18, w16   	  // shift to pin position
  orr  w17, w17, w18  	  // clear bit
  str  w17, [x15]	  // update register
</pre></code>
</td>
</tr>
</table>
Calling this routine with input register 17 will pull it up to HIGH, turning the LED off. 
<h4 id="blink"> 4 -Switch 5 times between LOW and HIGH voltage, waiting 1 second in each state, to make the LED blink</h4>
To blink our LED, we just need to switch tbe pin level from HIGH to LOW, waiting some time between the two trasitions. Pulling the pin down is basically the same as pulling it up, but in this case we will need to update the GPCLR registers. The part of the program that is in charge of configuring the pin functions is implemented in the assembly files gpioPinClrxx.s (<a href="https://github.com/elisa2995/ARM32-64isa/blob/7b6539b6a37b7b2ddbf0a719d9b15fc2110857a9/32bit/GPIO/01_BlinkLED/gpioPinClr32.s">32bit</a>, <a href="https://github.com/elisa2995/ARM32-64isa/blob/7b6539b6a37b7b2ddbf0a719d9b15fc2110857a9/64bit/GPIO/01_BlinkLED/gpioPinClr64.s">64bit</a>).
<br> The implementation of this function is straightforward, it is basically the same as gpioPinSet, hence will be not commented here.
<br> To blink the led 5 times we implemeneted a loop and waited 1 second between each transition, as you can see in the code:
<table>
<tr>
<th>
<a href="https://github.com/elisa2995/ARM32-64isa/blob/7b6539b6a37b7b2ddbf0a719d9b15fc2110857a9/32bit/GPIO/01_BlinkLED/blinkLED32.s">32bit</a>
</th>
<th>
<a href="https://github.com/elisa2995/ARM32-64isa/blob/7b6539b6a37b7b2ddbf0a719d9b15fc2110857a9/64bit/GPIO/01_BlinkLED/blinkLED64.s">64bit</a>
</th>
</tr>
<tr>
<td><code><pre>

blink:
  mov  r0, r5           @ GPIO programming memory
  mov  r1, #PIN_LED    @ pin to blink
  bl   gpioPinClr	@ pull down the pin  (turn the LED on)

  mov  r0, #ONE_SEC     @ wait a second
  bl   sleep

  mov  r0, r5           @ GPIO programming memory
  mov  r1, #PIN_LED    @ pin to blink
  bl   gpioPinSet       @ pull up the pin (turn the LED off)
 
  mov  r0, #ONE_SEC     @ wait a second
  bl   sleep
  subs r6, r6, 1        @ decrement counter
  bgt  blink		@ loop until 0
</pre></code></td>
<td><code><pre>

blink:
  mov  x0, x20       // GPIO programming memory
  mov  x1, #PIN_LED  // pin to blink
  bl   gpioPinClr    // pull down the pin  (turn the LED on)

  mov  x0, #ONE_SEC  // wait a second
  bl   sleep

  mov  x0, x20	     // GPIO programming memory
  mov  x1, #PIN_LED  // pin to blink
  bl   gpioPinSet    // pull up the pin (turn the LED off)

  mov  x0, #ONE_SEC  // wait a second
  bl   sleep
  subs x21, x21, #1  // decrement counter
  bgt  blink         // loop until 0
</pre></code></td>
</tr>
</table>
We're almost done here: the rest of the program just unmaps the allocated memory and closes the device.
