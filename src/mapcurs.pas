{ Draws and erases the party's cursor on a wilderness picture. DrawCursor draws cursorPicture over the 8x8 cell at
  column wildernessX + 1, row wildernessY + 1 of zone 0, and RestoreCursorBackground puts that cell back; both act only
  while isViewActive is set. The unit owns no storage. NoopMapCursA to NoopMapCursD are empty placeholders. }
{$O+,F+,A+}
unit MapCurs;

interface

{ Empty routine with no callers. }
procedure NoopMapCursA;

{ Empty routine with no callers. }
procedure NoopMapCursB;

{ When the view is active, saves the party's cell, draws the cursor picture through its mask over a copy of it, shows
  that, and resets the dirty-span tables (the first-row table to $FF, the rest to 0); otherwise does nothing. }
procedure DrawCursor;

{ When the view is active, shows the saved cell back over the party's cell; otherwise does nothing. }
procedure RestoreCursorBackground;

{ Empty routine with no callers. }
procedure NoopMapCursC;

{ Empty routine with no callers. }
procedure NoopMapCursD;

implementation

uses Blit, GDConsts, GDVars;

procedure DrawCursor;
begin
  if GDVars.isViewActive then begin
    Blit.GrabPic(GDVars.zone0^.wildernessX + 1, GDVars.zone0^.wildernessY + 1, GDVars.savedWildernessCell);
    Blit.BlitTileCell(0, 0, 0, 0, GDVars.savedWildernessCell, GDVars.wildernessCursorCell);
    Blit.BlitTileCell(0, 0, 0, 1, GDVars.cursorPicture, GDVars.wildernessCursorCell);
    Blit.ShowPic(GDVars.zone0^.wildernessX + 1, GDVars.zone0^.wildernessY + 1, GDVars.wildernessCursorCell);
    FillChar(GDVars.dirtyRows, SizeOf(GDVars.dirtyRows), 0);
    FillChar(GDVars.dirtyRowLeft, SizeOf(GDVars.dirtyRowLeft), 0);
    FillChar(GDVars.dirtyRowFirst, SizeOf(GDVars.dirtyRowFirst), $FF);
    FillChar(GDVars.dirtyRowLast, SizeOf(GDVars.dirtyRowLast), 0)
  end
end;

procedure RestoreCursorBackground;
begin
  if not GDVars.isViewActive then Exit;
  Blit.ShowPic(GDVars.zone0^.wildernessX + 1, GDVars.zone0^.wildernessY + 1, GDVars.savedWildernessCell)
end;

procedure NoopMapCursA; begin end;

procedure NoopMapCursB; begin end;

procedure NoopMapCursC; begin end;

procedure NoopMapCursD; begin end;

begin
end.
