# Makefile

all: blinkLED64

blinkLED64 : blinkLED64.o gpioPinFSelect64.o gpioPinSet64.o gpioPinClr64.o	
		gcc -o $@ $+ 

gpioPinFSelect64.o : gpioPinFSelect64.s
		as -o $@ $<

blinkLED64.o : blinkLED64.s
		as -o $@ $<

gpioPinSet64.o : gpioPinSet64.s
		as -o $@ $<

gpioPinClr64.o : gpioPinClr64.s
		as -o $@ $<

clean :	
	rm -vf blinkLED64 *.o