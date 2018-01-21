// sha512.s
// Implements the algorith secure hash algorithm, known as SHA512
// The implementation follows the pseudocode that can be found at
// https://en.wikipedia.org/wiki/SHA-2#Pseudocode
 

// Define my Raspberry Pi
		.cpu cortex-a53

// Constants for the assembler
		.equ DWORD, 8			// number of bytes od dword
		.equ DW_SHIFT, 3		// number of shifts to convert bytes to dwords
				
// Program variables 		 
		.data
		.balign DWORD

// Initialize hash values: first 64 bits of the fractional parts of the square roots of the first 8 primes 2..19
hash: 
		.dword 0x6a09e667f3bcc908, 0xbb67ae8584caa73b, 0x3c6ef372fe94f82b, 0xa54ff53a5f1d36f1,0x510e527fade682d1, 0x9b05688c2b3e6c1f, 0x1f83d9abfb41bd6b, 0x5be0cd19137e2179

// Initialize array of round constants: first 64 bits of the fractional parts of the cube roots of the first 80 primes 2..409):
k: 
		.dword 0x428a2f98d728ae22, 0x7137449123ef65cd, 0xb5c0fbcfec4d3b2f, 0xe9b5dba58189dbbc, 0x3956c25bf348b538, 0x59f111f1b605d019, 0x923f82a4af194f9b, 0xab1c5ed5da6d8118, 0xd807aa98a3030242, 0x12835b0145706fbe, 0x243185be4ee4b28c, 0x550c7dc3d5ffb4e2, 0x72be5d74f27b896f, 0x80deb1fe3b1696b1, 0x9bdc06a725c71235,0xc19bf174cf692694, 0xe49b69c19ef14ad2, 0xefbe4786384f25e3, 0x0fc19dc68b8cd5b5, 0x240ca1cc77ac9c65, 0x2de92c6f592b0275, 0x4a7484aa6ea6e483, 0x5cb0a9dcbd41fbd4, 0x76f988da831153b5, 0x983e5152ee66dfab,0xa831c66d2db43210, 0xb00327c898fb213f, 0xbf597fc7beef0ee4, 0xc6e00bf33da88fc2, 0xd5a79147930aa725,  0x06ca6351e003826f, 0x142929670a0e6e70, 0x27b70a8546d22ffc, 0x2e1b21385c26c926, 0x4d2c6dfc5ac42aed, 0x53380d139d95b3df, 0x650a73548baf63de, 0x766a0abb3c77b2a8, 0x81c2c92e47edaee6, 0x92722c851482353b, 0xa2bfe8a14cf10364, 0xa81a664bbc423001, 0xc24b8b70d0f89791, 0xc76c51a30654be30, 0xd192e819d6ef5218, 0xd69906245565a910, 0xf40e35855771202a, 0x106aa07032bbd1b8, 0x19a4c116b8d2d0c8, 0x1e376c085141ab53, 0x2748774cdf8eeb99, 0x34b0bcb5e19b48a8, 0x391c0cb3c5c95a63, 0x4ed8aa4ae3418acb, 0x5b9cca4f7763e373, 0x682e6ff3d6b2b8a3, 0x748f82ee5defb2fc, 0x78a5636f43172f60, 0x84c87814a1f0ab72, 0x8cc702081a6439ec, 0x90befffa23631e28, 0xa4506cebde82bde9, 0xbef9a3f7b2c67915, 0xc67178f2e372532b, 0xca273eceea26619c, 0xd186b8c721c0c207, 0xeada7dd6cde0eb1e, 0xf57d4f7fee6ed178, 0x06f067aa72176fba, 0x0a637dc5a2c898a6, 0x113f9804bef90dae, 0x1b710b35131c471b, 0x28db77f523047d84, 0x32caab7b40c72493, 0x3c9ebe0a15c9bebc,0x431d67c49c100d4c, 0x4cc5d4becb3e42b6, 0x597f299cfc657e2a, 0x5fcb6fab3ad6faec, 0x6c44198c4a475817	

// Message schedule array
message: 
		.dword   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

// Working variables
a: 
		.dword 0

b: 		
		.dword 0

c: 
		.dword 0

d: 		
		.dword 0

e: 		
		.dword 0

f: 		
		.dword 0

g: 
		.dword 0

m: 
		.dword 0

// Address of the variable holding the text to process
addr_input: 
		.dword 0

input_length: 
		.dword 0

// The program
		.text
		.globl mainAsm
		.globl printHash

// mainAsm
// Calling sequence:
//		x0 <- input address
//		x1 <- input length
//		bl 	mainAsm
// or mainAsm(char* input_address, int length)
 
mainAsm:
    	stp 	x30, x29, [sp, #-16]!			//push {lr, ...} $ 

// Save input address and input length
    	ldr		x2, ptr_addr_input
    	str 	x0, [x2]						//input address -> addr_input 
    	ldr 	x2, addr_input_length
    	str 	x1, [x2]						//input length -> input_length 

//Preprocessing, at the end of this phase we have a processed input (input + padding + length expressed with 128 bit) 
    	bl 		startPadding
    	bl 		fillEnd

//Compression 
    	bl		processChunks

//Print hash
    	ldr 	x0, addr_hash
    	bl 		printHash 

		ldp 	x30, x29, [sp], #16				//pop {lr, ...} $  
    	ret

// startPadding
// Adds 1 at the start of the padding
// input[input length]=0b10000000
// Calling sequence:
//		bl startPadding 
startPadding:
	
		stp 	x20, x21, [sp, #-16]!			//push {x20,x21} $  
		stp 	x22, x23, [sp, #-16]!			//push {x22,x23} $  
		stp		x24, x25, [sp, #-16]!			//push {x24,x25} $  

		ldr 	x23, ptr_addr_input 			
		ldr 	x23,[x23]						//x23<-[input] 

		ldr 	x20, addr_input_length
		ldr 	x20, [x20]						//x20<-input_length 
		mov 	x22, x20					 
	
		lsr 	x22, x22, #DW_SHIFT				//x22<- index of the dword that we have to modify (from left to right) 
		and 	x20, x20, #0b00000111			//x20= input_length MOD 8 
		mov 	x25, #DWORD-1					// $ rsb  
		sub 	x20, x25, x20					//x20= (7-input_length MOD 4)index of the byte in the dword that has to be modified 	
		lsl 	x20,x20, #3						//x20<-x20//8, # of left shifts of 0b10000000 

		ldr		x24,[x23,x22, lsl #DW_SHIFT]	//Load the word that has to be modified 
	
		mov 	x21,#0b10000000		
		lsl 	x21,x21, x20					//Positioning the 0x10 the right position 

		orr		x24,x24, x21					//Insert the 1 
		str 	x24,[x23,x22, lsl #DW_SHIFT]	//Store the modified value  
	
		ldp 	x24, x25, [sp], #16				//pop {x24,x25} $  
		ldp 	x22, x23, [sp], #16				//pop {x22,x23} $  
    	ldp 	x20, x21, [sp], #16				//pop {x20,x21} $  
    
		ret

// fillEnd 
// Copy the length of the input expressed as 128 bit big endian 
// in the last 2 words of the input
// Calling sequence:
//		bl fillEnd
fillEnd:
		stp 	x30, x29, [sp, #-16]!			//push {lr, ...} $  
		stp 	x20, x21, [sp, #-16]!			//push {x20,x21} $  
		stp 	x22, x23, [sp, #-16]!			//push {x22,x23} $  

		bl 		prdDwords						//x0<-nDWords(input) 		
	
		ldr		x21, ptr_addr_input
		ldr 	x21, [x21]  					//x21<-[input] 
		ldr 	x20, addr_input_length
		ldr 	x20,[x20]		 				//x20<-input_length 
	
		lsr 	x22, x20, #61 					//x22<-3 most significant bits of input_length*8 (bits)  
		sub 	x23, x0, #2						//x23=nDWords(input)-2 
		str 	x22,[x21, x23, lsl #DW_SHIFT]	//x22->processed_input[nDWords(input)-2]  
	
		lsl		x22, x20, #3					//x22= 64 less significant bits of input_length*8 (bits)  
		sub 	x23, x0, #1
		str 	x22, [x21, x23, lsl #DW_SHIFT]	//x22->processed_input[nDWords(input)-1] 

		ldp 	x22, x23, [sp], #16				//pop {lr, ...} $  
		ldp 	x20, x21, [sp], #16				//pop {x22,x23} $  
		ldp 	x30, x29, [sp], #16				//pop {x20,x21} $  
		ret
	

// processChunks
// For each chuck(16 dwords) in which we can divide the processed input we do:
//	- copyProcessed
//	- fillMessage	
//	- initAlphabeth
//	- compress
//	- updateHash
// Calling sequence:
//		bl processChuncks		 
processChunks:
	
		stp		x30, x29, [sp, #-16]!			//push {lr, ...} $  
		stp 	x20, x21, [sp, #-16]!			//push {x20,x21} $  

		mov		x20, #0							//x20 counter 
		bl		prdDwords											   
		mov 	x21, x0							//x21=number of dwords of the processed input (input + padding + length expressed with 128 bit)

// We divide the processed input in 16 dwords chucks (1024 bits) and process them separately
loop_pChs:	

		mov 	x0, x20, lsl #DW_SHIFT 			//x0=chunck offset in processed input 

		bl 		copyProcessed					// copy the chunck in the first 16 dwords of the message array
		bl 		fillMessage						// complete the message following the rules of the algorithm
		bl 		initAlphabeth					// initialize the working variables with the current value of the hash
		bl 		compress						// compress the message schedule array following the rules of the algorithm
		bl 		updateHash						// update hash values

		add 	x20,x20,#16						// next chunk
		cmp 	x20, x21	
		blt 	loop_pChs						// if there are still chunks 

		ldp 	x20, x21, [sp], #16				// pop {x20,x21} $  
		ldp 	x30, x29, [sp], #16				// pop {lr, ...} $  	
		ret

// prdDwords
// Returns the length in dwords of the processed input (a multiple of 16 dwords - 128  bytes - 1024 bits).
// It computes the result by means of this calculation:
// nrOfBytes = (floor((inputLength+17-1)/128))*128+128
// if inputLength+17=128 -> nrOfBytes= floor((128-1)/128)*128+128=128
// if inputLength+17=127 -> nrOfBytes= floor((127-1)/128)*128+128=128
// if inputLength+17=129 -> nrOfBytes= floor((129-1)/128)*128+128=256
// Calling sequence:
//		bl prdDwords
// Output:
// 		x0 <- length in dwords of the processed input 	
prdDwords:

		ldr 	x0, addr_input_length
		ldr 	x0,[x0]							// x0<-input_length 
		add 	x0, x0, #17						// 17 bytes= 16 bytes for the length of the word in bits+ 1 byte of padding 

//x0=floor(input_length+17)/128 
		sub 	x0, x0, #1						// x0=input_length+17-1
		lsr 	x0, x0, #7						// x0=floor((input_length+17-1)/64), 128  bytes = 1024 bits 

//x0=x0*128+128 
		lsl 	x0, x0, #7						// x0=(floor(input_length+17-1)/64)*64
		add 	x0, x0, #128					// x0= (floor(input_length+17-1)/64)*64+64

		lsr 	x0, x0, #DW_SHIFT				// x0=x0/8 from bytes to dwords 
		ret
					
// copyProcessed
// Copy in the first 16 dwords of message schedule array the dwords of the chunck
// Calling sequence:
// 		x0 <- chunk address offset in the processed input
//		bl copyProcessed
copyProcessed:	
	
		stp 	x20, x21, [sp, #-16]!			// push {x20,x21} $  
		stp 	x22, x23, [sp, #-16]!			// push {x22,x23} $  	
		
		ldr 	x21, addr_message
	
		ldr 	x22, ptr_addr_input 		
		ldr 	x22, [x22]						// x22=base address of processed_input 
		add 	x0, x0, x22						// x0=chunk address (base+offset) 	
			
		mov 	x20,#0							// x20 counter 
																		  	
loop_pCh: 
		ldr		x22,[x0,x20, lsl #DW_SHIFT]		// x22<-chunk[i] 
		str		x22,[x21,x20, lsl #DW_SHIFT]	// message[i]=chunk[i] 

// Update counter			
		add 	x20, x20,#1						// next word in the chunk
		cmp 	x20, #16
		bne 	loop_pCh

		ldp 	x22, x23, [sp], #16				// pop {x22,x23} $  
		ldp 	x20, x21, [sp], #16				// pop {x22,x23} $  
		ret

// fillMessage
// Completes the values message[16-79] with values calculated as follows
//  s0 := (message[i-15] rightrotate 1) xor (message[i-15] rightrotate 8) xor (message[i-15] rightshift 7)
//  s1 := (message[i-2] rightrotate 19) xor (message[i-2] rightrotate 61) xor (message[i-2] rightshift 6)
//  message[i] := message[i-16] + s0 + message[i-7] + s1 
// Calling sequence:
//		bl fillMessage
fillMessage:

		stp 	x20, x21, [sp, #-16]!			//push {x20,x21} $  
		stp 	x22, x23, [sp, #-16]!			//push {x22,x23} $  	
		stp 	x24, x25, [sp, #-16]!			//push {x24,x25} $  
		stp 	x26, x27, [sp, #-16]!			//push {x26,x27} $  	
		
		mov 	x20, #16						//x20 = i (16:79) (end of message) 
		ldr 	x21, addr_message		

loop_fm:				
// x24 = s0 =(ror(message[i-15],1)) XOR (ror(message[i-15],8))  XOR (lsr(message[i-15],7))
		sub 	x22, x20, #15					// x22= i-15 
		ldr 	x23, [x21, x22, lsl #DW_SHIFT]	// x11 <- message[i-15] 
		ror 	x24, x23, #1					// x24=ror(message[i-15],1) 	
		ror 	x25, x23, #8					// x25=ror(message[i-15],8) 	
		eor 	x24, x24,x25					
		lsr 	x25, x23, #7					// x25=lsr(message[i-15],7) 
		eor 	x24,x24, x25					
			
// x25 = s1 = (ror(message[i-2],19)) XOR (ror(message[i-2],61)) XOR (lsr(message[i-2],6)) 		 
		sub 	x22, x20, #2					// x22=i-2 
		ldr 	x23, [x21, x22, lsl #DW_SHIFT]	// x23 <-message[i-2] 
		ror 	x25, x23, #19					//x25=ror(message[i-2],19) 
		ror 	x26, x23, #61					//x26=ror(message[i-2],61) 	
		eor 	x25, x25, x26					 
		lsr 	x26, x23, #6					//x26=lsr(message[i-2],6) 
		eor 	x25, x25, x26					 			

// x24 = s0+s1+message[i-16]+message[i-7] 		
		add 	x24, x24, x25	 
		sub 	x22, x20, #16					//x22= i-16 
		ldr 	x23, [x21, x22, lsl #DW_SHIFT]	//x23 <- message[i-16] 
		add 	x24, x24, x23
		sub 	x22, x20, #7					//x22= i-7 
		ldr 	x23, [x21, x22, lsl #DW_SHIFT]	//x23 <- message[i-7] 
		add 	x24, x24, x23					//x24=s0+s1+message[i-16]+message[i-7] 
		
// Update message[i]					
		str 	x24, [x21, x20, lsl #DW_SHIFT]	//message[i]=s0+s1+message[i-16]+message[i-7] 	
		
// counter update 
		add 	x20, x20, #1					//i++ 
		cmp 	x20, #80					
		blt 	loop_fm							//if i<80 loop 


bpEnd:				
		ldp 	x26, x27, [sp], #16				//pop {x26,x27} $  
		ldp 	x24, x25, [sp], #16				//pop {x24,x25} $  
		ldp 	x22, x23, [sp], #16				//pop {x22,x23} $  
		ldp 	x20, x21, [sp], #16				//pop {x20,x21} $  
		ret
	
// initAlphabeth
// Initializes the working variables a to m with hash values (a=hash[0], b=hash[1]....)
// Calling sequence:
// 		bl initAlphabeth
initAlphabeth:

		stp 	x30, x29, [sp, #-16]!			// push {lr, ...} $  
					
		ldr 	x0, addr_a						// working variable a address
		mov 	x1, #0							// hash index
		bl 		initLetter						// a = hash[index]
		
		ldr 	x0, addr_b
		mov 	x1, #1
		bl 		initLetter
		
		ldr 	x0, addr_c
		mov 	x1, #2
		bl 		initLetter	
		
		ldr		x0, addr_d
		mov 	x1, #3
		bl 		initLetter
			
		ldr 	x0, addr_e
		mov 	x1, #4
		bl 		initLetter
	
		ldr 	x0, addr_f
		mov 	x1, #5
		bl 		initLetter
			
		ldr 	x0, addr_g
		mov 	x1, #6
		bl 		initLetter
				
		ldr 	x0, addr_m
		mov 	x1, #7
		bl 		initLetter
		
		ldp 	x30, x29, [sp], #16				// pop {lr, ...} $  
		
		ret

// initLetter 
// Calling sequence:
//		x0 <- working variable address
//		x1 <- index of the hash value (i)
initLetter:
		stp 	x20, x21, [sp, #-16]!			// push {x20. x21} $  
			
		ldr		x21, addr_hash					// x21<-[hash] 
		ldr 	x20, [x21, x1, lsl #DW_SHIFT]	// x20<-hash[i] 
		str 	x20, [x0]						// working variable<-hash[i] 
	
		ldp		x20, x21, [sp], #16				// pop {x20. x21} $ 												
		ret

// compress
// Compression function main loop:
//   for i from 0 to 80
//       temp1 := makeTemp1
//       temp2 := makeTemp2
// 		 updateAlphabeth(temp1, temp2)
// Calling sequence:
// 		bl compress
compress:
		stp 	x30, x29, [sp, #-16]!			// push {lr, ...} $  
		stp 	x20, x21, [sp, #-16]!			// push {x20, x21} $  
			
		mov 	x20, #0							// x20 counter 
loop_cpr:	
		mov 	x0, x20							//input for makeTemp1 
		bl 		makeTemp1						// x0<-temp1 
		
		mov		x21, x0							// x21=temp1  
		bl 		makeTemp2						// x0<-temp2 
		
		mov 	x1, x0							// x1<-temp2 input for updateAlphabeth 	
		mov		x0, x21							// x0<-temp1 input for updateAlphabeth 
		bl 		updateAlphabeth
	
//counter update 
		add 	x20, x20,#1
		cmp 	x20, #80
		blt		loop_cpr
		
		ldp 	x20, x21, [sp], #16				//	pop {x20,x21} $  		
		ldp 	x30, x29, [sp], #16				//	pop {lr, ...} $  
		ret

// makeTemp1 
// Computes temp1:
// S1 := (e rightrotate 14) xor (e rightrotate 18) xor (e rightrotate 41)
// ch := (e and f) xor ((not e) and g)
// temp1 := m + S1 + ch + k[i] + message[i]
// Calling sequence:
//		x0 <- i
// 		bl makeTemp1
// Output:
// 		x0 <- temp1;
makeTemp1:

		stp 	x20, x21, [sp, #-16]!			//push {x20, x21} $  
		stp 	x22, x23, [sp, #-16]!			//push {x22, x23} $  
		stp 	x24, x25, [sp, #-16]!			//push {x24, x25} $  
		stp 	x26, x27, [sp, #-16]!			//push {x26, x27} $  
			
// x21 = S1 := (e rightrotate 14) xor (e rightrotate 18) xor (e rightrotate 41) 
		ldr 	x26, addr_e
		ldr 	x26, [x26]						//x26<-e 
		ror 	x21, x26, #14					//x21=ror(e,14) 
		ror 	x22, x26, #18					//x22=ror(e,18) 
		eor 	x21, x21, x22					//x21=ror(e,14) XOR ror(e,18) 
		ror 	x22, x26,#41					//x22=ror(e, 41) 
		eor 	x21, x21,x22					//x21=ror(e,14) XOR ror(e,18)XOR ror(e,41) 
		
// x22 = ch := (e and f) xor ((not e) and g) 
		ldr 	x15, addr_f
		ldr 	x25, addr_g
		ldr		x15, [x15]					  	//x15<-f 
		ldr 	x25, [x25]						//x25<-g 
		and 	x22, x26, x15					//x22=e AND f 
		mvn 	x26, x26						//x26=NOT(e) 
		and 	x23, x26, x25					//x23=NOT(e) AND g 
		eor 	x22, x22, x23					//x22=(e and f) xor ((not e) and g) 
	
// x23 = temp1 :=m + x21 + x22 + k[i] + message[i] 
		ldr 	x25, addr_m				
		ldr 	x25, [x25]						//x25<-m 
		add 	x23, x25, x21					//x23=m+x21 
		add 	x23, x23, x22					//x23=m+x21+x22 
		ldr 	x25, addr_k
		ldr 	x25, [x25, x0, lsl #DW_SHIFT]	//x25<-k[i] 
		add 	x23, x23, x25					//x23= m+x21+x22+k[i] 	
		ldr 	x25, addr_message
		ldr 	x25, [x25, x0, lsl #DW_SHIFT]	//x25<-message[i] 	
		add 	x23, x23, x25					//x23=m + x21 + x22 + k[i] + message[i] 
				
		mov 	x0, x23							//x0 = temp1 (output) 	

		ldp 	x26, x27, [sp], #16				//pop {x26, x27} $  		
		ldp 	x24, x25, [sp], #16				//pop {x24, x25} $  
		ldp 	x22, x23, [sp], #16				//pop {x22, x23} $  		
		ldp 	x20, x21, [sp], #16				//pop {x20, x21} $  
					
		ret

// makeTemp2
// Computes temp2:
//	S0 := (a rightrotate 28) xor (a rightrotate 34) xor (a rightrotate 39)
//  maj := (a and b) xor (a and c) xor (b and c)
//  temp2 := S0 + maj
// Calling sequence:
//		bl makeTemp2
// Output:
// 		x0 <- temp2
makeTemp2:	 

		stp 	x20, x21, [sp, #-16]!			//push {x20, x21} $  
		stp		x22, x23, [sp, #-16]!			//push {x22, x23} $  
		stp 	x24, x25, [sp, #-16]!			//push {x24, x25} $  
		stp 	x26, x27, [sp, #-16]!			//push {x26, x27} $  
			
	
// x21 = S0 := (a rightrotate 28) xor (a rightrotate 34) xor (a rightrotate 39) 
		ldr 	x20, addr_a				
		ldr 	x20, [x20]						//x20<-a 
		ror 	x21, x20, #28					//x21=ror(a, 28) 
		ror 	x22, x20, #34					//x22=ror(a, 34) 
		eor 	x21, x21, x22					//x21=ror(a, 2) XOR ror(a, 13) 
		ror 	x22, x20, #39					//x22=ror(a, 39) 
		eor 	x21, x21, x22					//x21=s0  
	
// x22 = maj := (a and b) xor (a and c) xor (b and c) 
		ldr 	x23, addr_b
		ldr 	x25, addr_c
		ldr 	x23, [x23]						//x23<-b 
		ldr 	x25, [x25]						//x25<-c 
		and 	x22, x20, x23					//x22=a AND b  
		and 	x26, x20, x25					//x26=a AND c  
		eor 	x22, x22, x26					//x22=(a AND b) XOR (a AND c) 
		and 	x26, x23, x25					//x26=b AND c 
		eor 	x22, x22, x26					//x22=(a AND b) XOR (a AND c) XOR (b AND c) 

// x0 = temp2 := S0+maj												
		add 	x0, x21, x22					// output 
	
		ldp 	x26, x27, [sp], #16				//pop {x26, x27} $  		
		ldp 	x24, x25, [sp], #16				//pop {x24, x25} $  
		ldp 	x22, x23, [sp], #16				//pop {x22, x23} $  		
		ldp 	x20, x21, [sp], #16				//pop {x20, x21} $  			
					
		ret


// updateAlphabeth
// Updates the alphabeth(working variables):
// m := g
// g := f
// f := e
// e := d + temp1
// d := c
// c := b
// b := a
// a := temp1 + temp2
// Calling sequence:
// 		x0 <- temp1
// 		x1 <- temp2
// Output:
//		bl updateAlphabeth
updateAlphabeth:
	
		stp 	x30, x29, [sp, #-16]!			// push {lr, ...} $  
		stp 	x20, x21, [sp, #-16]!			// push {x20, x21} $  
		stp 	x22, x23, [sp, #-16]!			// push {x22, x23} $  
												
		mov 	x20, x0							// x20=temp1 
		mov 	x21, x1							// x21=temp2 
	
// m=g 
		ldr 	x0, addr_m						// working variable m address, paramter for updateLetter 			
		ldr 	x1, addr_g						// working variable g address, paramter for updateLetter 
		bl 		updateLetter
	
// g=f 
		ldr 	x0, addr_g					
		ldr 	x1, addr_f		
		bl 		updateLetter
				
// f=e 
		ldr 	x0, addr_f					
		ldr 	x1, addr_e		
		bl 		updateLetter	
				
// e=d+temp1 
		ldr 	x0, addr_e					
		ldr 	x1, addr_d		
		bl 		updateLetter					// e=d 
		ldr 	x23, addr_e
		ldr 	x22, [x23]						// x22=e 
		add 	x22, x22, x20					// x22+=temp1 
		str 	x22, [x23]						// x22->e 
	
// d=c 
		ldr 	x0, addr_d					
		ldr 	x1, addr_c		
		bl 		updateLetter			
	
// c=b 
		ldr 	x0, addr_c				
		ldr 	x1, addr_b		
		bl 		updateLetter	
				
// b=a 
		ldr 	x0, addr_b					
		ldr 	x1, addr_a		
		bl 		updateLetter		
		
// a= temp1+temp2 
		add 		x20,x20,x21
		ldr 		x1, addr_a
		str			x20, [x1]					// a=temp1+temp2 
		
		ldp 		x22, x23, [sp], #16			// pop {x22, x23} $  
		ldp 		x20, x21, [sp], #16			// pop {x20, x21} $  
		ldp 		x30, x29, [sp], #16			// pop {lr, ... } $  	
		ret

// updateLetter
// Assigns to a working variable the value of another one
// letter1:= letter2
// Calling sequence:
// 		x0 <- address(letter1)
// 		x1 <- address(letter2)
//		bl updateAlphabeth
updateLetter:
		ldr 		x1, [x1]					//x1<-letter2 
		str			x1, [x0]					//letter2->letter1 
												
		ret


// updateHash
// Updates the values of the hash adding the current values of the working variables
//  h[0]+=a
//  h[1]+=b
//  ...
//  h[7]+=m
// Calling sequence:
//		bl updateHash	  
updateHash:
	
		stp 	x30, x29, [sp, #-16]!			//push {lr, ...} $  
		
//h[0]+=a 
		mov 	x0, #0							//x0=index 
		ldr 	x1, addr_a						//x1=address of working variable a 
		bl 		updateH
	
//h[1]+=b 
		mov 	x0, #1		
		ldr 	x1, addr_b	
		bl 		updateH
	
//h[2]+=c 
		mov 	x0, #2		
		ldr 	x1, addr_c	
		bl 		updateH
	
//h[3]+=d 
		mov 	x0, #3		
		ldr 	x1, addr_d	
		bl		updateH
	
//h[4]+=e 
		mov 	x0, #4		
		ldr 	x1, addr_e	
		bl 		updateH
	
//h[5]+=f 
		mov 	x0, #5		
		ldr 	x1, addr_f	
		bl 		updateH
	
//h[6]+=g 
		mov 	x0, #6		
		ldr 	x1, addr_g	
		bl 		updateH
	
//h[7]+=m 	
		mov 	x0, #7		
		ldr 	x1, addr_m	
		bl 		updateH
	
		ldp 	x30, x29, [sp], #16 			//pop {lr, ...} $  
		ret

// updateH
// Updates the value of hash[i] adding to it the value of a working variable
// (Overflows are ignored)
// 	hash[i]+=letter
// Calling sequence:
// 		x0 <- i
// 		x1 <- letter address 
updateH:  
												
		stp 	x20, x21, [sp, #-16]!			//push {lr, ...} $  
		ldr 	x20, addr_hash
		ldr 	x1, [x1] 						//x1<-letter 
		ldr 	x21, [x20, x0, lsl #DW_SHIFT] 	//x21<-hash[i] 
		add 	x21, x21, x1					//x21=hash[i]+letter 
		str 	x21,[x20, x0, lsl #DW_SHIFT]	//hash[i]+letter->hash[i] 
		ldp 	x20, x21, [sp], #16 			//pop {lr, ...} $  
		
		ret


		.balign DWORD
addr_hash: .dword hash
addr_k: .dword k
addr_message: .dword message
addr_a: .dword a
addr_b: .dword b
addr_c: .dword c
addr_d: .dword d
addr_e: .dword e
addr_f: .dword f
addr_g: .dword g
addr_m: .dword m
ptr_addr_input: .dword addr_input
addr_input_length: .dword input_length
