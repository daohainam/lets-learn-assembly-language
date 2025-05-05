section .text
    global _start

_start:
    mov rsi, prompt
    mov rdx, prompt_len
    call print_str
    
    xor r12, r12                   ; chỉ số i = 0

read_loop:
    cmp r12, 10
    je bubble_sort

    ; đọc một dòng từ stdin
    mov rax, 0       ; syscall read
    mov rdi, 0       ; stdin
    mov rsi, input_buf
    mov rdx, 32
    syscall

    ; chuyển chuỗi sang số nguyên
    mov rsi, input_buf
    call str_to_int

    mov [numbers + r12*8], rax   ; lưu giá trị vào mảng

    inc r12
    jmp read_loop

;-----------------------
; Bubble Sort
;-----------------------
bubble_sort:
    mov rsi, sorting_prompt
    mov rdx, sorting_prompt_len
    call print_str

    mov rcx, 10
outer_loop:
    dec rcx
    mov rbx, 0
inner_loop:
    mov r8, [numbers + rbx*8]
    mov r9, [numbers + rbx*8 + 8]
    cmp r8, r9
    jle no_swap

    ; hoán đổi
    mov [numbers + rbx*8], r9
    mov [numbers + rbx*8 + 8], r8

no_swap:
    inc rbx
    cmp rbx, rcx
    jl inner_loop
    cmp rcx, 1
    jg outer_loop

;-----------------------
; In kết quả ra màn hình
;-----------------------
    mov rsi, result_prompt
    mov rdx, result_prompt_len
    call print_str

    xor r12, r12
print_loop:
    cmp r12, 10
    je exit

    mov rax, [numbers + r12*8]
    call int_to_str              ; chuyển số thành chuỗi, kết quả ở input_buf
    call print_str               ; in chuỗi ra màn hình

    inc r12
    jmp print_loop

;-----------------------
; Thoát chương trình
;-----------------------
exit:
    mov rax, 60
    xor rdi, rdi
    syscall

%include "int-utils.asm"
%include "io-utils.asm"

section .rodata
    prompt db 'Enter 10 int64 values:', 0x0A, 0x0D
    prompt_len   equ $ - prompt
    sorting_prompt db 'Start sorting...', 0x0A, 0x0D
    sorting_prompt_len   equ $ - sorting_prompt
    result_prompt db 'Result:', 0x0A, 0x0D
    result_prompt_len   equ $ - result_prompt

section .bss
    numbers resq    10           ; mảng chứa 10 số nguyên 64-bit
    input_buf resb  32           ; buffer để đọc chuỗi nhập vào


