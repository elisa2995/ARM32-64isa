# Makefile

all: button64

button64: button64.o gpioPinFSelect64.o gpioPinRead64.o 
	gcc -o $@ $+ 

gpioPinFSelect64.o: gpioPinFSelect64.s 
	as -o $@ $<

gpioPinRead64.o: gpioPinRead64.s 
	as -o $@ $<

button64.o: button64.s 
	as -o $@ $<	

clean:
	rm -vf button64 *.o

