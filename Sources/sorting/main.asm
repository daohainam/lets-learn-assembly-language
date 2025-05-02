section .text
    global _start

_start:
    mov     rax, 1
    mov     rdi, 1
    mov     rsi, enter_quantity_msg
    mov     rdx, enter_quantity_msg_len
    syscall

    mov     rax, 60
    mov     rdi, 0
    syscall

extern _readQword

section .rodata
enter_quantity_msg      db 'How many numbers? '
enter_quantity_msg_len  equ $ - enter_quantity_msg

section .bss
array     resq 100

