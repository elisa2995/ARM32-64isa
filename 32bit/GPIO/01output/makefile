# Makefile

all: blinkLED

blinkLED: blinkLED.o gpioPinFSelect.o gpioPinSet.o gpioPinClr.o
	gcc -o $@ $+ 
	
gpioPinSet.o: gpioPinSet.s 
	as -o $@ $<		

gpioPinFSelect.o: gpioPinFSelect.s 
	as -o $@ $<

blinkLED.o: blinkLED.s 
	as -o $@ $<

gpioPinClr.o: gpioPinClr.s 
	as -o $@ $<	

clean:
	rm -vf blinkLED *.o

