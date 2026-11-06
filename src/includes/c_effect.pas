{ The effect numbers a creature can be under. postCombatClearedEffects lists five of them. }
unit C_Effect;

interface

const
  { effect numbers; each is named for what its EffHndlr handler does. Ids 4..12 and 15 (empty or EffHelpless handlers
    that nothing gives) and 17 (an empty handler) have no constant }
  HELPLESS = 1;
  { CbtActs's intimidation gives it, and CharHlp shows it as intimidated }
  SCARED = 2;
  { EffHndlr's EffUnkillable blocks every new effect and keeps damage from taking the holder below 0 hit points; CbtActs
    has the holder leap for cover from a blast and leaves it out of Leadership, and PostCbt puts a team holder below 45
    hit points back up to 45 }
  UNKILLABLE = 3;
  BLIND = 13;
  { a Sonic Stunner hit gives it }
  STUNNED = 14;
  { EffHndlr's EffBlockScared keeps C_Effect.SCARED from being added }
  BLOCK_SCARED = 16;
  { EffHndlr's EffImmuneToMicrowave cancels a hit from a C_WClass.MICROWAVE weapon }
  IMMUNE_TO_MICROWAVE = 18;
  { EffHndlr's EffBlockHelpless keeps C_Effect.HELPLESS from being added }
  BLOCK_HELPLESS = 19;
  { EffHndlr's EffImmuneToRocket cancels a C_WClass.ROCKET hit }
  IMMUNE_TO_ROCKET = 20;
  { EffHndlr's EffBlockDazzleGrenade keeps a Dazzle Grenade from adding an effect }
  BLOCK_DAZZLE_GRENADE = 21;
  { EffHndlr's EffBlockStunWeapons keeps an EffHndlr.WEAPON_CLASS_SONIC weapon or a Stun Grenade from adding an effect }
  BLOCK_STUN_WEAPONS = 22;
  { EffHndlr's EffImmuneToHeatAndPlasma cancels a hit or non-weapon damage while the weapon is
    EffHndlr.WEAPON_CLASS_HEAT or C_WClass.PLASMA }
  IMMUNE_TO_HEAT_AND_PLASMA = 23;
  { EffHndlr's EffImmuneToLaser cancels a C_WClass.LASER hit }
  IMMUNE_TO_LASER = 24;
  { EffHndlr's EffDodgeSlugHits cancels, half the time, a C_WClass.SLUG hit from beyond 1 cell }
  DODGE_SLUG_HITS = 25;
  { EffHndlr's EffResistRangedHits zeroes, half the time, the damage of a C_WClass.SLUG..EffHndlr.WEAPON_CLASS_HEAT hit
    from beyond 1 cell }
  RESIST_RANGED_HITS = 26;
  { EffHndlr's EffResistMeleeHits zeroes, half the time, the damage of a C_WClass.MELEE hit }
  RESIST_MELEE_HITS = 27;
  { EffHndlr's EffDizzyingPoison gives the holder's target C_Effect.DIZZY unless a saving throw negates it }
  DIZZYING_POISON = 28;
  { C_Effect.DIZZYING_POISON's handler gives it with 'is poisoned' }
  DIZZY = 29;
  { EffHndlr's EffLethalPoison kills the holder's target as poisoned unless a saving throw saves it }
  LETHAL_POISON = 30;
  { EffHndlr's EffStrikeAdjacent strikes an enabled enemy target within 1 cell for 8, or 4 on a saving throw }
  STRIKE_ADJACENT = 31;
  { EffHndlr's EffSpitAcid spits acid at an enabled enemy target within 12 cells }
  SPIT_ACID = 32;

implementation

end.
