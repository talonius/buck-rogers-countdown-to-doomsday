{ The ground-combat loop: rounds of combatants acting in initiative order until one side is gone or the round limit is
  reached, the player's combat menu and move menu for a manually controlled combatant, and the clean-up after. The
  actions themselves are CbtActs's, the computer's choices CombatAi's. The unit owns no state: the round counters, the
  combat order and the cloud list are shared with the other combat units. }
{$A-,O+,F+,V-}
unit Combat;

interface

uses Types, C_Combat, C_Screen, C_Side, C_Terr, GDConsts, GDVars, Blit, CbtMap, CbtActs, FxEngine,
  CharHlp, ViewChar, CombatSt, CombatAi, MenuCore, GameTime, Border, TextRend, GameIo, Crt, C_Equip, C_Effect, C_Dir,
  C_Skill, C_WClass, C_Ifc, C_Area, C_Keys, C_Menu, C_Cond, C_Time;

{ Runs a ground combat from CombatSt's CombatStart to the clean-up, with interfaceState IN_COMBAT. }
procedure CombatMain;

{ Gives cr its turn: resets its per-turn combat state, returns a dodging or failed zero-g cr to okay, runs its
  turn-start effects and drops the scared effect and, when it still has initiative (a handed-back 20 becomes 19), hands
  it to CombatAi or ManualControl.
  @param(cr The combatant whose turn it is.) }
procedure CreatureAction(cr: Types.PCharacter);

{ The player's turn for cr: the combat menu until an action ends the turn; a disabled cr just ends it.
  @param(cr The combatant the player controls.) }
procedure ManualControl(cr: Types.PCharacter);

{ Builds cr's combat menu from what it may do now and reads a key the menu accepts.
  @param(cr The combatant the menu is for.)
  @param(isDone Unused.)
  @param(key The letter chosen, or an Alt scan code when the extended-key flag is set.) }
procedure CombatMenu(cr: Types.PCharacter; var isDone: Boolean; var key: Char);

{ Ends the round: sprinters and jetpackers return to okay, the clock advances one minute, the round counter one, the
  hostiles' hit-point share is recalculated, the lingering clouds are counted down (FxEngine's CountDownAreaEffects),
  and the dying and the view are brought up to date. }
procedure EndOfRound;

{ Moves cr one cell per direction key, attacking whoever stands there, until Enter, 'D' or a canceled move; offers to
  flee when the step meets terrain 0, which is what lies off the arena.
  @param(cr The combatant moving.)
  @param(startKey The first key to act on; ' ' asks for one.)
  @param(isDone True when the turn has ended.) }
procedure MoveMenu(cr: Types.PCharacter; startKey: Char; var isDone: Boolean);

{ Attacks defender in melee unless attacker is sprinting, holds an area weapon or an empty slug weapon, or CbtActs's
  CheckAttackAlly declines.
  @param(attacker The combatant attacking.)
  @param(defender The combatant attacked.)
  @param(isDone True when the attack ended the attacker's turn.) }
procedure MeleeAttack(attacker, defender: Types.PCharacter; var isDone: Boolean);

{ Hands cr to the computer, dropping a target on its own side.
  @param(cr The combatant handed over.) }
procedure TurnOnAuto(cr: Types.PCharacter);

{ Fills the combat order with the party list by initiative, highest first, a tie going to the higher tiebreak value. }
procedure OrderCreatures;

{ Frees the cloud list, the arena and the combat pictures, returns combat statuses to okay, removes C_Effect.BLIND,
  C_Effect.HELPLESS and C_Effect.STUNNED from every combatant, clears C_Side.TEAM's tactics flag and restores the
  non-combat palette and view size. }
procedure CombatDoneCleanup;

{ Tests whether cr may fight with its readied weapon.
  @param(cr The combatant.)
  @returns(False while cr sprints or its readied weapon is an empty C_WClass.SLUG weapon.) }
function CombatOptionAllowed(cr: Types.PCharacter): Boolean;

implementation

const
  { scan codes the combat menu takes with isExtendedKey set, with C_Keys.ALT_X }
  KEY_ALT_Q = #16;
  KEY_ALT_R = #19;
  KEY_ALT_A = #30;
  KEY_ALT_M = #50;

type
  TString12 = String[12];

procedure CombatDoneCleanup;
var
  nextCloud: Types.PAreaEffect;
  cr: Types.PCharacter;
  { Unused in this version; see the other implementations of this routine. }
  effectScan: array[0..5] of Byte;
begin
  while GDVars.areaEffects <> nil do begin
    nextCloud := GDVars.areaEffects^.next;
    FreeMem(GDVars.areaEffects, SizeOf(Types.TAreaEffect));
    GDVars.areaEffects := nextCloud
  end;
  cr := GDVars.partyHead;
  while cr <> nil do begin
    if cr^.status in [Types.StDodging..Types.StUsingJetpack] then cr^.status := Types.StOkay;
    FxEngine.RemoveEffect(cr, C_Effect.BLIND, nil);
    FxEngine.RemoveEffect(cr, C_Effect.HELPLESS, nil);
    FxEngine.RemoveEffect(cr, C_Effect.STUNNED, nil);
    cr := cr^.next
  end;
  FreeMem(GDVars.combatArena, SizeOf(Types.TArena));
  GDVars.combatArena := nil;
  Blit.FreePic(GDVars.movingIcon);
  Blit.FreePic(GDVars.arenaTiles);
  CbtMap.SetNoncombatPalette;
  GDVars.tacticsSides[C_Side.TEAM] := 0;
  GDVars.viewPicture^.height := 200;
  GDVars.viewPicture^.width := 40
end;

procedure CombatMain;
var
  isDone: Boolean;
  cr: Types.PCharacter;
begin
  GDVars.interfaceState := C_Ifc.IN_COMBAT;
  CbtActs.UseLeadership;
  CombatSt.CombatStart;
  isDone := False;
  if (GDVars.teamCounts[C_Side.TEAM] = 0) or (GDVars.teamCounts[C_Side.HOSTILE] = 0) then
    isDone := True
  else
    GDVars.isTreatmentPending := True;
  cr := GDVars.partyHead;
  while not isDone do begin
    CharHlp.CountTeams;
    CbtActs.RollTactics;
    cr := GDVars.partyHead;
    while cr <> nil do begin
      CbtActs.BeginRound(cr);
      cr := cr^.next
    end;
    GDVars.zone1^.sideMask := 0;
    Combat.OrderCreatures;
    cr := GDVars.combatOrder[1];
    GDVars.currentCombatant := 1;
    while (cr <> nil) and not isDone do begin
      Combat.CreatureAction(cr);
      Inc(GDVars.currentCombatant);
      if GDVars.currentCombatant > C_Combat.MAX_COMBATANTS then
        cr := nil
      else
        cr := GDVars.combatOrder[GDVars.currentCombatant];
      CharHlp.CountTeams;
      if (GDVars.teamCounts[C_Side.TEAM] = 0) or (GDVars.teamCounts[C_Side.HOSTILE] = 0) or
          (GDVars.combatRound >= GDVars.combatEndRound) then
        isDone := True
    end;
    Combat.EndOfRound
  end;
  Combat.CombatDoneCleanup;
  GDVars.isMessageDelayed := True
end;

procedure OrderCreatures;
var
  isSearching: Boolean;
  cr: Types.PCharacter;
  displaced: Types.PCharacter;
  nextDisplaced: Types.PCharacter;
  initiative: ShortInt;
  otherInitiative: ShortInt;
  slot: Byte;
  shiftSlot: Byte;
begin
  cr := GDVars.partyHead;
  FillChar(GDVars.combatOrder, SizeOf(GDVars.combatOrder), 0);
  while cr <> nil do begin
    slot := 1;
    isSearching := True;
    initiative := cr^.combatState^.initiative;
    while (slot < 65) and isSearching do begin
      if GDVars.combatOrder[slot] <> nil then
        otherInitiative := GDVars.combatOrder[slot]^.combatState^.initiative
      else
        otherInitiative := -1;
      if (initiative > otherInitiative) or
          ((initiative = otherInitiative) and
           (GDVars.combatOrder[slot]^.combatState^.tieBreaker < cr^.combatState^.tieBreaker)) then
        isSearching := False
      else
        Inc(slot)
    end;
    displaced := GDVars.combatOrder[slot];
    GDVars.combatOrder[slot] := cr;
    if displaced <> nil then begin
      shiftSlot := slot;
      isSearching := True;
      while (shiftSlot < C_Combat.MAX_COMBATANTS) and isSearching do begin
        Inc(shiftSlot);
        nextDisplaced := GDVars.combatOrder[shiftSlot];
        GDVars.combatOrder[shiftSlot] := displaced;
        displaced := nextDisplaced;
        if nextDisplaced = nil then isSearching := False
      end
    end;
    cr := cr^.next
  end
end;

procedure CreatureAction(cr: Types.PCharacter);
var
  { Unused in this version; see the other implementations of this routine. }
  action: Byte;
begin
  with cr^ do begin
    combatState^.attacksDrawn := 0;
    combatState^.directionTotal := 0;
    combatState^.isGuarding := False;
    if (status = Types.StDodging) or (status = Types.StFailedZeroG) then status := Types.StOkay;
    FxEngine.TriggerEffectsWithCondition(C_Cond.TURN_START, cr);
    FxEngine.RemoveEffect(cr, C_Effect.SCARED, nil);
    if combatState^.initiative <= 0 then Exit;
    if combatState^.initiative = 20 then combatState^.initiative := 19;
    GDVars.currentCharacter := cr;
    GDVars.isMapVisible := (side = C_Side.TEAM) or CbtMap.CombatIconVisible(cr, 0);
    CbtMap.DisplayMapViewCentered(cr, 2, True);
    CharHlp.RecalcStats(cr);
    GDVars.needsCreatureInfoRedraw := True;
    CharHlp.CombatPrintCreatureInfo(cr);
    CbtActs.RollZeroG(cr);
    FxEngine.TriggerEffectsWithCondition(C_Cond.ACTION_START, cr);
    if combatState^.initiative > 0 then
      if isQuickfight <> 0 then
        CombatAi.CombatAiControl(cr)
      else Combat.ManualControl(cr);
    CbtMap.RedrawArenaCell(CbtMap.CombatCellX(cr), CbtMap.CombatCellY(cr))
  end
end;

function CombatOptionAllowed(cr: Types.PCharacter): Boolean;
var
  item: Types.PItem;
begin
  CombatOptionAllowed := True;
  if cr^.status = Types.StSprinting then
    CombatOptionAllowed := False
  else begin
    item := cr^.readiedItems[C_Equip.WEAPON];
    if item <> nil then
      if (GDVars.itemTypes[item^.template.itemType].weaponClass = C_WClass.SLUG) and (item^.template.quantity = 0) then
        CombatOptionAllowed := False
  end
end;

procedure ManualControl(cr: Types.PCharacter);
var
  key: Char;
  isDone: Boolean;
  p: Types.PCharacter;
  { CombatAimMenu fills it }
  selection: Types.TAimTarget;
  { Unused in this version; see the other implementations of this routine. }
  menuKeys: array[1..2] of Byte;
  { passed to CombatMenu, which neither reads nor writes it }
  isMenuDone: Boolean;
  { Unused in this version; see the other implementations of this routine. }
  choice: Byte;
begin
  if cr^.isEnabled <> 0 then begin
    isDone := False;
    isMenuDone := True;
    while not isDone do begin
      GDVars.horizontalChoice := 1;
      Combat.CombatMenu(cr, isMenuDone, key);
      if not GDVars.isExtendedKey then
        case key of
          'M': Combat.MoveMenu(cr, ' ', isDone);
          'T': CbtActs.CombatAimMenu(cr, 255, C_Combat.AIM_ATTACK, False, Combat.CombatOptionAllowed(cr), isDone,
                                     selection);
          'V': begin
                 ViewChar.ViewCharMenu(isDone);
                 CbtActs.RecalcAttacksLeft(cr);
                 CharHlp.DisplayCombatInterface
               end;
          'I': begin
                 CbtActs.IntimidateTarget(cr);
                 isDone := CharHlp.EndActions(cr)
               end;
          'Q': begin
                 Combat.TurnOnAuto(cr);
                 TextRend.ClearStatusLine;
                 GameIo.FlushKeys;
                 Delay(200);
                 isDone := True;
                 CombatAi.CombatAiControl(cr)
               end;
          'A': begin
                 ViewChar.TreatPatients(cr);
                 isDone := CharHlp.EndActions(cr)
               end;
          'S': begin
                 if cr^.status <> Types.StSprinting then begin
                   cr^.status := Types.StSprinting;
                   cr^.combatState^.movement := cr^.combatState^.movement * 2
                 end;
                 Combat.MoveMenu(cr, ' ', isDone)
               end;
          'D': begin
                 cr^.status := Types.StDodging;
                 isDone := CharHlp.EndActions(cr)
               end;
          'J': begin
                 CbtActs.CombatUseJetpack(cr);
                 isDone := cr^.combatState^.initiative = 0
               end;
          { wait: cr moves to the end of the order and acts again this round }
          'W': begin
                 cr^.combatState^.initiative := 1;
                 GDVars.loopIndex := GDVars.currentCombatant;
                 p := GDVars.combatOrder[GDVars.loopIndex + 1];
                 while (p <> nil) and (GDVars.loopIndex < C_Combat.MAX_COMBATANTS) do begin
                   GDVars.combatOrder[GDVars.loopIndex] := p;
                   Inc(GDVars.loopIndex);
                   p := GDVars.combatOrder[GDVars.loopIndex + 1]
                 end;
                 GDVars.combatOrder[GDVars.loopIndex] := cr;
                 Dec(GDVars.currentCombatant);
                 isDone := True
               end;
          'G': isDone := CbtActs.Guard(cr);
          'E': isDone := CharHlp.EndActions(cr);
          { takes every active team member who is not a companion off quick-fight }
          ' ': begin
                 p := GDVars.partyHead;
                 while p <> nil do begin
                   with p^ do
                     if (side = C_Side.TEAM) and (isCompanion = 0) and (combatState^.isOutOfPlay = 0) then
                       isQuickfight := 0;
                   p := p^.next
                 end
               end
        end else
        case key of
          { the whole party goes to quick-fight, cr starting over under the computer }
          Combat.KEY_ALT_Q, Combat.KEY_ALT_A: begin
                 Dec(GDVars.currentCombatant);
                 cr^.combatState^.initiative := 20;
                 p := GDVars.partyHead;
                 while p <> nil do begin
                   Combat.TurnOnAuto(p);
                   p := p^.next
                 end;
                 TextRend.ClearStatusLine;
                 Delay(200);
                 isDone := True
               end;
          C_Keys.ALT_X: if CbtActs.VictoryCheat then begin
                  CbtMap.DisplayMapViewCentered(cr, 3, False);
                  isDone := True
                end
        end;
      if not isDone then begin
        CbtMap.DisplayMapViewCentered(cr, 2, True);
        GDVars.needsCreatureInfoRedraw := True;
        CharHlp.CombatPrintCreatureInfo(cr)
      end
    end
  end else
    isDone := CharHlp.EndActions(cr)
end;

procedure CombatMenu(cr: Types.PCharacter; var isDone: Boolean; var key: Char);
var
  menu: String;
  { Unused in this version; see the other implementations of this routine. }
  menuLength: Word;
begin
  Border.ClearBox(0, 23, 39, 24);
  menu := '';
  if cr^.combatState^.movement > 0 then menu := menu + 'Move ';
  menu := menu + 'Target View ';
  if (cr^.skillLevels[C_Skill.INTIMIDATE] > 0) and (CharHlp.CountTargets(cr, 1) > 0) and
      (cr^.status <> Types.StDodging) and (cr^.status <> Types.StFailedZeroG) then
    menu := menu + 'Intimidate ';
  menu := menu + 'Quick ';
  if ViewChar.FindPatients(cr) then menu := menu + 'Aid ';
  { the last space: MenuHorizontal starts the second line there }
  menu[Length(menu)] := '@';
  if (cr^.combatState^.movement > 0) and (cr^.status <> Types.StDodging) then begin
    if cr^.status <> Types.StSprinting then begin
      if (cr^.status <> Types.StUsedJetpack) and (cr^.status <> Types.StFailedZeroG) then
        menu := menu + 'Sprint ';
      menu := menu + 'Dodge '
    end;
    if (cr^.status <> Types.StUsedJetpack) and (ViewChar.FindReadiedItem(cr, C_Equip.JETPACK) <> nil) and
        (GDVars.zone0^.areaKind in [C_Area.VENUS_WILDERNESS, C_Area.MARS_WILDERNESS]) then
      menu := menu + 'Jetpack '
  end;
  menu := menu + 'Wait ';
  if (cr^.status <> Types.StSprinting) and (cr^.status <> Types.StDodging) then
    menu := menu + 'Guard ';
  menu := menu + 'End';
  repeat
    MenuCore.MenuHorizontal('', menu, True, False);
    key := GDVars.menuKey;
    if GDVars.isExtendedKey then
      if not (key in [Combat.KEY_ALT_Q, Combat.KEY_ALT_R, Combat.KEY_ALT_A, C_Keys.ALT_X, Combat.KEY_ALT_M]) then
        key := C_Keys.NONE
  until key in
      [Combat.KEY_ALT_Q, Combat.KEY_ALT_R, Combat.KEY_ALT_A, ' ', C_Keys.ALT_X, Combat.KEY_ALT_M, 'A', 'D', 'E',
       'G', 'I', 'J', 'M', 'Q', 'S', 'T', 'V', 'W'];
  Border.ClearBox(0, 23, 39, 24)
end;

procedure EndOfRound;
var
  { Unused in this version; see the other implementations of this routine. }
  index: Byte;
  p: Types.PCharacter;
begin
  p := GDVars.partyHead;
  while p <> nil do begin
    if (p^.status = Types.StSprinting) or (p^.status = Types.StUsedJetpack) then p^.status := Types.StOkay;
    p := p^.next
  end;
  GameTime.AdvanceTime(1, C_Time.MINUTES);
  Inc(GDVars.combatRound);
  CbtActs.UpdateHostileHpPercent;
  FxEngine.CountDownAreaEffects;
  CharHlp.ProcessDyingCharacters;
  CbtMap.ScrollView(GDVars.combatArena^.viewOriginX + 3, GDVars.combatArena^.viewOriginY + 3, 255, C_Dir.CENTER)
end;

procedure MoveMenu(cr: Types.PCharacter; startKey: Char; var isDone: Boolean);
var
  savedMove: Byte;
  savedDir: Byte;
  startX: Byte;
  startY: Byte;
  { Unused in this version; see the other implementations of this routine. }
  slot: Integer;
  dir: Byte;
  crIdx: Byte;
  terrIdx: Byte;
  key: Char;
  { ProbeDirection's gas report; not read here }
  isHarmful: Boolean;
  cost: Byte;
  prompt: TString12;

  { Puts cr back on the cell the move began on, with its movement and facing; isDone when it no longer fits there. }
  procedure UndoMove;
  begin
    cr^.combatState^.movement := savedMove;
    CbtMap.UpdateCombatMapTile(0, 0, CbtMap.CombatSlot(cr));
    isDone := not CbtMap.IsValidCreatureLoc(cr, startX, startY, False);
    CbtMap.ScrollView(CbtMap.CombatCellX(cr), CbtMap.CombatCellY(cr), 0, C_Dir.CENTER);
    cr^.combatState^.direction := savedDir;
    dir := C_Dir.CENTER
  end;

begin
  GDVars.isInMoveMenu := True;
  savedMove := cr^.combatState^.movement;
  savedDir := cr^.combatState^.direction;
  startX := CbtMap.CombatCellX(cr);
  startY := CbtMap.CombatCellY(cr);
  key := startKey;
  isDone := False;
  dir := C_Dir.CENTER;
  repeat
    while (key <> C_Keys.NONE) and (key <> C_Keys.ENTER) and (key <> 'D') and (isDone = False) do begin
      if cr^.status = Types.StSprinting then
        prompt := 'Sprinting'
      else if cr^.status = Types.StDodging then
        prompt := 'Dodging'
      else
        prompt := 'Move/Attack';
      Border.ClearBox(24, C_Screen.STATUS_ROW, 39, C_Screen.STATUS_ROW);
      if key = ' ' then begin
        MenuCore.MenuHorizontal(prompt + ', Move Left = ' + TextRend.ByteToString(cr^.combatState^.movement div 2),
                                ' Done', True, False);
        key := GDVars.menuKey
      end;
      case key of
        C_Keys.NONE: UndoMove;
        C_Keys.PAGE_UP: dir := C_Dir.NORTHEAST;
        C_Keys.UP: dir := C_Dir.NORTH;
        C_Keys.PAGE_DOWN: dir := C_Dir.SOUTHEAST;
        C_Keys.RIGHT: dir := C_Dir.EAST;
        C_Keys.END_KEY: dir := C_Dir.SOUTHWEST;
        C_Keys.DOWN: dir := C_Dir.SOUTH;
        C_Keys.HOME: dir := C_Dir.NORTHWEST;
        C_Keys.LEFT: dir := C_Dir.WEST
      else
        dir := C_Dir.CENTER
      end;
      if dir < C_Dir.CENTER then begin
        CbtMap.SetCreatureFacing(cr, dir, 0, 0);
        CbtMap.ProbeDirection(cr, dir, crIdx, terrIdx, isHarmful);
        if crIdx > 0 then
          Combat.MeleeAttack(cr, GDVars.creatures[crIdx], isDone)
        else if terrIdx = 0 then begin
          case MenuCore.YesNoMenu('Flee:', C_Menu.DEFAULT_NO) of
            'Y': isDone := CbtActs.AttemptFlee(cr);
            'N': isDone := False
          end
        end else begin
          if Odd(dir) then
            cost := GDConsts.combatTerrain[terrIdx].cost * 3
          else
            cost := GDConsts.combatTerrain[terrIdx].cost * 2;
          if GDConsts.combatTerrain[terrIdx].cost = C_Terr.IMPASSABLE then cost := C_Terr.IMPASSABLE;
          if cost > cr^.combatState^.movement then
            CharHlp.PrintBottomLine('can''t go there')
          else begin
            if cr^.isEnabled = 0 then
              isDone := CharHlp.EndActions(cr)
            else begin
              if cr^.combatState^.movement > 0 then
                CbtActs.CombatMoveCreature(cr, dir);
              if cr^.isEnabled = 0 then isDone := CharHlp.EndActions(cr);
              FxEngine.ConsiderTerrainEffects(cr, 1);
              if CharHlp.IsHelpless(cr) then isDone := CharHlp.EndActions(cr)
            end
          end
        end
      end;
      if (key <> C_Keys.NONE) and (key <> C_Keys.ENTER) and (key <> 'D') then key := ' '
    end
  until (key <> ' ') or isDone;
  if cr^.combatState^.movement < 2 then cr^.combatState^.movement := 0;
  GDVars.isInMoveMenu := False
end;

procedure MeleeAttack(attacker, defender: Types.PCharacter; var isDone: Boolean);
begin
  if attacker^.status = Types.StSprinting then
    CharHlp.PrintBottomLine('Not while running')
  else if CharHlp.HasAreaWeapon(attacker) or not Combat.CombatOptionAllowed(attacker) then
    CharHlp.PrintBottomLine('Not with that weapon')
  else if CbtActs.CheckAttackAlly(attacker, defender) then begin
    attacker^.combatState^.target := defender;
    CbtActs.NoteAttackDirection(attacker, defender);
    CbtActs.MakeAttack(attacker, defender, False, isDone)
  end
end;

procedure TurnOnAuto(cr: Types.PCharacter);
begin
  cr^.isQuickfight := 1;
  if cr^.combatState^.target <> nil then
    if cr^.combatState^.target^.side = cr^.side then
      cr^.combatState^.target := nil
end;

begin
end.
