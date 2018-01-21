/**
* Entry point of the program. Reads the input string
* and saves it in a big endian format. 
* It then calls the assembly program that implements the
* logic of the SHA256 algorithm. 
*/
#include <stdio.h> 
#include <stdlib.h>
#include <time.h>

#define INPUT_LENGTH 64	// initial buffer size
#define WORD 4		   	// number of bytes of a word
#define HASH_LENGTH 32  // bytes
#define	EXTRA_BYTES 9	// we will append to the input al least 1 byte 
						// of padding and 8 bytes containing the length 
						// of the input expressed in bits

void mainAsm(char *inputString, int length);  
void invertChars(char *inputString, int buffer_length);
int length(char *buffer_ptr);							
void initBuffer(char *buffer_ptr, int start_point);		   
void printHash(char *hash_ptr);

int main(){

	int buffer_length, i =0, k=1;
	char tmp;
	clock_t start, end;
	char *buffer=malloc(sizeof(char)*INPUT_LENGTH);

	initBuffer(buffer, 0);
	printf ("Insert the string you want to hash \n");

	while((tmp=getchar())!='\n'){

		// If the input exceeds the allocated memory, allocate more memory
		if(i+EXTRA_BYTES>INPUT_LENGTH*k){
			k++;
			buffer=realloc(buffer, sizeof(char)*INPUT_LENGTH*k);
			initBuffer(buffer, INPUT_LENGTH*(k-1));
		}

    	buffer[i]=tmp;
		i++;
	};

	buffer_length=length(buffer);
	invertChars(buffer, buffer_length);

	start = clock();
	mainAsm(buffer, buffer_length);
	end = clock();
	printf("Elapsed time %f us \n",(double)((end - start)*1000000.0) / CLOCKS_PER_SEC);

	free(buffer);

	return 0;
}


/* initBuffer
 * Sets to 0 INPUT_LENGTH charactes of the buffer pointed by buffer_ptr,
 * starting from start_point.
 */
void initBuffer(char *buffer_ptr, int start_point){

	for(int i=start_point; i<start_point+INPUT_LENGTH; i++){
		buffer_ptr[i]='\0';
	}
}

/** invertChars(char *buffer_ptr, int buffer_length)
 * Inverts the order of the chars within a word (4 by 4), so that we 
 * can work in big endian.
*/
void invertChars(char *buffer_ptr, int buffer_length){
	
	char tmp;
	for(int i = 0; i<=(buffer_length)/WORD; i++){

		for(int j = 0; j<WORD/2; j++){
			tmp = buffer_ptr[i*WORD+j];
			buffer_ptr[i*WORD+j]=buffer_ptr[WORD*(i+1)-j-1];
			buffer_ptr[WORD*(i+1)-j-1]=tmp;
		}
	} 
}

/** length(char *buffer_ptr)
 * Returns the length of the string (WITHOUT termination character '\0').
*/
int length(char *buffer_ptr){

	int count = 0;
	while(buffer_ptr[count]!='\0'){
		count++;
	}  

	return count;
}


/** printHash
 * Prints the hash pointed by hash_ptr.
 * (called by sha256.s)
*/
void printHash(char *hash_ptr){
	for(int i = 0; i<HASH_LENGTH/WORD; i++){
		for(int j=0; j<WORD;j++){
			printf("%02x", hash_ptr[i*WORD+(WORD-1-j)]);
		}
		printf(" ");
	}	  
	printf("\n");
}