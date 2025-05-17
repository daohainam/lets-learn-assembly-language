extern printf
extern scanf

section .rodata
    read_format  db "%lf %lf", 0
    result_msg db "[%d] %lfx + %lf = 0 => x = %lf", 10, 0
    step_msg   db "Step!", 10, 0
    align 32
    neg_mask: dq 0x8000000000000000, 0x8000000000000000, 0x8000000000000000, 0x8000000000000000

section .bss
    align 32
    a_values resq 4      ; 4 x double = 32 bytes
    align 32
    b_values resq 4
    align 32
    x_values resq 4

section .text
    global _start

_start:
    ; Read 4 pairs (a[i], b[i])
    xor r12, r12
.read_loop:
    ; scanf("%lf %lf", &a[i], &b[i])
    mov rdi, read_format
    lea rsi, [a_values+ r12*8]
    lea rdx, [b_values + r12*8]
    xor rax, rax
    call scanf

    inc r12
    cmp r12, 4
    jl .read_loop

    ; Load 4 a’s and b’s to ymm registers
    vmovapd ymm0, [a_values]     ; ymm0 = a[0..3]
    vmovapd ymm1, [b_values]     ; ymm1 = b[0..3]

    ; Load negate mask
    vmovapd ymm2, [neg_mask]
    vxorpd ymm1, ymm1, ymm2      ; ymm1 = -b

    ; Compute x = -b / a
    vdivpd ymm3, ymm1, ymm0      ; ymm3 = x[0..3]

    ; Store results
    vmovapd [x_values], ymm3

    ; Print results
    xor r12, r12
.print_loop:
    ; Load double x[i] to xmm0 (lower 64-bit of ymm3)
    movsd xmm0, [a_values + r12*8]
    movsd xmm1, [b_values + r12*8]
    movsd xmm2, [x_values + r12*8]
    mov rdi, result_msg
    mov rsi, r12
    inc rsi
    mov eax, 3
    call printf

    inc r12
    cmp r12, 4
    jl .print_loop

    ; Exit
    mov rax, 60
    xor rdi, rdi
    syscall