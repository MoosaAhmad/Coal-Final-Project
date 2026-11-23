[org 0x0100]
jmp start

; =========================================================
; DATA SECTION
; =========================================================
old_int8         dd 0                   ; Original INT 08h vector
exit_flag        db 0                   ; Set to 1 when ESC is pressed
key_pressed      db 0                   ; Stores last detected key
game_over_state  db 0                   ; 0 = Playing, 1 = Win, 2 = Lose

; --- RANDOM SEED & SPAWN CONTROL ---
rand_seed        dw 0xACE1              ; Seeded from BIOS clock at start
spawn_timer      db 12                  ; Ticks until next spawn attempt
SPAWN_INTERVAL   equ 18                 ; Attempt spawn every ~1 second (18 ticks)

; --- TRAIN ARRAYS (Max 5 trains, size 5) ---
train_r          db 0, 0, 0, 0, 0       ; Current row of each train
train_c          db 0, 0, 0, 0, 0       ; Current col of each train
train_dest       db 0, 0, 0, 0, 0       ; Destination letter ('A','B','C','D')
isActive         db 0, 0, 0, 0, 0       ; 1 = active on track, 0 = free slot
train_count      db 0                   ; Number of currently active trains (0..5)

; Movement-update collision snapshot and destination reservations
update_collision db 0
start_r         db 0, 0, 0, 0, 0
start_c         db 0, 0, 0, 0, 0
claimed_r        db 0, 0, 0, 0, 0
claimed_c        db 0, 0, 0, 0, 0
claimed_active    db 0, 0, 0, 0, 0

; Reachable station lookup tables
entry1_dests     db 'A', 'B', 'C', 'D'  ; Entry 1 can reach all 4 stations
entry2_dests     db 'B', 'C', 'D'       ; Entry 2 can reach B, C, or D (cannot reach A)

; --- GAME STATS & TIMER VARIABLES ---
Score            db 0                   ; Current correct deliveries
ReqScore         db 10                  ; Target deliveries (10 in 1P, 20 in Co-op)
strikes          db 0                   ; Current mistakes
maxStrikes       db 5                   ; Max allowed mistakes (5)
TickRate         db 6                   ; Movement interval in timer ticks (6 -> 3)
currentTickCount db 0                   ; Tick counter for train movement
mode             db 1                   ; 1 = Single-Player, 2 = Co-op
speedBoosted     db 0                   ; 1 once one-time speed boost is applied

elapsedSec       dw 0                   ; Total elapsed seconds
secTickCount     db 0                   ; Counts 18 ticks = ~1 second
secChanged       db 0                   ; Flag set by ISR when 1 second passes

; --- SWITCH & TRACK DATA ---
switchState      db 0, 0, 0, 0          ; 0 = Default/Direct, 1 = Shared/Alternate

; Dependent track part numbers (1..15) for each switch (4 per switch, 0 = end)
sw_parts         db 3, 4, 7, 8          ; Switch 1 -> parts 3, 4, 7, 8
                 db 5, 6, 8, 9          ; Switch 2 -> parts 5, 6, 8, 9
                 db 10, 11, 15, 0       ; Switch 3 -> parts 10, 11, 15
                 db 12, 13, 14, 0       ; Switch 4 -> parts 12, 13, 14

; Switch coordinates (Buttons 1..4)
switch_y         db 8, 16, 12, 12
switch_x         db 20, 20, 44, 60

; Station coordinates
station_r        db 5, 8, 12, 16, 19
station_val      db 'A', 'B', 'C', 'D', 'D'
station_c        db 74

; Track colors & characters
TRACK_CHAR       equ 0x20               ; Space character for background fill
ACTIVE_COL       equ 0xF0               ; Bright White background (Active)
INACTIVE_COL     equ 0x70               ; Dark Grey background (Inactive)
STATION_COL      equ 0x60               ; Orange/Brown background with black text
TRAIN_COL        equ 0x4F               ; Bright White letter on Red background

; Uniform-direction track tables (15 Segments: Parts 1..15)
track_r          db 8,  16, 7,  9,  15, 17, 5,  12, 19, 11, 12, 13, 12, 16, 8
track_c          db 11, 11, 20, 20, 20, 20, 20, 20, 20, 44, 45, 60, 61, 60, 44
track_len        db 9,  9,  2,  3,  3,  2,  54, 24, 54, 3,  15, 3,  13, 14, 30
track_dr         db 0,  0, -1,  1, -1,  1,  0,  0,  0, -1,  0,  1,  0,  0,  0
track_dc         db 1,  1,  0,  0,  0,  0,  1,  1,  1,  0,  1,  0,  1,  1,  1
track_stride     dw 2,  2,-160,160,-160,160,2,  2,  2,-160, 2, 160, 2,  2,  2
track_sw         db 0xFF,0xFF,0, 0, 1,  1,  0,  8,  1,  2,  2,  3,  3,  3,  2
track_req        db 0,  0,  0,  1,  1,  0,  0,  0,  0,  0,  1,  1,  0,  1,  0

; --- MENU, HUD & END SCREEN STRINGS ---
str_title        db '=== S W I T C H Y A R D ==='
str_sub          db 'FAST-NUCES Lahore - COAL Project'
str_opt1         db '[1] Single-Player Mode (Target: 10 | Keys: 1, 2, 3, 4)'
str_opt2         db '[2] Two-Player Co-op   (Target: 20 | P1: 1,2 | P2: J,K)'
str_opt_esc      db '[ESC] Exit to DOS'

str_logo         db 'SwitchYard'
str_logo_bar     db '=========='
str_mode_lbl     db 'Mode:'
str_score_lbl    db 'Score:'
str_mist_lbl     db 'Mistakes:'
str_time_lbl     db 'Time:'
str_tick_lbl     db 'TickRate:'
str_entry1       db '[Entry 1]'
str_entry2       db '[Entry 2]'
str_ctrl_1p      db 'Controls: [1-4] Toggle Switches 1-4                        [ESC] Exit'
str_ctrl_2p      db 'Co-op Controls: P1=[1, 2] Switches 1-2 | P2=[J, K] Switches 3-4 [ESC]'

str_win          db '*** VICTORY! ALL TRAINS DELIVERED SAFELY! ***'
str_lose         db '*** GAME OVER! TOO MANY MISTAKES (5/5)! ***'
str_replay       db 'Press [R] to Replay or [ESC] to Exit'

; Dynamic formatting buffers
buf_mode         db '1P'
buf_score        db '00/10'
buf_mistakes     db '00/05'
buf_time         db '00:00'
buf_tick         db '06'

; =========================================================
; CUSTOM TIMER ISR (INT 08h)
; =========================================================
my_int8:
    push ax
    push ds

    push cs
    pop ds

    ; 1. Increment movement tick counter
    inc byte [currentTickCount]

    ; 2. Track elapsed seconds (~18.2 ticks per second)
    inc byte [secTickCount]
    cmp byte [secTickCount], 18
    jl near .chk_kbd
    mov byte [secTickCount], 0
    inc word [elapsedSec]
    mov byte [secChanged], 1

.chk_kbd:
    ; 3. Non-blocking keyboard check
    mov ah, 0x01
    int 0x16
    jz near .skip_key

    mov ah, 0x00
    int 0x16
    mov [key_pressed], al

.skip_key:
    pop ds
    pop ax

    ; Chain to original BIOS timer interrupt
    jmp far [cs:old_int8]

; =========================================================
; UTILITY & RANDOM NUMBER ROUTINES
; =========================================================
clrscr:
    push cx
    push ax
    push es
    push di
    mov cx, 2000
    mov ax, 0xb800
    mov es, ax
    mov ax, 0x0720
    xor di, di
    rep stosw
    pop di
    pop es
    pop ax
    pop cx
    ret

hideCursor:
    push ax
    push cx
    mov ah, 0x01
    mov ch, 0x20
    mov cl, 0x00
    int 0x10
    pop cx
    pop ax
    ret

showCursor:
    push ax
    push cx
    mov ah, 0x01
    mov ch, 0x06
    mov cl, 0x07
    int 0x10
    pop cx
    pop ax
    ret

; Seeds rand_seed using BIOS system clock (INT 1Ah / AH=00h)
seedRandom:
    push ax
    push cx
    push dx
    xor ah, ah
    int 0x1a
    or dx, 1                    ; Ensure non-zero seed
    mov [rand_seed], dx
    pop dx
    pop cx
    pop ax
    ret

; Generates pseudo-random 16-bit number in AX
getRandom:
    push dx
    mov ax, [rand_seed]
    mov dx, 25173
    mul dx
    add ax, 13849
    mov [rand_seed], ax
    pop dx
    ret

; printString: Prints string via BIOS INT 10h / AH=13h
; Stack: [bp+12]=ptr, [bp+10]=len, [bp+8]=row, [bp+6]=col, [bp+4]=attr
printString:
    push bp
    mov bp, sp
    push ax
    push bx
    push cx
    push dx
    push si
    push es

    mov si, [bp+12]
    mov cx, [bp+10]
    mov dh, [bp+8]
    mov dl, [bp+6]
    mov bl, [bp+4]
    mov bh, 0

    push cs
    pop es
    push bp
    mov bp, si
    mov ax, 0x1300
    int 0x10
    pop bp

    pop es
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp
    ret 10

; Converts byte in AL (0..99) to 2 ASCII digits at [DI] and [DI+1]
byteTo2Digits:
    push ax
    push bx
    xor ah, ah
    mov bl, 10
    div bl
    add al, '0'
    add ah, '0'
    mov [di], al
    mov [di + 1], ah
    pop bx
    pop ax
    ret

drawChar:
    push bp
    mov bp, sp
    push ax
    push si
    push es
    mov ax, 0xb800
    mov es, ax
    mov al, 80
    mul byte [bp+8]
    add ax, [bp+6]
    shl ax, 1
    mov si, ax
    mov ax, [bp+4]
    mov [es:si], ax
    pop es
    pop si
    pop ax
    pop bp
    ret 6

drawSeg:
    push bp
    mov bp, sp
    push ax
    push cx
    push dx
    push si
    push es
    mov ax, 0xb800
    mov es, ax
    mov al, 80
    mul byte [bp+10]
    add ax, [bp+8]
    shl ax, 1
    mov si, ax
    mov ax, [bp+4]
    mov cx, [bp+12]
    mov dx, [bp+6]
.nextChar:
    mov [es:si], ax
    add si, dx
    dec cx
    jnz near .nextChar
    pop es
    pop si
    pop dx
    pop cx
    pop ax
    pop bp
    ret 10

; =========================================================
; MAIN MENU & GAME RESET (Requirements 5 & 6)
; =========================================================
showMainMenu:
    call clrscr

    push word str_title
    push word 27
    push word 6
    push word 26
    push word 0x0E              ; Bright Yellow
    call printString

    push word str_sub
    push word 32
    push word 8
    push word 24
    push word 0x0B              ; Bright Cyan
    call printString

    push word str_opt1
    push word 54
    push word 12
    push word 13
    push word 0x0A              ; Bright Green
    call printString

    push word str_opt2
    push word 54
    push word 14
    push word 13
    push word 0x0F              ; Bright White
    call printString

    push word str_opt_esc
    push word 17
    push word 17
    push word 31
    push word 0x0C              ; Light Red
    call printString

.wait_choice:
    mov ah, 0x00
    int 0x16

    cmp al, '1'
    jne near .chk_2p
    mov byte [mode], 1
    mov byte [ReqScore], 10
    ret

.chk_2p:
    cmp al, '2'
    jne near .chk_menu_esc
    mov byte [mode], 2
    mov byte [ReqScore], 20
    ret

.chk_menu_esc:
    cmp al, 27
    jne near .wait_choice
    mov byte [exit_flag], 1
    ret

resetGame:
    push cx
    push bx

    ; Clear all 5 train slots
    mov cx, 5
    xor bx, bx
.clr_trains:
    mov byte [isActive + bx], 0
    mov byte [train_r + bx], 0
    mov byte [train_c + bx], 0
    mov byte [train_dest + bx], 0

inc bx
dec cx
jnz near .clr_trains
; Reset all 4 switches to 0
mov cx, 4
xor bx, bx
.clr_sw:
mov byte [switchState + bx], 0
inc bx
dec cx
jnz near .clr_sw
; Reset counters, speed, and timer
mov byte [train_count], 0
mov byte [Score], 0
mov byte [strikes], 0
mov byte [TickRate], 6
mov byte [currentTickCount], 0
mov byte [speedBoosted], 0
mov word [elapsedSec], 0
mov byte [secTickCount], 0
mov byte [secChanged], 0
mov byte [game_over_state], 0
mov byte [key_pressed], 0
mov byte [spawn_timer], 6   ; Spawn first train quickly after start
pop bx
pop cx
ret
; =========================================================
; INIT NAV BAR & PRINT STATS (Colorful HUD via INT 10h/13h)
; =========================================================
initNavBar:
push word str_logo
push word 10
push word 0
push word 2
push word 0x0E              ; Bright Yellow
call printString
push word str_logo_bar
push word 10
push word 1
push word 2
push word 0x06              ; Orange/Brown
call printString
push word 0
push word 14
push word 0x097C            ; Blue '|'
call drawChar
push word 1
push word 14
push word 0x097C            ; Blue '|'
call drawChar
push word str_mode_lbl
push word 5
push word 0
push word 20
push word 0x07
call printString
push word str_score_lbl
push word 6
push word 0
push word 33
push word 0x07
call printString
push word str_time_lbl
push word 5
push word 0
push word 58
push word 0x07
call printString
push word str_mist_lbl
push word 9
push word 1
push word 33
push word 0x07
call printString
push word str_tick_lbl
push word 9
push word 1
push word 58
push word 0x07
call printString
push word 80
push word 2
push word 0
push word 2
push word 0x092D
call drawSeg
push word 2
push word 14
push word 0x0B2B
call drawChar
push word str_entry1
push word 9
push word 8
push word 2
push word 0x0B
call printString
push word str_entry2
push word 9
push word 16
push word 2
push word 0x0B
call printString
push word 80
push word 22
push word 0
push word 2
push word 0x092D
call drawSeg
cmp byte [mode], 2
je near .draw_2p_ctrl
push word str_ctrl_1p
push word 70
push word 23
push word 2
push word 0x03
call printString
ret
.draw_2p_ctrl:
push word str_ctrl_2p
push word 70
push word 23
push word 2
push word 0x03
call printString
ret
printStats:
push ax
push bx
push dx
push di
; 1. Mode ("1P" or "2P")
mov al, [mode]
add al, '0'
mov [buf_mode], al
push word buf_mode
push word 2
push word 0
push word 26
push word 0x0B
call printString
; 2. Score ("00/10" or "00/20")
mov al, [Score]
mov di, buf_score
call byteTo2Digits
mov al, [ReqScore]
mov di, buf_score + 3
call byteTo2Digits
push word buf_score
push word 5
push word 0
push word 43
push word 0x0A
call printString
; 3. Mistakes ("00/05")
mov al, [strikes]
mov di, buf_mistakes
call byteTo2Digits
mov al, [maxStrikes]
mov di, buf_mistakes + 3
call byteTo2Digits
push word buf_mistakes
push word 5
push word 1
push word 43
push word 0x0C
call printString
; 4. Time ("MM:SS")
mov ax, [elapsedSec]
xor dx, dx
mov bx, 60
div bx
mov di, buf_time
call byteTo2Digits
mov al, dl
mov di, buf_time + 3
call byteTo2Digits
push word buf_time
push word 5
push word 0
push word 64
push word 0x0F
call printString
; 5. TickRate ("06" -> "03")
mov al, [TickRate]
mov di, buf_tick
call byteTo2Digits
push word buf_tick
push word 2
push word 1
push word 68
push word 0x0E
call printString
pop di
pop dx
pop bx
pop ax
ret
; =========================================================
; COORDINATE LOOKUP: getPartOfTrack(r, c)
; Stack: [bp+6]=r, [bp+4]=c
; Returns in AX:
;   16..19 -> Switches 1..4 (15 + switch_num)
;   20..24 -> Stations 1..5 (19 + station_num)
;   1..15  -> Track segments 1..15
;   0      -> Not on track
; =========================================================
getPartOfTrack:
push bp
mov bp, sp
push bx
push cx
push dx
push si
mov dh, [bp+6]              ; DH = r
mov dl, [bp+4]              ; DL = c
; 1. Check Switches First (16..19)
mov cx, 4
xor bx, bx
.chk_sw:
cmp dh, [switch_y + bx]
jne near .next_sw
cmp dl, [switch_x + bx]
jne near .next_sw
mov ax, bx
add ax, 16
jmp near .found
.next_sw:
inc bx
dec cx
jnz near .chk_sw
; 2. Check Stations Next (20..24)
cmp dl, [station_c]
jne near .chk_parts
mov cx, 5
xor bx, bx
.chk_sta:
cmp dh, [station_r + bx]
jne near .next_sta
mov ax, bx
add ax, 20
jmp near .found
.next_sta:
inc bx
dec cx
jnz near .chk_sta
; 3. Check 15 Track Segments (1..15)
.chk_parts:
mov cx, 15
xor si, si
.chk_seg_loop:
mov al, [track_dr + si]
cmp al, 0
jne near .chk_vertical
cmp dh, [track_r + si]
jne near .next_seg
mov bl, [track_c + si]
cmp dl, bl
jb near .next_seg
add bl, [track_len + si]
cmp dl, bl
jae near .next_seg
mov ax, si
inc ax
jmp near .found
.chk_vertical:
cmp dl, [track_c + si]
jne near .next_seg
cmp al, 1
jne near .chk_upward
mov bl, [track_r + si]
cmp dh, bl
jb near .next_seg
add bl, [track_len + si]
cmp dh, bl
jae near .next_seg
mov ax, si
inc ax
jmp near .found
.chk_upward:
mov bl, [track_r + si]
cmp dh, bl
ja near .next_seg
sub bl, [track_len + si]
cmp dh, bl
jbe near .next_seg
mov ax, si
inc ax
jmp near .found
.next_seg:
inc si
dec cx
jnz near .chk_seg_loop
xor ax, ax
.found:
pop si
pop dx
pop cx
pop bx
pop bp
ret 4
; =========================================================
; TRACK, SWITCH, STATION & TRAIN RENDERING
; =========================================================
drawTrackPart:
push bp
mov bp, sp
push ax
push bx
push cx
push dx
push si
mov bx, [bp+4]
dec bx
mov si, bx
mov bx, track_sw
add bx, si
mov al, [bx]
cmp al, 0xFF
je near .is_active
cmp al, 8
je near .check_part8
xor ah, ah
mov bx, ax
mov al, [switchState + bx]
mov bx, track_req
add bx, si
cmp al, [bx]
jne near .is_inactive
jmp near .is_active
.check_part8:
cmp byte [switchState + 0], 1
je near .is_active
cmp byte [switchState + 1], 1
je near .is_active
jmp near .is_inactive
.is_active:
mov dl, ACTIVE_COL
jmp near .draw_segment
.is_inactive:
mov dl, INACTIVE_COL
.draw_segment:
mov bx, track_len
add bx, si
mov al, [bx]
xor ah, ah
push ax
mov bx, track_r
add bx, si
mov al, [bx]
xor ah, ah
push ax
mov bx, track_c
add bx, si
mov al, [bx]
xor ah, ah
push ax
push si
shl si, 1
mov bx, track_stride
add bx, si
mov ax, [bx]
pop si
push ax
mov al, TRACK_CHAR
mov ah, dl
push ax
call drawSeg
pop si
pop dx
pop cx
pop bx
pop ax
pop bp
ret 2
draw_track:
push cx
mov cx, 1
.next_part:
push cx
call drawTrackPart
inc cx
cmp cx, 15
jle near .next_part
pop cx
ret
drawSwitches:
push ax
push bx
push cx
mov cx, 4
xor bx, bx
.nextSwitch:
xor ax, ax
mov al, [switch_y + bx]
push ax
mov al, [switch_x + bx]
push ax
mov ah, 0x2F
mov al, '1'
add al, bl
push ax
call drawChar
inc bx
dec cx
jnz near .nextSwitch
pop cx
pop bx
pop ax
ret
drawStations:
push ax
push bx
push cx
mov cx, 5
xor bx, bx
.nextStation:
xor ax, ax
mov al, [station_r + bx]
push ax
mov al, [station_c]
push ax
mov ah, STATION_COL
mov al, [station_val + bx]
push ax
call drawChar
inc bx
dec cx
jnz near .nextStation
pop cx
pop bx
pop ax
ret
drawTrains:
push ax
push bx
push cx
mov cx, 5
xor bx, bx
.nextTrain:
cmp byte [isActive + bx], 1
jne near .skip_t
xor ax, ax
mov al, [train_r + bx]
push ax
mov al, [train_c + bx]
push ax
mov ah, TRAIN_COL
mov al, [train_dest + bx]
push ax
call drawChar
.skip_t:
inc bx
dec cx
jnz near .nextTrain
pop cx
pop bx
pop ax
ret
; =========================================================
; COLLISION & CELL OCCUPANCY CHECK
; Checks if any active train is currently at (DH=r, DL=c)
; Returns AL = 1 if occupied, 0 if free
; =========================================================
isCellOccupied:
push bx
push cx
mov cx, 5
xor bx, bx
.chk_occ_loop:
cmp byte [isActive + bx], 1
jne near .next_occ
cmp dh, [train_r + bx]
jne near .next_occ
cmp dl, [train_c + bx]
jne near .next_occ
mov al, 1
jmp near .done_occ
.next_occ:
inc bx
dec cx
jnz near .chk_occ_loop
xor al, al
.done_occ:
pop cx
pop bx
ret
; =========================================================
; MOVEMENT COLLISION CHECK (start-of-update snapshot + claims)
; DH/DL = proposed destination, SI = moving train index
; Returns AL = 1 blocked, 0 free
; =========================================================
isMoveBlocked:
push bx
push cx
mov cx, 5
xor bx, bx
.chk_start:
cmp bx, si
je near .next_start
cmp byte [isActive + bx], 1
jne near .next_start
cmp dh, [start_r + bx]
jne near .next_start
cmp dl, [start_c + bx]
je near .blocked
.next_start:
inc bx
dec cx
jnz near .chk_start
; Check claims made by trains already processed this update.
mov cx, 5
xor bx, bx
.chk_claim:
cmp byte [claimed_active + bx], 1
jne near .next_claim
cmp dh, [claimed_r + bx]
jne near .next_claim
cmp dl, [claimed_c + bx]
je near .blocked
.next_claim:
inc bx
dec cx
jnz near .chk_claim
xor al, al
jmp near .done_move_check
.blocked:
mov al, 1
.done_move_check:
pop cx
pop bx
ret

; =========================================================
; TRAIN SPAWNING (Requirement 2)
; Spawns at unoccupied Entry 1 (8,11) or Entry 2 (16,11)
; with a random reachable station letter.
; =========================================================
spawnTrain:
push ax
push bx
push cx
push dx
push si
; Max 5 trains allowed at once
cmp byte [train_count], 5
jae near .done_spawn
; Find free slot in isActive[0..4]
mov cx, 5
xor si, si
.find_slot:
cmp byte [isActive + si], 0
je near .slot_found
inc si
dec cx
jnz near .find_slot
jmp near .done_spawn
.slot_found:
; Pick random entrance (0 = Entry 1, 1 = Entry 2)
call getRandom
mov al, ah
and al, 1
cmp al, 0
jne near .try_entry2
.try_entry1:
mov dh, 8
mov dl, 11
call isCellOccupied
cmp al, 0
je near .spawn_at_e1
; Fallback to Entry 2 if Entry 1 is occupied
mov dh, 16
mov dl, 11
call isCellOccupied
cmp al, 0
je near .spawn_at_e2
jmp near .done_spawn
.try_entry2:
mov dh, 16
mov dl, 11
call isCellOccupied
cmp al, 0
je near .spawn_at_e2
; Fallback to Entry 1 if Entry 2 is occupied
mov dh, 8
mov dl, 11
call isCellOccupied
cmp al, 0
je near .spawn_at_e1
jmp near .done_spawn
.spawn_at_e1:
mov byte [train_r + si], 8
mov byte [train_c + si], 11
; Pick random reachable station from A, B, C, D (0..3)
call getRandom
and ax, 3
mov bx, ax
mov al, [entry1_dests + bx]
mov [train_dest + si], al
jmp near .activate_train
.spawn_at_e2:
mov byte [train_r + si], 16
mov byte [train_c + si], 11
; Pick random reachable station from B, C, D (0..2)
call getRandom
xor dx, dx
mov bx, 3
div bx                      ; DX = 0..2
mov bx, dx
mov al, [entry2_dests + bx]
mov [train_dest + si], al
.activate_train:
mov byte [isActive + si], 1
inc byte [train_count]
call drawTrains
.done_spawn:
pop si
pop dx
pop cx
pop bx
pop ax
ret
; =========================================================
; COMPUTE NEXT CELL FOR TRAIN AT (DH=r, DL=c)
; Uses getPartOfTrack & switchState to compute (DH=next_r, DL=next_c)
; =========================================================
getNextCell:
push ax
push bx
push si
xor ax, ax
mov al, dh
push ax                     ; r
mov al, dl
push ax                     ; c
call getPartOfTrack         ; AX = 1..15 (track) or 16..19 (switch)
cmp ax, 0
je near .done_next
; --- Case A: Currently on Switch 1..4 (AX = 16..19) ---
cmp ax, 16
jl near .on_track_part
cmp ax, 19
jg near .done_next
; Switch 1 (8, 20) -> 0: Up (7, 20), 1: Down (9, 20)
cmp ax, 16
jne near .chk_sw2_step
cmp byte [switchState + 0], 0
jne near .sw1_down
dec dh
jmp near .done_next
.sw1_down:
inc dh
jmp near .done_next
; Switch 2 (16, 20) -> 0: Down (17, 20), 1: Up (15, 20)
.chk_sw2_step:
cmp ax, 17
jne near .chk_sw3_step
cmp byte [switchState + 1], 0
jne near .sw2_up
inc dh
jmp near .done_next
.sw2_up:
dec dh
jmp near .done_next
; Switch 3 (12, 44) -> 0: Up (11, 44), 1: Right (12, 45)
.chk_sw3_step:
cmp ax, 18
jne near .chk_sw4_step
cmp byte [switchState + 2], 0
jne near .sw3_right
dec dh
jmp near .done_next
.sw3_right:
inc dl
jmp near .done_next
; Switch 4 (12, 60) -> 0: Right (12, 61), 1: Down (13, 60)
.chk_sw4_step:
cmp byte [switchState + 3], 0
jne near .sw4_down
inc dl
jmp near .done_next
.sw4_down:
inc dh
jmp near .done_next
; --- Case B: Currently on Track Segment 1..15 ---
.on_track_part:
; Check corner turning points before stepping:
; Part 3 (upward) reaching corner1 (5, 20) -> turns right onto Part 7
cmp ax, 3
jne near .chk_c2a
cmp dh, 5
jne near .apply_dr_dc
inc dl
jmp near .done_next
; Part 4 (downward) reaching corner2 (12, 20) -> turns right onto Part 8
.chk_c2a:
cmp ax, 4
jne near .chk_c2b
cmp dh, 12
jne near .apply_dr_dc
inc dl
jmp near .done_next
; Part 5 (upward) reaching corner2 (12, 20) -> turns right onto Part 8
.chk_c2b:
cmp ax, 5
jne near .chk_c3
cmp dh, 12
jne near .apply_dr_dc
inc dl
jmp near .done_next
; Part 6 (downward) reaching corner3 (19, 20) -> turns right onto Part 9
.chk_c3:
cmp ax, 6
jne near .chk_c4
cmp dh, 19
jne near .apply_dr_dc
inc dl
jmp near .done_next
; Part 10 (upward) reaching corner4 (8, 44) -> turns right onto Part 15
.chk_c4:
cmp ax, 10
jne near .chk_c5
cmp dh, 8
jne near .apply_dr_dc
inc dl
jmp near .done_next
; Part 12 (downward) reaching corner5 (16, 60) -> turns right onto Part 14
.chk_c5:
cmp ax, 12
jne near .apply_dr_dc
cmp dh, 16
jne near .apply_dr_dc
inc dl
jmp near .done_next
.apply_dr_dc:
mov si, ax
dec si                      ; 0-based segment index (0..14)
add dh, [track_dr + si]
add dl, [track_dc + si]
.done_next:
pop si
pop bx
pop ax
ret
; =========================================================
; TRAIN MOVEMENT, SCORING & SPEED BOOST (Requirements 2, 3, 4)
; =========================================================
updateTrains:
push ax
push bx
push cx
push dx
push si
xor si, si                  ; SI = train index (0..4)
; Freeze the positions occupied at the beginning of this update.
; All trains consult this snapshot, not positions already changed below.
mov cx, 5
xor bx, bx
.snapshot_loop:
mov al, [train_r + bx]
mov [start_r + bx], al
mov al, [train_c + bx]
mov [start_c + bx], al
mov byte [claimed_active + bx], 0
inc bx
dec cx
jnz near .snapshot_loop
mov byte [update_collision], 1
.train_loop:
cmp si, 5
jae near .finish_update
cmp byte [isActive + si], 1
jne near .next_train
; Current position (DH=r, DL=c)
mov dh, [train_r + si]
mov dl, [train_c + si]
; Compute desired next position (DH=next_r, DL=next_c)
call getNextCell
; Check if next cell is occupied by another train (Collision Prevention)
call isMoveBlocked
cmp al, 1
je near .next_train         ; Wait in place with no penalty if blocked!
; Reserve this destination so later trains cannot claim it.
mov [claimed_r + si], dh
mov [claimed_c + si], dl
mov byte [claimed_active + si], 1
; Advance train to (DH, DL)
mov [train_r + si], dh
mov [train_c + si], dl
; Check if (DH, DL) reached any station (AX = 20..24)
xor ax, ax
mov al, dh
push ax
mov al, dl
push ax
call getPartOfTrack
cmp ax, 20
jl near .next_train
cmp ax, 24
jg near .next_train
; --- Train Reached a Station! ---
sub ax, 20                  ; Station index 0..4
mov bx, ax
mov al, [station_val + bx]  ; Station letter ('A','B','C','D')
; Remove train from track
mov byte [isActive + si], 0
dec byte [train_count]
; Compare destination letter with reached station letter
cmp al, [train_dest + si]
jne near .wrong_station
; Correct Delivery -> +1 Score
inc byte [Score]
; Check One-Time Speed Boost (Requirement 4: Score 6 in 1P, 12 in Co-op)
cmp byte [speedBoosted], 1
je near .chk_win_cond
mov al, 6
cmp byte [mode], 2
jne near .cmp_boost
mov al, 12
.cmp_boost:
cmp byte [Score], al
jl near .chk_win_cond
mov byte [speedBoosted], 1
shr byte [TickRate], 1      ; Integer division by 2
cmp byte [TickRate], 1
jae near .chk_win_cond
mov byte [TickRate], 1      ; Minimum 1 tick
.chk_win_cond:
mov al, [ReqScore]
cmp byte [Score], al
jb near .update_hud_after_sta
mov byte [game_over_state], 1 ; Win!
jmp near .update_hud_after_sta
.wrong_station:
; Wrong Delivery -> +1 Mistake
inc byte [strikes]
mov al, [maxStrikes]
cmp byte [strikes], al
jb near .update_hud_after_sta
mov byte [game_over_state], 2 ; Lose!
.update_hud_after_sta:
call printStats
.next_train:
inc si
jmp near .train_loop
.finish_update:
; End snapshot collision mode before ordinary occupancy checks/spawning
mov byte [update_collision], 0
; Redraw tracks, switches, stations, and trains cleanly
call draw_track
call drawSwitches
call drawStations
call drawTrains
pop si
pop dx
pop cx
pop bx
pop ax
ret
; =========================================================
; INPUT HANDLING (Single-Player & 2-Player Co-op)
; =========================================================
handleInput:
push ax
push bx
push cx
push si
mov al, [key_pressed]
cmp al, 0
je near .done_input
mov byte [key_pressed], 0   ; Consume key
cmp al, 27                  ; ESC
jne near .chk_1p_keys
mov byte [exit_flag], 1
jmp near .done_input
; Keys '1' and '2' work in both 1P and Co-op
.chk_1p_keys:
cmp al, '1'
je near .toggle_sw1
cmp al, '2'
je near .toggle_sw2
; In Single-Player, '3' and '4' toggle switches 3 and 4
cmp byte [mode], 1
jne near .chk_coop_keys
cmp al, '3'
je near .toggle_sw3
cmp al, '4'
je near .toggle_sw4
jmp near .done_input
; In Co-op, Player 2 uses 'J'/'j' and 'K'/'k' for switches 3 and 4
.chk_coop_keys:
cmp al, 'j'
je near .toggle_sw3
cmp al, 'J'
je near .toggle_sw3
cmp al, 'k'
je near .toggle_sw4
cmp al, 'K'
je near .toggle_sw4
jmp near .done_input
.toggle_sw1:
mov bx, 0
jmp near .do_toggle
.toggle_sw2:
mov bx, 1
jmp near .do_toggle
.toggle_sw3:
mov bx, 2
jmp near .do_toggle
.toggle_sw4:
mov bx, 3
.do_toggle:
xor byte [switchState + bx], 1
shl bx, 1
shl bx, 1
lea si, [sw_parts + bx]
mov cx, 4
.redraw_loop:
mov al, [si]
cmp al, 0
je near .redraw_done
xor ah, ah
push ax
call drawTrackPart
inc si
dec cx
jnz near .redraw_loop
.redraw_done:
call drawSwitches
call drawTrains             ; Keep trains visible on top of redrawn tracks
.done_input:
pop si
pop cx
pop bx
pop ax
ret
; =========================================================
; END GAME SCREEN (Win / Lose & Replay Prompt - Req 6)
; =========================================================
showEndScreen:
call printStats
cmp byte [game_over_state], 1
jne near .show_lose_msg
push word str_win
push word 47
push word 10
push word 16
push word 0x2F              ; Bright White on Green banner
call printString
jmp near .show_replay_msg
.show_lose_msg:
push word str_lose
push word 45
push word 10
push word 17
push word 0x4F              ; Bright White on Red banner
call printString
.show_replay_msg:
push word str_replay
push word 36
push word 13
push word 22
push word 0x0E              ; Bright Yellow
call printString
.wait_end_key:
mov al, [key_pressed]
cmp al, 0
je near .wait_end_key
mov byte [key_pressed], 0
cmp al, 27                  ; ESC -> Exit
jne near .chk_replay_key
mov byte [exit_flag], 1
ret
.chk_replay_key:
cmp al, 'r'
je near .do_replay
cmp al, 'R'
jne near .wait_end_key
.do_replay:
call resetGame
call clrscr
call initNavBar
call printStats
call draw_track
call drawSwitches
call drawStations
ret
; =========================================================
; MAIN ENTRY POINT
; =========================================================
start:
mov ax, 0x1003      ; Enable 16 background colors (disable blink)
xor bx, bx
int 0x10
call seedRandom
call hideCursor
call showMainMenu
cmp byte [exit_flag], 1
je near .exit_to_dos
call resetGame
call clrscr
call initNavBar
call printStats
call draw_track
call drawSwitches
call drawStations
; Save & hook INT 08h
mov ax, 0x3508
int 0x21
mov [old_int8], bx
mov [old_int8 + 2], es
mov ax, 0x2508
mov dx, my_int8
int 0x21
.game_loop:
call handleInput
cmp byte [exit_flag], 1
je near .unhook_and_exit
; 1. Update elapsed timer on screen every 1 second
cmp byte [secChanged], 1
jne near .chk_spawn_tick
mov byte [secChanged], 0
call printStats
; 2. Check if it's time to move trains (every TickRate ticks)
.chk_spawn_tick:
mov al, [TickRate]
cmp byte [currentTickCount], al
jb near .game_loop
mov byte [currentTickCount], 0
call updateTrains
; Check Win / Lose condition
cmp byte [game_over_state], 0
je near .do_spawn_step
call showEndScreen
cmp byte [exit_flag], 1
je near .unhook_and_exit
jmp near .game_loop
; 3. Decrement spawn timer and spawn a new train periodically
.do_spawn_step:
dec byte [spawn_timer]
jnz near .game_loop
mov byte [spawn_timer], SPAWN_INTERVAL
call spawnTrain
jmp near .game_loop
.unhook_and_exit:
; Restore original INT 08h vector before returning to DOS
lds dx, [old_int8]
mov ax, 0x2508
int 0x21
push cs
pop ds
.exit_to_dos:
mov ax, 0x1003
mov bx, 1
int 0x10
call showCursor
call clrscr
mov ax, 0x4c00
int 0x21

