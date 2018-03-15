// gpioPinSet64.s
// Sets a GPIO pin. Assumes that GPIO registers
// have been mapped to programming memory.

// Define my Raspberry Pi
        .cpu    cortex-a53

// Constants for assembler
        .equ    PIN,1           		// 1 bit for pin
	.equ	DIV_32, 5			// number of shifts necessary to divide a number by 32			
	.equ	W_SHIFT,  2	 		// number of shifts to convert from bytes to word
        .equ    GPSET0,0x1c 			// set register offset

// The program
        .text
        .align  4				// $
        .global gpioPinSet

// gpioPinSet64
// Sets a GPIO pin
// Calling sequence:
//       x0 <- address of GPIO in mapped memory
//       x1 <- pin number
//       bl gpioPinSet
gpioPinSet:
	stp x30, x29, [sp, #-16]!	// push {lr, fp} $ 			  	   
	stp x19, x20, [sp, #-16]!	// push {x19, x20} $  		  

        add     x19, x0, GPSET0  // pointer to GPSET regs.
        mov     w20, w1          // save pin number
        
// Compute address of GPSET register and pin field  
	lsr	w15, w20, #DIV_32		// pinNumber/32 = GPSET number
	lsl	w16, w15, #DIV_32		// w16= GPSET number * 32  to compute the remainder
        sub     w16, w20, w16      		//     for relative pin position
        lsl     w15, w15, #W_SHIFT		// 8 bytes in a register, w15=offset
        add     x15, x15, x19      		// address of GPSETn, w15= base+offset

	ldrsw	x17, [x15]			// get entire 32 bit register

        mov     w18, PIN         		// one pin
        lsl     w18, w18, w16   		// shift to pin position
        orr     w17, w17, w18  		 	// clear bit
	str		w17, [x15]			 	// update register

        mov     x0, #0           		// return 0;

	ldp 	x19, x20, [sp], #16		//pop {x19, x20} $ 
	ldp 	x30, x29, [sp], #16		//pop {lr, fp}   $ 
        
	ret					// return
