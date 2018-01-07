# Makefile

all: sha

sha: sha.o
	gcc -o $@ $+

sha.o : sha.s
	as -o $@ $<

clean: 
	rm -vf sha *.o