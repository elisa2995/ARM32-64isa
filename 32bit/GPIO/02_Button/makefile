# Makefile

all: button32

button32: button32.o gpioPinFSelect32.o gpioPinRead32.o
	gcc -o $@ $+ 

gpioPinFSelect32.o: gpioPinFSelect32.s 
	as -o $@ $<

gpioPinRead32.o: gpioPinRead32.s 
	as -o $@ $<

button32.o: button32.s 
	as -o $@ $<	

clean:
	rm -vf button32 *.o

