@ gpioPinFSelect32.s
@ Selects a function for a GPIO pin. Assumes that 
@ GPIO registers have been mapped to programming memory.

@ Define my Raspberry Pi
        .cpu    cortex-a53
        .fpu    neon-fp-armv8
        .syntax unified         @ modern syntax

@ Constants for assembler
		.equ	PINS_IN_REG, 10 @ each GPFSEL register configures the function of 10 pins (3 bits per pin)
		.equ    PIN_FIELD,0b111 @ 3 bits
		.equ	W_SHIFT, 2		@ number of shifts to convert from bytes to words

@ The program
        .text
        .align  2
        .global gpioPinFSelect

@ gpioPinFselect
@ Selects a function for a GPIO pin.
@ Calling sequence:
@       r0 <- address of GPIO in mapped memory
@       r1 <- pin number
@       r2 <- pin function
@       bl gpioPinFSelect
gpioPinFSelect:
		push	{r4, r5, r6, lr}
        
        mov     r4, r0          	@ save pointer to GPIO
        mov     r5, r1          	@ save pin number
        mov     r6, r2          	@ save function code
        
@ Compute address of GPFSEL register and pin field        
        mov     r3, #10         	@ divisor
        udiv    r0, r5, r3      	@ GPFSEL number
        
        mul     r1, r0, r3      	@ compute remainder
        sub     r1, r5, r1      	@     for GPFSEL pin  
        
@ Set up the GPIO pin funtion register in programming memory
        lsl     r0, r0, #W_SHIFT	@ 4 bytes in a register, r0 = offset	 
        add     r0, r4, r0      	@ GPFSELn address		 r0 = base + offset
        ldr     r2, [r0]        	@ get entire register
        
        mov     r3, r1          	@ need to multiply pin
        add     r1, r1, r3, lsl 1   @    position by 3
        mov     r3, PIN_FIELD   	@ gpio pin field (0b111)
        lsl     r3, r3, r1      	@ shift to pin position
        bic     r2, r2, r3      	@ clears the 3 bits related to the pin of interest

        lsl     r6, r6, r1      	@ shift function code to pin position	 
        orr     r2, r2, r6      	@ enter function code		
        str     r2, [r0]        	@ update register
        
        mov     r0, 0           	@ return 0
		pop		{r4, r5, r6, lr}
        bx      lr              	@ return
