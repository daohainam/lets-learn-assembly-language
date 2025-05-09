all:
	nasm -f elf64 threads.asm -o threads.o
	gcc -no-pie -nostartfiles threads.o -o threads -lc
clean:
	rm -f *.o threads