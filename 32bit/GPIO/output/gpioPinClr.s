@ gpioPinClr.s
@ Clears a GPIO pin. Assumes that GPIO registers
@ have been mapped to programming memory.
@ Calling sequence:
@       r0 <- address of GPIO in mapped memory
@       r1 <- pin number
@       bl gpioPinClr
@ 2017-09-30: Bob Plantz

@ Define my Raspberry Pi
        .cpu    cortex-a53
        .fpu    neon-fp-armv8
        .syntax unified         @ modern syntax

@ Constants for assembler
        .equ    PIN,1           @ 1 bit for pin
        .equ    PINS_IN_REG,32
        .equ    GPCLR0,0x28     @ clear register offset

@ The program
        .text
        .align  2
        .global gpioPinClr
        .type   gpioPinClr, %function
gpioPinClr:
        sub     sp, sp, 16      @ space for saving regs
        str     r4, [sp, 0]     @ save r4
        str     r5, [sp, 4]     @      r5
        str     fp, [sp, 8]     @      fp
        str     lr, [sp, 12]    @      lr
        add     fp, sp, 12      @ set our frame pointer
        
        add     r4, r0, GPCLR0  @ pointer to GPSET regs.
        mov     r5, r1          @ save pin number
        
@ Compute address of GPSET register and pin field        
        mov     r3, PINS_IN_REG @ divisor
        udiv    r0, r5, r3      @ GPSET number
        mul     r1, r0, r3      @ compute remainder
        sub     r1, r5, r1      @     for relative pin position
        lsl     r0, r0, 2       @ 4 bytes in a register
        add     r0, r0, r4      @ address of GPSETn
        
@ Set up the GPIO pin funtion register in programming memory
        ldr     r2, [r0]        @ get entire register
        mov     r3, PIN         @ one pin
        lsl     r3, r3, r1      @ shift to pin position
        orr     r2, r2, r3      @ clear bit
        str     r2, [r0]        @ update register
        
        mov     r0, 0           @ return 0;
        ldr     r4, [sp, 0]     @ restore r4
        ldr     r5, [sp, 4]     @      r5
        ldr     fp, [sp, 8]     @         fp
        ldr     lr, [sp, 12]    @         lr
        add     sp, sp, 16      @ restore sp
        bx      lr              @ return