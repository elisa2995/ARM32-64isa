# Makefile

all: blinkLED32

blinkLED32: blinkLED32.o gpioPinFSelect32.o gpioPinSet32.o gpioPinClr32.o
	gcc -o $@ $+ 
	
gpioPinSet32.o: gpioPinSet32.s 
	as -o $@ $<		

gpioPinFSelect32.o: gpioPinFSelect32.s 
	as -o $@ $<

blinkLED32.o: blinkLED32.s 
	as -o $@ $<

gpioPinClr32.o: gpioPinClr32.s 
	as -o $@ $<	

clean:
	rm -vf blinkLED32 *.o

