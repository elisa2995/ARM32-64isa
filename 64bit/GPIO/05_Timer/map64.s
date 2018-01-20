// map64.s
// Implements functionalities to work with the virtual memory

// Define my Raspberry Pi
        .cpu    cortex-a53	

// The following are defined in /usr/include/asm-generic/fcntl.h:
// Note that the values are specified in octal.
        .equ    O_RDWR,00000002   		// open for read/write
        .equ    O_DSYNC,00010000
        .equ    __O_SYNC,04000000
        .equ    O_SYNC,__O_SYNC|O_DSYNC
// The following are defined in /usr/include/asm-generic/mman-common.h:
        .equ    PROT_READ,0x1   		// page can be read
        .equ    PROT_WRITE,0x2  		// page can be written
        .equ    MAP_SHARED,0x01 		// share changes
// Defined by us:
		.equ    O_FLAGS,O_RDWR|O_SYNC 	// open file flags : read and write and sync
        .equ    PROT_RDWR,PROT_READ|PROT_WRITE
        .equ    NO_PREF,0
        .equ    PAGE_SIZE,4096  		//  memory page

// The program
		.text
		.align  4
	   	.global openRWSync
	   	.global mapMemory
		.global	closeDevice

// openRWSync
// Opens the device in read and write mode + synchronize and 
// returns the file descriptor.
// Calling sequence:
//		x0 <- device address
//		bl openRWSync
// Output:
//		x0 <- file descriptor, or -1 if an error occurred
openRWSync:
		stp 	x19, x30, [sp, #-16]!	// push {x19,lr} $

// Open the device for read/write and syncing        
        ldr     x1, openMode    		// flags for accessing device
        bl      open

		ldp 	x19, x30, [sp], #16		// pop {x19, lr} $
		ret								// return

// mapMemory
// Maps the memory.
// Calling sequence:
//		x0<- file descriptor
//		x1<- pointer to address of the programming memory
// 		bl mapMemory
// Output:
//		x0<- the mapped address or -1 if an error occurred
mapMemory:
		stp x29, x30, [sp, #-16]!		// push {x29,lr} $

		mov     x4, x0          		// file descriptor
		mov 	x5, x1					// programming memory 

// Map the registers to a main memory location so we can access them
	
        mov     x0, NO_PREF     		// let kernel pick memory
        mov     x1, PAGE_SIZE   		// get 1 page of memory
        mov     x2, PROT_RDWR   		// read/write this memory
        mov     x3, MAP_SHARED  		// share with other processes
        bl      mmap

		ldp 	x29, x30, [sp], #16		// pop {x29, lr} $
		ret


// closeDevice 
// Unmaps the memory allocated to the device and closes it
// Calling sequence:
//		x0<-address of the mapped memory
//		x1<-file descriptor
//		bl closeDevice
closeDevice:
		stp 	x19, x30, [sp, #-16]!	// push {x19,lr} $
		mov		x19, x1					// file descriptor

        mov     x1, PAGE_SIZE   		// amount we mapped
        bl      munmap          		// unmap it

        mov     x0, x19          		// file descriptor
        bl      close           		// close the file   
		ldp 	x19, x30, [sp], #16		// pop {x19, lr} $
		ret
             
openMode:
        .word   O_FLAGS
