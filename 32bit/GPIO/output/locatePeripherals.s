@ locatePeripherals.s
@ Determines the beginning address of peripherals.
@ Link with /opt/vc/lib/libbcm_host.so
@ 2017-09-29: Bob Plantz

@ Define my Raspberry Pi
        .cpu    cortex-a53
        .fpu    neon-fp-armv8
        .syntax unified         @ modern syntax

@ Constant program data
        .section  .rodata
        .align  2
formatMsg:
        .asciz	 "Peripheral addresses begin at %p\n"

@ Program code
        .text
        .align  2
        .global main
main:
        sub     sp, sp, 8       @ space for fp, lr
        str     fp, [sp, 0]     @ save fp
        str     lr, [sp, 4]     @   and lr
        add     fp, sp, 4       @ set our frame pointer
        
        bl      bcm_host_get_peripheral_address @ get the address
        mov     r1, r0          @ argument for printf
        ldr     r0, formatMsgAddr  @ printf("%i + %i = %i\n",
        bl      printf

        mov     r0, 0           @ return 0;
        ldr     fp, [sp, 0]     @ restore caller fp
        ldr     lr, [sp, 4]     @       lr
        add     sp, sp, 8       @   and sp
        bx      lr              @ return

        .align  2
formatMsgAddr:
        .word   formatMsg