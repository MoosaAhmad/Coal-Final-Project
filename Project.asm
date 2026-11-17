[org 0x0100]

jmp start
entry1:db 'Entry 1$'
entry2:db 'Entry 2$'
endA:db 'End A$'
endB:db 'End B$'
endC:db 'End C$'
endD:db 'End D$'

clrscr:
    push es
    push ax
    push di
    mov ax, 0xb800
    mov es, ax
    mov di, 0
    nextloc: mov word [es:di], 0x0720
    add di, 2
    cmp di, 4000
    jne nextloc
    pop di
    pop ax
    pop es
    ret

printtEntry:
    push ax
    push bx
    push cx
    push di
    push es
    mov ax, 0xb800
    mov es, ax

    ; Entry 1 (Row 11, Col 3, Width 7)
    mov ax, 11
    mov bl, 80
    mul bl
    add ax, 3           ; Start at col 3 (cols 3 to 9)
    shl ax, 1
    mov di, ax
    mov cx, 7
    mov ax, 0x4020      ; Red background, 1 row high
    entry1:
    mov [es:di], ax
    add di, 2
    loop entry1

    ; Entry 2 (Row 18, Col 3, Width 7)
    mov ax, 18
    mov bl, 80
    mul bl
    add ax, 3           ; Start at col 3 (cols 3 to 9)
    shl ax, 1
    mov di, ax
    mov cx, 7
    mov ax, 0x4020
    entry2:
    mov [es:di], ax
    add di, 2
    loop entry2

    pop es
    pop di
    pop cx
    pop bx
    pop ax
    ret

printtEnd:
    push ax
    push bx
    push cx
    push di
    push es
    mov ax,0xb800
    mov es,ax

    mov ax,5        ; Station A on row 5
    mov bl, 80
    mul bl
    add ax,70       ; Station A on column 70
    shl ax,1
    mov di,ax
    mov cx,5
    mov ax,0x6020
    endA:
    mov [es:di],ax
    add di,2
    loop endA

    mov ax,8        ; Station B on row 8
    mov bl, 80
    mul bl
    add ax,70       ; Station B on column 70
    shl ax,1
    mov di,ax
    mov cx,5
    mov ax,0x6020
    endB:
    mov [es:di],ax
    add di,2
    loop endB

    mov ax,14       ; Station C on row 14
    mov bl, 80
    mul bl
    add ax,70       ; Station C on column 70
    shl ax,1
    mov di,ax
    mov cx,5
    mov ax,0x6020
    endC:
    mov [es:di],ax
    add di,2
    loop endC

    mov ax,18       ; Station D1 on row 18
    mov bl, 80
    mul bl
    add ax,70       ; Station D1 on column 70
    shl ax,1
    mov di,ax
    mov cx,5
    mov ax,0x6020
    endD1:
    mov [es:di],ax
    add di,2
    loop endD1

    mov ax,21       ; Station D2 on row 21
    mov bl, 80
    mul bl
    add ax,70       ; Station D2 on column 70
    shl ax,1
    mov di,ax
    mov cx,5
    mov ax,0x6020
    endD2:
    mov [es:di],ax
    add di,2
    loop endD2

    pop es
    pop di
    pop cx
    pop bx
    pop ax
    ret

grayE1toS1:
    push ax
    push bx
    push cx
    push di
    push es
    mov ax,0xb800
    mov es,ax
    
    mov ax,11       ; Entry 1 on row 11
    mov bl, 80
    mul bl
    add ax,5       ;Entry 1 on column 5
    shl ax,1
    mov di,ax
    add di,10
    mov cx,10       ;runs 10 columns
    mov ax,0x7020
    E1S1:
    mov [es:di],ax
    add di,2
    loop E1S1
    pop es
    pop di
    pop cx
    pop bx
    pop ax
    ret

grayS1toA:
    push ax
    push bx
    push cx
    push di
    push es
    mov ax,0xb800
    mov es,ax

    mov ax,10 
    mov bl, 80
    mul bl
    add ax,21    
    shl ax,1
    mov di,ax
    mov cx,5   ;5 rosw up
    mov ax,0x7020
    S1up:
    mov [es:di],ax
    mov [es:di+2],ax
    sub di,160      ; Move up 1 row
    loop S1up

    mov cx,49 
    S1Aleft:
    mov [es:di],ax
    add di,2
    loop S1Aleft

    pop es
    pop di
    pop cx
    pop bx
    pop ax
    ret

grayE2toS2:
    push ax
    push bx
    push cx
    push di
    push es
    mov ax,0xb800
    mov es,ax
    
    mov ax,18       ; Entry 2 on row 18
    mov bl, 80
    mul bl
    add ax,5       ;Entry 2 on column 5
    shl ax,1
    mov di,ax
    add di,10
    mov cx,10       ;runs 10 columns
    mov ax,0x7020
    E2S2:
    mov [es:di],ax
    add di,2
    loop E2S2
    pop es
    pop di
    pop cx
    pop bx
    pop ax
    ret

map:
    call clrscr
    call printtEntry
    call grayE2toS2
    call grayE1toS1
    call grayS1toA
    call printtEnd
    ret
;    push bp
;    mov bp,sp
;    push ax
;    push bx
;    push cx
;    push dx
;    push si
;    push di
;    push es
;    push ds

;    mov ax,0xb800
;    mov es,ax
;    mov ax,0x5220
;
;    done:
;        pop ds
;        pop es
;        pop di
;        pop si
;        pop dx
;        pop cx
;        pop bx
;        pop ax
;        pop bp
;        ret

start:
    call map

terminate:
mov ax, 0x4c00
int 0x21