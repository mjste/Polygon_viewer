wait_for_click proc far
    push ax
    xor ax, ax
    int 16h
    pop ax
    ret
wait_for_click endp


wait_for_esc proc far
    push ax
wait_for_esc_label:
    mov ah, 07h
    int 21h
    cmp al, escape
    jnz wait_for_esc_label
    pop ax
    ret
wait_for_esc endp


print_line proc far
    push ax
    push dx
    mov ah, 2
    mov dl, cr
    int 21h
    mov dl, lf
    int 21h
    pop dx
    pop ax
    ret
print_line endp


exit proc far
    mov ax, 4c00h
    int 21h
exit endp


graphic_mode proc far
    push ax
    mov ah, 0; zmiana trybu karty VGA
    mov al, 13h; tryb 320 x 200 256 kol
    int 10h
    pop ax
    ret
graphic_mode endp


text_mode proc far
    push ax
    mov ah, 0
    mov al, 3
    int 10h
    pop ax
    ret
text_mode endp


copy_arg_to_data proc far
    push ax
    push dx
    push bx
    push si
    push es

    ; kopiuj argument do filename
    mov ax, seg filename
    mov ds, ax
    mov bx, 0
    mov si, offset filename

L01:
    mov al, byte ptr es:[82h][bx]
    mov byte ptr ds:[si], al
    inc bx
    inc si
    cmp al, cr
    jne L01
    ; argument skopiowano
    dec si
    mov byte ptr ds:[si], 0
    ; zmieniono ostatni znak na zero zamiast cr

    pop es
    pop si
    pop bx
    pop dx
    pop ax

    ret
copy_arg_to_data endp


evaluate_character proc far
    ; przyjmuje znak w al
    push si
    push bx
    push dx
    push cx

    ; switch w zależności od stanu
    ; if state == 1
state1:
    cmp ds:[state], 1
    jne state2
    ; {
    ; sprawdź czy al jest literą
case_white:
    cmp al, 'B'
    jne case_blue
    mov byte ptr ds:[k], white
    jmp end_color_case
case_blue:
    cmp al, 'N'
    jne case_red
    mov byte ptr ds:[k], blue
    jmp end_color_case
case_red:
    cmp al, 'C'
    jne case_green
    mov byte ptr ds:[k], red
    jmp end_color_case
case_green:
    cmp al, 'Z'
    jne default_color_case
    mov byte ptr ds:[k], green
    jmp end_color_case
default_color_case:
    call error_wrong_format
end_color_case:
    mov word ptr ds:[state], 2
    jmp state_end
    ; }

state2:
    ; if state == 2
    cmp ds:[state], 2
    jne state3
    ; {
    cmp al, space
    jne error_wrong_format
    mov word ptr ds:[number], 0
    mov word ptr ds:[state], 3
    jmp state_end
    ; }

state3:
    ; if state == 3
    cmp ds:[state], 3
    jne state4
    ; {
    cmp al, ','
    je comma3
    cmp al, '0'
    jl error_wrong_format
    cmp al, '9'
    jg error_wrong_format
digit3:
    xor cx, cx
    mov cl, al
    mov ax, word ptr ds:[number]
    mov bx, 10
    mul bx
    sub cl, '0'
    add ax, cx ; w ax numer
    cmp ax, 320
    jge error_wrong_format
    mov word ptr ds:[number], ax
    jmp state_end
comma3:
    ; umieść liczbę w x first, x0, x1, x
    mov ax, word ptr ds:[number]
    mov word ptr ds:[x], ax
    mov word ptr ds:[x0], ax
    mov word ptr ds:[x1], ax
    mov word ptr ds:[first_x], ax
    mov word ptr ds:[number], 0
    mov word ptr ds:[state], 4
    jmp state_end
    ; }

state4:
    ; if state == 4
    cmp ds:[state], 4
    jne state5
    ; {
    cmp al, ' '
    je space4
    cmp al, cr
    je carriage4
    cmp al, '0'
    jl error_wrong_format
    cmp al, '9'
    jg error_wrong_format
digit4: ; '0' <= al <= '9'
    xor cx, cx
    mov cl, al
    mov ax, word ptr ds:[number]
    mov bx, 10
    mul bx
    sub cl, '0'
    add ax, cx ; w ax numer
    cmp ax, 320
    jge error_wrong_format
    mov word ptr ds:[number], ax
    jmp state_end
space4:
    ; umieść liczbę w y first, y0, y1, y
    mov ax, word ptr ds:[number]
    mov word ptr ds:[y], ax
    mov word ptr ds:[y0], ax
    mov word ptr ds:[y1], ax
    mov word ptr ds:[first_y], ax
    mov word ptr ds:[number], 0
    mov word ptr ds:[state], 5
    jmp state_end
carriage4:
    mov ax, word ptr ds:[number]
    mov word ptr ds:[y], ax
    mov word ptr ds:[y0], ax
    mov word ptr ds:[y1], ax
    mov word ptr ds:[first_y], ax
    mov word ptr ds:[state], 7
    call draw_point
    jmp state_end
    ; }

state5:
    cmp ds:[state], 5
    jne state6
    ; {
    cmp al, ','
    je comma5
    cmp al, '0'
    jl error_wrong_format
    cmp al, '9'
    jg error_wrong_format
digit5:
    xor cx, cx
    mov cl, al
    mov ax, word ptr ds:[number]
    mov bx, 10
    mul bx
    sub cl, '0'
    add ax, cx ; w ax numer
    cmp ax, 320
    jge error_wrong_format
    mov word ptr ds:[number], ax
    jmp state_end
comma5:
    ; x0 = x1
    mov ax, word ptr ds:[x1]
    mov word ptr ds:[x0], ax
    ; x1 = number
    mov ax, word ptr ds:[number]
    mov word ptr ds:[x1], ax
    ; number = 0
    mov word ptr ds:[number], 0
    ; state = 6
    mov word ptr ds:[state], 6
    jmp state_end
    ; }

state6:
    cmp ds:[state], 6
    jne state7
    ; {
    cmp al, ' '
    je space6
    cmp al, cr
    je carriage6
    cmp al, '0'
    jl error_wrong_format
    cmp al, '9'
    jg error_wrong_format
digit6: ; '0' <= al <= '9'
    xor cx, cx
    mov cl, al
    mov ax, word ptr ds:[number]
    mov bx, 10
    mul bx
    sub cl, '0'
    add ax, cx ; w ax numer
    cmp ax, 320
    jge error_wrong_format
    mov word ptr ds:[number], ax
    jmp state_end
space6:
    ; y0 = y1
    mov ax, word ptr ds:[y1]
    mov word ptr ds:[y0], ax
    ; y1 = number
    mov ax, word ptr ds:[number]
    mov word ptr ds:[y1], ax
    ; number = 0
    mov word ptr ds:[number], 0
    ; draw line
    call draw_line
    ; state = 5
    mov word ptr ds:[state], 5
    jmp state_end
carriage6:
    ; y0 = y1
    mov ax, word ptr ds:[y1]
    mov word ptr ds:[y0], ax
    ; y1 = number
    mov ax, word ptr ds:[number]
    mov word ptr ds:[y1], ax
    ; number = 0
    mov word ptr ds:[number], 0
    ; draw line
    call draw_line
    ; draw last line
    ; x0 = first_x
    mov ax, word ptr ds:[first_x]
    mov word ptr ds:[x0], ax
    ; y0 = first_x
    mov ax, word ptr ds:[first_y]
    mov word ptr ds:[y0], ax
    ; draw line
    call draw_line
    ; state = 7
    mov word ptr ds:[state], 7
    jmp state_end
    ; }

state7:
    cmp ds:[state], 7
    jne error_wrong_format
    ; {
    cmp al, lf
    jne error_wrong_format
    ; state = 1
    mov word ptr ds:[state], 1
    jmp state_end
    ; }

state_end:
    pop cx
    pop dx
    pop bx
    pop si
    ret
evaluate_character endp


error_wrong_format proc far
    call wait_for_click
    call text_mode
    ; write message ; zły format pliku
    mov ax, seg error_message_3 
    mov ds, ax
    mov ah, 9
    mov dx, offset error_message_3
    int 21h
    ; wiadomość: zły stan
    mov dx, offset error_message_4
    int 21h
    ; stan
    mov dx, word ptr ds:[state]
    add dx, 48
    mov ah, 2
    int 21h
    ; linia
    call print_line
    ; wiadomość: zły znak
    mov ah, 9
    mov dx, offset error_message_5
    int 21h
    ; znak
    mov ah, 2
    mov dl, byte ptr ds:[wrong_character]
    int 21h
    ; linia
    call print_line

    call wait_for_click
    call exit
error_wrong_format endp