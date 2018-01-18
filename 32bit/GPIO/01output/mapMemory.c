#include <stdio.h>

void mainAsm();
void printMemory();
void saveResult(int *res);

int *result;
void main(){
	mainAsm();
}

void printMemory(){
	char str[100];
	for(int i=13; i<=14; i++){
	   sprintf(str, "%p	%x", (void *)result+i*4, result[i]);
	   puts(str);
	}	
	printf("\n -------------------------- \n");
}

void saveResult(int *res){
	result = res;

}