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


uint64_t *myMapAddress(int fd);
void printMemory(uint32_t* pointer, int nrCells);
uint64_t* mapMyAddress(void *no_pref, size_t page_size, int prot_rdwr, int map_shared,int fd,off_t gpio);
uint32_t* mapClock();

uint64_t* result64;
uint32_t* result32;

void main(){
	mapClock();
}

/* mapAddress
*
*/
uint64_t* myMapAddress(int fd){
	result64 = (uint64_t * )mmap(NO_PREF, PAGE_SIZE, PROT_RDWR, MAP_SHARED, fd, GPIO);
	result32 = (uint32_t*)result64;

	//char str[10];
	//sprintf(str, "%p", result64);
	//puts(str);
	//int veryImportant = fake6(1, 2, 3, 4, 5, 6);
	return result64;
}

/* mapClock
* maps the clock
*/
uint32_t* mapClock(){

	int fd = open(DEVICE, OPEN_MODE);
	result32 = (uint32_t * )mmap(NO_PREF, PAGE_SIZE, PROT_RDWR, MAP_SHARED, fd, GPIO);
	//result32 = (uint32_t*)result64;

	char str[10];
	sprintf(str, "%p", result64);
	puts(str);
	printMemory(result32, 3);
	return result32;
}

/* mapAddress
*
*/
uint64_t* mapMyAddress(void *no_pref, size_t page_size, int prot_rdwr, int map_shared,int fd,off_t gpio){
	printf("nopref %i\n", no_pref);
	printf("page size %i\n", page_size);
	printf("prot_rdwr %i \n", prot_rdwr);
	printf("map_shared %i \n", map_shared);
	printf("fd %i \n", fd);
	printf("off_t \n", gpio);
	result64 = (uint64_t * )mmap(no_pref, page_size, prot_rdwr, map_shared, fd, gpio);
	result32 = (uint32_t*)result64;

	char str[10];
	//sprintf(str, "%p", result64);
	//puts(str);
	//int veryImportant = fake6(1, 2, 3, 4, 5, 6);
	return result64;
}

void printMemory(uint32_t* pointer, int nrCells){
	char str[100];
	// -- 64bits
	/*printf("\n ----------64----------- \n");
	for(int i=3; i<=4; i++){
	   sprintf(str, "%p	%x", (void *)pointer+i*8, pointer[i]);
	   puts(str);
	}*/
	printf("\n ----------32----------- \n");
	for(int i=0; i<nrCells; i++){
	   sprintf(str, "%p	%x", (void *)pointer+i*4, pointer[i]);
	   puts(str);
	}
}
