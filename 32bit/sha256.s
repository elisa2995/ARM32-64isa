/** -- sha256 --*/

.data
.equ WORD,4
.equ PRD_LENGTH_W, 16 /*words(512 bits)*/
.equ PRD_BYTES, PRD_LENGTH_W*WORD
/*.equ INPUT_LENGTH_B, 8 /*byte*/
/*.equ INPUT_LENGTH_W, 2*/
.equ INPUT_LENGTH_B, 0
.equ INPUT_LENGTH_W, 0
.balign 4
hash: .word 0x6a09e667,0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
string: .asciz "ciao \n"
.balign 4
k: .word    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147,0x06ca6351, 0x14292967,0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a,0x5b9cca4f, 0x682e6ff3,0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2

/*input_b: .byte 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30
input_w: .word 0,0	 */
input_b: .byte 0x0
input_w: .word 0 
addr_input: .word 0	 
input_length: .word 0
processed: .word 0, 0, 10, 10,0, 0, 10, 10,0, 0, 10, 10,0, 0, 10, 10
message: .word   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
a: .word 0
b: .word 0
c: .word 0
d: .word 0
e: .word 0
f: .word 0
g: .word 0
m: .word 0
   
.text
.global mainAsm
.global printf

/*
 * PARAMS:
 * r0=address(input)
 * r1=length(input)	
*/
mainAsm:
	push {lr}

	ldr r2, ptr_addr_input		 		
	str r0, [r2]						/*r0=address(input)->addr_input*/
	ldr r2, addr_input_length
	str r1, [r2]						/*r1=length(input)->input_length*/
bp1:
	bl parse
bp:		
	/*PREPROSSING*/
	bl preprocess
	bl startPadding
	bl fillEnd
	
	/*COMPRESSION*/
	bl processChunks

	ldr r0, addr_string
	/*bl printf	 */
	
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

		ldr r5, addr_input_length
		ldr r7, ptr_addr_input
		ldr r7, [r7]					/*r7<- [input]*/
		ldr r5, [r5]				  	/*r5<-input_length*/

		ands r5, r5, #0b00000011		/*r5=input_length MOD 4 */
		beq end_parse
		rsb r6, r5, #3					/*r6= (3-#input_length MOD 4)index of the byte in the word from which to insert 0*/
		lsl r6, #3						/*r6=r6*8, number of left shifts of 0b00000000*/
		ldr r8, [r7, r5, lsl #2]

		mov r10, #0xFFFFFF00			/*r10=mask*/
		lsl r10, r6						/*lsl of the mask(ex input_length=6=>mask=0xFFFF0000)*/
		and r8, r8,r10					/*apply the mask*/
		str r8, [r7, r5, lsl #2]		
	



/*		movs r5, #INPUT_LENGTH_B		/*if INPUT_LENGTH_B==0 end*/
/*		beq break_prs 

 		ldr r6, addr_input_b			/*r6->input_b*/
/* 		ldr r8, addr_input_w			/*r8->input_w*/
// 		mov r5,#0						/*r5=counter i*/
// 		mov r7,#0						/*r7=counter j*/
//loop_prs_i:
// 		mov r11,#0						/*r11 holds the 4 byte chunk from input*/
// 		mov r7, #0						/*j=0*/
//loop_prs_j:
// 		add r9, r7, r5, lsl #2			/*r9<- j+i*WORD*/
// 		cmp r9, #INPUT_LENGTH_B			/*if j+i*WORD == INPUT_LENGTH_B*/
// 		beq end_prs						/*END*/
// 		ldrb r10, [r6, r9]				/*r10<-input_b[j+i*WORD]*/
// 			
// 		rsb r9, r7, #WORD-1				/*r9<-WORD-1-j*/		 
// 		lsl r9,#3						/*r9<-(WORD-1-j)*8*/	
// 		lsl r10, r9	
// 		orr r11,r10						/*r11(byte j)=INPUT[j+i*4]*/	
// 				 
// 		add r7,r7, #1
// 		cmp r7, #WORD
// 		blt loop_prs_j
// 		/*end loop_prs_j*/
//end_prs:
// 		str r11, [r8,r5, lsl #2]
// 		add r5,r5,#1
// 		cmp r5, #INPUT_LENGTH_W
// 		blt loop_prs_i
// /*end loop_prs_i*/	
//break_prs:
end_parse: 		pop {r5, r6, r7, r8, r9, r10, r11, r12}
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
		ldr r6, addr_input_w 			/*r6->input*/
		ldr r8, addr_processed 			/*r8->processed*/
		mov r5,#0 						/*r5=counter*/
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
		ldr r8, addr_processed 			/*r8->processed*/
		mov r7, #INPUT_LENGTH_B+1		/*r7<- length in byte of input + 0b10000000*/		
		lsr r7,#2						/*r7<- index of the word that we have to modify (from left to right)*/

		mov r5, #INPUT_LENGTH_B 		
		and r5, #0b00000011				/*r5= #INPUT_LENGTH_B MOD 4*/
		rsb r5, r5, #3					/*r5= (3-#INPUT_LENGTH_B MOD 4)index of the byte in the word that has to be modified*/	
		lsl r5,#3						/*r5<- r5*8, number of left shifts of 0b10000000*/

		ldr r9,[r8,r7, lsl #2]			/*Load the word that has to be modified*/		
		mov r6,#0x00000080		
		lsl r6, r5						/*Positioning the 0x10 the right position*/	
		orr r9,r6						/*Insert the 1*/
		str r9,[r8,r7, lsl #2]			/*Store the modified value*/

		pop {r5, r6, r7, r8, r9, r10}
		bx lr
		
/*
 * fillEnd 
 * Copy the length of input_w expressed as 64 bit big endian 
 * 
*/
fillEnd:
		push {r5, r6, r7, r8}

		ldr r6, addr_processed
		mov r5, #INPUT_LENGTH_B				
		cmp r5, #0x1FFFFFFF					/*if the length in bits exceeds a word */
		lsrgt r7, r5, #29					/*r7<-3 most significant bits of INPUT_LENGTH_B*8(bits)*/
		strgt r7,[r6, #14*4]				/*r7->processed[14] */
		lsl r7, r5, #3						/*r7= 32 less significant bits of INPUT_LENGTH_B*8(bits)*/
		str r7, [r6, #15*4]					/*r7->processed[15]*/
		
		pop {r5, r6, r7, r8}
		bx lr

/*
 * processChunks
 * For each chuck(16 words) in which we can divide processed we do functions:
 * 
*/
processChunks:
			push {r0, r5, r6, lr}
			mov r5, #0					/* r5 counter*/
					
loop_pChs:	
			mov r0, r5, lsl #2			/*r0=chunck offset in processed */ 			
			bl copyProcessed

			bl fillMessage	
			bl initAlphabeth
			bl compress
			bl updateHash
			
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
			
			ldr r6, addr_message
			ldr r7, addr_processed 		/*r7=base address of processed*/
			add r0, r0, r7				/*r0=chunk address*/	
			
			mov r5,#0					/*r5 counter*/
loop_pCh:   
			ldr r7,[r0,r5, lsl #2]		/*r7<-chunk[i]*/
			str r7,[r6,r5, lsl #2]		/*message[i]=chunck[i]*/	
			add r5,r5,#1
			cmp r5, #16
			bne loop_pCh
bp2:			
			pop {r5, r6, r7, r8}
			bx lr
			

/*
 * fillMessage
 * We complete the values message[16-63] with values calculated as follows
 *  s0 := (w[i-15] rightrotate 7) xor (w[i-15] rightrotate 18) xor (w[i-15] rightshift 3)
 *  s1 := (w[i-2] rightrotate 17) xor (w[i-2] rightrotate 19) xor (w[i-2] rightshift 10)
 *  w[i] := w[i-16] + s0 + w[i-7] + s1 	
 *(w=message)
*/
fillMessage:

			push {r5, r6, r7, r8, r9, r10, r11, r12}
			mov r5, #16					/*r5 = i 16:63 (end of message)*/
			ldr r6, addr_message		
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
			
			add r9, r9, r10				/*r9=s0+s1*/
			
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

/*initAlphabeth
 *Initializes the letters a to  with hash values (a=hash[0], b=hash[1]....)
 * 
*/
initAlphabeth:
			push {r0, r1, r5, lr}
						
			ldr r0, addr_a
			mov r1, #0
			bl initLetter	
			
			ldr r0, addr_b
			mov r1, #1
			bl initLetter
			
			ldr r0, addr_c
			mov r1, #2
			bl initLetter	
			
			ldr r0, addr_d
			mov r1, #3
			bl initLetter
			
			ldr r0, addr_e
			mov r1, #4
			bl initLetter
			
			ldr r0, addr_f
			mov r1, #5
			bl initLetter
			
			ldr r0, addr_g
			mov r1, #6
			bl initLetter
			
			ldr r0, addr_m
			mov r1, #7
			bl initLetter	
			
			pop {r0, r1, r5, lr}
			bx lr
			
/*initLetter
 *
 *PARAMS:
 *r0<-letter address
 *r1<-index of the hash value (i)
*/
initLetter:
			push {r5,r6}
			
			ldr r6, addr_hash			/*r6<-hash[0]*/
			ldr r5, [r6, r1, lsl #2]	/*r5<-hash[i]*/
			str r5, [r0]				/*letter<-hash[i]*/
			
			pop {r5,r6}
			bx lr

/*compress
 *Compression function main loop:
 *   for i from 0 to 63
 *       S1 := (e rightrotate 6) xor (e rightrotate 11) xor (e rightrotate 25)
 *       ch := (e and f) xor ((not e) and g)
 *       temp1 := m + S1 + ch + k[i] + message[i]
 *       S0 := (a rightrotate 2) xor (a rightrotate 13) xor (a rightrotate 22)
 *       maj := (a and b) xor (a and c) xor (b and c)
 *       temp2 := S0 + maj
 * 
 *      h := g
 *      g := f
 *      f := e
 *      e := d + temp1
 *      d := c
 *      c := b
 *      b := a
 *      a := temp1 + temp2
 *
*/
compress:
			push {r0, r1, r5, r6, r7, lr}
			
			mov r5, #0					/*r5 counter*/
loop_cpr:	
			mov r0, r5					/*input for make_temp1*/ 
			bl make_temp1				/*r0<-temp1*/
			mov r6, r0					/*r6=temp1*/

			bl make_temp2				/*r0<-temp2*/
			mov r1, r0					/*r1<-temp2 input for updateAlphabeth*/

			mov r0, r6					/*r0<-temp1 input for updateAlphabeth*/
			bl updateAlphabeth

			/*counter update*/
			add r5,r5,#1
			cmp r5, #64
			blt loop_cpr
			
			
			pop {r0, r1, r5, r6, r7, lr}
			bx lr

/*make_temp1 
 * computes temp1:
 * S1 := (e rightrotate 6) xor (e rightrotate 11) xor (e rightrotate 25)
 * ch := (e and f) xor ((not e) and g)
 * temp1 := m + S1 + ch + k[i] + message[i]
 * PARAMS:
 * r0 = i;
 * OUTPUT:
 * r0 = temp1;
 *
*/
make_temp1:
			push {r5, r6, r7, r8, r9, r10, r11, r12}	
			/*r6 := (e rightrotate 6) xor (e rightrotate 11) xor (e rightrotate 25)*/	
			ldr r11, addr_e
			ldr r11, [r11]				/*r11<-e*/
			ror r6, r11, #6				/*r6=ror(e,6)*/
			ror r7, r11, #11			/*r7=ror(e,11)*/
			eor r6, r6, r7				/*r6=ror(e,6) XOR ror(e,11)*/
			ror r7,r11, #25				/*r7=ror(e, 25)*/
			eor r6,r6,r7				/*r6=ror(e,6) XOR ror(e,11)XOR ror(e,11)*/
			
			/*r7 := (e and f) xor ((not e) and g)*/
			ldr r12, addr_f
			ldr r10, addr_g
			ldr r12, [r12]		  		/*r12<-f*/
			ldr r10, [r10]				/*r10<-g*/
			and r7, r11, r12			/*r7=e AND f*/
			mvn r11, r11				/*r11=NOT(e)*/
			and r8, r11, r10			/*r8=NOT(e) AND g*/
			eor r7, r7, r8				/*r7=(e and f) xor ((not e) and g)*/

			/*r8:=m + r6 + r7 + k[i] + message[i]*/
			ldr r10, addr_m				
			ldr r10, [r10]				/*r10<-m*/
			add r8, r10, r6				/*r8=m+r6*/
			add r8, r8, r7				/*r8=m+r6+r7*/
			ldr r10, addr_k
			ldr r10, [r10, r0, lsl #2]	/*r10<-k[i]*/
			add r8, r8, r10				/*r8= m+r6+r7+k[i]*/	
			ldr r10, addr_message
			ldr r10, [r10, r0, lsl #2]	/*r10<-message[i]*/	
			add r8, r8, r10				/*r8=m + r6 + r7 + k[i] + message[i]*/
			
			mov r0, r8					/*r0 = temp1 (output)*/				

			pop {r5, r6, r7, r8, r9, r10, r11, r12}
			bx lr

/*make_temp2
 * computes temp2:
 *	S0 := (a rightrotate 2) xor (a rightrotate 13) xor (a rightrotate 22)
 *  maj := (a and b) xor (a and c) xor (b and c)
 *  temp2 := S0 + maj
 * OUTPUT:
 * r0= temp2
*/
make_temp2:
			push {r5, r6, r7, r8, r9, r10, r11, r12}

			/*r6 := (a rightrotate 2) xor (a rightrotate 13) xor (a rightrotate 22)*/
			ldr r5, addr_a				
			ldr r5, [r5]				/*r5<-a*/
			ror r6, r5, #2				/*r6=ror(a, 2)*/
			ror r7, r5, #13				/*r7=ror(a, 13)*/
			eor r6, r6, r7				/*r6=ror(a, 2) XOR ror(a, 13)*/
			ror r7, r5, #22				/*r7=ror(a, 22)*/
			eor r6, r6, r7				/*r6=s0*/ 

			/*r7 := (a and b) xor (a and c) xor (b and c)*/
			ldr r8, addr_b
			ldr r10, addr_c
			ldr r8, [r8]				/*r8<-b*/
			ldr r10, [r10]				/*r10<-c*/
			and r7, r5, r8				/*r7=a AND b*/ 
			and r11, r5, r10			/*r11=a AND c */
			eor r7, r7, r11				/*r7=(a AND b) XOR (a AND c)*/
			and r11, r8, r10			/*r11=b AND c*/
			eor r7, r7, r11				/*r7=(a AND b) XOR (a AND c) XOR (b AND c)*/
					
			add r0, r6, r7				/*r0=S0+maj, output*/
				
			pop {r5, r6, r7, r8, r9, r10, r11, r12}
			bx lr

/*updateAlphabeth
 * m := g
 * g := f
 * f := e
 * e := d + temp1
 * d := c
 * c := b
 * b := a
 * a := temp1 + temp2
 * PARAMS:
 * r0 = temp1
 * r1 = temp2
*/
updateAlphabeth:
			push {r5, r6, r7, r8, r9, lr}

			mov r5, r0			/*r5=temp1*/
			mov r6, r1			/*r6=temp2*/

			push {r0, r1}
brU:
			/*m=g*/
			ldr r0, addr_m		/*paramter for updateLetter*/			
			ldr r1, addr_g		/*paramter for updateLetter*/
			bl updateLetter
		
		    /*g=f*/
			ldr r0, addr_g					
			ldr r1, addr_f		
			bl updateLetter
			
			/*f=e*/
			ldr r0, addr_f					
			ldr r1, addr_e		
			bl updateLetter	
			
			/*e=d+temp1*/
			ldr r0, addr_e					
			ldr r1, addr_d		
			bl updateLetter		/*e=d*/			
			ldr r7, [r0]		/*r7=e*/
			add r7, r7, r5		/*r7+=temp1*/
			str r7, [r0]		/*r7->e*/

			/*d=c*/
			ldr r0, addr_d					
			ldr r1, addr_c		
			bl updateLetter			

			/*c=b*/
			ldr r0, addr_c				
			ldr r1, addr_b		
			bl updateLetter	
			
			/*b=a*/
			ldr r0, addr_b					
			ldr r1, addr_a		
			bl updateLetter		
			
			/*a= temp1+temp2*/
			add r5,r5,r6
			ldr r1, addr_a
			str r5, [r1]		/*a=temp1+temp2*/
				

			pop {r0, r1}

			pop {r5, r6, r7, r8, r9, lr}
			bx lr

/* updateLetter
* assigns to a letter the value of another letter
* letter1:= letter2
* PARAMS:
* r0 = address(letter1)
* r1 = address(letter2)
*/
updateLetter:
			ldr r1, [r1]		/*r1<-letter2*/
			str r1, [r0]		/*letter2->letter1*/
			
			bx lr

/*updateHash
*  h[0]+=a
*  h[1]+=b
*  ...
*/	  
updateHash:
			push {r0, r1, r5, lr}

			/*h[0]+=a*/
			mov r0, #0		/*r0=index*/
			ldr r1, addr_a	/*r1=address of a*/
			bl updateH

			/*h[1]+=b*/
			add r0, r0, #1		
			ldr r1, addr_b	
			bl updateH

			/*h[2]+=c*/
			add r0, r0, #1		
			ldr r1, addr_c	
			bl updateH

			/*h[3]+=d*/
			add r0, r0, #1		
			ldr r1, addr_d	
			bl updateH

			/*h[4]+=e*/
			add r0, r0, #1		
			ldr r1, addr_e	
			bl updateH

			/*h[5]+=f*/
			add r0, r0, #1		
			ldr r1, addr_f	
			bl updateH

			/*h[6]+=g*/
			add r0, r0, #1		
			ldr r1, addr_g	
			bl updateH

			/*h[7]+=m*/	
			add r0, r0, #1		
			ldr r1, addr_m	
			bl updateH

			pop {r0, r1, r5, lr}
			bx lr

/*updateH
 * h[i]+=letter
 * PARAMS:
 * r0=i
 * r1=address(letter)
*/
updateH:
			push {r5, r6}
			ldr r5, addr_hash
			ldr r1, [r1] 				/*r1<-letter*/
			ldr r6, [r5, r0, lsl #2] 	/*r6<-hash[i]*/
			add r6, r6, r1				/*r6=hash[i]+letter*/
			str r6,[r5, r0, lsl #2]		/*hash[i]+letter->hash[i]*/
			pop {r5, r6}
			bx lr

addr_hash: .word hash
addr_k: .word k
addr_input_b: .word input_b
addr_input_w: .word input_w
addr_processed: .word processed
addr_message: .word message
addr_a: .word a
addr_b: .word b
addr_c: .word c
addr_d: .word d
addr_e: .word e
addr_f: .word f
addr_g: .word g
addr_m: .word m
addr_string: .word string
ptr_addr_input: .word addr_input
addr_input_length: .word input_length