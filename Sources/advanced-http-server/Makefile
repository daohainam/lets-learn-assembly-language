all:
	nasm -f elf64 advanced-http-server.asm -o advanced-http-server.o
	nasm -f elf64 mime-type.asm -o mime-type.o
	ld advanced-http-server.o mime-type.o -o advanced-http-server

clean:
	rm -f *.o advanced-http-server