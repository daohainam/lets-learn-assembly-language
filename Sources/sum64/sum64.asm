section .text
    global _start

_start:

    mov rax, 1
    mov rdi, 1
    mov rsi, enter_int1_msg
    mov rdx, enter_int1_msg_len
    syscall

    mov rax, 0
    mov rdi, 0
    mov rsi, int_1
    mov rdx, 20
    syscall

    call string_to_int

    mov r12, rax

    ; Prompt for second integer
    mov rax, 1
    mov rdi, 1
    mov rsi, enter_int2_msg
    mov rdx, enter_int2_msg_len
    syscall

    mov rax, 0
    mov rdi, 0
    mov rsi, int_2
    mov rdx, 20
    syscall

    call string_to_int

    add rax, r12

    push rax

    mov rax, 1
    mov rdi, 1
    mov rsi, result_msg
    mov rdx, result_msg_len
    syscall

    pop rax

    call int_to_string
    mov rax, 1
    mov rdi, 1
    mov rdx, rcx
    syscall

    mov rax, 1
    mov rdi, 1
    mov rsi, new_line
    mov rdx, 1
    syscall

    mov rax, 60
    mov rdi, 0
    syscall

string_to_int:
    ; Convert string in rsi to integer in rax
    ; Convert string to integer
    mov rax, 0 ; xor rax, rax
    mov rbx, 0
    mov bl, [rsi]
    cmp bl, 10
    je .read_int_done

.read_int_loop:
    ; n = n * 10 + (bl - '0')

    sub bl, '0' ; Convert ASCII to integer
    imul rax, rax, 10 ; Multiply current value by 10
    add rax, rbx
    inc rsi
    mov bl, [rsi]
    cmp bl, 10
    jne .read_int_loop

.read_int_done:
    ; Return with integer in rax
    ret

int_to_string:
    ; Convert integer in rax to string in rsi

    xor rcx, rcx
    mov rbx, 10
    mov rsi, result
    add rsi, 21

.convert_loop:
    xor rdx, rdx ; rdx:rax / rbx ---> rdx = remainder, rax = quotient
    div rbx ; Divide rax by 10, quotient in rax, remainder in rdx
    add dl, '0' ; Convert remainder to ASCII
    dec rsi
    mov [rsi], dl ; Store ASCII character
    inc rcx ; Count digits

    test rax, rax
    jnz .convert_loop

    ret

section .rodata
    enter_int1_msg       db 'Enter 1st integer: '
    enter_int1_msg_len   equ $ - enter_int1_msg
    enter_int2_msg       db 'Enter 2nd integer: '
    enter_int2_msg_len   equ $ - enter_int2_msg
    result_msg           db 'The sum is: '
    result_msg_len       equ $ - result_msg
    new_line             db 10

section .bss
    int_1 resb 20    
    int_2 resb 20
    result resb 20

