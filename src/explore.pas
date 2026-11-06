{ Moving the party in the 3-D view, the wilderness and the orbit map; the map main menu, with its change, party-order,
  level and message-speed menus; and the rest menu. NoopExploreA to NoopExploreE are empty placeholders. Its menu lines,
  the message-speed words and the orbit-map steps are in GDConsts. }
{$O+,F+,V-}
unit Explore;

interface

{ Makes the move the map menu chose, by interfaceState: a step ahead in C_Ifc.VIEW_3D, a wilderness step in
  C_Ifc.WILDERNESS or a rocket move in C_Ifc.ORBIT_MAP. A moveBlocked of 255 cancels it once instead. }
procedure ResolveMovement;

{ Runs the main menu of the 3-D view (C_Ifc.VIEW_3D), the orbit map (C_Ifc.ORBIT_MAP) or the wilderness
  (C_Ifc.WILDERNESS), with each one's move mode; on the way out it clears the text window while the bottom line is not
  marked clear.
  @returns(In the 3-D view the menu's last key, or #0 after a step or turn; on the orbit map 'M', the only key that ends
    its menu, but in move mode no key is read and the result is left unset; in the wilderness the last key, or a keypad
    key after a click.) }
function MapMainMenu: Char;

{ The rest menu: each Rest is GameTime's RestAndHeal(1), a day on the clock and a hit point for each okay or unconscious
  member, until Exit. }
procedure RestMenu;

{ Empty routine with no callers. }
procedure NoopExploreA;

{ Empty routine with no callers. }
procedure NoopExploreB;

{ Empty routine with no callers. }
procedure NoopExploreC;

{ Empty routine with no callers. }
procedure NoopExploreD;

{ Empty routine with no callers. }
procedure NoopExploreE;

implementation

uses View3D, Music, Crt, GameTime, Mouse, MapCurs, CharHlp, MenuCore, TextRend, SaveLoad, ViewChar, Blit, CharGen,
  GameIo, OrbitMap, CbtMap, Portrait, Types, C_Msg, C_Orbit, C_Search, GDConsts, GDVars,
  C_Dir, C_Sys, C_Ifc, C_Diff, C_Keys, C_Menu, C_Time;

const
  { GameTime's clock unit of ten minutes, which a step while searching and Look advance the clock by }
  TIME_TURN = 2;
  { GameTime's clock unit of an hour; a wilderness step advances the clock twelve of them }
  TIME_HOUR = 3;
  { TOrbitView.rocketIcon at heading 7, the rocket's last tile }
  LAST_ROCKET_ICON = 94;
  { zone 1's searchFlags bit: Look asks EclVm's GameLoop for one run of the search entry point }
  LOOK_PENDING = 2;
  { phase counts down through 0..PHASE_CYCLE - 1 and wraps }
  PHASE_CYCLE = 224;

{ Checks the step ahead: when the facing side has a barrier and the step would leave the 16 by 16 map, pins the party to
  that edge and sets zone 1's hasLeftMap. It does not move the party; ResolveMovement's MovePartyForward3D does. }
procedure MoveForward;
var
  nx: Integer;
  ny: Integer; face: Word;
begin
  nx := GDVars.partyPosition.mapX;
  ny := GDVars.partyPosition.mapY;
  face := GDVars.partyPosition.facing;
  GDVars.zone1^.hasLeftMap := 0;
  if View3D.GetBarrierType(nx, ny, face) <> 0 then begin
    Inc(nx, GDConsts.dirStepX[face]);
    Inc(ny, GDConsts.dirStepY[face]);
    if nx > SizeOf(GDVars.geoMap^.wallsNE[0]) - 1 then begin
      GDVars.partyPosition.mapX := SizeOf(GDVars.geoMap^.wallsNE[0]) - 1;
      GDVars.zone1^.hasLeftMap := 1
    end;
    if nx < 0 then begin GDVars.partyPosition.mapX := 0; GDVars.zone1^.hasLeftMap := 1 end;
    if ny > SizeOf(GDVars.geoMap^.wallsNE) div SizeOf(GDVars.geoMap^.wallsNE[0]) - 1 then begin
      GDVars.partyPosition.mapY := SizeOf(GDVars.geoMap^.wallsNE) div SizeOf(GDVars.geoMap^.wallsNE[0]) - 1;
      GDVars.zone1^.hasLeftMap := 1
    end;
    if ny < 0 then begin GDVars.partyPosition.mapY := 0; GDVars.zone1^.hasLeftMap := 1 end
  end
end;

{ Steps the party ahead with the step sound, wrapping at the map's edges, refreshes the wall-ahead and event bytes,
  resets doorOpen, and advances the clock a turn while searching, else a minute. }
procedure MovePartyForward3D;
begin
  Music.SendSoundCommand(GDConsts.stepSound);
  Delay(50);
  Inc(GDVars.partyPosition.mapX, GDConsts.dirStepX[GDVars.partyPosition.facing]);
  Inc(GDVars.partyPosition.mapY, GDConsts.dirStepY[GDVars.partyPosition.facing]);
  if GDVars.partyPosition.mapX < 0 then GDVars.partyPosition.mapX := SizeOf(GDVars.geoMap^.wallsNE[0]) - 1;
  if GDVars.partyPosition.mapX > SizeOf(GDVars.geoMap^.wallsNE[0]) - 1 then GDVars.partyPosition.mapX := 0;
  if GDVars.partyPosition.mapY < 0 then
    GDVars.partyPosition.mapY := SizeOf(GDVars.geoMap^.wallsNE) div SizeOf(GDVars.geoMap^.wallsNE[0]) - 1;
  if GDVars.partyPosition.mapY > SizeOf(GDVars.geoMap^.wallsNE) div SizeOf(GDVars.geoMap^.wallsNE[0]) - 1 then
    GDVars.partyPosition.mapY := 0;
  GDVars.partyPosition.wallAhead := View3D.GetWallType(GDVars.partyPosition.mapX, GDVars.partyPosition.mapY,
                                                         GDVars.partyPosition.facing);
  FillChar(GDVars.doorOpen, SizeOf(GDVars.doorOpen), 1);
  GDVars.partyPosition.mapEvent := View3D.GetMapEvent(GDVars.partyPosition.mapX, GDVars.partyPosition.mapY);
  if GDVars.zone1^.searchFlags and C_Search.SEARCHING > 0 then GameTime.AdvanceTime(1, Explore.TIME_TURN)
  else GameTime.AdvanceTime(1, C_Time.MINUTES)
end;

{ Moves the wilderness cursor one step along the facing, held to columns 0..37 and rows 0..14, and advances the clock 12
  hours. }
procedure MovePartyWilderness;
var
  { Unused in this version; see the other implementations of this routine. }
  col: Byte;
  nx: ShortInt;
  ny: ShortInt;
begin
  Mouse.HideMouse;
  MapCurs.RestoreCursorBackground;
  GDVars.zone0^.previousX := GDVars.zone0^.wildernessX;
  GDVars.zone0^.previousY := GDVars.zone0^.wildernessY;
  nx := GDVars.zone0^.wildernessX + GDConsts.dirStepX[GDVars.partyPosition.facing];
  ny := GDVars.zone0^.wildernessY + GDConsts.dirStepY[GDVars.partyPosition.facing];
  if nx < 0 then nx := 0;
  if nx > 37 then nx := 37;
  if ny < 0 then ny := 0;
  if ny > 14 then ny := 14;
  GDVars.zone0^.wildernessX := nx;
  GDVars.zone0^.wildernessY := ny;
  MapCurs.DrawCursor;
  Mouse.ShowMouse;
  GameTime.AdvanceTime(12, Explore.TIME_HOUR)
end;

{ Sets zone 0's difficulty from the level menu; a cursor key steps the current character instead. }
procedure CampDifficultyMenu;
var difficulty: Byte;
begin
  difficulty := GDVars.zone0^.difficulty;
  GDVars.horizontalChoice := difficulty + 1;
  GDVars.menuChecksum := C_Menu.KEEP_MENU_CHOICE;
  MenuCore.MenuHorizontal('', GDConsts.difficultyMenu, False, True);
  if GDVars.isExtendedKey then begin
    CharHlp.DisplayRoster(GDVars.currentCharacter, False);
    ViewChar.SelectPrevNextChar(GDVars.menuKey);
    CharHlp.DisplayRoster(GDVars.currentCharacter, True)
  end else
    case GDVars.menuKey of
      'N': difficulty := C_Diff.DIFFICULTY_NOVICE;
      'C': difficulty := C_Diff.DIFFICULTY_CADET;
      'T': difficulty := C_Diff.DIFFICULTY_TROOPER;
      'V': difficulty := C_Diff.DIFFICULTY_VETERAN;
      'A': difficulty := C_Diff.DIFFICULTY_ACE
    end;
  GDVars.zone0^.difficulty := difficulty
end;

{ Shows the message speed with its word, and makes it faster or slower (also by the down and up keys) until Exit. }
procedure CampSpeedMenu;
var menuText: Types.TString40;
begin
  TextRend.ClearTextWindow;
  repeat
    GDVars.textLeft := GDVars.windowLeft;
    GDVars.windowTextRow := GDVars.windowTop;
    TextRend.DisplayWindowText(Black, '');
    TextRend.DisplayWindowText(LightGreen,
                               'Message Speed = ' + TextRend.ByteToString(GDVars.zone0^.messageSpeed) + ' (' +
                               GDConsts.speedWords[GDConsts.speedWordCodes[GDVars.zone0^.messageSpeed] shr 4] +
                               GDConsts.speedSuffixes[GDConsts.speedWordCodes[GDVars.zone0^.messageSpeed] and 3] +
                               ')   ');
    menuText := '';
    if GDVars.zone0^.messageSpeed > 0 then menuText := menuText + ' Faster';
    if GDVars.zone0^.messageSpeed < C_Msg.SLOWEST_MESSAGE_SPEED then menuText := menuText + ' Slower';
    menuText := menuText + ' Exit';
    MenuCore.MenuHorizontal('Message Speed:', menuText, False, True);
    if GDVars.isExtendedKey then
      case GDVars.menuKey of
        C_Keys.DOWN: if GDVars.zone0^.messageSpeed > 0 then Dec(GDVars.zone0^.messageSpeed);
        C_Keys.UP: if GDVars.zone0^.messageSpeed <
          C_Msg.SLOWEST_MESSAGE_SPEED then Inc(GDVars.zone0^.messageSpeed)
      end else
      case GDVars.menuKey of
        'F': Dec(GDVars.zone0^.messageSpeed);
        'S': Inc(GDVars.zone0^.messageSpeed)
      end
  until GDVars.menuKey in [C_Keys.NONE, 'E'];
  TextRend.ClearTextWindow
end;

{ Moves currentCharacter one place up the party list; from the top it goes to the bottom. }
procedure OrderMoveUp;
var
  prev: Types.PCharacter;
  p: Types.PCharacter;
  nxt: Types.PCharacter;
begin
  p := GDVars.partyHead;
  prev := nil;
  if p = GDVars.currentCharacter then
    while p^.next <> nil do p := p^.next
  else
    while p^.next <> GDVars.currentCharacter do begin prev := p; p := p^.next end;
  nxt := GDVars.currentCharacter^.next;
  if GDVars.partyHead = GDVars.currentCharacter then begin
    if nxt <> nil then GDVars.partyHead := nxt;
    p^.next := GDVars.currentCharacter;
    GDVars.currentCharacter^.next := nil
  end else begin
    p^.next := nxt;
    GDVars.currentCharacter^.next := p;
    if (p = GDVars.partyHead) or (prev = nil) then GDVars.partyHead := GDVars.currentCharacter
    else prev^.next := GDVars.currentCharacter
  end
end;

{ Moves currentCharacter one place down the party list; from the bottom it goes to the top. }
procedure OrderMoveDown;
var
  p: Types.PCharacter;
  nxt: Types.PCharacter;
begin
  p := GDVars.partyHead;
  if p <> GDVars.currentCharacter then
    while p^.next <> GDVars.currentCharacter do p := p^.next;
  nxt := GDVars.currentCharacter^.next;
  if nxt = nil then begin
    GDVars.currentCharacter^.next := GDVars.partyHead;
    GDVars.partyHead := GDVars.currentCharacter;
    p^.next := nxt
  end else begin
    GDVars.currentCharacter^.next := nxt^.next;
    if GDVars.partyHead = GDVars.currentCharacter then GDVars.partyHead := nxt;
    if p <> GDVars.currentCharacter then p^.next := nxt;
    nxt^.next := GDVars.currentCharacter
  end
end;

{ Runs the party-order menu: a member is picked with Select or a click, then moved with the up and down keys, or put
  ahead of another member by clicking that one. Ends on Exit. }
procedure PartyOrderMenu;
var selected: ShortInt; savedCurChar: Types.PCharacter; p: Types.PCharacter;
begin
  selected := 0;
  GDVars.menuKey := ' ';
  GDVars.isInPartyOrderMenu := True;
  while not (GDVars.menuKey in [C_Keys.NONE, 'E']) do begin
    savedCurChar := GDVars.currentCharacter;
    MenuCore.MenuHorizontal('Party Order: ', GDConsts.partyOrderMenus[selected], True, True);
    if savedCurChar <> GDVars.currentCharacter then begin
      selected := Ord(selected = 0);
      if selected <> 0 then
        CharHlp.PrintCreatureMessage(GDVars.currentCharacter, 'has been selected', 10, False)
      else begin
        if (savedCurChar <> nil) and (GDVars.currentCharacter <> nil) then begin
          if savedCurChar = GDVars.partyHead then GDVars.partyHead := savedCurChar^.next
          else begin
            p := GDVars.partyHead;
            while (p^.next <> savedCurChar) and (p <> nil) do p := p^.next;
            if p^.next = savedCurChar then p^.next := savedCurChar^.next
            else TextRend.DisplayValue('lost pc in alterpartyorder', 0)
          end;
          savedCurChar^.next := GDVars.currentCharacter;
          if GDVars.currentCharacter = GDVars.partyHead then GDVars.partyHead := savedCurChar
          else begin
            p := GDVars.partyHead;
            while (p^.next <> GDVars.currentCharacter) and (p <> nil) do p := p^.next;
            if p^.next = GDVars.currentCharacter then p^.next := savedCurChar
            else TextRend.DisplayValue('lost olddude in alterpartyorder', 0)
          end
        end;
        MenuCore.DisplayParty(GDVars.currentCharacter)
      end
    end else if GDVars.isExtendedKey then begin
      if selected = 0 then begin
        CharHlp.DisplayRoster(GDVars.currentCharacter, False);
        ViewChar.SelectPrevNextChar(GDVars.menuKey);
        CharHlp.DisplayRoster(GDVars.currentCharacter, True)
      end else begin
        case GDVars.menuKey of C_Keys.UP: Explore.OrderMoveUp; C_Keys.DOWN: Explore.OrderMoveDown end;
        MenuCore.DisplayParty(GDVars.currentCharacter)
      end
    end else if GDVars.menuKey in [C_Keys.ENTER, 'P', 'S'] then begin
      selected := Ord(selected = 0);
      if selected <> 0 then CharHlp.PrintCreatureMessage(GDVars.currentCharacter, 'has been selected', 10, False)
      else CharHlp.ClearMessageWindow
    end
  end;
  GDVars.isInPartyOrderMenu := False;
  CharHlp.ClearMessageWindow
end;

{ The Change menu: party order and purge (not on the orbit map), message speed, the animation switch and the difficulty
  level, until Exit; a cursor key steps the current character. }
procedure CampAlterMenu;
var choice: Char;
    { Unused in this version; see the other implementations of this routine. }
    toggleChoice: Byte;
    menuText: Types.TString40;
begin
  choice := ' ';
  while not (choice in [C_Keys.NONE, 'E']) do begin
    if GDVars.interfaceState = C_Ifc.ORBIT_MAP then menuText := '' else menuText := GDConsts.changeMenuHead;
    MenuCore.MenuHorizontal('', menuText + GDConsts.changeMenuTail, False, True);
    choice := GDVars.menuKey;
    if GDVars.isExtendedKey then begin
      CharHlp.DisplayRoster(GDVars.currentCharacter, False);
      ViewChar.SelectPrevNextChar(choice);
      CharHlp.DisplayRoster(GDVars.currentCharacter, True)
    end else
      case choice of
        'O': Explore.PartyOrderMenu;
        'P': CharGen.DropCharacterMenu;
        'M': Explore.CampSpeedMenu;
        'A': begin
          GDVars.areAnimationsEnabled := Ord(GDVars.areAnimationsEnabled = 0);
          if GDVars.areAnimationsEnabled <> 0 then CharHlp.PrintBottomLine('Animation on')
          else CharHlp.PrintBottomLine('Animation off')
        end;
        'L': Explore.CampDifficultyMenu
      end
  end
end;

{ Reads one rocket move on the orbit map, by key or click, and makes it: turns the rocket to the heading, steps it
  (never onto the center body), rests the team three days and, each time the tick reaches 32, moves the bodies on a
  phase.
  @param(isFromMenu True, the map menu's call in move mode, returns at once.) }
procedure MoveRocket(isFromMenu: Boolean);
var
  target: Byte;
  dir: Byte;
  ticks: Byte; step: ShortInt;
    { Unused in this version; see the other implementations of this routine. }
    distanceText: array[0..3] of Byte;
    fuelText: String[4];
    { Unused in this version; see the other implementations of this routine. }
    heading: Byte;
begin
  if isFromMenu then Exit;
  with GDVars.orbitView^ do begin
  GDVars.savedCursorX := rocketX;
  GDVars.savedCursorY := rocketY;
  Str(GDVars.partyShip^.systemStatus[C_Sys.FUEL]:0, fuelText);
  MenuCore.MenuHorizontal('En route. Fuel = ' + fuelText + ' ', 'Done', True, False);
  target := C_Dir.CENTER;
  case GDVars.menuKey of
    C_Keys.PAGE_UP: target := 7; C_Keys.UP: target := 0; C_Keys.PAGE_DOWN: target :=
      5; C_Keys.RIGHT: target := 6;
    C_Keys.END_KEY: target := 3; C_Keys.DOWN: target := 4; C_Keys.HOME: target :=
      1; C_Keys.LEFT: target := 2;
    { Note: meant as Escape, which MenuHorizontal answers as C_Keys.NONE }
    'D', C_Keys.NONE, C_Keys.ENTER, C_Keys.RIGHT_BRACKET:
      if GDVars.isMouseClick and (GDVars.mouseY <= 176) and
          (GDVars.mouseX >= C_Orbit.MAP_LEFT * 8) then begin
        target := CbtMap.DirectionBetween(rocketX, rocketY, GDVars.mouseX div 8 - C_Orbit.MAP_LEFT,
                                          GDVars.mouseY div 8 - C_Orbit.MAP_TOP);
        { DirectionBetween counts clockwise, mapStepX counterclockwise }
        target := (-target) and 7
      end else GDVars.isMoveMode := False
  end;
  if target < C_Dir.CENTER then begin
    Mouse.HideMouse;
    dir := target + C_Orbit.FIRST_ROCKET_ICON;
    if ((dir < rocketIcon) and (dir >= rocketIcon - 4)) or (dir >= rocketIcon + 4) then step := -1 else step := 1;
    while rocketIcon <> dir do begin
      Inc(rocketIcon, step);
      if rocketIcon < C_Orbit.FIRST_ROCKET_ICON then rocketIcon := Explore.LAST_ROCKET_ICON
      else if rocketIcon > Explore.LAST_ROCKET_ICON then rocketIcon := C_Orbit.FIRST_ROCKET_ICON;
      OrbitMap.RedrawOrbitCursor;
      Delay(100)
    end;
    Inc(rocketX, GDConsts.mapStepX[target]);
    if rocketX = 255 then rocketX := 0
    else if rocketX > 21 then rocketX := 21;
    Inc(rocketY, GDConsts.mapStepY[target]);
    if rocketY = 255 then rocketY := 0
    else if rocketY > 21 then rocketY := 21;
    if (rocketX = C_Orbit.CENTER_X) and (rocketY = C_Orbit.CENTER_Y) then begin
      Dec(rocketX, GDConsts.mapStepX[target]);
      Dec(rocketY, GDConsts.mapStepY[target])
    end;
    OrbitMap.RedrawOrbitCursor;
    ticks := 3;
    Inc(tick, ticks);
    GameTime.RestAndHeal(3);
    if tick > 32 - 1 then begin
      Dec(tick, 32);
      if phase = 0 then phase := Explore.PHASE_CYCLE;
      Dec(phase);
      OrbitMap.PaintOrbitMap
    end;
    Mouse.ShowMouse
  end
  end
end;

{ Saves the game, then offers to quit to DOS. }
procedure SaveQuit;
begin
  SaveLoad.SaveGame;
  GDVars.promptColor := Yellow;
  if MenuCore.YesNoMenu('Quit TO DOS ', C_Menu.DEFAULT_NO) = 'Y' then GameIo.ExitGame
end;

function MapMainMenu: Char;
var isDone: Boolean; c: Char;
    { Unused in this version; see the other implementations of this routine. }
    ext: Byte;
    { Unused in this version; see the other implementations of this routine. }
    menuText: array[0..39] of Byte;
    { ViewCharMenu's hasEndedTurn, which MapMainMenu ignores }
    isSheetDone: Boolean;
    { Unused in this version; see the other implementations of this routine. }
    oldZone: Pointer;
    { Unused in this version; see the other implementations of this routine. }
    savedZone: Pointer;
    { Unused in this version; see the other implementations of this routine. }
    savedOrbit: Pointer;
begin
  GDVars.zone1^.moveBlocked := 0;
  case GDVars.interfaceState of
    C_Ifc.VIEW_3D: begin
      isDone := False;
      c := C_Keys.NONE;
      repeat
        if not GDVars.isMoveMode then begin
          GDVars.canClickParty := True;
          MenuCore.MenuHorizontal('', GDConsts.dungeonMenu, True, True);
          GDVars.canClickParty := False;
          c := GDVars.menuKey;
          if not GDVars.isExtendedKey then
            case c of
              'M': begin TextRend.ClearStatusLine; GDVars.isMoveMode := True end;
              'A': if GDVars.zone0^.isAutomapLocked = 0 then begin
                     GDVars.isAutomapOn := not GDVars.isAutomapOn;
                     View3D.Display3DMapView(GDVars.partyPosition.mapX, GDVars.partyPosition.mapY,
                                             GDVars.partyPosition.facing)
                   end else begin
                     TextRend.PrintAndPause('Not Here', Yellow, Black);
                     CharHlp.PrintMiscInfo
                   end;
              'V': begin ViewChar.ViewCharMenu(isSheetDone);
                         CharHlp.DisplayNoncombatInterface end;
              'S': Explore.SaveQuit;
              'C': Explore.CampAlterMenu;
              'L': begin
                GDVars.zone1^.searchFlags := GDVars.zone1^.searchFlags or Explore.LOOK_PENDING;
                CharHlp.PrintMiscInfo;
                GameTime.AdvanceTime(1, Explore.TIME_TURN);
                GDVars.eclIp := GDVars.eclEntryPoints[2];
                isDone := True
              end
            end else begin
            CharHlp.DisplayRoster(GDVars.currentCharacter, False);
            ViewChar.SelectPrevNextChar(c);
            CharHlp.DisplayRoster(GDVars.currentCharacter, True);
            CharHlp.PrintMiscInfo
          end
        end else begin
          MenuCore.MenuHorizontal('', 'Exit', True, False);
          c := GDVars.menuKey;
          if not GDVars.isExtendedKey then begin
            case c of 'E': GDVars.isMoveMode := False end
          end else begin
            case c of
              C_Keys.UP: begin Explore.MoveForward; isDone := True; CharHlp.PrintMiscInfo; c :=
                C_Keys.NONE end;
              C_Keys.DOWN: begin
                GDVars.partyPosition.facing := (GDVars.partyPosition.facing + 4) mod 8;
                GDVars.partyPosition.wallAhead := View3D.GetWallType(GDVars.partyPosition.mapX,
                                                                       GDVars.partyPosition.mapY,
                                                                       GDVars.partyPosition.facing);
                View3D.Display3DMapView(GDVars.partyPosition.mapX, GDVars.partyPosition.mapY,
                                        GDVars.partyPosition.facing);
                CharHlp.PrintMiscInfo; c := C_Keys.NONE
              end;
              C_Keys.LEFT: begin
                GDVars.partyPosition.facing := (GDVars.partyPosition.facing + 6) mod 8;
                Music.SendSoundCommand(GDConsts.stepSound);
                GDVars.partyPosition.wallAhead := View3D.GetWallType(GDVars.partyPosition.mapX,
                                                                       GDVars.partyPosition.mapY,
                                                                       GDVars.partyPosition.facing);
                View3D.Display3DMapView(GDVars.partyPosition.mapX, GDVars.partyPosition.mapY,
                                        GDVars.partyPosition.facing);
                CharHlp.PrintMiscInfo; c := C_Keys.NONE
              end;
              C_Keys.RIGHT: begin
                GDVars.partyPosition.facing := (GDVars.partyPosition.facing + 2) mod 8;
                Music.SendSoundCommand(GDConsts.stepSound);
                GDVars.partyPosition.wallAhead := View3D.GetWallType(GDVars.partyPosition.mapX,
                                                                       GDVars.partyPosition.mapY,
                                                                       GDVars.partyPosition.facing);
                View3D.Display3DMapView(GDVars.partyPosition.mapX, GDVars.partyPosition.mapY,
                                        GDVars.partyPosition.facing);
                CharHlp.PrintMiscInfo; c := C_Keys.NONE
              end
            end;
          end
        end
      until isDone or GDVars.isPartyDefeated
    end;
    C_Ifc.ORBIT_MAP: if GDVars.isMoveMode then Explore.MoveRocket(True) else begin
      repeat
        MenuCore.MenuHorizontal('', 'Move Rocket Change Save', False, True);
        c := GDVars.menuKey;
        if GDVars.isExtendedKey then c := C_Keys.NONE
        else
          case c of
            'M': GDVars.isMoveMode := True;
            'R': begin
              GDVars.interfaceState := C_Ifc.SHIP;
              OrbitMap.LoadShipPictures; CharHlp.DisplayNoncombatInterface;
              TextRend.PauseContinue;
              GDVars.interfaceState := C_Ifc.ORBIT_MAP;
              OrbitMap.LoadOrbitPictures;
              CharHlp.DisplayNoncombatInterface
            end;
            'C': Explore.CampAlterMenu;
            'S': Explore.SaveQuit
          end
      until c = 'M'
    end;
    C_Ifc.WILDERNESS: begin
      isDone := False;
      repeat
        if not GDVars.isMoveMode then begin
          MenuCore.MenuHorizontal('', 'Move Save', False, True);
          c := GDVars.menuKey;
          if not GDVars.isExtendedKey then
            case c of
              'M': begin TextRend.ClearStatusLine; GDVars.isMoveMode := True end;
              'S': Explore.SaveQuit
            end
        end else begin
          c := C_Keys.NONE;
          if c = C_Keys.NONE then begin
            MenuCore.MenuHorizontal('', 'Exit', True, False);
            c := GDVars.menuKey
          end;
          if not GDVars.isExtendedKey then
            case c of
              'E': if GDVars.isMouseClick and (GDVars.mouseY <= 128) then begin
                     GDVars.partyPosition.facing := CbtMap.DirectionBetween(GDVars.zone0^.wildernessX,
                                                                              GDVars.zone0^.wildernessY,
                                                                              GDVars.mouseX div 8 - 1,
                                                                              GDVars.mouseY div 8 - 1);
                     { Note: the key of keypad digit facing + 1, not the facing's; EclVm tests the result only for 'E',
                       which none of these is }
                     c := GDConsts.keypadScanCodes[GDVars.partyPosition.facing];
                     isDone := True
                   end else GDVars.isMoveMode := False
            end else begin
            isDone := True;
            case c of
              C_Keys.UP: GDVars.partyPosition.facing := C_Dir.NORTH;
              C_Keys.PAGE_UP: GDVars.partyPosition.facing := C_Dir.NORTHEAST;
              C_Keys.RIGHT: GDVars.partyPosition.facing := C_Dir.EAST;
              C_Keys.PAGE_DOWN: GDVars.partyPosition.facing := C_Dir.SOUTHEAST;
              C_Keys.DOWN: GDVars.partyPosition.facing := C_Dir.SOUTH;
              C_Keys.END_KEY: GDVars.partyPosition.facing := C_Dir.SOUTHWEST;
              C_Keys.LEFT: GDVars.partyPosition.facing := C_Dir.WEST;
              C_Keys.HOME: GDVars.partyPosition.facing := C_Dir.NORTHWEST
            end;
            CharHlp.PrintMiscInfo
          end
        end
      until isDone
    end
  end;
  if not GDVars.isBottomClear then begin
    TextRend.FillRect(GDVars.windowLeft, GDVars.windowTop, GDVars.windowRight, GDVars.windowBottom,
                      GDVars.windowColor);
    GDVars.isBottomClear := True
  end;
  MapMainMenu := c
end;

procedure ResolveMovement;
var canStep: Boolean;
    { Unused in this version; see the other implementations of this routine. }
    menuStr: Types.TString40;
begin
  canStep := False;
  case GDVars.interfaceState of
    C_Ifc.VIEW_3D: begin
      if GDVars.zone1^.moveBlocked < 255 then begin
        GDVars.isPortraitPending := True;
        if View3D.GetBarrierType(GDVars.partyPosition.mapX, GDVars.partyPosition.mapY,
                                 GDVars.partyPosition.facing) = 1 then canStep := True;
        if canStep then Explore.MovePartyForward3D;
        CharHlp.PrintMiscInfo
      end else GDVars.zone1^.moveBlocked := 0;
      Portrait.FreeAnimation;
      Blit.FreePic(GDVars.portraitSlots[1].picture);
      Blit.FreePic(GDVars.portraitSlots[2].picture);
      GDVars.portraitSlots[1].id := 255;
      GDVars.portraitSlots[2].id := 255
    end;
    C_Ifc.WILDERNESS: if GDVars.zone1^.moveBlocked < 255 then begin
      Explore.MovePartyWilderness;
      CharHlp.PrintMiscInfo
    end else GDVars.zone1^.moveBlocked := 0;
    C_Ifc.ORBIT_MAP: if GDVars.zone1^.moveBlocked < 255 then Explore.MoveRocket(False)
       else GDVars.zone1^.moveBlocked := 0
  end
end;

procedure RestMenu;
var c: Char;
begin
  repeat
    MenuCore.MenuHorizontal('', 'Rest Save Change Exit', False, True);
    c := GDVars.menuKey;
    if not GDVars.isExtendedKey then
      case c of
        'R': begin CharHlp.PrintBottomLine('The team rests.');
                   GameTime.RestAndHeal(1); MenuCore.DisplayParty(GDVars.currentCharacter) end;
        'S': Explore.SaveQuit;
        'C': Explore.CampAlterMenu
      end else begin
      CharHlp.DisplayRoster(GDVars.currentCharacter, False);
      ViewChar.SelectPrevNextChar(c);
      CharHlp.DisplayRoster(GDVars.currentCharacter, True);
      CharHlp.PrintMiscInfo
    end
  until (c = 'E') and not GDVars.isExtendedKey
end;

procedure NoopExploreA; begin end;

procedure NoopExploreB; begin end;

procedure NoopExploreC; begin end;

procedure NoopExploreD; begin end;

procedure NoopExploreE; begin end;

begin
end.
