all:
	nasm -f elf64 -g -F dwarf demo_rax.asm -o demo_rax.o
	ld demo_rax.o -o demo_rax

clean:
	rm -f *.o demo_rax