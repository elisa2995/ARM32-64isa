# Makefile

all: sha512

sha512: sha512.c sha512.o 
	gcc -o $@ $+

sha512.o : sha512.s
	as -o $@ $<

clean:
	rm -vf sha512 *.o
