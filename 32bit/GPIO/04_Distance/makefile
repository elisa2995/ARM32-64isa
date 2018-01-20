# Makefile

all: distance32

distance32 : distance32.o gpioPinFSelect32.o gpioPinSet32.o gpioPinClr32.o gpioPinRead32.o
		gcc -o $@ $+ 

gpioPinFSelect32.o : gpioPinFSelect32.s
		as -o $@ $<

distance32.o : distance32.s
		as -o $@ $<

gpioPinSet32.o : gpioPinSet32.s
		as -o $@ $<

gpioPinClr32.o : gpioPinClr32.s
		as -o $@ $<		 

gpioPinRead32.o : gpioPinRead32.s
		as -o $@ $<

clean :	
	rm -vf distance32 *.o