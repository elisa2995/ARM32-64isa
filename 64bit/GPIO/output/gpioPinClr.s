/// gpioPinClr.s
// Clears a GPIO pin. Assumes that GPIO registers
// have been mapped to programming memory.
// Calling sequence:
//       x0 <- address of GPIO in mapped memory
//       x1 <- pin number
//       bl gpioPinClr
// 2017-09-30: Bob Plantz

// Define my Raspberry Pi
        .cpu    cortex-a53

// Constants for assembler
        .equ    PIN, 1           // 1 bit for pin
        .equ    PINS_IN_REG, 32	 // $
        .equ    GPCLR0, 0x28   		// clear register offset
		.equ	DW_SHIFT,  3	 //	number of shift to convert from bytes to dwords

// The program
        .text
        .align  4
        .global gpioPinClr
        .type   gpioPinClr, %function
							 
gpioPinClr:

		stp x30, x29, [sp, #-16]!	// push {lr, fp} $ 			  /*	x20		*/	// <-sp
																  /*	x19		*/	   
		stp x19, x20, [sp, #-16]!	// push {x19, x20} $  		  /*	fp		*/
																  /*	lr		*/	//<-fp
        add     x29, sp, #24      // set our frame pointer
        
        add     x19, x0, GPCLR0  // pointer to GPSET regs.
        mov     w20, w1          // save pin number
        
// Compute address of GPSET register and pin field        
        mov     w18, PINS_IN_REG   		// divisor
        udiv    w15, w20, w18      		// GPSET number
        mul     w16, w15, w18      		// compute remainder
        sub     w16, w20, w16      		//     for relative pin position
        lsl     w15, w15, #2			// 8 bytes in a register			$
        add     x15, x15, x19      		// address of GPSETn
        
// Set up the GPIO pin funtion register in programming memory

		ldrsw	x17, [x15] 				// get entire 32 bit register
        mov     w18, PIN         		// one pin
        lsl     w18, w18, w16   		// shift to pin position
        orr     w17, w17, w18  		 	// clear bit
		str		w17, [x15]				 // update register
        
        mov     x0, #0           		// return 0;

		ldp 	x19, x20, [sp], #16		/*pop {x19, x20} $ */
		ldp 	x30, x29, [sp], #16		/*pop {lr, fp}   $ */

        ret								// return
