@ sha256.s
@ Implements the secure hash algorithm known as SHA256.
@ The implementation follows the pseudocode that can be
@ found at https://en.wikipedia.org/wiki/SHA-2#Pseudocode

@ Define my Raspberry Pi
        .cpu    cortex-a53
        .fpu    neon-fp-armv8
        .syntax unified         @ modern syntax
		
@ Constants for assembler
		.equ WORD,4				@ number of bytes of a word
		.equ W_SHIFT, 2			@ number of shifts to convert bytes to words

@ Program variables
		.data
		.balign WORD

@ Initialize hash values: first 32 bits of the fractional parts of the square roots of the first 8 primes 2..19
hash: 
		.word 0x6a09e667,0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19

@ Initialize array of round constants: (first 32 bits of the fractional parts of the cube roots of the first 64 primes 2..311):
k: 
		.word    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147,0x06ca6351, 0x14292967,0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a,0x5b9cca4f, 0x682e6ff3,0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2

@ Message schedule array
message: 
		.word   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

@ Working variables:
a:		
	.word 0
b: 	
	.word 0
c: 
	.word 0
d: 
	.word 0
e: 
	.word 0
f: 
	.word 0
g: 
	.word 0
m: 
	.word 0

@ Address of the variable holding the text to process
addr_input: 
	.word 0	 
input_length: 
	.word 0
   
@ The program
	.text
	.global mainAsm
	.global printHash

@ mainAsm
@
@ Calling sequence:
@		r0 <- input address
@  		r1 <- input length
@		bl mainAsm
@	or mainAsm(char *input_address, int length);
mainAsm:
		push	{lr} 
@ Save input address and input length 
		ldr 	r2, ptr_addr_input		 		
		str 	r0, [r2]					@ input address->addr_input 
		ldr 	r2, addr_input_length
		str 	r1, [r2]					@ input length->input_length 
	
@ Preprocessing, at the end of this phase we have a processed input (input + padding + length in bits expressed with 64 bits)
		bl	startPadding
		bl 		fillEnd						

@ Compression 
		bl 		processChunks

@ Print hash 
		ldr 	r0, addr_hash
		bl 		printHash

		pop 	{lr}
		bx 		lr

@ startPadding
@ Adds 1 at the start of the padding :
@ input[input_length]=0b10000000
@	
@ Calling sequence:
@		bl startPadding	   
startPadding:		
		push 	{r5, r6, r7, r8, r9, r10}

		ldr 	r8, ptr_addr_input 			
		ldr 	r8,	[r8]					@ r8<-[input] 
		ldr 	r5, addr_input_length
		ldr 	r5, [r5]					@ r5<- input_length 
		add 	r7, r5,#1					@ r7<- length in byte of input + 0b10000000 		
		lsr 	r7,#W_SHIFT					@ r7<- index of the word that we have to modify (from left to right) 
		
		and 	r5, #0b00000011				@ r5= input_length MOD 4 
		rsb 	r5, r5, #WORD-1				@ r5= (3-input_length MOD 4)index of the byte in the word that has to be modified 	
		lsl 	r5,#3						@ r5<- r5*8, number of left shifts of 0b10000000 

		ldr 	r9,[r8,r7, lsl #W_SHIFT]	@ load the word that has to be modified 		
		mov 	r6,#0x00000080		
		lsl 	r6, r5						@ positioning the 0b10000000 in the right position 	
		orr 	r9,r6						@ insert the 1 
		str 	r9,[r8,r7, lsl #W_SHIFT]	@ store the modified value 

		pop 	{r5, r6, r7, r8, r9, r10}
		bx 		lr
		
@ fillEnd 
@ Copy the length of the input expressed as 64 
@ bit big endian in the last 2 words of the input.
@
@ Calling sequence:
@		bl fillEnd
fillEnd:
		push 	{r5, r6, r7, r8, r9, lr}

		bl 		prdWords					@ r0<-nWords(input) 

		ldr 	r6, ptr_addr_input
		ldr 	r6, [r6]  					@ r6<-[input] 
		ldr 	r5, addr_input_length
		ldr 	r5,[r5]						@ r5<-input_length 
		lsr 	r7, r5, #29					@ r7<-3 most significant bits of input_length*8(bits) 

		sub 	r8, r0, #2					@ r8=nWords(input)-2 
		str 	r7,[r6, r8, lsl #W_SHIFT]	@ r7->processed[nWords(input)-2]  
		lsl 	r7, r5, #3					@ r7= 32 less significant bits of input_length*8(bits) 
		sub 	r8, r0, #1
		str 	r7, [r6, r8, lsl #W_SHIFT]	@ r7->processed[nWords(input)-1] 
									
		pop 	{r5, r6, r7, r8, r9, lr}
		bx 		lr

@ processChunks
@ For each chuck(16 words) in which we can divide the processed input we do:
@		- copyProcessed
@		- fillMessage	
@		- initAlphabeth
@		- compress
@		- updateHash
@
@ Calling sequence:
@ 		bl processChunks
processChunks:
		push 	{r5, r6, r7, lr}
		mov 	r5, #0						@ r5 counter 
		bl 		prdWords
		mov 	r6, r0						@ r6=number of words of the processed input (input + padding + L in bits)

@ We divide the processed input in 16 words chunks (512 bits) and process them separately					
loop_pChs:	
		mov 	r0, r5, lsl #W_SHIFT		@ r0=chunck offset in processed   			
			
		bl 		copyProcessed				@ copy the chunk in the first 16 words of the message schedule array
		bl		fillMessage					@ complete the message following the rules of the algorithm 
		bl		initAlphabeth				@ initialize the working variables with the current values of the hash
		bl		compress					@ compress the message schedule array following the rules of the algorithm
		bl 		updateHash					@ update hash values
			
		add 	r5,r5,#16					@ next chunk
		cmp		r5, r6		
		blt 	loop_pChs					@ if there are still chunks 
			
		pop {r5, r6, r7, lr}
		bx lr

@ prdWords
@ Returns the length in words of the processed input (a multiple of 64 bytes - 512 bits)
@ It computes the result by means of this calculation:
@ nrOfBytes = (floor((inputLength+9 -1)/64))*64+64 so that:
@ if inputLength+9=64 -> nrOfBytes = [floor((64-1)/64)]*64+64 =64
@ if inputLength+9=63 -> nrOfBytes = [floor((63-1)/64)]*64+64 =64
@ if inputLength+9=65 -> nrOfBytes = [floor((65-1)/64)]*64+64 =128
@
@ Calling sequence:
@		bl prdWords
@ OUTPUT:
@ r0 length in words of the processed input
prdWords:
		ldr 	r0, addr_input_length
		ldr 	r0,[r0]						@ r0<-input_length 
		add 	r0, r0, #9					@ 9 bytes= 8 bytes for the length of the word in bits+ 1 byte of padding 

@r0=floor(input_length+9)/64 
		sub 	r0, r0, #1					@ r0=length+9-1
		lsr 	r0, r0, #6					@ r0=floor[(length+9-1)/64], 64 bytes = 512 bits 
		
@r0=[floor((length+9-1)/64)]*64+64 
		lsl 	r0, #6						@ r0=[floor(length+9-1)/64]*64
		add 	r0, r0, #64					@ r0=[floor(length+9-1)/64]*64 + 64
			
		lsr 	r0, #W_SHIFT				@ r0=r0/4 from bytes to words 	
		bx lr

@ copyProcessed
@ Copy in the first 16 words of the message schedule array the words of the chunck.
@
@ Calling sequence:
@ 		r0<- chunk address offset in the processed input 
@		bl copyProcessed
copyProcessed:
		push 	{r5, r6, r7, r8}
			
		ldr 	r6, addr_message
		ldr 	r7, ptr_addr_input 		
		ldr 	r7, [r7]					@ r7=base address of processed input
		add 	r0, r0, r7					@ r0=chunk address (base + offset)
											
		mov 	r5,#0						@ r5 counter 
loop_pCh:   
		ldr 	r7,[r0,r5, lsl #W_SHIFT]	@ r7<-chunk[i] 
		str 	r7,[r6,r5, lsl #W_SHIFT]	@ message[i]=chunck[i] 	

@ Update counter
		add 	r5,r5,#1				 	@ next word in the chunk
		cmp 	r5, #16
		bne 	loop_pCh

		pop 	{r5, r6, r7, r8}
		bx 		lr
			
@ fillMessage
@ Completes the values message[16-63] with values calculated as follows
@  s0 := (message[i-15] rightrotate 7) xor (message[i-15] rightrotate 18) xor (message[i-15] rightshift 3)
@  s1 := (message[i-2] rightrotate 17) xor (message[i-2] rightrotate 19) xor (message[i-2] rightshift 10)
@  message[i] := message[i-16] + s0 + message[i-7] + s1
@ 	
@ Calling sequence:
@		bl fillMessage
fillMessage:
		push	{r5, r6, r7, r8, r9, r10, r11, r12}

		mov		r5, #16						@ r5 = i 16:63 (end of message) 
		ldr		r6, addr_message		
loop_fm:	

@ r9=s0 :(ror(message[i-15], 7)) XOR (ror(message[i-15], 18)) XOR (lsr(message[i-15], 3))
		sub		r7, r5, #15					@ r7 = i-15 
		ldr		r8, [r6, r7, lsl #W_SHIFT]	@ r8 <- message[i-15] 			
		ror		r9, r8, #7					@ r9 =ror(message[i-15],7) 	
		ror		r10, r8, #18				@ r10=ror(message[i-15],18) 	
		eor		r9,r9,r10					
		lsr		r10, r8, #3					@ r10=lsr(message[i-15],3) 
		eor		r9,r9,r10					@ r9=s0

@ r10=s1 : (ror(message[i-2], 17)) XOR (ror(message[i-2], 19)) XOR (lsr(message[i-2], 10))						
		sub		r7, r5, #2					@ r7 =i-2 
		ldr		r8, [r6, r7, lsl #W_SHIFT]	@ r8 <- message[i-2] 	
		ror		r10, r8, #17				@ r10=ror(message[i-2],17) 
		ror 	r11, r8, #19				@ r11=ror(message[i-2],19) 	
		eor 	r10, r10,r11				
		lsr 	r11, r8, #10				@ r11=lsr(message[i-2],10) 
		eor 	r10, r10, r11				@ r10= s1

@ r9 = s0+s1+message[i-16]+message[i-7] 							
		add 	r9, r9, r10					@ r9=s0+s1 		
		sub 	r7, r5, #16					@ r7= i-16 
		ldr 	r8, [r6, r7, lsl #W_SHIFT]	@ r8 <- message[i-16] 	
		add 	r9, r9, r8					@ r9=s0+s1+message[i-16] 
		sub 	r7, r5, #7					@ r7= i-7 
		ldr 	r8, [r6, r7, lsl #W_SHIFT]	@ r8 <- message[i-7] 					
		add 	r9, r9, r8					@ r9=s0+s1+message[i-16]+message[i-7] 

@ update message[i] 										
		str 	r9, [r6, r5, lsl #W_SHIFT]	@ message[i]=s0+s1+message[i-16]+message[i-7] 	
	
@ update counter 
		add 	r5,r5,#1					@ i++ 
		cmp 	r5, #64					
		blt 	loop_fm						@ if i<64 loop 
		
		pop 	{r5, r6, r7, r8, r9, r10, r11, r12}
		bx lr

@ initAlphabeth
@ Initializes the working variables a to m with hash values (a=hash[0], b=hash[1]....)
@ 
@ Calling sequence:
@		bl initAlphabeth
initAlphabeth:
		push	{r5, lr}
						
		ldr 	r0, addr_a				@ working variable a address
		mov 	r1, #0			 		@ i,hash index
		bl 		initLetter				@ a = hash[i]
			
		ldr 	r0, addr_b
		mov 	r1, #1
		bl 		initLetter
			
		ldr 	r0, addr_c
		mov 	r1, #2
		bl 		initLetter	
			
		ldr 	r0, addr_d
		mov 	r1, #3
		bl 		initLetter
			
		ldr 	r0, addr_e
		mov 	r1, #4
		bl 		initLetter
			
		ldr 	r0, addr_f
		mov 	r1, #5
		bl 		initLetter
		
		ldr 	r0, addr_g
		mov 	r1, #6
		bl 		initLetter
		
		ldr 	r0, addr_m
		mov 	r1, #7
		bl 		initLetter	
		
		pop 	{r5, lr}
		bx 		lr
			
@ initLetter
@ Calling sequence:
@		r0<-working variable address
@		r1<-index of the hash value (i)
@		bl initLetter
initLetter:
		push	 {r5,r6}
			
		ldr 	r6, addr_hash				@ r6<-[hash] 
		ldr 	r5, [r6, r1, lsl #W_SHIFT]	@ r5<-hash[i] 
		str 	r5, [r0]					@ working variable<-hash[i] 
			
		pop 	{r5,r6}
		bx 		lr

@ compress
@ Compression function main loop:
@  for i from 0 to 63
@ 	temp1 := makeTemp1
@   temp2 := makeTemp2
@	updateAlphabeth(temp1, temp2)
@
@ Calling sequence:
@ 		bl compress
compress:
		push 	{r5, r6, r7, lr}
			
		mov 	r5, #0						@ r5 counter 
loop_cpr:	
		mov 	r0, r5						@ input for makeTemp1  
		bl 		makeTemp1					@ r0<-temp1 
		mov 	r6, r0						@ r6=temp1 

		bl 		makeTemp2					@ r0<-temp2 
		mov 	r1, r0						@ r1<-temp2 input for updateAlphabeth 
											
		mov 	r0, r6						@ r0<-temp1 input for updateAlphabeth 
		bl 		updateAlphabeth

@ counter update 
		add 	r5,r5,#1
		cmp 	r5, #64
		blt 	loop_cpr
			
		pop		{r5, r6, r7, lr}
		bx 		lr

@ makeTemp1 
@ Computes temp1:
@ S1 := (e rightrotate 6) xor (e rightrotate 11) xor (e rightrotate 25)
@ ch := (e and f) xor ((not e) and g)
@ temp1 := m + S1 + ch + k[i] + message[i]
@
@ Calling sequence:
@ 		r0 <- i
@		bl makeTemp1
@ OUTPUT:
@ 		r0 = temp1
makeTemp1:
		push {r5, r6, r7, r8, r9, r10, r11, r12}	
			
@r6 = s1:= (e rightrotate 6) xor (e rightrotate 11) xor (e rightrotate 25) 	
		ldr		r11, addr_e
		ldr		r11, [r11]					@ r11<-e 
		ror		r6, r11, #6					@ r6=ror(e,6) 
		ror		r7, r11, #11				@ r7=ror(e,11) 
		eor		r6, r6, r7					@ r6=ror(e,6) XOR ror(e,11) 
		ror		r7,r11, #25					@ r7=ror(e, 25) 
		eor		r6,r6,r7					@ r6=ror(e,6) XOR ror(e,11)XOR ror(e,11) 
		
@r7 = ch:= (e and f) xor ((not e) and g) 
		ldr		r12, addr_f
		ldr		r10, addr_g
		ldr		r12, [r12]		  			@ r12<-f 
		ldr		r10, [r10]					@ r10<-g 
		and		r7, r11, r12				@ r7=e AND f 
		mvn		r11, r11					@ r11=NOT(e) 
		and		r8, r11, r10				@ r8=NOT(e) AND g 
		eor		r7, r7, r8					@ r7=(e and f) xor ((not e) and g) 
		
@r8= temp1:= m + r6 + r7 + k[i] + message[i] 
		ldr 	r10, addr_m				
		ldr 	r10, [r10]					@ r10<-m 
		add 	r8, r10, r6					@ r8=m+r6 
		add 	r8, r8, r7					@ r8=m+r6+r7 
		ldr 	r10, addr_k					
		ldr 	r10, [r10, r0, lsl #W_SHIFT]@ r10<-k[i] 
		add 	r8, r8, r10					@ r8= m+r6+r7+k[i] 	
		ldr 	r10, addr_message			
		ldr 	r10, [r10, r0, lsl #W_SHIFT]@ r10<-message[i] 	
		add 	r8, r8, r10					@ r8=m + r6 + r7 + k[i] + message[i] 
											
		mov 	r0, r8						@ r0 = temp1 (output) 				
				
		pop 	{r5, r6, r7, r8, r9, r10, r11, r12}
		bx 	lr

@ makeTemp2
@ Computes temp2:
@	S0 := (a rightrotate 2) xor (a rightrotate 13) xor (a rightrotate 22)
@  maj := (a and b) xor (a and c) xor (b and c)
@  temp2 := S0 + maj
@
@ Calling sequence:
@ 		bl makeTemp2
@ OUTPUT:
@ r0= temp2	  
makeTemp2:
		push {r5, r6, r7, r8, r9, r10, r11, r12}

@r6 =S0 := (a rightrotate 2) xor (a rightrotate 13) xor (a rightrotate 22) 
		ldr		r5, addr_a				
		ldr		r5, [r5]					@ r5<-a 
		ror		r6, r5, #2					@ r6=ror(a, 2) 
		ror		r7, r5, #13					@ r7=ror(a, 13) 
		eor		r6, r6, r7					@ r6=ror(a, 2) XOR ror(a, 13) 
		ror		r7, r5, #22					@ r7=ror(a, 22) 
		eor		r6, r6, r7					@ r6=s0  

@r7 =maj:= (a and b) xor (a and c) xor (b and c) 
		ldr		r8, addr_b
		ldr		r10, addr_c
		ldr		r8, [r8]					@ r8<-b 
		ldr		r10, [r10]					@ r10<-c 
		and		r7, r5, r8					@ r7=a AND b  
		and		r11, r5, r10				@ r11=a AND c  
		eor 	r7, r7, r11					@ r7=(a AND b) XOR (a AND c) 
		and 	r11, r8, r10				@ r11=b AND c 
		eor 	r7, r7, r11					@ r7=(a AND b) XOR (a AND c) XOR (b AND c) 

@ r0 = temp2 := S0 + maj				
		add 	r0, r6, r7					@ output 
				
		pop 	{r5, r6, r7, r8, r9, r10, r11, r12}
		bx lr

@ updateAlphabeth
@ Updates the alphabeth (the working variables):
@ m := g
@ g := f
@ f := e
@ e := d + temp1
@ d := c
@ c := b
@ b := a
@ a := temp1 + temp2
@
@ Calling sequence
@ 		r0 <- temp1
@ 		r1 <- temp2
@		bl updateAlphabeth
updateAlphabeth:
		push {r5, r6, r7, lr}

		mov 	r5, r0						@ r5=temp1 
		mov 	r6, r1						@ r6=temp2 

@m=g 
		ldr 	r0, addr_m					@ working variable m address, paramter for updateLetter 			
		ldr 	r1, addr_g					@ wordking variable g address, paramter for updateLetter 
		bl 		updateLetter
		
@g=f 
		ldr 	r0, addr_g					
		ldr 	r1, addr_f		
		bl 		updateLetter
			
@f=e 
		ldr 	r0, addr_f					
		ldr 	r1, addr_e		
		bl 		updateLetter	
			
@e=d+temp1 
		ldr 	r0, addr_e					
		ldr 	r1, addr_d		
		bl 		updateLetter				@ e=d 
		ldr 	r8, addr_e
		ldr 	r7, [r8]					@ r7=e 
		add 	r7, r7, r5					@ r7+=temp1 
		str 	r7, [r8]					@ r7->e 

@d=c 
		ldr 	r0, addr_d					
		ldr 	r1, addr_c		
		bl 		updateLetter			

@c=b 
		ldr 	r0, addr_c				
		ldr 	r1, addr_b		
		bl 		updateLetter	
			
@b=a 
		ldr 	r0, addr_b					
		ldr 	r1, addr_a		
		bl 		updateLetter		
			
@a= temp1+temp2 
		add 	r5,r5,r6
		ldr 	r6, addr_a
		str 	r5, [r6]					@ a=temp1+temp2 
				
		pop 	{r5, r6, r7, lr}
		bx 		lr

@ updateLetter
@ Assigns to a working variable the value of another one
@ letter1:= letter2
@ 
@ Calling sequence 
@ r0 = address(letter1)
@ r1 = address(letter2)	    
updateLetter:
		ldr		r1, [r1]					@ r1<-letter2 
		str		r1, [r0]					@ letter2->letter1 
	
		bx		lr

@ updateHash
@ Updates the values of the hash adding the current values of the working variables:
@  h[0]+=a
@  h[1]+=b
@  ...
@  h[7]+=m
@
@ Calling sequence:
@		bl updateHash
updateHash:
		push {r5, lr}

@h[0]+=a 
		mov 	r0, #0						@ r0=index 
		ldr 	r1, addr_a					@ r1=address of working variable a 
		bl 		updateH

@h[1]+=b 
		mov 	r0, #1		
		ldr 	r1, addr_b	
		bl 		updateH

@h[2]+=c 
		mov 	r0, #2	
		ldr 	r1, addr_c	
		bl 		updateH
		
@h[3]+=d 
		mov 	r0, #3		
		ldr 	r1, addr_d	
		bl 		updateH

@h[4]+=e 
		mov 	r0, #4		
		ldr 	r1, addr_e	
		bl 		updateH

@h[5]+=f 
		mov 	r0, #5		
		ldr 	r1, addr_f	
		bl 		updateH

@h[6]+=g 
		mov 	r0, #6		
		ldr 	r1, addr_g	
		bl 		updateH

@h[7]+=m 	
		mov 	r0, #7		
		ldr 	r1, addr_m	
		bl 		updateH

		pop 	{r5, lr}
		bx 		lr

@ updateH
@ Updates the value of hash[i] adding to it the value of a working variable.
@ (Overflows are ignored).
@ hash[i]+=letter
@ 
@ Calling sequence:
@ 		r0<-i
@		r1 = address(letter)
@		bl updateH
updateH:
		push	{r5, r6}
		ldr 	r5, addr_hash
		ldr 	r1, [r1] 					@ r1<-letter 
		ldr 	r6, [r5, r0, lsl #W_SHIFT] 	@ r6<-hash[i] 
		add 	r6, r6, r1					@ r6=hash[i]+letter 
		str 	r6,[r5, r0, lsl #W_SHIFT]	@ hash[i]+letter->hash[i] 
		pop		{r5, r6}
		bx 		lr
		
		.balign WORD

addr_hash: .word hash
addr_k: .word k
addr_message: .word message
addr_a: .word a
addr_b: .word b
addr_c: .word c
addr_d: .word d
addr_e: .word e
addr_f: .word f
addr_g: .word g
addr_m: .word m
ptr_addr_input: .word addr_input
addr_input_length: .word input_length
