; VgaFrame's assembly routines, XorFrame and ExpandRleFrame, which PrepareVgaFrame in vgaframe.pas and Portrait's
; animation loader call to decode VGA portrait frames.  Both are FAR and keep the caller's DS in DX while they run.

; Arguments, FAR and in Pascal order: the last one declared lies nearest bp
xorSrc       EQU 10h            ; XorFrame: src, far pointer
xorDst       EQU 0Ch            ; XorFrame: dst, far pointer
xorKey       EQU 08h            ; XorFrame: key, far pointer
xorCount     EQU 06h            ; XorFrame: count, bytes
rleSrc       EQU 0Ch            ; ExpandRleFrame: src, far pointer
rleDst       EQU 08h            ; ExpandRleFrame: dst, far pointer
rleEncoded   EQU 06h            ; ExpandRleFrame: encodedBytes

CODE    SEGMENT BYTE PUBLIC
        ASSUME  CS:CODE
        PUBLIC  XorFrame, ExpandRleFrame

; XorFrame: stores each byte of src, XORed with the same byte of key, into dst, for count bytes; dst may be src.
; LOOP tests CX after decrementing it, so a count of 0 runs 65536 bytes: count must be above 0.
XorFrame PROC FAR
        push    bp
        mov     bp,sp
        cld                             ; (no string instruction follows)
        mov     dx,ds                   ; keep the caller's DS
        les     si,[bp+xorSrc]          ; ES:SI = src, as DS changes below
        mov     cx,[bp+xorCount]        ; CX counts the bytes left
        mov     bx,0                    ; BX = i, the offset into all three buffers
        mov     ax,0                    ; (only AL is used)
xor_loop:
        mov     al,es:[bx+si]           ; src[i]
        lds     di,[bp+xorKey]          ; key, reloaded every byte
        xor     al,[bx+di]              ; xor key[i]
        lds     di,[bp+xorDst]
        mov     [bx+di],al              ; dst[i] := the result
        inc     bx
        loop    xor_loop
        mov     ds,dx                   ; restore the caller's DS
        pop     bp
        ret     0Eh                     ; pops src, dst, key and count
XorFrame ENDP

; ExpandRleFrame: expands encodedBytes of run-length code at src into dst.  A control byte n up to 7Fh is followed by
; n+1 literal bytes; one above 7Fh by one byte that is repeated 257-n times.
ExpandRleFrame PROC FAR
        push    bp
        mov     bp,sp
        cld                             ; MOVSB and STOSB step forward
        mov     dx,ds                   ; keep the caller's DS
        lds     si,[bp+rleSrc]          ; DS:SI = the code
        les     di,[bp+rleDst]          ; ES:DI = the expanded frame
        mov     bx,0                    ; BX counts the code bytes consumed
        mov     ax,0                    ; AH stays 0, so AX = AL below
rle_next:
        cmp     bx,[bp+rleEncoded]      ; all encodedBytes consumed?
        jae     rle_done
        cmp     byte ptr [si],7Fh       ; control byte above 7Fh: a repeat
        ja      rle_repeat
        mov     al,[si]                 ; a literal run: n
        add     bx,ax
        inc     bx
        inc     bx                      ; consumes the control byte and n+1 literals
        mov     cx,ax
        inc     cx                      ; copies n+1
        inc     si                      ; SI = the first literal
        rep     movsb
        jmp     rle_next
rle_repeat:
        inc     bx
        inc     bx                      ; consumes the control byte and the value
        mov     cx,100h
        mov     al,[si]
        sub     cx,ax
        inc     cx                      ; CX = 257-n
        inc     si                      ; SI = the value
        lodsb                           ; the value to repeat
        rep     stosb
        jmp     rle_next
rle_done:
        mov     ds,dx                   ; restore the caller's DS
        pop     bp
        ret     0Ah                     ; pops src, dst and encodedBytes
ExpandRleFrame ENDP

CODE    ENDS
        END
