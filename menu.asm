[org 0x0100]

jmp start
oldisr:dd 0
selection:db 1
changed: db 0
enterPressed: db 0
prompt:db 'Press Enter to Start$'
opt1:db '>  Singleplayer'
opt2:db '>  Multiplayer'
opt3:db 'Exit'

strwelcome:
    db '-------------------#---#-###-#---###-###-#---#-###---###-###--------------------'
    db '-------------------#-#-#-##--#---#---#-#-##-##-##-----#--#-#--------------------'
    db '-------------------##-##-#---#---#---#-#-#-#-#-#------#--#-#--------------------'
    db '-------------------#---#-###-###-###-###-#---#-###----#--###--------------------'

strswitchyard:
    db '------######-##---##-####-######--#####-##--##-##--##--####--#####--#####-------'
    db '------##-----##---##--##----##---##-----##--##-##--##-##--##-##--##-##--##------'
    db '------##-----##-#-##--##----##---##-----##--##--####--##--##-##--##-##--##------'
    db '------######-##-#-##--##----##---##-----######---##---######-#####--##--##------'
    db '----------##-#######--##----##---##-----##--##---##---##--##-##-##--##--##------'
    db '----------##-###-###--##----##---##-----##--##---##---##--##-##--##-##--##------'
    db '------######-##---##-####---##----#####-##--##---##---##--##-##--##-#####-------'

switchyard5row:
    db '---------#####-##---##-####-######-#####-##-##-##--##--###--####--####----------'
    db '---------##----##---##--##----##---##----##-##--####--##-##-##-##-##-##---------'
    db '---------#####-##-#-##--##----##---##----#####---##---#####-####--##-##---------'
    db '------------##-#######--##----##---##----##-##---##---##-##-##-##-##-##---------'
    db '---------#####--##-##--####---##---#####-##-##---##---##-##-##-##-####----------'
clrscr:
    push es
    push ax
    push di
    mov ax, 0xb800
    mov es, ax
    mov di, 0
    nextloc:
    mov word [es:di], 0x0720
    add di, 2
    cmp di, 4000
    jne nextloc
    pop di
    pop ax
    pop es
    ret

bounds:
    push ax
    push cx
    push di
    push es
    push 0xb800
    pop es
    mov ah,0x01     ; 1 for blue and 9 for high intensity blue
    mov al,0x3d     ; = 
    mov di,0
    mov cx,80
    rep stosw
    mov di,160
    mov cx,80
    rep stosw
    mov di,3840
    mov cx,80
    rep stosw
    pop es
    pop di
    pop cx
    pop ax
    ret
prtswitchyard:     ; just give it a row no to start printnig on
    push bp
    mov bp,sp
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es

    mov ax, 0xb800
    mov es,ax
    mov ax,[bp+4]
    mov bx,160
    mul bx
    mov di,ax

    mov bx,0
    mov cx,560
    printswt:
        mov dl,[strswitchyard+bx]
        cmp dl,0x2d
        je space
        mov ax,0x0EDB
        jmp prit
        space:
            mov ax,0x0720
        prit:
        stosw
        inc bx
        
    loop printswt

    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret 2

prtwelcome:     ; just give it a row no to start printnig on
    push bp
    mov bp,sp
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es

    mov ax, 0xb800
    mov es,ax
    mov ax,[bp+4]
    mov bx,160
    mul bx
    mov di,ax

    mov bx,0
    mov cx,320
    printwel:
        mov dl,[strwelcome+bx]
        cmp dl,0x2d
        je isspace
        mov ax,0x6020
        jmp prt
        isspace:
            mov ax,0x0720
        prt:
        stosw
        inc bx
        
    loop printwel
    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret 2

mainswitchyard:
    push bp
    mov bp,sp
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es

    mov ax, 0xb800
    mov es,ax
    mov ax,[bp+4]
    mov bx,160
    mul bx
    mov di,ax

    mov bx,0
    mov cx,400
    mloop:
        mov dl,[switchyard5row+bx]
        cmp dl,0x2d
        je eq
        mov ax,0x0EDB
        jmp pt
        eq:
            mov ax,0x0720
        pt:
        stosw
        inc bx
        
    loop mloop
    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret 2

prtopt1:
    push bp
    push ax
    push bx
    push cx
    push dx
    push es
    mov ah, 0x13 ; service 13 - print string
    mov al, 0 ; subservice 01 – update cursor
    mov bh, 0 ; output on page 0
    mov bl,0x07
    cmp byte[cs:selection],1
    jne skip1
    mov bl, 0x87
    skip1:
    mov dx, 0x1220
    mov cx, 15
    push cs
    pop es
    mov bp, opt1 ; offset of string
    int 0x10
    pop es
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret
prtopt2:
    push bp
    push ax
    push bx
    push cx
    push dx
    push es
    mov ah, 0x13 ; service 13 - print string
    mov al, 0 ; subservice 01 – update cursor
    mov bh, 0 ; output on page 0
    mov bl, 0x07
    cmp byte[cs:selection],2
    jne skip2
    mov bl, 0x87
    skip2:
    mov dx, 0x1420
    mov cx, 14 ; length of string
    push cs
    pop es ; segment of string
    mov bp, opt2 ; offset of string
    int 0x10
    pop es
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret
prtopt3:
    push bp
    push ax
    push bx
    push cx
    push dx
    push es
    mov ah, 0x13 ; service 13 - print string
    mov al, 0 ; subservice 01 – update cursor
    mov bh, 0 ; output on page 0
    mov bl, 0x07
    cmp byte[cs:selection],3
    jne skip3
    mov bl, 0x87
    skip3:
    mov dx, 0x1626
    mov cx, 4 ; length of string
    push cs
    pop es ; segment of string
    mov bp, opt3 ; offset of string
    int 0x10
    pop es
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret
updopts:
    call prtopt1
    call prtopt2
    call prtopt3
    ret
mainmenu:
    push bp
    mov bp,sp
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push es
    push ds

    call clrscr
    call bounds
    push 7
    call mainswitchyard
    call updopts
    pop ds
    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret
    
initialscr:
    call clrscr
    call bounds
    push 5
    call prtwelcome
    push 11
    call prtswitchyard
    mov ah, 0x13
    mov al, 0
    mov bh, 0
    mov bl, 0x87
    mov dx, 0x161d
    mov cx, 20
    push cs
    pop es
    mov bp, prompt
    int 0x10
    ret

initkisr:
    push ax
    in al,0x60
    cmp al,0x1c
    jne inichain
    mov byte [cs:enterPressed],1
    inichain:
    pop ax
    jmp far [cs:oldisr]

    menukisr:
        push ax
        in al, 0x60

        cmp al, 0x48
        jne cmp2
        dec byte [cs:selection]
        cmp byte [cs:selection], 0
        ja skip4
        mov byte [cs:selection], 3
    skip4:
        mov byte [cs:changed], 1
        jmp menuchain

    cmp2:
        cmp al, 0x50
        jne cmp3
        inc byte [cs:selection]
        cmp byte [cs:selection], 4
        jb skip5
        mov byte [cs:selection], 1
    skip5:
        mov byte [cs:changed], 1
        jmp menuchain

    cmp3:
        cmp al, 0x1c
        jne menuchain
        mov byte [cs:enterPressed], 1

    menuchain:
        pop ax
        jmp far [cs:oldisr]

start:
    xor ax, ax
    mov es, ax
    mov ax, [es:9*4]
    mov [oldisr], ax
    mov ax, [es:9*4+2]
    mov [oldisr+2], ax

    cli
    mov word [es:9*4], initkisr
    mov [es:9*4+2], cs
    sti
    call initialscr

initwait:
    cmp byte [enterPressed], 1
    jne initwait
    mov byte [cs:enterPressed], 0

    xor ax, ax
    mov es, ax
    cli
    mov word [es:9*4], menukisr
    mov [es:9*4+2], cs
    sti

    call mainmenu

menuwait:
    cmp byte [changed], 1
    jne check_enter
    mov byte [cs:changed], 0
    call updopts

check_enter:
    cmp byte [enterPressed], 1
    jne menuwait
    mov byte [cs:enterPressed], 0

    xor ax, ax
    mov es, ax
    cli
    mov ax, [oldisr]
    mov [es:9*4], ax
    mov ax, [oldisr+2]
    mov [es:9*4+2], ax
    sti

    mov ax, 0x4c00
    int 0x21