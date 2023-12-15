%define BACKSPACE 0x08
%define ENTER 0x0D
%define ESC 0x1B
%define SPACE 0x20
%define MAX_CHARACTER_COUNT 200

main:

    call clear_screen
    mov word [cursor_coords], 0101h
    call sync_cursor

    mov si, WAIT_FOR_ENTER
    mov bh, 0 ; page number
    mov bl, 0ch ; text color
    mov dx, word [cursor_coords]
    call print_string; print the prompt string

    jmp wait_enter_continue

wait_enter_continue:
    mov ah, 0
    int 16h

    cmp al, 0dh
    jz get_input

    jmp wait_enter_continue

get_input:
    mov word [cursor_coords], 0301h
    call sync_cursor

    ;; Get the floppy head
    mov si, INPUT_PROMPT
    mov di, input
    call prompt
    ;; Convert the string to a number
    mov si, input
    call invert_string

    mov word [cursor_coords], 0601h
    call sync_cursor
    
    mov si, di
    call print_string

    ; mov word [cursor_coords], 0401H
    ; call sync_cursor

    ; jmp $

;; Invert the string from si
;; Parameters: si - pointer to string
;;             di - pointer to output string
;; Returns:    None

invert_string:
    

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

sync_cursor:
    pusha
    mov ah, 0x02
    mov bh, 0x00
    mov dx, [cursor_coords]
    int 0x10
    popa
    ret

prompt:
    pusha
    mov bh, 0; page number
    mov bl, 7; text color
    mov dx, word [cursor_coords]; get the cursor coordinates
    call print_string; print the prompt string

    call str_len; get the length of the prompt string
    mov byte [cursor_x], cl
    call sync_cursor; sync the cursor with the coordinates
    mov cx, 0; character counter
    .prompt_read_char:
        mov ah, 0
        int 16h

        cmp al, BACKSPACE; if the character is backspace
        je .prompt_handle_backspace; jump to handle_backspace
        cmp al, ENTER; if the character is enter
        je .prompt_handle_enter; jump to handle_enter
        jmp .prompt_handle_symbol; jump to handle_symbol

    .prompt_handle_symbol:
        cmp cx, MAX_CHARACTER_COUNT; if the character counter is equal to the maximum character count
        je .prompt_read_char

        mov [di], al; store the character in the buffer
        inc di; increment the buffer pointer
        inc cx; increment the character counter
        inc byte [cursor_x]; increment the cursor x coordinate
        pusha; save all registers
        mov ah, 0eh; print the character
        int 10h
        popa; restore all registers
        jmp .prompt_read_char; read another character

    .prompt_handle_backspace:
        cmp cx, 0; if the character counter is 0, do nothing
        je .prompt_read_char

        dec di; decrement the buffer pointer
        dec cx; decrement the character counter
        dec byte [cursor_x]; decrement the cursor x coordinate
        call sync_cursor;
        pusha; save all registers
        mov ah, 0AH; print the character at the cursor position
        mov bh, 0; page number
        mov cx, 1; number of times to print the character
        mov al, ' '; print a space
        int 10h
        popa; restore all registers
        jmp .prompt_read_char; read another character

    .prompt_handle_enter:
        ;; don't do anything if string length is 0
        cmp cx, 0
        je .prompt_read_char
        mov byte [di], 0; null terminate the string
        inc di; increment the buffer pointer
        popa
        ret


; section .data
    WAIT_FOR_ENTER_TO_RESTART_MSG db "Press ENTER to restart", 0
    WAIT_FOR_ENTER db "Press ENTER to start", 0
    INPUT_PROMPT db "Input:  ", 0
    pointer_store dw 0 ; used by str_len to avoid changing extra registers

    cursor_coords:
        cursor_x db 0
        cursor_y db 0

; section .bss
    input resb 200
    output resb 200


times 1024 - ($-$$) db 0