{ The heap-error hook: its initialization installs HeapErrorHandler as System's HeapError, so a failed allocation saves
  the game and exits instead of dying with a run-time error. The unit owns no state. }
{$O+,F+,A+}
unit HeapErr;

interface

{ Warns that memory is short. While a game is in progress it saves the game, warning again until the saved flag shows
  the save went through; otherwise it says it is exiting. Note: the saved flag is not cleared before the save, so a flag
  still set by an earlier save ends the loop even if this save failed.
  @param(size Unused.)
  @returns(Never: ExitGame halts the program.) }
function HeapErrorHandler(size: Word): Integer;

implementation

uses TextRend, SaveLoad, GameIo, GDConsts, GDVars, Crt;

function HeapErrorHandler(size: Word): Integer;
var
  isDone: Boolean;
begin
  isDone := False;
  repeat
    TextRend.DisplayAndPause(Yellow, Black, 'WARNING: Insufficient Memory');
    if GDVars.isGameUp then begin
      SaveLoad.SaveGame;
      isDone := GDVars.isGameSaved
    end else begin
      isDone := True;
      TextRend.DisplayAndPause(Yellow, Black, 'Insufficient Memory. Exiting Program')
    end
  until isDone;
  GameIo.ExitGame
end;

begin
  HeapError := @HeapErr.HeapErrorHandler
end.
