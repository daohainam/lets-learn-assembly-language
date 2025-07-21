all:
	nasm -f elf64 -g -F dwarf sum64.asm -o sum64.o
	ld sum64.o -o sum64

clean:
	rm -f *.o sum64