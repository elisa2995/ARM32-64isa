# Makefile

all: buttonLED64

buttonLED64 : buttonLED64.o gpioPinFSelect64.o gpioPinSet64.o gpioPinClr64.o gpioPinRead64.o
		gcc -o $@ $+ 

gpioPinFSelect64.o : gpioPinFSelect64.s
		as -o $@ $<

buttonLED64.o : buttonLED64.s
		as -o $@ $<

gpioPinSet64.o : gpioPinSet64.s
		as -o $@ $<

gpioPinClr64.o : gpioPinClr64.s
		as -o $@ $<		 

gpioPinRead64.o : gpioPinRead64.s
		as -o $@ $<

clean :	
	rm -vf buttonLED64 *.o