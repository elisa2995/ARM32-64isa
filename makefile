# Makefile

all: sha2

sha2: sha2.o
	gcc -o $@ $+

sha2.o : sha2.s
	as -o $@ $<

clean: 
	rm -vf sha2 *.o