/** -- sha256 --*/

.data
.equ WORD,4
.equ PRD_LENGTH, 64
.equ PRD_BYTES, PRD_LENGTH*WORD
.equ INPUT_LENGTH_B, 5 /*byte*/
.equ INPUT_LENGTH_W, 2
.balign 4
h: .word 0x6a09e667,0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
.balign 4
k: .word    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147,0x06ca6351, 0x14292967,0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a,0x5b9cca4f, 0x682e6ff3,0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2

input_b: .byte 0x01, 0x02,0x03,0x04,0x05
input_w: .word 0,0
processed: .word 0, 0, 10, 10,0, 0, 10, 10,0, 0, 10, 10,0, 0, 10, 10, 0, 0, 10, 10,0, 0, 10, 10,0, 0, 10, 10,0, 0, 10, 10, 0, 0, 10, 10,0, 0, 10, 10,0, 0, 10, 10,0, 0, 10, 10,0, 0, 10, 10,0, 0, 10, 10,0, 0, 10, 10,0, 0, 10, 10

   
.text
.global main

main:
	push {lr}
	bl parse	
breakpoint:
	bl preprocess

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
bpr10: 			
 		rsb r9, r7, #WORD-1		/*r9<-WORD-j*/		 
 		lsl r9,#3			/*r9<-(WORD-j)*8*/	
 		lsl r10, r9	
 		orr r11,r10			/*r11(byte j)=INPUT[j+i*4]*/	
bpr11: 				 
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
 * I copy the content of input into processed putting 0s after its end
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
		mov r5,#0 			/*r5=counter*/
loop_PP:					
		cmp r5, #INPUT_LENGTH_W
		ldrlt r7,[r6,r5] 		/*if i<input.length r7<-input[i]*/
		movge r7,#0 			/*else r7<-0*/
		str r7,[r8,r5] 			/*processed[i]<-r7 ; i++*/	
		add r5, r5, #WORD
		mov r7, #PRD_BYTES
		cmp r5, r7
		blt loop_PP			/*if i<process.length, next loop*/
		
		pop {r5,r6,r7,r8}
		bx lr				/*return*/
	

addr_h: .word h
addr_k: .word k
addr_input_b: .word input_b
addr_input_w: .word input_w
addr_processed: .word processed