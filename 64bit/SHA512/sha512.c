/* Entry point of the program. Reads the input string and 
 * saves it in a big endian format. It then calls the assembly
 * program that implements the logic of the SHA512 algorithm. 	
*/
#include <stdio.h>
#include <stdlib.h>

#define INPUT_LENGTH 128	// initial buffer size
#define DWORD 8				// number of bytes of a double word
#define HASH_LENGTH 64 		// bytes
#define	EXTRA_BYTES 17		// we will append to the input at least 1 bytes of padding + 16 bytes 
							// containing the length of the input expressed in bits

void mainAsm(char *inputString, int length);
void invertChars(char *inputString, int buffer_length);
int length(char *buffer_ptr);
void initBuffer(char *buffer_ptr, int start_point);
void printHash(char *hash_ptr);

int main(){

	int buffer_length, i =0, k=1;
	char tmp;
	char *buffer=(char *)malloc(sizeof(char)*INPUT_LENGTH);

	initBuffer(buffer, 0);
	printf ("Insert the string you want to hash \n");

	while((tmp=getchar())!='\n'){

		// If the input exceeds the allocated memory, allocates more memory
		if(i+EXTRA_BYTES>INPUT_LENGTH*k){
			k++;
			buffer=(char *)realloc(buffer, sizeof(char)*INPUT_LENGTH*k);
			initBuffer(buffer, INPUT_LENGTH*(k-1));
		}

		buffer[i]=tmp;
		i++;
	};

	buffer_length=length(buffer);
	invertChars(buffer, buffer_length);
	mainAsm(buffer, buffer_length);
	free(buffer);

	return 0;
}

/* initBuffer
 * Sets to 0 INPUT_LENGTH charactersof the buffer pointed by 
 * buffer_ptr, starting from startPoint
 */
void initBuffer(char *buffer_ptr, int start_point){
	for(int i=start_point; i<start_point+INPUT_LENGTH; i++){
		buffer_ptr[i]='\0';
	}
}

/* invertChars
 * Inverts the order of the chars within a dword (8 by 8),
 * so that we can work in big endian.
*/

void invertChars(char *buffer_ptr, int buffer_length){

	char tmp;
	for(int i = 0; i<=(buffer_length)/DWORD; i++){
		for(int j = 0; j<DWORD/2; j++){
			tmp = buffer_ptr[i*DWORD+j];
			buffer_ptr[i*DWORD+j]=buffer_ptr[DWORD*(i+1)-j-1];
			buffer_ptr[DWORD*(i+1)-j-1]=tmp;
		}
	} 	
}


/* length
 * Returns the length of the string (WITHOUT termination character '\0').
*/

int length(char *buffer_ptr){

	int count = 0;

	while(buffer_ptr[count]!='\0'){
		count++;
	}
	return count;

}

/* printHash
 * Prints the hash pointed by hash_ptr.
 * (Called by sha512.s)
*/
void printHash(char *hash_ptr){

	for(int i = 0; i<HASH_LENGTH/DWORD; i++){ 		
		for(int j=0; j<DWORD;j++){ 
			printf("%02x", hash_ptr[i*DWORD+(DWORD-1-j)]);
		}
		printf(" ");
	}	  
	printf("\n");
}