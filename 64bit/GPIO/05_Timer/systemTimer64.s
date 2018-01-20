// systemTimer64.s
// Implements functionalities to handle the system
// timer of the Raspberry

// Define my Raspberry Pi
        .cpu    cortex-a53

// Constants for assembler
        .equ    PERIPH,0x3f000000   	// RPi 2 & 3 peripherals
        .equ    TIMER_OFFSET,0x3000     // system timer offset
		.equ 	CLO_OFFSET, 4			// system timer counter lower 32 bits offset from beginning of timer regs
		.equ 	CHI_OFFSET, 8			// system timer counter higher 32 bits offset from beginning of timer regs

// Defined by us:
		.equ    PAGE_SIZE,4096  		//  memory page

// Program variables
		.data
fileDesc:
		.dword	0
progMem:
		.dword	0	

// The program
        .text
        .align  4
        .global getTimestamp
		.global getElapsedTime
		.global delay
		.global initTimer
		.global closeTimer

// Constant program data
        .section .rodata
        .align  4
device:
        .asciz  "/dev/mem"
devErr:
        .asciz  "Cannot open /dev/mem\n"
memErr:
        .asciz  "Cannot map /dev/mem\n"

// initTimer
// Maps the timer registers to a main memory location so we can access them
// Calling sequence:
// 		bl initTimer
initTimer:

		stp 	x19, x30, [sp, #-16]!	// push {x19,lr} $

// Open /dev/mem for read/write and syncing        
        ldr     x0, deviceAddr  		// address of /dev/mem
        bl		openRWSync
        cmp     x0, -1          		// check for error
        bne     memTOK       			// no error, continue
        ldr     x0, devErrAddr  		// error, tell user
        bl      printf
        b       allDone         		// and end program

 
memTOK: 
//Save the file descriptor
		ldr		x19, fileDescAddr
		str		x0, [x19]				//x0 contains the file descriptor (returned by open)

// Map the timer

		ldr		x1, timerAddrPtr 		// x1 is a pointer to the timer address
		bl     	mapMemory
        cmp     x0, -1          		// check for error
        bne     mmapTOK         		// no error, continue
        ldr     x0, memErrAddr 			// error, tell user
        bl      printf			
        b       closeTDev       		// and close /dev/mem

// Save the address of the mapping memory in an internal variable
mmapTOK:
		ldr		x1, progMemAddr
		str		x0, [x1]    
		b		allDone

closeTDev:
        mov     x0, x19			        // /dev/mem file descriptor
        bl      close	        		// close the file   
allDone:								
		ldp 	x19, x30, [sp], #16		// pop {x19, lr} $
		ret		
		


// getTimestamp
// Returns the current timestamp
// Calling sequence:
//       bl getTimestamp
// Output:
//		x0 <- system time(us)

getTimestamp:
		
       	ldr		x0, progMemAddr			// pointer to the address of TIMER regs
		ldr		x0, [x0]				// address of TIMER regs

		ldrsw	x1, [x0, #CLO_OFFSET] 	// lower 32 bits of the system timer
		ldrsw	x2, [x0, #CHI_OFFSET]	// higher 32 bits of the system timer
		lsl		x2, x2, #32				
		orr 	x0, x1, x2				// combain the two parts in a single dword
        ret              				// return

// getElapsedTime
// Returns the us that elapsed between the two timestamp in input.
// Calling sequence:
//		x0 <- first timestamp (us)  - the farthest one
//		x1 <- second timestamp (us) - the closest one
//		bl getElapsedTime	
// Output:
//		x0 <-  elapsed time (us)
getElapsedTime:	 	
		
		sub 	x0, x1, x0
		ret

// delay
// Waits x0 us (up to 18*10^18 [us] - 0xFFFFFFFF FFFFFFFF [us]
// Calling sequence:
//       x0 <- us to wait for
//       bl delay  
delay:
		stp 	x29, x30, [sp, #-16]!	// push {x29,lr} $
		stp 	x19, x20, [sp, #-16]!	// push {x19,x20} $

		mov 	x19, x0					// time to wait for

		bl 		getTimestamp
		mov 	x20, x0					// start time	

// Wait until the timer exceeds	
delayLoop:	
		bl 		getTimestamp
		mov 	x1,	x0					// current time
		mov 	x0, x20					// start time
		bl 		getElapsedTime
		cmp 	x0, x19
		blt		delayLoop				// if the elapsed time is less than the time to wait for

		ldp 	x19, x20, [sp], #16		// pop {x19, x20} $
		ldp 	x29, x30, [sp], #16		// pop {x29, lr} $
		ret

// closeTimer
// Unmaps the timer memory and closes the device
// Calling sequence:
// 		bl closeTimer
closeTimer:
		stp 	x29, x30, [sp, #-16]!	// push {x29,lr} $
		ldr 	x0, progMemAddr
		ldr 	x0, [x0]				// address of the mapped memory
		ldr 	x1, fileDescAddr		
		ldr 	x1, [x1]				// file descriptor
		bl		closeDevice	 			
		ldp 	x29, x30, [sp], #16		// pop {x29, lr} $
		ret

		.align 4		
deviceAddr:
        .dword   device
devErrAddr:
        .dword   devErr
memErrAddr:
        .dword   memErr
timerAddrPtr:
		.dword   PERIPH+TIMER_OFFSET
fileDescAddr:
		.dword 	 fileDesc
progMemAddr:
		.dword	 progMem
