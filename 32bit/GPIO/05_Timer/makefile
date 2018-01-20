# Makefile

all: distanceTimer32

distanceTimer32 : distanceTimer32.o gpioPinFSelect32.o gpioPinSet32.o gpioPinClr32.o gpioPinRead32.o systemTimer32.o map32.o
		gcc -o $@ $+ 

gpioPinFSelect32.o : gpioPinFSelect32.s
		as -o $@ $<

sensor32.o : sensor32.s
		as -o $@ $<

gpioPinSet32.o : gpioPinSet32.s
		as -o $@ $<

gpioPinClr32.o : gpioPinClr32.s
		as -o $@ $<		 

gpioPinRead32.o : gpioPinRead32.s
		as -o $@ $<

distanceTimer32.o : distanceTimer32.s
		as -o $@ $<

map32.o : map32.s
		as -o $@ $<

clean :	
	rm -vf sensorTimer32 *.o