{ The computer's turn in ground combat, for monsters and for party members on quick fight: picking an approach and a
  target, readying the best weapon, choosing where to aim an area weapon, stepping toward the target or away in flight,
  attacking, and the morale check. It uses the step history AiMoveStep reads (lastMoveDir, stuckCount), and the tables
  AiMoveStep steps and SelectAreaTarget aims by (aiDirOffsets, areaHalfWidths). }
{$A-,O+,F+,V-,I-,R-,S-}
unit CombatAi;

interface

uses Types, C_Npc, C_Screen, C_Side, C_Terr, GDConsts, GDVars, Crt, CharHlp, TextRend, CbtActs,
  GameIo, FxEngine, CbtMap, ViewChar, Pathing, C_Equip, C_Effect, C_Dir, C_Abil, C_WClass, C_Armor, C_Area, C_Item,
  C_Keys, C_Cond;

{ Plays cr's turn: rerolls its approach when it is unset or 5 or 6, and one time in four when it is 1..4 (a reroll gives
  1..4 seven times in eight, else 5 or 6), checks its morale, then prepares and acts until the turn is done. A key press
  can hand it back to the player.
  @param(cr The combatant whose turn it is.) }
procedure CombatAiControl(cr: Types.PCharacter);

{ Moves cr toward its target and attacks it, or a target in reach, until the turn ends.
  @param(cr The combatant acting.)
  @returns(True when cr has finished acting.) }
function AiMoveAttack(cr: Types.PCharacter): Boolean;

{ Ends cr's turn, on guard when it can still act.
  @param(cr The combatant.)
  @returns(True when the turn is over.) }
function FinishRound(cr: Types.PCharacter): Boolean;

{ Reads a pending key: Space returns the party's quick-fighters to the player, Alt-X checks the debug phrase. Note: a
  plain '-' checks it too, since it is the same byte as Alt-X's scan code and the case does not ask whether the key was
  extended.
  @param(cr The combatant whose turn it is.)
  @returns(True when cr itself came back to the player.) }
function CheckKeystroke(cr: Types.PCharacter): Boolean;

{ Tests a companion's morale against its own wounds, then against the hostiles' remaining hit points and the fight's
  moraleBase, which a C_Side.TEAM companion always fails. One that fails both flees when no enemy is faster (movement
  rates compared halved); otherwise, if its INT is over 5, it surrenders.
  @param(cr The companion tested.)
  @returns(True when cr surrendered and its turn is over.) }
function CheckMorale(cr: Types.PCharacter): Boolean;

{ Readies cr's best weapon against its target, by damage, bonuses and what the line to the target crosses; the armor
  with the highest class byte and plus; and, with a C_WClass.GRENADE weapon, a C_Equip.GRENADE_LAUNCHER item when none
  is readied. Note: the weapon swap writes the old and the new weapon's flags without testing for nil, so with no weapon
  readied before, or none better than unarmed, it writes through a nil pointer, and the launcher test then reads through
  it.
  @param(cr The combatant.)
  @param(mode 0 leaves area weapons out; otherwise they are scored by where they would land.)
  @param(result True when the weapon readied is heavy, which ends the turn.) }
procedure EquipWeaponAndArmor(cr: Types.PCharacter; mode: Byte; var result: Boolean);

{ Keeps cr's target when it is still a valid enemy, or picks one at random from those in any range (a second pass with
  the arena's distMode 1), and readies a weapon for it when mode is non-zero.
  @param(cr The combatant.)
  @param(mode Non-zero readies a weapon for the target.)
  @param(done Set when readying that weapon ends the turn.)
  @returns(True when cr has a target.) }
function PrepareAiAction(cr: Types.PCharacter; mode: Byte; var done: Boolean): Boolean;

implementation

const
  { grenades' itemTypes rows, named by ITEM0.DAX's templates of the same number: each fires its projectile kind; this
    one kind 6 }
  EXPLOSIVE_GRENADE_TYPE = 33;
  { kind 7, GAS_TERRAIN's cloud }
  GAS_GRENADE_TYPE = 34;
  { kind 8, CHAFF_TERRAIN's cloud }
  CHAFF_GRENADE_TYPE = 37;
  { kind 9, AEROSOL_MIST_TERRAIN's cloud }
  AEROSOL_MIST_GRENADE_TYPE = 38;
  { the farthest SelectAreaTarget scores cells from its origin }
  AREA_REACH = 9;
  { marks a combatant handed back to the player, set here on Space and by Combat on Alt-Q and Alt-A; AiMoveAttack stops
    acting at it, Combat turns it into 19, and no roll reaches it (d10 + DexMissileAdjust + 1 is at most 15) }
  HAND_BACK_INITIATIVE = 20;

type
  TAreaGrid = array[-CombatAi.AREA_REACH..CombatAi.AREA_REACH, -CombatAi.AREA_REACH..CombatAi.AREA_REACH] of ShortInt;
  PAreaGrid = ^TAreaGrid;

procedure CombatAiControl(cr: Types.PCharacter);
var
  pattern: Byte;
  done: Boolean;
  { Unused in this version; see the other implementations of this routine. }
  prepared: Boolean;
begin
  done := CombatAi.CheckKeystroke(cr);
  TextRend.ClearStatusLine;
  CharHlp.ClearMessageWindow;
  if (cr^.isEnabled = 0) or (cr^.status = Types.StDodging) or (cr^.status = Types.StSprinting) then
    done := CharHlp.EndActions(cr);
  pattern := cr^.combatState^.approach;
  if (pattern = 0) or (pattern > 4) or (CharHlp.RollDice(1, 4) = 1) then begin
    pattern := CharHlp.RollDice(1, 8);
    if pattern = 8 then
      pattern := CharHlp.RollDice(1, 2) + 4
    else
      pattern := CharHlp.RollDice(1, 4)
  end;
  cr^.combatState^.approach := pattern;
  if not done then done := CombatAi.CheckMorale(cr);
  if cr^.combatState^.isFleeing then
    CharHlp.PrintCreatureMessage(cr, 'flees in panic', 10, True);
  if not done then begin
    done := CombatAi.CheckKeystroke(cr);
    while not done do begin
      prepared := CombatAi.PrepareAiAction(cr, 1, done);
      if not done then
        if (cr^.combatState^.initiative > 0) and (cr^.isEnabled <> 0) then
          done := CombatAi.AiMoveAttack(cr)
        else
          done := CombatAi.FinishRound(cr)
    end
  end
end;

{ Scores every cell an area weapon cr has readied could hit, each member in the blast counting by side, and aims at the
  best cell a line reaches: fires there when mode is non-zero, or with no cell worth it readies a weapon with
  EquipWeaponAndArmor's mode 0; with mode 0 reports the score.
  @param(cr The combatant with the area weapon.)
  @param(mode Non-zero fires; 0 only scores.)
  @param(choice With mode 0, the best cell's score scaled to a byte.)
  @returns(With mode non-zero, True when cr's turn is over.) }
function SelectAreaTarget(cr: Types.PCharacter; mode: Byte; var choice: Byte): Boolean;
var
  scores: PAreaGrid;
  areaClass: Byte;
  outerRange: Byte;
  innerRange: Byte;
  item: Types.PItem;
  origin: Types.PCharacter;
  originX: ShortInt;
  originY: ShortInt;
  pX: ShortInt;
  pY: ShortInt;
  bestX: ShortInt;
  bestY: ShortInt;
  crX: ShortInt;
  crY: ShortInt;
  j: ShortInt;
  i: ShortInt;
  cellMin: ShortInt;
  cellMax: ShortInt;
  lowOffset: ShortInt;
  highOffset: ShortInt;
  teamWeight: ShortInt;
  bestWeight: ShortInt;
  outerMaxY: ShortInt;
  outerMaxX: ShortInt;
  outerMinY: ShortInt;
  outerMinX: ShortInt;
  innerMaxY: ShortInt;
  innerMaxX: ShortInt;
  innerMinY: ShortInt;
  innerMinX: ShortInt;
  done: Boolean;
  distance: Word;
  occupant: Byte;
  terrain: Byte;
  weights: array[0..1] of ShortInt;
  effectScratch: Types.PEffect;
  value: Word;
begin
  SelectAreaTarget := False;
  choice := 0;
  if cr = nil then Exit;
  item := cr^.readiedItems[C_Equip.WEAPON];
  if item = nil then Exit;
  { the area weapon classes }
  case GDVars.itemTypes[item^.template.itemType].weaponClass of
    C_WClass.ROCKET_LAUNCHER: areaClass := 2;
    C_WClass.GRENADE: areaClass := 1;
    C_WClass.PLASMA: areaClass := 3
  else
    Exit
  end;
  origin := nil;
  outerRange := ViewChar.ReadiedWeaponRange(cr) + areaClass;
  if outerRange > CombatAi.AREA_REACH then begin
    outerRange := CombatAi.AREA_REACH;
    if not (item^.template.itemType in [CombatAi.CHAFF_GRENADE_TYPE, CombatAi.AEROSOL_MIST_GRENADE_TYPE]) then
      origin := cr^.combatState^.target
  end;
  innerRange := outerRange - areaClass;
  { a chaff or mist cloud counts cr's side 4 and the other 1; any other blast counts cr's enemies 1 and its own side -12
    for C_Side.TEAM, -2 for C_Side.HOSTILE }
  if item^.template.itemType in [CombatAi.CHAFF_GRENADE_TYPE, CombatAi.AEROSOL_MIST_GRENADE_TYPE] then begin
    if cr^.side = C_Side.TEAM then begin
      weights[C_Side.TEAM] := 4;
      weights[C_Side.HOSTILE] := 1
    end else begin
      weights[C_Side.TEAM] := 1;
      weights[C_Side.HOSTILE] := 4
    end
  end else begin
    if cr^.side = C_Side.TEAM then begin
      weights[C_Side.TEAM] := -12;
      weights[C_Side.HOSTILE] := 1
    end else begin
      weights[C_Side.TEAM] := 1;
      weights[C_Side.HOSTILE] := -2
    end
  end;
  if origin = nil then origin := cr;
  originX := Byte(CbtMap.CombatCellX(origin));
  originY := Byte(CbtMap.CombatCellY(origin));
  outerMinX := originX - outerRange;
  outerMaxX := originX + outerRange;
  outerMinY := originY - outerRange;
  outerMaxY := originY + outerRange;
  innerMinX := originX - innerRange;
  innerMaxX := originX + innerRange;
  innerMinY := originY - innerRange;
  innerMaxY := originY + innerRange;
  GetMem(scores, SizeOf(TAreaGrid));
  FillChar(scores^, SizeOf(TAreaGrid), 0);
  { origin now walks the combatants }
  origin := GDVars.partyHead;
  while origin <> nil do begin
    pX := Byte(CbtMap.CombatCellX(origin));
    pY := Byte(CbtMap.CombatCellY(origin));
    if (origin^.isEnabled <> 0) and (pX >= outerMinX) and (pX <= outerMaxX) and (pY >= outerMinY) and
        (pY <= outerMaxY) then begin
      teamWeight := weights[origin^.side];
      case item^.template.itemType of
        CombatAi.CHAFF_GRENADE_TYPE, CombatAi.AEROSOL_MIST_GRENADE_TYPE: begin
          CbtMap.GetArenaContents(Byte(pX), Byte(pY), occupant, terrain);
          if (terrain = C_Terr.CHAFF_TERRAIN) or (terrain = C_Terr.AEROSOL_MIST_TERRAIN) then
            teamWeight := -1
        end;
        C_Item.STUN_GRENADE_TYPE: begin
          if CharHlp.HasEffect(origin, C_Effect.STUNNED, effectScratch) or CharHlp.IsHelpless(origin) then
            teamWeight := 0
        end;
        CombatAi.GAS_GRENADE_TYPE:
          if CharHlp.IsHelpless(origin) then teamWeight := 0
      end;
      lowOffset := -areaClass;
      highOffset := areaClass;
      if lowOffset + pY < innerMinY then
        lowOffset := innerMinY - pY;
      if highOffset + pY > innerMaxY then
        highOffset := innerMaxY - pY;
      for i := lowOffset to highOffset do begin
        cellMin := pX - GDConsts.areaHalfWidths[i, areaClass];
        cellMax := pX + GDConsts.areaHalfWidths[i, areaClass];
        if cellMin < innerMinX then cellMin := innerMinX;
        if cellMax > innerMaxX then cellMax := innerMaxX;
        for j := cellMin to cellMax do
          Inc(scores^[j - originX, i + pY - originY], teamWeight)
      end
    end;
    origin := origin^.next
  end;
  crX := Byte(CbtMap.CombatCellX(cr));
  crY := Byte(CbtMap.CombatCellY(cr));
  bestWeight := 0;
  for j := -innerRange to innerRange do
    for i := -innerRange to innerRange do begin
      teamWeight := scores^[j, i];
      if (teamWeight > bestWeight) or
          ((teamWeight = bestWeight) and (teamWeight > 0) and CharHlp.PercentileRoll(25)) then begin
        pX := crX;
        pY := crY;
        distance := ViewChar.ReadiedWeaponRange(cr);
        GDVars.stopsAtChaff := True;
        if Pathing.WalkLine(Byte(originX + j), Byte(originY + i), pX, pY, distance) and not GDVars.sawChaff then begin
          bestX := j;
          bestY := i;
          bestWeight := teamWeight
        end
      end
    end;
  FreeMem(scores, SizeOf(TAreaGrid));
  if mode <> 0 then begin
    if bestWeight > 0 then begin
      CbtActs.AttackGroundTarget(cr, originX + bestX, originY + bestY, done);
      SelectAreaTarget := CharHlp.EndActions(cr)
    end else begin
      CombatAi.EquipWeaponAndArmor(cr, 0, done);
      SelectAreaTarget := done
    end
  end else if bestWeight > 0 then begin
    case item^.template.itemType of
      CombatAi.CHAFF_GRENADE_TYPE: value := CharHlp.RollDice(1, 6) + 1;
      CombatAi.AEROSOL_MIST_GRENADE_TYPE: value := CharHlp.RollDice(1, 6);
      CombatAi.EXPLOSIVE_GRENADE_TYPE: value := 40;
      CombatAi.GAS_GRENADE_TYPE: value := 5;
      C_Item.DAZZLE_GRENADE_TYPE: value := CharHlp.RollDice(1, 10) + 10;
      C_Item.STUN_GRENADE_TYPE: value := CharHlp.RollDice(1, 10) + 5;
      C_Item.PLASMA_THROWER_TYPE: value := 25;
      C_Item.ROCKET_LAUNCHER_TYPE: value := 30
    end;
    value := value * bestWeight;
    if value > 128 then
      choice := (value shr 4) + 120
    else
      choice := value
  end
end;

{ Scores an area weapon for cr: SelectAreaTarget's mode-0 score with it readied in place of cr's weapon.
  @param(cr The combatant.)
  @param(item The weapon scored.)
  @returns(The score.) }
function EvaluateItem(cr: Types.PCharacter; item: Types.PItem): Byte;
var
  choice: Byte;
  savedWeapon: Types.PItem;
begin
  savedWeapon := cr^.readiedItems[C_Equip.WEAPON];
  cr^.readiedItems[C_Equip.WEAPON] := item;
  if CombatAi.SelectAreaTarget(cr, 0, choice) then ;
  EvaluateItem := choice;
  cr^.readiedItems[C_Equip.WEAPON] := savedWeapon
end;

{ Tests the step cr's approach tries: onto an empty cell whose cost is less than its movement left.
  @param(cr The combatant stepping.)
  @param(attempt The approach's try, which picks the turn from baseDirection.)
  @param(baseDirection The direction toward the target, or away from the fight.)
  @param(edge True when that cell is off the arena.)
  @returns(True when the step can be taken.) }
function AiCanStep(cr: Types.PCharacter; attempt, baseDirection: Byte; var edge: Boolean): Boolean;
var
  { Unused in this version; see the other implementations of this routine. }
  eff: Pointer;
  pattern: Byte;
  direction: Byte;
  creatureIndex: Byte;
  terrainIndex: Byte;
  cost: Byte;
  { ProbeDirection's gas report; not read here }
  isHarmful: Boolean;
  { Unused in this version; see the other implementations of this routine. }
  terrainHazard: Byte;
  ok: Boolean;
begin
  edge := False;
  ok := False;
  pattern := GDConsts.aiDirOffsets[cr^.combatState^.approach, attempt];
  direction := (baseDirection + pattern) mod 8;
  CbtMap.ProbeDirection(cr, direction, creatureIndex, terrainIndex, isHarmful);
  if terrainIndex = 0 then
    edge := True
  else begin
    if GDConsts.combatTerrain[terrainIndex].cost = C_Terr.IMPASSABLE then begin
      AiCanStep := False;
      Exit
    end;
    if Odd(direction) then
      cost := GDConsts.combatTerrain[terrainIndex].cost * 3
    else
      cost := GDConsts.combatTerrain[terrainIndex].cost shl 1;
    if (creatureIndex = 0) and (cost < cr^.combatState^.movement) then
      if cr^.combatState^.movement >= cost then ok := True
  end;
  AiCanStep := ok
end;

{ Steps cr once toward its target, or away from the fight when fleeing, trying its approach's turns in order; a fleeing
  cr at the arena's edge tries to flee the fight. Finding no way, or reversing its last step, turns its approach; the
  second time since AiMoveAttack began it drops its target and seeks another, the third ends its move. It finishes the
  round instead with no move or initiative left, as a medic neither fleeing nor armored, or as a C_Side.TEAM non-player
  when hostileHpPercent exceeds morale plus d100.
  @param(cr The combatant stepping.) }
procedure AiMoveStep(cr: Types.PCharacter);
var
  direction: Byte;
  newDirection: Byte;
  attempt: Byte;
  edge: Boolean;
  done: Boolean;
  { Unused in this version; see the other implementations of this routine. }
  combatant: LongInt;
  { Unused in this version; see the other implementations of this routine. }
  steps: Byte;
begin
  TextRend.DisplayString(0, C_Screen.STATUS_ROW, LightGreen, Black,
                         'Move/Attack, Move Left = ' + TextRend.ByteToString(cr^.combatState^.movement div 2) + ' ');
  if CombatAi.CheckKeystroke(cr) then Exit;
  if (cr^.combatState^.movement div 2 > 0) and (cr^.combatState^.initiative > 0) and
      ((cr^.npc < C_Npc.NON_PLAYER_FLAG) or
       ((cr^.npc > C_Npc.NON_PLAYER_FLAG - 1) and
        (GDVars.hostileHpPercent <= GDVars.morale + CharHlp.RollDice(1, 100))) or
      (cr^.side = C_Side.HOSTILE)) and
      (cr^.combatState^.isFleeing or (cr^.readiedItems[C_Equip.ARMOR] <> nil) or
       (cr^.career <> Types.CareerMedic)) then begin
    if not cr^.combatState^.isFleeing then
      direction := CbtMap.DirectionToward(cr, cr^.combatState^.target)
    else begin
      cr^.combatState^.approach := CharHlp.RollDice(1, 2);
      direction := GDVars.partyPosition.facing - (GDVars.partyPosition.facing + 2) mod 4 div 2;
      if cr^.side = C_Side.TEAM then direction := direction + 4;
      direction := direction mod 8
    end;
    edge := False;
    done := False;
    attempt := 1;
    while (attempt < 6) and (not done) and (not CombatAi.AiCanStep(cr, attempt, direction, edge)) do
      if cr^.combatState^.isFleeing and edge then
        done := CbtActs.AttemptFlee(cr)
      else
        Inc(attempt);
    if done then begin
      cr^.combatState^.movement := 0;
      cr^.combatState^.isFleeing := False;
      done := CharHlp.EndActions(cr)
    end else begin
      newDirection := (direction + GDConsts.aiDirOffsets[cr^.combatState^.approach, attempt]) mod 8;
      if (attempt = 6) or (GDVars.lastMoveDir = (newDirection + 4) mod 8) then begin
        Inc(GDVars.stuckCount);
        cr^.combatState^.approach := cr^.combatState^.approach mod 6 + 1;
        if GDVars.stuckCount > 1 then begin
          cr^.combatState^.target := nil;
          if GDVars.stuckCount > 2 then begin
            cr^.combatState^.movement := 0;
            done := True
          end else if (not CombatAi.PrepareAiAction(cr, 1, done)) and (not done) then
            done := CombatAi.FinishRound(cr)
        end
      end;
      if attempt < 6 then
        GDVars.lastMoveDir := newDirection
      else
        done := True
    end;
    if not done then begin
      GDVars.isMapVisible := GDVars.isTargetInReach or CbtMap.CombatIconVisible(cr, 0) or
        (cr^.side = C_Side.TEAM);
      CbtMap.SetCreatureFacing(cr, newDirection, 0, 0);
      if cr^.isEnabled = 0 then
        done := CharHlp.EndActions(cr)
      else begin
        if cr^.combatState^.movement > 0 then
          CbtActs.CombatMoveCreature(cr, cr^.combatState^.direction);
        if (cr^.isEnabled = 0) or CharHlp.IsHelpless(cr) then
          done := CharHlp.EndActions(cr);
        FxEngine.ConsiderTerrainEffects(cr, 1)
      end
    end
  end else
    done := CombatAi.FinishRound(cr)
end;

function AiMoveAttack(cr: Types.PCharacter): Boolean;
var
  stop: Boolean;
  acting: Boolean;
  reach: Byte;
  distance: Word;
  targetCount: Byte;
  pick: Byte;
  target: Types.PCharacter;
  targetX: ShortInt;
  targetY: ShortInt;
  rounds: Byte;
  areaChoice: Byte;
begin
  GDVars.lastMoveDir := C_Dir.CENTER;
  GDVars.stuckCount := 0;
  GDVars.aiMoveState := 0;
  rounds := 0;
  acting := True;
  stop := False;
  FxEngine.TriggerEffectsWithCondition(C_Cond.MONSTER_SPECIAL, cr);
  if (cr^.side = C_Side.TEAM) and not GDVars.isSoloCombat and ViewChar.FindPatients(cr) then begin
    ViewChar.TreatPatients(cr);
    cr^.combatState^.initiative := 0
  end;
  if cr^.combatState^.initiative = 0 then acting := False;
  while (not stop) and acting do begin
    if cr^.combatState^.isFleeing then
      while (cr^.combatState^.movement > 0) and (cr^.combatState^.initiative > 0) and
          (cr^.combatState^.initiative < CombatAi.HAND_BACK_INITIATIVE) do
        CombatAi.AiMoveStep(cr);
    if (cr^.combatState^.initiative = 0) or (cr^.combatState^.initiative = CombatAi.HAND_BACK_INITIATIVE) then
      acting := False
    else
      stop := False;
    if (not stop) and acting then begin
      Inc(rounds);
      if rounds > 20 then begin
        stop := True;
        acting := not CombatAi.FinishRound(cr)
      end;
      GDVars.isTargetInReach := False;
      target := cr^.combatState^.target;
      if target^.isEnabled = 0 then target := nil;
      reach := ViewChar.ReadiedWeaponRange(cr);
      if target <> nil then
        if CbtActs.CanTarget(cr, target) then begin
          targetX := Byte(CbtMap.CombatCellX(target));
          targetY := Byte(CbtMap.CombatCellY(target));
          distance := reach;
          GDVars.combatArena^.distMode := 0;
          if Pathing.WalkLine(Byte(CbtMap.CombatCellX(cr)), Byte(CbtMap.CombatCellY(cr)), targetX, targetY,
                              distance) then
            if distance div 2 <= reach then
              if (cr^.combatState^.movement < 4) or (reach > distance) or CharHlp.HasAreaWeapon(cr) then
                GDVars.isTargetInReach := True
        end;
      if not GDVars.isTargetInReach then begin
        if cr^.combatState^.movement > 4 then reach := 1;
        targetCount := CharHlp.CountTargets(cr, reach);
        if targetCount = 0 then begin
          if CombatAi.PrepareAiAction(cr, 0, stop) and (not stop) then
            CombatAi.AiMoveStep(cr)
          else
            stop := CombatAi.FinishRound(cr)
        end else begin
          pick := CharHlp.RollDice(1, targetCount);
          target := GDVars.creatures[GDVars.targetOrder[pick]];
          if (CharHlp.CalcDistance(cr, target) <= reach) or CbtActs.CanTarget(cr, target) then
            GDVars.isTargetInReach := True
        end
      end;
      if GDVars.isTargetInReach then begin
        if CharHlp.HasAreaWeapon(cr) then
          stop := CombatAi.SelectAreaTarget(cr, 1, areaChoice)
        else begin
          CbtMap.ScrollView(Byte(CbtMap.CombatCellX(cr)), Byte(CbtMap.CombatCellY(cr)), 2,
                            CbtMap.DirectionToward(cr, target));
          CbtActs.NoteAttackDirection(cr, target);
          CbtActs.MakeAttack(cr, target, False, stop)
        end;
        if stop then
          acting := False
        else if target^.isEnabled = 0 then
          stop := True
      end
    end
  end;
  AiMoveAttack := not acting
end;

function FinishRound(cr: Types.PCharacter): Boolean;
begin
  CharHlp.ClearMessageWindow;
  if CharHlp.IsHelpless(cr) or (cr^.combatState^.initiative = 0) then
    FinishRound := CharHlp.EndActions(cr)
  else
    FinishRound := CbtActs.Guard(cr)
end;

function CheckKeystroke(cr: Types.PCharacter): Boolean;
var
  p: Types.PCharacter;
  key: Char;
begin
  CheckKeystroke := False;
  if GameIo.InputPending then begin
    key := GameIo.ReadGameKey;
    if key = #0 then key := GameIo.ReadGameKey;
    case key of
      ' ': begin
        p := GDVars.partyHead;
        while p <> nil do begin
          with p^ do
            if (side = C_Side.TEAM) and (isCompanion = 0) and (combatState^.isOutOfPlay = 0) then
              isQuickfight := 0;
          p := p^.next
        end;
        if cr^.isQuickfight = 0 then begin
          cr^.combatState^.initiative := CombatAi.HAND_BACK_INITIATIVE;
          CheckKeystroke := True
        end
      end;
      C_Keys.ALT_X: if CbtActs.VictoryCheat then ;
    end
  end;
  GameIo.FlushKeys
end;

function CheckMorale(cr: Types.PCharacter): Boolean;
var
  enemyMovement: Byte;
  { Unused in this version; see the other implementations of this routine. }
  previousMorale: Byte;
  outStatus: Types.TStatus;
begin
  CheckMorale := False;
  cr^.combatState^.isFleeing := False;
  if cr^.isCompanion <> 0 then begin
    GDVars.morale := (cr^.npc and not C_Npc.NON_PLAYER_FLAG) shl 1;
    if GDVars.morale > 102 then GDVars.morale := 0;
    FxEngine.TriggerEffectsWithCondition(C_Cond.MORALE_CHECK, cr);
    if (GDVars.morale < 100 - cr^.hitPoints * 100 div cr^.hitPointMaximum) or (GDVars.morale = 0) then begin
      previousMorale := GDVars.morale;
      GDVars.morale := GDVars.hostileHpPercent;
      FxEngine.TriggerEffectsWithCondition(C_Cond.MORALE_CHECK, cr);
      if (GDVars.morale < 100 - GDVars.zone1^.moraleBase) or (GDVars.morale = 0) or
          (cr^.side = C_Side.TEAM) then begin
        enemyMovement := CbtActs.HighestEnemyMovement(cr);
        if enemyMovement <= CharHlp.RecalcMovement(cr) div 2 then
          cr^.combatState^.isFleeing := True
        else if cr^.abilities[C_Abil.INTELLIGENCE] > 5 then begin
          if cr^.side = C_Side.TEAM then outStatus := Types.StFleeing
                          else outStatus := Types.StUnconscious;
          FxEngine.PutOutOfPlayWithStatus(cr, outStatus, 'Surrenders');
          CheckMorale := CharHlp.EndActions(cr)
        end
      end
    end
  end
end;

procedure EquipWeaponAndArmor(cr: Types.PCharacter; mode: Byte; var result: Boolean);
var
  targetCharacter: Types.PCharacter;
  bestWeapon: Types.PItem;
  oldWeapon: Types.PItem;
  item: Types.PItem;
  launcher: Types.PItem;
  bestArmor: Types.PItem;
  oldArmor: Types.PItem;
  isLauncherReadied: Boolean;
  baseItem: ^TItemType;
  bestPriority: Byte;
  priority: Byte;
  { Unused in this version; see the other implementations of this routine. }
  lineReached: Boolean;
  effectScratch: Types.PEffect;
  targetX: ShortInt;
  targetY: ShortInt;
  distance: Word;
  laserShift: Byte;
  microwaveShift: Byte;
  rocketShift: Byte;

  { item's score as a weapon from its damage, bonuses and specialization; 0 when it is out of shots or unusable here. }
  function CalcWeaponPriority: Byte;
  var
    priority: Byte;
    multiplier: Byte;
  begin
    if (baseItem^.weaponClass > C_WClass.MELEE) and (item^.template.quantity = 0) then begin
      CalcWeaponPriority := 0;
      Exit
    end;
    priority := baseItem^.diceSides * baseItem^.diceCount + baseItem^.damageBonus * 2;
    if item^.template.itemType = C_Item.SONIC_STUNNER_TYPE then begin
        if (targetCharacter <> nil) and CharHlp.HasEffect(targetCharacter, C_Effect.STUNNED, effectScratch) then
          priority := 0
        else
          priority := 12
    end else if item^.template.itemType in [C_Item.PLASMA_THROWER_TYPE, C_Item.ROCKET_LAUNCHER_TYPE,
                              CombatAi.GAS_GRENADE_TYPE..CombatAi.AEROSOL_MIST_GRENADE_TYPE] then begin
        if (mode <> 0) and
            ((cr^.side = C_Side.HOSTILE) or
             not (item^.template.itemType in [CombatAi.CHAFF_GRENADE_TYPE, CombatAi.AEROSOL_MIST_GRENADE_TYPE])) and
            (((GDVars.zone0^.areaKind and C_Area.ZERO_GRAVITY) = 0) or
             not (item^.template.itemType in [CombatAi.CHAFF_GRENADE_TYPE, CombatAi.AEROSOL_MIST_GRENADE_TYPE])) then
          priority := CombatAi.EvaluateItem(cr, item)
        else
          priority := 0
    end
    ;
    Inc(priority, CharHlp.SpecializationLevel(cr, item) * 3 + item^.template.plus * 3);
    if baseItem^.weaponClass = C_WClass.MELEE then
      Inc(priority, CharHlp.StrDamageAdjust(cr) * 2 + CharHlp.StrToHitAdjust(cr) * 2)
    else
      Inc(priority, CharHlp.DexMissileAdjust(cr) * 2);
    multiplier := baseItem^.attacksDoubled shr 1;
    if multiplier = 0 then multiplier := 1;
    if (mode = 0) and (baseItem^.weaponClass >= C_WClass.FIRST_AREA_WEAPON) then
      CalcWeaponPriority := 0
    else
      CalcWeaponPriority := priority * multiplier
  end;

begin
  targetCharacter := cr^.combatState^.target;
  bestArmor := nil;
  bestWeapon := nil;
  launcher := nil;
  isLauncherReadied := False;
  bestPriority := cr^.unarmedDice[1] * cr^.unarmedRolls[1] + cr^.unarmedModifiers[1] * 2;
  laserShift := 0;
  microwaveShift := 0;
  rocketShift := 0;
  if targetCharacter <> nil then begin
    targetX := Byte(CbtMap.CombatCellX(targetCharacter));
    targetY := Byte(CbtMap.CombatCellY(targetCharacter));
    distance := 255;
    lineReached := Pathing.WalkLine(Byte(CbtMap.CombatCellX(cr)), Byte(CbtMap.CombatCellY(cr)), targetX, targetY,
                                    distance);
    if GDVars.sawAerosolMist or CharHlp.HasEffect(targetCharacter, C_Effect.IMMUNE_TO_LASER, effectScratch) then
      laserShift := 3;
    if GDVars.sawChaff then
      rocketShift := 3
    else begin
      if (targetCharacter^.armorFlags and C_Armor.ECM <> 0) or
          CharHlp.HasEffect(targetCharacter, C_Effect.IMMUNE_TO_ROCKET, effectScratch) then
        rocketShift := 2
    end;
    if (targetCharacter^.armorFlags and C_Armor.BODY <> 0) or
        CharHlp.HasEffect(targetCharacter, C_Effect.IMMUNE_TO_MICROWAVE, effectScratch) then
      microwaveShift := 3
  end;
  item := cr^.itemList;
  while item <> nil do begin
    baseItem := @GDVars.itemTypes[item^.template.itemType];
    case baseItem^.slot of
      C_Equip.WEAPON: begin
        priority := CalcWeaponPriority;
        case baseItem^.weaponClass of
          C_WClass.ROCKET: priority := priority shr rocketShift;
          C_WClass.LASER: priority := priority shr laserShift;
          C_WClass.MICROWAVE: priority := priority shr microwaveShift
        end;
        if priority > bestPriority then begin
          bestPriority := priority;
          bestWeapon := item
        end
      end;
      C_Equip.ARMOR: begin
        if (bestArmor = nil) or
            (GDVars.itemTypes[bestArmor^.template.itemType].weaponClass + bestArmor^.template.plus <
             baseItem^.weaponClass + item^.template.plus) then
          bestArmor := item
      end;
      C_Equip.GRENADE_LAUNCHER: begin
        if item^.template.flags and C_Item.READIED <> 0 then
          isLauncherReadied := True
        else
          launcher := item
      end
    end;
    item := item^.next
  end;
  oldArmor := ViewChar.FindReadiedItem(cr, C_Equip.ARMOR);
  if bestArmor <> oldArmor then begin
    if oldArmor <> nil then
      ViewChar.ToggleReadyItem(oldArmor, result);
    if bestArmor <> nil then
      ViewChar.ToggleReadyItem(bestArmor, result)
  end;
  result := False;
  oldWeapon := ViewChar.FindReadiedItem(cr, C_Equip.WEAPON);
  if (bestWeapon <> oldWeapon) or (bestWeapon <> cr^.readiedItems[C_Equip.WEAPON]) then
    if (bestWeapon <> nil) and (GDVars.itemTypes[bestWeapon^.template.itemType].isHeavy <> 0) then
      result := True;
  oldWeapon^.template.flags := oldWeapon^.template.flags and not C_Item.READIED;
  cr^.readiedItems[C_Equip.WEAPON] := bestWeapon;
  bestWeapon^.template.flags := bestWeapon^.template.flags or C_Item.READIED;
  if not result and (launcher <> nil) and not isLauncherReadied and
      (GDVars.itemTypes[bestWeapon^.template.itemType].weaponClass = C_WClass.GRENADE) then
    ViewChar.ToggleReadyItem(launcher, result);
  if (oldArmor <> bestArmor) or (oldWeapon <> bestWeapon) or result then begin
    CharHlp.RecalcStats(cr);
    CbtActs.RecalcAttacksLeft(cr);
    CharHlp.CombatPrintCreatureInfo(cr);
    if result then begin
      CharHlp.PrintCreatureMessage(cr, 'readies a heavy weapon', 10, False);
      TextRend.PauseOnly
    end
  end
end;

function PrepareAiAction(cr: Types.PCharacter; mode: Byte; var done: Boolean): Boolean;
var
  targetCount: Byte;
  attempts: Byte;
  index: Byte;
  retryDone: Boolean;
  hasTarget: Boolean;
  secondPass: Boolean;
  target: Types.PCharacter;
  { Unused in this version; see the other implementations of this routine. }
  deadPointer: Pointer;
begin
  deadPointer := nil;
  secondPass := False;
  hasTarget := False;
  retryDone := False;
  target := cr^.combatState^.target;
  if target <> nil then
    if (target^.side = cr^.side) or (target^.isEnabled = 0) or not CbtActs.CanTarget(cr, target) then
      cr^.combatState^.target := nil;
  if cr^.combatState^.target <> nil then hasTarget := True;
  while (not hasTarget) and (not retryDone) do begin
    retryDone := secondPass;
    if secondPass then GDVars.combatArena^.distMode := 1;
    attempts := 20;
    targetCount := CharHlp.CountTargets(cr, 255);
    while (attempts > 0) and (not hasTarget) and (targetCount > 0) do begin
      Dec(attempts);
      index := CharHlp.RollDice(1, targetCount);
      if GDVars.targetOrder[index] > 0 then begin
        target := GDVars.creatures[GDVars.targetOrder[index]];
        if ((mode <> 0) and (GDVars.combatArena^.distMode <> 0)) or CbtActs.CanTarget(cr, target) then begin
          hasTarget := True;
          cr^.combatState^.target := target
        end else begin
          GDVars.targetOrder[index] := 0;
          for index := 1 to targetCount do
            if GDVars.targetOrder[index] > 0 then hasTarget := True;
          { some are left: search on }
          if hasTarget then
            hasTarget := False
          else
            targetCount := 0
        end
      end
    end;
    if not secondPass then secondPass := True
  end;
  GDVars.combatArena^.distMode := 0;
  if hasTarget and (mode <> 0) then
    CombatAi.EquipWeaponAndArmor(cr, 1, done);
  PrepareAiAction := hasTarget
end;

begin
end.
