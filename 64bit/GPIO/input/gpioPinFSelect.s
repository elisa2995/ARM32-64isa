// gpioPinFSelect.s
// Selects a function for a GPIO pin. Assumes that GPIO registers
// have been mapped to programming memory.
// Calling sequence:
//       x0 <- address of GPIO in mapped memory
//       x1 <- pin number
//       x2 <- pin function
//       bl gpioPinFSelect
// 2017-09-30: Bob Plantz

// Define my Raspberry Pi
        .cpu    cortex-a53

// Constants for assembler
        .equ    PIN_FIELD,0b111 		// 3 bits
		.equ	DW_SHIFT, 3
// The program
        .text
        .align  4						// $c		
        .global gpioPinFSelect
        .type   gpioPinFSelect, %function
gpioPinFSelect:
		stp x30, x29, [sp, #-16]!		// push {lr, fp} $ 			  /*	x22		*/	   //<-sp
																	  /*	x21		*/	   
		stp x19, x20, [sp, #-16]!		// push {x19, x20} $  		  /*	x20		*/
																	  /*	x19		*/
		stp x21, x22, [sp, #-16]!		// push {x21, x22} $		  /*	fp		*/
																	  /*	lr		*/	   //<-fp
		add		x29, sp, 40     		// set our frame pointer
        
        mov     x19, x0          		// save pointer to GPIO
        mov     w20, w1          		// save pin number
        mov     w21, w2          		// save function code
        
// Compute address of GPFSEL register and pin field        
        mov     w18, #10          		// divisor
        udiv    w15, w20, w18      		// GPFSEL number
        
        mul     w16, w15, w18      		// compute remainder
        sub     w16, w20, w16      		//     for GPFSEL pin	  

// Set up the GPIO pin funtion register in programming memory

        lsl     w15, w15, #2		     // 8 bytes in a register  $c
        add     x15, x19, x15      		// GPFSELn address
		ldrsw	x17, [x15]				// get entire 32 bit register
        
        mov     w18, w16          		// need to multiply pin
        add     w16, w16, w18, lsl #1	//    position by 3
        mov     w18, PIN_FIELD   		// gpio pin field

        lsl     w18, w18, w16      		// shift to pin position
        bic     w17, w17, w18      		// clear pin 
        lsl     w21, w21, w16      		// shift function code to pin position
        orr     w17, w17, w21      		// enter function 
		str		w17, [x15]				// update register

        mov     x0, #0           		// return 0;
		ldp 	x21, x22, [sp], #16		/*pop {x21,x22}  $ */
		ldp 	x19, x20, [sp], #16		/*pop {x19, x20} $ */
		ldp 	x30, x29, [sp], #16		/*pop {lr, fp}   $ */
        
		ret              				// return
		