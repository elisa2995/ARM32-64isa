@ gpioPinClr32.s
@ Clears a GPIO pin.Assumes that GPIO registers
@ have been mapped to programming memory.

@ Define my Raspberry Pi
        .cpu    cortex-a53
        .fpu    neon-fp-armv8
        .syntax unified         @ modern syntax

@ Constants for assembler
        .equ    PIN,1           @ 1 bit for pin
		.equ	DIV_32, 5		@ number of shifts necessary to divide a number by 32
		.equ	W_SHIFT, 2		@ number of shifts to convert from bytes to words
        .equ    GPCLR0,0x28     @ clear register offset

@ The program
        .text
        .align  2
        .global gpioPinClr

@ gpioPinClr
@ Clears a pin.
@ Calling sequence:
@       r0 <- address of GPIO in mapped memory
@       r1 <- pin number
@       bl gpioPinClr
gpioPinClr:
		push	{r4, r5, r6, lr}
        add     r4, r0, #GPCLR0 @ pointer to GPSET regs.
        mov     r5, r1          @ save pin number
        
@ Compute address of GPSET register and pin field  
		lsr		r0, r5, #DIV_32	@ pinNumber/32 = GPCLR number
        lsl		r1, r0, #DIV_32	@ r1 = GPSET number * 32 to compute the remainder
		sub     r1, r5, r1      @ 	for relative pin position
        lsl     r0, r0, #W_SHIFT@ 4 bytes in a register		  r0 = offset
        add     r0, r0, r4      @ address of GPCLRn			  r0 = base + offset
        
@ Set up the GPIO pin funtion register in programming memory
        ldr     r2, [r0]        @ get entire register
        mov     r3, PIN         @ one pin
        lsl     r3, r3, r1      @ shift to pin position
        orr     r2, r2, r3      @ clear bit
        str     r2, [r0]        @ update register
        
        mov     r0, 0           @ return 0
		pop		{r4, r5, r6, lr}
        bx      lr              @ return
