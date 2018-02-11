// distanceTimer64.s
// Integrates 04_Distance/distance64 with the functionalities 
// of systemTimer64, which exploits the Broadcom systemTimer, 
// to manage the time. 
// All the necessaries mapping functionalities are implemented
// by map64.s
// FROM 04_Distance/distance64:
// Activates a distance sensor that works with ultrasound waves. 
// The sensor has to be triggered at least 10 us, it will then start 
// sending ultrasound waves and pulls the echo pin up.
// As the sensor receives the echo it pulls the echo pin down.
// NEW: 
// The program prints on the screen	the distance of the detected 
// object. The measure is repeated 10 times.

// Define my Raspberry Pi
        .cpu    cortex-a53 
		        
// Constants for assembler
        .equ    PERIPH,0x3f000000   		// RPi 3 peripherals
        .equ    GPIO_OFFSET,0x200000  		// start of GPIO device
											
// The following are defined by us:
        .equ    INPUT,0         			// use pin for input
        .equ    OUTPUT,1        			// use pin for ouput
        .equ    PIN_ECHO,11       			// echo pin 
	.equ	PIN_TRIG, 26				// trigger pin 
	.equ	SIXTY_MS, 60000				// wait time between two measures
	.equ	W_SHIFT, 2				// number of shifts to convert bytes to words 
	
	.data
	.align 4
measures:
	.word	0,0,0,0,0,0,0,0	

// Constant program data	   	
        .section .rodata
        .align  4				// $
device:
        .asciz  "/dev/mem"	   // $
devErr:
        .asciz  "Cannot open /dev/mem\n"	 //$
memErr:
        .asciz  "Cannot map /dev/mem\n"		 //$
distMessage:
		.asciz  "Object detected at %i cm\n"

// The program
        .text
        .align  4				// $
        .global addMeasure
        .global main								  	   
main:													  
		stp x30, x29, [sp, #-16]!		// push {lr, fp} $			     
		stp x19, x20, [sp, #-16]!		// push {x19, x20} $  		
		stp x21, x22, [sp, #-16]!		// push {x21, x22} $ 
		stp x23, x24, [sp, #-16]!		// push {x23, x24} $

// Open /dev/mem for read/write and syncing        
        ldr     x0, deviceAddr  		// address of /dev/mem	 $
        bl      openRWSync
        cmp     x0, -1          		// check for error
        bne     memOK       			// no error, continue
        ldr     x0, devErrAddr  		// error, tell user	  
        bl      printf
        b       allDone         		// and end program
        
memOK:   
        mov     x19, x0          		// use x19 for file descriptor

// Map the gpio registers to a main memory location so we can access them
        mov     x0, x19    				// /dev/mem file descriptor		$							   
        ldr     x1, gpio  				// address of GPIO	
		bl      mapMemory	
	   	cmp     x0, -1          		// check for error
        bne     mmapOK          		// no error, continue
        ldr     x0, memErrAddr 			// error, tell user
        bl      printf
        mov     x0, x19         		// /dev/mem file descriptor
        bl      close           		// close the file
		b 		allDone

// All OK, set up timer and sensor
mmapOK:  
		mov     x20, x0          		// use x20 for programming memory address 

// Initialize timer
		bl 		initTimer

// Select function for ECHO pin (input)   
       	mov     x0, x20          		// GPIO programming memory
        mov     x1, PIN_ECHO     		// echo pin
        mov     x2, INPUT      	 		// it's an input
        bl      gpioPinFSelect  		// select function

// Select function for TRIGGER pin (output)
        mov     x0, x20          		// GPIO programming memory
        mov     x1, PIN_TRIG     		// trigger pin
        mov     x2, OUTPUT      		// it's an output
        bl      gpioPinFSelect   		// select function

// For 10 times, trigger the sensor and print the distance
		mov 	x23, #8
trigger:
// Trigger the sensor by setting the trigger pin to 1 for at least 10 us
        mov     x0, x20			 		// GPIO programming memory
        mov     x1, PIN_TRIG	 		// trigger pin
        bl      gpioPinSet		 		// pull up the pin 
		mov     x0, #10     	 		// wait for 10 us
        bl      delay

		mov     x0, x20          		// GPIO programming memory
        mov     x1, PIN_TRIG	 		// trigger pin
        bl      gpioPinClr		 		// pull down the pin

// Keep reading the ECHO pin, till it is pulled up (the sensor starts sending ultrasound waves)
waitWave:
        mov 	x0, x20			 		// GPIO programming memory
		mov 	x1, PIN_ECHO	 		// pin to read
		bl 		gpioPinRead		 		// read the level of the pin
		cmp		x0, #1
		bne		waitWave 		 		// if it's not 1 the wave has not been sent yet  

// Get the time when the wave is sent
		bl 		getTimestamp
		mov 	x21, x0					// start time

// Keep reading the ECHO pin, till it is pulled down (the sensor has received the echo)
waitEcho:
        mov 	x0, x20			 		// GPIO programming memory
		mov 	x1, PIN_ECHO	 		// pin to read
		bl 		gpioPinRead		 		// read the level of the pin
		cmp		x0, #0
		bne		waitEcho	     		// if it's not 0 the sensor has not received the echo yet        

// Get the time when the echo is received 
		bl 		getTimestamp
		mov 	x22, x0					// received echo time

// Calculate the time elapsed since the wave was sent and the echo was received
		mov 	x0, x21		  			// start time
		mov 	x1, x22				    // received echo time
		bl 		getElapsedTime			
		mov		x21, x0					// time elapsed 

// Retrieve the distance of the object
		sub		x23, x23, #1
		ldr 		x1, measuresAddr
		str		w21, [x1, x23, lsl #W_SHIFT]

		mov 		x0, #SIXTY_MS				// wait for 60 ms
		bl 		delay

		cmp 		x23, #0
		bne		trigger	
		
// Calculate the average measure and the corresponding distance
		ldr 		x0, measuresAddr
		bl 		computeAverage				
		bl 		convToDistance
		mov 		x21, x0
		ldr		x0, distMessageAddr 		// message
		mov		x1, x21				// distance
		bl		printf
		
// Save measures into a file
		ldr 		x0, measuresAddr
		mov		x1, #8
		bl 		saveMeasures		

// Unmap the memory
        mov     x0, x20         		// memory to unmap
		mov		x1, x19					// file descriptor
        bl      closeDevice          	

// Unmap and close the timer
		bl		closeTimer

allDone:        
        mov     x0, #0           		// return 0;
		ldp 	x23, x24, [sp], #16		// pop {x21, x22} $ 
		ldp 	x21, x22, [sp], #16		// pop {x21, x22} $ 
		ldp 	x19, x20, [sp], #16		// pop {x19, x20} $ 
		ldp 	x30, x29, [sp], #16		// pop {lr, fp}   $ 

        ret			            		// return

// computeAverage
// Computes the average measure 
// Calling sequence:
//		x0 <- address of the array of measures
// 		bl computeAverage
// Output:
// 		r0 <- average measure
computeAverage:
		stp		x19, x20, [sp, #-16]!		// push {x19, x20} $
		stp 		x21, x22, [sp, #-16]!		// push {x21, x22} $
		mov 		x20, x0			// base address
		mov 		x19, #8			// counter
		mov 		x0, #0			// initialize output
		
addMeasure:	
		sub		x19, x19, #1
		ldrsw 		x21, [x20, x19, lsl #W_SHIFT]	// load measure
		add 		x0, x0, x21, lsr #3	
		
		cmp 		x19, #0
		bne		addMeasure
				
		ldp 	x21, x22, [sp], #16		// pop {x21, x22} $ 
		ldp 	x19, x20, [sp], #16		// pop {x19, x20} $ 
		ret

// convToDistance
// Converts the amount of time elapsed between the trigger 
// and the echo (us), to the distance of the obstacle (cm). 
// Calling sequence:
//		x0 <- elapsed time
// Output:
//		x0 <- distance	[cm]
// distance [cm]= (sound_speed*elapsed_time)/2 = 
// = (340 *10^-4 [cm/us]) * (elapsed_time[us]) /2 =
// = 170 * 10^-4 *elapsed_time [cm] = elapsed_time/58 [cm] 
convToDistance:
		
		ldr		x1, =58
		udiv	x0, x0, x1
		ret
		        
        .align  4
// addresses of messages
deviceAddr:
        .dword   device
gpio:
        .dword   PERIPH+GPIO_OFFSET
devErrAddr:
        .dword   devErr
memErrAddr:
        .dword   memErr
distMessageAddr:
		.dword	 distMessage
measuresAddr:
	.dword	measures
	
	

			
							
