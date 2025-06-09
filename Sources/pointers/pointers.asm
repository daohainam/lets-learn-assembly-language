%macro linefeed 0
    mov rax, 1
    mov rdi, 1
    mov rsi, linefeed_msg
    mov rdx, 2
    syscall 
%endmacro

%macro print_string 2
    mov rax, 1
    mov rdi, 1
    mov rsi, %1
    mov rdx, %2
    syscall 
%endmacro

section .text
    global _start

_start:
    ; in địa chỉ của x
    print_string address_x_msg, address_x_msg_len
    mov rdi, x
    call print_hex
    linefeed

    ; in giá trị của x
    print_string value_x_msg, value_x_msg_len
    mov rdi, [x]
    call print_hex
    linefeed

    ; in địa chỉ của p
    print_string address_p_msg, address_p_msg_len
    mov rdi, p
    call print_hex
    linefeed

    ; in giá trị của p
    print_string value_p_msg, value_p_msg_len
    mov rdi, [p]
    call print_hex
    linefeed

    print_string p_points_to_x_msg, p_points_to_x_msg_len
    linefeed

    ; p = &x;
    mov rdi, x
    mov [p], rdi

    ; in giá trị của p
    print_string value_p_msg, value_p_msg_len
    mov rdi, [p]
    call print_hex
    linefeed

    print_string change_x_value_msg, change_x_value_msg_len
    linefeed

    ; thay đổi giá trị của x: x = 0x_0000_CAFEBABE_0000
    mov rax, 0x_0000_CAFEBABE_0000
    mov [x], rax

    ; in ra giá trị tại *p
    print_string value_p_dest_msg, value_p_dest_msg_len
    mov rdi, [p]
    mov rdi, [rdi]
    call print_hex

    linefeed

    mov rax, 60
    mov rdi, 0
    syscall

print_hex:
    push rsi
    push rdx
    push rcx
    push rax

    mov rcx, 16                  ; Số chữ số hex cần in
    lea rsi, [hex_buffer + 16]   ; Con trỏ đến cuối buffer
.hex_loop:
    dec rsi                      ; Lùi về 1 byte để ghi ký tự
    mov rax, rdi
    and rax, 0xF                 ; Lấy 4 bit thấp
    cmp rax, 10
    jl .digit
    add al, 'a' - 10
    jmp .store
.digit:
    add al, '0'
.store:
    mov [rsi], al
    shr rdi, 4                   ; Dịch sang phải 4 bit (1 hex digit)
    loop .hex_loop

    ; Ghi ra stdout (sys_write)
    mov rax, 1                   ; syscall: write
    mov rdi, 1                   ; fd: stdout
    mov rdx, 16                  ; số byte cần ghi
    syscall

    pop rax
    pop rcx
    pop rdx
    pop rsi
    ret


section .data
    address_x_msg db 'Address of x: '
    address_x_msg_len equ $ - address_x_msg
    value_x_msg db 'Value of x: '
    value_x_msg_len equ $ - value_x_msg
    address_p_msg db 'Address of p: '
    address_p_msg_len equ $ - address_p_msg
    value_p_msg db 'Value of p: '
    value_p_msg_len equ $ - value_p_msg
    value_p_dest_msg db 'Value of *p: '
    value_p_dest_msg_len equ $ - value_p_dest_msg
    p_points_to_x_msg db 10, 13, 'SET: p = &x;', 10, 13
    p_points_to_x_msg_len equ $ - p_points_to_x_msg
    change_x_value_msg db 10, 13, 'SET: x = 0x_0000_CAFEBABE_0000;', 10, 13
    change_x_value_msg_len equ $ - change_x_value_msg
    linefeed_msg db 10, 13   
    x dq 0x_CAFEBABE_CAFEBABE ; biến x (unsigned long long x = 0x_CAFEBABE_CAFEBABE;)

section .bss
    p resq 1 ; con trỏ p (int *p;)
    hex_buffer resb 16

