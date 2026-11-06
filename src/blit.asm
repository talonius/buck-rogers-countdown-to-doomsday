; blit.asm -- the assembler half of the Blit unit, linked into its code segment through {$L BLIT.OBJ}: the per-mode tile
; blitters that BlitTileCell and BlitTileClipped dispatch to, the scanline loops those blitters share, and the EGA and
; VGA line fills that Hline and Vline call.
;
; Every procedure is NEAR, called from inside the unit's own segment.  Arguments are in Pascal order, so the last one
; declared lies nearest bp.
;
; The row loops record what they draw in four dirty-row tables, which Blit's FlushView copies to the screen.
; They are named below as externals and reached through DS, which holds the data segment whenever a loop touches them.
; Each table has 168 entries, one per view scanline.  Note: nothing bounds the row index, so a tile on rows 168..199 of
; a 200-row picture writes past each table into the next.

        LOCALS

DATA    SEGMENT WORD PUBLIC
        EXTRN   dirtyRows:BYTE          ; per view scanline, non-zero once drawn
        EXTRN   dirtyRowLeft:WORD       ; per scanline, the screen byte of the leftmost dirty cell
        EXTRN   dirtyRowFirst:WORD      ; per scanline, the picture offset of the first dirty byte
        EXTRN   dirtyRowLast:WORD       ; per scanline, the picture offset of the last dirty byte
DATA    ENDS

VideoSeg     EQU 0A000h         ; EGA/VGA display memory, as C_Video's VIDEO_SEG
EgaRowBytes  EQU 40             ; one EGA plane scanline, 320 pixels at 8 per byte
VgaRowBytes  EQU 320            ; one mode-13h scanline, a byte per pixel
SeqIndex     EQU 3C4h           ; EGA sequencer index port, data at the next port
GcIndex      EQU 3CEh           ; EGA graphics controller index port, data at the next port
SeqMapMask   EQU 2              ; sequencer: the planes a write reaches
GcSetReset   EQU 0              ; graphics controller: the set/reset color
GcEnableSR   EQU 1              ; graphics controller: the planes set/reset drives
GcFunction   EQU 3              ; graphics controller: data rotate / function select
GcMode       EQU 5              ; graphics controller: write mode
GcBitMask    EQU 8              ; graphics controller: the pixels of a byte a write changes

; TImgBuf (Types') fields the blitters touch
imgHeight    EQU 00h            ; height: scanlines per frame
imgWidth     EQU 02h            ; width: 8-pixel cells per scanline
imgFrameSize EQU 12h            ; frameSize: bytes per frame
imgTransp    EQU 17h            ; transp: far pointer to the mask plane
imgData      EQU 1Bh            ; data: the pixels, inline after the header

; The cell and clipped blitters share one frame, and the row loops run inside it.  Note: each prologue reserves the
; frame twice; the locals use the first.
; Arguments:
argDest      EQU 04h            ; dest: PImgBuf, the picture drawn into
argGfx       EQU 08h            ; gfx:  PImgBuf, the tile set
cellTile     EQU 0Ch            ; cell blitters: tileIdx, the frame of gfx drawn
cellY        EQU 0Eh            ; cell blitters: screenY, in 8-scanline cells
cellX        EQU 10h            ; cell blitters: screenX, in cells
keyCellKey   EQU 0Eh            ; BlitCellVgaKeyed: transpColor
keyCellY     EQU 10h            ; BlitCellVgaKeyed: screenY
keyCellX     EQU 12h            ; BlitCellVgaKeyed: screenX
clipMode     EQU 0Ch            ; clipped blitters: flag, bit 0 masked, bit 2 save what is covered
clipTile     EQU 0Eh            ; clipped blitters: tileIdx
clipY        EQU 10h            ; clipped blitters: screenY, in cells, may be negative
clipX        EQU 12h            ; clipped blitters: screenX, in cells, may be negative
argSave      EQU 14h            ; clipped blitters: the save-under buffer, a PImgBuf where covered pixels go
keyClipKey   EQU 10h            ; BlitClippedVga: transpColor
keyClipY     EQU 12h            ; BlitClippedVga: screenY
keyClipX     EQU 14h            ; BlitClippedVga: screenX
keyClipSave  EQU 16h            ; BlitClippedVga: under
; Locals:
maskPtr      EQU -04h           ; far pointer, copy of gfx^.transp
spanLeft     EQU -06h           ; value recorded into dirtyRowLeft
viewRow      EQU -08h           ; first scanline, indexes the dirty-row tables
rowCount     EQU -0Ah           ; scanlines to draw
destOff      EQU -0Ch           ; running offset into dest^.data
srcOff       EQU -0Eh           ; running offset into gfx^.data (and the mask)
rowBytes     EQU -10h           ; bytes copied per scanline
destSkip     EQU -12h           ; dest bytes right of the tile
leftBytes    EQU -14h           ; dest bytes left of the tile
skipRight    EQU -16h           ; tile bytes clipped off the right
skipLeft     EQU -18h           ; tile bytes clipped off the left
saveFlag     EQU -1Ah           ; byte: copy the covered pixels to the save-under buffer first
saveOff      EQU -1Ch           ; running offset into the save-under buffer's data
keyColor     EQU -1Ch           ; VGA frame: byte, the transparent color
keySaveOff   EQU -1Eh           ; VGA frame: saveOff, moved down past keyColor

; HlineEga/HlineVga and VlineEga/VlineVga: color, the last argument, then the line's own coordinates
lineColor    EQU 04h            ; color
hlRow        EQU 06h            ; Hline*: row, the screen scanline
hlX2         EQU 08h            ; Hline*: x2, the last pixel
hlX1         EQU 0Ah            ; Hline*: x1, the first pixel
vlX          EQU 06h            ; Vline*: x, the pixel column
vlY2         EQU 08h            ; Vline*: y2, the last scanline
vlY1         EQU 0Ah            ; Vline*: y1, the first scanline

CODE    SEGMENT BYTE PUBLIC             ; no 'CODE' class -> {$L} merges into the unit seg
        ASSUME  CS:CODE, DS:DATA
        PUBLIC  BlitCellCga, BlitCellCgaMasked, BlitClippedCga
        PUBLIC  BlitCellEga, BlitCellEgaMasked, BlitClippedEga
        PUBLIC  BlitCellTandy, BlitCellTandyMasked, BlitClippedTandy
        PUBLIC  BlitCellVga, BlitCellVgaKeyed, BlitClippedVga
        PUBLIC  HlineEga, VlineEga, HlineVga, VlineVga

; The cell blitters, BlitCellCga and BlitCellCgaMasked and their forms for the other modes, draw tile tileIdx of gfx
; into dest at cell (screenX, screenY), whole or through the tile's mask.  The clipped blitters, BlitClippedCga and its
; forms, do the same for a tile that may hang off dest's edges, and can first save the pixels it covers into the
; save-under buffer.  The display mode fixes the bytes per 8-pixel cell row: CGA 2, EGA 4, Tandy 4, VGA 8.  VGA has no
; mask plane; BlitCellVgaKeyed and BlitClippedVga key on a color instead, with one more local in their frame.

BlitCellCga PROC NEAR
        push    bp                      ; frame for the arguments and locals
        mov     bp,sp
        sub     sp,1Ch                  ; the frame
        sub     sp,1Ch                  ; again: the frame is reserved twice
        push    ss                      ; SS and DS are restored before the return
        push    ds
        cld                             ; CopyRows' movsb walks upwards
        les     di,[bp+argDest]         ; ES:DI = dest
        mov     ax,[bp+cellY]           ; viewRow = screenY * 8, the first scanline
        mov     cl,3
        shl     ax,cl
        mov     [bp+viewRow],ax
        mov     bx,es:[di+imgWidth]     ; destOff = viewRow * dest width, in cells
        mul     bx
        mov     [bp+destOff],ax
        mov     ax,[bp+cellX]           ; leftBytes = screenX, in cells for now
        mov     [bp+leftBytes],ax
        mov     ax,es:[di+imgWidth]     ; ax = dest width
        les     di,[bp+argGfx]          ; ES:DI = the tile set
        sub     ax,es:[di+imgWidth]     ; destSkip = dest width - tile width - screenX:
        sub     ax,[bp+cellX]           ;   the dest cells right of the tile
        mov     [bp+destSkip],ax
        mov     ax,[bp+leftBytes]       ; spanLeft = leftBytes, to bytes (2 a cell)
        mov     [bp+spanLeft],ax
        shl     word ptr [bp+spanLeft],1
        mov     ax,es:[di+imgWidth]     ; rowBytes = the tile width in bytes
        shl     ax,1
        mov     [bp+rowBytes],ax
        mov     ax,es:[di+imgHeight]    ; rowCount = the tile's scanlines
        mov     [bp+rowCount],ax
        shl     word ptr [bp+leftBytes],1 ; leftBytes and destSkip to bytes
        shl     word ptr [bp+destSkip],1
        mov     ax,es:[di+imgFrameSize] ; srcOff = frameSize * tileIdx, the tile's frame
        xor     bx,bx
        mov     bl,[bp+cellTile]
        mul     bx
        mov     [bp+srcOff],ax
        shl     word ptr [bp+destOff],1 ; destOff to bytes
        mov     bx,[bp+viewRow]         ; bx = the first scanline, cx = the rows, as
        mov     cx,[bp+rowCount]        ;   the row loops take them
        mov     byte ptr [bp+saveFlag],0 ; nothing to save, nothing clipped
        mov     word ptr [bp+skipLeft],0
        mov     word ptr [bp+skipRight],0
        call    CopyRows                ; rowCount rows from scanline viewRow
        pop     ds                      ; restore DS and SS
        pop     ss
        mov     sp,bp                   ; drop the frame
        pop     bp
        ret     0Eh                     ; pops the arguments
BlitCellCga ENDP

; BlitCellCgaMasked: BlitCellCga, but it records gfx's mask pointer and calls MaskRows, which uses no string
; instructions and so needs no cld.
BlitCellCgaMasked PROC NEAR
        push    bp                      ; frame for the arguments and locals
        mov     bp,sp
        sub     sp,1Ch                  ; the frame, reserved twice as in BlitCellCga
        sub     sp,1Ch
        push    ss                      ; SS and DS are restored before the return
        push    ds
        les     di,[bp+argDest]         ; ES:DI = dest
        mov     ax,[bp+cellY]           ; viewRow = screenY * 8
        mov     cl,3
        shl     ax,cl
        mov     [bp+viewRow],ax
        mov     bx,es:[di+imgWidth]     ; destOff = viewRow * dest width, in cells
        mul     bx
        mov     [bp+destOff],ax
        mov     ax,[bp+cellX]           ; leftBytes = screenX, in cells for now
        mov     [bp+leftBytes],ax
        mov     ax,es:[di+imgWidth]     ; ax = dest width
        les     di,[bp+argGfx]          ; ES:DI = the tile set
        sub     ax,es:[di+imgWidth]     ; destSkip = dest width - tile width - screenX
        sub     ax,[bp+cellX]
        mov     [bp+destSkip],ax
        mov     ax,[bp+leftBytes]       ; spanLeft = leftBytes, to bytes
        mov     [bp+spanLeft],ax
        shl     word ptr [bp+spanLeft],1
        mov     ax,es:[di+imgWidth]     ; rowBytes = the tile width in bytes
        shl     ax,1
        mov     [bp+rowBytes],ax
        mov     ax,es:[di+imgHeight]    ; rowCount = the tile's scanlines
        mov     [bp+rowCount],ax
        mov     ax,es:[di+imgTransp]    ; maskPtr = the tile set's mask
        mov     [bp+maskPtr],ax
        mov     ax,es:[di+imgTransp+2]
        mov     [bp+maskPtr+2],ax
        shl     word ptr [bp+leftBytes],1 ; leftBytes and destSkip to bytes
        shl     word ptr [bp+destSkip],1
        mov     ax,es:[di+imgFrameSize] ; srcOff = frameSize * tileIdx
        xor     bx,bx
        mov     bl,[bp+cellTile]
        mul     bx
        mov     [bp+srcOff],ax
        shl     word ptr [bp+destOff],1 ; destOff to bytes
        mov     bx,[bp+viewRow]         ; bx = the first scanline, cx = the rows
        mov     cx,[bp+rowCount]
        mov     byte ptr [bp+saveFlag],0 ; nothing to save, nothing clipped
        mov     word ptr [bp+skipLeft],0
        mov     word ptr [bp+skipRight],0
        call    MaskRows                ; rowCount rows through the mask
        pop     ds                      ; restore DS and SS, drop the frame
        pop     ss
        mov     sp,bp
        pop     bp
        ret     0Eh                     ; pops the arguments
BlitCellCgaMasked ENDP

BlitClippedCga PROC NEAR
        push    bp                      ; frame for the arguments and locals
        mov     bp,sp
        sub     sp,1Ch                  ; the frame, reserved twice
        sub     sp,1Ch
        push    ss                      ; SS and DS are restored before the return
        push    ds
        cld                             ; CopyRows' movsb walks upwards
        push    ds                      ; the caller's DS, kept past the lds below
        lds     si,[bp+argGfx]          ; DS:SI = the tile set
        les     di,[bp+argDest]         ; ES:DI = dest
        mov     ax,[si+imgTransp]       ; maskPtr = the tile set's mask
        mov     [bp+maskPtr],ax
        mov     ax,[si+imgTransp+2]
        mov     [bp+maskPtr+2],ax
        mov     ax,[bp+clipX]
        cmp     ax,8000h                ; a negative x (unsigned above 8000h)?
        jbe     @@xOnScreen
        mov     [bp+skipLeft],ax        ; skipLeft = -x, the tile cells left of the edge
        neg     word ptr [bp+skipLeft]
        mov     word ptr [bp+leftBytes],0 ; drawn from dest's left edge
        jmp     @@checkRight
@@xOnScreen:
        mov     word ptr [bp+skipLeft],0 ; nothing clipped on the left
        mov     [bp+leftBytes],ax       ; leftBytes = x, in cells for now
@@checkRight:
        add     ax,[si+imgWidth]        ; ax = x + tile width, the tile's right end
        cmp     es:[di+imgWidth],ax     ; does dest's width reach it?
        jae     @@rightFits
        sub     ax,es:[di+imgWidth]     ; skipRight = the tile cells past the right edge
        mov     [bp+skipRight],ax
        mov     word ptr [bp+destSkip],0 ; nothing of dest right of the tile
        jmp     @@clipTop
@@rightFits:
        mov     word ptr [bp+skipRight],0 ; nothing clipped on the right
        mov     ax,es:[di+imgWidth]     ; destSkip = dest width - x - tile width
        sub     ax,[bp+clipX]
        sub     ax,[si+imgWidth]
        mov     [bp+destSkip],ax
@@clipTop:
        mov     ax,[bp+clipY]
        cmp     ax,8000h                ; a negative y?
        jbe     @@yOnScreen
        neg     ax                      ; ax = the scanlines above the top edge, -y * 8
        mov     cx,3
        shl     ax,cl
        mov     bx,[si+imgHeight]       ; rowCount = the tile's rows below the edge
        mov     [bp+rowCount],bx
        sub     [bp+rowCount],ax
        mov     bx,[si+imgWidth]        ; srcOff = the hidden rows' cells
        mul     bx
        mov     [bp+srcOff],ax
        mov     word ptr [bp+destOff],0 ; drawn from dest's top scanline
        mov     word ptr [bp+viewRow],0
        jmp     @@checkEmpty
@@yOnScreen:
        mov     word ptr [bp+srcOff],0  ; nothing clipped at the top
        mov     cx,3                    ; viewRow = y * 8
        shl     ax,cl
        mov     [bp+viewRow],ax
        mov     bx,es:[di+imgWidth]     ; destOff = viewRow * dest width, in cells
        mul     bx
        mov     [bp+destOff],ax
        mov     ax,[bp+viewRow]         ; does the tile end above dest's bottom?
        add     ax,[si+imgHeight]
        cmp     ax,es:[di+imgHeight]
        jbe     @@bottomFits
        mov     ax,es:[di+imgHeight]    ; rowCount = the rows above dest's bottom
        sub     ax,[bp+viewRow]
        mov     [bp+rowCount],ax
        jmp     @@checkEmpty
@@bottomFits:
        mov     ax,[si+imgHeight]       ; rowCount = all the tile's rows
        mov     [bp+rowCount],ax
@@checkEmpty:
        mov     ax,[si+imgWidth]        ; clipped off the left or right entirely?
        cmp     ax,[bp+skipLeft]
        jb      @@offView               ; nothing left on dest: draw nothing
        cmp     ax,[bp+skipRight]
        jb      @@offView
        mov     ax,[bp+srcOff]          ; clipped off the top entirely?
        cmp     ax,[si+imgFrameSize]
        ja      @@offView
        mov     ax,[bp+destOff]         ; starting below dest's last byte?
        cmp     ax,es:[di+imgFrameSize]
        ja      @@offView
        mov     ax,[bp+rowCount]        ; a negative rowCount, read unsigned?
        cmp     ax,[si+imgHeight]
        ja      @@offView
        jmp     @@draw
@@offView:
        pop     ds                      ; the caller's DS again
        pop     ds                      ; restore DS and SS, drop the frame
        pop     ss
        mov     sp,bp
        pop     bp
        ret     14h                     ; pops the arguments
@@draw:
        mov     ax,[bp+leftBytes]       ; leftBytes to bytes, and spanLeft with it
        shl     ax,1
        mov     [bp+leftBytes],ax
        mov     [bp+spanLeft],ax
        mov     ax,[si+imgWidth]        ; rowBytes = the visible cells, in bytes
        sub     ax,[bp+skipLeft]
        sub     ax,[bp+skipRight]
        shl     ax,1
        mov     [bp+rowBytes],ax
        shl     word ptr [bp+skipLeft],1 ; the remaining cell counts to bytes
        shl     word ptr [bp+skipRight],1
        shl     word ptr [bp+destSkip],1
        shl     word ptr [bp+srcOff],1
        shl     word ptr [bp+destOff],1
        mov     ax,[bp+srcOff]          ; saveOff = the first covered byte, in the save picture
        mov     [bp+saveOff],ax
        mov     ax,[si+imgFrameSize]    ; srcOff += frameSize * tileIdx, the tile's frame
        xor     bx,bx
        mov     bl,[bp+clipTile]
        mul     bx
        add     [bp+srcOff],ax
        mov     bx,[bp+viewRow]         ; bx = the first scanline, cx = the rows
        mov     cx,[bp+rowCount]
        mov     byte ptr [bp+saveFlag],0 ; no save unless the masked path asks
        pop     ds                      ; DS = the data segment again, for the dirty-row tables
        test    byte ptr [bp+clipMode],1 ; bit 0: masked
        jne     @@masked
        call    CopyRows                ; unmasked: copy the rows
        pop     ds                      ; restore DS and SS, drop the frame
        pop     ss
        mov     sp,bp
        pop     bp
        ret     14h                     ; pops the arguments
@@masked:
        mov     byte ptr [bp+saveFlag],0
        test    byte ptr [bp+clipMode],4 ; bit 2: save what is covered first
        je      @@noSave
        mov     byte ptr [bp+saveFlag],1
@@noSave:
        call    MaskRows                ; draw the rows through the mask
        pop     ds                      ; restore DS and SS, drop the frame
        pop     ss
        mov     sp,bp
        pop     bp
        ret     14h                     ; pops the arguments
BlitClippedCga ENDP

; The EGA, Tandy and VGA blitters repeat the CGA ones at their own bytes per cell (EGA and Tandy 4, VGA 8: two or three
; shl's for CGA's one).  EGA records spanLeft in cells, before the scaling, where the others record bytes; FlushView's
; EGA arm reads it as a column.
BlitCellEga PROC NEAR
        push    bp                      ; frame for the arguments and locals
        mov     bp,sp
        sub     sp,1Ch                  ; the frame, reserved twice
        sub     sp,1Ch
        push    ss                      ; SS and DS are restored before the return
        push    ds
        cld                             ; CopyRows' movsb walks upwards
        les     di,[bp+argDest]         ; ES:DI = dest
        mov     ax,[bp+cellY]           ; viewRow = screenY * 8
        mov     cl,3
        shl     ax,cl
        mov     [bp+viewRow],ax
        mov     bx,es:[di+imgWidth]     ; destOff = viewRow * dest width, in cells
        mul     bx
        mov     [bp+destOff],ax
        mov     ax,[bp+cellX]           ; leftBytes = screenX, in cells for now
        mov     [bp+leftBytes],ax
        mov     ax,es:[di+imgWidth]     ; ax = dest width
        les     di,[bp+argGfx]          ; ES:DI = the tile set
        sub     ax,es:[di+imgWidth]     ; destSkip = dest width - tile width - screenX
        sub     ax,[bp+cellX]
        mov     [bp+destSkip],ax
        mov     ax,[bp+leftBytes]       ; spanLeft = screenX, left in cells
        mov     [bp+spanLeft],ax
        mov     ax,es:[di+imgWidth]     ; rowBytes = the tile width in bytes (4 a cell)
        shl     ax,1
        shl     ax,1
        mov     [bp+rowBytes],ax
        mov     ax,es:[di+imgHeight]    ; rowCount = the tile's scanlines
        mov     [bp+rowCount],ax
        shl     word ptr [bp+leftBytes],1 ; leftBytes and destSkip to bytes
        shl     word ptr [bp+leftBytes],1
        shl     word ptr [bp+destSkip],1
        shl     word ptr [bp+destSkip],1
        mov     ax,es:[di+imgFrameSize] ; srcOff = frameSize * tileIdx
        xor     bx,bx
        mov     bl,[bp+cellTile]
        mul     bx
        mov     [bp+srcOff],ax
        shl     word ptr [bp+destOff],1 ; destOff to bytes
        shl     word ptr [bp+destOff],1
        mov     bx,[bp+viewRow]         ; bx = the first scanline, cx = the rows
        mov     cx,[bp+rowCount]
        mov     byte ptr [bp+saveFlag],0 ; nothing to save, nothing clipped
        mov     word ptr [bp+skipLeft],0
        mov     word ptr [bp+skipRight],0
        call    CopyRows                ; copy the rows
        pop     ds                      ; restore DS and SS, drop the frame
        pop     ss
        mov     sp,bp
        pop     bp
        ret     0Eh                     ; pops the arguments
BlitCellEga ENDP

BlitCellEgaMasked PROC NEAR
        push    bp                      ; frame for the arguments and locals
        mov     bp,sp
        sub     sp,1Ch                  ; the frame, reserved twice
        sub     sp,1Ch
        push    ss                      ; SS and DS are restored before the return
        push    ds
        cld                             ; as BlitCellEga, though MaskRows moves no strings
        les     di,[bp+argDest]         ; ES:DI = dest
        mov     ax,[bp+cellY]           ; viewRow = screenY * 8
        mov     cl,3
        shl     ax,cl
        mov     [bp+viewRow],ax
        mov     bx,es:[di+imgWidth]     ; destOff = viewRow * dest width, in cells
        mul     bx
        mov     [bp+destOff],ax
        mov     ax,[bp+cellX]           ; leftBytes = screenX, in cells for now
        mov     [bp+leftBytes],ax
        mov     ax,es:[di+imgWidth]     ; ax = dest width
        les     di,[bp+argGfx]          ; ES:DI = the tile set
        sub     ax,es:[di+imgWidth]     ; destSkip = dest width - tile width - screenX
        sub     ax,[bp+cellX]
        mov     [bp+destSkip],ax
        mov     ax,[bp+leftBytes]       ; spanLeft = screenX, left in cells
        mov     [bp+spanLeft],ax
        mov     ax,es:[di+imgWidth]     ; rowBytes = the tile width in bytes
        shl     ax,1
        shl     ax,1
        mov     [bp+rowBytes],ax
        mov     ax,es:[di+imgHeight]    ; rowCount = the tile's scanlines
        mov     [bp+rowCount],ax
        mov     ax,es:[di+imgTransp]    ; maskPtr = the tile set's mask
        mov     [bp+maskPtr],ax
        mov     ax,es:[di+imgTransp+2]
        mov     [bp+maskPtr+2],ax
        shl     word ptr [bp+leftBytes],1 ; leftBytes and destSkip to bytes
        shl     word ptr [bp+leftBytes],1
        shl     word ptr [bp+destSkip],1
        shl     word ptr [bp+destSkip],1
        mov     ax,es:[di+imgFrameSize] ; srcOff = frameSize * tileIdx
        xor     bx,bx
        mov     bl,[bp+cellTile]
        mul     bx
        mov     [bp+srcOff],ax
        shl     word ptr [bp+destOff],1 ; destOff to bytes
        shl     word ptr [bp+destOff],1
        mov     bx,[bp+viewRow]         ; bx = the first scanline, cx = the rows
        mov     cx,[bp+rowCount]
        mov     byte ptr [bp+saveFlag],0 ; nothing to save, nothing clipped
        mov     word ptr [bp+skipLeft],0
        mov     word ptr [bp+skipRight],0
        call    MaskRows                ; draw the rows through the mask
        pop     ds                      ; restore DS and SS, drop the frame
        pop     ss
        mov     sp,bp
        pop     bp
        ret     0Eh                     ; pops the arguments
BlitCellEgaMasked ENDP

BlitClippedEga PROC NEAR
        push    bp                      ; frame for the arguments and locals
        mov     bp,sp
        sub     sp,1Ch                  ; the frame, reserved twice
        sub     sp,1Ch
        push    ss                      ; SS and DS are restored before the return
        push    ds
        cld                             ; CopyRows' movsb walks upwards
        push    ds                      ; the caller's DS, kept past the lds below
        lds     si,[bp+argGfx]          ; DS:SI = the tile set
        les     di,[bp+argDest]         ; ES:DI = dest
        mov     ax,[si+imgTransp]       ; maskPtr = the tile set's mask
        mov     [bp+maskPtr],ax
        mov     ax,[si+imgTransp+2]
        mov     [bp+maskPtr+2],ax
        mov     ax,[bp+clipX]
        cmp     ax,8000h                ; a negative x?
        jbe     @@xOnScreen
        mov     [bp+skipLeft],ax        ; skipLeft = -x, the tile cells left of the edge
        neg     word ptr [bp+skipLeft]
        mov     word ptr [bp+leftBytes],0 ; drawn from dest's left edge
        jmp     @@checkRight
@@xOnScreen:
        mov     word ptr [bp+skipLeft],0 ; nothing clipped on the left
        mov     [bp+leftBytes],ax       ; leftBytes = x, in cells for now
@@checkRight:
        add     ax,[si+imgWidth]        ; does dest's width reach the tile's right end?
        cmp     es:[di+imgWidth],ax
        jae     @@rightFits
        sub     ax,es:[di+imgWidth]     ; skipRight = the tile cells past the right edge
        mov     [bp+skipRight],ax
        mov     word ptr [bp+destSkip],0 ; nothing of dest right of the tile
        jmp     @@clipTop
@@rightFits:
        mov     word ptr [bp+skipRight],0 ; nothing clipped on the right
        mov     ax,es:[di+imgWidth]     ; destSkip = dest width - x - tile width
        sub     ax,[bp+clipX]
        sub     ax,[si+imgWidth]
        mov     [bp+destSkip],ax
@@clipTop:
        mov     ax,[bp+clipY]
        cmp     ax,8000h                ; a negative y?
        jbe     @@yOnScreen
        neg     ax                      ; ax = the scanlines above the top edge
        mov     cx,3
        shl     ax,cl
        mov     bx,[si+imgHeight]       ; rowCount = the tile's rows below the edge
        mov     [bp+rowCount],bx
        sub     [bp+rowCount],ax
        mov     bx,[si+imgWidth]        ; srcOff = the hidden rows' cells
        mul     bx
        mov     [bp+srcOff],ax
        mov     word ptr [bp+destOff],0 ; drawn from dest's top scanline
        mov     word ptr [bp+viewRow],0
        jmp     @@checkEmpty
@@yOnScreen:
        mov     word ptr [bp+srcOff],0  ; nothing clipped at the top
        mov     cx,3                    ; viewRow = y * 8
        shl     ax,cl
        mov     [bp+viewRow],ax
        mov     bx,es:[di+imgWidth]     ; destOff = viewRow * dest width, in cells
        mul     bx
        mov     [bp+destOff],ax
        mov     ax,[bp+viewRow]         ; does the tile end above dest's bottom?
        add     ax,[si+imgHeight]
        cmp     ax,es:[di+imgHeight]
        jbe     @@bottomFits
        mov     ax,es:[di+imgHeight]    ; rowCount = the rows above dest's bottom
        sub     ax,[bp+viewRow]
        mov     [bp+rowCount],ax
        jmp     @@checkEmpty
@@bottomFits:
        mov     ax,[si+imgHeight]       ; rowCount = all the tile's rows
        mov     [bp+rowCount],ax
@@checkEmpty:
        mov     ax,[si+imgWidth]        ; clipped off the left or right entirely?
        cmp     ax,[bp+skipLeft]
        jb      @@offView
        cmp     ax,[bp+skipRight]
        jb      @@offView
        mov     ax,[bp+srcOff]          ; clipped off the top entirely?
        cmp     ax,[si+imgFrameSize]
        ja      @@offView
        mov     ax,[bp+destOff]         ; starting below dest's last byte?
        cmp     ax,es:[di+imgFrameSize]
        ja      @@offView
        mov     ax,[bp+rowCount]        ; a negative rowCount, read unsigned?
        cmp     ax,[si+imgHeight]
        ja      @@offView
        jmp     @@draw
@@offView:
        pop     ds                      ; the caller's DS again
        pop     ds                      ; restore DS and SS, drop the frame
        pop     ss
        mov     sp,bp
        pop     bp
        ret     14h                     ; pops the arguments
@@draw:
        mov     ax,[bp+leftBytes]       ; spanLeft = x, left in cells
        mov     [bp+spanLeft],ax
        mov     ax,[bp+leftBytes]       ; leftBytes to bytes
        shl     ax,1
        shl     ax,1
        mov     [bp+leftBytes],ax
        mov     ax,[si+imgWidth]        ; rowBytes = the visible cells, in bytes
        sub     ax,[bp+skipLeft]
        sub     ax,[bp+skipRight]
        shl     ax,1
        shl     ax,1
        mov     [bp+rowBytes],ax
        shl     word ptr [bp+skipLeft],1 ; the remaining cell counts to bytes
        shl     word ptr [bp+skipLeft],1
        shl     word ptr [bp+skipRight],1
        shl     word ptr [bp+skipRight],1
        shl     word ptr [bp+destSkip],1
        shl     word ptr [bp+destSkip],1
        shl     word ptr [bp+srcOff],1
        shl     word ptr [bp+srcOff],1
        shl     word ptr [bp+destOff],1
        shl     word ptr [bp+destOff],1
        mov     ax,[bp+srcOff]          ; saveOff = the first covered byte, in the save picture
        mov     [bp+saveOff],ax
        mov     ax,[si+imgFrameSize]    ; srcOff += frameSize * tileIdx
        xor     bx,bx
        mov     bl,[bp+clipTile]
        mul     bx
        add     [bp+srcOff],ax
        mov     bx,[bp+viewRow]         ; bx = the first scanline, cx = the rows
        mov     cx,[bp+rowCount]
        mov     byte ptr [bp+saveFlag],0 ; no save unless the masked path asks
        pop     ds                      ; DS = the data segment again, for the dirty-row tables
        test    byte ptr [bp+clipMode],1 ; bit 0: masked
        jne     @@masked
        call    CopyRows                ; unmasked: copy the rows
        pop     ds                      ; restore DS and SS, drop the frame
        pop     ss
        mov     sp,bp
        pop     bp
        ret     14h                     ; pops the arguments
@@masked:
        mov     byte ptr [bp+saveFlag],0
        test    byte ptr [bp+clipMode],4 ; bit 2: save what is covered first
        je      @@noSave
        mov     byte ptr [bp+saveFlag],1
@@noSave:
        call    MaskRows                ; draw the rows through the mask
        pop     ds                      ; restore DS and SS, drop the frame
        pop     ss
        mov     sp,bp
        pop     bp
        ret     14h                     ; pops the arguments
BlitClippedEga ENDP

BlitCellTandy PROC NEAR
        push    bp                      ; frame for the arguments and locals
        mov     bp,sp
        sub     sp,1Ch                  ; the frame, reserved twice
        sub     sp,1Ch
        push    ss                      ; SS and DS are restored before the return
        push    ds
        cld                             ; CopyRows' movsb walks upwards
        les     di,[bp+argDest]         ; ES:DI = dest
        mov     ax,[bp+cellY]           ; viewRow = screenY * 8
        mov     cl,3
        shl     ax,cl
        mov     [bp+viewRow],ax
        mov     bx,es:[di+imgWidth]     ; destOff = viewRow * dest width, in cells
        mul     bx
        mov     [bp+destOff],ax
        mov     ax,[bp+cellX]           ; leftBytes = screenX, in cells for now
        mov     [bp+leftBytes],ax
        mov     ax,es:[di+imgWidth]     ; ax = dest width
        les     di,[bp+argGfx]          ; ES:DI = the tile set
        sub     ax,es:[di+imgWidth]     ; destSkip = dest width - tile width - screenX
        sub     ax,[bp+cellX]
        mov     [bp+destSkip],ax
        mov     ax,[bp+leftBytes]       ; spanLeft = leftBytes, to bytes (4 a cell)
        mov     [bp+spanLeft],ax
        shl     word ptr [bp+spanLeft],1
        shl     word ptr [bp+spanLeft],1
        mov     ax,es:[di+imgWidth]     ; rowBytes = the tile width in bytes
        shl     ax,1
        shl     ax,1
        mov     [bp+rowBytes],ax
        mov     ax,es:[di+imgHeight]    ; rowCount = the tile's scanlines
        mov     [bp+rowCount],ax
        shl     word ptr [bp+leftBytes],1 ; leftBytes and destSkip to bytes
        shl     word ptr [bp+leftBytes],1
        shl     word ptr [bp+destSkip],1
        shl     word ptr [bp+destSkip],1
        mov     ax,es:[di+imgFrameSize] ; srcOff = frameSize * tileIdx
        xor     bx,bx
        mov     bl,[bp+cellTile]
        mul     bx
        mov     [bp+srcOff],ax
        shl     word ptr [bp+destOff],1 ; destOff to bytes
        shl     word ptr [bp+destOff],1
        mov     bx,[bp+viewRow]         ; bx = the first scanline, cx = the rows
        mov     cx,[bp+rowCount]
        mov     byte ptr [bp+saveFlag],0 ; nothing to save, nothing clipped
        mov     word ptr [bp+skipLeft],0
        mov     word ptr [bp+skipRight],0
        call    CopyRows                ; copy the rows
        pop     ds                      ; restore DS and SS, drop the frame
        pop     ss
        mov     sp,bp
        pop     bp
        ret     0Eh                     ; pops the arguments
BlitCellTandy ENDP

BlitCellTandyMasked PROC NEAR
        push    bp                      ; frame for the arguments and locals
        mov     bp,sp
        sub     sp,1Ch                  ; the frame, reserved twice
        sub     sp,1Ch
        push    ss                      ; SS and DS are restored before the return
        push    ds
        les     di,[bp+argDest]         ; ES:DI = dest
        mov     ax,[bp+cellY]           ; viewRow = screenY * 8
        mov     cl,3
        shl     ax,cl
        mov     [bp+viewRow],ax
        mov     bx,es:[di+imgWidth]     ; destOff = viewRow * dest width, in cells
        mul     bx
        mov     [bp+destOff],ax
        mov     ax,[bp+cellX]           ; leftBytes = screenX, in cells for now
        mov     [bp+leftBytes],ax
        mov     ax,es:[di+imgWidth]     ; ax = dest width
        les     di,[bp+argGfx]          ; ES:DI = the tile set
        sub     ax,es:[di+imgWidth]     ; destSkip = dest width - tile width - screenX
        sub     ax,[bp+cellX]
        mov     [bp+destSkip],ax
        mov     ax,[bp+leftBytes]       ; spanLeft = leftBytes, to bytes
        mov     [bp+spanLeft],ax
        shl     word ptr [bp+spanLeft],1
        shl     word ptr [bp+spanLeft],1
        mov     ax,es:[di+imgWidth]     ; rowBytes = the tile width in bytes
        shl     ax,1
        shl     ax,1
        mov     [bp+rowBytes],ax
        mov     ax,es:[di+imgHeight]    ; rowCount = the tile's scanlines
        mov     [bp+rowCount],ax
        mov     ax,es:[di+imgTransp]    ; maskPtr = the tile set's mask
        mov     [bp+maskPtr],ax
        mov     ax,es:[di+imgTransp+2]
        mov     [bp+maskPtr+2],ax
        shl     word ptr [bp+leftBytes],1 ; leftBytes and destSkip to bytes
        shl     word ptr [bp+leftBytes],1
        shl     word ptr [bp+destSkip],1
        shl     word ptr [bp+destSkip],1
        mov     ax,es:[di+imgFrameSize] ; srcOff = frameSize * tileIdx
        xor     bx,bx
        mov     bl,[bp+cellTile]
        mul     bx
        mov     [bp+srcOff],ax
        shl     word ptr [bp+destOff],1 ; destOff to bytes
        shl     word ptr [bp+destOff],1
        mov     bx,[bp+viewRow]         ; bx = the first scanline, cx = the rows
        mov     cx,[bp+rowCount]
        mov     byte ptr [bp+saveFlag],0 ; nothing to save, nothing clipped
        mov     word ptr [bp+skipLeft],0
        mov     word ptr [bp+skipRight],0
        call    MaskRows                ; draw the rows through the mask
        pop     ds                      ; restore DS and SS, drop the frame
        pop     ss
        mov     sp,bp
        pop     bp
        ret     0Eh                     ; pops the arguments
BlitCellTandyMasked ENDP

BlitClippedTandy PROC NEAR
        push    bp                      ; frame for the arguments and locals
        mov     bp,sp
        sub     sp,1Ch                  ; the frame, reserved twice
        sub     sp,1Ch
        push    ss                      ; SS and DS are restored before the return
        push    ds
        cld                             ; CopyRows' movsb walks upwards
        push    ds                      ; the caller's DS, kept past the lds below
        lds     si,[bp+argGfx]          ; DS:SI = the tile set
        les     di,[bp+argDest]         ; ES:DI = dest
        mov     ax,[si+imgTransp]       ; maskPtr = the tile set's mask
        mov     [bp+maskPtr],ax
        mov     ax,[si+imgTransp+2]
        mov     [bp+maskPtr+2],ax
        mov     ax,[bp+clipX]
        cmp     ax,8000h                ; a negative x?
        jbe     @@xOnScreen
        mov     [bp+skipLeft],ax        ; skipLeft = -x, the tile cells left of the edge
        neg     word ptr [bp+skipLeft]
        mov     word ptr [bp+leftBytes],0 ; drawn from dest's left edge
        jmp     @@checkRight
@@xOnScreen:
        mov     word ptr [bp+skipLeft],0 ; nothing clipped on the left
        mov     [bp+leftBytes],ax       ; leftBytes = x, in cells for now
@@checkRight:
        add     ax,[si+imgWidth]        ; does dest's width reach the tile's right end?
        cmp     es:[di+imgWidth],ax
        jae     @@rightFits
        sub     ax,es:[di+imgWidth]     ; skipRight = the tile cells past the right edge
        mov     [bp+skipRight],ax
        mov     word ptr [bp+destSkip],0 ; nothing of dest right of the tile
        jmp     @@clipTop
@@rightFits:
        mov     word ptr [bp+skipRight],0 ; nothing clipped on the right
        mov     ax,es:[di+imgWidth]     ; destSkip = dest width - x - tile width
        sub     ax,[bp+clipX]
        sub     ax,[si+imgWidth]
        mov     [bp+destSkip],ax
@@clipTop:
        mov     ax,[bp+clipY]
        cmp     ax,8000h                ; a negative y?
        jbe     @@yOnScreen
        neg     ax                      ; ax = the scanlines above the top edge
        mov     cx,3
        shl     ax,cl
        mov     bx,[si+imgHeight]       ; rowCount = the tile's rows below the edge
        mov     [bp+rowCount],bx
        sub     [bp+rowCount],ax
        mov     bx,[si+imgWidth]        ; srcOff = the hidden rows' cells
        mul     bx
        mov     [bp+srcOff],ax
        mov     word ptr [bp+destOff],0 ; drawn from dest's top scanline
        mov     word ptr [bp+viewRow],0
        jmp     @@checkEmpty
@@yOnScreen:
        mov     word ptr [bp+srcOff],0  ; nothing clipped at the top
        mov     cx,3                    ; viewRow = y * 8
        shl     ax,cl
        mov     [bp+viewRow],ax
        mov     bx,es:[di+imgWidth]     ; destOff = viewRow * dest width, in cells
        mul     bx
        mov     [bp+destOff],ax
        mov     ax,[bp+viewRow]         ; does the tile end above dest's bottom?
        add     ax,[si+imgHeight]
        cmp     ax,es:[di+imgHeight]
        jbe     @@bottomFits
        mov     ax,es:[di+imgHeight]    ; rowCount = the rows above dest's bottom
        sub     ax,[bp+viewRow]
        mov     [bp+rowCount],ax
        jmp     @@checkEmpty
@@bottomFits:
        mov     ax,[si+imgHeight]       ; rowCount = all the tile's rows
        mov     [bp+rowCount],ax
@@checkEmpty:
        mov     ax,[si+imgWidth]        ; clipped off the left or right entirely?
        cmp     ax,[bp+skipLeft]
        jb      @@offView
        cmp     ax,[bp+skipRight]
        jb      @@offView
        mov     ax,[bp+srcOff]          ; clipped off the top entirely?
        cmp     ax,[si+imgFrameSize]
        ja      @@offView
        mov     ax,[bp+destOff]         ; starting below dest's last byte?
        cmp     ax,es:[di+imgFrameSize]
        ja      @@offView
        mov     ax,[bp+rowCount]        ; a negative rowCount, read unsigned?
        cmp     ax,[si+imgHeight]
        ja      @@offView
        jmp     @@draw
@@offView:
        pop     ds                      ; the caller's DS again
        pop     ds                      ; restore DS and SS, drop the frame
        pop     ss
        mov     sp,bp
        pop     bp
        ret     14h                     ; pops the arguments
@@draw:
        mov     ax,[bp+leftBytes]       ; leftBytes to bytes, and spanLeft with it
        shl     ax,1
        shl     ax,1
        mov     [bp+leftBytes],ax
        mov     [bp+spanLeft],ax
        mov     ax,[si+imgWidth]        ; rowBytes = the visible cells, in bytes
        sub     ax,[bp+skipLeft]
        sub     ax,[bp+skipRight]
        shl     ax,1
        shl     ax,1
        mov     [bp+rowBytes],ax
        shl     word ptr [bp+skipLeft],1 ; the remaining cell counts to bytes
        shl     word ptr [bp+skipLeft],1
        shl     word ptr [bp+skipRight],1
        shl     word ptr [bp+skipRight],1
        shl     word ptr [bp+destSkip],1
        shl     word ptr [bp+destSkip],1
        shl     word ptr [bp+srcOff],1
        shl     word ptr [bp+srcOff],1
        shl     word ptr [bp+destOff],1
        shl     word ptr [bp+destOff],1
        mov     ax,[bp+srcOff]          ; saveOff = the first covered byte, in the save picture
        mov     [bp+saveOff],ax
        mov     ax,[si+imgFrameSize]    ; srcOff += frameSize * tileIdx
        xor     bx,bx
        mov     bl,[bp+clipTile]
        mul     bx
        add     [bp+srcOff],ax
        mov     bx,[bp+viewRow]         ; bx = the first scanline, cx = the rows
        mov     cx,[bp+rowCount]
        mov     byte ptr [bp+saveFlag],0 ; no save unless the masked path asks
        pop     ds                      ; DS = the data segment again, for the dirty-row tables
        test    byte ptr [bp+clipMode],1 ; bit 0: masked
        jne     @@masked
        call    CopyRows                ; unmasked: copy the rows
        pop     ds                      ; restore DS and SS, drop the frame
        pop     ss
        mov     sp,bp
        pop     bp
        ret     14h                     ; pops the arguments
@@masked:
        mov     byte ptr [bp+saveFlag],0
        test    byte ptr [bp+clipMode],4 ; bit 2: save what is covered first
        je      @@noSave
        mov     byte ptr [bp+saveFlag],1
@@noSave:
        call    MaskRows                ; draw the rows through the mask
        pop     ds                      ; restore DS and SS, drop the frame
        pop     ss
        mov     sp,bp
        pop     bp
        ret     14h                     ; pops the arguments
BlitClippedTandy ENDP

; The scanline loops, entered from a blitter's frame with bx = viewRow, cx = rowCount and DS = the data segment.  Each
; marks its row dirty and widens the row's dirty range for FlushView.  CopyRows copies; MaskRows ANDs the mask in and
; ORs the tile over it.  Note: CopyRows never adds skipLeft or skipRight to srcOff, so a tile clipped at a side and
; drawn unmasked is read at the clipped width's stride; MaskRows adds both.  On an equal offset CopyRows rewrites the
; row's first and last entries and MaskRows leaves them (ja/jb against jae/jbe), so only CopyRows then rewrites
; dirtyRowLeft.

CopyRows PROC NEAR
        mov     byte ptr [bx+dirtyRows],1 ; mark scanline bx dirty
        shl     bx,1                    ; bx indexes the Word tables
        mov     ax,[bp+leftBytes]       ; destOff += leftBytes: the row's first byte
        add     [bp+destOff],ax
        mov     ax,[bp+destOff]
        cmp     ax,[bx+dirtyRowFirst]
        ja      @@spanKnown             ; a new first byte when at or below the one recorded
        mov     [bx+dirtyRowFirst],ax
        mov     ax,[bp+spanLeft]
        mov     [bx+dirtyRowLeft],ax    ; the span's left screen byte with it
@@spanKnown:
        push    ds                      ; keep the data segment past the lds
        lds     si,[bp+argGfx]          ; DS:SI = the tile's row
        les     di,[bp+argDest]         ; ES:DI = dest's row
        add     si,imgData
        add     si,[bp+srcOff]
        add     di,imgData
        add     di,[bp+destOff]
        push    cx                      ; keep the row count
        mov     cx,[bp+rowBytes]
        rep movsb                       ; copy the row
        pop     cx
        pop     ds                      ; DS = the data segment again
        mov     ax,[bp+rowBytes]        ; advance both offsets past the row
        add     [bp+srcOff],ax
        add     [bp+destOff],ax
        mov     ax,[bp+destOff]         ; ax = the row's last byte
        dec     ax
        cmp     ax,[bx+dirtyRowLast]
        jb      @@endKnown              ; a new last byte when at or above the one recorded
        mov     [bx+dirtyRowLast],ax
@@endKnown:
        mov     ax,[bp+destSkip]
        add     [bp+destOff],ax         ; skip dest's bytes right of the tile
        shr     bx,1                    ; bx = the next scanline
        inc     bx
        loop    CopyRows                ; next scanline
        ret
CopyRows ENDP

MaskRows PROC NEAR
        mov     byte ptr [bx+dirtyRows],1 ; mark scanline bx dirty
        shl     bx,1                    ; bx indexes the Word tables
        mov     ax,[bp+skipLeft]        ; skip the tile's bytes left of the edge
        add     [bp+srcOff],ax
        mov     ax,[bp+leftBytes]       ; destOff += leftBytes: the row's first byte
        add     [bp+destOff],ax
        mov     ax,[bp+destOff]
        cmp     ax,[bx+dirtyRowFirst]
        jae     @@spanKnown             ; a new first byte only when below the one recorded
        mov     [bx+dirtyRowFirst],ax
        mov     ax,[bp+spanLeft]
        mov     [bx+dirtyRowLeft],ax    ; the span's left screen byte with it
@@spanKnown:
        push    ds                      ; keep the data segment past the lds's below
        les     di,[bp+argDest]         ; ES:DI = dest's row, less the header
        add     di,[bp+destOff]
        push    cx                      ; keep the row count
        mov     cx,[bp+rowBytes]        ; cx = the row's bytes
@@pixel:
        cmp     byte ptr [bp+saveFlag],0
        je      @@noSave
        lds     si,[bp+argSave]         ; saveFlag: copy the covered byte to the save-under buffer first
        add     si,[bp+saveOff]
        mov     al,es:[di+imgData]
        mov     [si+imgData],al
@@noSave:
        lds     si,[bp+maskPtr]
        add     si,[bp+srcOff]
        mov     ah,[si]                 ; the mask byte
        lds     si,[bp+argGfx]
        add     si,[bp+srcOff]
        mov     al,[si+imgData]         ; the tile byte
        and     es:[di+imgData],ah      ; clear what the tile covers
        or      es:[di+imgData],al      ; and draw it
        inc     word ptr [bp+srcOff]    ; advance every offset a byte
        inc     word ptr [bp+saveOff]
        inc     word ptr [bp+destOff]
        inc     di
        loop    @@pixel
        pop     cx                      ; the row count
        pop     ds                      ; DS = the data segment again
        mov     ax,[bp+destOff]         ; ax = the row's last byte
        dec     ax
        cmp     ax,[bx+dirtyRowLast]
        jbe     @@endKnown              ; a new last byte only when above the one recorded
        mov     [bx+dirtyRowLast],ax
@@endKnown:
        mov     ax,[bp+destSkip]        ; skip dest's bytes right of the tile
        add     [bp+destOff],ax
        mov     ax,[bp+skipRight]       ; skip the tile's bytes past the right edge
        add     [bp+srcOff],ax
        add     [bp+saveOff],ax
        shr     bx,1                    ; bx = the next scanline
        inc     bx
        dec     cx
        je      @@done
        jmp     MaskRows                ; next scanline (dec/je/jmp: loop cannot reach)
@@done:
        ret
MaskRows ENDP

BlitCellVga PROC NEAR
        push    bp                      ; frame for the arguments and locals
        mov     bp,sp
        sub     sp,1Ch                  ; the frame, reserved twice
        sub     sp,1Ch
        push    ss                      ; SS and DS are restored before the return
        push    ds
        cld                             ; CopyRowsVga's movsb walks upwards
        les     di,[bp+argDest]         ; ES:DI = dest
        mov     ax,[bp+cellY]           ; viewRow = screenY * 8
        mov     cl,3
        shl     ax,cl
        mov     [bp+viewRow],ax
        mov     bx,es:[di+imgWidth]     ; destOff = viewRow * dest width, in cells
        mul     bx
        mov     [bp+destOff],ax
        mov     ax,[bp+cellX]           ; leftBytes = screenX, in cells for now
        mov     [bp+leftBytes],ax
        mov     ax,es:[di+imgWidth]     ; ax = dest width
        les     di,[bp+argGfx]          ; ES:DI = the tile set
        sub     ax,es:[di+imgWidth]     ; destSkip = dest width - tile width - screenX
        sub     ax,[bp+cellX]
        mov     [bp+destSkip],ax
        mov     ax,[bp+leftBytes]       ; spanLeft = leftBytes, to bytes (8 a cell)
        mov     [bp+spanLeft],ax
        shl     word ptr [bp+spanLeft],1
        shl     word ptr [bp+spanLeft],1
        shl     word ptr [bp+spanLeft],1
        mov     ax,es:[di+imgWidth]     ; rowBytes = the tile width in bytes
        shl     ax,1
        shl     ax,1
        shl     ax,1
        mov     [bp+rowBytes],ax
        mov     ax,es:[di+imgHeight]    ; rowCount = the tile's scanlines
        mov     [bp+rowCount],ax
        shl     word ptr [bp+leftBytes],1 ; leftBytes and destSkip to bytes
        shl     word ptr [bp+leftBytes],1
        shl     word ptr [bp+leftBytes],1
        shl     word ptr [bp+destSkip],1
        shl     word ptr [bp+destSkip],1
        shl     word ptr [bp+destSkip],1
        mov     ax,es:[di+imgFrameSize] ; srcOff = frameSize * tileIdx
        xor     bx,bx
        mov     bl,[bp+cellTile]
        mul     bx
        mov     [bp+srcOff],ax
        shl     word ptr [bp+destOff],1 ; destOff to bytes
        shl     word ptr [bp+destOff],1
        shl     word ptr [bp+destOff],1
        mov     bx,[bp+viewRow]         ; bx = the first scanline, cx = the rows
        mov     cx,[bp+rowCount]
        mov     byte ptr [bp+saveFlag],0 ; nothing to save, nothing clipped
        mov     word ptr [bp+skipLeft],0
        mov     word ptr [bp+skipRight],0
        call    CopyRowsVga             ; copy the rows
        pop     ds                      ; restore DS and SS, drop the frame
        pop     ss
        mov     sp,bp
        pop     bp
        ret     0Eh                     ; pops the arguments
BlitCellVga ENDP

; BlitCellVgaKeyed and BlitClippedVga take the transparent color as one more argument and draw through KeyRows, in a
; frame with room for keyColor.  Both still copy gfx^.transp into maskPtr, which KeyRows never reads.
BlitCellVgaKeyed PROC NEAR
        push    bp                      ; frame for the arguments and locals
        mov     bp,sp
        sub     sp,1Eh                  ; the larger frame, reserved twice
        sub     sp,1Eh
        push    ss                      ; SS and DS are restored before the return
        push    ds
        les     di,[bp+argDest]         ; ES:DI = dest
        mov     ah,[bp+keyCellKey]      ; keyColor = transpColor, for KeyRows
        mov     [bp+keyColor],ah
        mov     ax,[bp+keyCellY]        ; viewRow = screenY * 8
        mov     cl,3
        shl     ax,cl
        mov     [bp+viewRow],ax
        mov     bx,es:[di+imgWidth]     ; destOff = viewRow * dest width, in cells
        mul     bx
        mov     [bp+destOff],ax
        mov     ax,[bp+keyCellX]        ; leftBytes = screenX, in cells for now
        mov     [bp+leftBytes],ax
        mov     ax,es:[di+imgWidth]     ; ax = dest width
        les     di,[bp+argGfx]          ; ES:DI = the tile set
        sub     ax,es:[di+imgWidth]     ; destSkip = dest width - tile width - screenX
        sub     ax,[bp+keyCellX]
        mov     [bp+destSkip],ax
        mov     ax,[bp+leftBytes]       ; spanLeft = leftBytes, to bytes
        mov     [bp+spanLeft],ax
        shl     word ptr [bp+spanLeft],1
        shl     word ptr [bp+spanLeft],1
        shl     word ptr [bp+spanLeft],1
        mov     ax,es:[di+imgWidth]     ; rowBytes = the tile width in bytes
        shl     ax,1
        shl     ax,1
        shl     ax,1
        mov     [bp+rowBytes],ax
        mov     ax,es:[di+imgHeight]    ; rowCount = the tile's scanlines
        mov     [bp+rowCount],ax
        mov     ax,es:[di+imgTransp]    ; maskPtr = gfx^.transp, unread
        mov     [bp+maskPtr],ax
        mov     ax,es:[di+imgTransp+2]
        mov     [bp+maskPtr+2],ax
        shl     word ptr [bp+leftBytes],1 ; leftBytes and destSkip to bytes
        shl     word ptr [bp+leftBytes],1
        shl     word ptr [bp+leftBytes],1
        shl     word ptr [bp+destSkip],1
        shl     word ptr [bp+destSkip],1
        shl     word ptr [bp+destSkip],1
        mov     ax,es:[di+imgFrameSize] ; srcOff = frameSize * tileIdx
        xor     bx,bx
        mov     bl,[bp+cellTile]
        mul     bx
        mov     [bp+srcOff],ax
        shl     word ptr [bp+destOff],1 ; destOff to bytes
        shl     word ptr [bp+destOff],1
        shl     word ptr [bp+destOff],1
        mov     bx,[bp+viewRow]         ; bx = the first scanline, cx = the rows
        mov     cx,[bp+rowCount]
        mov     byte ptr [bp+saveFlag],0 ; nothing to save, nothing clipped
        mov     word ptr [bp+skipLeft],0
        mov     word ptr [bp+skipRight],0
        call    KeyRows                 ; draw the rows, skipping the key color
        pop     ds                      ; restore DS and SS, drop the frame
        pop     ss
        mov     sp,bp
        pop     bp
        ret     10h                     ; pops the arguments
BlitCellVgaKeyed ENDP

BlitClippedVga PROC NEAR
        push    bp                      ; frame for the arguments and locals
        mov     bp,sp
        sub     sp,1Eh                  ; the larger frame, reserved twice
        sub     sp,1Eh
        push    ss                      ; SS and DS are restored before the return
        push    ds
        cld                             ; CopyRowsVga's movsb walks upwards
        push    ds                      ; the caller's DS, kept past the lds below
        lds     si,[bp+argGfx]          ; DS:SI = the tile set
        les     di,[bp+argDest]         ; ES:DI = dest
        mov     ax,[si+imgTransp]       ; maskPtr = gfx^.transp, unread
        mov     [bp+maskPtr],ax
        mov     ax,[si+imgTransp+2]
        mov     [bp+maskPtr+2],ax
        mov     ah,[bp+keyClipKey]      ; keyColor = transpColor, for KeyRows
        mov     [bp+keyColor],ah
        mov     ax,[bp+keyClipX]
        cmp     ax,8000h                ; a negative x?
        jbe     @@xOnScreen
        mov     [bp+skipLeft],ax        ; skipLeft = -x, the tile cells left of the edge
        neg     word ptr [bp+skipLeft]
        mov     word ptr [bp+leftBytes],0 ; drawn from dest's left edge
        jmp     @@checkRight
@@xOnScreen:
        mov     word ptr [bp+skipLeft],0 ; nothing clipped on the left
        mov     [bp+leftBytes],ax       ; leftBytes = x, in cells for now
@@checkRight:
        add     ax,[si+imgWidth]        ; does dest's width reach the tile's right end?
        cmp     es:[di+imgWidth],ax
        jae     @@rightFits
        sub     ax,es:[di+imgWidth]     ; skipRight = the tile cells past the right edge
        mov     [bp+skipRight],ax
        mov     word ptr [bp+destSkip],0 ; nothing of dest right of the tile
        jmp     @@clipTop
@@rightFits:
        mov     word ptr [bp+skipRight],0 ; nothing clipped on the right
        mov     ax,es:[di+imgWidth]     ; destSkip = dest width - x - tile width
        sub     ax,[bp+keyClipX]
        sub     ax,[si+imgWidth]
        mov     [bp+destSkip],ax
@@clipTop:
        mov     ax,[bp+keyClipY]
        cmp     ax,8000h                ; a negative y?
        jbe     @@yOnScreen
        neg     ax                      ; ax = the scanlines above the top edge
        mov     cx,3
        shl     ax,cl
        mov     bx,[si+imgHeight]       ; rowCount = the tile's rows below the edge
        mov     [bp+rowCount],bx
        sub     [bp+rowCount],ax
        mov     bx,[si+imgWidth]        ; srcOff = the hidden rows' cells
        mul     bx
        mov     [bp+srcOff],ax
        mov     word ptr [bp+destOff],0 ; drawn from dest's top scanline
        mov     word ptr [bp+viewRow],0
        jmp     @@checkEmpty
@@yOnScreen:
        mov     word ptr [bp+srcOff],0  ; nothing clipped at the top
        mov     cx,3                    ; viewRow = y * 8
        shl     ax,cl
        mov     [bp+viewRow],ax
        mov     bx,es:[di+imgWidth]     ; destOff = viewRow * dest width, in cells
        mul     bx
        mov     [bp+destOff],ax
        mov     ax,[bp+viewRow]         ; does the tile end above dest's bottom?
        add     ax,[si+imgHeight]
        cmp     ax,es:[di+imgHeight]
        jbe     @@bottomFits
        mov     ax,es:[di+imgHeight]    ; rowCount = the rows above dest's bottom
        sub     ax,[bp+viewRow]
        mov     [bp+rowCount],ax
        jmp     @@checkEmpty
@@bottomFits:
        mov     ax,[si+imgHeight]       ; rowCount = all the tile's rows
        mov     [bp+rowCount],ax
@@checkEmpty:
        mov     ax,[si+imgWidth]        ; clipped off the left or right entirely?
        cmp     ax,[bp+skipLeft]
        jb      @@offView
        cmp     ax,[bp+skipRight]
        jb      @@offView
        mov     ax,[bp+srcOff]          ; clipped off the top entirely?
        cmp     ax,[si+imgFrameSize]
        ja      @@offView
        mov     ax,[bp+destOff]         ; starting below dest's last byte?
        cmp     ax,es:[di+imgFrameSize]
        ja      @@offView
        mov     ax,[bp+rowCount]        ; a negative rowCount, read unsigned?
        cmp     ax,[si+imgHeight]
        ja      @@offView
        jmp     @@draw
@@offView:
        pop     ds                      ; the caller's DS again
        pop     ds                      ; restore DS and SS, drop the frame
        pop     ss
        mov     sp,bp
        pop     bp
        ret     16h                     ; pops the arguments
@@draw:
        mov     ax,[bp+leftBytes]       ; leftBytes to bytes, and spanLeft with it
        shl     ax,1
        shl     ax,1
        shl     ax,1
        mov     [bp+leftBytes],ax
        mov     [bp+spanLeft],ax
        mov     ax,[si+imgWidth]        ; rowBytes = the visible cells, in bytes
        sub     ax,[bp+skipLeft]
        sub     ax,[bp+skipRight]
        shl     ax,1
        shl     ax,1
        shl     ax,1
        mov     [bp+rowBytes],ax
        shl     word ptr [bp+skipLeft],1 ; the remaining cell counts to bytes
        shl     word ptr [bp+skipLeft],1
        shl     word ptr [bp+skipLeft],1
        shl     word ptr [bp+skipRight],1
        shl     word ptr [bp+skipRight],1
        shl     word ptr [bp+skipRight],1
        shl     word ptr [bp+destSkip],1
        shl     word ptr [bp+destSkip],1
        shl     word ptr [bp+destSkip],1
        shl     word ptr [bp+srcOff],1
        shl     word ptr [bp+srcOff],1
        shl     word ptr [bp+srcOff],1
        shl     word ptr [bp+destOff],1
        shl     word ptr [bp+destOff],1
        shl     word ptr [bp+destOff],1
        mov     ax,[bp+srcOff]          ; keySaveOff = the first covered byte, in the save picture
        mov     [bp+keySaveOff],ax
        mov     ax,[si+imgFrameSize]    ; srcOff += frameSize * tileIdx
        xor     bx,bx
        mov     bl,[bp+clipTile]
        mul     bx
        add     [bp+srcOff],ax
        mov     bx,[bp+viewRow]         ; bx = the first scanline, cx = the rows
        mov     cx,[bp+rowCount]
        mov     byte ptr [bp+saveFlag],0 ; no save unless the keyed path asks
        pop     ds                      ; DS = the data segment again, for the dirty-row tables
        test    byte ptr [bp+clipMode],1 ; bit 0: keyed
        jne     @@keyed
        call    CopyRowsVga             ; unkeyed: copy the rows
        pop     ds                      ; restore DS and SS, drop the frame
        pop     ss
        mov     sp,bp
        pop     bp
        ret     16h                     ; pops the arguments
@@keyed:
        mov     byte ptr [bp+saveFlag],0
        test    byte ptr [bp+clipMode],4 ; bit 2: save what is covered first
        je      @@noSave
        mov     byte ptr [bp+saveFlag],1
@@noSave:
        call    KeyRows                 ; draw the rows, skipping the key color
        pop     ds                      ; restore DS and SS, drop the frame
        pop     ss
        mov     sp,bp
        pop     bp
        ret     16h                     ; pops the arguments
BlitClippedVga ENDP

; The VGA half's own row loops.  CopyRowsVga is CopyRows over again, instruction for instruction; KeyRows is MaskRows
; with the mask replaced by a test against keyColor and under and saveOff read from the VGA frame's slots.

CopyRowsVga PROC NEAR
        mov     byte ptr [bx+dirtyRows],1 ; mark scanline bx dirty
        shl     bx,1                    ; bx indexes the Word tables
        mov     ax,[bp+leftBytes]       ; destOff += leftBytes: the row's first byte
        add     [bp+destOff],ax
        mov     ax,[bp+destOff]
        cmp     ax,[bx+dirtyRowFirst]
        ja      @@spanKnown             ; a new first byte when at or below the one recorded
        mov     [bx+dirtyRowFirst],ax
        mov     ax,[bp+spanLeft]
        mov     [bx+dirtyRowLeft],ax    ; the span's left screen byte with it
@@spanKnown:
        push    ds                      ; keep the data segment past the lds
        lds     si,[bp+argGfx]          ; DS:SI = the tile's row
        les     di,[bp+argDest]         ; ES:DI = dest's row
        add     si,imgData
        add     si,[bp+srcOff]
        add     di,imgData
        add     di,[bp+destOff]
        push    cx                      ; keep the row count
        mov     cx,[bp+rowBytes]
        rep movsb                       ; copy the row
        pop     cx
        pop     ds                      ; DS = the data segment again
        mov     ax,[bp+rowBytes]        ; advance both offsets past the row
        add     [bp+srcOff],ax
        add     [bp+destOff],ax
        mov     ax,[bp+destOff]         ; ax = the row's last byte
        dec     ax
        cmp     ax,[bx+dirtyRowLast]
        jb      @@endKnown              ; a new last byte when at or above the one recorded
        mov     [bx+dirtyRowLast],ax
@@endKnown:
        mov     ax,[bp+destSkip]
        add     [bp+destOff],ax         ; skip dest's bytes right of the tile
        shr     bx,1                    ; bx = the next scanline
        inc     bx
        loop    CopyRowsVga             ; next scanline
        ret
CopyRowsVga ENDP

KeyRows PROC NEAR
        mov     byte ptr [bx+dirtyRows],1 ; mark scanline bx dirty
        shl     bx,1                    ; bx indexes the Word tables
        mov     ax,[bp+skipLeft]        ; skip the tile's bytes left of the edge
        add     [bp+srcOff],ax
        mov     ax,[bp+leftBytes]       ; destOff += leftBytes: the row's first byte
        add     [bp+destOff],ax
        mov     ax,[bp+destOff]
        cmp     ax,[bx+dirtyRowFirst]
        jae     @@spanKnown             ; a new first byte only when below the one recorded
        mov     [bx+dirtyRowFirst],ax
        mov     ax,[bp+spanLeft]
        mov     [bx+dirtyRowLeft],ax    ; the span's left screen byte with it
@@spanKnown:
        push    ds                      ; keep the data segment past the lds's below
        les     di,[bp+argDest]         ; ES:DI = dest's row, less the header
        add     di,[bp+destOff]
        push    cx                      ; keep the row count
        mov     cx,[bp+rowBytes]        ; cx = the row's bytes
@@pixel:
        cmp     byte ptr [bp+saveFlag],0
        je      @@noSave
        lds     si,[bp+keyClipSave]     ; saveFlag: copy the covered byte to under first
        add     si,[bp+keySaveOff]
        mov     al,es:[di+imgData]
        mov     [si+imgData],al
@@noSave:
        lds     si,[bp+argGfx]          ; al = the tile byte
        add     si,[bp+srcOff]
        mov     al,[si+imgData]
        cmp     al,[bp+keyColor]        ; the key color is transparent
        je      @@keyed
        mov     es:[di+imgData],al      ; any other color is drawn
@@keyed:
        inc     word ptr [bp+srcOff]    ; advance every offset a byte
        inc     word ptr [bp+keySaveOff]
        inc     word ptr [bp+destOff]
        inc     di
        loop    @@pixel
        pop     cx                      ; the row count
        pop     ds                      ; DS = the data segment again
        mov     ax,[bp+destOff]         ; ax = the row's last byte
        dec     ax
        cmp     ax,[bx+dirtyRowLast]
        jbe     @@endKnown              ; a new last byte only when above the one recorded
        mov     [bx+dirtyRowLast],ax
@@endKnown:
        mov     ax,[bp+destSkip]        ; skip dest's bytes right of the tile
        add     [bp+destOff],ax
        mov     ax,[bp+skipRight]       ; skip the tile's bytes past the right edge
        add     [bp+srcOff],ax
        add     [bp+keySaveOff],ax
        shr     bx,1                    ; bx = the next scanline
        inc     bx
        dec     cx
        je      @@done
        jmp     KeyRows                 ; next scanline (dec/je/jmp: loop cannot reach)
@@done:
        ret
KeyRows ENDP

; HlineEga and VlineEga -- Hline's and Vline's EGA arms (VmEga), drawn straight into display memory at A000:0.  Each
; puts its end points in order first.  Set/reset writes color into all four planes; the bit-mask register picks the
; pixels, and a read first loads the latches so the pixels it leaves out keep their color.  The byte written is
; irrelevant: set/reset supplies every plane.

HlineEga PROC NEAR
        push    bp                      ; frame for the arguments
        mov     bp,sp
        sub     sp,0                    ; no locals
        push    ss                      ; SS and DS are restored before the return
        push    ds
        mov     ax,[bp+hlX1]
        cmp     ax,[bp+hlX2]
        jle     @@ordered               ; put x1 before x2 (a signed test)
        xchg    [bp+hlX2],ax            ; swap them in the argument slots
        mov     [bp+hlX1],ax
@@ordered:
        mov     dx,GcIndex              ; graphics controller mode: write mode 0
        mov     al,GcMode
        out     dx,al
        inc     dx
        mov     al,0
        out     dx,al
        mov     dx,GcIndex              ; enable set/reset on all four planes
        mov     al,GcEnableSR
        out     dx,al
        inc     dx
        mov     al,0Fh
        out     dx,al
        mov     dx,GcIndex              ; set/reset color = color
        mov     al,GcSetReset
        out     dx,al
        inc     dx
        mov     al,[bp+lineColor]
        out     dx,al
        mov     dx,GcIndex              ; function: replace, no rotate
        mov     al,GcFunction
        out     dx,al
        inc     dx
        mov     al,0
        out     dx,al
        mov     dx,SeqIndex             ; sequencer map mask: write all four planes
        mov     al,SeqMapMask
        out     dx,al
        inc     dx
        mov     al,0Fh
        out     dx,al
        cld                             ; stosb walks rightwards
        mov     ax,VideoSeg             ; ES = display memory
        mov     es,ax
        mov     al,[bp+hlRow]           ; di = row * 40 + x1 / 8, x1's byte
        mov     bl,EgaRowBytes
        mul     bl
        mov     bx,[bp+hlX1]
        mov     cl,3
        shr     bx,cl
        add     ax,bx
        mov     di,ax
        mov     ax,[bp+hlX1]            ; x1 on a byte boundary: no left edge byte
        and     ax,7
        je      @@span
        mov     bx,0FFh                 ; bl = the left edge byte's pixels from x1 on
        mov     cl,al
        shr     bx,cl
        mov     dx,[bp+hlX1]            ; x1 = the next byte boundary
        and     dx,0FFF8h
        add     dx,8
        mov     [bp+hlX1],dx
        cmp     dx,[bp+hlX2]            ; does the line reach past this byte?
        jbe     @@leftMask
        mov     cx,dx                   ; a line inside one byte: drop the pixels past x2
        sub     cx,[bp+hlX2]
        dec     cx
        mov     ax,0FFh
        shl     ax,cl
        and     bl,al
@@leftMask:
        mov     dx,GcIndex              ; bit mask = the edge byte's pixels
        mov     al,GcBitMask
        out     dx,al
        inc     dx
        mov     al,bl
        out     dx,al
        mov     al,es:[di]              ; load the latches
        stosb                           ; write the edge byte, di to the next
@@span:
        mov     ax,[bp+hlX2]            ; ax = pixels from x1 to x2; none left: done
        sub     ax,[bp+hlX1]
        js      @@restore
        inc     ax
        mov     bx,ax                   ; bx keeps the pixel count
        mov     cl,3
        shr     ax,cl
        mov     cx,ax                   ; cx = whole bytes
        mov     dx,GcIndex              ; bit mask = every pixel of the byte
        mov     al,GcBitMask
        out     dx,al
        inc     dx
        mov     al,0FFh
        out     dx,al
        rep stosb                       ; fill the whole bytes
        and     bl,7                    ; pixels left over past them?
        je      @@restore
        mov     cl,bl                   ; bl = the right edge byte's pixels up to x2
        mov     bx,0FF00h
        shr     bx,cl
        mov     dx,GcIndex              ; bit mask = those pixels
        mov     al,GcBitMask
        out     dx,al
        inc     dx
        mov     al,bl
        out     dx,al
        mov     al,es:[di]              ; load the latches
        stosb                           ; write the edge byte
@@restore:
        mov     dx,GcIndex              ; set/reset off again
        mov     al,GcEnableSR
        out     dx,al
        inc     dx
        mov     al,0
        out     dx,al
        mov     dx,GcIndex              ; bit mask back to every pixel
        mov     al,GcBitMask
        out     dx,al
        inc     dx
        mov     al,0FFh
        out     dx,al
        pop     ds                      ; restore DS and SS
        pop     ss
        pop     bp
        ret     8                       ; pops the arguments
HlineEga ENDP

VlineEga PROC NEAR
        push    bp                      ; frame for the arguments
        mov     bp,sp
        sub     sp,0                    ; no locals
        push    ss                      ; SS and DS are restored before the return
        push    ds
        mov     al,[bp+vlY1]
        cmp     al,[bp+vlY2]
        jbe     @@ordered               ; put y1 before y2
        xchg    [bp+vlY2],al            ; swap them in the argument slots
        mov     [bp+vlY1],al
@@ordered:
        mov     dx,GcIndex              ; graphics controller mode: write mode 0
        mov     al,GcMode
        out     dx,al
        inc     dx
        mov     al,0
        out     dx,al
        mov     dx,GcIndex              ; enable set/reset on all four planes
        mov     al,GcEnableSR
        out     dx,al
        inc     dx
        mov     al,0Fh
        out     dx,al
        mov     dx,GcIndex              ; set/reset color = color
        mov     al,GcSetReset
        out     dx,al
        inc     dx
        mov     al,[bp+lineColor]
        out     dx,al
        mov     dx,GcIndex              ; function: replace, no rotate
        mov     al,GcFunction
        out     dx,al
        inc     dx
        mov     al,0
        out     dx,al
        mov     dx,SeqIndex             ; sequencer map mask: write all four planes
        mov     al,SeqMapMask
        out     dx,al
        inc     dx
        mov     al,0Fh
        out     dx,al
        cld                             ; no string instruction follows
        mov     ax,VideoSeg             ; ES = display memory
        mov     es,ax
        mov     al,[bp+vlY1]            ; di = y1 * 40 + x / 8, the first pixel's byte
        mov     bl,EgaRowBytes
        mul     bl
        mov     bx,[bp+vlX]
        mov     cl,3
        shr     bx,cl
        add     ax,bx
        mov     di,ax
        mov     cx,[bp+vlX]             ; bl = x's pixel in its byte
        and     cl,7
        mov     bx,80h
        shr     bx,cl
        mov     dx,GcIndex              ; bit mask = that pixel
        mov     al,GcBitMask
        out     dx,al
        inc     dx
        mov     al,bl
        out     dx,al
        sub     ch,ch                   ; cx = y2 - y1 + 1, the line's scanlines
        mov     cl,[bp+vlY2]
        sub     cl,[bp+vlY1]
        inc     cl
@@pixel:
        mov     al,es:[di]              ; load the latches
        mov     es:[di],al              ; and write the pixel
        add     di,EgaRowBytes          ; the next scanline
        loop    @@pixel
        mov     dx,GcIndex              ; set/reset off again
        mov     al,GcEnableSR
        out     dx,al
        inc     dx
        mov     al,0
        out     dx,al
        mov     dx,GcIndex              ; bit mask back to every pixel
        mov     al,GcBitMask
        out     dx,al
        inc     dx
        mov     al,0FFh
        out     dx,al
        pop     ds                      ; restore DS and SS
        pop     ss
        pop     bp
        ret     8                       ; pops the arguments
VlineEga ENDP

; HlineVga and VlineVga -- Hline's and Vline's VGA arms (VmVga, BIOS mode 13h), one byte per pixel at A000:0.
; Neither orders its end points: they take x1 <= x2 and y1 <= y2.

HlineVga PROC NEAR
        push    bp                      ; frame for the arguments
        mov     bp,sp
        cld                             ; stosb walks rightwards
        push    ds                      ; DS is restored before the return
        mov     bx,VgaRowBytes          ; di = row * 320 + x1, the first pixel
        xor     ax,ax
        mov     al,[bp+hlRow]
        mul     bx
        add     ax,[bp+hlX1]
        mov     di,ax
        mov     ax,VideoSeg             ; ES = display memory
        mov     es,ax
        xor     ax,ax                   ; al = color
        mov     al,[bp+lineColor]
        mov     cx,[bp+hlX2]            ; cx = x2 - x1 + 1
        inc     cx
        sub     cx,[bp+hlX1]
        rep stosb                       ; fill the run
        pop     ds
        pop     bp
        ret     8                       ; pops the arguments
HlineVga ENDP

VlineVga PROC NEAR
        push    bp                      ; frame for the arguments
        mov     bp,sp
        cld                             ; stosb steps di forwards
        push    ds                      ; DS is restored before the return
        mov     bx,VgaRowBytes          ; di = y1 * 320 + x, the first pixel
        mov     ax,[bp+vlY1]
        mul     bx
        add     ax,[bp+vlX]
        mov     di,ax
        mov     ax,VideoSeg             ; ES = display memory
        mov     es,ax
        xor     ax,ax                   ; al = color
        mov     al,[bp+lineColor]
        mov     cx,[bp+vlY2]            ; cx = y2 - y1 + 1
        inc     cx
        sub     cx,[bp+vlY1]
@@pixel:
        stosb                           ; the pixel, di one past it
        add     di,VgaRowBytes-1        ; the same column on the next scanline
        loop    @@pixel
        pop     ds
        pop     bp
        ret     8                       ; pops the arguments
VlineVga ENDP

CODE    ENDS
        END
