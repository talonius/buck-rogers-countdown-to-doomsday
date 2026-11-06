{ The PC-speaker and Tandy sound driver. SOUNDDRV.OBJ (sounddrv.asm) holds the INT 8 service routine, the tune tables
  and streams, the sequencer and the voice writers; this unit installs it and dispatches commands to it.

  soundState comes from the config file's sound letter: A GameBoot.SOUND_STATE_ADLIB, T C_Sound.TANDY, P
  C_Sound.SPEAKER, anything else C_Sound.OFF. At C_Sound.OFF sound is off: StartSound only records the state, and
  SoundCommand ignores every command but 21. At C_Sound.TANDY songs play on the Tandy voices, otherwise on the speaker.

  soundMode names the driver that sound commands go to: C_Sound.DRIVER_BUILT_IN this one, C_Sound.DRIVER_LOADED the one
  MusDrv calls, C_Sound.DRIVER_NONE neither. Music, GameIo and DaxIo dispatch on it. DaxIo's PushSoundState stops the
  driver and sets C_Sound.DRIVER_NONE for a disk access, and so does OpenWithRetry's StopHook call before a floppy read.
  Note: while sound is switched off by Ctrl-S, command $FF is ignored, so a disk access sets soundMode to
  C_Sound.DRIVER_NONE and leaves this driver holding INT 8. }
{$F+,O-,S-,R-,V-,B-,I-,A+}
unit SoundDrv;

interface

{ Sends a command to this driver; with no sound device configured every command but 21 is ignored.
  @param(cmd 0 starts song 0 on both devices, which silences them; 1 turns output on; 2..20 start song cmd - 1 on the
    Tandy voices for the Tandy device, else on the speaker; $FF, while this driver holds the sound, silences both
    devices, uninstalls the driver and records that no driver is loaded; 21 arms the timer routine's countdown to its
    fake run-time error.) }
procedure SoundCommand(cmd: Word);

{ Saves the current sound setting and, unless sound is off, marks this driver as the one in use, installs it and starts
  song 0 on both devices. }
procedure StartSound;

implementation

uses GDConsts, GDVars, C_Sound;

{$L SOUNDDRV.OBJ}
{ Installs the driver's timer interrupt handler, saving the old one, and speeds up the timer. }
procedure InstallSoundTimer; external;

{ Restores the old timer interrupt handler and the BIOS timer rate, and silences both banks of voices. }
procedure UninstallSoundTimer; external;

{ Starts a song on the Tandy voices; song 0 silences them.
  @param(song The song number.) }
procedure ProgramTandyVoices(song: Word); external;

{ Starts a song on the PC-speaker voices; song 0 silences them.
  @param(song The song number.) }
procedure ProgramSpeakerVoices(song: Word); external;

{ Turns the driver's output on or off without disturbing the songs.
  @param(value Non-zero turns output on; only the low byte is read.) }
procedure SetSoundOutputEnabled(value: Word); external;

{ a data word, declared as a procedure for its address }
procedure ExitCount; external;

procedure SoundCommand(cmd: Word);
var
  { Unused in this version; see the other implementations of this routine. }
  savedState: array[0..1] of Byte;
begin
  case cmd of
    0:
      if GDVars.soundState <> C_Sound.OFF then begin
        SoundDrv.ProgramTandyVoices(0);
        SoundDrv.ProgramSpeakerVoices(0)
      end;
    1:
      if GDVars.soundState <> C_Sound.OFF then SoundDrv.SetSoundOutputEnabled(1);
    255:
      if (GDVars.soundState <> C_Sound.OFF) and
          (GDVars.soundMode = C_Sound.DRIVER_BUILT_IN) then begin
        GDVars.soundMode := C_Sound.DRIVER_NONE;
        SoundDrv.ProgramTandyVoices(0);
        SoundDrv.ProgramSpeakerVoices(0);
        SoundDrv.UninstallSoundTimer
      end;
    2..20:
      if GDVars.soundState <> C_Sound.OFF then
        if GDVars.soundState = C_Sound.TANDY then SoundDrv.ProgramTandyVoices(cmd - 1)
        else SoundDrv.ProgramSpeakerVoices(cmd - 1);
    21:
      GDVars.timeoutPtr^ := 5000
  end
end;

procedure StartSound;
begin
  GDVars.savedSoundState := GDVars.soundState;
  if GDVars.soundState = C_Sound.OFF then Exit;
  GDVars.soundMode := C_Sound.DRIVER_BUILT_IN;
  SoundDrv.InstallSoundTimer;
  SoundDrv.ProgramSpeakerVoices(0);
  SoundDrv.ProgramTandyVoices(0)
end;

begin
  GDVars.timeoutPtr := @SoundDrv.ExitCount;
  GDVars.timeoutPtr^ := 0
end.
