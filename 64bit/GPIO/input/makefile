# Makefile

all: button

button: button.o gpioPinFSelect.o gpioPinRead.o 
	gcc -o $@ $+ 

gpioPinFSelect.o: gpioPinFSelect.s 
	as -o $@ $<

gpioPinRead.o: gpioPinRead.s 
	as -o $@ $<

button.o: button.s 
	as -o $@ $<	

clean:
	rm -vf button *.o

