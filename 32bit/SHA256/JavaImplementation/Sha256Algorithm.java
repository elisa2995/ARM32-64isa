/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package sha256;

/**
 *
 * @author Elisa
 */
public class Sha256Algorithm {

    //final int BYTE = 8;
    final int INT = 32;
    /*int[] toProcess = {0x11112222, 0x33334444, 0x55556666, 0x77778888,
        0x11112222, 0x11112222, 0x11112222, 0x11112222, 0x11112222, 0x11112222,
        0x11112222, 0x11112222, 0x11112222, 0x11112222, 0x11112222, 0x11112222};*/
    int[] toProcess = {0x31313131, 0x31313131,0x31313232,0x32323232,0x32323232,
        0x33333333, 0x33333333, 0x33333434, 0x34343434, 0x34343434, 0x35353535,
        0x35353535, 0x35353636, 0x36363636, 0x36363636}; /*0x30303030, 0x30303030*/
    //int[] toProcess = {0b10000000000000000000000000000000};
    //Initialize hash values:
    //(first 32 bits of the fractional parts of the square roots of the first 8 primes 2..19):
    int[] h = new int[]{0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19};
    //Initialize array of round constants:
    //(first 32 bits of the fractional parts of the cube roots of the first 64 primes 2..311):
    int[] k = new int[]{
        0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
        0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
        0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
        0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
        0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
        0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
        0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
        0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2};
    int a = h[0], b = h[1], c = h[2], d = h[3], e = h[4], f = h[5], g = h[6], m = h[7];

    public Sha256Algorithm() {
        algorithm();
    }

    public void algorithm() {
        int[] processed = preprocess(toProcess);
        int[] w;
        //break message into 512-bit chunks
        int[][] chunks = get512bitsChunks(processed);
        for (int[] chunk : chunks) {
            w = processChunk(chunk);
            initializeAlphabeth();
            compress(w);
            updateHash();
        }
        printHash();
    }

    /**
     * Pre-processing: begin with the original message of length L bits
     * ((((append a single '1' bit))) append K '0' bits, where K is the minimum
     * number >= 0 such that L + 1 + K + 64 is a multiple of 512 append L as a
     * 64-bit big-endian integer, making the total post-processed length a
     * multiple of 512 bits
     */
    private int[] preprocess(int[] toProcess) {
        int nBits = toProcess.length * INT;
        int[] processed = new int[512 * (int) Math.ceil((nBits * 1.0 + 64.0) / 512.0) / INT];
        // I copy the content of toProcess into process, putting 0 after the end of it
        for (int i = 0; i < processed.length; i++) {
            if (i < toProcess.length) {
                processed[i] = toProcess[i];
            } else {
                processed[i] = 0;
            }
        }
        // I set the first bit after the end of toProcess to 1
        processed[toProcess.length] = 0x80000000;
        int[] toInsert = new int[2];
        if (/*INPUT_LENGTH_B*/toProcess.length * 4 > 0x1FFFFFFF) {
            toInsert[0]=lsr(toProcess.length*4,29);
        } else {
            toInsert[0] = 0;
        }        
        toInsert[1] = lsl((toProcess.length * 4), 3);
        
        // I copy the length of toProcess in bits as a 64-bit big-endian integer
        processed[processed.length - 2] = toInsert[0];
        processed[processed.length - 1] = toInsert[1];
        System.out.println("Processed");
        for(int i=0; i<processed.length; i++){
            System.out.print(Integer.toHexString(processed[i])+" ");
        }
        
//        for (int i = 0; i < processed.length; i++) {
//            System.out.println(processed[i] + " ");
//        }
        //System.out.println(processed.length);
        return processed;
    }

    private int[][] get512bitsChunks(int[] processed) {
        int nIntPerChunk = 512 / INT;
        // Each row of this matrix is a chunk
        int[][] chunks = new int[processed.length / nIntPerChunk][nIntPerChunk];
        for (int i = 0; i < chunks.length; i++) {
            //System.out.print("r ");
            for (int j = 0; j < chunks[0].length; j++) {
                chunks[i][j] = processed[j + i * chunks[0].length];
                //System.out.print(chunks[i][j]+" ");
            }
            //System.out.println("");
        }
        return chunks;
    }

    /**
     * <pre>
     * Create a 64-entry message schedule array w[0..63] of 32-bit words
     *(The initial values in w[0..63] don't matter, so many implementations zero them here)
     * copy chunk into first 16 words w[0..15] of the message schedule array
     *
     * Extend the first 16 words into the remaining 48 words w[16..63] of the message schedule array:
     * for i from 16 to 63
     *   s0 := (w[i-15] rightrotate 7) xor (w[i-15] rightrotate 18) xor (w[i-15] rightshift 3)
     *   s1 := (w[i-2] rightrotate 17) xor (w[i-2] rightrotate 19) xor (w[i-2] rightshift 10)
     *   w[i] := w[i-16] + s0 + w[i-7] + s1
     * </pre>
     *
     * @param chunk
     */
    private int[] processChunk(int[] chunk) {
        int[] w = new int[64];
        int s0, s1;
        // Copy chunk into first 16 words of w
        for (int i = 0; i < chunk.length; i++) {
            w[i] = chunk[i];
        }

        //
        for (int i = chunk.length; i < w.length; i++) {
            s0 = ror(w[i - 15], 7) ^ (ror(w[i - 15], 18)) ^ (lsr(w[i - 15], 3));
            s1 = ror(w[i - 2], 17) ^ (ror(w[i - 2], 19)) ^ (lsr(w[i - 2], 10));
            w[i] = w[i - 16] + s0 + w[i - 7] + s1;
        }
        return w;
    }

    private void initializeAlphabeth() {
        a = h[0];
        b = h[1];
        c = h[2];
        d = h[3];
        e = h[4];
        f = h[5];
        g = h[6];
        m = h[7];
    }

    /**
     * <pre>
     *
     * h := g
     * g := f
     * f := e
     * e := d + temp1
     * d := c
     * c := b
     * b := a
     * a := temp1 + temp2
     *
     ** </pre>
     *
     * @param w
     */
    private void compress(int[] w) {
        int S1, ch, temp1 = 0, S0, maj, temp2 = 0;
        /*    for i from 0 to 63
        * S1 := (e rightrotate 6) xor (e rightrotate 11) xor (e rightrotate 25)
        * ch := (e and f) xor ((not e) and g)
        * temp1 := h + S1 + ch + k[i] + w[i]
        * S0 := (a rightrotate 2) xor (a rightrotate 13) xor (a rightrotate 22)
        * maj := (a and b) xor (a and c) xor (b and c)
        * temp2 := S0 + maj*/
        for (int i = 0; i < 64; i++) {
            S1 = ror(e, 6) ^ ror(e, 11) ^ ror(e, 25);
            ch = (e & f) ^ ((~e) & g);
            temp1 = m + S1 + ch + k[i] + w[i];

            S0 = ror(a, 2) ^ ror(a, 13) ^ ror(a, 22);
            maj = (a & b) ^ (a & c) ^ (b & c);
            temp2 = S0 + maj;
            
            

            m = g;              //h := g
            g = f;              //g := f
            f = e;              //* f := e
            e = d + temp1;      //* e := d + temp1
            d = c;              //* d := c
            c = b;              //* c := b
            b = a;              //* b := a
            a = temp1 + temp2;  //* a := temp1 + temp2  
        }
    }

    /**
     * Add the compressed chunk to the current hash value:
     *
     */
    private void updateHash() {
        h[0] += a;        //h0 := h0 + a
        h[1] += b;        //h1 := h1 + b
        h[2] += c;        //h2 := h2 + c
        h[3] += d;        //h3 := h3 + d
        h[4] += e;        //h4 := h4 + e
        h[5] += f;        //h5 := h5 + f
        h[6] += g;        //h6 := h6 + g
        h[7] += m;        //h7 := h7 + h

    }

    private int ror(int bits, int k) {
        return (bits >>> k) | (bits << (Integer.SIZE - k));
    }

    private int lsr(int bits, int k) {
        return bits >>> k;
    }

    private int lsl(int bits, int k) {
        return bits << k;
    }

    private void printHash() {
        for (int i = 0; i < h.length; i++) {
            System.out.print(Integer.toHexString(h[i]) + " ");
        }
    }

}
