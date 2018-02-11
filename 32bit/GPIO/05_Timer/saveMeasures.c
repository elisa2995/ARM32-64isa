#include <stdio.h>
#include <stdlib.h>

void saveMeasures(int* measuresAddr, int length){
	FILE *fp=fopen("measures.txt", "a");
	if(fp==NULL){
		printf("File not found");
	}
	for(int i=0; i<length; i++){
		fprintf(fp, "%i\t", measuresAddr[i]);
	}
	fprintf(fp,"\n");
	fclose(fp);
	return;
}