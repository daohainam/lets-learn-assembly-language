section .bss
    buffer resb 32        ; buffer để chứa số (tối đa 20 chữ số cho 64-bit)

section .text
    global _start

_start:
    mov r8, 12

    call print_r8

    mov rax, 1            
    mov rdi, 1            
    mov rsi, space
    mov rdx, 1
    syscall

    ; thoát
    mov rax, 60
    xor rdi, rdi
    syscall

print_r8:
    push rax
    mov rax, r8
    mov rcx, 0            ; đếm số chữ số
    lea rbx, [buffer+31]  ; trỏ đến cuối buffer

.convert_loop:
    xor rdx, rdx          ; dọn thanh ghi dư
    mov rdi, 10
    div rdi               ; rax = rax / 10, rdx = rax % 10
    add dl, '0'           ; chuyển số thành ASCII
    dec rbx
    mov [rbx], dl
    inc rcx
    test rax, rax
    jnz .convert_loop

    ; syscall write(stdout, rbx, rcx)
    mov rax, 1
    mov rdi, 1
    mov rsi, rbx
    mov rdx, rcx
    syscall
    
    pop rax
    ret

section .data
    space db ' '
