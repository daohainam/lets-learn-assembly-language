all:
	nasm -f elf64 -g -F dwarf for_loop.asm -o for_loop.o
	ld for_loop.o -o for_loop

clean:
	rm -f *.o for_loop
