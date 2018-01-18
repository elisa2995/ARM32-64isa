// blinkLED.s
// Blinks LED connected between pins 1 and 11 on Raspberry Pi
// GPIO connector once a second for five seconds.
// 2017-09-30: Bob Plantz

// Define my Raspberry Pi
        .cpu    cortex-a53
        
// Constants for assembler
        .equ    PERIPH,0x3f000000   // RPi 2 & 3 peripherals
        .equ    GPIO_OFFSET,0x200000  // start of GPIO device
// The following are defined in /usr/include/asm-generic/fcntl.h:
// Note that the values are specified in octal.
        .equ    O_RDWR,00000002   // open for read/write
        .equ    O_DSYNC,00010000
        .equ    __O_SYNC,04000000
        .equ    O_SYNC,__O_SYNC|O_DSYNC
// The following are defined in /usr/include/asm-generic/mman-common.h:
        .equ    PROT_READ,0x1   // page can be read
        .equ    PROT_WRITE,0x2  // page can be written
        .equ    MAP_SHARED,0x01 // share changes
// The following are defined by me:
        .equ    O_FLAGS,O_RDWR|O_SYNC // open file flags
        .equ    PROT_RDWR,PROT_READ|PROT_WRITE
        .equ    NO_PREF,0
        .equ    PAGE_SIZE,4096  // Raspbian memory page
        .equ    INPUT,0         // use pin for input
        .equ    OUTPUT,1        // use pin for ouput
        .equ    ONE_SEC,1       // sleep one second
        .equ    PIN17,17        // pin set bit
        .equ    FILE_DESCRP_ARG,0   // file descriptor		  NOT USED we pass parameters with x0-x7
        .equ    DEVICE_ARG,0        // device address		  NOT USED
        .equ    STACK_ARGS,0    // includes sp 16-byte align (we don't use the stack to pass parameters) $	  NOT USED

// Constant program data	   	
        .section .rodata
        .align  4				// $
device:
        .asciz  "/dev/mem"	   // $
devErr:
        .asciz  "Cannot open /dev/mem\n"	 //$
memErr:
        .asciz  "Cannot map /dev/mem\n"		 //$

// The program
        .text
        .align  4				// $
        .global main									  	   
main:															  /*----STACK---*/ 																
																  /*			*/	  //<-sp1 
																  /*			*/						
		stp x30, x29, [sp, #-16]!	// push {lr, fp} $ 			  /*	x22		*/	   //<-sp0
																  /*	x21		*/	   
		stp x19, x20, [sp, #-16]!	// push {x19, x20} $  		  /*	x20		*/
																  /*	x19		*/
		stp x21, x22, [sp, #-16]!	// push {x21, x22} $		  /*	fp		*/
																  /*	lr		*/	   //<-fp
		add		x29, sp, 40
        sub     sp, sp, STACK_ARGS								  /*does nothing - for coherence with 32bits*/

// Open /dev/mem for read/write and syncing        
        ldr     x0, deviceAddr  // address of /dev/mem	 $
        ldr     x1, openMode    // flags for accessing device
        bl      open
        cmp     x0, -1          // check for error
        bne     gpiomemOK       // no error, continue
        ldr     x0, devErrAddr  // error, tell user

        bl      printf
        b       allDone         // and end program
        
gpiomemOK:   
        mov     x19, x0          // use x19 for file descriptor

        mov     x0, NO_PREF     // let kernel pick memory							   
        mov     x1, PAGE_SIZE   // get 1 page of memory								   
        mov     x2, PROT_RDWR   // read/write this memory							   
        mov     x3, MAP_SHARED  // share with other processes						   
     	mov		x4, x19			// /dev/mem file descriptor		$
		ldr 	x5, gpio		// address of GPIO
		bl      mmap	
	   	cmp     x0, -1          // check for error
        bne     mmapOK          // no error, continue
        ldr     x0, memErrAddr // error, tell user
        bl      printf
        b       closeDev        // and close /dev/mem
											
		
        				  
// All OK, blink the LED
mmapOK:         															         
        mov     x20, x0         // use x20 for programming memory address

        mov     x0, x20         // programming memory
        mov     x1, PIN17       // pin to blink
        mov     x2, INPUT       // it's an output
        bl      gpioPinFSelect  // select function

        mov     x21, #5         // blink five times
loop:
        mov 	x0, x20			 // programming memory
		mov 	x1, PIN17		 // pin to read
		bl 		gpioPinRead
        subs    x21, x21, #1     // decrement counter
        bgt     loop            // loop until 0

unmap:        
        mov     x0, x20         // memory to unmap
        mov     x1, PAGE_SIZE   // amount we mapped
        bl      munmap          // unmap it

closeDev:
        mov     x0, x19         // /dev/mem file descriptor
        bl      close           // close the file

allDone:        
        mov     x0, #0           // return 0;
        add     sp, sp, STACK_ARGS  // fix sp

		ldp 	x21, x22, [sp], #16		/*pop {x21,x22}  $ */
		ldp 	x19, x20, [sp], #16		/*pop {x19, x20} $ */
		ldp 	x30, x29, [sp], #16		/*pop {lr, fp}   $ */

        ret			            // return
        
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
