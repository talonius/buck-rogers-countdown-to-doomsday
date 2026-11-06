{ Ground combat's limits: the combatant slots, the party's size and the icon slots past it, how long an idle combat
  lasts, the bits of a combat icon's size, and the aiming mode that attacks. }
unit C_Combat;

interface

const
  { the ground combat slots, numbered from 1: it bounds the per-combatant tables below, by slot or by order, and
    GameTime's effectFlags; Combat's round loop and waiting shuffle stop at the last }
  MAX_COMBATANTS = 72;
  { zone 1's partyCount at most: CharGen's AddCharacterMenu and SaveLoad's AddCreatureToParty add no one past it }
  MAX_PARTY_SIZE = 8;
  { the first icon slot, TCharacter.orderNumber, past the members': SaveLoad's AddCharToParty gives a member the first
    free slot below it, and EclMenu's EclInit and EclVm's EclClearMonsters start nextCreatureIconSlot at it }
  FIRST_CREATURE_ICON_SLOT = 8;
  { rounds a ground combat lasts past its last attack: CombatSt's CombatStart sets combatEndRound to it and CbtActs's
    MakeAttack sets it that far past combatRound }
  IDLE_ROUNDS = 15;
  { TCharacter.iconDimensions' bits holding the combat icon's size, as CbtMap and CbtActs read it }
  ICON_SIZE_MASK = $7F;
  { CbtActs's CombatAimMenu's and ManualAimCursor's mode: the target chosen is attacked }
  AIM_ATTACK = 1;

implementation

end.
