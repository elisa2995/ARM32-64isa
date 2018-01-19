@ gpioPinSet.s
@ Sets a GPIO pin. Assumes that GPIO registers
@ have been mapped to programming memory.
@ Calling sequence:
@       r0 <- address of GPIO in mapped memory
@       r1 <- pin number
@       bl gpioPinSet
@ 2017-09-30: Bob Plantz

@ Define my Raspberry Pi
        .cpu    cortex-a53
        .fpu    neon-fp-armv8
        .syntax unified         @ modern syntax

@ Constants for assembler
        .equ    PIN,1           @ 1 bit for pin
        .equ    PINS_IN_REG,32
        .equ    GPLEV0,0x34     @ set register offset

@ The program
        .text
        .align  2
        .global gpioPinRead
        .type   gpioPinRead, %function
gpioPinRead:
		push	{r4, r5, r6, lr}
//        sub     sp, sp, 16      @ space for saving regs
//        str     r4, [sp, 0]     @ save r4
//        str     r5, [sp, 4]     @      r5
//        str     fp, [sp, 8]     @      fp
//        str     lr, [sp, 12]    @      lr
//        add     fp, sp, 12      @ set our frame pointer
        
        add     r4, r0, GPLEV0  @ pointer to GPLEV regs.
        mov     r5, r1          @ save pin number
        
@ Compute address of GPLEV register and pin field        
        mov     r3, PINS_IN_REG @ divisor
        udiv    r0, r5, r3      @ GPSET number
        mul     r1, r0, r3      @ compute remainder
        sub     r1, r5, r1      @     for relative pin position
        lsl     r0, r0, 2       @ 4 bytes in a register
        add     r0, r0, r4      @ address of GPLEVn
        
@ Read the level of the pin
        ldr     r2, [r0]        @ get entire register
		lsr		r2, r2, r1		@ move the pin of interest in the lowest bit of the register
		and 	r2, r2, 0x1		@ keep only the bit of interest		
        
        mov     r0, r2          @ return if the pin is high/low;

//        ldr     r4, [sp, 0]     @ restore r4
//        ldr     r5, [sp, 4]     @      r5
//        ldr     fp, [sp, 8]     @         fp
//        ldr     lr, [sp, 12]    @         lr
//        add     sp, sp, 16      @ restore sp
		pop		{r4, r5, r6, lr}
        bx      lr              @ return