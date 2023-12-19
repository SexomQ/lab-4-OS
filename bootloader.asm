; BITS 16
; ORG 7e00H


%define BACKSPACE 0x08
%define ENTER 0x0D
%define ESC 0x1B
%define SPACE 0x20
%define MAX_CHARACTER_COUNT 200

section .text
    global main

main:
    ; mov ax, 0x0100
    ; mov ds, ax
    ; mov es, ax

    mov [BOOT_DISK], dl; save boot disk number

    call clear_screen
    mov word [cursor_coords], 010FH
    call sync_cursor    


    mov si, msg
    mov bh, 0; page number
    mov bl, 7; text color
    mov dx, word [cursor_coords]; get the cursor coordinates
    call print_string; print the prompt string

    ; mov ax, 1301H
    ; int 10H 

    call kernel_load

    ; jmp $

kernel_load:

    mov byte [head], 0
    mov byte [cylinder], 0
    mov byte [sector], 0
    mov byte [number_of_sectors], 0
    mov word [ram_address], 0
    mov word [ram_address + 2], 0
    mov word [error_code], 0
    mov word [far_ptr], 0
    mov word [far_ptr + 2], 0

    mov word [cursor_coords], 0301H
    call sync_cursor

    ;; Get the floppy head
    mov si, HEAD_PROMPT
    mov di, conversion_buffer
    call prompt
    ;; Convert the string to a number
    mov si, conversion_buffer
    call string_to_int
    mov byte [head], al

    mov word [cursor_coords], 0401H
    call sync_cursor

    ; get the cylinder
    mov si, CYLINDER_PROMPT
    mov di, conversion_buffer
    call prompt
    ;; Convert the string to a number
    mov si, conversion_buffer
    call string_to_int
    mov byte [cylinder], al

    mov word [cursor_coords], 0501H
    call sync_cursor

    ; get the sector
    mov si, SECTOR_PROMPT
    mov di, conversion_buffer
    call prompt
    ;; Convert the string to a number
    mov si, conversion_buffer
    call string_to_int
    mov byte [sector], al

    mov word [cursor_coords], 0601H
    call sync_cursor

    ; get the sector
    mov si, NUMBER_OF_SECTORS_PROMPT
    mov di, conversion_buffer
    call prompt
    ;; Convert the string to a number
    mov si, conversion_buffer
    call string_to_int
    mov byte [number_of_sectors], al

    mov word [cursor_coords], 0701H
    call sync_cursor

    ; get the ram address
    mov si, RAM_ADDRESS_PROMPT
    mov di, hex_conversion_buffer
    call prompt
    ;; Convert the string to a hex
    mov si, hex_conversion_buffer
    mov di, ram_address
    call string_to_hex

    mov word [cursor_coords], 0801H
    call sync_cursor

    ; get the offset address
    mov si, RAM_OFFSET_PROMPT
    mov di, hex_conversion_buffer
    call prompt
    ;; Convert the string to a hex
    mov si, hex_conversion_buffer
    mov di, ram_address + 2
    call string_to_hex

    mov word [cursor_coords], 0901H
    call sync_cursor

    ; setup es:bx to point to the sector to load to memory
    mov bx, [ram_address]
    mov es, bx
    mov bx, [ram_address + 2]

    mov dl, 0x00 ; boot from boot drive
    mov ch, [cylinder] ; cylinder
    mov dh, [head] ; head
    mov cl, [sector] ; sector

    mov ah, 0x02 ; read disk function
    mov al, [number_of_sectors] ; number of sectors to read
    int 0x13     ; call interrupt 13h

    cmp ah, 0
        mov al, ah; convert ah to ax
        mov ah, 0
        mov [error_code], ax

        mov ax, 0x0100
        mov es, ax ; set es to the segment where the bootloader is loaded

    jne .floppy_error

    ;; print success message
    mov si, FLOPPY_SUCCESS_MSG
    mov dx, 0A01H; cursor coordinates
    mov bl, 2; green color
    mov bh, 0
    call print_string
    mov bl, 0x0F; reset color

    mov dx, 0C01H;
    mov si, WAIT_FOR_ENTER_MSG
    call print_string
    jmp wait_for_enter_ok

    .floppy_error:      
        mov si, FLOPPY_ERROR_MSG
        mov dx, 0A01H; cursor coordinates
        mov bl, 4; red color
        mov bh, 0
        call print_string
        mov bl, 0x0F; reset color
        ;; convert error code to string representation of number
        mov ax, [error_code]
        mov di, conversion_buffer
        call int_to_string
        mov si, conversion_buffer
        mov dx, 0A20H; cursor coordinates
        mov bh, 0
        call print_string

        mov dx, 0C01H;
        mov si, WAIT_FOR_ENTER_TO_RESTART_MSG
        call print_string
        jmp wait_for_enter_not_ok

wait_for_enter_not_ok:
    mov ah, 0
    int 16h

    cmp al, 0dh
    jz main

    jmp wait_for_enter_not_ok

wait_for_enter_ok:
    mov ah, 0
    int 16h

    cmp al, 0dh
    jz jump_to_kernel

    jmp wait_for_enter_ok

jump_to_kernel:
    mov ax, [ram_address + 2]
    mov bx, [ram_address]

    mov [far_ptr], ax
    mov [far_ptr + 2], bx

    jmp far [far_ptr]


clear_screen:
    mov ah, 0x00
    mov al, 0x03
    int 0x10
    ret

disk_error:
    mov bh, 0                 
    mov ax, 0H
    mov es, ax                 
    mov bp, error_disk   

    mov bl, 07H                
    mov cx, 11                
    mov dh, 0                
    mov dl, 0       

    mov ax, 1301H
    int 10H 

;; Prompts input from the user
;; Parameters: si: the string to prompt the user with
;;             di: the buffer to store the user input
;;             global cursor_coords: the coordinates of the cursor to start the prompt at
;; Returns: nothing
;; Mutates: the buffer pointed to by di
;;          the cursor coordinates
;; Notes: maximum input length is 256 characters
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

;; Syncs the cursor with the coordinates stored in cursor_coords
sync_cursor:
    pusha
    mov ah, 0x02
    mov bh, 0x00
    mov dx, [cursor_coords]
    int 0x10
    popa
    ret

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

;; Converts string to uint
;; Parameters: si - string to convert
;; Returns:    ax - converted int
;;             bl - error code
string_to_int:
    pusha
    mov dx, si; save pointer to string
    mov ax, 0
    mov word [result], 0
    .string_to_int_loop:
        ;; check if null character is reached
        cmp byte [si], 0
        je .string_to_int_end
        ;; check if character is digit
        cmp byte [si], '0'
        jl .string_to_int_error
        cmp byte [si], '9'
        jg .string_to_int_error
        ;; convert character to int
        mov bx, 0
        mov bl, [si]
        sub bl, '0'
        ;; multiply current number by 10
        mov cx, 10
        mul cx
        ;; add current digit
        add ax, bx
        inc si
        jmp .string_to_int_loop
    .string_to_int_error:
        popa
        mov bl, 1
        mov ax, 0
        ret
    .string_to_int_end:
        mov [result], ax
        popa
        mov bl, 0
        mov ax, [result]
        ret

;; Converts uint to string
;; Parameters: ax - uint to convert
;;             di - buffer to store string
;; Returns:    Nothing
;; Mutates:    di
int_to_string:
    pusha
    mov bx, 10
    mov cx, 0
    .int_to_string_loop:
        xor dx, dx
        div bx
        push dx
        inc cx
        cmp ax, 0
        jne .int_to_string_loop
    .int_to_string_loop2:
        pop dx
        add dl, '0'
        mov [di], dl
        inc di
        loop .int_to_string_loop2
    mov byte [di], 0
    popa
    ret

string_to_hex:
    atoh_conv_loop:
        cmp     byte [si], 0
        je      atoh_conv_done

        xor     ax, ax
        mov     al, [si]
        cmp     al, 65
        jl      conv_digit  

        conv_letter:
            sub     al, 55
            jmp     atoh_finish_iteration

        conv_digit:
            sub     al, 48

        atoh_finish_iteration:
            mov     bx, [di]
            imul    bx, 16
            add     bx, ax
            mov     [di], bx

            inc     si

        jmp     atoh_conv_loop

    atoh_conv_done:
        ret



; section .data
    msg db "------> Welcome to TUD_OS! by Tudor Sclifos <------", 10, 0
    press db "Press ENTER to continue.", 10, 0
    error_disk db "Disk Error!", 10, 0 

    cursor_coords:
        cursor_x db 0
        cursor_y db 0

    HEAD_PROMPT db "Enter head: ", 0
    CYLINDER_PROMPT db "Enter cylinder: ", 0
    SECTOR_PROMPT db "Enter sector: ", 0   
    NUMBER_OF_SECTORS_PROMPT db "Enter number of sectors: ", 0
    WAIT_FOR_ENTER_MSG db "Press ENTER to continue", 0
    WAIT_FOR_ENTER_TO_RESTART_MSG db "Press ENTER to restart", 0
    FLOPPY_SUCCESS_MSG db "Floppy read/write success", 0
    FLOPPY_ERROR_MSG db "Floppy read/write error: ", 0
    RAM_ADDRESS_PROMPT db "Enter RAM address: ", 0
    RAM_OFFSET_PROMPT db "Enter RAM offset: ", 0

    BOOT_DISK db 0

    result dw 0
    row db 0
    head db 0
    cylinder db 0
    sector db 0
    error_code dw 0
    pointer_store dw 0 ; used by str_len to avoid changing extra registers
    number_of_sectors db 0

    far_ptr:
        dw 0x0000 ; Offset
        dw 0x0000 ; Segment

; section .bss
    conversion_buffer resb 32
    hex_conversion_buffer resb 64 
    ram_address resb 4
    ram_buffer resb 512

    


times 2048 - ($ - $$) db 0
