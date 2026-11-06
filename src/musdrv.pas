{ Calls into the music driver that Music loads from MUSIC.dax, a .COM-style program entered at 100h. The driver's entry
  point, the music bank's address and the result of the last call are kept in GDVars. }
{$F+,O-,S-,R-,V-,B-,I-,A+}
unit MusDrv;

interface

{ Calls the driver's dispatch entry with a function code and a far argument; returns its status. Codes used: 0 install
  (StartDriver), 1 start (StartPlayback), 3 stop (StopHook).
  @param(func Driver function code.)
  @param(offset Offset of the far argument.)
  @param(segment Segment of the far argument.)
  @returns(The driver's status.) }
function DriverCall(func, offset, segment: Word): Word;

{ Releases the driver's code and musicBank and clears isDriverReady. }
procedure FreeDriver;

{ Makes the loaded driver the one sound commands go to: sets soundMode to C_Sound.DRIVER_LOADED, saves port $61 and
  calls driver function 0 with the music bank. Halts unless codePtr's offset is a multiple of 16.
  @param(codePtr The driver code, alignedDriverCode, which Music sets.)
  @param(bankPtr The music bank, musicBank, which Music loads.) }
procedure StartDriver(codePtr, bankPtr: Pointer);

{ Passes command 2 to the driver as function 1, and ignores every other command.
  @param(command The sound command.) }
procedure StartPlayback(command: Word);

{ Stops the driver if it is started: marks it stopped, restores the speaker gate and calls driver function 3. }
procedure StopHook;

implementation

uses Types, GDConsts, GDVars, C_Sound;

function DriverCall(func, offset, segment: Word): Word;
begin
  DriverCall := GDVars.driverEntry(segment, offset, func)
end;

procedure FreeDriver;
var
  { Unused in this version; see the other implementations of this routine. }
  codeSize: Word;
begin
  FreeMem(GDVars.driverCode, GDVars.driverCodeSize + C_Sound.DRIVER_CODE_SLACK);
  FreeMem(GDVars.musicBank, GDVars.musicBankSize);
  GDVars.isDriverReady := False
end;

procedure StartDriver(codePtr, bankPtr: Pointer);
var codeAddress: LongInt absolute codePtr;
begin
  GDVars.soundMode := C_Sound.DRIVER_LOADED;
  GDVars.savedPort61 := Port[$61];
  if Byte(codeAddress and $F) <> 0 then Halt(0);
  Inc(codeAddress, $100);
  { the same address, 100h further into a segment 10h paragraphs lower: a .COM entry }
  Dec(codeAddress, $100000);
  @GDVars.driverEntry := codePtr;
  Move(bankPtr, GDVars.bankCopy, SizeOf(GDVars.bankCopy));
  GDVars.bankOffset := GDVars.bankCopy.ofs;
  GDVars.bankSegment := GDVars.bankCopy.seg;
  GDVars.driverResult := MusDrv.DriverCall(0, GDVars.bankOffset, GDVars.bankSegment)
end;

procedure StartPlayback(command: Word);
begin
  if command <> 2 then Exit;
  Dec(command, 2);
  GDVars.driverResult := MusDrv.DriverCall(1, 0, 0)
end;

procedure StopHook;
begin
  if GDVars.soundMode = C_Sound.DRIVER_LOADED then begin
    GDVars.soundMode := C_Sound.DRIVER_NONE;
    Port[$61] := GDVars.savedPort61;
    GDVars.driverResult := MusDrv.DriverCall(3, 0, 0)
  end
end;

begin
end.
