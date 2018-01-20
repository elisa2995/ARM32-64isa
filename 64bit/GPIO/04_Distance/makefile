# Makefile

all: distance64

distance64 : distance64.o gpioPinFSelect64.o gpioPinSet64.o gpioPinClr64.o gpioPinRead64.o
		gcc -o $@ $+ 

gpioPinFSelect64.o : gpioPinFSelect64.s
		as -o $@ $<

distance64.o : distance64.s
		as -o $@ $<

gpioPinSet64.o : gpioPinSet64.s
		as -o $@ $<

gpioPinClr64.o : gpioPinClr64.s
		as -o $@ $<		 

gpioPinRead64.o : gpioPinRead64.s
		as -o $@ $<

clean :	
	rm -vf distance64 *.o