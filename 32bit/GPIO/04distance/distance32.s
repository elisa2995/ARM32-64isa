@ distance32.s
@ Activates a disatance sensor that works with ultrasound waves.
@ The sensor has to be triggered for at least 10 us, it then
@ starts sending ultrasound waves, and pulls the echo pin up. 
@ As the sensor receives the echo, it pulls the echo pin down. 
@ The program ends when the echo is received, printing "Received 
@ echo" on the screen.
 
@ Define my Raspberry Pi
        .cpu    cortex-a53
        .fpu    neon-fp-armv8
        .syntax unified         			@ modern syntax

@ Constants for assembler
        .equ    PERIPH,0x3f000000   		@ RPi 2 & 3 peripherals
        .equ    GPIO_OFFSET,0x200000		@ start of GPIO device

@ The following are defined in /usr/include/asm-generic/fcntl.h:
@ Note that the values are specified in octal.
        .equ    O_RDWR,00000002   			@ open for read/write
        .equ    O_DSYNC,00010000
        .equ    __O_SYNC,04000000
        .equ    O_SYNC,__O_SYNC|O_DSYNC

@ The following are defined in /usr/include/asm-generic/mman-common.h:
        .equ    PROT_READ,0x1   			@ page can be read
        .equ    PROT_WRITE,0x2  			@ page can be written
        .equ    MAP_SHARED,0x01 			@ share changes

@ The following are defined by us:
        .equ    O_FLAGS,O_RDWR|O_SYNC 		@ open file flags
        .equ    PROT_RDWR,PROT_READ|PROT_WRITE
        .equ    NO_PREF,0
        .equ    PAGE_SIZE,4096  			@ Raspbian memory page
        .equ    INPUT,0         			@ use pin for input
        .equ    OUTPUT,1        			@ use pin for ouput
        .equ    PIN_ECHO,11        			@ echo pin
		.equ    PIN_TRIG,26        			@ trigger pin

@ Constant program data
        .section .rodata
        .align  2
device:
        .asciz  "/dev/gpiomem"
devErr:
        .asciz  "Cannot open /dev/gpiomem\n"
memErr:
        .asciz  "Cannot map /dev/gpiomem\n"
wait:	
		.asciz	"Wait...\n"
received:
		.asciz	"Echo received\n"

@ The program
        .text
        .align  2
        .global main
        .type   main, %function
main:
		push	{r4, r5, r6, lr}

@ Open /dev/gpiomem for read/write and syncing        
        ldr     r0, deviceAddr  			@ address of /dev/gpiomem
        ldr     r1, openMode    			@ flags for accessing device
        bl      open
        cmp     r0, -1          			@ check for error
        bne     gpiomemOK       			@ no error, continue
        ldr     r0, devErrAddr  			@ error, tell user
        bl      printf
        b       allDone         			@ and end program
        
gpiomemOK:
		mov     r4, r0          			@ use r4 for file descriptor

@ Map the GPIO registers to a main memory location so we can access them     
@ Push the 5th and 6th parameters of mmap into the stack
		ldr 	r5, gpio					@ address of GPIO
		push 	{r4, r5}

@ Save the other parameters into r0-r3
        mov     r0, NO_PREF     			@ let kernel pick memory
        mov     r1, PAGE_SIZE   			@ get 1 page of memory
        mov     r2, PROT_RDWR   			@ read/write this memory
        mov     r3, MAP_SHARED  			@ share with other processes
        bl      mmap
		pop		{r4, r5}
        cmp     r0, -1          			@ check for error
        bne     mmapOK          			@ no error, continue
        ldr     r0, memErrAddr 				@ error, tell user
        bl      printf
        b       closeDev        			@ and close /dev/gpiomem
        
@ All OK, set the sensor up
mmapOK:  
		mov     r5, r0          			@ use r5 for programming memory address
@ Configure the pins      
        mov     r0, r5          			@ GPIO programming memory
        mov     r1, PIN_ECHO       			@ echo pin
        mov     r2, INPUT      				@ it's an input
        bl      gpioPinFSelect  			@ select function

        mov     r0, r5          			@ programming memory
        mov     r1, PIN_TRIG       			@ trigger pin
        mov     r2, OUTPUT      			@ it's an output
        bl      gpioPinFSelect  			@ select function

@ Trigger the sensor by setting the trigger pin to 1 for at least 10 us 
        mov     r0, r5						@ GPIO programming memory
        mov     r1, PIN_TRIG				@ trigger pin
        bl      gpioPinSet					@ pull up the pin
		mov     r0, #10				     	@ turn it on for 10 us
        bl      usleep

		mov     r0, r5          			@ GPIO programming memory
        mov     r1, PIN_TRIG				@ trigger pin
        bl      gpioPinClr					@ pull down the pin

@ Keep reading the echo pin, till it is pulled up (the sensor starts sending ultrasound waves)
waitWave:
        mov 	r0, r5			 			@ GPIO programming memory
		mov 	r1, PIN_ECHO		 		@ pin to read
		bl 		gpioPinRead					@ read level of the pin
		cmp		r0, #1
		bne		waitWave					@ if it's not 1 the wave has not been sent yet

@ Keep reading the echo pin, til it is pulled down (the sensor has received the echo)
waitEcho:
		ldr		r0, waitAddr				@ waiting for the echo, tell the user
		bl		printf
		mov		r0, #50						@ wait for 50 us
		bl		usleep
		mov 	r0, r5			 			@ GPIO programming memory
		mov 	r1, PIN_ECHO		 		@ pin to read
		bl 		gpioPinRead					@ read level of the pin
		cmp		r0, #0
		bne		waitEcho					@ if it's not 0 the echo has not been received yet

@ Echo received, tell the user
		ldr		r0, receivedAddr
		bl		printf

@ Unmap the memory               
        mov     r0, r5          			@ memory to unmap
        mov     r1, PAGE_SIZE   			@ amount we mapped
        bl      munmap          			@ unmap it

closeDev:
        mov     r0, r4          			@ /dev/gpiomem file descriptor
        bl      close           			@ close the file

allDone:        
        mov     r0, 0           			@ return 0
		pop		{r4, r5, r6, lr}
        bx      lr              			@ return
        
        .align  2
@ addresses of messages
deviceAddr:
        .word   device
openMode:
        .word   O_FLAGS
gpio:
        .word   PERIPH+GPIO_OFFSET
devErrAddr:
        .word   devErr
memErrAddr:
        .word   memErr
waitAddr:
		.word	wait
receivedAddr:
		.word	received
