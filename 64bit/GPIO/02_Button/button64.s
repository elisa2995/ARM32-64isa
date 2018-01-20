// button64.s
// Decrememts a counter as a button connected to pin 17 is pressed-
// Prints the value of the counter on the screen til it reaches 0

// Define my Raspberry Pi
        .cpu    cortex-a53
        
// Constants for assembler
        .equ    PERIPH,0x3f000000   	// RPi 2 & 3 peripherals
        .equ    GPIO_OFFSET,0x200000  	// start of GPIO device
// The following are defined in /usr/include/asm-generic/fcntl.h:
// Note that the values are specified in octal.
        .equ    O_RDWR,00000002   		// open for read/write
        .equ    O_DSYNC,00010000
        .equ    __O_SYNC,04000000
        .equ    O_SYNC,__O_SYNC|O_DSYNC
// The following are defined in /usr/include/asm-generic/mman-common.h:
        .equ    PROT_READ,0x1   		// page can be read
        .equ    PROT_WRITE,0x2  		// page can be written
        .equ    MAP_SHARED,0x01 		// share changes
// The following are defined by me:
        .equ    O_FLAGS,O_RDWR|O_SYNC 	// open file flags
        .equ    PROT_RDWR,PROT_READ|PROT_WRITE
        .equ    NO_PREF,0
        .equ    PAGE_SIZE,4096  		// memory page
        .equ    INPUT,0         		// use pin for input
        .equ    OUTPUT,1        		// use pin for ouput
        .equ    PIN_BTN,17        		// button pin
		.equ	MAX, 2					// maximum value of the counter
		
// Constant program data	   	
        .section .rodata
        .align  4				// $
device:
        .asciz  "/dev/mem"	   // $
devErr:
        .asciz  "Cannot open /dev/mem\n"	 //$
memErr:
        .asciz  "Cannot map /dev/mem\n"		 //$
message:
		.asciz	"Counter: %i \n"

// The program
        .text
        .align  4				// $
        .global main									  	   
main:															  		
		stp x30, x29, [sp, #-16]!		// push {lr, fp} $ 			  	   
		stp x19, x20, [sp, #-16]!		// push {x19, x20} $  		  
		stp x21, x22, [sp, #-16]!		// push {x21, x22} $		 

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

        mov     x0, NO_PREF     		// let kernel pick memory							   
        mov     x1, PAGE_SIZE   		// get 1 page of memory								   
        mov     x2, PROT_RDWR   		// read/write this memory							   
        mov     x3, MAP_SHARED  		// share with other processes						   
     	mov		x4, x19					// /dev/mem file descriptor		$
		ldr 	x5, gpio				// address of GPIO
		bl      mmap	
	   	cmp     x0, -1         			// check for error
        bne     mmapOK          		// no error, continue
        ldr     x0, memErrAddr 			// error, tell user
        bl      printf
        b       closeDev        		// and close /dev/mem
											
		
        				  
// All OK, configure button pin
mmapOK:         															         
        mov     x20, x0       	 	 	// use x20 for programming memory address

        mov     x0, x20         		// programming memory
        mov     x1, #PIN_BTN       		// button pin
        mov     x2, INPUT      		 	// it's an output
        bl      gpioPinFSelect  		// select function

        mov     x21, #MAX         		// maximum value of the counter
countLoop:
readAgain:
		ldr		x0, =100000				// wait 0.1 s
		bl 		usleep
        mov 	x0, x20			 		// programming memory
		mov 	x1, #PIN_BTN		 	// pin to read
		bl 		gpioPinRead
		cmp		x0, #1					// x0=1 if the button is pressed
		bne		readAgain				

// Print the value of the counter
		ldr 	x0, messageAddr
		mov		x1, x21
		sub		x1, x1, #1
		bl 		printf		
				
        subs    x21, x21, #1     		// decrement counter
        bgt     countLoop            	// loop until 0

unmap:        
        mov     x0, x20         		// memory to unmap
        mov     x1, #PAGE_SIZE   		// amountwe mapped
        bl      munmap          		// unmap it

closeDev:
        mov     x0, x19         		// /dev/mem file descriptor
        bl      close           		// close the file

allDone:        
        mov     x0, #0           		// return 0;
        
		ldp 	x21, x22, [sp], #16		// pop {x21,x22}  $ 
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
messageAddr:
		.dword   message
