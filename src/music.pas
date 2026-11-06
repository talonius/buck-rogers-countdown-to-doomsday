{ Loads the music driver from MUSIC.dax, and routes sound commands to one of the two drivers: SoundDrv's resident
  speaker and Tandy driver, or the loaded one that MusDrv calls. }
{$F+,O+,S-,R-,V-,B-,I-}
unit Music;

interface

{ Plays a sound command: stops the music driver if it is installed, installs SoundDrv's driver if none is, then calls
  SoundCommand.
  @param(command Sound command for SoundDrv.SoundCommand.) }
procedure SendSoundCommand(command: Word);

{ Unless sound is off, sends command to the loaded driver, first uninstalling SoundDrv's driver if it runs and then
  starting the loaded one if no driver runs.
  @param(command A sound command; MusDrv.StartPlayback acts on command 2 alone.) }
procedure StartMusic(command: Word);

{ Shuts down the music driver if it is installed. }
procedure StopMusic;

{ Releases the loaded driver's code and musicBank while its code is allocated. }
procedure FreeLoadedDriver;

{ Loads MUSIC.dax record 1, the driver code, into a block at driverCode, copied to the block's first 16-byte boundary,
  alignedDriverCode, so that it can run with its own segment. Aborts the game when the record is missing. }
procedure LoadDriverCode;

{ Loads MUSIC.dax record 2, the music bank the driver reads, into musicBank. }
procedure LoadMusicBank;

implementation

uses Types, GDConsts, GDVars, DaxIo, GameIo, SoundDrv, MusDrv, C_Sound;

procedure SendSoundCommand(command: Word);
begin
  if GDVars.soundMode = C_Sound.DRIVER_LOADED then MusDrv.StopHook;
  if GDVars.soundMode = C_Sound.DRIVER_NONE then SoundDrv.StartSound;
  SoundDrv.SoundCommand(command)
end;

procedure StartMusic(command: Word);
begin
  if GDVars.soundState = C_Sound.OFF then Exit;
  if GDVars.soundMode = C_Sound.DRIVER_BUILT_IN then SoundDrv.SoundCommand(GDConsts.soundDriverOff);
  if GDVars.soundMode =
      C_Sound.DRIVER_NONE then MusDrv.StartDriver(GDVars.alignedDriverCode, GDVars.musicBank);
  MusDrv.StartPlayback(command)
end;

procedure StopMusic;
begin
  if GDVars.soundMode = C_Sound.DRIVER_LOADED then MusDrv.StopHook
end;

procedure FreeLoadedDriver;
begin
  if GDVars.isDriverReady then begin
    MusDrv.FreeDriver;
    GDVars.isDriverReady := False
  end
end;

procedure LoadDriverCode;
var data: Types.PByteArr;
begin
  data := nil;
  DaxIo.LoadDax('MUSIC', '.dax', 1, GDVars.driverCodeSize, data);
  if GDVars.driverCodeSize = 0 then begin
    WriteLn('unable to load com file');
    GameIo.ExitGame
  end;
  GetMem(GDVars.driverCode, GDVars.driverCodeSize + C_Sound.DRIVER_CODE_SLACK);
  FillChar(GDVars.driverCode^, GDVars.driverCodeSize + C_Sound.DRIVER_CODE_SLACK, 0);
  GDVars.alignedDriverCode := GDVars.driverCode;
  { Round up to a 16-byte boundary: a heap pointer is normalized, so its offset is below 16 and the next segment at
    offset 0 is the next boundary. }
  if (LongInt(GDVars.alignedDriverCode) and $F) > 0 then begin
    Inc(LongInt(GDVars.alignedDriverCode), $10000);
    LongInt(GDVars.alignedDriverCode) := LongInt(GDVars.alignedDriverCode) and $FFFF0000
  end;
  { the offset's whole paragraphs move into the segment }
  LongInt(GDVars.alignedDriverCode) := ((LongInt(GDVars.alignedDriverCode) and $FFF0) shl 12) +
    LongInt(GDVars.alignedDriverCode);
  LongInt(GDVars.alignedDriverCode) := LongInt(GDVars.alignedDriverCode) and $FFFF0000;
  GDVars.driverCopy := GDVars.alignedDriverCode;
  Move(data^, GDVars.driverCopy^, GDVars.driverCodeSize);
  FreeMem(data, GDVars.driverCodeSize);
  GDVars.isDriverReady := True
end;

procedure LoadMusicBank;
var
  data: Types.PByteArr;
  { Unused in this version; see the other implementations of this routine. }
  count: Byte;
begin
  DaxIo.LoadDax('MUSIC', '.dax', 2, GDVars.musicBankSize, data);
  GDVars.musicBank := data
end;

begin
end.
