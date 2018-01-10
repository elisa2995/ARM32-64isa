# Makefile

all: sha256

sha256: sha256.c sha256.o 
	gcc -o $@ $+

sha256.o : sha256.s
	as -o $@ $<

clean:
	rm -vf sha256 *.o

