/** mapTimer
* Inteded for debugging purposes.
* Maps the timer and prints the cells related to it.
*/

#include <sys/mman.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#include <stdint.h>

#define DEVICE "/dev/mem"
#define OPEN_MODE 0x100002
#define NO_PREF 0
#define PAGE_SIZE 4096*2
#define PROT_RDWR 0x3
#define MAP_SHARED 0x01
#define GPIO 0x3f003000

void printMemory(uint32_t* pointer, int nrCells);
uint32_t* mapTimer();

uint64_t* result64;
uint32_t* result32;

void main(){
	mapTimer();
}

/* mapTimer
* maps the timer
*/
uint32_t* mapTimer(){

	int fd = open(DEVICE, OPEN_MODE);
	result32 = (uint32_t * )mmap(NO_PREF, PAGE_SIZE, PROT_RDWR, MAP_SHARED, fd, GPIO);

	char str[10];
	sprintf(str, "%p", result64);
	puts(str);
	printMemory(result32, 3);
	return result32;
}

/** printMemory
* Prints <code>nrCells</code> 32 bits cells starting from
* <code>pointer </code> on.
* @param pointer the pointer to the first cell of memory to print
* @param nrCells the number of cells to be printed
*/
void printMemory(uint32_t* pointer, int nrCells){
	char str[100];
	printf("\n ----------32----------- \n");
	for(int i=0; i<nrCells; i++){
	   sprintf(str, "%p	%x", (void *)pointer+i*4, pointer[i]);
	   puts(str);
	}
}
