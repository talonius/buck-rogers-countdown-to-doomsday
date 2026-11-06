{ The title sequence: TITLE pictures 1 to 3, the credits screen, then picture 4. Each wait replays the step sound once a
  second and ends early on input; input at the first wait skips pictures 2 and 3. Introduction switches to data set 6
  for the pictures; on the way out it shows the mouse, loads the music driver and, unless sound is off, starts it, then
  sets isGameUp and restores the data set. NoopIntro is an empty placeholder. }
{$O+,F+,V+}
unit Intro;

interface

{ Runs the title sequence and readies the music, as the unit header describes. }
procedure Introduction;

{ Empty routine with no callers. }
procedure NoopIntro;

implementation

uses Blit, Border, GameIo, Mouse, TextRend, Music, Portrait, Types, C_Pic, GDConsts, GDVars;

const
  { the data set the TITLE pictures load from }
  TITLE_DATA_SET = 6;
  { credits color: the first line }
  CREDITS_BANNER = 14;
  { credits color: each role }
  CREDITS_HEADING = 15;
  { credits color: the names }
  CREDITS_NAME = 10;
  { MusDrv.StartPlayback: start the music }
  START_MUSIC_COMMAND = 2;

{ Waits, replaying the step sound once a second, until the time runs out or input arrives.
  @param(seconds The time to wait.)
  @returns(True when input cut the wait short.) }
function DelayOrKey(seconds: Word): Boolean;
var
  base: LongInt;
  target: LongInt;
  sample: LongInt;
begin
  GameIo.FlushKeys;
  base := TextRend.GetTicks;
  target := base + seconds * 100;
  sample := TextRend.GetTicks;
  repeat
    if TextRend.GetTicks - sample >= 100 then begin
      Music.SendSoundCommand(GDConsts.stepSound);
      sample := TextRend.GetTicks
    end
  until GameIo.InputPending or (TextRend.GetTicks >= target);
  if TextRend.GetTicks >= target then DelayOrKey := False else DelayOrKey := True;
  GameIo.FlushKeys
end;

{ Ends the title sequence: shows the mouse, loads the music driver and its bank, starts the music (unless sound is off),
  sets isGameUp and restores the data set. }
procedure FinishIntroduction;
begin
  Mouse.ShowMouse;
  Music.LoadDriverCode;
  Music.LoadMusicBank;
  Music.StartMusic(Intro.START_MUSIC_COMMAND);
  GDVars.isGameUp := True;
  GDVars.dataSet := GDVars.savedDataSet
end;

{ Shows the credits screen in the view palette for 20 seconds or until input, then clears the screen. }
procedure Credits;
begin
  Blit.SetDacPalette(C_Pic.VIEW_DAC_FIRST, C_Pic.VIEW_DAC_COUNT, GDVars.viewPalette);
  TextRend.ClearScreen;
  Border.ScreenCredits;
  TextRend.DisplayString(2, 1, Intro.CREDITS_BANNER, 0, 'CREATED BY:SSI SPECIAL PROJECTS TEAM');
  TextRend.DisplayString(11, 3, Intro.CREDITS_HEADING, 0, 'GAME DEVELOPMENT:');
  TextRend.DisplayString(14, 4, Intro.CREDITS_NAME, 0, 'BRET BERRY');
  TextRend.DisplayString(13, 6, Intro.CREDITS_HEADING, 0, 'PROGRAMMING:');
  TextRend.DisplayString(4, 7, Intro.CREDITS_NAME, 0, 'MIKE MCNALLY      RUSS BROWN');
  TextRend.DisplayString(1, 9, Intro.CREDITS_HEADING, 0, 'ENCOUNTER CODE:      MUSICAL SCORE:');
  TextRend.DisplayString(4, 10, Intro.CREDITS_NAME, 0, 'DAVID SHELLEY      TOM WAHL');
  TextRend.DisplayString(4, 11, Intro.CREDITS_NAME, 0, 'KEN HUMPHRIES');
  TextRend.DisplayString(22, 11, Intro.CREDITS_HEADING, 0, 'PLAYTEST:');
  TextRend.DisplayString(4, 12, Intro.CREDITS_NAME, 0, 'RHONDA GILBERT    LARRY WEBBER');
  TextRend.DisplayString(4, 13, Intro.CREDITS_NAME, 0, 'KEN EKLUND        ERIK FLOM');
  TextRend.DisplayString(1, 14, Intro.CREDITS_HEADING, 0, 'GRAPHIC ARTS:');
  TextRend.DisplayString(22, 14, Intro.CREDITS_NAME, 0, 'JOHN KIRK');
  TextRend.DisplayString(4, 15, Intro.CREDITS_NAME, 0, 'TOM WAHL          RICK WHITE');
  TextRend.DisplayString(4, 16, Intro.CREDITS_NAME, 0, 'LAURA BOWEN       DAVE LUCCA');
  TextRend.DisplayString(4, 17, Intro.CREDITS_NAME, 0, 'FRED BUTTS        CYRUS HARRIS');
  TextRend.DisplayString(4, 18, Intro.CREDITS_NAME, 0, 'MARK JOHNSON      GLEN CURETON');
  TextRend.DisplayString(4, 19, Intro.CREDITS_NAME, 0, 'CYRUS LUM         CHAD CASELLI');
  TextRend.DisplayString(4, 20, Intro.CREDITS_NAME, 0, 'SUSAN MANLEY      JEFF SHOTWELL');
  TextRend.DisplayString(4, 21, Intro.CREDITS_NAME, 0, 'MIKE PROVENZA     MIKE GILMARTIN');
  TextRend.DisplayString(4, 22, Intro.CREDITS_NAME, 0, 'MAURINE STARKEY   NATHANIEL TRUHER');
  { input only cuts the wait short }
  if Intro.DelayOrKey(20) then;
  TextRend.ClearScreen
end;

procedure Introduction;
var
  pic: Types.PImgBuf;
  { Unused in this version; see the other implementations of this routine. }
  keyed: Boolean;

  { Shows the last title picture on a cleared screen. }
  procedure ShowLastTitle;
  begin
    pic := nil;
    Blit.LoadPic('title', 4, False, 0, pic);
    TextRend.ClearScreen;
    Blit.SetDacPalette(C_Pic.VIEW_DAC_FIRST, C_Pic.VIEW_DAC_COUNT, GDVars.picturePalette);
    Blit.ShowPic(6, 9, pic);
    Blit.FreePic(pic)
  end;

begin
  pic := nil;
  Portrait.FreeAnimation;
  Mouse.HideMouse;
  TextRend.ClearScreen;
  GDVars.savedDataSet := GDVars.dataSet;
  GDVars.dataSet := Intro.TITLE_DATA_SET;
  Blit.LoadPic('title', 1, False, 0, pic);
  Blit.SetDacPalette(C_Pic.VIEW_DAC_FIRST, C_Pic.VIEW_DAC_COUNT, GDVars.picturePalette);
  Blit.ShowPic(0, 7, pic);
  Blit.FreePic(pic);
  if Intro.DelayOrKey(5) then begin
    Intro.Credits;
    ShowLastTitle;
    Intro.FinishIntroduction;
    Exit
  end;
  Blit.LoadPic('title', 2, False, 0, pic);
  TextRend.ClearScreen;
  Blit.ShowPic(2, 1, pic);
  Blit.FreePic(pic);
  Blit.LoadPic('title', 3, False, 0, pic);
  Blit.ShowPic(3, 21, pic);
  Blit.FreePic(pic);
  if Intro.DelayOrKey(5) then begin
    Intro.Credits;
    ShowLastTitle;
    Intro.FinishIntroduction;
    Exit
  end;
  Intro.Credits;
  ShowLastTitle;
  Intro.FinishIntroduction;
  Exit
end;

procedure NoopIntro;
begin
end;

begin
end.
