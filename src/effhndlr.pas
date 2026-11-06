{ The combat effect handlers. GameInit calls InitEffectHandlers to fill effectHandlers, one handler per effect number,
  and FxEngine's CallEffectHandler calls through it. Each handler is Eff and the effect it serves; the ones whose body
  is empty are EffNone, EffNoneB and EffNoneC. InitEffectHandlers gives the effect numbers each handler serves.
  EffSpitAcid's combat line is acidMessage, in GDConsts. NoopEffHndlrA to NoopEffHndlrE are empty placeholders.

  A handler's test of "the weapon" reads currentCharacter's readied weapon, the attacker's under FxEngine's trigger
  condition 5. Condition 9 runs as an effect is about to be added, and clearing pendingEffectId there blocks it;
  condition 5 runs on the defender of a hit, and ClearEffectMode there cancels the hit's damage; condition 6 runs as
  FxEngine deals damage that is not a weapon's. }
{$O+,F+,I-}
unit EffHndlr;

interface

uses Types, C_Item, GDConsts, GDVars, CharHlp, FxEngine, TextRend, CbtActs, CbtMap, Music, Blit,
  C_Equip, C_Effect, C_WClass, C_Attack, C_Save;

{ Fills effectHandlers[1..32], each effect number's handler. }
procedure InitEffectHandlers;

{ Empty routine with no callers. }
procedure NoopEffHndlrA;

{ Clears pendingEffectId, effectDamage and currentAttackRoll.
  @param(which The mode to clear only while it is set, or 0 to clear whatever is set.) }
procedure ClearEffectMode(which: Byte);

{ Empty routine with no callers. }
procedure NoopEffHndlrB;

{ Ends the creature's actions for the round.
  @param(owner The creature carrying the effect.)
  @param(effect Unused.)
  @param(removed Unused.) }
procedure EffEndActions(var owner: Types.TEffectOwner; effect: Types.PEffect; removed: Byte);

{ Helpless effect: ends the owner's combat actions.
  @param(owner The effect's owner.)
  @param(effect The effect's node.)
  @param(removed Set as the effect is removed.) }
procedure EffHelpless(var owner: Types.TEffectOwner; effect: Types.PEffect; removed: Byte);

{ Ends the owner's combat actions, but not as the effect is removed.
  @param(owner The effect's owner.)
  @param(effect Unused.)
  @param(removed Set as the effect is removed.) }
procedure EffScared(var owner: Types.TEffectOwner; effect: Types.PEffect; removed: Byte);

{ Blocks any new effect and caps the effect damage at the owner's hit points.
  @param(owner The effect's owner.)
  @param(effect Unused.)
  @param(removed Unused.) }
procedure EffUnkillable(var owner: Types.TEffectOwner; effect: Types.PEffect; removed: Byte);

{ Does nothing.
  @param(owner Unused.)
  @param(effect Unused.)
  @param(removed Unused.) }
procedure EffNone(var owner: Types.TEffectOwner; effect: Types.PEffect; removed: Byte);

{ Blinds the owner: takes 4 off the attack roll, both armor classes and the saving-throw roll, but not as the effect is
  removed.
  @param(owner The effect's owner.)
  @param(effect Unused.)
  @param(removed Set as the effect is removed.) }
procedure EffBlind(var owner: Types.TEffectOwner; effect: Types.PEffect; removed: Byte);

{ Ends the owner's combat actions (EffEndActions).
  @param(owner The effect's owner.)
  @param(effect The effect's node.)
  @param(removed Set as the effect is removed.) }
procedure EffStunned(var owner: Types.TEffectOwner; effect: Types.PEffect; removed: Byte);

{ Does nothing.
  @param(owner Unused.)
  @param(effect Unused.)
  @param(removed Unused.) }
procedure EffNoneB(var owner: Types.TEffectOwner; effect: Types.PEffect; removed: Byte);

{ Blocks the Scared effect.
  @param(owner Unused.)
  @param(effect Unused.)
  @param(removed Unused.) }
procedure EffBlockScared(var owner: Types.TEffectOwner; effect: Types.PEffect; removed: Byte);

{ Does nothing.
  @param(owner Unused.)
  @param(effect Unused.)
  @param(removed Unused.) }
procedure EffNoneC(var owner: Types.TEffectOwner; effect: Types.PEffect; removed: Byte);

{ Cancels a hit from a microwave weapon.
  @param(owner Unused.)
  @param(effect Unused.)
  @param(removed Unused.) }
procedure EffImmuneToMicrowave(var owner: Types.TEffectOwner; effect: Types.PEffect; removed: Byte);

{ Blocks the Helpless effect.
  @param(owner Unused.)
  @param(effect Unused.)
  @param(removed Unused.) }
procedure EffBlockHelpless(var owner: Types.TEffectOwner; effect: Types.PEffect; removed: Byte);

{ Cancels a hit from a rocket weapon.
  @param(owner Unused.)
  @param(effect Unused.)
  @param(removed Unused.) }
procedure EffImmuneToRocket(var owner: Types.TEffectOwner; effect: Types.PEffect; removed: Byte);

{ Blocks a new effect while the weapon is a Dazzle Grenade.
  @param(owner Unused.)
  @param(effect Unused.)
  @param(removed Unused.) }
procedure EffBlockDazzleGrenade(var owner: Types.TEffectOwner; effect: Types.PEffect; removed: Byte);

{ Blocks a new effect while the weapon is a sonic weapon, the Sonic Stunner, or a Stun Grenade.
  @param(owner Unused.)
  @param(effect Unused.)
  @param(removed Unused.) }
procedure EffBlockStunWeapons(var owner: Types.TEffectOwner; effect: Types.PEffect; removed: Byte);

{ Cancels a hit from a heat or plasma weapon.
  @param(owner Unused.)
  @param(effect Unused.)
  @param(removed Unused.) }
procedure EffImmuneToHeatAndPlasma(var owner: Types.TEffectOwner; effect: Types.PEffect; removed: Byte);

{ Cancels a hit from a laser weapon.
  @param(owner Unused.)
  @param(effect Unused.)
  @param(removed Unused.) }
procedure EffImmuneToLaser(var owner: Types.TEffectOwner; effect: Types.PEffect; removed: Byte);

{ Dodges, half the time, a slug-weapon hit from beyond 1 cell, canceling it and taking it off hitCounts[1].
  @param(owner The effect's owner.)
  @param(effect Unused.)
  @param(removed Unused.) }
procedure EffDodgeSlugHits(var owner: Types.TEffectOwner; effect: Types.PEffect; removed: Byte);

{ Zeroes, half the time, the damage of a ranged hit, from a slug weapon through a heat weapon, from beyond 1 cell.
  @param(owner The effect's owner.)
  @param(effect Unused.)
  @param(removed Unused.) }
procedure EffResistRangedHits(var owner: Types.TEffectOwner; effect: Types.PEffect; removed: Byte);

{ Zeroes, half the time, the damage of a melee hit.
  @param(owner Unused.)
  @param(effect Unused.)
  @param(removed Unused.) }
procedure EffResistMeleeHits(var owner: Types.TEffectOwner; effect: Types.PEffect; removed: Byte);

{ Poisons the owner's target, making it dizzy ('is poisoned'), unless it makes saving throw 1 against the effect's
  strength.
  @param(owner The effect's owner.)
  @param(effect The effect's node.)
  @param(removed Unused.) }
procedure EffDizzyingPoison(var owner: Types.TEffectOwner; effect: Types.PEffect; removed: Byte);

{ Halves the movement and attack rates, but not as the effect is removed.
  @param(owner Unused.)
  @param(effect Unused.)
  @param(removed Set as the effect is removed.) }
procedure EffDizzy(var owner: Types.TEffectOwner; effect: Types.PEffect; removed: Byte);

{ Kills the owner's target as poisoned when it fails saving throw 1 against the effect's strength.
  @param(owner The effect's owner.)
  @param(effect The effect's node.)
  @param(removed Unused.) }
procedure EffLethalPoison(var owner: Types.TEffectOwner; effect: Types.PEffect; removed: Byte);

{ Strikes an adjacent foe: an enabled enemy target within 1 cell takes 8 damage, or 4 when it makes saving throw 6.
  @param(owner The effect's owner.)
  @param(effect Unused.)
  @param(removed Unused.) }
procedure EffStrikeAdjacent(var owner: Types.TEffectOwner; effect: Types.PEffect; removed: Byte);

{ Spits acid at an enabled enemy target within 12 cells, with a 30% chance of 2d8 damage. Note: it inflicts the damage
  itself and then hands it to CbtActs's ProcessAttackResult, which inflicts it again, so a hit counts twice.
  @param(owner The effect's owner.)
  @param(effect Unused.)
  @param(removed Unused.) }
procedure EffSpitAcid(var owner: Types.TEffectOwner; effect: Types.PEffect; removed: Byte);

{ Empty routine with no callers. }
procedure NoopEffHndlrC;

{ Empty routine with no callers. }
procedure NoopEffHndlrD;

{ Empty routine with no callers. }
procedure NoopEffHndlrE;

implementation

const
  { TItemType.weaponClass of the Heat Gun }
  WEAPON_CLASS_HEAT = 5;
  { TItemType.weaponClass of the Sonic Stunner }
  WEAPON_CLASS_SONIC = 6;

procedure ClearEffectMode(which: Byte);
begin
  if (which = 0) or (GDVars.pendingEffectId = which) then begin
    GDVars.effectDamage := 0;
    GDVars.pendingEffectId := 0;
    GDVars.currentAttackRoll := 0
  end
end;

procedure EffEndActions(var owner: Types.TEffectOwner; effect: Types.PEffect; removed: Byte);
var
  { Unused in this version; see the other implementations of this routine. }
  ignored: Boolean;
begin
  ignored := CharHlp.EndActions(owner.character)
end;

procedure EffHelpless(var owner: Types.TEffectOwner; effect: Types.PEffect; removed: Byte);
begin EffHndlr.EffEndActions(owner, effect, removed) end;

procedure EffScared(var owner: Types.TEffectOwner; effect: Types.PEffect; removed: Byte);
var
  { Unused in this version; see the other implementations of this routine. }
  ignored: Boolean;
begin if removed = 0 then ignored := CharHlp.EndActions(owner.character) end;

procedure EffUnkillable(var owner: Types.TEffectOwner; effect: Types.PEffect; removed: Byte);
begin
  GDVars.pendingEffectId := 0;
  if GDVars.effectDamage > owner.character^.hitPoints then
    GDVars.effectDamage := Lo(owner.character^.hitPoints)
end;

procedure EffNone(var owner: Types.TEffectOwner; effect: Types.PEffect; removed: Byte); begin end;

procedure EffBlind(var owner: Types.TEffectOwner; effect: Types.PEffect; removed: Byte);
begin
  if removed = 0 then begin
    Dec(GDVars.currentAttackRoll, 4);
    Dec(owner.character^.armorClass[0], 4);
    Dec(owner.character^.armorClass[1], 4);
    Dec(GDVars.saveRoll, 4)
  end
end;

procedure EffStunned(var owner: Types.TEffectOwner; effect: Types.PEffect; removed: Byte);
begin EffHndlr.EffEndActions(owner, effect, removed) end;

procedure EffNoneB(var owner: Types.TEffectOwner; effect: Types.PEffect; removed: Byte); begin end;

procedure EffBlockScared(var owner: Types.TEffectOwner; effect: Types.PEffect; removed: Byte);
begin if GDVars.pendingEffectId = C_Effect.SCARED then EffHndlr.ClearEffectMode(0) end;

procedure EffNoneC(var owner: Types.TEffectOwner; effect: Types.PEffect; removed: Byte); begin end;

procedure EffImmuneToMicrowave(var owner: Types.TEffectOwner; effect: Types.PEffect; removed: Byte);
var weapon: Types.PItem;
begin
  weapon := GDVars.currentCharacter^.readiedItems[C_Equip.WEAPON];
  if (weapon <> nil) and
      (GDVars.itemTypes[weapon^.template.itemType].weaponClass =
       C_WClass.MICROWAVE) then EffHndlr.ClearEffectMode(0)
end;

procedure EffBlockHelpless(var owner: Types.TEffectOwner; effect: Types.PEffect; removed: Byte);
begin if GDVars.pendingEffectId = C_Effect.HELPLESS then EffHndlr.ClearEffectMode(0) end;

procedure EffImmuneToRocket(var owner: Types.TEffectOwner; effect: Types.PEffect; removed: Byte);
var weapon: Types.PItem;
begin
  weapon := GDVars.currentCharacter^.readiedItems[C_Equip.WEAPON];
  if (weapon <> nil) and
      (GDVars.itemTypes[weapon^.template.itemType].weaponClass = C_WClass.ROCKET) then EffHndlr.ClearEffectMode(0)
end;

procedure EffBlockDazzleGrenade(var owner: Types.TEffectOwner; effect: Types.PEffect; removed: Byte);
var weapon: Types.PItem;
begin
  weapon := GDVars.currentCharacter^.readiedItems[C_Equip.WEAPON];
  if (weapon <> nil) and (weapon^.template.itemType = C_Item.DAZZLE_GRENADE_TYPE) then EffHndlr.ClearEffectMode(0)
end;

procedure EffBlockStunWeapons(var owner: Types.TEffectOwner; effect: Types.PEffect; removed: Byte);
var weapon: Types.PItem;
begin
  weapon := GDVars.currentCharacter^.readiedItems[C_Equip.WEAPON];
  if (weapon <> nil) and
      ((GDVars.itemTypes[weapon^.template.itemType].weaponClass = EffHndlr.WEAPON_CLASS_SONIC) or
       (weapon^.template.itemType = C_Item.STUN_GRENADE_TYPE)) then
    EffHndlr.ClearEffectMode(0)
end;

procedure EffImmuneToHeatAndPlasma(var owner: Types.TEffectOwner; effect: Types.PEffect; removed: Byte);
var weapon: Types.PItem;
    weaponClass: Byte;
begin
  weapon := GDVars.currentCharacter^.readiedItems[C_Equip.WEAPON];
  if weapon <> nil then begin
    weaponClass := GDVars.itemTypes[weapon^.template.itemType].weaponClass;
    if (weaponClass = EffHndlr.WEAPON_CLASS_HEAT) or
        (weaponClass = C_WClass.PLASMA) then EffHndlr.ClearEffectMode(0)
  end
end;

procedure EffImmuneToLaser(var owner: Types.TEffectOwner; effect: Types.PEffect; removed: Byte);
var weapon: Types.PItem;
begin
  weapon := GDVars.currentCharacter^.readiedItems[C_Equip.WEAPON];
  if (weapon <> nil) and
      (GDVars.itemTypes[weapon^.template.itemType].weaponClass = C_WClass.LASER) then EffHndlr.ClearEffectMode(0)
end;

procedure EffDodgeSlugHits(var owner: Types.TEffectOwner; effect: Types.PEffect; removed: Byte);
var weapon: Types.PItem;
begin
  weapon := GDVars.currentCharacter^.readiedItems[C_Equip.WEAPON];
  if (weapon <> nil) and (GDVars.itemTypes[weapon^.template.itemType].weaponClass = C_WClass.SLUG) and
      (CharHlp.CalcDistance(GDVars.currentCharacter, owner.character) > 1) and CharHlp.PercentileRoll(50) then begin
    CharHlp.PrintCreatureMessage(owner.character, 'dodges it', 10, True);
    EffHndlr.ClearEffectMode(0);
    Dec(GDVars.hitCounts[1])
  end
end;

procedure EffResistRangedHits(var owner: Types.TEffectOwner; effect: Types.PEffect; removed: Byte);
var weapon: Types.PItem;
begin
  weapon := GDVars.currentCharacter^.readiedItems[C_Equip.WEAPON];
  if (weapon <> nil) and (GDVars.itemTypes[weapon^.template.itemType].weaponClass >= C_WClass.SLUG) and
      (GDVars.itemTypes[weapon^.template.itemType].weaponClass <= EffHndlr.WEAPON_CLASS_HEAT) and
      (CharHlp.CalcDistance(GDVars.currentCharacter, owner.character) > 1) and CharHlp.PercentileRoll(50) then
    GDVars.effectDamage := 0
end;

procedure EffResistMeleeHits(var owner: Types.TEffectOwner; effect: Types.PEffect; removed: Byte);
var weapon: Types.PItem;
begin
  weapon := GDVars.currentCharacter^.readiedItems[C_Equip.WEAPON];
  if (weapon <> nil) and (GDVars.itemTypes[weapon^.template.itemType].weaponClass = C_WClass.MELEE) and
      CharHlp.PercentileRoll(50) then
    GDVars.effectDamage := 0
end;

procedure EffDizzyingPoison(var owner: Types.TEffectOwner; effect: Types.PEffect; removed: Byte);
var hasSaved: Boolean;
begin
  GDVars.activeTarget := owner.character^.combatState^.target;
  hasSaved := FxEngine.RollSavingThrow(GDVars.activeTarget, 1, effect^.strength);
  FxEngine.AddEffectWithMessage(GDVars.activeTarget, C_Effect.DIZZY, 0, 0, False, C_Save.CANCELS, hasSaved,
                                'is poisoned');
  TextRend.PauseOnly;
  if CharHlp.HasEffect(GDVars.activeTarget, C_Effect.DIZZY, effect) then
    CharHlp.PrintCreatureMessage(GDVars.activeTarget, 'is dizzy', 10, True)
end;

procedure EffDizzy(var owner: Types.TEffectOwner; effect: Types.PEffect; removed: Byte);
begin
  if removed <> 0 then Exit;
  GDVars.movementRate := GDVars.movementRate div 2;
  GDVars.attackRate := GDVars.attackRate div 2
end;

procedure EffLethalPoison(var owner: Types.TEffectOwner; effect: Types.PEffect; removed: Byte);
var hasSaved: Boolean;
begin
  GDVars.activeTarget := owner.character^.combatState^.target;
  hasSaved := FxEngine.RollSavingThrow(GDVars.activeTarget, 1, effect^.strength);
  if not hasSaved then FxEngine.KillCreature(GDVars.activeTarget, Types.StPoisoned, 'is poisoned')
end;

procedure EffStrikeAdjacent(var owner: Types.TEffectOwner; effect: Types.PEffect; removed: Byte);
begin
  GDVars.activeTarget := owner.character^.combatState^.target;
  if (GDVars.activeTarget <> nil) and (CharHlp.CalcDistance(owner.character, GDVars.activeTarget) <= 1) and
      (GDVars.activeTarget^.isEnabled <> 0) and (GDVars.activeTarget^.side <> owner.character^.side) then begin
    if FxEngine.RollSavingThrow(GDVars.activeTarget, 6, 0) then
      GDVars.effectDamage := 4
    else
      GDVars.effectDamage := 8;
    GDVars.attackManner := C_Attack.PLAIN;
    CbtActs.ProcessAttackResult(owner.character, GDVars.activeTarget, GDVars.effectDamage, GDVars.effectDamage,
                                True);
    GDVars.isFrameScriptDone := True
  end
end;

procedure EffSpitAcid(var owner: Types.TEffectOwner; effect: Types.PEffect; removed: Byte);
begin
  GDVars.activeTarget := owner.character^.combatState^.target;
  if (GDVars.activeTarget <> nil) and (CharHlp.CalcDistance(owner.character, GDVars.activeTarget) <= 12) and
      (GDVars.activeTarget^.isEnabled <> 0) and (GDVars.activeTarget^.side <> owner.character^.side) then begin
    GDVars.isFrameScriptDone := True;
    CharHlp.CombatPrintCreatureInfo(owner.character);
    owner.character^.combatState^.direction := CbtMap.DirectionToward(owner.character, GDVars.activeTarget);
    CbtMap.SetCreatureFacing(owner.character, owner.character^.combatState^.direction, 1, 0);
    owner.character^.combatState^.target := GDVars.activeTarget;
    CharHlp.PrintCreatureMessage(owner.character, GDConsts.acidMessage, 10, False);
    Music.SendSoundCommand(GDConsts.launchSound);
    Blit.BuildIconFrames(18);
    CharHlp.CombatAnimateMovingIcon(CbtMap.CombatCellX(owner.character), CbtMap.CombatCellY(owner.character),
                                    CbtMap.CombatCellX(GDVars.activeTarget),
                                    CbtMap.CombatCellY(GDVars.activeTarget), 4, 45);
    if CharHlp.PercentileRoll(30) then begin
      GDVars.effectDamage := CharHlp.RollDice(2, 8);
      CharHlp.InflictDamage(GDVars.activeTarget, GDVars.effectDamage)
    end else
      GDVars.effectDamage := 0;
    GDVars.attackManner := C_Attack.PLAIN;
    CbtActs.ProcessAttackResult(owner.character, GDVars.activeTarget, GDVars.effectDamage, GDVars.effectDamage,
                                GDVars.effectDamage > 0)
  end
end;

procedure InitEffectHandlers;
begin
  GDVars.effectHandlers[C_Effect.HELPLESS] := EffHndlr.EffHelpless;
  GDVars.effectHandlers[C_Effect.SCARED] := EffHndlr.EffScared;
  GDVars.effectHandlers[C_Effect.UNKILLABLE] := EffHndlr.EffUnkillable;
  GDVars.effectHandlers[4] := EffHndlr.EffNone;
  for GDVars.loopIndex := 5 to 12 do GDVars.effectHandlers[GDVars.loopIndex] := EffHndlr.EffHelpless;
  GDVars.effectHandlers[C_Effect.BLIND] := EffHndlr.EffBlind;
  GDVars.effectHandlers[C_Effect.STUNNED] := EffHndlr.EffStunned;
  GDVars.effectHandlers[15] := EffHndlr.EffNoneB;
  GDVars.effectHandlers[C_Effect.BLOCK_SCARED] := EffHndlr.EffBlockScared;
  GDVars.effectHandlers[17] := EffHndlr.EffNoneC;
  GDVars.effectHandlers[C_Effect.IMMUNE_TO_MICROWAVE] := EffHndlr.EffImmuneToMicrowave;
  GDVars.effectHandlers[C_Effect.BLOCK_HELPLESS] := EffHndlr.EffBlockHelpless;
  GDVars.effectHandlers[C_Effect.IMMUNE_TO_ROCKET] := EffHndlr.EffImmuneToRocket;
  GDVars.effectHandlers[C_Effect.BLOCK_DAZZLE_GRENADE] := EffHndlr.EffBlockDazzleGrenade;
  GDVars.effectHandlers[C_Effect.BLOCK_STUN_WEAPONS] := EffHndlr.EffBlockStunWeapons;
  GDVars.effectHandlers[C_Effect.IMMUNE_TO_HEAT_AND_PLASMA] := EffHndlr.EffImmuneToHeatAndPlasma;
  GDVars.effectHandlers[C_Effect.IMMUNE_TO_LASER] := EffHndlr.EffImmuneToLaser;
  GDVars.effectHandlers[C_Effect.DODGE_SLUG_HITS] := EffHndlr.EffDodgeSlugHits;
  GDVars.effectHandlers[C_Effect.RESIST_RANGED_HITS] := EffHndlr.EffResistRangedHits;
  GDVars.effectHandlers[C_Effect.RESIST_MELEE_HITS] := EffHndlr.EffResistMeleeHits;
  GDVars.effectHandlers[C_Effect.DIZZYING_POISON] := EffHndlr.EffDizzyingPoison;
  GDVars.effectHandlers[C_Effect.DIZZY] := EffHndlr.EffDizzy;
  GDVars.effectHandlers[C_Effect.LETHAL_POISON] := EffHndlr.EffLethalPoison;
  GDVars.effectHandlers[C_Effect.STRIKE_ADJACENT] := EffHndlr.EffStrikeAdjacent;
  GDVars.effectHandlers[C_Effect.SPIT_ACID] := EffHndlr.EffSpitAcid
end;

procedure NoopEffHndlrA; begin end;

procedure NoopEffHndlrB; begin end;

procedure NoopEffHndlrC; begin end;

procedure NoopEffHndlrD; begin end;

procedure NoopEffHndlrE; begin end;

begin
end.
