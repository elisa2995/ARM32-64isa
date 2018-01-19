# Makefile

all: sensorTimer

sensorTimer : sensorTimer.o gpioPinFSelect.o gpioPinSet.o gpioPinClr.o gpioPinRead.o systemTimer.o map.o
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

systemTimer.o : systemTimer.s
		as -o $@ $<

map.o : map.s
		as -o $@ $<

clean :	
	rm -vf sensorTimer *.o