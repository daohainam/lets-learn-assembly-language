%define SYS_folk 57
%define SYS_exit 60
%define SYS_nanosleep 35

section .data
fmt_msg     db "Thread %d, Sleep %d", 10, 0
start_msg   db "Multi-thread demo", 10, 0
stop_msg    db "Press Ctrl-C to stop...", 10, 0
stack_size  equ 0x1000

section .bss
thread_ids  resq 5

section .text
extern printf
extern srand
extern rand
global _start

; -----------------------------
_start:
    mov rdi, start_msg
    call printf

    ; seed rand
    mov rdi, 12345
    call srand

    mov rbx, 0
.next_thread:
    cmp rbx, 10
    jge wait_exit

    mov rax, SYS_folk
    syscall

    test rax, rax
    jz .child               ; child thread will go to thread_func

    ; parent, save child id
    mov [thread_ids + rbx*8], rax
    inc rbx
    jmp .next_thread

.child:
    ; child thread jumps directly to function
    jmp thread_func

; -----------------------------
thread_func:
    mov rcx, 1
.loop:
    push rcx

    ; sleep random 1–5 seconds
    call rand
    ;xor rdx, rdx
    mov rcx, 5
    ;xor rax, rax
    div rcx             ; rax = rand() / 5, rdx = rand() % 5
    inc rdx             ; 1-5

    push rcx
    ; print: printf("Thread %d, Sleep %d\n", thread_id, rcx, rdx)
    mov rdi, fmt_msg
    mov rsi, rbx        ; thread id
    call printf
    pop rcx

    ; build timespec
    sub rsp, 16
    mov qword [rsp], rdx     ; tv_sec
    mov qword [rsp+8], 0     ; tv_nsec
    mov rdi, rsp
    xor rsi, rsi
    mov rax, SYS_nanosleep
    syscall
    add rsp, 16

    pop rcx

    inc rcx
    jmp .loop

    mov rax, SYS_exit
    xor rdi, rdi
    syscall

; -----------------------------
wait_exit:
    ; parent waits until user kills it or all threads done (basic version ends here)
    ; in real case should use futex or pthread join

    mov rdi, stop_msg
    call printf

.wait:
    jmp .wait
