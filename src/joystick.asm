; joystick.asm -- ReadJoystick, the game-port sampling routine of the Joystick unit (joystick.pas).
;
; Game port 201h: bits 0-3 are the axis one-shots (stick 1 X, Y; stick 2 X, Y), which read 1 while timing after any
; write to the port; bits 4-7 are the buttons (stick 1 buttons 1, 2; stick 2 buttons 1, 2), which read 0 while
; pressed.  An axis position is the number of reads until its bit falls.
;
; ReadJoystick takes joy and the far addresses of xRaw, yRaw and buttons, and returns its Boolean in AL.  It is far,
; and each ret pops the arguments, which lie in Pascal order, the last one declared nearest bp:
argJoy       EQU 12h            ; joy: 1 or 2
argXRaw      EQU 0Eh            ; @xRaw, far
argYRaw      EQU 0Ah            ; @yRaw, far
argButtons   EQU 06h            ; @buttons, far

CODE    SEGMENT BYTE PUBLIC
        ASSUME  CS:CODE
        PUBLIC  ReadJoystick

ReadJoystick    PROC FAR
        push    bp
        mov     bp,sp
        cmp     byte ptr [bp+argJoy],1  ; joy must be 1 or 2
        jz      joyValid
        cmp     byte ptr [bp+argJoy],2
        jz      joyValid
        mov     al,0                    ; bad joy -> False
        pop     bp
        ret     0Eh
joyValid:
        mov     ah,1                    ; AH = the stick's X-axis bit: bit 0 for stick 1
        xor     bx,bx                   ; (BX is set again below)
        cmp     byte ptr [bp+argJoy],2
        jnz     fireX                   ; stick 1 keeps bit 0
        shl     ah,1                    ; bit 2 for stick 2
        shl     ah,1
fireX:
        mov     bx,1                    ; BX counts reads: the axis position
        xor     cx,cx                   ; CX = 0: LOOP allows 65536 reads
        mov     al,0FFh
        mov     dx,201h                 ; DX = the game port
        out     dx,al                   ; any write fires all four one-shots
xLoop:
        in      al,dx                   ; read the port's bits
        not     al                      ; a lapsed axis bit now reads 1
        test    al,ah                   ; X lapsed?
        jnz     xDone
        inc     bx
        loop    xLoop
        mov     al,0                    ; X never lapsed -> False
        pop     bp
        ret     0Eh
; The spin makes up the iterations a count falls short of 1FFFh, so each axis takes about the same time whatever the
; stick's position.
xDone:
        mov     cx,1FFFh                ; spin 1FFFh minus the count (65536 at exactly 1FFFh)
        sub     cx,bx
        jc      xStore                  ; count above 1FFFh: no spin
        loop    $                       ; spin CX times
xStore:
        les     di,[bp+argXRaw]         ; ES:DI = @xRaw
        mov     es:[di],bx              ; xRaw := count
        shl     ah,1                    ; AH = the same stick's Y-axis bit
        xor     cx,cx                   ; CX = 0: up to 65536 reads
yWait:
        in      al,dx                   ; wait for Y's one-shot from the first write
        not     al
        test    al,ah                   ; Y lapsed?
        jnz     fireY
        loop    yWait
        mov     al,0                    ; Y never lapsed -> False
        pop     bp
        ret     0Eh
fireY:
        mov     bx,1                    ; restart the count for Y
        xor     cx,cx                   ; CX = 0: up to 65536 reads
        mov     al,0FFh
        out     dx,al                   ; fire the one-shots again to time Y
yLoop:
        in      al,dx                   ; read the port's bits
        not     al
        test    al,ah                   ; Y lapsed?
        jnz     yDone
        inc     bx
        loop    yLoop
        mov     al,0                    ; Y timed out -> False
        pop     bp
        ret     0Eh
; Note: yDone's jc goes to X's store, not Y's.  A Y count above 1FFFh then overwrites xRaw, AH moves up to the next
; port bit, and that bit is timed as Y: the read usually times out and returns False, and a count above 1FFFh takes
; this jc again.  On that path the comments where AH goes back to the X-axis bit and at buttonWait below do not hold.
yDone:
        mov     cx,1FFFh                ; spin 1FFFh minus the count, as for X
        sub     cx,bx
        jc      xStore                  ; Note: to X's store (see above)
        loop    $                       ; spin CX times
        les     di,[bp+argYRaw]         ; ES:DI = @yRaw
        mov     es:[di],bx              ; yRaw := count
        shr     ah,1                    ; AH = the X-axis bit again
        xor     cx,cx                   ; CX = 0: up to 65536 reads
buttonWait:
        in      al,dx                   ; wait for X's one-shot from the second write
        not     al                      ; buttons now read 1 while pressed
        test    al,ah                   ; X lapsed?
        jnz     buttonsDone             ; AL keeps this read's button bits
        loop    buttonWait
        mov     al,0                    ; X never lapsed -> False
        pop     bp
        ret     0Eh
buttonsDone:
        mov     cx,4
        shr     al,cl                   ; button bits 4-7 down to bits 0-3
        les     di,[bp+argButtons]      ; ES:DI = @buttons
        mov     es:[di],al              ; buttons := the four button bits
        mov     al,1                    ; success -> True
        pop     bp
        ret     0Eh
ReadJoystick    ENDP
CODE    ENDS
        END
