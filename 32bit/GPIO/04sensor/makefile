# Makefile

all: sensor

sensor : sensor.o gpioPinFSelect.o gpioPinSet.o gpioPinClr.o gpioPinRead.o
		gcc -o $@ $+ 

gpioPinFSelect.o : gpioPinFSelect.s
		as -o $@ $<

sensor.o : sensor.s
		as -o $@ $<

gpioPinSet.o : gpioPinSet.s
		as -o $@ $<

gpioPinClr.o : gpioPinClr.s
		as -o $@ $<		 

gpioPinRead.o : gpioPinRead.s
		as -o $@ $<

clean :	
	rm -vf sensor *.o