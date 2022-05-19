; draw_point (x,y)
; draw_line (x0, y0), (x1, y1)


draw_point proc far
    push ax
    push bx
    push es

    mov ax, 0a000h
    mov es, ax

    mov bx, 320
    mov ax, 199
    sub ax, word ptr ds:[y]
    mul bx
    mov bx, word ptr ds:[x]
    add bx, ax
    mov al, byte ptr ds:[k]
    mov byte ptr es:[bx], al ; zapal punkt - przeniesienie koloru na ekran

    pop es
    pop bx
    pop ax
    ret
draw_point endp


draw_line proc far
    ; draws line from (x0, y0) to (x1, y1)S
    push ax
    ; if x0 < x1:
    mov ax, word ptr ds:[x0]
    cmp ax, word ptr ds:[x1]
    jge L001
    mov word ptr ds:[step_x], 1
    mov ax, word ptr ds:[x1]
    sub ax, word ptr ds:[x0]
    mov word ptr ds:[diff_x], ax
    jmp L002
L001:
    mov word ptr ds:[step_x], -1
    mov ax, word ptr ds:[x0]
    sub ax, word ptr ds:[x1]
    mov word ptr ds:[diff_x], ax
L002:
    ;---------------------------------
    ; if y0 < y1
    mov ax, word ptr ds:[y0]
    cmp ax, word ptr ds:[y1]
    jge L003
    mov word ptr ds:[step_y], 1
    mov ax, word ptr ds:[y1]
    sub ax, word ptr ds:[y0]
    mov word ptr ds:[diff_y], ax
    jmp L004
L003:
    mov word ptr ds:[step_y], -1
    mov ax, word ptr ds:[y0]
    sub ax, word ptr ds:[y1]
    mov word ptr ds:[diff_y], ax
L004:
    ;---------------------------------
    ; x = x0
    mov ax, word ptr ds:[x0]
    mov word ptr ds:[x], ax

    ; y = y0
    mov ax, word ptr ds:[y0]
    mov word ptr ds:[y], ax
    ; draw first pixel
    call draw_point

    ;------------------------------
    ; if dx > dy
    mov ax, word ptr ds:[diff_x]
    cmp ax, word ptr ds:[diff_y]
    jle L005
    ; dx > dy

    ; incrE = 2dy
    mov ax, word ptr ds:[diff_y]
    shl ax, 1
    mov word ptr ds:[incrE], ax

    ; incrNE = 2*(dy-dx)
    mov ax, word ptr ds:[diff_y]
    sub ax, word ptr ds:[diff_x]
    shl ax, 1
    mov word ptr ds:[incrNE], ax

    ; diff = dy*2-dx
    mov ax, word ptr ds:[diff_y]
    shl ax, 1
    sub ax, word ptr ds:[diff_x]
    mov word ptr ds:[diff], ax

    ; while x != x1
while1:
    mov ax, word ptr ds:[x]
    cmp ax, word ptr ds:[x1]
    je endwhile1
    
    ; x += stepX
    add ax, word ptr ds:[step_x]
    mov word ptr ds:[x], ax

    ; if d <= 0:
    mov ax, word ptr ds:[diff]
    cmp ax, 0
    jg L006
    ; d <= 0
    ; d += incrE
    add ax, word ptr ds:[incrE]
    mov word ptr ds:[diff], ax
    jmp L007
L006:
    ; d > 0
    ; d += incrNe
    add ax, word ptr ds:[incrNE]
    mov word ptr ds:[diff], ax
    ; y += step_y
    mov ax, word ptr ds:[y]
    add ax, word ptr ds:[step_y]
    mov word ptr ds:[y], ax
L007:   ; endif
    call draw_point
    jmp while1
endwhile1:
    jmp draw_line_end
L005:
    ; dx <= dy
    ; incrE = 2dx
    mov ax, word ptr ds:[diff_x]
    shl ax, 1
    mov word ptr ds:[incrE], ax

    ; incrNE = 2*(dy-dx)
    mov ax, word ptr ds:[diff_x]
    sub ax, word ptr ds:[diff_y]
    shl ax, 1
    mov word ptr ds:[incrNE], ax

    ; diff = dx*2-dy
    mov ax, word ptr ds:[diff_x]
    shl ax, 1
    sub ax, word ptr ds:[diff_y]
    mov word ptr ds:[diff], ax

while2:
    mov ax, word ptr ds:[y]
    cmp ax, word ptr ds:[y1]
    je endwhile2

    ; y += step_y
    add ax, word ptr ds:[step_y]
    mov word ptr ds:[y], ax

    ; if d < 0:
    mov ax, word ptr ds:[diff]
    cmp ax, 0
    jge L008
    ; d < 0
    ; d += incrE
    mov ax, word ptr ds:[diff]
    add ax, word ptr ds:[incrE]
    mov word ptr ds:[diff], ax
    jmp L009
L008:   ; d >= 0
    ; d += incrNE
    mov ax, word ptr ds:[diff]
    add ax, word ptr ds:[incrNE]
    mov word ptr ds:[diff], ax
    ; x += step_x
    mov ax, word ptr ds:[x]
    add ax, word ptr ds:[step_x]
    mov word ptr ds:[x], ax
L009:   ; endif
    call draw_point
    jmp while2
endwhile2:
    jmp draw_line_end

draw_line_end:
    pop ax
    ret
draw_line endp