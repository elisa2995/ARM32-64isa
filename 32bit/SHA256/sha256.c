#include <stdio.h> 
#include <stdlib.h>

#define INPUT_LENGTH 64	
#define WORD 4		   
#define HASH_LENGTH 32 //bytes

void mainAsm(char *inputString, int length);  
void invertChars(char *inputString, int buffer_length);
int length(char *buffer_ptr);							
void invertLastWord(char *buffer_ptr, int buffer_length); 
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
		if(i+9>INPUT_LENGTH*k){
			k++;
			buffer=(char *)realloc(buffer, sizeof(char)*INPUT_LENGTH*k);
			initBuffer(buffer, INPUT_LENGTH*(k-1));
		}

    	buffer[i]=tmp;
		i++;
	};

	buffer_length=length(buffer);
	invertChars(buffer, buffer_length);
	mainAsm(buffer, buffer_length-1);
	free(buffer);

	return 0;
}

/*invertChars
 *Inverts the order of the chars within a word (4 by 4).
*/

void invertChars(char *buffer_ptr, int buffer_length){

	char tmp;
	int i;

	for(i = 0; i<=(buffer_length-1)/WORD; i++){

		for(int j = 0; j<WORD/2; j++){
			tmp = buffer_ptr[i*WORD+j];
			buffer_ptr[i*WORD+j]=buffer_ptr[WORD*(i+1)-j-1];
			buffer_ptr[WORD*(i+1)-j-1]=tmp;
		}
	} 
}


/* length(char *buffer_ptr)
 * Returns the length of the string (WITH termination character '\0').
*/

int length(char *buffer_ptr){

	int count = 0;

	while(buffer_ptr[count]!='\0'){
		count++;
	}  
	count++;

	return count;

}


/* initBuffer
 * Initialize the buffer with INPUT_LENGTH '\0'
 */

void initBuffer(char *buffer_ptr, int start_point){

	for(int i=start_point; i<start_point+INPUT_LENGTH; i++){
		buffer_ptr[i]='\0';
	}
}
/*printHash
 *Prints the hash
*/
void printHash(char *hash_ptr){
	for(int i = 0; i<HASH_LENGTH/WORD; i++){
		for(int j=0; j<WORD;j++){
			printf("%02x", hash_ptr[i*WORD+(WORD-1-j)]);
			//printf("%02x", hash_ptr[i*WORD+j]);
		}
		printf(" ");
	}	  
	printf("\n");
}