{ Keyboard, mouse and joystick input, the hotkeys, and the game's exit.

  ReadGameKey takes a key from the BIOS keyboard, or a button or joystick zone from the device in use, and runs the
  hotkeys before it answers: Ctrl-S switches sound off and on, Ctrl-U flips isMusicOn and stops the loaded driver as it
  turns it off, Ctrl-D switches logging to debug.txt, Ctrl-Z walks the party list when logging, Ctrl-C ends the game
  through ExitGame. OverlayReadWithBeep is the overlay read routine GameBoot installs. }
{$F+,O-,S-,R-,V-,B-,I-}
unit GameIo;

interface

{ Ends the game at once: hides and resets the mouse, stops the loaded sound driver, restores the saved video mode,
  closes debug.txt while logging, and halts. Note: SoundDrv's driver is not stopped while the sound is off, so after
  Ctrl-S the game halts with INT 8 still hooked. }
procedure ExitGame;

{ Waits for a key or, while a mouse or joystick is in use, for a button (Enter or Escape) or a joystick zone (the keypad
  digit joystickKeys gives); in the demo with neither in use and no key waiting it answers #0 at once. Runs the hotkeys,
  and sets isMouseClick when the mouse poller took a button. Note: both buttons at once (3) are neither Enter nor
  Escape, so the answer is left unset.
  @returns(The key, or #0.) }
function ReadGameKey: Char;

{ Tests for input without taking it.
  @returns(True when a key waits or, while a mouse or joystick is in use, a button is down or the joystick is off
    center.) }
function InputPending: Boolean;

{ Discards every key waiting in the BIOS buffer. }
procedure FlushKeys;

{ Takes one pending input through ReadGameKey, hotkeys included, and discards it. }
procedure DiscardPendingKeys;

{ Reads an overlay for the overlay manager, as installed by GameBoot: calls the saved reader until that succeeds,
  beeping (4000 Hz, 20 ms) after each failure.
  @param(overlaySegment The overlay to read, passed to the saved reader.)
  @returns(0, success.) }
function OverlayReadWithBeep(overlaySegment: Word): Integer;

implementation
uses Crt, Dos, Mouse, Joystick, SoundDrv, Types, C_Video, GDConsts, GDVars, C_Sound,
  C_Keys, C_Joy, MusDrv;

const
  KEY_CTRL_C = #3;
  KEY_CTRL_D = #4;
  KEY_CTRL_S = #19;
  KEY_CTRL_U = #21;
  KEY_CTRL_Z = #26;
  { a mouse's left button, or a joystick's button 1: C_Keys.ENTER }
  FIRST_BUTTON = 1;
  { a mouse's right button, or a joystick's button 2: C_Keys.ESCAPE }
  SECOND_BUTTON = 2;

procedure ExitGame;
var
  { Unused in this version; see the other implementations of this routine. }
  videoMode: Word;
begin
  Mouse.HideMouse;
  Mouse.ResetMouse;
  case GDVars.soundMode of
    C_Sound.DRIVER_LOADED: MusDrv.StopHook;
    C_Sound.DRIVER_BUILT_IN: SoundDrv.SoundCommand(GDConsts.soundDriverOff);
  end;
  GDVars.regs.ah := C_Video.BIOS_SET_VIDEO_MODE;
  GDVars.regs.al := GDVars.savedVideoMode;
  Intr($10, Registers(GDVars.regs));
  if GDVars.isDebugMode then
    Close(GDVars.debugFile);
  Halt(0);
end;

{ Does nothing; in debug mode the game-key reader's Ctrl-Z handler calls it for each creature in the party list.
  @param(node Unused.) }
procedure DumpWhoList(node: Types.PCharacter);
var
  { Unused in this version; see the other implementations of this routine. }
  cur: Types.PEffect;
begin
end;

function ReadGameKey: Char;
var
  ch: Char;
  member: Types.PCharacter;
  buttons: Integer;
  zone: Byte;
  hasInput: Boolean;
  { Unused in this version; see the other implementations of this routine. }
  scanCode: Byte;

  { Waits for a key or for joystick input, turning a button into Enter or Escape and a stick zone into its keypad key. }
  procedure TranslateJoystick;
  begin
    buttons := 0;
    hasInput := False;
    while (not KeyPressed) and not hasInput do begin
      Joystick.GetJoystick(buttons, zone);
      if (zone < C_Joy.NO_ZONE) or ((buttons <> 0) <> False) then begin
        if zone < C_Joy.NO_ZONE then
          ch := GDConsts.joystickKeys[zone]
        else
          case buttons of
            GameIo.FIRST_BUTTON: ch := C_Keys.ENTER;
            GameIo.SECOND_BUTTON: ch := C_Keys.ESCAPE;
          end;
        hasInput := True;
      end;
    end;
  end;

  { Waits for a key or a mouse button, turning the button into Enter or Escape and noting the mouse click. }
  procedure TranslateMouse;
  begin
    buttons := 0;
    hasInput := False;
    while (not KeyPressed) and not hasInput do begin
      Mouse.GetMouse(buttons, GDVars.mouseX, GDVars.mouseY);
      if buttons <> 0 then begin
        case buttons of
          GameIo.FIRST_BUTTON: ch := C_Keys.ENTER;
          GameIo.SECOND_BUTTON: ch := C_Keys.ESCAPE;
        end;
        GDVars.isMouseClick := True;
        hasInput := True;
      end;
    end;
  end;

begin
  GDVars.isMouseClick := False;
  if KeyPressed then
    ch := ReadKey
  else if GDVars.isJoystickOn or GDVars.isMouseOn then begin
    if GDVars.isMouseOn then TranslateMouse else TranslateJoystick;
    if KeyPressed then ch := ReadKey;
  end else if GDVars.isDemoRunning then
    ch := #0
  else
    ch := ReadKey;

  { sound off, or back on when the soundState it left was C_Sound.TANDY or C_Sound.SPEAKER }
  if ch = GameIo.KEY_CTRL_S then begin
    if GDVars.soundState <> C_Sound.OFF then begin
      GDVars.savedSoundState := GDVars.soundState;
      if GDVars.soundMode = C_Sound.DRIVER_BUILT_IN then
        SoundDrv.SoundCommand(GDConsts.silenceSounds);
      GDVars.soundState := C_Sound.OFF;
    end else if GDVars.savedSoundState in [C_Sound.TANDY, C_Sound.SPEAKER] then begin
      GDVars.soundState := GDVars.savedSoundState;
      if GDVars.soundMode = C_Sound.DRIVER_BUILT_IN then
        SoundDrv.SoundCommand(GDConsts.soundOutputOn);
    end;
  end;

  { flips isMusicOn; turning it on starts nothing }
  if ch = GameIo.KEY_CTRL_U then begin
    GDVars.isMusicOn := not GDVars.isMusicOn;
    if not GDVars.isMusicOn then
      MusDrv.StopHook;
  end;

  case ch of
    { logging to debug.txt on or off }
    GameIo.KEY_CTRL_D:
      begin
        GDVars.isDebugMode := not GDVars.isDebugMode;
        if GDVars.isDebugMode then begin
          Assign(GDVars.debugFile, 'debug.txt');
          Rewrite(GDVars.debugFile);
        end else
          Close(GDVars.debugFile);
      end;
    GameIo.KEY_CTRL_Z:
      begin
        if GDVars.isDebugMode then begin
          member := GDVars.partyHead;
          while member <> nil do begin
            GameIo.DumpWhoList(member);
            member := member^.next;
          end;
        end;
      end;
    GameIo.KEY_CTRL_C:
      GameIo.ExitGame;
  end;

  ReadGameKey := ch;
end;

function InputPending: Boolean;
var
  buttons: Integer;
  zone: Byte;
begin
  InputPending := KeyPressed;
  if not (GDVars.isJoystickOn or GDVars.isMouseOn) then Exit;
  if GDVars.isMouseOn then begin
    Mouse.GetMouse(buttons, GDVars.mouseX, GDVars.mouseY);
    InputPending := KeyPressed or ((buttons <> 0) <> False);
  end else begin
    Joystick.GetJoystick(buttons, zone);
    InputPending := KeyPressed or ((buttons > 0) <> False) or ((zone < C_Joy.NO_ZONE) <> False);
  end;
end;

procedure FlushKeys;
var
  { Unused in this version; see the other implementations of this routine. }
  ch: Char;
begin
  while KeyPressed do
    ch := ReadKey;
end;

procedure DiscardPendingKeys;
var
  { Unused in this version; see the other implementations of this routine. }
  key: Char;
begin
  if GameIo.InputPending then
    key := GameIo.ReadGameKey;
end;

function OverlayReadWithBeep(overlaySegment: Word): Integer;
begin
  while GDVars.originalOvrReader(overlaySegment) <> 0 do begin
    Sound(4000);
    Delay(20);
    NoSound;
  end;
  OverlayReadWithBeep := 0;
end;

begin
end.
