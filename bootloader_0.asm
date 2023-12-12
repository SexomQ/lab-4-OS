BITS 16
ORG 7c00H

start:
    ; setup es:bx to point to the sector to load to memory
    mov bx, 0x7e00
    mov es, bx
    mov bx, 0x0000

    mov dl, 0x00 ; boot from boot drive
    mov ch, 0x00 ; cylinder
    mov dh, 0x00 ; head
    mov cl, 0x02 ; sector read after boot sector

    mov ah, 0x02 ; read disk function
    mov al, 0x04 ; number of sectors to read
    int 0x13     ; call interrupt 13h

    jc disk_error ; jump if carry flag is set

    mov ax, 0x7e00
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, ax

    jmp 0x7e00:0x0000

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

error_disk dd "Disk Error!", 10, 13, 0

times 510-($-$$) db 0
dw 0xaa55