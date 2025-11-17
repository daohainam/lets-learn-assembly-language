extern get_mime_type

%define SYS_SOCKET    41
%define SYS_BIND      49
%define SYS_LISTEN    50
%define SYS_ACCEPT    43
%define SYS_READ      0
%define SYS_WRITE     1
%define SYS_OPEN      2
%define SYS_CLOSE     3
%define SYS_EXIT      60
%define SYS_FORK      57

section .data
    sockaddr:
        dw 2          ; AF_INET
        dw 0x5000     ; Port 80
        dd 0          ; INADDR_ANY
        times 8 db 0  ; Padding

    http_404 db "HTTP/1.1 404 Not Found", 13,10, \
                "Content-Type: text/plain", 13,10, \
                "Connection: close", 13,10,13,10, \
                "404 Not Found", 10
    http_404_len equ $ - http_404

section .bss
    sockfd     resq 1
    clientfd   resq 1
    buffer     resb 4096
    filepath   resb 256
    filebuf    resb 8192
    mimebuf    resb 64
    headerbuf  resb 512

section .text
    global _start

_start:
    ; socket
    mov rax, SYS_SOCKET
    mov rdi, 2
    mov rsi, 1
    xor rdx, rdx
    syscall
    mov [sockfd], rax

    ; bind
    mov rax, SYS_BIND
    mov rdi, [sockfd]
    lea rsi, [sockaddr]
    mov edx, 16
    syscall

    ; listen
    mov rax, SYS_LISTEN
    mov rdi, [sockfd]
    mov rsi, 10
    syscall

accept_loop:
    ; accept
    mov rax, SYS_ACCEPT
    mov rdi, [sockfd]
    xor rsi, rsi
    xor rdx, rdx
    syscall
    mov [clientfd], rax

    ; fork
    mov rax, SYS_FORK
    syscall
    test rax, rax
    jnz .parent

    ; child: handle client
    mov rdi, [clientfd]
    call handle_client

    ; close + exit
    mov rax, SYS_CLOSE
    mov rdi, [clientfd]
    syscall

    mov rax, SYS_EXIT
    xor rdi, rdi
    syscall

.parent:
    ; parent: close client socket
    mov rax, SYS_CLOSE
    mov rdi, [clientfd]
    syscall
    jmp accept_loop

handle_client:
    ; read request
    mov rax, SYS_READ
    mov rdi, rdi
    lea rsi, [buffer]
    mov rdx, 4096
    syscall

    ; parse GET path
    lea rsi, [buffer]
    lea rdi, [filepath]
    call parse_get_path

    ; open file
    mov rax, SYS_OPEN
    lea rdi, [filepath]
    xor rsi, rsi
    syscall
    cmp rax, 0
    js .send_404
    mov rbx, rax ; fd

    ; read file
    mov rax, SYS_READ
    mov rdi, rbx
    lea rsi, [filebuf]
    mov rdx, 8192
    syscall
    mov rcx, rax ; file size

    ; get mime type
    lea rdi, [filepath]
    lea rsi, [mimebuf]
    call get_mime_type

    ; build header
    lea rdi, [mimebuf]
    lea rsi, [headerbuf]
    call build_http_header

    ; send header
    mov rax, SYS_WRITE
    mov rdi, [clientfd]
    lea rsi, [headerbuf]
    mov rdx, rax      ; header length trả về từ build_http_header trong rax
    syscall

    ; send file content
    mov rax, SYS_WRITE
    mov rdi, [clientfd]
    lea rsi, [filebuf]
    mov rdx, rcx
    syscall

    ret

.send_404:
    mov rax, SYS_WRITE
    mov rdi, [clientfd]
    lea rsi, [http_404]
    mov rdx, http_404_len
    syscall
    ret

parse_get_path:
    push rcx
    push rdx
    xor rcx, rcx
.skip:
    cmp byte [rsi + rcx], ' '
    je .found
    inc rcx
    cmp rcx, 10
    jne .skip
    jmp .done
.found:
    inc rcx ; skip space
    xor rbx, rbx
.copy:
    mov al, [rsi + rcx]
    cmp al, ' '
    je .done
    cmp al, '/'
    je .skip_slash
    mov [rdi + rbx], al
    inc rbx
.skip_slash:
    inc rcx
    cmp rbx, 255
    jl .copy
.done:
    mov byte [rdi + rbx], 0
    pop rdx
    pop rcx
    ret

build_http_header:
    ; rdi: mimebuf, rsi: headerbuf
    mov rcx, 0
    ; copy status
    mov rbx, header_1
.copy1:
    mov al, [rbx + rcx]
    mov [rsi + rcx], al
    cmp al, 0
    je .copy_mime
    inc rcx
    jmp .copy1
.copy_mime:
    dec rcx
    mov rbx, rdi
.copy2:
    mov al, [rbx]
    mov [rsi + rcx], al
    cmp al, 0
    je .copy3
    inc rbx
    inc rcx
    jmp .copy2
.copy3:
    mov rbx, header_2
    mov rdx, 0
.copy4:
    mov al, [rbx + rdx]
    mov [rsi + rcx], al
    inc rcx
    inc rdx
    cmp byte [rbx + rdx -1], 0
    jne .copy4
.done:
    mov rax, rcx ; return header length
    ret

header_1 db "HTTP/1.1 200 OK", 13,10,"Content-Type: ",0
header_2 db 13,10,"Connection: close",13,10,13,10,0

