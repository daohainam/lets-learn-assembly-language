all:
	nasm -f elf64 solve_linear_simd.asm
	gcc -no-pie -nostartfiles -mavx -o solve_linear_simd solve_linear_simd.o
clean:
	rm -f *.o solve_linear_simd