{ Start-up and restart, for FixMain: InitializeGame once at start-up and ResetGameState after each game; both end in
  InitShipAndOrbit. InitializeGame starts the 16 colors from defaultPalette.

  The storage GameInit initializes is Mouse's state, Joystick's center, Crt's LastMode, the BIOS keyboard flags and the
  storage in GDVars. }
{$O+,F+,I-}
unit GameInit;

interface

{ Start-up: allocates and clears the game's buffers and zones, sets the palettes, the mouse and the default game state,
  and loads the font, tiles, icons, items and item templates. }
procedure InitializeGame;

{ Resets the game state for a restart after a game, keeping the buffers and what is loaded. The party starts facing
  east, and wall set slot 1 is reset to file 0. }
procedure ResetGameState;

implementation

uses Crt, Mouse, Blit, TextRend, Sym8x8, MapTiles, DaxIo, EffHndlr, EclMenu, SaveLoad, Types, C_Ecl, C_Map, C_Orbit,
  C_Pic, C_Side, GDConsts, GDVars, C_Dir, C_Ifc, C_Sound, C_Diff;

const
  { LoadShipData's ship type for the party's ship, the Maelstrom Rider: SHIPS record 50 }
  PARTY_SHIP_ID = 10;
  { the orbit at whose starting position the party's rocket begins }
  START_ORBIT = 2;
  { The glyphs gameFont's allocation holds. }
  FONT_GLYPHS = 177;
  { the WALLDEF banks wallDefs's allocation holds }
  WALL_BANKS = 3;
  { zone 0's messageSpeed at start-up and on ResetGameState }
  START_MESSAGE_SPEED = 4;

var

  { The BIOS keyboard shift-state byte. }
  biosKbdFlags: Byte absolute $0000: $0417;

{ Resets the menu colors and the combat and orbit state, loads the party's ship and places its rocket at the starting
  orbit position. }
procedure InitShipAndOrbit;
var
  oldDataSet: Byte;
begin
  GDVars.promptColor := LightMagenta;
  GDVars.menuColor := LightGreen;
  GDVars.highlightColor := White;
  GDVars.isTreatmentPending := False;
  GDVars.isShipRepairPending := False;
  GDVars.areaEffects := nil;
  GDVars.tacticsSides[C_Side.TEAM] := 0;
  GDVars.tacticsSides[C_Side.HOSTILE] := 0;
  GDVars.isIconEditorActive := False;
  GDVars.isVerticalMenuActive := False;
  GDVars.windowColor := 0;
  oldDataSet := GDVars.dataSet;
  GDVars.dataSet := 1;
  GDVars.partyShip := @GDVars.zone0^.partyShip;
  SaveLoad.LoadShipData(GDVars.partyShip, GameInit.PARTY_SHIP_ID);
  GDVars.dataSet := oldDataSet;
  GDVars.orbitView := nil;
  GDVars.orbitView := @GDVars.zone0^.orbit;
  with GDVars.orbitView^ do begin
    phase := 0;
    tick := 0;
    with GDConsts.orbitPositions[GDConsts.orbitStartPhases[GameInit.START_ORBIT] +
      GDConsts.orbitFirstPositions[GameInit.START_ORBIT]] do begin
      rocketX := x;
      rocketY := y;
      rocketIcon := C_Orbit.FIRST_ROCKET_ICON
    end
  end
end;

procedure InitializeGame;
var
  { Unused in this version; see the other implementations of this routine. }
  messageText: string;
begin
  for GDVars.index := 0 to SizeOf(GDConsts.defaultPalette) div SizeOf(Types.TRgb) - 1 do begin
    for GDVars.component := 0 to SizeOf(Types.TRgb) - 1 do
      GDVars.picturePalette[GDVars.index, GDVars.component] := GDConsts.defaultPalette[GDVars.index, GDVars.component];
    GDVars.paletteNibbles[GDVars.index] := GDVars.index
  end;
  for GDVars.index := 0 to 3 do
    GDVars.nibbleCgaColors[GDVars.index] := GDVars.index;
  Blit.ShadowPaletteEntries(0, 15, GDVars.combatPalette);
  Blit.ShadowPaletteEntries(0, 15, GDVars.viewPalette);
  Blit.SetDacPalette(0, 15, GDVars.picturePalette);
  { Num Lock on }
  biosKbdFlags := biosKbdFlags or $20;
  Randomize;
  if GDVars.isMouseOn then begin
    GDVars.canClickParty := True;
    GDVars.mouseButtons := 0;
    GDVars.mouseButtonState := 0;
    Mouse.InitMouse;
    if GDVars.isMouseOn then begin
      GDVars.isMouseScaled := True;
      if GDVars.displayMode = Types.VmCga then
        GDVars.mouseCursorMask := @GDConsts.cgaArrowCursor
      else
        GDVars.mouseCursorMask := @GDConsts.arrowCursor;
      Mouse.SetMouseCursor(0, 0, GDVars.mouseCursorMask);
      Mouse.SetMouse(639, 100);
      Mouse.GetMouse(GDVars.mBtn, GDVars.mX, GDVars.mY);
      GDVars.isMouseScaled := (GDVars.mX >= 321) = False;
      Mouse.ShowMouse;
    end;
    GDVars.mouseX := 160;
    GDVars.mouseY := 100;
    Mouse.SetMouse(GDVars.mouseX, GDVars.mouseY);
    GDVars.mouseOldX := 0;
    GDVars.mouseOldY := 0;
  end;
  if GDVars.isJoystickOn then begin
    GDVars.joystickCenterX := 160;
    GDVars.joystickCenterY := 100;
  end;
  GetMem(GDVars.zone0, SizeOf(Types.TZone0));
  GetMem(GDVars.zone1, SizeOf(Types.TZone1));
  GetMem(GDVars.zone2, SizeOf(Types.TZone2));
  GetMem(GDVars.zone3, SizeOf(Types.TZone3));
  { Note: LoadGameFont copies the whole of 8X8D1 record 201, 2048 bytes, into this 1416-byte block, so the last 632
    bytes spill into wallDefs's block, allocated next }
  GetMem(GDVars.gameFont, GameInit.FONT_GLYPHS * SizeOf(Types.TGlyph));
  GetMem(GDVars.wallDefs, GameInit.WALL_BANKS * SizeOf(Types.TWallDef));
  GetMem(GDVars.geoMap, SizeOf(Types.TGeoMap));
  Blit.AllocPic(8, 1, 1, 0, GDVars.tileScratch);
  Blit.AllocPic(8, 1, 1, 0, GDVars.savedWildernessCell);
  Blit.AllocPic(8, 1, 1, 0, GDVars.wildernessCursorCell);
  GDVars.cursorPicture := nil;
  Blit.AllocPic(200, 40, 1, 0, GDVars.viewPicture);
  Blit.AllocPic(24, 3, 1, 0, GDVars.saveUnder);
  FillChar(GDVars.dirtyRows, SizeOf(GDVars.dirtyRows), 0);
  FillChar(GDVars.dirtyRowLeft, SizeOf(GDVars.dirtyRowLeft), 0);
  FillChar(GDVars.dirtyRowFirst, SizeOf(GDVars.dirtyRowFirst), $FF);
  FillChar(GDVars.dirtyRowLast, SizeOf(GDVars.dirtyRowLast), 0);
  for GDVars.index := 0 to SizeOf(GDVars.cgaRowSegments) div SizeOf(Word) - 1 do begin
    if Odd(GDVars.index) then
      GDVars.cgaRowSegments[GDVars.index] := (GDVars.index div 2) * 5 + $BA00
    else
      GDVars.cgaRowSegments[GDVars.index] := (GDVars.index div 2) * 5 + $B800;
    GDVars.egaRowOffsets[GDVars.index] := GDVars.index * SizeOf(Types.TEgaRow);
    case GDVars.index mod 4 of
      0: GDVars.tandyRowSegments[GDVars.index] := (GDVars.index div 4) * 10 + $B800;
      1: GDVars.tandyRowSegments[GDVars.index] := (GDVars.index div 4) * 10 + $BA00;
      2: GDVars.tandyRowSegments[GDVars.index] := (GDVars.index div 4) * 10 + $BC00;
      3: GDVars.tandyRowSegments[GDVars.index] := (GDVars.index div 4) * 10 + $BE00;
    end;
  end;
  FillChar(GDVars.backdropPictures, SizeOf(GDVars.backdropPictures), 0);
  FillChar(GDVars.tileSets, SizeOf(GDVars.tileSets), 0);
  FillChar(GDVars.arenaTiles, SizeOf(GDVars.arenaTiles), 0);
  FillChar(GDVars.shipPictureBuffers, SizeOf(GDVars.shipPictureBuffers), 0);
  FillChar(GDVars.zone0^, SizeOf(Types.TZone0), 0);
  GDVars.zone0^.difficulty := C_Diff.DIFFICULTY_TROOPER;
  GDVars.zone0^.areaKind := 1;
  GDVars.zone0^.savedEclId := C_Ecl.NO_ECL_SCRIPT;
  FillChar(GDVars.zone1^, SizeOf(Types.TZone1), 0);
  FillChar(GDVars.zone2^, SizeOf(Types.TZone2), 0);
  FillChar(GDVars.zone3^, SizeOf(Types.TZone3), 0);
  FillChar(GDVars.iconFrames, SizeOf(GDVars.iconFrames), 0);
  for GDVars.index := 1 to SizeOf(GDVars.portraitSlots) div SizeOf(Types.TPortraitSlot) do begin
    GDVars.portraitSlots[GDVars.index].id := 255;
    GDVars.portraitSlots[GDVars.index].picture := nil
  end;
  FillChar(GDVars.displayCounter, SizeOf(Types.TDisplayCounter), 0);
  FillChar(GDVars.vgaAnimation, SizeOf(Types.TVgaAnimation), 0);
  FillChar(GDVars.imageFrames, SizeOf(GDVars.imageFrames), 0);
  FillChar(GDVars.portraitAnimation, SizeOf(GDVars.portraitAnimation), 0);
  GDVars.bigPicture := nil;
  GDVars.availableItems := nil;
  FillChar(GDVars.partyPosition, SizeOf(GDVars.partyPosition), 0);
  GDVars.partyPosition.mapX := 7;
  GDVars.partyPosition.mapY := 13;
  GDVars.partyPosition.facing := C_Dir.NORTH;
  FillChar(GDVars.doorOpen, SizeOf(GDVars.doorOpen), 1);
  FillChar(GDVars.wallSets, SizeOf(GDVars.wallSets), 0);
  GDVars.isGameUp := False;
  GDVars.combatDebugPassword := GDConsts.shipNames[2, 1];
  GDVars.areAnimationsEnabled := 1;
  GDVars.arePicturesEnabled := 1;
  GDVars.isDebugMode := False;
  GDVars.isMessageDelayed := True;
  GDVars.hasLoadedSave := 0;
  GDVars.restTicks := 0;
  GDVars.partyHead := nil;
  GDVars.currentCharacter := nil;
  GDVars.partyRowCharacter := nil;
  GDVars.eclIp := $8000;
  GDVars.zone0^.messageSpeed := GameInit.START_MESSAGE_SPEED;
  GDVars.isDemoRunning := False;
  GDVars.dataSet := 1;
  GDVars.previousDataSet := 1;
  GDVars.isAutomapOn := False;
  LastMode := CO40;
  GDVars.zone1^.partyCount := 0;
  GDVars.menuTop := 1;
  GDVars.isSoloCombat := False;
  GDVars.isCombatLineLowered := False;
  GDVars.zone1LoBit := 0;
  GDVars.eclDisplaying := 0;
  GDVars.isPictureShown := False;
  GDVars.isPartyDefeated := False;
  GDVars.clipFlag := 1;
  GDVars.isMonsterSpriteShown := False;
  GDVars.isDiskPromptSuppressed := 0;
  GDVars.cachedName[0] := #0;
  GDVars.savedPicArcName[0] := #0;
  GDVars.cachedAnimationId := C_Pic.NO_ANIMATION;
  GDVars.savedPicArcId := C_Pic.NO_ANIMATION;
  GDVars.isGameSaved := False;
  GDVars.horizonColorCode := $E8;
  GDVars.floorColorCode := $DB;
  GDVars.inEncounterMenu := 0;
  GDVars.isSelectorMode := False;
  GDVars.isMapVisible := True;
  GDVars.bigPictureId := C_Pic.NO_BIG_PICTURE;
  GDVars.isFreeTraining := False;
  GDVars.horizontalChoice := 1;
  GDVars.interfaceState := C_Ifc.VIEW_3D;
  GDVars.previousInterfaceState := 0;
  GDVars.overrideFlag := 0;
  GDVars.isBigPictureShown := False;
  GDVars.victoryStart := 0;
  GDVars.isInMoveMenu := False;
  GDVars.isCursorActive := False;
  GDVars.isMoveMode := False;
  GDVars.isMouseClick := False;
  GDVars.isModifyActive := False;
  GDVars.hasCenturyPassed := False;
  GDVars.isMusicOn := True;
  GDVars.savedSoundMode := C_Sound.DRIVER_NONE;
  GDVars.soundMode := C_Sound.DRIVER_NONE;
  GDVars.isDriverReady := False;
  GDVars.musicBank := nil;
  GDVars.musicBankSize := 0;
  TextRend.LoadGameFont;
  TextRend.DisplayLoading;
  Sym8x8.Load8x8Set(0, 6);
  Sym8x8.Load8x8Set(202, 4);
  Blit.ShadowPaletteEntries(C_Pic.VIEW_DAC_FIRST, C_Pic.VIEW_DAC_COUNT, GDVars.viewPalette);
  Blit.SetDacPalette(C_Pic.VIEW_DAC_FIRST, C_Pic.VIEW_DAC_COUNT, GDVars.picturePalette);
  for GDVars.index := 1 to 25 do
    MapTiles.LoadIconAnim('COMSPR', GDVars.index, GDVars.index + 13 - 1);
  Blit.ShadowPaletteEntries($40, 32, GDVars.combatPalette);
  Blit.LoadPic('cursor', 1, True, C_Pic.KEY_COLOR, GDVars.cursorPicture);
  GDVars.hasOpenedItems := DaxIo.OpenWithRetry('ITEMS', GDConsts.diskPrompts[GDVars.dataSet], 0, GDVars.itemsFile);
  Reset(GDVars.itemsFile, 1);
  { asks for all 129 rows of itemTypes; ITEMS holds 39 (351 bytes), and a BlockRead that returns its count stops short
    there without an I/O error }
  BlockRead(GDVars.itemsFile, GDVars.itemTypes, SizeOf(GDVars.itemTypes), GDVars.itemsRead);
  Close(GDVars.itemsFile);
  EffHndlr.InitEffectHandlers;
  EclMenu.LoadItemTemplates;
  GDVars.enemyShip := nil;
  GDVars.areOrbitPicturesLoaded := False;
  GDVars.areShipPictureBuffersLoaded := False;
  GameInit.InitShipAndOrbit;
end;

procedure ResetGameState;
begin
  GDVars.isGameUp := True;
  FillChar(GDVars.dirtyRows, SizeOf(GDVars.dirtyRows), 0);
  FillChar(GDVars.dirtyRowLeft, SizeOf(GDVars.dirtyRowLeft), 0);
  FillChar(GDVars.dirtyRowFirst, SizeOf(GDVars.dirtyRowFirst), $FF);
  FillChar(GDVars.dirtyRowLast, SizeOf(GDVars.dirtyRowLast), 0);
  FillChar(GDVars.zone0^, SizeOf(Types.TZone0), 0);
  GDVars.zone0^.difficulty := C_Diff.DIFFICULTY_TROOPER;
  GDVars.zone0^.areaKind := 1;
  GDVars.zone0^.savedEclId := C_Ecl.NO_ECL_SCRIPT;
  FillChar(GDVars.zone1^, SizeOf(Types.TZone1), 0);
  FillChar(GDVars.zone2^, SizeOf(Types.TZone2), 0);
  FillChar(GDVars.zone3^, SizeOf(Types.TZone3), 0);
  FillChar(GDVars.partyPosition, SizeOf(GDVars.partyPosition), 0);
  GDVars.partyPosition.mapX := 7;
  GDVars.partyPosition.mapY := 13;
  GDVars.partyPosition.facing := C_Dir.EAST;
  FillChar(GDVars.doorOpen, SizeOf(GDVars.doorOpen), 1);
  GDVars.canClickParty := True;
  GDVars.wallSets[1].fileId := 0;
  GDVars.wallSets[1].slot := 1;
  for GDVars.index := 2 to 3 do begin
    GDVars.wallSets[GDVars.index].fileId := C_Map.NO_WALL_SET_FILE;
    GDVars.wallSets[GDVars.index].slot := C_Map.NO_WALL_SET_SLOT;
  end;
  GDVars.isDebugMode := False;
  GDVars.isMessageDelayed := True;
  GDVars.hasLoadedSave := 0;
  GDVars.restTicks := 0;
  GDVars.partyHead := nil;
  GDVars.currentCharacter := nil;
  GDVars.partyRowCharacter := nil;
  GDVars.eclIp := $8000;
  GDVars.zone0^.messageSpeed := GameInit.START_MESSAGE_SPEED;
  GDVars.dataSet := 1;
  GDVars.previousDataSet := 1;
  GDVars.isAutomapOn := False;
  LastMode := CO40;
  GDVars.zone1^.partyCount := 0;
  GDVars.menuTop := 1;
  GDVars.isSoloCombat := False;
  GDVars.isCombatLineLowered := False;
  GDVars.zone1LoBit := 0;
  GDVars.eclDisplaying := 0;
  GDVars.isPictureShown := False;
  GDVars.isPartyDefeated := False;
  GDVars.clipFlag := 1;
  GDVars.isMonsterSpriteShown := False;
  GDVars.isDiskPromptSuppressed := 0;
  GDVars.cachedName[0] := #0;
  GDVars.savedPicArcName[0] := #0;
  GDVars.cachedAnimationId := C_Pic.NO_ANIMATION;
  GDVars.savedPicArcId := C_Pic.NO_ANIMATION;
  GDVars.isGameSaved := False;
  GDVars.horizonColorCode := $E8;
  GDVars.floorColorCode := $DB;
  GDVars.inEncounterMenu := 0;
  GDVars.isMapVisible := True;
  GDVars.bigPictureId := C_Pic.NO_BIG_PICTURE;
  GDVars.isFreeTraining := False;
  TextRend.ClearStatusLine;
  GDVars.horizontalChoice := 1;
  GDVars.interfaceState := C_Ifc.VIEW_3D;
  GDVars.previousInterfaceState := 0;
  GDVars.overrideFlag := 0;
  GDVars.victoryStart := 0;
  GDVars.isInMoveMenu := False;
  GDVars.isCursorActive := False;
  GDVars.isMoveMode := False;
  GDVars.isMouseClick := False;
  GDVars.isSelectorMode := False;
  GDVars.isModifyActive := False;
  GDVars.isBigPictureShown := False;
  GDVars.hasCenturyPassed := False;
  GameInit.InitShipAndOrbit;
end;

begin
end.
