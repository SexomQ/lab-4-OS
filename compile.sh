#!/bin/bash

bootloader="bootloader_0.asm"
bootloader2="bootloader.asm"
program="program.asm"
dopping="dopping.asm"
kernel="kernel.asm"

filename1=$(basename "$bootloader" | cut -d. -f1)
filename2=$(basename "$bootloader2" | cut -d. -f1)
filename3=$(basename "$kernel" | cut -d. -f1)
filename4=$(basename "$program" | cut -d. -f1)
filename5=$(basename "$dopping" | cut -d. -f1)

nasm -f bin -o "$filename1.bin" "$filename1.asm"
nasm -f bin -o "$filename2.bin" "$filename2.asm"
nasm -f bin -o "$filename3.bin" "$filename3.asm"
nasm -f bin -o "$filename4.bin" "$filename4.asm"
nasm -f bin -o "$filename5.bin" "$filename5.asm"

cat "$filename1.bin" "$filename2.bin" "$filename4.bin" "$filename5.bin" "$filename3.bin" > "boot.flp"

truncate -s 1474560 "boot.flp"

rm $filename1.bin $filename2.bin $filename3.bin $filename4.bin $filename5.bin

echo "File: 'boot.flp' is compiled"
