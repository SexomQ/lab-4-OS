start:
    ; setup es:bx to point to the sector to load to memory
    mov bx, 8500h
    mov es, bx
    mov bx, 0000h

    mov dl, 0x00 ; boot from boot drive
    mov ch, 0x00 ; cylinder
    mov dh, 0x00 ; head
    mov cl, 0x07 ; sector read after boot sector

    mov ah, 0x02 ; read disk function
    mov al, 0x01 ; number of sectors to read
    int 0x13     ; call interrupt 13h

    mov ax, 8500h ; setup segment registers
    mov ds, ax
    ; mov es, ax
    ; mov ss, ax
    ; mov sp, ax

    jmp 8500h:0000h ; jump to the loaded sector

times 512-($-$$) db 0 ; pad the rest of the sector with zeros