global get_mime_type

section .rodata
    ; extension strings
    ext_html    db ".html",0
    ext_htm     db ".htm",0
    ext_css     db ".css",0
    ext_js      db ".js",0
    ext_png     db ".png",0
    ext_jpg     db ".jpg",0
    ext_jpeg    db ".jpeg",0
    ext_txt     db ".txt",0

    ; mime strings
    mime_html   db "text/html; charset=utf-8",0
    mime_css    db "text/css; charset=utf-8",0
    mime_js     db "application/javascript; charset=utf-8",0
    mime_png    db "image/png",0
    mime_jpg    db "image/jpeg",0
    mime_txt    db "text/plain; charset=utf-8",0

    mime_default db "application/octet-stream",0

    ; bảng: ext, mime
    ; mỗi entry: dq ext_ptr, dq mime_ptr
    mime_table:
        dq ext_html, mime_html
        dq ext_htm,  mime_html
        dq ext_css,  mime_css
        dq ext_js,   mime_js
        dq ext_png,  mime_png
        dq ext_jpg,  mime_jpg
        dq ext_jpeg, mime_jpg
        dq ext_txt,  mime_txt
        dq 0,        0          ; kết thúc

    MAX_MIME_LEN equ 63          ; tối đa 63 ký tự + 1 null

section .text

; int strcmp(const char* s1, const char* s2)
; rdi=s1, rsi=s2, rax=0 nếu bằng, !=0 nếu khác
strcmp:
    push rbx
.str_loop:
    mov al, [rdi]
    mov bl, [rsi]
    cmp al, bl
    jne .diff
    test al, al
    je .same
    inc rdi
    inc rsi
    jmp .str_loop
.same:
    xor rax, rax
    pop rbx
    ret
.diff:
    mov rax, 1
    pop rbx
    ret

; void safe_strcpy(dest(mime_buf), src(mime), max_len=63)
; rdi = dest, rsi = src
safe_strcpy:
    push rcx
    push rdx
    mov rcx, MAX_MIME_LEN
.copy_loop:
    cmp rcx, 0
    je .force_null
    mov al, [rsi]
    mov [rdi], al
    cmp al, 0
    je .done
    inc rsi
    inc rdi
    dec rcx
    jmp .copy_loop
.force_null:
    mov byte [rdi], 0
.done:
    pop rdx
    pop rcx
    ret

; get_mime_type(filepath, mime_buf)
; rdi = filepath, rsi = mime_buf
get_mime_type:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15

    mov r12, rdi       ; filepath
    mov r13, rsi       ; mime_buf

    ; tìm dấu '.' cuối cùng
    mov rbx, r12
    xor r14, r14       ; r14 = last_dot = NULL
.find_dot_loop:
    mov al, [rbx]
    cmp al, 0
    je .dot_done
    cmp al, '.'
    jne .next_char
    mov r14, rbx       ; cập nhật last_dot
.next_char:
    inc rbx
    jmp .find_dot_loop

.dot_done:
    test r14, r14
    jz .no_ext         ; không có dấu '.'

    ; r14 = pointer tới '.' trong filepath
    lea rdi, [r14]     ; s1 = extension trong filepath

    mov r15, mime_table

.search_table:
    mov rbx, [r15]     ; ext ptr
    test rbx, rbx
    jz .no_ext         ; hết bảng -> default

    mov rdx, [r15+8]   ; mime ptr
    mov rsi, rbx       ; s2 = ext trong bảng
    call strcmp
    test rax, rax
    jz .match_found

    add r15, 16
    jmp .search_table

.match_found:
    ; copy mime vào mime_buf (r13)
    mov rdi, r13       ; dest
    mov rsi, rdx       ; src = mime ptr
    call safe_strcpy
    jmp .done

.no_ext:
    mov rdi, r13
    mov rsi, mime_default
    call safe_strcpy

.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret
