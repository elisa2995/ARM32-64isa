@ gpioPinRead32.s
@ Reads the level of a pin. Assumes that GPIO registers
@ have been mapped to programming memory.

@ Define my Raspberry Pi
        .cpu    cortex-a53
        .fpu    neon-fp-armv8
        .syntax unified         @ modern syntax

@ Constants for assembler
        .equ    PIN,1           @ 1 bit for pin
		.equ	DIV_32, 5		@ number of shifts necessary to divide a number by 32
		.equ	W_SHIFT, 2		@ number of shifts to convert from bytes to words
        .equ    GPLEV0,0x34     @ set register offset

@ The program
        .text
        .align  2
        .global gpioPinRead
        .type   gpioPinRead, %function

@ gpioPinRead
@ Reads the level of a pin.
@ Calling sequence:
@       r0 <- address of GPIO in mapped memory
@       r1 <- pin number
@       bl gpioPinRead
gpioPinRead:
		push	{r4, r5, r6, lr}
        add     r4, r0, GPLEV0  @ pointer to GPLEV regs.
        mov     r5, r1          @ save pin number
        
@ Compute address of GPLEV register and pin field        
		lsr		r0, r5, #DIV_32	@ pinNumber/32 = GPLEV number
		lsl		r1, r0, #DIV_32	@ r1 = GPLEV number * 32 to compute the remainder
        sub     r1, r5, r1      @     for relative pin position
        lsl     r0, r0, #W_SHIFT@ 4 bytes in a register			r0 = offset
        add     r0, r0, r4      @ address of GPLEVn				r0 = base + offset
        
@ Read the level of the pin
        ldr     r2, [r0]        @ get entire register
		lsr		r2, r2, r1		@ move the pin of interest in the lowest bit of the register
		and 	r2, r2, #0x1	@ keep only the bit of interest		
        
        mov     r0, r2          @ return if the pin is high/low;

		pop		{r4, r5, r6, lr}
        bx      lr              @ return
