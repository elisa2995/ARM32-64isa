<h1>SHA256</h1>
(This whole content is reported in the <a href="https://github.com/elisa2995/ARM32-64isa/wiki/SHA">wiki</a> of the project.) 
<br><a href="https://en.wikipedia.org/wiki/SHA-2">From Wikipedia</a>: SHA-2 (Secure Hash Algorithm 2) is a set of cryptographic hash functions designed by the United States National Security Agency (NSA). Cryptographic hash functions are mathematical operations run on digital data; by comparing the computed "hash" (the output from execution of the algorithm) to a known and expected hash value, a person can determine the data's integrity. 

SHA-256 and SHA-512 are hash functions computed with 32-bit and 64-bit words, respectively. They use different shift amounts and additive constants, but their structures are otherwise virtually identical, differing only in the number of rounds.

We implemented SHA-256 on the 32 bit OS, following the Wikipedia pseudocode that you can find [here](https://github.com/elisa2995/ARM32-64isa/blob/master/32bit/SHA256/pseudocodeSHA256.txt). You can find the source code of our implementation <a href="https://github.com/elisa2995/ARM32-64isa/tree/master/32bit/SHA256">here</a>.

We did the same for SHA-512 on the 64 bit OS, with the pseudocode that you can find [here](https://github.com/elisa2995/ARM32-64isa/blob/master/64bit/SHA512/pseudocodeSHA512.txt). You can find the source code of our implementation <a href="https://github.com/elisa2995/ARM32-64isa/tree/master/64bit/SHA512">here</a>.
<hr>
<h3>How the program works</h3>
Implementing these algorithms is all about following the rules, so there are only a few things to point out about our implementation. 
The program consists of 2 source files, one implemented in C (<a href="https://github.com/elisa2995/ARM32-64isa/blob/master/32bit/SHA256/sha256.c">sha256.c</a>, <a href="https://github.com/elisa2995/ARM32-64isa/blob/master/64bit/SHA512/sha512.c">sha512.c</a>)and the other one in Assembly (<a href="https://github.com/elisa2995/ARM32-64isa/blob/master/32bit/SHA256/sha256.s">sha256.s</a>, <a href="https://github.com/elisa2995/ARM32-64isa/blob/master/64bit/SHA512/sha512.s">sha512.s</a>).
The two sources are linked together as you can see in the makefile (<a href="https://github.com/elisa2995/ARM32-64isa/blob/master/32bit/SHA256/makefile">makefileSha256</a>,<a href="https://github.com/elisa2995/ARM32-64isa/blob/master/64bit/SHA512/makefile">makefileSha512</a>).
<br>
The entry point of the program is the main() function in shaxx.c. 
<ul>
<li> The C program has the task of asking the user to insert the text for which he wants to compute the hashing function. It <a href="https://github.com/elisa2995/ARM32-64isa/blob/bcf2054feed721c2a1be7876111c86123d2067c3/32bit/SHA256/sha256.c#L34-L45">allocates dynamically</a> the necessary memory to store the input. At this point the program will start keeping track of the number of clock cycles passed, and immediately <a href="https://github.com/elisa2995/ARM32-64isa/blob/bcf2054feed721c2a1be7876111c86123d2067c3/32bit/SHA256/sha256.c#L50-L51">call</a> the <a href="https://github.com/elisa2995/ARM32-64isa/blob/bcf2054feed721c2a1be7876111c86123d2067c3/32bit/SHA256/sha256.s#L67">mainAsm</a> function, which implements the whole algorithm logic.</li>
<li> The Assembly part is organized in this way: there is a main (mainAsm) function, which is made global (<a href="https://github.com/elisa2995/ARM32-64isa/blob/bcf2054feed721c2a1be7876111c86123d2067c3/32bit/SHA256/sha256.s#L57"><code>.global mainAsm</code></a>) so that it can be called outside the assembly file. This function receives in input the address at which the input is memorized and its length. This function exploits other routines which implement the specific hash algorithm logic and updates the final hash. Once the algorithm finishes, the execution flows goes back to shaxx.c, which <a href="https://github.com/elisa2995/ARM32-64isa/blob/bcf2054feed721c2a1be7876111c86123d2067c3/32bit/SHA256/sha256.c#L52">stops counting</a> the clock cycles. The hash is printed on the screen together with the number of microseconds necessary for its computation. 
</li>
</ul>
<br>

<h3>Differences</h3>

Implementing these algorithms was a good startpoint to see the differences between the two instruction sets:

<table>
<tr>
<th width="25%">32 bit isa</th>
<th width="25%">64 bit isa</th>
<th >Comments</th>
</tr>
<tr>
<td><code>push {Rn, Rm}</code> 

<code>pop {Rn, Rm}</code></td>
<td><code>stp	Xn, Xm, [sp, #-16]!</code>

<code>ldp Xn, Xm, [sp], #16</code></td>
<td>In 64 bit isa there are not <code>push</code> and <code>pop</code> instructions, so to do these operations you have to directly store and load the values into the stack. You can take advantage of the instructions <code>stp</code> and <code>ldp</code> that allow you, respectively, to store and load 2 registers at a time (in this way it's easier to maintain the alignment of the stack, that has to be 16 bytes)(example: <a href="https://github.com/elisa2995/ARM32-64isa/blob/bcf2054feed721c2a1be7876111c86123d2067c3/32bit/SHA256/sha256.s#L96">push 32bits</a>, <a href="https://github.com/elisa2995/ARM32-64isa/blob/bcf2054feed721c2a1be7876111c86123d2067c3/32bit/SHA256/sha256.s#L115">pop 32bits</a>, <a href="https://github.com/elisa2995/ARM32-64isa/blob/bcf2054feed721c2a1be7876111c86123d2067c3/64bit/SHA512/sha512.s#L141-L143">push 64bits</a>, <a href="https://github.com/elisa2995/ARM32-64isa/blob/bcf2054feed721c2a1be7876111c86123d2067c3/64bit/SHA512/sha512.s#L160-L162">pop 64bits</a></td>
</tr>
<tr>
<td><code>bx lr</code></td>
<td><code>ret</code></td>
<td>In 64 bit isa there is an instruction <code>ret</code> that directly branches to the address contained in <code>lr</code> (<code>pc</code> <= <code>lr</code>) (example: <a href="https://github.com/elisa2995/ARM32-64isa/blob/bcf2054feed721c2a1be7876111c86123d2067c3/32bit/SHA256/sha256.s#L116">32bits</a>, <a href="https://github.com/elisa2995/ARM32-64isa/blob/bcf2054feed721c2a1be7876111c86123d2067c3/64bit/SHA512/sha512.s#L163">64bits</a>)</td>
</tr>
<tr>
<td><code>rsb Rn, Operand2</code></td>
<td><code>mov Xn, Operand2	</code>				 

<code>sub Xm, Xn, Xm </td></code>
<td>In 64 bit isa there is not an instruction that performs the reverse subtract without carry so you have to do it in two separate steps
(example: <a href="https://github.com/elisa2995/ARM32-64isa/blob/bcf2054feed721c2a1be7876111c86123d2067c3/32bit/SHA256/sha256.s#L106">32bits</a>, <a href="https://github.com/elisa2995/ARM32-64isa/blob/bcf2054feed721c2a1be7876111c86123d2067c3/64bit/SHA512/sha512.s#L117-L118">64 bits</a>)</td>
</tr>
<tr>
<td> <code>Operation{cond}{S} </code></td>
<td> <code>Operation{S} </code></td>
<td> In 64 bit isa the predicators can only be added to the branch instructon <code>b</code> while in 32 bit isa it's possible to use them with generic instructions </td>
</tr>
</table>

Other differences we found out are:
<table>
<tr>
<th width="25%">AArch32</th>
<th width="25%">AArch64</th>
<th >Comments</th>
</tr>
<tr>
<td><code>r0-r15</code></td>
<td><code>x0-x30</code></td>
<td>In 64 bit architecture there are 31 integer registers in user mode, while in 32 bit there are only 16 of them. Particularities of AArch64 is that the program counter <code>pc</code> is no longer accessible and there is a dedicate stack pointer <code>sp</code>. On the contrary, in AArch32 the <code>pc</code> is accesible from register <code>r15</code> and the<code>sp</code> is saved in register<code>r13</code>.</td>
</tr>
<tr>
<td><code>.align 2</code>

<code>.balign 4</code></td>
<td><code>.align 4</code>

<code>.balign 8</code>
</td>
<td>The alignment is of course different in the two architectures because they work with 32 and 64 bit respectively. (Examples: <a href="https://github.com/elisa2995/ARM32-64isa/blob/bcf2054feed721c2a1be7876111c86123d2067c3/32bit/SHA256/sha256.s#L17">32bits</a>, <a href="https://github.com/elisa2995/ARM32-64isa/blob/bcf2054feed721c2a1be7876111c86123d2067c3/64bit/SHA512/sha512.s#L16">64 bits</a>)</td>
</tr>
<tr>
<td><code>r0-r4</code> passing parameters regs

<code>r5-r12</code> callee-saved regs
</td>
<td><code>x0-x7</code> passing parameters regs

<code>x8-x18</code> caller-saved regs

<code>x19-x28</code> callee-saved regs
</td>
<td>The Procedure Call standard is different in the two architectures:
in AArch32, there are only 4 registers to use as function parameters and there are not caller-saved registers.
In AArch64, there are 8 registers dedicated to passing parameters and there are also caller-saved registers. To maintain the parallelism between the architectures and to do more or less the same number of instructions(pushes, pops) we didn't use the caller-saved registers. Therefore besides rare cases there is a direct correspondence between the registers used in the 32bits implementation and the ones used in the 64 bits implementation: when in 32 bit we use rn, in 64 bit we will use x(n+15).</td>
</tr>
</table>

<h3>Statistics</h3>
To compare performances of the two algorithms we have run 20 times each algorithm with the same input string.
First we used the input "computer architectures" (22 characters) and then we used an entire paragraph from a Lorem Ipsum generator (771 characters). We have aggregated data into boxplots, shown in the figure below:
<br><br>

<center>
<img src="https://github.com/elisa2995/ARM32-64isa/blob/master/media/SHAPerfComp.png">
</center>

As you can see from the picture, the algorithm running in AArch64 is faster than the on in AArch32, even though for each chunk it performs more computations (the message schedule array has 80 entry instead of 64).
