global get_mime_type

section .rodata
    ; MIME table: [ext, mimetype]
    mime_table:
        db ".html",0,"text/html",0
        db ".css",0,"text/css",0
        db ".js",0,"application/javascript",0
        db ".png",0,"image/png",0
        db ".jpg",0,"image/jpeg",0
        db ".jpeg",0,"image/jpeg",0
        db ".txt",0,"text/plain",0
        db 0
    plain db "text/plain", 0

section .text

get_mime_type:
    ; rdi: filepath, rsi: mimebuf
    push rdi
    push rsi
    ; find last dot
    mov rbx, rdi
.find_dot:
    cmp byte [rbx], 0
    je .noext
    cmp byte [rbx], '.'
    je .found
    inc rbx
    jmp .find_dot
.found:
    ; rbx = .ext
    lea rdx, [mime_table]
.next:
    cmp byte [rdx], 0
    je .noext
    ; compare ext
    mov rdi, rbx
    mov rsi, rdx
    call strcmp
    cmp rax, 0
    jne .skip
    ; match: copy mime type
    .cpy:
        ; skip ext
        .skip0:
        cmp byte [rdx], 0
        je .start_cpy
        inc rdx
        jmp .skip0
    .start_cpy:
        inc rdx
        mov rcx, 0
    .copy_loop:
        mov al, [rdx + rcx]
        mov [rsi + rcx], al
        cmp al, 0
        je .done
        inc rcx
        jmp .copy_loop
.skip:
    ; skip ext and mime
    .sk:
    cmp byte [rdx], 0
    je .sk2
    inc rdx
    jmp .sk
.sk2:
    inc rdx
    cmp byte [rdx], 0
    je .next
    jmp .next
.noext:
    ; default: text/plain
    mov rax, 0
    mov rbx, rsi
    mov rdi, plain
.cp:
    mov al, [rdi + rax]
    mov [rbx + rax], al
    cmp al, 0
    je .done
    inc rax
    jmp .cp
.done:
    pop rsi
    pop rdi
    ret

strcmp:
    xor rax, rax
.loop:
    mov al, [rdi]
    mov bl, [rsi]
    cmp al, bl
    jne .diff
    test al, al
    je .same
    inc rdi
    inc rsi
    jmp .loop
.same:
    xor rax, rax
    ret
.diff:
    mov rax, 1
    ret
