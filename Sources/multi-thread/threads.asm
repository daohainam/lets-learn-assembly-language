%define SYS_folk 57
%define SYS_exit 60
%define SYS_nanosleep 35
%define num_threads 10

section .data
fmt_msg     db "[Thread %d] Sleeping %d sec...", 10, 0
thread_start_msg db "Thread %d started", 10, 0
start_msg   db "Multi-thread demo", 10, 0
stop_msg    db "Press Ctrl-C to stop...", 10, 0

section .bss
thread_ids  resq num_threads

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
    mov rdi, 0x_cafe_babe
    call srand

    mov rbx, 0
.next_thread:
    cmp rbx, num_threads
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
    mov rdi, thread_start_msg
    mov rsi, rbx        ; rbx = thread number (0..n)    
    call printf
    
.loop:

    ; sleep random 1–10 seconds, rax is now containing a random value
    call rand
    xor rdx, rdx
    mov rcx, 10
    div rcx             ; rax = rand() / 0, rdx = rand() % 10
    inc rdx             ; rdx = remainer + 1 
    add rdx, rbx

    mov r12, rdx

    mov rdi, fmt_msg
    mov rsi, rbx        
    call printf

    ; build timespec
    sub rsp, 16
    mov qword [rsp], r12     ; tv_sec
    mov qword [rsp+8], 0     ; tv_nsec
    mov rdi, rsp
    xor rsi, rsi
    mov rax, SYS_nanosleep
    syscall
    add rsp, 16

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
