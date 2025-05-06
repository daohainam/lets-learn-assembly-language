;-----------------------
; Hàm str_to_int: chuỗi -> số
; Input: RSI = địa chỉ chuỗi
; Output: RAX = số nguyên (64-bit)
;-----------------------
str_to_int:
    xor rax, rax
    xor rbx, rbx
.next_digit:
    mov bl, byte [rsi]
    cmp bl, 10
    je .done
    cmp bl, 13
    je .done
    cmp bl, 0
    je .done
    sub bl, '0'
    imul rax, rax, 10
    add rax, rbx
    inc rsi
    jmp .next_digit
.done:
    ret

;-----------------------
; Hàm int_to_str
; Input: RAX = số nguyên
; Output: input_buf = chuỗi kết quả (kết thúc bằng newline)
;-----------------------
int_to_str:
    mov rsi, input_buf
    add rsi, 31
    mov byte [rsi], 10      ; newline
    dec rsi
    xor rcx, rcx

.convert:
    xor rdx, rdx
    mov rbx, 10
    div rbx
    add dl, '0'
    mov [rsi], dl
    dec rsi
    inc rcx
    test rax, rax
    jnz .convert

    inc rsi
    mov rdi, rsi
    mov rdx, rcx
    inc rdx                 ; để in cả newline
    ret
