// gpioPinSet.s
// Sets a GPIO pin. Assumes that GPIO registers
// have been mapped to programming memory.
// Calling sequence:
//       x0 <- address of GPIO in mapped memory
//       x1 <- pin number
//       bl gpioPinSet
// 2017-09-30: Bob Plantz

// Define my Raspberry Pi
        .cpu    cortex-a53

// Constants for assembler
        .equ    PIN,1           // 1 bit for pin
        .equ    PINS_IN_REG,32	// $c
        .equ    GPLEV0,0x34 	//-4	// set register offset

// The program
        .text
        .align  4				// $
        .global gpioPinRead
        .type   gpioPinRead, %function
gpioPinRead:
		stp x30, x29, [sp, #-16]!	// push {lr, fp} $ 			  /*	x20		*/	// <-sp
																  /*	x19		*/	   
		stp x19, x20, [sp, #-16]!	// push {x19, x20} $  		  /*	fp		*/
																  /*	lr		*/	//<-fp
        add     x29, sp, #24      // set our frame pointer
        
        add     x19, x0, GPLEV0  // pointer to GPSET regs.
        mov     w20, w1          // save pin number
        
// Compute address of GPSET register and pin field        
        mov     w18, PINS_IN_REG   		// divisor
        udiv    w15, w20, w18      		// GPLEV number
        mul     w16, w15, w18      		// compute remainder
        sub     w16, w20, w16      		//     for relative pin position  
        lsl     w15, w15, #2			// 4 bytes in a register			$
        add     x15, x15, x19      		// address of GPSETn

// Read the level of the pin
        ldrsw   x17, [x15]		       	// get entire register
		lsr		w17, w17, w16			// move the pin of interest in the lowest bit of the register
		and 	w17, w17, 0x1			// keep only the bit of interest		
        
        mov     w0, w17          		// return if the pin is high/low;

		ldp 	x19, x20, [sp], #16		/*pop {x19, x20} $ */
		ldp 	x30, x29, [sp], #16		/*pop {lr, fp}   $ */
        
		ret								// return
