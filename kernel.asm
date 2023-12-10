
section .data
    WAIT_FOR_ENTER db "Press ENTER to restart...", 0
    pointer_store dw 0 ; used by str_len to avoid changing extra registers

section .bss
    input resb 1

section .text
    global main

main:
    call clear_screen

    mov si, WAIT_FOR_ENTER
    mov bh, 0
    mov bl, 0x0F
    mov dh, 0
    mov dl, 0
    call print_string

    jmp $

clear_screen:
    mov ah, 0
    mov al, 3
    int 0x10
    ret


;; Gets string length
;; Parameters: si - pointer to string
;; Returns:    cx    - string length
;; Notes       String must be zero terminated
str_len:
    mov cx, 0
    mov [pointer_store], si
    cmp byte [si], 0
    je .str_len_end

    .str_len_loop:
        inc cx
        inc si
        cmp byte [si], 0
        jne .str_len_loop

    .str_len_end:
        mov si, [pointer_store]
        ret

;; Prints zero terminated string
;; Parameters: bh    - page number
;;             bl    - video attribute http://www.techhelpmanual.com/87-screen_attributes.html
;;             dh,dl - coords to start writing
;;             si - pointer to string
;; Returns:    None
print_string:
    pusha
    ;; Get string length
    call str_len
    mov ax, 1300h
    mov bp, si
    int 10h
    popa
    ret 

times 512 - ($-$$) db 0