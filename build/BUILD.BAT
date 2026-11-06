@ECHO OFF
REM ==========================================================================
REM  Buck Rogers: Countdown to Doomsday v1.0 -- THE BUILD.
REM
REM  This file runs under DOS, calls Borland's TASM and TPC and Microsoft's
REM  EXEPACK, and emits the two files SSI shipped under their shipped names:
REM  START.EXE (linked as FIXMAIN.EXE, then packed) and GAME.OVR (written as
REM  FIXMAIN.OVR, then renamed). Those three tools produce every byte; no host
REM  program writes into either artifact.
REM
REM  The compiler switches are NOT here. They live in the tracked
REM  E:\SRC\TPC.CFG, which TPC reads from the current directory automatically,
REM  and one file cannot disagree with itself the way a config and a command
REM  line can. This batch therefore refuses if TPC.CFG is absent rather than
REM  compiling under TPC's defaults.
REM
REM  Every output -- the .OBJ, every .TPU, FIXMAIN.EXE/.MAP, GAME.OVR, START.EXE --
REM  goes to E:\OBJ, never E:\SRC, which holds tracked source and TPC.CFG
REM  only. gametools/build.sh creates E:\OBJ before calling this file.
REM
REM  Drive letters, assigned by the caller (gametools/build.sh) because only the
REM  host knows its own paths:
REM
REM      C:  drive_c (the game data)      E:  the version dir (v10)
REM      D:  TP 5.5 -- TPC.EXE, TURBO.TPL    F:  TASM
REM      G:  EXEPACK                       H:  this file's directory (v10/build)
REM ==========================================================================
E:
CD \SRC
PATH D:\

REM --- start from nothing --------------------------------------------------
REM  Every earlier output goes first, so a step that fails leaves nothing of an
REM  earlier build to be linked, packed or measured in place of its own.
IF EXIST E:\OBJ\*.TPU DEL E:\OBJ\*.TPU
IF EXIST E:\OBJ\*.OBJ DEL E:\OBJ\*.OBJ
IF EXIST E:\OBJ\FIXMAIN.EXE DEL E:\OBJ\FIXMAIN.EXE
IF EXIST E:\OBJ\FIXMAIN.OVR DEL E:\OBJ\FIXMAIN.OVR
IF EXIST E:\OBJ\GAME.OVR DEL E:\OBJ\GAME.OVR
IF EXIST E:\OBJ\FIXMAIN.MAP DEL E:\OBJ\FIXMAIN.MAP
IF EXIST E:\OBJ\START.EXE DEL E:\OBJ\START.EXE
REM  And in E:\SRC, the cwd: TPC also looks there for a .TPU, and for a {$L}
REM  object BEFORE /O..\OBJ, so a leftover is linked in place of the one TASM
REM  writes below.
IF EXIST *.TPU DEL *.TPU
IF EXIST *.OBJ DEL *.OBJ

REM --- the hand-written assembly units -------------------------------------
REM  SSI's own, reached from Pascal through {$L}. Each one assembles to the
REM  .OBJ the unit of the same name links in. Named outright, one line each:
REM  gametools/build.sh refuses if this list and v10/src/*.asm disagree.
F:\TASM BLIT,E:\OBJ\BLIT          > E:\BUILD\LOGS\TASM.OUT
F:\TASM JOYSTICK,E:\OBJ\JOYSTICK >> E:\BUILD\LOGS\TASM.OUT
F:\TASM SOUNDDRV,E:\OBJ\SOUNDDRV       >> E:\BUILD\LOGS\TASM.OUT
F:\TASM TEXTREND,E:\OBJ\TEXTREND >> E:\BUILD\LOGS\TASM.OUT
F:\TASM VGAFRAME,E:\OBJ\VGAFRAME >> E:\BUILD\LOGS\TASM.OUT

REM --- the compiler ---------------------------------------------------------
REM  Every byte-deciding switch comes from TPC.CFG, bare, one per line. /B
REM  rebuilds every unit, because make cannot see TPC.CFG. /E..\OBJ and
REM  /O..\OBJ are locations, not switches that decide a byte: /E is where TPC
REM  writes the EXE, OVR, MAP and every TPU, /O where it finds the .OBJ files
REM  TASM wrote above.
REM
REM  These lines are in this order because DOS opens a redirection before it
REM  evaluates the IF, so a false condition still truncates the file it names.
REM  TPC writes the log; the refusal APPENDS to what is then an empty one. An
REM  absent TPC.CFG must not compile under TPC's own defaults ($A+ word-aligns
REM  each typed constant larger than a byte, $S+ adds a stack check to every
REM  frame, and with no /L the whole-image link reports Error 1 at the root):
REM  that image is not this reconstruction, and build.sh reads a log matching
REM  neither pattern as nothing-was-measured.
IF EXIST TPC.CFG TPC FIXMAIN.PAS /B /E..\OBJ /O..\OBJ > E:\BUILD\LOGS\TPC.OUT
IF NOT EXIST TPC.CFG ECHO BUILD.BAT: E:\SRC\TPC.CFG is absent, so there is no >> E:\BUILD\LOGS\TPC.OUT
IF NOT EXIST TPC.CFG ECHO switch set and TPC was not run. Nothing was compiled. >> E:\BUILD\LOGS\TPC.OUT
REM  TPC names the overlay after the root; SSI shipped it as GAME.OVR.
REN E:\OBJ\FIXMAIN.OVR GAME.OVR

REM --- the container --------------------------------------------------------
REM  The shipped START.EXE is EXEPACK-packed, so the packer is in the byte
REM  path. This is Microsoft's own EXEPACK 4.06.
G:\EXEPACK E:\OBJ\FIXMAIN.EXE E:\OBJ\START.EXE > E:\BUILD\LOGS\EXEPACK.OUT
