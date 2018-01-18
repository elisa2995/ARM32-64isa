@ blinkLED.s
@ Blinks LED connected between pins 1 and 11 on Raspberry Pi
@ GPIO connector once a second for five seconds.
@ 2017-09-30: Bob Plantz

@ Define my Raspberry Pi
        .cpu    cortex-a53
        .fpu    neon-fp-armv8
        .syntax unified         @ modern syntax

@ Constants for assembler
        .equ    PERIPH,0x3f000000   @ RPi 2 & 3 peripherals
        .equ    GPIO_OFFSET,0x200000  @ start of GPIO device
@ The following are defined in /usr/include/asm-generic/fcntl.h:
@ Note that the values are specified in octal.
        .equ    O_RDWR,00000002   @ open for read/write
        .equ    O_DSYNC,00010000
        .equ    __O_SYNC,04000000
        .equ    O_SYNC,__O_SYNC|O_DSYNC
@ The following are defined in /usr/include/asm-generic/mman-common.h:
        .equ    PROT_READ,0x1   @ page can be read
        .equ    PROT_WRITE,0x2  @ page can be written
        .equ    MAP_SHARED,0x01 @ share changes
@ The following are defined by me:
        .equ    O_FLAGS,O_RDWR|O_SYNC @ open file flags
        .equ    PROT_RDWR,PROT_READ|PROT_WRITE
        .equ    NO_PREF,0
        .equ    PAGE_SIZE,4096  @ Raspbian memory page
        .equ    INPUT,0         @ use pin for input
        .equ    OUTPUT,1        @ use pin for ouput
        .equ    ONE_SEC,1       @ sleep one second
        .equ    PIN_IN,17        @ pin input
		.equ    PIN_OUT,26        @ pin output
        .equ    FILE_DESCRP_ARG,0   @ file descriptor
        .equ    DEVICE_ARG,4        @ device address
        .equ    STACK_ARGS,8    @ includes sp 8-byte align

@ Constant program data
        .section .rodata
        .align  2
device:
        .asciz  "/dev/gpiomem"
devErr:
        .asciz  "Cannot open /dev/gpiomem\n"
memErr:
        .asciz  "Cannot map /dev/gpiomem\n"

@ The program
        .text
        .align  2
		.global printMemory			@ $
		.global saveResult			@ $
        .global main
        .type   main, %function
main:
        sub     sp, sp, 24      @ space for saving regs
                                @ (keeping 8-byte sp align)
        str     r4, [sp, 4]     @ save r4
        str     r5, [sp, 8]     @      r5
        str     r6, [sp,12]     @      r6
        str     fp, [sp, 16]    @      fp
        str     lr, [sp, 20]    @      lr
        add     fp, sp, 20      @ set our frame pointer
        sub     sp, sp, STACK_ARGS

@ Open /dev/gpiomem for read/write and syncing        
        ldr     r0, deviceAddr  @ address of /dev/gpiomem
        ldr     r1, openMode    @ flags for accessing device
        bl      open
        cmp     r0, -1          @ check for error
        bne     gpiomemOK       @ no error, continue
        ldr     r0, devErrAddr  @ error, tell user
        bl      printf
        b       allDone         @ and end program
        
gpiomemOK:      
        mov     r4, r0          @ use r4 for file descriptor

@ Map the GPIO registers to a main memory location so we can access them
        str     r4, [sp, FILE_DESCRP_ARG] @ /dev/gpiomem file descriptor
        ldr     r0, gpio        @ address of GPIO
        str     r0, [sp, DEVICE_ARG]      @ location of GPIO
        mov     r0, NO_PREF     @ let kernel pick memory
        mov     r1, PAGE_SIZE   @ get 1 page of memory
        mov     r2, PROT_RDWR   @ read/write this memory
        mov     r3, MAP_SHARED  @ share with other processes
        bl      mmap
        cmp     r0, -1          @ check for error
        bne     mmapOK          @ no error, continue
        ldr     r0, memErrAddr @ error, tell user
        bl      printf
        b       closeDev        @ and close /dev/gpiomem
        
@ All OK, blink the LED
mmapOK:        
        mov     r5, r0          @ use r5 for programming memory address
        mov     r0, r5          @ programming memory
        mov     r1, PIN_IN       @ pin button
        mov     r2, INPUT      @ it's an input
        bl      gpioPinFSelect  @ select function

        mov     r0, r5          @ programming memory
        mov     r1, PIN_OUT       @ pin led
        mov     r2, OUTPUT      @ it's an output
        bl      gpioPinFSelect  @ select function
loop:
        mov 	r0, r5			 // programming memory
		mov 	r1, PIN_IN		 // pin to read
		bl 		gpioPinRead
		mov 	r6, r0
		mov     r0, #10000     // wait a second
        bl      usleep
		cmp 	r6, #0			 //	x0=1 if the button is pressed
		beq     loop            // loop until the button is pushed 

		mov     r0, r5          @ GPIO programming memory
        mov     r1, PIN_OUT
        bl      gpioPinClr

        mov     r0, ONE_SEC     @ wait a second
        bl      sleep
        mov     r0, r5
        mov     r1, PIN_OUT
        bl      gpioPinSet
                
        mov     r0, r5          @ memory to unmap
        mov     r1, PAGE_SIZE   @ amount we mapped
        bl      munmap          @ unmap it

closeDev:
        mov     r0, r4          @ /dev/gpiomem file descriptor
        bl      close           @ close the file

allDone:        
        mov     r0, 0           @ return 0;
        add     sp, sp, STACK_ARGS  @ fix sp
        ldr     r4, [sp, 4]     @ restore r4
        ldr     r5, [sp, 8]     @      r5
        ldr     r6, [sp,12]     @      r6
        ldr     fp, [sp, 16]    @      fp
        ldr     lr, [sp, 20]    @      lr
        add     sp, sp, 24      @      sp
        bx      lr              @ return
        
        .align  2
@ addresses of messages
deviceAddr:
        .word   device
openMode:
        .word   O_FLAGS
gpio:
        .word   PERIPH+GPIO_OFFSET
devErrAddr:
        .word   devErr
memErrAddr:
        .word   memErr


