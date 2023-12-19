BITS 16
ORG 7c00H

start:
    mov [BOOT_DISK], dl ; save boot drive number
    xor ax, ax ; set ax to 0
    mov ds, ax ; set ds to 0
    mov es, ax ; set es to 0
    mov ss, ax ; set ss to 0
    mov sp, 7c00h ; set sp to 7c00h

    ; setup es:bx to point to the sector to load to memory
    mov bx, 0100h
    mov es, bx
    mov bx, 0000h

    mov dl, [BOOT_DISK] ; boot from boot drive
    mov ch, 0x00 ; cylinder
    mov dh, 0x00 ; head
    mov cl, 0x02 ; sector read after boot sector

    mov ah, 0x02 ; read disk function
    mov al, 0x04 ; number of sectors to read
    int 0x13     ; call interrupt 13h

    jc disk_error ; jump if carry flag is set

    mov ax, 0100h ; setup segment registers
    mov ds, ax
    ; mov es, ax
    ; mov ss, ax
    ; mov sp, ax

    jmp 0100h:0000h ; jump to the loaded sector 

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
BOOT_DISK db 0

times 510-($-$$) db 0
dw 0xaa55