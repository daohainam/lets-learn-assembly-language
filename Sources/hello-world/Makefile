all:
	nasm -f elf64 -g -F dwarf hello.asm -o hello.o
	ld hello.o -o hello

clean:
	rm -f *.o hello