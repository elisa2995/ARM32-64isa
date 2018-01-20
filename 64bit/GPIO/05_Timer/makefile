# Makefile

all: distanceTimer64

distanceTimer64 : distanceTimer64.o gpioPinFSelect64.o gpioPinSet64.o gpioPinClr64.o gpioPinRead64.o map64.o systemTimer64.o
		gcc -o $@ $+ 

gpioPinFSelect64.o : gpioPinFSelect64.s
		as -o $@ $<

distanceTimer64.o : distanceTimer64.s
		as -o $@ $<

gpioPinSet64.o : gpioPinSet64.s
		as -o $@ $<

gpioPinClr64.o : gpioPinClr64.s
		as -o $@ $<		 

gpioPinRead64.o : gpioPinRead64.s
		as -o $@ $<

map64.o : map64.s
		as -o $@ $<

systemTimer64.o : systemTimer64.s
		as -o $@ $<

clean :	
	rm -vf distanceTimer64 *.o