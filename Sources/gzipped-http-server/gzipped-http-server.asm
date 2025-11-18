%define SYS_read    0
%define SYS_write   1
%define SYS_open    2
%define SYS_close   3
%define SYS_fstat   5
%define SYS_exit    60
%define SYS_socket  41
%define SYS_accept  43
%define SYS_bind    49
%define SYS_listen  50
%define SYS_fork    57

%define AF_INET     2
%define SOCK_STREAM 1

extern get_mime_type

section .rodata
    default_docroot db "./http_docs",0

    resp_200      db "HTTP/1.1 200 OK",13,10,0
    resp_404      db "HTTP/1.1 404 Not Found",13,10,0
    resp_400      db "HTTP/1.1 400 Bad Request",13,10,0
    resp_405      db "HTTP/1.1 405 Method Not Allowed",13,10,0

    hdr_server     db "Server: advanced-http-server/0.1",13,10,0
    hdr_conn_close db "Connection: close",13,10,0
    hdr_ct         db "Content-Type: ",0
    hdr_cl         db "Content-Length: ",0

    crlf           db 13,10,0
    crlf2          db 13,10,13,10,0

    log_prefix     db "[REQ] ",0
    log_crlf       db 13,10,0

    http_docs_key  db "HTTP_DOCS=",0
    http_docs_key_len equ $-http_docs_key-1

    bind_ip_key    db "BIND_IP=",0
    bind_ip_key_len equ $-bind_ip_key-1

    bind_port_key  db "BIND_PORT=",0
    bind_port_key_len equ $-bind_port_key-1

section .bss
    server_fd    resd 1
    docroot_ptr  resq 1
    envp_ptr     resq 1

    bind_port_host resd 1
    bind_ip_host   resd 1

    req_buf   resb 4096
    path_buf  resb 1024
    fs_path   resb 2048
    num_buf   resb 32
    mime_buf  resb 64

    stat_buf  resb 144

section .text
    global _start

write_fd:
    mov rax, SYS_write
    syscall
    ret

write_z:
    push rdi
    push rsi
    mov rcx, rsi
    xor rdx, rdx
.wz_len:
    cmp byte [rcx], 0
    je .wz_go
    inc rcx
    inc rdx
    jmp .wz_len
.wz_go:
    mov rax, SYS_write
    syscall
    pop rsi
    pop rdi
    ret

_exit:
    mov rax, SYS_exit
    syscall

u64_to_dec:
    mov rcx, 0
    lea rbx, [rsi+31]
    mov byte [rbx], 0
    cmp rax, 0
    jne .conv_loop
    dec rbx
    mov byte [rbx], '0'
    jmp .conv_done
.conv_loop:
    xor rdx, rdx
    mov rdi, 10
    div rdi
    add dl, '0'
    dec rbx
    mov [rbx], dl
    inc rcx
    test rax, rax
    jne .conv_loop
.conv_done:
    mov rdi, rsi
.copy_num:
    mov al, [rbx]
    mov [rdi], al
    cmp al, 0
    je .num_done
    inc rbx
    inc rdi
    jmp .copy_num
.num_done:
    ret

find_env_value:
    push rbx
    push r12
    push r13
    mov r12, rdi
    mov r13, rsi
    mov rdx, [envp_ptr]
.env_loop:
    mov r8, [rdx]
    test r8, r8
    jz .not_found
    mov rcx, r13
    mov r10, r8
    mov r11, r12
.cmp_loop:
    cmp rcx, 0
    je .match
    mov al, [r10]
    mov bl, [r11]
    cmp al, bl
    jne .next_env
    inc r10
    inc r11
    dec rcx
    jmp .cmp_loop
.match:
    mov rax, r10
    jmp .done
.next_env:
    add rdx, 8
    jmp .env_loop
.not_found:
    xor rax, rax
.done:
    pop r13
    pop r12
    pop rbx
    ret

parse_port:
    xor eax, eax
    xor ecx, ecx
.pp_loop:
    mov bl, [rdi]
    cmp bl, 0
    je .end
    cmp bl, '0'
    jb .end_err
    cmp bl, '9'
    ja .end_err
    sub bl, '0'
    mov edx, eax
    mov eax, edx
    imul eax, 10
    add eax, ebx
    cmp eax, 65535
    ja .end_err
    inc ecx
    inc rdi
    jmp .pp_loop
.end:
    cmp ecx, 0
    je .end_err
    ret
.end_err:
    xor eax, eax
    ret

parse_ipv4:
    xor eax, eax
    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx
    xor r8d, r8d
    xor r9d, r9d
    xor r10d, r10d
    xor r11d, r11d
    mov esi, 0
.next_octet:
    xor eax, eax
    xor ebx, ebx
.po_loop:
    mov dl, [rdi]
    cmp dl, 0
    je .po_end
    cmp dl, '0'
    jb .po_end
    cmp dl, '9'
    ja .po_end
    sub dl, '0'
    mov ecx, eax
    imul eax, 10
    add eax, edx
    cmp eax, 255
    ja .ipv_err
    inc ebx
    inc rdi
    jmp .po_loop
.po_end:
    cmp ebx, 0
    je .ipv_err
    cmp esi, 0
    je .store_a
    cmp esi, 1
    je .store_b
    cmp esi, 2
    je .store_c
    cmp esi, 3
    je .store_d
    jmp .ipv_err
.store_a:
    mov r8d, eax
    jmp .after_store
.store_b:
    mov r9d, eax
    jmp .after_store
.store_c:
    mov r10d, eax
    jmp .after_store
.store_d:
    mov r11d, eax
.after_store:
    cmp esi, 3
    je .after_last
    mov dl, [rdi]
    cmp dl, '.'
    jne .ipv_err
    inc rdi
    inc esi
    jmp .next_octet
.after_last:
    mov dl, [rdi]
    cmp dl, 0
    jne .ipv_err
    mov eax, r11d
    shl eax, 24
    mov edx, r10d
    shl edx, 16
    or eax, edx
    mov edx, r9d
    shl edx, 8
    or eax, edx
    or eax, r8d
    ret
.ipv_err:
    xor eax, eax
    ret

_start:
    mov rbx, rsp
    mov rdi, [rbx]
    mov rcx, rdi
    lea rsi, [rbx+8]
.skip_argv:
    cmp rcx, 0
    je .after_argv
    add rsi, 8
    dec rcx
    jmp .skip_argv
.after_argv:
    add rsi, 8
    mov [envp_ptr], rsi

    mov qword [docroot_ptr], default_docroot
    mov dword [bind_port_host], 8080
    mov dword [bind_ip_host], 0

    mov rdi, http_docs_key
    mov rsi, http_docs_key_len
    call find_env_value
    test rax, rax
    jz .skip_http_docs
    mov [docroot_ptr], rax
.skip_http_docs:

    mov rdi, bind_port_key
    mov rsi, bind_port_key_len
    call find_env_value
    test rax, rax
    jz .skip_bind_port
    mov rdi, rax
    call parse_port
    test eax, eax
    jz .skip_bind_port
    mov [bind_port_host], eax
.skip_bind_port:

    mov rdi, bind_ip_key
    mov rsi, bind_ip_key_len
    call find_env_value
    test rax, rax
    jz .skip_bind_ip
    mov rdi, rax
    call parse_ipv4
    test eax, eax
    jz .skip_bind_ip
    mov [bind_ip_host], eax
.skip_bind_ip:

    mov rax, SYS_socket
    mov rdi, AF_INET
    mov rsi, SOCK_STREAM
    xor rdx, rdx
    syscall
    cmp rax, 0
    js .fatal
    mov [server_fd], eax

    sub rsp, 16
    mov word [rsp], AF_INET

    mov eax, [bind_port_host]
    mov ax, ax
    xchg al, ah
    mov [rsp+2], ax

    mov eax, [bind_ip_host]
    mov [rsp+4], eax

    mov qword [rsp+8], 0

    mov rax, SYS_bind
    mov rdi, [server_fd]
    mov rsi, rsp
    mov rdx, 16
    syscall
    cmp rax, 0
    js .fatal

    mov rax, SYS_listen
    mov rdi, [server_fd]
    mov rsi, 128
    syscall
    cmp rax, 0
    js .fatal

    add rsp, 16

.accept_loop:
    mov rax, SYS_accept
    mov rdi, [server_fd]
    xor rsi, rsi
    xor rdx, rdx
    syscall
    cmp rax, 0
    js .exit_server

    mov r14, rax

    mov rax, SYS_fork
    syscall
    cmp rax, 0
    jl .fork_error
    je .in_child

    mov rax, SYS_close
    mov rdi, r14
    syscall
    jmp .accept_loop

.fork_error:
    mov rax, SYS_close
    mov rdi, r14
    syscall
    jmp .accept_loop

.in_child:
    mov rax, SYS_close
    mov rdi, [server_fd]
    syscall

    mov rdi, r14
    call handle_client

    xor rdi, rdi
    call _exit

.exit_server:
    mov rax, SYS_close
    mov rdi, [server_fd]
    syscall
    xor rdi, rdi
    call _exit

.fatal:
    mov rdi, 1
    call _exit

handle_client:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15

    mov r15, rdi

    mov rax, SYS_read
    mov rdi, r15
    mov rsi, req_buf
    mov rdx, 4096
    syscall
    cmp rax, 0
    jle .done

    mov rbx, rax

    mov rsi, req_buf
    mov rcx, rbx
.find_eol:
    cmp rcx, 0
    je .bad_request
    mov al, [rsi]
    cmp al, 13
    je .got_line
    cmp al, 10
    je .got_line
    inc rsi
    dec rcx
    jmp .find_eol

.got_line:
    mov byte [rsi], 0

    mov rdi, 1
    mov rsi, log_prefix
    call write_z
    mov rdi, 1
    mov rsi, req_buf
    call write_z
    mov rdi, 1
    mov rsi, log_crlf
    call write_z

    mov rsi, req_buf
    mov rdx, rsi
.find_sp1:
    cmp byte [rdx], ' '
    je .sp1
    cmp byte [rdx], 0
    je .bad_request
    inc rdx
    jmp .find_sp1
.sp1:
    mov byte [rdx], 0
    mov r8, rdx
    inc r8

    mov r9, r8
.find_sp2:
    cmp byte [r9], ' '
    je .sp2
    cmp byte [r9], 0
    je .bad_request
    inc r9
    jmp .find_sp2
.sp2:
    mov byte [r9], 0
    mov r10, r9
    inc r10

    mov r11b, 2
    mov al, [req_buf]
    cmp al, 'G'
    jne .check_head
    cmp byte [req_buf+1], 'E'
    jne .check_head
    cmp byte [req_buf+2], 'T'
    jne .check_head
    mov r11b, 1
    jmp .have_method
.check_head:
    mov al, [req_buf]
    cmp al, 'H'
    jne .method_not_allowed
    cmp byte [req_buf+1], 'E'
    jne .method_not_allowed
    cmp byte [req_buf+2], 'A'
    jne .method_not_allowed
    cmp byte [req_buf+3], 'D'
    jne .method_not_allowed
    mov r11b, 0

.have_method:
    mov rsi, r8
    mov al, [rsi]
    cmp al, '/'
    jne .build_path
    cmp byte [rsi+1], 0
    jne .build_path

    mov r8, path_buf
    mov byte [r8+0], '/'
    mov byte [r8+1], 'i'
    mov byte [r8+2], 'n'
    mov byte [r8+3], 'd'
    mov byte [r8+4], 'e'
    mov byte [r8+5], 'x'
    mov byte [r8+6], '.'
    mov byte [r8+7], 'h'
    mov byte [r8+8], 't'
    mov byte [r8+9], 'm'
    mov byte [r8+10],'l'
    mov byte [r8+11],0
    jmp .build_fs_path

.build_path:
    mov rsi, r8
    mov rdi, path_buf
    mov rcx, 1023
.cp_path_loop:
    cmp rcx, 0
    je .path_trunc
    mov al, [rsi]
    mov [rdi], al
    cmp al, 0
    je .build_fs_path
    inc rsi
    inc rdi
    dec rcx
    jmp .cp_path_loop
.path_trunc:
    mov byte [rdi], 0

.build_fs_path:
    mov rsi, [docroot_ptr]
    mov rdi, fs_path
    mov rcx, 2047
.cp_docroot:
    cmp rcx, 0
    je .fs_trunc
    mov al, [rsi]
    mov [rdi], al
    cmp al, 0
    je .after_docroot
    inc rsi
    inc rdi
    dec rcx
    jmp .cp_docroot
.after_docroot:
    cmp rcx, 0
    je .fs_trunc
    cmp byte [rdi-1], '/'
    je .skip_slash
    mov byte [rdi], '/'
    inc rdi
    dec rcx
.skip_slash:
    mov rsi, path_buf
    cmp byte [rsi], '/'
    jne .cp_pb
    inc rsi
.cp_pb:
    cmp rcx, 0
    je .fs_trunc
    mov al, [rsi]
    mov [rdi], al
    cmp al, 0
    je .have_fs_path
    inc rsi
    inc rdi
    dec rcx
    jmp .cp_pb
.fs_trunc:
    mov byte [rdi], 0

.have_fs_path:
    mov rax, SYS_open
    mov rdi, fs_path
    mov rsi, 0
    mov rdx, 0
    syscall
    cmp rax, 0
    js .not_found
    mov r12, rax

    mov rax, SYS_fstat
    mov rdi, r12
    mov rsi, stat_buf
    syscall
    cmp rax, 0
    js .not_found_close

    mov rax, [stat_buf+48]
    mov r14, rax

    lea rdi, [fs_path]
    lea rsi, [mime_buf]
    call get_mime_type

    mov rdi, r15
    mov rsi, resp_200
    call write_z
    mov rdi, r15
    mov rsi, crlf
    call write_z

    mov rdi, r15
    mov rsi, hdr_server
    call write_z
    mov rdi, r15
    mov rsi, crlf
    call write_z

    mov rdi, r15
    mov rsi, hdr_ct
    call write_z
    mov rdi, r15
    lea rsi, [mime_buf]
    call write_z
    mov rdi, r15
    mov rsi, crlf
    call write_z

    mov rdi, r15
    mov rsi, hdr_cl
    call write_z

    mov rax, r14
    mov rsi, num_buf
    call u64_to_dec
    mov rdi, r15
    mov rsi, num_buf
    call write_z
    mov rdi, r15
    mov rsi, crlf
    call write_z

    mov rdi, r15
    mov rsi, hdr_conn_close
    call write_z
    mov rdi, r15
    mov rsi, crlf
    call write_z

    mov rdi, r15
    mov rsi, crlf
    call write_z

    cmp r11b, 1
    jne .close_file_only
.send_body:
    mov rax, SYS_read
    mov rdi, r12
    mov rsi, req_buf
    mov rdx, 4096
    syscall
    cmp rax, 0
    jle .close_file_only
    mov rdx, rax
    mov rax, SYS_write
    mov rdi, r15
    mov rsi, req_buf
    syscall
    jmp .send_body

.close_file_only:
    mov rax, SYS_close
    mov rdi, r12
    syscall
    jmp .done

.not_found_close:
    mov rax, SYS_close
    mov rdi, r12
    syscall
.not_found:
    mov rdi, r15
    mov rsi, resp_404
    call write_z
    mov rdi, r15
    mov rsi, crlf
    call write_z
    mov rdi, r15
    mov rsi, crlf
    call write_z
    jmp .done

.bad_request:
    mov rdi, r15
    mov rsi, resp_400
    call write_z
    mov rdi, r15
    mov rsi, crlf2
    call write_z
    jmp .done

.method_not_allowed:
    mov rdi, r15
    mov rsi, resp_405
    call write_z
    mov rdi, r15
    mov rsi, crlf2
    call write_z
    jmp .done

.done:
    mov rax, SYS_close
    mov rdi, r15
    syscall

    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret
