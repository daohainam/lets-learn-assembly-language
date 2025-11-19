all:
	nasm -f elf64 gzipped-http-server.asm -o gzipped-http-server.o
	nasm -f elf64 mime-type.asm -o mime-type.o
	ld gzipped-http-server.o mime-type.o -o gzipped-http-server -Oz

clean:
	rm -f *.o gzipped-http-server