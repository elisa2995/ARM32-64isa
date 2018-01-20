// gpioPinFSelect64.s
// Selects a function for a GPIO pin. Assumes that GPIO registers
// have been mapped to programming memory.

// Define my Raspberry Pi
        .cpu    cortex-a53

// Constants for assembler
        .equ	PINS_IN_REG, 10			// each GPFSEL register confires the functions of 10 pins(3 bits per field)
		.equ    PIN_FIELD, 0b111 		// 3 bits 		
		.equ	W_SHIFT, 2				// number of shifts to convert from bytes to word
// The program
        .text
        .align  4						// $c		
        .global gpioPinFSelect

// gpioPinFSelect
// Selects a function for a GPIO pin
// Calling sequence:
//       x0 <- address of GPIO in mapped memory
//       x1 <- pin number
//       x2 <- pin function
//       bl gpioPinFSelect
gpioPinFSelect:
		stp x30, x29, [sp, #-16]!		// push {lr, fp} $ 			  	   
		stp x19, x20, [sp, #-16]!		// push {x19, x20} $  		 
		stp x21, x22, [sp, #-16]!		// push {x21, x22} $	
        
        mov     x19, x0          		// save pointer to GPIO
        mov     w20, w1          		// save pin number
        mov     w21, w2          		// save function code
        
// Compute address of GPFSEL register and pin field        
        mov     w18, #PINS_IN_REG  		// divisor
        udiv    w15, w20, w18      		// GPFSEL number
        
        mul     w16, w15, w18      		// compute remainder
        sub     w16, w20, w16      		//     for GPFSEL pin	  

// Set up the GPIO pin funtion register in programming memory

        lsl     w15, w15, #W_SHIFT	    // 4 bytes in a register , x15=offset 
        add     x15, x19, x15      		// GPFSELn address , x15=base+offset
		ldrsw	x17, [x15]				// get entire 32 bit register
        
        mov     w18, w16          		// need to multiply pin
        add     w16, w16, w18, lsl #1	//    position by 3
        mov     w18, PIN_FIELD   		// gpio pin field (0b111)

        lsl     w18, w18, w16      		// shift to pin position
        bic     w17, w17, w18      		// clears the 3 bits related to the pin of interest 

        lsl     w21, w21, w16      		// shift function code to pin position
        orr     w17, w17, w21      		// enter function code
		str		w17, [x15]				// update register

        mov     x0, #0           		// return 0;
		ldp 	x21, x22, [sp], #16		//pop {x21,x22}  $ 
		ldp 	x19, x20, [sp], #16		//pop {x19, x20} $ 
		ldp 	x30, x29, [sp], #16		//pop {lr, fp}   $ 
        
		ret              				// return
		