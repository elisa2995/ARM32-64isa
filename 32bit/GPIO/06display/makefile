# Makefile

all: display

display : display.o gpioPinFSelect.o gpioPinSet.o gpioPinClr.o map.o
		gcc -o $@ $+ 

gpioPinFSelect.o : gpioPinFSelect.s
		as -o $@ $<

gpioPinSet.o : gpioPinSet.s
		as -o $@ $<

gpioPinClr.o : gpioPinClr.s
		as -o $@ $<		 

display.o : display.s
		as -o $@ $<

map.o : map.s
		as -o $@ $<

clean :	
	rm -vf display *.o