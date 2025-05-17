all:
	nasm -f elf64 http-server.asm -o http-server.o
	nasm -f elf64 mime-type.asm -o mimi-type.o
	ld http-server.o mimi-type.o -o http-server

clean:
	rm -f *.o http-server