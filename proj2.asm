red equ 0ch
blue equ 09h
green equ 0ah
white equ 0fh
escape equ 27
cr equ 13
lf equ 10
space equ 32
BUFFER_SIZE equ 250

assume cs:code1, ds:data1

data1 segment
x   dw  160
y   dw  100
k   db  red
x0  dw  0
y0  dw  0
x1  dw  200
y1  dw  200
first_x dw  ?
first_y dw  ?
diff_x  dw  ?
diff_y  dw  ?
step_x  dw  ?
step_y  dw  ?
incrE   dw  ?
incrNE  dw  ?
diff    dw  ?
state   dw  1
number  dw  0
file_handle dw  ?
bytes_read  dw  ?
wrong_character db  ?
buffer_index    dw  0
error_message_1 db  "Pliku nie mozna otworzyc", cr, lf, '$'
error_message_2 db "Nie udalo sie zamknac pliku", cr, lf, '$'
error_message_3 db "Zly format pliku", cr, lf, '$'
error_message_4 db "Bledny stan:", '$'
error_message_5 db "Bledny znak:", '$'
filename    db  200 dup('$')
buffer  db  BUFFER_SIZE dup(0)

include draw.asm
include utils.asm
data1 ends

code1 segment
start1:
    mov ax, seg ws1
    mov ss, ax
    mov sp, offset ws1
    ; kopia ds w es
    mov ax, ds
    mov es, ax

    call copy_arg_to_data

    ; otwórz plik filename
    mov ax, seg filename
    mov ds, ax
    mov dx, offset filename
    mov ah, 3dh
    mov al, 0
    int 21h
    jc file_opening_error
    mov word ptr ds:[file_handle], ax

    ; ds = seg data1
    mov ax, seg data1
    mov ds, ax

    call graphic_mode
    ; -------------------------------------------------------------------

    ; read file
read_file:
    mov ah, 3fh
    mov bx, word ptr ds:[file_handle]
    mov cx, BUFFER_SIZE
    mov dx, offset buffer
    int 21h
    jc file_reading_error
    mov word ptr ds:[bytes_read], ax
    mov si, offset buffer

    xor bx, bx
read_char:
    ; if cx == BUFFER_SIZE jump to read_file
    cmp bx, BUFFER_SIZE
    je read_file
    ; if cx == bytes jump to end
    cmp bx, word ptr ds:[bytes_read]
    je end_read
    ; for character in file:
    ; {
        mov al, byte ptr ds:[si]
        mov byte ptr ds:[wrong_character], al
        mov word ptr ds:[buffer_index], bx
        call evaluate_character
    ; }
    inc bx
    inc si
    jmp read_char
end_read:

    call wait_for_esc
    call text_mode

    ; zamknij plik
    mov bx, word ptr ds:[file_handle]
    mov ah, 3eh
    int 21h
    jc file_closing_error

    call exit
    ;--------------------------------------------------------------


file_opening_error:
    push ax
    push ds
    push dx

    mov ax, seg error_message_1
    mov ds, ax
    mov dx, offset error_message_1
    mov ah, 9
    int 21h

    call wait_for_click

    pop dx
    pop ds
    pop dx
    call exit


file_closing_error:
    mov ax, seg error_message_2
    mov ds, ax
    mov dx, offset error_message_2
    mov ah, 9
    int 21h
    call wait_for_click
    call exit


file_reading_error:
    call exit

code1 ends

stos1 segment stack
    dw 200 dup(?)
ws1 dw ?
stos1 ends

end start1
