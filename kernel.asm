start:
    ; setup es:bx to point to the sector to load to memory
    mov bx, 8900h
    mov es, bx
    mov bx, 0000h

    mov dl, 0x00 ; boot from boot drive
    mov ch, 0x00 ; cylinder
    mov dh, 0x00 ; head
    mov cl, 0x06 ; sector read after boot sector

    mov ah, 0x02 ; read disk function
    mov al, 0x02 ; number of sectors to read
    int 0x13     ; call interrupt 13h

    mov ax, 8900h ; setup segment registers
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, ax

    jmp 8900h:0000h ; jump to the loaded sector
    

    WAIT_FOR_ENTER_TO_RESTART_MSG db "Press ENTER to restart", 0
    WAIT_FOR_ENTER db "Press ENTER to start", 0
    INPUT_PROMPT db "Input:  ", 0
    pointer_store dw 0 ; used by str_len to avoid changing extra registers

    cursor_coords:
        cursor_x db 0
        cursor_y db 0

times 512-($-$$) db 0 ; pad the rest of the sector with zeros