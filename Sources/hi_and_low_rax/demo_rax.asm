section .text
    global _start

%macro print 2 
    mov     rsi, %1
    mov     rdx, %2
    call    print_string 
%endmacro

_start:
    xor rax, rax
    call print_rax

    mov al, 0xEF
    print al_msg, al_msg_len
    call print_rax

    mov ah, 0xCD
    print ah_msg, ah_msg_len
    call print_rax

    or eax, 0x89AB0000
    print eax_msg, eax_msg_len
    call print_rax

    mov rbx, 0x0123456700000000
    or rax, rbx
    print rax_or_msg, rax_or_msg_len
    call print_rax

    mov rbx, 0xF0F0F0F0F0F0F0F0
    and rax, rbx
    print rax_and_msg, rax_and_msg_len
    call print_rax

    mov rax, 60
    xor rdi, rdi
    syscall

print_rax:
    push rax
    mov rax, 1              ; write
    mov rdi, 1              ; stdout
    mov rsi, rax_content
    mov rdx, rax_content_len
    syscall
    pop rax

    call print_rax_hex

    push rax
    mov rax, 1              ; write
    mov rdi, 1              ; stdout
    mov rsi, newline
    mov rdx, newline_len
    syscall
    pop rax

    ret

print_string:
    push rax
    mov rax, 1              ; write
    mov rdi, 1              ; stdout
    syscall
    pop rax

    ret

%include "print_rax.asm"

section .rodata
    rax_content db 'RAX: '
    rax_content_len equ $ - rax_content

    newline db 10, 13
    newline_len equ 2

    hex_prefix db "0x"
    hex_prefix_len equ $ - hex_prefix

    al_msg db 'AL = 0xEF', 10, 13
    al_msg_len equ $ - al_msg

    ah_msg db 'AH = 0xCD', 10, 13
    ah_msg_len equ $ - ah_msg

    eax_msg db 'EAX = EAX or 0x89AB0000', 10, 13
    eax_msg_len equ $ - eax_msg

    rax_or_msg db 'RAX = RAX or 0x0123456700000000', 10, 13
    rax_or_msg_len equ $ - rax_or_msg
  
    rax_and_msg db 'RAX = RAX and 0xF0F0F0F0F0F0F0F0', 10, 13
    rax_and_msg_len equ $ - rax_and_msg
  

section .bss
    hex_buffer resb 16      