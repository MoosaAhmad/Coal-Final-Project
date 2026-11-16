[org 0x0100]

jmp start

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
    mov ax,0xb800
    mov es,ax
    mov ax,11       ; Entry 1 on row 11
    mov bl, 80
    mul bl
    add ax,5       ;Entry 1 on column 5
    shl ax,1
    mov di,ax
    mov cx,5
    mov ax,0x4020
    entry1:
    mov [es:di-160],ax
    mov [es:di],ax
    mov [es:di+160],ax
    add di,2
    loop entry1

    mov ax,18       ; Entry 2 on row 18
    mov bl, 80
    mul bl
    add ax,5       ;Entry 2 on column 5
    shl ax,1
    mov di,ax
    mov cx,5
    mov ax,0x4020
    entry2:
    mov [es:di-160],ax
    mov [es:di],ax
    mov [es:di+160],ax
    add di,2
    loop entry2

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
    add di,6
    mov cx,12       ;runs 10 columns
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
    add di,6
    mov cx,12       ;runs 10 columns
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