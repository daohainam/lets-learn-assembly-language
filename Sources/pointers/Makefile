all:
	nasm -f elf64 -g -F dwarf pointers.asm -o pointers.o
	ld pointers.o -o pointers

clean:
	rm -f *.o pointers