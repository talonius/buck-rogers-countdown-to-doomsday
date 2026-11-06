{ The sound settings: soundState's values, the configured device, and soundMode's, the driver in use; and the room the
  loaded driver takes past its code. }
unit C_Sound;

interface

const
  { soundState values: the config file's sound letter, as GameBoot's first-run dialog offers it }
  { T, its Tandy 1000: SoundDrv plays its songs on the Tandy voices }
  TANDY = 3;
  { P, its PC speaker }
  SPEAKER = 4;
  { any other letter, the dialog's Silent writing S: SoundDrv and Music play nothing }
  OFF = 5;
  { soundMode values: the driver sound commands go to }
  { neither: GameInit at start-up, DaxIo for a disk access, and each driver as it stops }
  DRIVER_NONE = 0;
  { SoundDrv's own speaker and Tandy driver, linked in, which its StartSound installs }
  DRIVER_BUILT_IN = 1;
  { the driver Music loads from MUSIC.dax, which MusDrv's StartDriver runs }
  DRIVER_LOADED = 2;
  { extra bytes Music allocates for that driver past driverCodeSize: room to align it on a 16-byte boundary, and working
    space past its code }
  DRIVER_CODE_SLACK = 606;

implementation

end.
