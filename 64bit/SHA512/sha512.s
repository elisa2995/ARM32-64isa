/** -- sha 512 --*/
.data
.equ DWORD, 8
.equ DW_SHIFT, 3
.balign 8
hash: .dword 0x6a09e667f3bcc908, 0xbb67ae8584caa73b, 0x3c6ef372fe94f82b, 0xa54ff53a5f1d36f1,0x510e527fade682d1, 0x9b05688c2b3e6c1f, 0x1f83d9abfb41bd6b, 0x5be0cd19137e2179
.balign 8
k: .dword 0x428a2f98d728ae22, 0x7137449123ef65cd, 0xb5c0fbcfec4d3b2f, 0xe9b5dba58189dbbc, 0x3956c25bf348b538, 0x59f111f1b605d019, 0x923f82a4af194f9b, 0xab1c5ed5da6d8118, 0xd807aa98a3030242, 0x12835b0145706fbe, 0x243185be4ee4b28c, 0x550c7dc3d5ffb4e2, 0x72be5d74f27b896f, 0x80deb1fe3b1696b1, 0x9bdc06a725c71235,0xc19bf174cf692694, 0xe49b69c19ef14ad2, 0xefbe4786384f25e3, 0x0fc19dc68b8cd5b5, 0x240ca1cc77ac9c65, 0x2de92c6f592b0275, 0x4a7484aa6ea6e483, 0x5cb0a9dcbd41fbd4, 0x76f988da831153b5, 0x983e5152ee66dfab,0xa831c66d2db43210, 0xb00327c898fb213f, 0xbf597fc7beef0ee4, 0xc6e00bf33da88fc2, 0xd5a79147930aa725,  0x06ca6351e003826f, 0x142929670a0e6e70, 0x27b70a8546d22ffc, 0x2e1b21385c26c926, 0x4d2c6dfc5ac42aed, 0x53380d139d95b3df, 0x650a73548baf63de, 0x766a0abb3c77b2a8, 0x81c2c92e47edaee6, 0x92722c851482353b, 0xa2bfe8a14cf10364, 0xa81a664bbc423001, 0xc24b8b70d0f89791, 0xc76c51a30654be30, 0xd192e819d6ef5218, 0xd69906245565a910, 0xf40e35855771202a, 0x106aa07032bbd1b8, 0x19a4c116b8d2d0c8, 0x1e376c085141ab53, 0x2748774cdf8eeb99, 0x34b0bcb5e19b48a8, 0x391c0cb3c5c95a63, 0x4ed8aa4ae3418acb, 0x5b9cca4f7763e373, 0x682e6ff3d6b2b8a3, 0x748f82ee5defb2fc, 0x78a5636f43172f60, 0x84c87814a1f0ab72, 0x8cc702081a6439ec, 0x90befffa23631e28, 0xa4506cebde82bde9, 0xbef9a3f7b2c67915, 0xc67178f2e372532b, 0xca273eceea26619c, 0xd186b8c721c0c207, 0xeada7dd6cde0eb1e, 0xf57d4f7fee6ed178, 0x06f067aa72176fba, 0x0a637dc5a2c898a6, 0x113f9804bef90dae, 0x1b710b35131c471b, 0x28db77f523047d84, 0x32caab7b40c72493, 0x3c9ebe0a15c9bebc,0x431d67c49c100d4c, 0x4cc5d4becb3e42b6, 0x597f299cfc657e2a, 0x5fcb6fab3ad6faec, 0x6c44198c4a475817	
addr_input: .word 0	 
input_length: .dword 0
message: .dword   0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
a: .dword 0
b: .dword 0
c: .dword 0
d: .dword 0
e: .dword 0
f: .dword 0
g: .dword 0
m: .dword 0

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

    ldr w2, ptr_addr_input
    str w0, [x2]			/*w0=address(input)->addr_input*/
    ldr w2, addr_input_length
    str w1, [x2]			/*w1=length(input)->input_length*/

    /*PREPROSSING*/
    bl startPadding
    bl fillEnd

    /*COMPRESSION*/
    bl processChunks

    /*PRINT HASH*/
    ldr w0, addr_hash
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
	
	lsr x10,x10, #DW_SHIFT		/*x10<- index of the dword that we have to modify (from left to right)*/

	and x8, x8, #0b00000111		/*x8= input_length MOD 8*/
	mov x13, #DWORD-1		/* $ rsb */
	sub x8, x13, x8			/*x8= (7-input_length MOD 4)index of the byte in the word that has to be modified*/	
	lsl x8,x8, #3				/*x8<-x8*8, # of left shifts of 0b10000000*/

	ldr x12,[x11,x10, lsl #DW_SHIFT]	/*Load the word that has to be modified*/
	ret
ciao:	
	mov x9,#0b10000000		
	lsl x9,x9, x8			/*Positioning the 0x10 the right position*/

	orr x12,x12, x9			/*Insert the 1*/
	str x12,[x11,x10, lsl #DW_SHIFT]	/*Store the modified value*/

	ret


fillEnd:	
    ret

processChunks:
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
