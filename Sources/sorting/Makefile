all:
	nasm -f elf64 -g -F dwarf main.asm -o bubblesort.o
	ld bubblesort.o -o bubblesort

clean:
	rm -f *.o bubblesort