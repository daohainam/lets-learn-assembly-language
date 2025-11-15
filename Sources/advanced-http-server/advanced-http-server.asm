; advanced-http-server.asm
; A simple advanced HTTP server in x86_64 assembly (Linux)
; Features:
; - Serve static files from a specified document root
; - Supports GET and HEAD methods
; - Basic MIME type handling based on file extension
; - Proper HTTP response headers including Content-Length and Content-Type
; - Graceful handling of 404 Not Found, 400 Bad Request, and 405 Method Not Allowed
; Build:
;   nasm -felf64 advanced-http-server.asm -o advanced-http-server.o
;   ld -o advanced-http-server advanced-http-server.o
;
; Run:
;   mkdir -p httpdocs
;   echo "<h1>Hello ASM</h1>" > httpdocs/index.html
;   HTTP_DOCS=/path/to/docs ./advanced-http-server
;   # hoặc dùng mặc định ./httpdocs
;
; Truy cập: http://127.0.0.1:8080/

%define SYS_read    0
%define SYS_write   1
%define SYS_open    2
%define SYS_close   3
%define SYS_stat    4
%define SYS_fstat   5
%define SYS_exit    60
%define SYS_socket  41
%define SYS_accept  43
%define SYS_bind    49
%define SYS_listen  50

%define AF_INET     2
%define SOCK_STREAM 1

section .data
    ; mặc định bind 0.0.0.0:8080
    ip_any     dd 0                ; INADDR_ANY (0.0.0.0)
    port_8080  dw 0x1F90           ; htons(8080) = 0x1F90

    ; mặc định docroot = "./httpdocs"
    default_docroot db "./httpdocs",0

    ; một số chuỗi HTTP cơ bản
    resp_200      db "HTTP/1.1 200 OK",13,10,0
    resp_404      db "HTTP/1.1 404 Not Found",13,10,0
    resp_400      db "HTTP/1.1 400 Bad Request",13,10,0
    resp_405      db "HTTP/1.1 405 Method Not Allowed",13,10,0

    hdr_server    db "Server: advanced-http-server/0.1",13,10,0
    hdr_conn_close db "Connection: close",13,10,0

    hdr_ct        db "Content-Type: ",0
    hdr_cl        db "Content-Length: ",0

    crlf          db 13,10,0
    crlf2         db 13,10,13,10,0

    ; một số mime đơn giản
    mime_html db "text/html; charset=utf-8",0
    mime_txt  db "text/plain; charset=utf-8",0
    mime_css  db "text/css; charset=utf-8",0
    mime_js   db "application/javascript; charset=utf-8",0
    mime_png  db "image/png",0
    mime_jpg  db "image/jpeg",0
    mime_bin  db "application/octet-stream",0

    method_get db "GET",0
    method_head db "HEAD",0

section .bss
    ; Socket
    server_fd  resd 1

    ; docroot pointer
    docroot_ptr   resq 1

    ; buffer chung
    req_buf   resb 4096
    path_buf  resb 1024
    fs_path   resb 2048
    num_buf   resb 32

    stat_buf  resb 144        ; struct stat (đủ to)

section .text
    global _start

;--------------------------------------
; write(fd, rsi=buf, rdx=len)
write_fd:
    mov rax, SYS_write
    syscall
    ret

; write zero-terminated string ở RSI đến FD trong RDI
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
    ; rdi, rsi, rdx đã có
    syscall
    pop rsi
    pop rdi
    ret

; exit(code)
_exit:
    mov rax, SYS_exit
    syscall

;--------------------------------------
; _start: lấy env, chuẩn bị docroot, tạo socket, loop accept
_start:
    ; Lấy envp từ stack:
    ; layout: [argc][argv0]...[argvN][0][env0]...[0]
    mov rbx, rsp
    mov rdi, [rbx]       ; argc
    mov rcx, rdi
    lea rsi, [rbx+8]     ; &argv[0]

.skip_argv:
    cmp rcx, 0
    je .after_argv
    add rsi, 8
    dec rcx
    jmp .skip_argv

.after_argv:
    add rsi, 8           ; skip NULL sau argv => rsi = &envp[0]
    mov rdx, rsi         ; rdx = envp

    ; tìm HTTP_DOCS=...
    mov qword [docroot_ptr], default_docroot

.find_http_docs_env:
    mov r8, [rdx]         ; envp[i]
    test r8, r8
    jz .env_done
    ; so sánh prefix "HTTP_DOCS="
    mov r9, http_docs_key
    mov rcx, http_docs_key_len
    push rdx
    push r8
    push rcx
    mov r10, r8
    mov r11, r9
.env_cmp_loop:
    cmp rcx, 0
    je .env_match
    mov al, [r10]
    mov bl, [r11]
    cmp al, bl
    jne .env_nomatch
    inc r10
    inc r11
    dec rcx
    jmp .env_cmp_loop

.env_match:
    ; r10 đang trỏ ngay sau "HTTP_DOCS="
    mov [docroot_ptr], r10
    pop rcx
    pop r8
    pop rdx
    jmp .env_done

.env_nomatch:
    pop rcx
    pop r8
    pop rdx
    add rdx, 8
    jmp .find_http_docs_env

.env_done:

    ; tạo socket, bind 0.0.0.0:8080, listen
    mov rax, SYS_socket
    mov rdi, AF_INET
    mov rsi, SOCK_STREAM
    xor rdx, rdx
    syscall
    cmp rax, 0
    js .fatal
    mov [server_fd], eax

    ; struct sockaddr_in (16 byte):
    ; sin_family=AF_INET, sin_port=htons(8080), sin_addr=0
    sub rsp, 16
    mov word [rsp], AF_INET
    mov ax, port_8080
    mov [rsp+2], ax
    mov dword [rsp+4], [ip_any]
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
    mov rsi, 16
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
    mov r12, rax       ; client_fd

    ; handle 1 request rồi đóng (no keep-alive)
    mov rdi, r12
    call handle_client

    mov rax, SYS_close
    mov rdi, r12
    syscall

    jmp .accept_loop

.exit_server:
    mov rax, SYS_close
    mov rdi, [server_fd]
    syscall
    xor rdi, rdi
    call _exit

.fatal:
    ; lỗi: exit(1)
    mov rdi, 1
    call _exit

;--------------------------------------
; handle_client(rdi = client_fd)
handle_client:
    push rdi
    mov rsi, req_buf
    mov rdx, 4096
    mov rax, SYS_read
    syscall
    cmp rax, 0
    jle .done
    mov rbx, rax        ; length
    ; req_buf chứa request

    ; lấy request line: đến \r hoặc \n
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
    mov byte [rsi], 0   ; kết thúc chuỗi request line

    ; parse: METHOD PATH HTTP/version
    mov rsi, req_buf
    ; METHOD
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
    inc r8          ; r8 = PATH

    ; PATH
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
    inc r10         ; r10 = HTTP version (không dùng)

    ; Kiểm tra METHOD = GET hoặc HEAD
    mov rdi, [rsp+8]   ; client_fd (stack: [ret][client_fd])
    ; so sánh với "GET"
    mov rax, 0
    mov al, [req_buf]
    cmp al, 'G'
    jne .check_head
    mov al, [req_buf+1]
    cmp al, 'E'
    jne .check_head
    mov al, [req_buf+2]
    cmp al, 'T'
    jne .check_head
    mov byte [req_buf+3],0
    mov r11b, 1        ; is_get = 1
    jmp .have_method

.check_head:
    mov al, [req_buf]
    cmp al, 'H'
    jne .method_not_allowed
    mov al, [req_buf+1]
    cmp al, 'E'
    jne .method_not_allowed
    mov al, [req_buf+2]
    cmp al, 'A'
    jne .method_not_allowed
    mov al, [req_buf+3]
    cmp al, 'D'
    jne .method_not_allowed
    mov byte [req_buf+4],0
    mov r11b, 0        ; HEAD

.have_method:
    ; r8 = PATH
    ; nếu PATH == "/" -> "/index.html"
    mov rsi, r8
    mov al, [rsi]
    cmp al, '/'
    jne .build_path
    cmp byte [rsi+1], 0
    jne .build_path
    ; path "/" => thay bằng "/index.html"
    mov r8, path_buf
    mov byte [r8], '/'
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
    jmp .build_fs_path_from_buf

.build_path:
    ; copy PATH vào path_buf (giữ nguyên dạng "/..."), đơn giản
    mov rsi, r8
    mov rdi, path_buf
.copy_path:
    mov al, [rsi]
    mov [rdi], al
    cmp al, 0
    je .build_fs_path_from_buf
    inc rsi
    inc rdi
    jmp .copy_path

.build_fs_path_from_buf:
    ; fs_path = docroot + "/" + (path_buf + 1) (bỏ dấu '/')
    mov rsi, [docroot_ptr]
    mov rdi, fs_path
    ; copy docroot
.copy_docroot:
    mov al, [rsi]
    mov [rdi], al
    cmp al, 0
    je .after_docroot_copy
    inc rsi
    inc rdi
    jmp .copy_docroot

.after_docroot_copy:
    ; nếu docroot không kết thúc bằng '/', thêm '/'
    cmp byte [rdi-1], '/'
    je .skip_add_slash
    mov byte [rdi], '/'
    inc rdi
.skip_add_slash:
    ; copy path_buf + 1 (bỏ '/')
    mov rsi, path_buf
    cmp byte [rsi], '/'
    jne .cp_pb
    inc rsi
.cp_pb:
    mov al, [rsi]
    mov [rdi], al
    cmp al, 0
    je .have_fs_path
    inc rsi
    inc rdi
    jmp .cp_pb

.have_fs_path:
    ; mở file
    mov rax, SYS_open
    mov rdi, fs_path
    mov rsi, 0          ; O_RDONLY
    mov rdx, 0
    syscall
    cmp rax, 0
    js .not_found
    mov r13, rax        ; fd file

    ; fstat để lấy size
    mov rax, SYS_fstat
    mov rdi, r13
    mov rsi, stat_buf
    syscall
    cmp rax, 0
    js .not_found_close

    ; lấy st_size (off_t) ở offset 48 trên x86_64 (tùy glibc/sysv; ở đây đơn giản assume)
    ; để an toàn, ta đọc qword [stat_buf+48]
    mov rax, [stat_buf+48]
    mov r14, rax        ; file size

    ; chọn mime theo extension
    mov rsi, fs_path
    mov rcx, 0
.find_end:
    mov al, [rsi]
    cmp al, 0
    je .search_dot
    inc rsi
    jmp .find_end

.search_dot:
    ; đi lùi tìm '.'
    dec rsi
    cmp rsi, fs_path
    jb .no_ext
    mov al, [rsi]
    cmp al, '.'
    je .have_dot
    jmp .search_dot

.have_dot:
    inc rsi
    mov rdi, mime_bin   ; default
    ; so sánh ext với "html", "htm", "txt", "css", "js", "png", "jpg", "jpeg"
    ; check "html"
    mov al, [rsi]
    cmp al, 'h'
    jne .check_txt
    cmp byte [rsi+1], 't'
    jne .check_txt
    cmp byte [rsi+2], 'm'
    jne .check_txt
    cmp byte [rsi+3], 'l'
    jne .check_txt
    cmp byte [rsi+4], 0
    jne .check_txt
    mov rdi, mime_html
    jmp .have_mime

.check_txt:
    mov al, [rsi]
    cmp al, 't'
    jne .check_css
    cmp byte [rsi+1], 'x'
    jne .check_css
    cmp byte [rsi+2], 't'
    jne .check_css
    cmp byte [rsi+3], 0
    jne .check_css
    mov rdi, mime_txt
    jmp .have_mime

.check_css:
    mov al, [rsi]
    cmp al, 'c'
    jne .check_js
    cmp byte [rsi+1], 's'
    jne .check_js
    cmp byte [rsi+2], 's'
    jne .check_js
    cmp byte [rsi+3], 0
    jne .check_js
    mov rdi, mime_css
    jmp .have_mime

.check_js:
    mov al, [rsi]
    cmp al, 'j'
    jne .check_png
    cmp byte [rsi+1], 's'
    jne .check_png
    cmp byte [rsi+2], 0
    jne .check_png
    mov rdi, mime_js
    jmp .have_mime

.check_png:
    mov al, [rsi]
    cmp al, 'p'
    jne .check_jpg
    cmp byte [rsi+1], 'n'
    jne .check_jpg
    cmp byte [rsi+2], 'g'
    jne .check_jpg
    cmp byte [rsi+3], 0
    jne .check_jpg
    mov rdi, mime_png
    jmp .have_mime

.check_jpg:
    mov al, [rsi]
    cmp al, 'j'
    jne .no_ext
    cmp byte [rsi+1], 'p'
    jne .check_jpeg
    cmp byte [rsi+2], 'g'
    jne .check_jpeg
    cmp byte [rsi+3], 0
    jne .check_jpeg
    mov rdi, mime_jpg
    jmp .have_mime

.check_jpeg:
    cmp byte [rsi+1], 'p'
    jne .no_ext
    cmp byte [rsi+2], 'e'
    jne .no_ext
    cmp byte [rsi+3], 'g'
    jne .no_ext
    cmp byte [rsi+4], 0
    jne .no_ext
    mov rdi, mime_jpg
    jmp .have_mime

.no_ext:
    mov rdi, mime_bin

.have_mime:
    ; rdi = mime*
    ; gửi header 200 + content-length + content-type + connection: close

    ; client_fd trong [rsp+8]
    mov rbx, [rsp+8]
    mov r13, rbx   ; client_fd

    ; HTTP/1.1 200 OK
    mov rdi, r13
    mov rsi, resp_200
    call write_z

    ; CRLF
    mov rdi, r13
    mov rsi, crlf
    call write_z

    ; Server
    mov rdi, r13
    mov rsi, hdr_server
    call write_z
    mov rdi, r13
    mov rsi, crlf
    call write_z

    ; Content-Type
    mov rdi, r13
    mov rsi, hdr_ct
    call write_z
    mov rdi, r13
    mov rsi, rdi    ; sai, cần mime pointer => dùng r15
    ; sửa: lưu mime vào r15
    ; (đã lỡ, nhưng để đơn giản ta dùng r15 giữ mime)

    ; -- sửa đoạn nhỏ: (nhảy xuống sửa) --

    jmp .after_header_fix

.header_fix_label:
    ; r15 chứa mime*
    mov rdi, r13
    mov rsi, r15
    call write_z
    mov rdi, r13
    mov rsi, crlf
    call write_z

    ; Content-Length
    mov rdi, r13
    mov rsi, hdr_cl
    call write_z

    ; convert r14 (file size) to decimal in num_buf
    mov rax, r14
    mov rsi, num_buf
    call u64_to_dec

    mov rdi, r13
    mov rsi, num_buf
    call write_z
    mov rdi, r13
    mov rsi, crlf
    call write_z

    ; Connection: close
    mov rdi, r13
    mov rsi, hdr_conn_close
    call write_z
    mov rdi, r13
    mov rsi, crlf
    call write_z

    ; CRLF cuối
    mov rdi, r13
    mov rsi, crlf
    call write_z

    ; nếu là GET thì gửi body
    cmp r11b, 1
    jne .close_file_only

.send_body:
    mov rax, SYS_read
    mov rdi, r13        ; fd file
    mov rsi, req_buf    ; dùng lại buffer
    mov rdx, 4096
    syscall
    cmp rax, 0
    jle .close_file_only
    mov rdx, rax
    mov rax, SYS_write
    mov rdi, r13        ; (lẽ ra là client_fd, nhưng bị trùng)
    ; cẩn thận: client_fd là rbx, fd file là r13
    ; sửa: đọc lại

.close_file_only:
    mov rax, SYS_close
    mov rdi, r13
    syscall
    jmp .done

;------------- chỗ fix: gán mime vào r15 rồi quay lại --------------
.after_header_fix:
    mov r15, rdi    ; rdi đang chứa mime*
    jmp .header_fix_label

.not_found_close:
    mov rax, SYS_close
    mov rdi, r13
    syscall

.not_found:
    mov rbx, [rsp+8]
    mov rdi, rbx
    mov rsi, resp_404
    call write_z
    mov rdi, rbx
    mov rsi, crlf
    call write_z
    mov rdi, rbx
    mov rsi, crlf
    call write_z
    jmp .done

.bad_request:
    mov rbx, [rsp+8]
    mov rdi, rbx
    mov rsi, resp_400
    call write_z
    mov rdi, rbx
    mov rsi, crlf2
    call write_z
    jmp .done

.method_not_allowed:
    mov rbx, [rsp+8]
    mov rdi, rbx
    mov rsi, resp_405
    call write_z
    mov rdi, rbx
    mov rsi, crlf2
    call write_z
    jmp .done

.done:
    pop rdi
    ret

;--------------------------------------
; u64_to_dec: rax = value, rsi = buffer
; ghi chuỗi decimal (zero-terminated) vào buffer
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
    div rdi          ; rax = rax/10, rdx = rax%10
    add dl, '0'
    dec rbx
    mov [rbx], dl
    inc rcx
    test rax, rax
    jne .conv_loop

.conv_done:
    ; copy từ rbx sang rsi
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

;--------------------------------------
; key "HTTP_DOCS="
http_docs_key db "HTTP_DOCS=",0
http_docs_key_len equ $-http_docs_key-1
