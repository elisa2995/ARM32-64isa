/** -- sha256 --*/

.data
.equ WORD,4
.equ PRD_LENGTH_W, 16 /*words(512 bits)*/
.equ PRD_BYTES, PRD_LENGTH_W*WORD
.equ INPUT_LENGTH_B, 5 /*byte*/
.equ INPUT_LENGTH_W, 2
.balign 4
h: .word 0x6a09e667,0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
.balign 4
k: .word    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147,0x06ca6351, 0x14292967,0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a,0x5b9cca4f, 0x682e6ff3,0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2

input_b: .byte 0x01, 0x02,0x03,0x04, 0x05
input_w: .word 0,0
processed: .word 0, 0, 10, 10,0, 0, 10, 10,0, 0, 10, 10,0, 0, 10, 10
message: .word   0, 0,0, 0,0, 0,0, 0,  0, 0,0, 0,0, 0,0, 0,  0, 0,0, 0,0, 0,0, 0,  0, 0,0, 0,0, 0,0, 0,  0, 0,0, 0,0, 0,0, 0,  0, 0,0, 0,0, 0,0, 0,  0, 0,0, 0,0, 0,0, 0
s0: .word 0
s1: .word 0
a: .word 0
b: .word 0
c: .word 0
d: .word 0
e: .word 0
f: .word 0
g: .word 0
m: .word 0
   
.text
.global main

main:
	push {lr}
	bl parse
		
	/*PREPROSSING*/
	bl preprocess
	bl startPadding
	bl fillEnd
	
	/*COMPRESSION*/
	
	bl processChunks
	
breakpoint:
	pop {lr}
	bx lr
	
/* parse
 * Parses a string (array of char - 1 byte) into an array of words (4 bytes)
 * adding 0 at the end (if necessary).
 * (We assume that the word array is initialized to 0s)
 * for(int i=0; i<INPUT_LENGTH_W; i++){
 *	for(int j=0; j<WORD; j++){
 *		if(j+i*WORD==INPUT_LENGTH_B){
 *			break;
 *		}
 * 		r10+=lsl(input[j+i*WORD],(WORD-j-1)*8)
 *	}
 *	input_w[i]=r10;
 * }
 */
 parse:	
 		push {r5, r6, r7, r8, r9, r10, r11, r12}
 		ldr r6, addr_input_b			/*r6->input_b*/
 		ldr r8, addr_input_w			/*r8->input_w*/
 		mov r5,#0				/*r5=counter i*/
 		mov r7,#0				/*r7=counter j*/
loop_prs_i:
 		mov r11,#0				/*r11 holds the 4 byte chunk from input*/
 		mov r7, #0				/*j=0*/
loop_prs_j:
 		add r9, r7, r5, lsl #2		/*r9<- j+i*WORD*/
 		cmp r9, #INPUT_LENGTH_B		/*if j+i*WORD == INPUT_LENGTH_B*/
 		beq end_prs			/*END*/
 		ldrb r10, [r6, r9]		/*r10<-input_b[j+i*WORD]*/
 			
 		rsb r9, r7, #WORD-1		/*r9<-WORD-j*/		 
 		lsl r9,#3			/*r9<-(WORD-j)*8*/	
 		lsl r10, r9	
 		orr r11,r10			/*r11(byte j)=INPUT[j+i*4]*/	
 				 
 		add r7,r7, #1
 		cmp r7, #WORD
 		blt loop_prs_j
 		/*end loop_prs_j*/
end_prs:
 		str r11, [r8,r5, lsl #2]
 		add r5,r5,#1
 		cmp r5, #INPUT_LENGTH_W
 		blt loop_prs_i
 /*end loop_prs_i*/	
 		pop {r5, r6, r7, r8, r9, r10, r11, r12}
 		bx lr

	
/* preprocess
 * I copy the content of input into processed putting 0s after its end and I add 1
 * after it.
 * for(int i=0; i<processed.length;i++){
 *	if(i<input.length){
 *		processed[i]=input[i];
 *	}else{
 *		processed[i]=0;
 *	}
 *} 
 */	
preprocess:	
		push {r5,r6,r7,r8} 
		ldr r6, addr_input_w 		/*r6->input*/
		ldr r8, addr_processed 		/*r8->processed*/
		mov r5,#0 					/*r5=counter*/
loop_PP:					
		cmp r5, #INPUT_LENGTH_W
		ldrlt r7,[r6,r5, lsl #2] 		/*if i<input.length r7<-input[i]*/
		movge r7,#0 					/*else r7<-0*/
		str r7,[r8,r5, lsl #2] 			/*processed[i]<-r7 ; i++*/	
		add r5, r5, #1
		cmp r5, #PRD_LENGTH_W
		blt loop_PP						/*if i<process.length, next loop*/
			
		pop {r5,r6,r7,r8}
		bx lr							/*return*/

/*
 * startPadding
 * Add 1 at the start of the padding
 * processed(byte INPUT_LENGTH_B)=0x10
 *
*/
startPadding:	
		
		push {r5, r6, r7, r8, r9, r10}
		ldr r8, addr_processed 		/*r8->processed*/
		mov r7, #INPUT_LENGTH_B+1				
		lsr r7,#2						/*r7<- index of the word that we have to modify*/
		mov r5, #INPUT_LENGTH_B 		
		and r5, #0x3					/*r5<- index of the byte in the word that has to be modified(r5 = #INPUT_LENGTH_B MOD 4)*/
		lsl r5,#3						/*r5<- number of right shifts */
		ldr r9,[r8,r7, lsl #2]			/*Load the word that has to be modified*/
		
		mov r6,#0x10000000		
		lsr r6, r5						/*Positioning the 1 in the right position*/	
		orr r9,r6						/*Insert the 1*/
		str r9,[r8,r7, lsl #2]			/*Store the modified value*/
		pop {r5, r6, r7, r8, r9, r10}
		bx lr
		
/*
 * fillEnd 
 * Copy the first 2 words of input_w into the last 2 words of processed
 * if(input_w.length>0){
 * 		processed[14]=input_w[0];
 * 		if(input_w.length>1){
 * 			processed[15]=input_w[1];
 * 		}		
 * }
 *
*/
fillEnd:
		push {r5, r6, r7, r8}
		movs r5, #INPUT_LENGTH_W			/*if #INPUT_LENGTH_B!=0*/
		ldrne r6, addr_input_w	
		ldrne r8, addr_processed	
		ldrne r7,[r6]						/*r7<-input[0]*/
		strne r7,[r8, #14*4]				/*processed[14]=input_w[0]*/
		cmpne r5, #1						/*if #INPUT_LENGTH_B!=1*/	
		ldrne r7,[r6,#4]					/*r7<-input[1]*/
		strne r7,[r8, #15*4]				/*processed[15]=input_w[1]*/
			
		pop {r5, r6, r7, r8}
		bx lr

/*
 * processChunks
 * For each chuck(16 words) in which we can divide processed we do functions:
 * 
 *
 *
*/
processChunks:
			push {r0, r5, r6, lr}
			mov r5, #0					/* r5 counter*/
					
			
loop_pChs:	
			mov r0, r5, lsl #2			/*r0=chunck offset in processed */
			bl copyProcessed
			bl fillMessage	
			
			add r5,r5,#16				
			cmp r5, #PRD_LENGTH_W		
			blt loop_pChs				/*if there are still chunks*/
			
			pop {r0, r5, r6, lr}
			bx lr

/*
 * copyProcessed
 * Copy in the first 16 words of message the words of chunck
 *
 * PARAM: r0=chunk offset in processed 
*/		
copyProcessed:
			push {r5, r6, r7, r8}
			
			ldr r7, addr_processed 
			add r0, r0, r7			/*r0=chunk address*/	
			
			mov r5,#0				/*r5 counter*/
			ldr r6, addr_message


loop_pCh:   
			ldr r7,[r0,r5, lsl #2]		/*r7<-chunk[i]*/
			str r7,[r6,r5, lsl #2]		/*message[i]=chunck[i]*/	
			add r5,r5,#1
			cmp r5, #16
			bne loop_pCh
			
			pop {r5, r6, r7, r8}
			bx lr
			

/*
 * fillMessage
 * We complete the values message[16-63] with values calculated as follows
 *  s0 := (w[i-15] rightrotate 7) xor (w[i-15] rightrotate 18) xor (w[i-15] rightshift 3)
 *  s1 := (w[i-2] rightrotate 17) xor (w[i-2] rightrotate 19) xor (w[i-2] rightshift 10)
 *  w[i] := w[i-16] + s0 + w[i-7] + s1 	
*/
fillMessage:

			push {r5, r6, r7, r8, r9, r10, r11, r12}
			mov r5, #16					/*r5 = i (starts from the end of the chunk and goes to the end of message)*/
			ldr r6, addr_message		/*w=message*/
loop_fm:	
			/*r8 <- w[i-15]*/
			sub r7, r5, #15				/*r7= i-15*/
			ldr r8, [r6, r7, lsl #2]	/*r8 <- w[i-15]*/			
			
			/*r9=s0*/
			ror r9, r8, #7				/*r9=ror(w[i-15],7)*/	
			ror r10, r8, #18			/*r10=ror(w[i-15],18)*/	
			eor r9,r9,r10				/*r9=r9 XOR r10*/
			lsr r10, r8, #3				/*r10=lsr(w[i-15],3)*/
			eor r9,r9,r10				/*r9=r9 XOR r10*/
			
			/*r8 <- w[i-2]*/
			sub r7, r5, #2				/*r7= i-2*/
			ldr r8, [r6, r7, lsl #2]	/*r8 <- w[i-2]*/	
			
			/*r10=s1*/
			ror r10, r8, #17			/*r10=ror(w[i-2],17)*/
			ror r11, r8, #19			/*r11=ror(w[i-2],19)*/	
			eor r10, r10,r11			/*r10=r10 XOR r11*/
			lsr r11, r8, #10			/*r11=lsr(w[i-2],10)*/
			eor r10, r10, r11			/*r10=r0 XOR r11*/
			
			/*r9=s0+s1*/
			add r9, r9, r10
			
			/*r8 <- w[i-16]*/
			sub r7, r5, #16				/*r7= i-16*/
			ldr r8, [r6, r7, lsl #2]	/*r8 <- w[i-16]*/
			
			add r9, r9, r8				/*r9=s0+s1+w[i-16]*/
			
			/*r8 <- w[i-7]*/
			sub r7, r5, #7				/*r7= i-7*/
			ldr r8, [r6, r7, lsl #2]	/*r8 <- w[i-7]*/			
			
			add r9, r9, r8				/*r9=s0+s1+w[i-16]+w[i-7]*/
			
			str r9, [r6, r5, lsl #2]	/*w[i]=s0+s1+w[i-16]+w[i-7]*/	
		
			/* counter update*/
			add r5,r5,#1				/*i++*/
			cmp r5, #64					
			blt loop_fm					/*if i<64 loop*/
			
			pop {r5, r6, r7, r8, r9, r10, r11, r12}
			bx lr
			

			
addr_h: .word h
addr_k: .word k
addr_input_b: .word input_b
addr_input_w: .word input_w
addr_processed: .word processed
addr_message: .word message
