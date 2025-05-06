print_rax_hex:
    push rax
    push rbx            ; save rbx (callee-saved)

    mov rbx, rax        ; sao chép giá trị RAX sang RBX để xử lý

    ; in tiền tố "0x"
    mov rax, 1          ; syscall write
    mov rdi, 1          ; stdout
    mov rsi, hex_prefix
    mov rdx, hex_prefix_len
    syscall

    ; chuyển số trong RBX sang hex chuỗi
    mov rcx, 16         ; 16 chữ số hex cho 64-bit
    lea rdi, [hex_buffer + 15]  ; con trỏ tới cuối buffer

convert_loop:
    mov rax, rbx
    and rax, 0xF            ; lấy 4 bit cuối
    cmp rax, 9
    jbe to_digit
    add rax, 'A' - 10
    jmp store

to_digit:
    add rax, '0'

store:
    mov [rdi], al
    dec rdi
    shr rbx, 4
    loop convert_loop

    ; in chuỗi hex
    mov rax, 1          ; syscall write
    mov rdi, 1          ; stdout
    lea rsi, [hex_buffer]
    mov rdx, 16
    syscall

    ; in dấu xuống dòng
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, newline_len
    syscall

    pop rbx
    pop rax
    ret