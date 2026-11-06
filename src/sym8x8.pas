{ The 8x8 tile sets: Load8x8Set loads a set into a slot of tileSets, Put8x8Sym draws a tile by its number, and
  DrawBorderRun draws a run of the border slot's tiles. Tile numbers run on through the slots, tileSetFirst and
  tileSetLast giving each slot's range; Put8x8Sym takes the first slot whose last tile reaches the number. Note: slot
  0's range, 0 to 255, also covers slots 1 to 3's, so tiles 1 to 255 always draw from slot 0. NoopSym8x8A and
  NoopSym8x8B are empty placeholders. }
{$O+,F+,I-}
unit Sym8x8;

interface

{ Empty routine with no callers. }
procedure NoopSym8x8A;

{ Loads a tile set from 8x8d plus the data set's digit, or from borders for the border slot; a failed load stops the
  game.
  @param(fileId The record to load.)
  @param(slot The tile-set slot, 0 to 6; another slot does nothing.) }
procedure Load8x8Set(fileId, slot: Byte);

{ Draws a tile by its number; tile 0, a tile past the last slot's range, or one whose slot is not loaded draws nothing.
  @param(col The cell's column.)
  @param(row The cell's row.)
  @param(tile The tile's number, counted on through the slots.)
  @param(isInView Non-zero blits it into viewPicture; zero shows it on the screen.)
  @param(isMasked Passed to Blit's BlitTileCell as its flag, whose bit 0 asks for the masked draw.) }
procedure Put8x8Sym(col, row: ShortInt; tile: Word; isInView, isMasked: Byte);

{ Empty routine with no callers. }
procedure NoopSym8x8B;

{ Draws a horizontal or vertical run of border tiles on the screen. The third cell from each end is left undrawn, and a
  corner or junction tile also draws a join tile two cells off.
  @param(x1 The first cell's column.)
  @param(y1 The first cell's row.)
  @param(x2 The last cell's column.)
  @param(y2 The last cell's row.)
  @param(firstSel The first cell's tile, counted from the border slot's first.)
  @param(lastSel The last cell's tile, likewise.) }
procedure DrawBorderRun(x1, y1, x2, y2: ShortInt; firstSel, lastSel: Byte);

implementation

uses GameIo, Blit, Types, C_Pic, GDConsts, GDVars;

const
  { the tile-set slot holding the border tiles }
  BORDER_SLOT = 6;
  { EmitBorderCell's sel: SEL_SKIP draws nothing in the cell and moves on; SEL_STRAIGHT draws STRAIGHT_TILE plus
    isVertical, both counted from the border slot's first. }
  SEL_SKIP = 0;
  SEL_STRAIGHT = 1;
  SEL_FIRST = 2;
  SEL_LAST = 3;
  STRAIGHT_TILE = 4;

procedure Load8x8Set(fileId, slot: Byte);
var
  fileName: String[8];
  { Unused in this version; see the other implementations of this routine. }
  result: Integer;
  { Unused in this version; see the other implementations of this routine. }
  key: Char;
begin
  if GDVars.isDebugMode then
    WriteLn(GDVars.debugFile, 'slotnum = ', slot);
  if slot in [0..SizeOf(GDVars.tileSets) div SizeOf(Types.PImgBuf) - 1] then begin
    if slot = Sym8x8.BORDER_SLOT then
      fileName := 'borders'
    else begin
      Str(GDVars.dataSet, fileName);
      fileName := '8x8d' + fileName
    end;
    Blit.LoadPic(fileName, fileId, True, C_Pic.KEY_COLOR, GDVars.tileSets[slot]);
    if GDVars.tileSets[slot] = nil then begin
      Blit.RestoreVideoMode;
      WriteLn('Unable to load ', fileId, ' from ' + fileName);
      key := GameIo.ReadGameKey;
      Blit.RestoreVideoMode;
      GameIo.ExitGame
    end;
    GameIo.FlushKeys
  end
end;

procedure Put8x8Sym(col, row: ShortInt; tile: Word; isInView, isMasked: Byte);
var
  slot: Byte;
begin
  slot := 0;
  while GDConsts.tileSetLast[slot] < tile do Inc(slot);
  if (tile = 0) or (slot > SizeOf(GDVars.tileSets) div SizeOf(Types.PImgBuf) - 1) then Exit;
  if GDVars.tileSets[slot] = nil then Exit;
  Dec(tile, GDConsts.tileSetFirst[slot]);
  if isInView <> 0 then
    Blit.BlitTileCell(col, row, tile, isMasked, GDVars.tileSets[slot], GDVars.viewPicture)
  else begin
    with GDVars.tileSets[slot]^ do
      Move(data[tile * frameSize], GDVars.tileScratch^.data[0], frameSize);
    Blit.ShowPic(col, row, GDVars.tileScratch)
  end
end;

procedure DrawBorderRun(x1, y1, x2, y2: ShortInt; firstSel, lastSel: Byte);
var
  isVertical: Byte;
  count: ShortInt;

  { Draws the run's next cell as sel picks, with the extra tiles 10 and 11 its tile needs, then steps along the run. }
  procedure EmitBorderCell(sel: Byte);
  var
    idx: ShortInt;
  begin
    case sel of
      Sym8x8.SEL_SKIP: idx := -1;
      Sym8x8.SEL_STRAIGHT: idx := isVertical + Sym8x8.STRAIGHT_TILE;
      Sym8x8.SEL_FIRST: idx := firstSel;
      Sym8x8.SEL_LAST: idx := lastSel
    end;
    if idx >= 0 then
      Sym8x8.Put8x8Sym(x1, y1, idx + GDConsts.tileSetFirst[Sym8x8.BORDER_SLOT], 0, 0);
    if idx in [0, 3, 6, 8, 9] then
      Sym8x8.Put8x8Sym(x1 + 2, y1, GDConsts.tileSetFirst[Sym8x8.BORDER_SLOT] + 10, 0, 0);
    if idx in [1, 2, 6, 7, 8] then
      Sym8x8.Put8x8Sym(x1 - 2, y1, GDConsts.tileSetFirst[Sym8x8.BORDER_SLOT] + 10, 0, 0);
    if idx in [0, 1, 6, 7, 9] then
      Sym8x8.Put8x8Sym(x1, y1 + 2, GDConsts.tileSetFirst[Sym8x8.BORDER_SLOT] + 11, 0, 0);
    if idx in [2, 3, 7, 8, 9] then
      Sym8x8.Put8x8Sym(x1, y1 - 2, GDConsts.tileSetFirst[Sym8x8.BORDER_SLOT] + 11, 0, 0);
    if isVertical <> 0 then Inc(y1) else Inc(x1);
    Dec(count)
  end;

begin
  if y1 = y2 then begin
    isVertical := 0;
    if x1 > x2 then begin
      count := x1; x1 := x2; x2 := count
    end;
    count := x2 - x1 + 1
  end else begin
    isVertical := 1;
    if y1 > y2 then begin
      count := y1; y1 := y2; y2 := count
    end;
    count := y2 - y1 + 1
  end;
  EmitBorderCell(Sym8x8.SEL_FIRST);
  EmitBorderCell(Sym8x8.SEL_STRAIGHT);
  EmitBorderCell(Sym8x8.SEL_SKIP);
  while count > 3 do EmitBorderCell(Sym8x8.SEL_STRAIGHT);
  if count = 3 then EmitBorderCell(Sym8x8.SEL_SKIP);
  if count = 2 then EmitBorderCell(Sym8x8.SEL_STRAIGHT);
  if count = 1 then EmitBorderCell(Sym8x8.SEL_LAST)
end;

procedure NoopSym8x8A; begin end;

procedure NoopSym8x8B; begin end;

begin
end.
