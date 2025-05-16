all:
	nasm -f elf64 -g -F dwarf main.asm -o bubblesort.o
	nasm -f elf64 -g -F dwarf int-utils.asm -o int-utils.o
	nasm -f elf64 -g -F dwarf io-utils.asm -o io-utils.o
	ld bubblesort.o int-utils.o io-utils.o -o bubblesort

clean:
	rm -f *.o bubblesort