@ display.s

@ Define my Raspberry Pi
        .cpu    cortex-a53
        .fpu    neon-fp-armv8
        .syntax unified         @ modern syntax

@ Constants for assembler
        .equ    PERIPH,0x3f000000   @ RPi 3 peripherals
        .equ    GPIO_OFFSET,0x200000  @ start of GPIO device
@ The following are defined by us:
        .equ    INPUT,0         	@ use pin for input
        .equ    OUTPUT,1        	@ use pin for ouput
        .equ    PIN_CLK,11		    @ clock pin
		.equ    PIN_DIO,26        	@ digital output pin

@ Constant program data
        .section .rodata
        .align  2
device:
        .asciz  "/dev/gpiomem"
devErr:
        .asciz  "Cannot open /dev/gpiomem\n"
memErr:
        .asciz  "Cannot map /dev/gpiomem\n"

@ The program
        .text
        .align  2
        .global main
        .type   main, %function
main:
		push	{r4, r5, r6, r7, r8, r9, r10, lr}

@ Open /dev/gpiomem for read/write and syncing        
        ldr     r0, deviceAddr  @ address of /dev/gpiomem
        bl		openRWSync
        cmp     r0, -1          @ check for error
        bne     memOK       	@ no error, continue
        ldr     r0, devErrAddr  @ error, tell user
        bl      printf
        b       allDone         @ and end program

@ Map the GPIO. 
memOK: 
		ldr		r1, gpio
		bl     	mapMemory
        cmp     r0, -1          @ check for error
        bne     mmapOK          @ no error, continue
        ldr     r0, memErrAddr 	@ error, tell user
        bl      printf	
		mov     r0, r4          @ /dev/mem file descriptor
        bl      close           @ close the file		
        b       allDone	        @ and close /dev/mem

        
@ All OK 
mmapOK:      
		mov     r5, r0          @ use r5 for programming memory address		
 

@ Select function for the ECHO pin (input)
        mov     r0, r5		    @ programming memory
        mov     r1, PIN_CLK	    @ clock pin
        mov     r2, OUTPUT 		@ it's an output
        bl      gpioPinFSelect  @ select function

@ Select function for the TRIGGER pin (output)
        mov     r0, r5	        @ programming memory
        mov     r1, PIN_DIO	    @ digital output pin
        mov     r2, OUTPUT      @ it's an output
        bl      gpioPinFSelect  @ select function

@ 
		
		mov 	r7, #7
		
loop: 
	
@ Set the DIO pin 
		mov     r0, r5
        mov     r1, PIN_DIO
        bl      gpioPinClr
//		mov     r0, #300     	@ wait 10 us
//        bl      usleep
@ Set the clock pin to 1 for at least 10 us
		mov     r0, r5
        mov     r1, PIN_CLK
        bl      gpioPinSet
		mov     r0, #10     	@ wait 10 us
        bl      usleep
@ Set the clock pin to 0
		mov     r0, r5
        mov     r1, PIN_CLK
        bl      gpioPinClr
		mov     r0, #10      	@ wait 10 us
        bl      usleep
		b 		loop
//		subs 	r7, r7, #1
//		bne		loop
		
		ldr     r0, =#1000000     	@ wait 1 s
        bl      usleep
//
//@ Trigger the sensor by setting its pin to 1 for at least 10 us 
//        mov     r0, r5
//        mov     r1, PIN_TRIG
//        bl      gpioPinSet
//		mov     r0, #10     	@ wait 10 us
//        bl      usleep
//
//		mov     r0, r5			@ GPIO programming memory
//        mov     r1, PIN_TRIG
//        bl      gpioPinClr		@ Turn the pin off
//
//@ Keep reading the output pin, till it turns to 1 (the sensor has sent the wave)
//waitWave:
//        mov 	r0, r5			 @ programming memory
//		mov 	r1, PIN_ECHO	 @ pin to read
//		bl 		gpioPinRead
//		cmp		r0, #1
//		bne		waitWave
//
//@ Get the time when the wave is sent
//		bl 		getTimestamp
//		mov 	r6, r0			@ lowest 32 bits of the timestamp
//		mov		r7, r1			@ highest 32 bits of the timestamp
//
//@ Keep reading the output pin, till it turns to 0 (the sensor receives the echo)
//waitEcho:
//        mov 	r0, r5			 @ programming memory
//		mov 	r1, PIN_ECHO	 @ pin to read
//		bl 		gpioPinRead
//		cmp		r0, #0
//		bne		waitEcho
//
//@ Get the time when the echo is received
//		bl 		getTimestamp	
//		mov 	r8, r0			@ lowest 32 bits of the timestamp
//		mov		r9, r1			@ highest 32 bits of the timestamp
//
//@ Calculate the elapsed time
//		mov		r0, r6
//		mov		r1, r7
//		mov		r2, r8
//		mov		r3, r9
//		bl		getElapsedTime
//		mov		r6, r0			@ elapsed time, since the sensor measures up to 
//br:
//@ Retrieve the distance of the object. Since the sensor measures up to 4m 
//@ distance, the maximum elapsed time will be 
//@ s*2/v = (4m * 2) /(340m/s)= 23530 us = 0x5bea us. 
//@ Therefore the highest part of the elapsed time will always be 0.
//		mov		r0, r6			
//		bl		convToDistance

@ Unmap and close the device
		mov 	r0, r5			@ memory to unmap
		mov		r1, r4			@ file descriptor (/dev/gpio)
		bl		closeDevice 

allDone:        
        mov     r0, 0           @ return 0
		pop		{r4, r5, r6, r7, r8, r9, r10, lr}
		bx		lr


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



