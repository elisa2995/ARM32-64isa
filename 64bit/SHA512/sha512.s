/** -- sha 512 --*/
.data
.equ DWORD, 8
.equ DW_SHIFT, 3
.balign 8
hash: .dword 0x6a09e667f3bcc908, 0xbb67ae8584caa73b, 0x3c6ef372fe94f82b, 0xa54ff53a5f1d36f1,0x510e527fade682d1, 0x9b05688c2b3e6c1f, 0x1f83d9abfb41bd6b, 0x5be0cd19137e2179
.balign 8
k: .dword 0x428a2f98d728ae22, 0x7137449123ef65cd, 0xb5c0fbcfec4d3b2f, 0xe9b5dba58189dbbc, 0x3956c25bf348b538, 0x59f111f1b605d019, 0x923f82a4af194f9b, 0xab1c5ed5da6d8118, 0xd807aa98a3030242, 0x12835b0145706fbe, 0x243185be4ee4b28c, 0x550c7dc3d5ffb4e2, 0x72be5d74f27b896f, 0x80deb1fe3b1696b1, 0x9bdc06a725c71235,0xc19bf174cf692694, 0xe49b69c19ef14ad2, 0xefbe4786384f25e3, 0x0fc19dc68b8cd5b5, 0x240ca1cc77ac9c65, 0x2de92c6f592b0275, 0x4a7484aa6ea6e483, 0x5cb0a9dcbd41fbd4, 0x76f988da831153b5, 0x983e5152ee66dfab,0xa831c66d2db43210, 0xb00327c898fb213f, 0xbf597fc7beef0ee4, 0xc6e00bf33da88fc2, 0xd5a79147930aa725,  0x06ca6351e003826f, 0x142929670a0e6e70, 0x27b70a8546d22ffc, 0x2e1b21385c26c926, 0x4d2c6dfc5ac42aed, 0x53380d139d95b3df, 0x650a73548baf63de, 0x766a0abb3c77b2a8, 0x81c2c92e47edaee6, 0x92722c851482353b, 0xa2bfe8a14cf10364, 0xa81a664bbc423001, 0xc24b8b70d0f89791, 0xc76c51a30654be30, 0xd192e819d6ef5218, 0xd69906245565a910, 0xf40e35855771202a, 0x106aa07032bbd1b8, 0x19a4c116b8d2d0c8, 0x1e376c085141ab53, 0x2748774cdf8eeb99, 0x34b0bcb5e19b48a8, 0x391c0cb3c5c95a63, 0x4ed8aa4ae3418acb, 0x5b9cca4f7763e373, 0x682e6ff3d6b2b8a3, 0x748f82ee5defb2fc, 0x78a5636f43172f60, 0x84c87814a1f0ab72, 0x8cc702081a6439ec, 0x90befffa23631e28, 0xa4506cebde82bde9, 0xbef9a3f7b2c67915, 0xc67178f2e372532b, 0xca273eceea26619c, 0xd186b8c721c0c207, 0xeada7dd6cde0eb1e, 0xf57d4f7fee6ed178, 0x06f067aa72176fba, 0x0a637dc5a2c898a6, 0x113f9804bef90dae, 0x1b710b35131c471b, 0x28db77f523047d84, 0x32caab7b40c72493, 0x3c9ebe0a15c9bebc,0x431d67c49c100d4c, 0x4cc5d4becb3e42b6, 0x597f299cfc657e2a, 0x5fcb6fab3ad6faec, 0x6c44198c4a475817	
addr_input: .dword 0	 
input_length: .dword 0
message: .dword   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
a: .dword 0
b: .dword 0
c: .dword 0
d: .dword 0
e: .dword 0
f: .dword 0
g: .dword 0
m: .dword 0

tmpVar:	.dword 0		
	

.text
.globl mainAsm
.globl printHash
.globl puts

/*
* PARAMS:
* r0=address(input)
* r1=length(input)	
*/
mainAsm:
    stp x30, x29, [sp, #-16]!	/*push {lr, ...} $ */

    ldr x2, ptr_addr_input
    str x0, [x2]			/*w0=address(input)->addr_input*/
    ldr x2, addr_input_length
    str x1, [x2]			/*w1=length(input)->input_length*/

    /*PREPROSSING*/
    bl startPadding
    bl fillEnd
bp3:	
    /*COMPRESSION*/
    bl processChunks

    /*PRINT HASH*/
    ldr x0, addr_hash
    bl printHash


breakpoint:
    ldp x30, x29, [sp], #16		/*pop {lr, ...} $ */
    ret
/*
* startPadding
* Add 1 at the start of the padding
* processed(byte INPUT_LENGTH_B)=0x10
*		   
*/
startPadding:	

	ldr x11, ptr_addr_input 			
	ldr x11,[x11]			/*x11<-[input]*/

	ldr x8, addr_input_length
	ldr x8, [x8]			/*x8<-input_length*/
	add x10, x8,#1			/*x10<- length in byte of input + 0b10000000*/
	
	add x10, xzr, x10, lsr #DW_SHIFT		/*x10<- index of the dword that we have to modify (from left to right)*/
	
	
	and x8, x8, #0b00000111		/*x8= input_length MOD 8*/
	mov x13, #DWORD-1		/* $ rsb */
	sub x8, x13, x8			/*x8= (7-input_length MOD 4)index of the byte in the dword that has to be modified*/	
	lsl x8,x8, #3			/*x8<-x8*8, # of left shifts of 0b10000000*/

	ldr x12,[x11,x10, lsl #DW_SHIFT]/*Load the word that has to be modified*/
	
	mov x9,#0b10000000		
	lsl x9,x9, x8			/*Positioning the 0x10 the right position*/

	orr x12,x12, x9			/*Insert the 1*/
	str x12,[x11,x10, lsl #DW_SHIFT]/*Store the modified value*/

	ret

/*
 * fillEnd 
 * Copy the length of input_w expressed as 128 bit big endian 
 * 
*/
fillEnd:
	stp x30, x29, [sp, #-16]!	/*push {lr, ...} $ */

	bl total_length			/*x0<-nDWords(input)*/		
	
	ldr x9, ptr_addr_input
	ldr x9, [x9]  			/*x9<-[input]*/
	ldr x8, addr_input_length
	ldr x8,[x8]		 	/*x8<-input_length*/
	
	lsr x10, x8, #29		/*X10<-3 most significant bits of input_length*8(bits)*/
	sub x11, x0, #2				/*x11=nDWords(input)-2*/
	str x10,[x9, x11, lsl #DW_SHIFT]	/*x10->processed[nWords(input)-2] */
	
	lsl x10, x8, #3				/*x10= 64 less significant bits of input_length*8(bits)*/
	sub x11, x0, #1
	str x10, [x9, x11, lsl #DW_SHIFT]	/*x10->processed[nWords(input)-1]*/

	ldp x30, x29, [sp], #16		/*pop {lr, ...} $ */
	ret
	
/*
* processChunks
* For each chuck(16 dwords) in which we can divide processed we do functions:
* 
*/
processChunks:
	
	stp x30, x29, [sp, #-16]!/*push {lr, ...} $ */

	mov x8, #0		/* x8 counter*/
	bl total_length
	mov x9, x0		/*x9=number of dwords*/

loop_pChs:	
	mov x0, x8, lsl #DW_SHIFT /*x0=chunck offset in processed */
	stp x8, x9, [sp, #-16]!/*push {x8,x9} $ */
	
	bl copyProcessed
	bl fillMessage	
	bl initAlphabeth
	bl compress
	bl updateHash
	
	ldp x8, x9, [sp], #16	/*pop {x8,x9} $ */
	

	add x8,x8,#16	
	cmp x8, x9	
	blt loop_pChs		/*if there are still chunks*/

	
	ldp x30, x29, [sp], #16		/*pop {lr, ...} $ */	
	ret

/*total_length
* OUTPUT:
* r0=length in bytes of the processed word (a multiple of 128  bytes - 1024 bits)	
*/ 
total_length:

	ldr x0, addr_input_length
	ldr x0,[x0]			/*x0<-input_length*/
	add x0, x0, #17			/*17 bytes= 16 bytes for the length of the word in bits+ 1 byte of padding*/

	/*x0=floor(input_length-17)/128*/
	sub x0, x0, #1			/*x0=x0-1, necessary to compute the floor of the division*/
	lsr x0, x0, #7			/*x0=x0/128, 128  bytes = 1024 bits*/

	/*x0=x0*128+128*/
	lsl x0, x0, #7					
	add x0, x0, #128	

	lsr x0, x0, #3			/*x0=x0/8 from bytes to dwords*/
tl:	
	ret

/*						
 * copyProcessed
 * Copy in the first 16 dwords of message the words of chunck
 *
 * PARAM: x0=chunk offset in processed 
*/		
copyProcessed:	
			
	ldr x9, addr_message
	
	ldr x10, ptr_addr_input 		
	ldr x10, [x10]				/*x10=base address of processed*/
	add x0, x0, x10				/*x0=chunk address*/	
			
	mov x8,#0				/*x8 counter*/
loop_pCh:   
	ldr x10,[x0,x8, lsl #DW_SHIFT]		/*x10<-chunk[i]*/
	str x10,[x9,x8, lsl #DW_SHIFT]		/*message[i]=chunck[i]*/	
	add x8, x8,#1
	cmp x8, #16
	bne loop_pCh
	ret

/*
 * fillMessage
 * We complete the values message[16-79] with values calculated as follows
 *  s0 := (w[i-15] rightrotate 1) xor (w[i-15] rightrotate 8) xor (w[i-15] rightshift 7)
 *  s1 := (w[i-2] rightrotate 19) xor (w[i-2] rightrotate 61) xor (w[i-2] rightshift 6)
 *  w[i] := w[i-16] + s0 + w[i-7] + s1 	
 *(w=message)
*/
fillMessage:

		
	mov x8, #16			/*x8 = i 16:79 (end of message)*/
	ldr x9, addr_message		
loop_fm:	
	/*x11 <- w[i-15]*/
	sub x10, x8, #15			/*x10= i-15*/
	ldr x11, [x9, x10, lsl #DW_SHIFT]	/*X11 <- w[i-15]*/		
			
	/*x12=s0*/
	ror x12, x11, #1		/*x12=ror(w[i-15],1)*/	
	ror x13, x11, #8		/*x13=ror(w[i-15],8)*/	
	eor x12, x12,x13		/*x12=x12 XOR x13*/
	lsr x13, x11, #7		/*x13=lsr(w[i-15],7)*/
	eor x12,x12, x13		/*x12=x12 XOR x13*/

	/*x11 <-w[i-2]*/
	sub x10, x8, #2				/*x10=i-2*/
	ldr x11, [x9, x10, lsl #DW_SHIFT]	/*x11 <-w[i-2]*/
			
	/*x13=s1*/
	ror x13, x11, #19		/*x13=ror(w[i-2],19)*/
	ror x14, x11, #61		/*x14=ror(w[i-2],61)*/	
	eor x13, x13,x11		/*x13=x13 XOR x14*/
	lsr x14, x11, #6		/*x14=lsr(w[i-2],6)*/
	eor x13, x13, x11		/*x13=x13 XOR x14*/
	
			
	add x12, x12, x13		/*x12=s0+s1*/
			
	/*x11 <- w[i-16]*/
	sub x10, x8, #16		/*x10= i-16*/
	ldr x11, [x9, x10, lsl #DW_SHIFT]/*x11 <- w[i-16]*/
			
	add x12, x12, x11		/*x12=s0+s1+w[i-16]*/
			
	/*x11 <- w[i-7]*/
	sub x10, x8, #7			/*x10= i-7*/
	ldr x11, [x9, x10, lsl #DW_SHIFT]/*x11 <- w[i-7]*/			
			
	add x12, x12, x11		/*x12=s0+s1+w[i-16]+w[i-7]*/
			
	str x12, [x9, x8, lsl #DW_SHIFT]/*w[i]=s0+s1+w[i-16]+w[i-7]*/	
		
	/* counter update*/
	add x8, x8, #1			/*i++*/
	cmp x8, #80					
	blt loop_fm			/*if i<80 loop*/
				
	ret
	
/*initAlphabeth
 *Initializes the letters a to  with hash values (a=hash[0], b=hash[1]....)
 * 
*/
initAlphabeth:
	stp x30, x29, [sp, #-16]!	/*push {lr, ...} $ */
					
	ldr x0, addr_a
	mov x1, #0
	bl initLetter	
		
	ldr x0, addr_b
	mov x1, #1
	bl initLetter
		
	ldr x0, addr_c
	mov x1, #2
	bl initLetter	
		
	ldr x0, addr_d
	mov x1, #3
	bl initLetter
			
	ldr x0, addr_e
	mov x1, #4
	bl initLetter
	
	ldr x0, addr_f
	mov x1, #5
	bl initLetter
			
	ldr x0, addr_g
	mov x1, #6
	bl initLetter
			
	ldr x0, addr_m
	mov x1, #7
	bl initLetter
	
	ldp x30, x29, [sp], #16		/*push {lr, ...} $ */
	
	ret

/*initLetter
 *
 *PARAMS:
 *x0<-letter address
 *x1<-index of the hash value (i)
*/
initLetter:
			
	ldr x9, addr_hash			/*x9<-[hash]*/
	ldr x8, [x9, x1, lsl #DW_SHIFT]		/*x8<-hash[i]*/
	str x8, [x0]				/*letter<-hash[i]*/
	
	ret

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
	stp x30, x29, [sp, #-16]!	/*push {lr, ...} $ */
		
	mov x8, #0			/*x8 counter*/
loop_cpr:	
	mov x0, x8			/*input for make_temp1*/
	
	stp x8, x9, [sp, #-16]!		/*push {x8,x9} $ */
	bl make_temp1			/*x0<-temp1*/
	ldp x8, x9, [sp], #16		/*pop {x8,x9} $ */
	
	mov x9, x0			/*x9=temp1*/

	stp x8, x9, [sp, #-16]!		/*push {x8,x9} $ */
	bl make_temp2			/*x0<-temp2*/
	ldp x8, x9, [sp], #16		/*pop {x8,x9} $ */
	
	mov x1, x0			/*x1<-temp2 input for updateAlphabeth*/

	mov x0, x9			/*x0<-temp1 input for updateAlphabeth*/
	stp x8, x9, [sp, #-16]!		/*push {x8,x9} $ */
	bl updateAlphabeth
	ldp x8, x9, [sp], #16		/*pop {x8,x9} $ */
	/*counter update*/
	add x8, x8,#1
	cmp x8, #80
	blt loop_cpr
			
	ldp x30, x29, [sp], #16		/*push {lr, ...} $ */
	ret

/*make_temp1 
 * computes temp1:
 * S1 := (e rightrotate 14) xor (e rightrotate 18) xor (e rightrotate 41)
 * ch := (e and f) xor ((not e) and g)
 * temp1 := m + S1 + ch + k[i] + message[i]
 * PARAMS:
 * r0 = i;
 * OUTPUT:
 * r0 = temp1;
 *
*/
make_temp1:
	
	/*x9 := (e rightrotate 14) xor (e rightrotate 18) xor (e rightrotate 41)*/
	ldr x14, addr_e
	ldr x14, [x14]			/*x14<-e*/
	ror x9, x14, #14		/*x9=ror(e,14)*/
	ror x10, x14, #18		/*x10=ror(e,18)*/
	eor x9, x9, x10			/*x9=ror(e,14) XOR ror(e,18)*/
	ror x10, x14,#41		/*x10=ror(e, 41)*/
	eor x9, x9,x10			/*x9=ror(e,14) XOR ror(e,18)XOR ror(e,41)*/
	
	/*x10 := (e and f) xor ((not e) and g)*/
	ldr x15, addr_f
	ldr x13, addr_g
	ldr x15, [x15]		  	/*x15<-f*/
	ldr x13, [x13]			/*x13<-g*/
	and x10, x14, x15		/*x10=e AND f*/
	mvn x14, x14			/*x14=NOT(e)*/
	and x11, x14, x13		/*x11=NOT(e) AND g*/
	eor x10, x10, x11		/*x10=(e and f) xor ((not e) and g)*/

	/*x11:=m + r6 + r7 + k[i] + message[i]*/
	ldr x13, addr_m				
	ldr x13, [x13]			/*x13<-m*/
	add x11, x13, x9		/*x11=m+x9*/
	add x11, x11, x10		/*x11=m+x9+x10*/
	ldr x13, addr_k
	ldr x13, [x13, x0, lsl #DW_SHIFT]/*x13<-k[i]*/
	add x11, x11, x13		/*x11= m+x9+x10+k[i]*/	
	ldr x13, addr_message
	ldr x13, [x13, x0, lsl #DW_SHIFT]/*x13<-message[i]*/	
	add x11, x11, x13		/*x11=m + r6 + r7 + k[i] + message[i]*/
			
	mov x0, x11			/*x0 = temp1 (output)*/				
	ret

/*make_temp2
 * computes temp2:
 *	S0 := (a rightrotate 28) xor (a rightrotate 34) xor (a rightrotate 39)
 *  maj := (a and b) xor (a and c) xor (b and c)
 *  temp2 := S0 + maj
 * OUTPUT:
 * r0= temp2
*/
make_temp2:

	/*x9 := (a rightrotate 28) xor (a rightrotate 34) xor (a rightrotate 39)*/
	ldr x8, addr_a				
	ldr x8, [x8]			/*x8<-a*/
	ror x9, x8, #28			/*x9=ror(a, 28)*/
	ror x10, x8, #34		/*x10=ror(a, 34)*/
	eor x9, x9, x10			/*x9=ror(a, 2) XOR ror(a, 13)*/
	ror x10, x8, #39		/*x10=ror(a, 39)*/
	eor x9, x9, x10			/*x9=s0*/ 

	/*x10 := (a and b) xor (a and c) xor (b and c)*/
	ldr x11, addr_b
	ldr x13, addr_c
	ldr x11, [x11]			/*x11<-b*/
	ldr x13, [x13]			/*x13<-c*/
	and x10, x8, x11		/*x10=a AND b*/ 
	and x14, x8, x13		/*x14=a AND c */
	eor x10, x10, x14		/*x10=(a AND b) XOR (a AND c)*/
	and x14, x11, x13		/*x14=b AND c*/
	eor x10, x10, x14		/*x10=(a AND b) XOR (a AND c) XOR (b AND c)*/
					
	add x0, x9, x10			/*x0=S0+maj, output*/
				
	ret


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
	
	stp x30, x29, [sp, #-16]!	/*push {lr, ...} $ */
	mov x8, x0		/*x8=temp1*/
	mov x9, x1		/*x9=temp2*/

	stp x8, x9, [sp, #-16]!		/*push {x8,x9} $ */
	/*m=g*/
	ldr x0, addr_m		/*paramter for updateLetter*/			
	ldr x1, addr_g		/*paramter for updateLetter*/
	bl updateLetter

	/*g=f*/
	ldr x0, addr_g					
	ldr x1, addr_f		
	bl updateLetter
			
	/*f=e*/
	ldr x0, addr_f					
	ldr x1, addr_e		
	bl updateLetter	
			
	/*e=d+temp1*/
	ldr x0, addr_e					
	ldr x1, addr_d		
	bl updateLetter		/*e=d*/
	
	ldp x8, x9, [sp], #16		/*pop {x8,x9} $ */
	
	ldr x11, addr_e
	ldr x10, [x11]		/*x10=e*/
	add x10, x10, x8	/*x10+=temp1*/
	str x10, [x11]		/*x10->e*/

	stp x8, x9, [sp, #-16]!		/*push {x8,x9} $ */
	/*d=c*/
	ldr x0, addr_d					
	ldr x1, addr_c		
	bl updateLetter			

	/*c=b*/
	ldr x0, addr_c				
	ldr x1, addr_b		
	bl updateLetter	
			
	/*b=a*/
	ldr x0, addr_b					
	ldr x1, addr_a		
	bl updateLetter		
	
	/*a= temp1+temp2*/
	add x8,x8,x9
	ldr x1, addr_a
	
	ldp x8, x9, [sp], #16		/*pop {x8,x9} $ */	
	str x8, [x1]		/*a=temp1+temp2*/
	
	ldp x30, x29, [sp], #16	/*push {lr, ...} $ */	
	ret

/* updateLetter
* assigns to a letter the value of another letter
* letter1:= letter2
* PARAMS:
* x0 = address(letter1)
* x1 = address(letter2)
*/
updateLetter:
	ldr x1, [x1]		/*x1<-letter2*/
	str x1, [x0]		/*letter2->letter1*/
			
	ret


/*updateHash
*  h[0]+=a
*  h[1]+=b
*  ...
*/	  
updateHash:
	
	stp x30, x29, [sp, #-16]!	/*push {lr, ...} $ */
	
	/*h[0]+=a*/
	mov x0, #0	/*x0=index*/
	ldr x1, addr_a	/*x1=address of a*/
	bl updateH

	/*h[1]+=b*/
	add x0, x0, #1		
	ldr x1, addr_b	
	bl updateH

	/*h[2]+=c*/
	add x0, x0, #1		
	ldr x1, addr_c	
	bl updateH

	/*h[3]+=d*/
	add x0, x0, #1		
	ldr x1, addr_d	
	bl updateH

	/*h[4]+=e*/
	add x0, x0, #1		
	ldr x1, addr_e	
	bl updateH

	/*h[5]+=f*/
	add x0, x0, #1		
	ldr x1, addr_f	
	bl updateH

	/*h[6]+=g*/
	add x0, x0, #1		
	ldr x1, addr_g	
	bl updateH

	/*h[7]+=m*/	
	add x0, x0, #1		
	ldr x1, addr_m	
	bl updateH

	ldp x30, x29, [sp], #16 	/*push {lr, ...} $ */
	ret

/*updateH
 * h[i]+=letter
 * PARAMS:
 * x0=i
 * x1=address(letter)
*/
updateH:

	ldr x8, addr_hash
	ldr x1, [x1] 				/*x1<-letter*/
	ldr x9, [x8, x0, lsl #DW_SHIFT] 	/*x9<-hash[i]*/
	add x9, x9, x1				/*x9=hash[i]+letter*/
	str x9,[x8, x0, lsl #DW_SHIFT]		/*hash[i]+letter->hash[i]*/
	ret
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
addr_tmpVar:.dword tmpVar
