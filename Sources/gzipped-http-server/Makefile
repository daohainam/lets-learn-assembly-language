all:
	nasm -f elf64 -g -F dwarf gzipped-http-server.asm -o gzipped-http-server.o
	nasm -f elf64 -g -F dwarf mime-type.asm -o mime-type.o
	ld gzipped-http-server.o mime-type.o -o gzipped-http-server

clean:
	rm -f *.o gzipped-http-server