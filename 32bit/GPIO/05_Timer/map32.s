@ map32.s
@ Implements functionalities to work with the virtual memory

@ Define my Raspberry Pi
        .cpu    cortex-a53
        .fpu    neon-fp-armv8
        .syntax unified         		@ modern syntax

@ The following are defined in /usr/include/asm-generic/fcntl.h:
@ Note that the values are specified in octal.
        .equ    O_RDWR,00000002   		@ open for read/write
        .equ    O_DSYNC,00010000
        .equ    __O_SYNC,04000000
        .equ    O_SYNC,__O_SYNC|O_DSYNC
@ The following are defined in /usr/include/asm-generic/mman-common.h:
        .equ    PROT_READ,0x1   		@ page can be read
        .equ    PROT_WRITE,0x2  		@ page can be written
        .equ    MAP_SHARED,0x01 		@ share changes
@ Defined by us:
		.equ    O_FLAGS,O_RDWR|O_SYNC 	@ open file flags : read and write and sync
        .equ    PROT_RDWR,PROT_READ|PROT_WRITE
        .equ    NO_PREF,0
        .equ    PAGE_SIZE,4096  		@ Raspbian memory page

@ The program
		.text
	   	.global openRWSync
	   	.global mapMemory
		.global	closeDevice

@ openRWSync
@ Opens the device in read and write mode + synchronize and 
@ returns the file descriptor.
@ Calling sequence:
@		r0 <- device address
@		bl openRWSync
@ Output:
@		r0 <- file descriptor, or -1 if an error occurred
openRWSync:
		push	{r4, lr}

@ Open the device for read/write and syncing        
        ldr     r1, openMode    @ flags for accessing device
        bl      open

		pop		{r4, lr}
		bx lr

@ mapMemory
@ Maps the memory.
@ Calling sequence:
@		r0<- file descriptor
@		r1<- pointer to the address of the programming memory
@		bl mapMemory
@ Output:
@		r0<- the mapped address or -1 if an error occurred
mapMemory:
		push	{r4, r5, r6, lr}

		mov     r4, r0          @ use r4 for file descriptor
		mov 	r5, r1			@ programming memory 

@ Map the registers to a main memory location so we can access them
		push 	{r4, r5}
        mov     r0, NO_PREF     @ let kernel pick memory
        mov     r1, PAGE_SIZE   @ get 1 page of memory
        mov     r2, PROT_RDWR   @ read/write this memory
        mov     r3, MAP_SHARED  @ share with other processes
        bl      mmap
		pop		{r4, r5}

		pop		{r4, r5, r6, lr}
		bx lr

@ closeDevice
@ Unmaps the memory allocated to the device and closes it
@ Calling sequence:
@		r0<-address of the mapped memory
@		r1<-file descriptor
@		bl closeDevice
closeDevice:
		push	{r4, lr}
		mov		r4, r1			@ file descriptor
        mov     r1, PAGE_SIZE   @ amount we mapped
        bl      munmap          @ unmap it

        mov     r0, r4          @ file descriptor
        bl      close           @ close the file   

		pop		{r4, lr}
		bx		lr
             
openMode:
        .word   O_FLAGS
