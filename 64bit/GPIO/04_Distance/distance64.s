// distance64.s
// Activates a distance sensor that works with ultrasound waves. 
// The sensor has to be triggered at least 10 us, it will then start 
// sending ultrasound waves and pulls the echo pin up.
// As the sensor receives the echo it pulls the echo pin down.
// The programe ends when the echo is received, printing "Received echo"
// on the screen.

// Define my Raspberry Pi
        .cpu    cortex-a53 
		        
// Constants for assembler
        .equ    PERIPH,0x3f000000   			// RPi 2 & 3 peripherals
        .equ    GPIO_OFFSET,0x200000  			// start of GPIO device

// The following are defined in /usr/include/asm-generic/fcntl.h:
// Note that the values are specified in octal.
        .equ    O_RDWR,00000002   				// open for read/write
        .equ    O_DSYNC,00010000
        .equ    __O_SYNC,04000000
        .equ    O_SYNC,__O_SYNC|O_DSYNC

// The following are defined in /usr/include/asm-generic/mman-common.h:
        .equ    PROT_READ,0x1   				// page can be read
        .equ    PROT_WRITE,0x2  				// page can be written
        .equ    MAP_SHARED,0x01 				// share changes

// The following are defined by us:
        .equ    O_FLAGS,O_RDWR|O_SYNC 			// open file flags
        .equ    PROT_RDWR,PROT_READ|PROT_WRITE
        .equ    NO_PREF,0						
        .equ    PAGE_SIZE,4096  				// Raspbian memory page
        .equ    INPUT,0         				// use pin for input
        .equ    OUTPUT,1        				// use pin for ouput
        .equ    PIN_ECHO,11       				// echo pin 
		.equ	PIN_TRIG, 26					// trigger pin 

// Constant program data	   	
        .section .rodata
        .align  4				// $
device:
        .asciz  "/dev/mem"	   // $
devErr:
        .asciz  "Cannot open /dev/mem\n"	 //$
memErr:
        .asciz  "Cannot map /dev/mem\n"		 //$
wait:	
		.asciz  "Wait...\n"
received:
		.asciz  "Echo received\n"


// The program
        .text
        .align  4				// $
        .global main									  	   
main:													  
		stp x30, x29, [sp, #-16]!		// push {lr, fp} $			     
		stp x19, x20, [sp, #-16]!		// push {x19, x20} $  		

// Open /dev/mem for read/write and syncing        
        ldr     x0, deviceAddr  		// address of /dev/mem	 $
        ldr     x1, openMode    		// flags for accessing device
        bl      open
        cmp     x0, -1          		// check for error
        bne     gpiomemOK       		// no error, continue
        ldr     x0, devErrAddr  		// error, tell user	  
        bl      printf
        b       allDone         		// and end program
        
gpiomemOK:   
        mov     x19, x0          		// use x19 for file descriptor

// Map the gpio registers to a main menìmory location so we can access them
        mov     x0, NO_PREF     		// let kernel pick memory							   
        mov     x1, PAGE_SIZE   		// get 1 page of memory								   
        mov     x2, PROT_RDWR   		// read/write this memory							   
        mov     x3, MAP_SHARED  		// share with other processes						   
     	mov		x4, x19					// /dev/mem file descriptor		$
		ldr 	x5, gpio				// address of GPIO
		bl      mmap	
	   	cmp     x0, -1          		// check for error
        bne     mmapOK          		// no error, continue
        ldr     x0, memErrAddr 			// error, tell user
        bl      printf
        b       closeDev        		// and close /dev/mem

// All OK, set the sensor up
mmapOK:  
		mov     x20, x0          		// use x20 for programming memory address 

// Configure the pins   
       	mov     x0, x20          		// GPIO programming memory
        mov     x1, PIN_ECHO     		// echo pin
        mov     x2, INPUT      	 		// it's an input
        bl      gpioPinFSelect  		// select function

        mov     x0, x20          		// GPIO programming memory
        mov     x1, PIN_TRIG     		// trigger pin
        mov     x2, OUTPUT      		// it's an output
        bl      gpioPinFSelect   		// select function

// Trigger the sensor by setting thetrigger pin to 1 for at least 10 us
        mov     x0, x20			 		// GPIO programming memory
        mov     x1, PIN_TRIG	 		// trigger pin
        bl      gpioPinSet		 		// pull up the pin 
		mov     x0, #10     	 		// turn it on for 10 us
        bl      usleep

		mov     x0, x20          		// GPIO programming memory
        mov     x1, PIN_TRIG	 		// trigger pin
        bl      gpioPinClr		 		// pull down the pin

// Keep reading the echo pin, till it is pulled up (the sensor starts sendong ultrasound waves)
waitWave:
        mov 	x0, x20			 		// GPIO programming memory
		mov 	x1, PIN_ECHO	 		// pin to read
		bl 		gpioPinRead		 		// read the level of the pin
		cmp		x0, #1
		bne		waitWave 		 		// if it's not 1 the wave has not been sent yet  

// Keep reading the echo pin, till it is pulled down (the sensor has received the echo)
waitEcho:
		ldr 	x0, waitAddr	 		// waiting for the echo, tell the user
		bl		printf
		mov     x0, #50     	 		// wait for 50 us
        bl      usleep	
        mov 	x0, x20			 		// GPIO programming memory
		mov 	x1, PIN_ECHO	 		// pin to read
		bl 		gpioPinRead		 		// read the level of the pin
		cmp		x0, #0
		bne		waitEcho	     		// if it's not 0 the echo has not been received yet         

// Echo received, tell the user       
		ldr 	x0, receivedAddr
		bl 		printf
		
// Unmap the memory
        mov     x0, x20         		// memory to unmap
        mov     x1, PAGE_SIZE   		// amount we mapped
        bl      munmap          		// unmap it

closeDev:
        mov     x0, x19         		// /dev/mem file descriptor
        bl      close           		// close the file

allDone:        
        mov     x0, #0           		// return 0;
		ldp 	x19, x20, [sp], #16		// pop {x19, x20} $ 
		ldp 	x30, x29, [sp], #16		// pop {lr, fp}   $ 

        ret			            		// return
        
        .align  4
// addresses of messages
deviceAddr:
        .dword   device
openMode:
        .dword   O_FLAGS
gpio:
        .dword   PERIPH+GPIO_OFFSET
devErrAddr:
        .dword   devErr
memErrAddr:
        .dword   memErr
waitAddr:
		.dword   wait
receivedAddr:
		.dword	 received
						
