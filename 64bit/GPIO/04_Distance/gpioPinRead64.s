// gpioPinRead64.s
// Reads the level of a GPIO pin. Assumes that GPIO registers
// have been mapped to programming memory.

// Define my Raspberry Pi
        .cpu    cortex-a53

// Constants for assembler
        .equ    PIN,1           		// 1 bit for pin
		.equ	DIV_32, 5				// number of shifts necessary to divide a number by 32			
		.equ	W_SHIFT,  2		 		// number of shifts to convert from bytes to word
        .equ    GPLEV0,0x34 			// set register offset

// The program
        .text
        .align  4				// $
        .global gpioPinRead

// gpioPinRead
// Reads the level of a GPIO pin
// Calling sequence:
//       x0 <- address of GPIO in mapped memory
//       x1 <- pin number
//       bl gpioPinRead
gpioPinRead:
		stp x30, x29, [sp, #-16]!		// push {lr, fp} $ 			  
		stp x19, x20, [sp, #-16]!		// push {x19, x20} $  		  
        
        add     x19, x0, GPLEV0  		// pointer to GPSET regs.
        mov     w20, w1          		// save pin number
        
// Compute address of GPSET register and pin field 
		lsr		w15, w20, #DIV_32		// pinNumber/32 = GPLEV number
		lsl		w16, w15, #DIV_32		// w16= GPLEV number * 32  to compute the remainder
        sub     w16, w20, w16      		//     for relative pin position        
        lsl     w15, w15, #W_SHIFT		// 4 bytes in a register, w15=offset			
        add     x15, x15, x19      		// address of GPSETn, w15=base+offset

// Read the level of the pin
        ldrsw   x17, [x15]		       	// get entire 32 bit register
		lsr		w17, w17, w16			// move the pin of interest in the lowest bit of the register
		and 	w17, w17, #0x1			// keep only the bit of interest		
        
        mov     w0, w17          		// return if the pin is high/low;

		ldp 	x19, x20, [sp], #16		//pop {x19, x20} $ 
		ldp 	x30, x29, [sp], #16		//pop {lr, fp}   $ 
        
		ret								// return
