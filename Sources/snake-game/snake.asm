; Build with:
; nasm -f elf64 snake.asm -o snake.o
; ld snake.o -o snake
; Run in terminal (Linux) with stty raw -echo; ./snake

BITS 64
DEFAULT REL

section .data
clear_screen     db 27, '[2J', 0
cursor_home      db 27, '[H', 0
game_over_msg    db 27, '[H', 'Game Over! Press Enter to restart.', 0
snake_char       db 'o'
food_char        db 'x'
snake_init_len   equ 3
max_snake_len    equ 2000
width            equ 80
height           equ 25

section .bss
snake_x resb max_snake_len
snake_y resb max_snake_len
snake_len resb 1
food_x   resb 1
food_y   resb 1
dir      resb 1  ; 0=left,1=right,2=up,3=down
char     resb 1

section .text
global _start

_start:
    call init_game
main_loop:
    call read_key
    call move_snake
    call check_collision
    call draw
    jmp main_loop

; ================================
; initialize game
; ================================
init_game:
    mov rsi, clear_screen
    call print_string
    mov rsi, cursor_home
    call print_string
    ; Set initial direction = right
    mov byte [dir], 1
    ; Set initial snake length
    mov byte [snake_len], snake_init_len
    ; Init snake positions
    mov rcx, snake_init_len
    mov rbx, 40  ; mid X
    mov rdx, 12  ; mid Y
.init_loop:
    mov [snake_x + rcx - 1], bl
    mov [snake_y + rcx - 1], dl
    dec bl
    loop .init_loop
    ; Place food
    call place_food
    ret

; ================================
; read key
; ================================
read_key:
    mov eax, 0      ; syscall: read
    mov edi, 0      ; stdin
    mov rsi, char
    mov edx, 3      ; read up to 3 bytes
    syscall
    cmp byte [char], 27  ; ESC?
    jne .check_arrows
    mov eax, 60     ; exit
    xor edi, edi
    syscall

.check_arrows:
    cmp byte [char+1], 91
    jne .done
    mov al, [char+2]
    cmp al, 'A'
    je .up
    cmp al, 'B'
    je .down
    cmp al, 'C'
    je .right
    cmp al, 'D'
    je .left
    jmp .done

.up:
    cmp byte [dir], 3
    je .done
    mov byte [dir], 2
    jmp .done
.down:
    cmp byte [dir], 2
    je .done
    mov byte [dir], 3
    jmp .done
.left:
    cmp byte [dir], 1
    je .done
    mov byte [dir], 0
    jmp .done
.right:
    cmp byte [dir], 0
    je .done
    mov byte [dir], 1
.done:
    ret

; ================================
; move snake
; ================================
move_snake:
    ; Shift body
    mov cl, [snake_len]
    dec cl
.rev:
    mov al, [snake_x + rcx]
    mov [snake_x + rcx + 1], al
    mov al, [snake_y + rcx]
    mov [snake_y + rcx + 1], al
    loop .rev

    ; Move head
    mov al, [snake_x]
    mov bl, [snake_y]
    mov dl, [dir]
    cmp dl, 0
    jne .not_left
    dec al
    jmp .set
.not_left:
    cmp dl, 1
    jne .not_right
    inc al
    jmp .set
.not_right:
    cmp dl, 2
    jne .not_up
    dec bl
    jmp .set
.not_up:
    inc bl
.set:
    mov [snake_x], al
    mov [snake_y], bl

    ; Check if food eaten
    cmp al, [food_x]
    jne .no_eat
    cmp bl, [food_y]
    jne .no_eat
    inc byte [snake_len]
    call place_food
.no_eat:
    ret

; ================================
; draw screen
; ================================
draw:
    mov rsi, clear_screen
    call print_string
    mov rcx, [snake_len]
    xor rbx, rbx
.draw_loop:
    mov al, [snake_x + rbx]
    mov bl, [snake_y + rbx]
    call draw_char_at
    inc rbx
    loop .draw_loop

    ; draw food
    mov al, [food_x]
    mov bl, [food_y]
    mov sil, byte [food_char]
    call draw_at
    ret

; ================================
; check collision
; ================================
check_collision:
    mov al, [snake_x]
    mov bl, [snake_y]
    mov rcx, [snake_len]
    cmp cl, 3
    jl .ok
    mov rsi, 1
.loop:
    mov dl, [snake_x + rsi]
    cmp al, dl
    jne .next
    mov dl, [snake_y + rsi]
    cmp bl, dl
    je .dead
.next:
    inc rsi
    loop .loop
.ok:
    ret
.dead:
    mov rsi, game_over_msg
    call print_string
.wait_key:
    mov eax, 0
    mov edi, 0
    mov rsi, char
    mov edx, 1
    syscall
    cmp byte [char], 10
    jne .wait_key
    call init_game
    ret

; ================================
; place food (simple rand using time)
; ================================
place_food:
    mov eax, 201    ; syscall: time
    xor edi, edi
    syscall
    ; use rax for x and y
    mov bl, al
    and bl, 79
    add bl, 1
    mov [food_x], bl
    shr al, 1
    and al, 23
    add al, 1
    mov [food_y], al
    ret

; ================================
; draw_char_at: al = x, bl = y, draw 'o'
; ================================
draw_char_at:
    push rsi
    mov sil, [snake_char]
    call draw_at
    pop rsi
    ret

; ================================
; draw_at: al = x, bl = y, sil = char
; ================================
draw_at:
    push rdi
    mov rdi, 1
    mov edx, 1
    mov ah, 0
    mov rsi, rsp
    mov [rsp-1], sil
    sub rsp, 1
    ; ANSI cursor move
    mov rax, 1
    call set_cursor
    mov eax, 1
    syscall
    add rsp, 1
    pop rdi
    ret

; ================================
; set_cursor: al = x, bl = y
; ================================
set_cursor:
    ; builds ANSI "\033[%d;%dH"
    push rbx
    push rax
    mov rsi, cursor_home
    call print_string
    pop rax
    pop rbx
    ret

; ================================
; print_string: rsi = zero-term string
; ================================
print_string:
    mov rdi, rsi
    xor rcx, rcx
.find_len:
    cmp byte [rdi + rcx], 0
    je .done_len
    inc rcx
    jmp .find_len
.done_len:
    mov eax, 1
    mov edi, 1
    mov edx, ecx
    syscall
    ret
