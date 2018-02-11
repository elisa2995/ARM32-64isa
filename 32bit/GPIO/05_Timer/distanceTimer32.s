@ distanceTimer32.s
@ Integrates 04_Distance/distance32 with the functionalities of 
@ systemTimer32, which exploits the	Broadcom System timer to 
@ manage the time. All the necessary mapping functionalities 
@ are implemented by map32.s.
@ FROM 04_Distance/distance32:
@ Activates a disatance sensor that works with ultrasound waves.
@ The sensor has to be triggered for at least 10 us, it then
@ starts sending ultrasound waves, and pulls the echo pin up. 
@ As the sensor receives the echo, it pulls the echo pin down. 
@ NEW: The program prints on the screen the distance of the 
@ detected object. The measure is repeated 10 times.

@ Define my Raspberry Pi
        .cpu    cortex-a53
        .fpu    neon-fp-armv8
        .syntax unified         	@ modern syntax

@ Constants for assembler
        .equ    PERIPH,0x3f000000    @ RPi 3 peripherals
        .equ    GPIO_OFFSET,0x200000 @ start of GPIO device

@ The following are defined by us:
        .equ    INPUT,0         	@ use pin for input
        .equ    OUTPUT,1        	@ use pin for ouput
        .equ    PIN_ECHO,11		@ pin input(echo of the sensor)
	.equ    PIN_TRIG,26        	@ pin output (trigger) 
	.equ	SIXTY_MS, 60000		@ wait time between 2 measures
	.equ	W_SHIFT, 2		@ number of shifts to convert bytes to words
	
	.data
	.align 2
measures:
	.word	0,0,0,0,0,0,0,0
@ Constant program data
        .section .rodata
        .align  2
device:
        .asciz  "/dev/gpiomem"
devErr:
        .asciz  "Cannot open /dev/gpiomem\n"
memErr:
        .asciz  "Cannot map /dev/gpiomem\n"
distMessage:
		.asciz	"Object detected at %i cm \n"
@ The program
        .text
        .align  2
        .global main
        .global saveMeasures
        .type   main, %function
main:
		push	{r4, r5, r6, r7, r8, r9, r10, lr}

@ Open /dev/gpiomem for read/write and syncing        
        ldr     r0, deviceAddr  	@ address of /dev/gpiomem
        bl		openRWSync
        cmp     r0, -1          	@ check for error
        bne     memOK       		@ no error, continue
        ldr     r0, devErrAddr  	@ error, tell user
        bl      printf
        b       allDone         	@ and end program

memOK: 
		mov		r4, r0				@ use r4 for file descriptor

@ Map the GPIO registers to a main memory location so we can access them
		mov		r0, r4
		ldr		r1, gpio
		bl     	mapMemory
        cmp     r0, -1          	@ check for error
        bne     mmapOK          	@ no error, continue
        ldr     r0, memErrAddr 		@ error, tell user
        bl      printf	
		mov     r0, r4          	@ /dev/mem file descriptor
        bl      close           	@ close the file		
        b       allDone	        	@ and close /dev/mem
   
@ All OK set up timer and sensor
mmapOK:      
		mov     r5, r0          	@ use r5 for programming memory address		
@ Initialize timer
		bl		initTimer  

@ Select function for the ECHO pin (input)
        mov     r0, r5		    	@ GPIO programming memory
        mov     r1, PIN_ECHO    	@ echo pin
        mov     r2, INPUT 			@ it's an input
        bl      gpioPinFSelect  	@ select function

@ Select function for the TRIGGER pin (output)
        mov     r0, r5	        	@ GPIO programming memory
        mov     r1, PIN_TRIG    	@ trigger pin
        mov     r2, OUTPUT      	@ it's an output
        bl      gpioPinFSelect  	@ select function
		
	mov	r10, #8 		@ 8 measures
		
@ Trigger the sensor by setting the trigger pin to 1 for at least 10 us 
trigger:
        mov     r0, r5				@ GPIO programming memory
        mov     r1, PIN_TRIG		@ trigger pin
        bl      gpioPinSet			@ pull up the pin
		mov     r0, #10     		@ wait for 10 us
        bl      delay

		mov     r0, r5				@ GPIO programming memory
        mov     r1, PIN_TRIG		@ trigger pin 
        bl      gpioPinClr			@ pull down the pin

@ Keep reading the ECHO pin, till it is pulled up (the sensor starts sending ultrasound waves)
waitWave:
        mov 	r0, r5			 	@ GPIO programming memory
		mov 	r1, PIN_ECHO	 	@ pin to read
		bl 		gpioPinRead		 	@ read the level of the pin
		cmp		r0, #1
		bne		waitWave		 	@ if it's not 1 the wave has not been sent yet

@ Get the time when the wave is sent
		bl 		getTimestamp
		mov 	r6, r0				@ lower 32 bits of the timestamp
		mov		r7, r1				@ higher 32 bits of the timestamp

@ Keep reading the output pin, till it is pulled down (the sensor has received the echo)
waitEcho:
        mov 	r0, r5			 	@ GPIO programming memory
		mov 	r1, PIN_ECHO	 	@ pin to read
		bl 		gpioPinRead		 	@ read the level of the pin
		cmp		r0, #0
		bne		waitEcho		 	@ if it's not 0, the sensor has not received the echo yet

@ Get the time when the echo is received
		bl 		getTimestamp	
		mov 	r8, r0				@ lowest 32 bits of the timestamp
		mov		r9, r1				@ highest 32 bits of the timestamp

@ Calculate the time elapsed since the wave was sent and the echo received
		mov		r0, r6
		mov		r1, r7
		mov		r2, r8
		mov		r3, r9
		bl		getElapsedTime
		mov		r6, r0				@ elapsed time 

@ Retrieve the distance of the object. Since the sensor measures up to 4m 
@ distance, the maximum elapsed time will be 
@ (maxDistance*2)/soundSpeed = (4m * 2) /(340m/s)= 23530 us = 0x5bea us. 
@ Therefore the highest part of the elapsed time will always be 0.
		@mov		r0, r6			
		@bl		convToDistance
		@mov		r6, r0
		@ldr		r0, distMessageAddr @ message
		@mov		r1, r6				@ distance
		@bl		printf
		
		sub		r10, r10, #1
		ldr 		r1, measuresAddr
		str 		r6, [r1, r10, lsl #W_SHIFT]	@ save the measure
		
		mov		r0, #SIXTY_MS			@ wait for 60 ms
		bl		delay
		cmp 		r10, #0
		bne		trigger

@ Calculate the average measure and the corresponding distance
		ldr 		r0, measuresAddr
		bl 		computeAverage				
		bl 		convToDistance
		mov 		r6, r0
		ldr		r0, distMessageAddr @ message
		mov		r1, r6				@ distance
		bl		printf
		
@ Save measures into a file
		ldr 		r0, measuresAddr
		mov		r1, #8
		bl 		saveMeasures
		

@ Unmap and close the device
		mov 		r0, r5				@ memory to unmap
		mov		r1, r4				@ file descriptor (/dev/gpio)
		bl		closeDevice 

@ Unmap and close the timer
		bl 		closeTimer

allDone:        
        mov     r0, #0           	@ return 0
		pop		{r4, r5, r6, r7, r8, r9, r10, lr}
		bx		lr

@ computeAverage
@ Computes the average measure 
@ Calling sequence:
@		r0 <- address of the array of measures
@ 		bl computeAverage
@ Output:
@ 		r0 <- average measure
computeAverage:
		push 		{r4, r5, r6, r7}
		mov 		r5, r0			@ base address
		mov 		r4, #8			@ counter
		mov 		r0, #0			@ initialize output
		
addMeasure:	
		sub		r4, r4, #1
		ldr 		r6, [r5, r4, lsl #W_SHIFT]	@ load measure
		add 		r0, r0, r6, lsr #3	
		
		cmp 		r4, #0
		bne		addMeasure
				
		pop		{r4, r5, r6, r7}
		bx 		lr



@ convToDistance
@ Converts the amount of time elapsed between the trigger 
@ and the echo (us), to the distance of the obstacle (cm). 
@ Calling sequence:
@		r0 <- lower 4 bytes of the elapsed time
@		bl convToDistance
@ Output:
@		r0 <- distance	[cm]
@ distance [cm]= (sound_speed elapsed_time)/2 = 
@ = (340 *10^-4 [cm/us]) * (elapsed_time[us]) /2 =
@ = 170 * 10^-4 *elapsed_time [cm] = elapsed_time/58 [cm]
convToDistance:
		ldr		r1, =58
		udiv	r0, r0, r1
		bx lr
		

        .align  2

@ addresses of messages
deviceAddr:
        .word   device
gpio:
        .word   PERIPH+GPIO_OFFSET
devErrAddr:
        .word   devErr
memErrAddr:
        .word   memErr
timeAddr:
		.word time
distMessageAddr:
		.word distMessage
measuresAddr:
		.word measures
		

