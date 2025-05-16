global print_str

;-----------------------
; print_str
; Input: RDI = địa chỉ chuỗi, RDX = độ dài
;-----------------------
print_str:
    mov rax, 1              ; write
    mov rdi, 1              ; stdout
    syscall
    ret