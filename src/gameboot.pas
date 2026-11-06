{ The resident start-up unit. It exports nothing; its initialization is the boot. It starts the overlay manager on
  GAME.OVR with GameIo's OverlayReadWithBeep as the overlay reader, takes the data path from the current directory and
  the alternate path from it (the other floppy drive, or the same path on a hard disk), and, when buck.cfg is missing,
  runs the first-run dialog that writes it. It then sets the video mode buck.cfg names (moving the free list down for
  Tandy video memory), sizes the overlay buffer, and reads the rest of buck.cfg: sound, input device, save path, intro
  flag and joystick calibration. The dialog's working storage is in GDVars. }
{$F+,O+,S-,R-,V-,B-,I-}
unit GameBoot;

interface

implementation

uses Crt, Dos, Overlay, DaxIo, TextRend, Joystick, GameIo, Blit, Types, GDConsts, GDVars,
  C_Sound;

const
  { soundState for A, the first-run dialog's Ad Lib card }
  SOUND_STATE_ADLIB = 2;
  { INT 10h function: AL returns the current mode }
  BIOS_GET_VIDEO_MODE = $0F;
  { 320x200, 4 colors }
  VIDEO_MODE_CGA = $04;
  { 320x200, 16 colors, Tandy 1000 }
  VIDEO_MODE_TANDY = $09;
  { 320x200, 16 colors }
  VIDEO_MODE_EGA = $0D;
  { 320x200, 256 colors }
  VIDEO_MODE_VGA = $13;
  { paragraphs (16 KB) FreePtr moves down for Tandy video memory }
  GFX_RESERVE_PARAS = 1024;
  { FreeMin after that move: the bytes the heap keeps for its free list, ten of TP's 8-byte free-list records }
  FREE_LIST_RESERVE = 80;
  OVERLAY_BUF_BYTES = 122880;

var
  freePtrWords: Types.TPtrWords absolute FreePtr;

{ Waits for a digit key within a range and echoes it.
  @param(minimum The lowest digit accepted.)
  @param(maximum The highest digit accepted.)
  @returns(The digit's value.) }
function ReadChoice(minimum, maximum: Byte): Byte;
begin
  repeat
    GDVars.cfgChar := ReadKey
  until (GDVars.cfgChar in ['0'..'9']) and ((Ord(GDVars.cfgChar) - Ord('0')) in [minimum..maximum]);
  Write(GDVars.cfgChar);
  ReadChoice := Ord(GDVars.cfgChar) - Ord('0')
end;

begin
  CheckBreak := False;
  DaxIo.OverlayPrompt;
  OvrInit('GAME.OVR');
  GDVars.originalOvrReader := OvrReadBuf;
  OvrReadBuf := GameIo.OverlayReadWithBeep;

  FSplit(FExpand('*.exe'), GDVars.gDataPath, GDVars.fsName, GDVars.fsExt);
  if GDVars.gDataPath[1] < 'C' then begin
    if GDVars.gDataPath[1] = 'A' then GDVars.gAltPath := 'B:\'
    else GDVars.gAltPath := 'A:\'
  end else GDVars.gAltPath := GDVars.gDataPath;
  GDVars.gPromptDrive := GDVars.gAltPath[1];

  if not DaxIo.FileExists(GDConsts.configFileName) then begin
    Assign(GDVars.cfgText, GDConsts.configFileName);
    Rewrite(GDVars.cfgText);
    GDVars.cfgErr := IOResult;
    if GDVars.cfgErr <> 0 then begin
      ClrScr;
      WriteLn('Sorry, disk A can''t be write-protected.');
      WriteLn;
      WriteLn('If these are your masters, use DISKCOPY to make duplicates.');
      Halt(1)
    end;

    ClrScr;
    Write('GRAPHICS ADAPTER TYPE:  [1] CGA  [2] EGA  [3] Tandy  [4] VGA ');
    GDVars.menuChoice := GameBoot.ReadChoice(1, 4);
    case GDVars.menuChoice of
      1: WriteLn(GDVars.cfgText, 'C');
      2: WriteLn(GDVars.cfgText, 'E');
      3: WriteLn(GDVars.cfgText, 'T');
      4: WriteLn(GDVars.cfgText, 'V')
    end;

    ClrScr;
    WriteLn('SOUND TYPE:  [1] AdLib');
    WriteLn('             [2] Tandy 1000');
    WriteLn('             [3] PC speaker');
    WriteLn('             [4] Silent');
    GDVars.menuChoice := GameBoot.ReadChoice(1, 4);
    case GDVars.menuChoice of
      1: WriteLn(GDVars.cfgText, 'A');
      2: WriteLn(GDVars.cfgText, 'T');
      3: WriteLn(GDVars.cfgText, 'P');
      4: WriteLn(GDVars.cfgText, 'S')
    end;

    GDVars.isJoystickOn := False;
    ClrScr;
    Write('ALTERNATE INPUT TYPE:  [1] JOYSTICK  [2] MOUSE  [3] NEITHER  ');
    GDVars.menuChoice := GameBoot.ReadChoice(1, 3);
    case GDVars.menuChoice of
      1: begin WriteLn(GDVars.cfgText, 'J'); GDVars.isJoystickOn := True end;
      2: WriteLn(GDVars.cfgText, 'M');
      3: WriteLn(GDVars.cfgText, 'N')
    end;

    ClrScr;
    GDVars.defaultSavePath := GDVars.gAltPath + 'SAVE';
    Write('PATH TO SAVE DATA (DEFAULT - ' + GDVars.defaultSavePath + '):  ');
    ReadLn(GDVars.pathBuf);
    GDVars.pathBuf[1] := UpCase(GDVars.pathBuf[1]);
    if not ((Length(GDVars.pathBuf) >= 4) and (GDVars.pathBuf[2] = ':') and
            (not (GDVars.pathBuf[1] in ['A', 'B']) or (GDVars.pathBuf[1] <> GDVars.gDataPath[1])) and
            (GDVars.pathBuf[1] in ['A'..'P'])) then begin
      GDVars.pathBuf := GDVars.defaultSavePath;
      WriteLn('USING DEFAULT PATH: ' + GDVars.pathBuf);
      Delay(2000)
    end;
    for GDVars.ix := 1 to Length(GDVars.pathBuf) do
      GDVars.pathBuf[GDVars.ix] := UpCase(GDVars.pathBuf[GDVars.ix]);
    if GDVars.pathBuf[Length(GDVars.pathBuf)] <> '\' then
      GDVars.pathBuf := GDVars.pathBuf + '\';
    WriteLn(GDVars.cfgText, GDVars.pathBuf);
    WriteLn(GDVars.cfgText, 'F');

    Joystick.CalibrateJoystick;
    for GDVars.ix := 0 to SizeOf(Types.TJoyAxis) div SizeOf(Word) - 1 do begin
      WriteLn(GDVars.cfgText, GDVars.joystickCalibration[1].x[GDVars.ix]);
      WriteLn(GDVars.cfgText, GDVars.joystickCalibration[1].y[GDVars.ix])
    end;
    Close(GDVars.cfgText)
  end;

  ClrScr;
  WriteLn('TANDY 1000 USERS - Make sure NUMLOCK is on.');
  Delay(2000);
  Assign(GDVars.cfgText, GDConsts.configFileName);
  Reset(GDVars.cfgText);
  ReadLn(GDVars.cfgText, GDVars.cfgChar);

  GDVars.regs.ah := GameBoot.BIOS_GET_VIDEO_MODE;
  Intr($10, Registers(GDVars.regs));
  GDVars.savedVideoMode := GDVars.regs.al;
  GDVars.curVideoMode := GDVars.savedVideoMode;
  case GDVars.cfgChar of
    'E': begin
      GDVars.displayMode := Types.VmEga;
      Blit.SetVideoMode(GameBoot.VIDEO_MODE_EGA);
      GDVars.egaShownPage := 0;
      GDVars.egaDrawPage := 0;
      TextRend.SetupEgaCurrentPage(GDVars.egaShownPage);
      TextRend.SetupEgaOtherPage(GDVars.egaDrawPage)
    end;
    'T': begin
      GDVars.displayMode := Types.VmTandy;
      GDVars.newFreePtr := Ptr(freePtrWords.seg - GameBoot.GFX_RESERVE_PARAS, freePtrWords.ofs);
      Move(FreePtr^, GDVars.newFreePtr^, SizeOf(Types.TFreeBlk));
      FreePtr := GDVars.newFreePtr;
      Blit.SetVideoMode(GameBoot.VIDEO_MODE_TANDY);
      FreeMin := GameBoot.FREE_LIST_RESERVE;
      GDVars.graphicsReserve := FreePtr
    end;
    'V': begin
      GDVars.displayMode := Types.VmVga;
      Blit.SetVideoMode(GameBoot.VIDEO_MODE_VGA)
    end;
  else
    GDVars.displayMode := Types.VmCga;
    Blit.SetVideoMode(GameBoot.VIDEO_MODE_CGA)
  end;

  if GameBoot.OVERLAY_BUF_BYTES - OvrGetBuf <= MemAvail then
    OvrSetBuf(GameBoot.OVERLAY_BUF_BYTES)
  else begin
    Blit.RestoreVideoMode;
    WriteLn('Not enough memory to run game.  You need ', GameBoot.OVERLAY_BUF_BYTES - OvrGetBuf - MemAvail,
            ' more bytes.');
    Halt
  end;
  if OvrResult <> 0 then begin
    Blit.RestoreVideoMode;
    WriteLn('Overlay error, program abort!');
    Halt
  end;

  ReadLn(GDVars.cfgText, GDVars.cfgChar);
  case GDVars.cfgChar of
    'A': GDVars.soundState := GameBoot.SOUND_STATE_ADLIB;
    'T': GDVars.soundState := C_Sound.TANDY;
    'P': GDVars.soundState := C_Sound.SPEAKER;
  else GDVars.soundState := C_Sound.OFF
  end;
  ReadLn(GDVars.cfgText, GDVars.cfgChar);
  case GDVars.cfgChar of
    'J': begin GDVars.isJoystickOn := True; GDVars.isMouseOn := False end;
    'M': begin GDVars.isMouseOn := True; GDVars.isJoystickOn := False end;
    'N': begin GDVars.isMouseOn := False; GDVars.isJoystickOn := False end
  end;
  ReadLn(GDVars.cfgText, GDVars.savePath);
  ReadLn(GDVars.cfgText, GDVars.cfgChar);
  if GDVars.cfgChar = 'F' then
    GDVars.isFullIntro := True
  else
    GDVars.isFullIntro := False;
  Joystick.ProbeJoystick;
  if GDVars.isJoystickOn then
    for GDVars.ix := 0 to SizeOf(Types.TJoyAxis) div SizeOf(Word) - 1 do begin
      ReadLn(GDVars.cfgText, GDVars.joystickCalibration[1].x[GDVars.ix]);
      ReadLn(GDVars.cfgText, GDVars.joystickCalibration[1].y[GDVars.ix])
    end;
  Close(GDVars.cfgText)
end.
