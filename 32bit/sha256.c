#include <stdio.h>
#include <stdlib.h>
#define INPUT_LENGTH 16
#define WORD 4
void mainAsm(char *inputString, int length);
void invertChars(char *inputString);
int length(char *buffer_ptr);
void invertLastWord(char *buffer_ptr, int buffer_length);
void initBuffer(char *buffer_ptr, int start_point);

int main(){

	int i =0;
	char tmp;
	int buffer_length= INPUT_LENGTH; 	
	char *buffer=(char *)malloc(sizeof(char)*INPUT_LENGTH);

	initBuffer(buffer, 0); 
	printf ("Insert the string you want to hash \n");

	while((tmp=getchar())!='\n'){  		
		// If the input exceeds the allocated memory, allocates more memory
		if(i==buffer_length){ 
			buffer_length +=INPUT_LENGTH;
			buffer=(char *)realloc(buffer, sizeof(char)*buffer_length);
			initBuffer(buffer, buffer_length-INPUT_LENGTH);
		}
    	buffer[i]=tmp;
		i++;
	};	 
	
	invertChars(buffer);
	mainAsm(buffer, length(buffer)-1);
	free(buffer);
	return 0;
}

/*invertChars
 *Inverts the order of the chars within a word (4 by 4).
*/
void invertChars(char *buffer_ptr){
	char tmp;
	int i;
	int buffer_length = length(buffer_ptr);
	for(i = 0; i<(buffer_length-1)/WORD; i++){
		for(int j = 0; j<WORD/2; j++){
			tmp = buffer_ptr[i*WORD+j];
			buffer_ptr[i*WORD+j]=buffer_ptr[WORD*(i+1)-j-1];
			buffer_ptr[WORD*(i+1)-j-1]=tmp; 
		}
	}
	invertLastWord(buffer_ptr, buffer_length);
	printf(buffer_ptr);
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

/*invertLastWord(char *buffer_ptr, int buffer_length)
 *Invert the last word of the string, handling the presence of '\0'.
*/
void invertLastWord(char *buffer_ptr, int buffer_length){
	char tmp;
    int i = (buffer_length-1)/WORD;
	switch(buffer_length%WORD){
		case 0:
				tmp = buffer_ptr[i*WORD];
				buffer_ptr[i*WORD]=buffer_ptr[i*WORD+2];
				buffer_ptr[i*WORD+2]=tmp;	
				break;
		case 3: 
				tmp = buffer_ptr[i*WORD];
				buffer_ptr[i*WORD]=buffer_ptr[i*WORD+1];
				buffer_ptr[i*WORD+1]=tmp;
				break;
		default:
				break;
	}
}

/* initBuffer
 * Initialize the buffer with INPUT_LENGTH '\0'
 */
void initBuffer(char *buffer_ptr, int start_point){
	for(int i=start_point; i<start_point+INPUT_LENGTH; i++){
		buffer_ptr[i]='\0';
	}
	
}