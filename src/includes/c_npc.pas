{ TCharacter.npc's values: the non-player bit and the party member value. }
unit C_Npc;

interface

const
  { TCharacter.npc's bit marking a non-player character: CharGen, Money, CombatAi, PostCbt, SaveLoad and ViewChar treat
    a character whose npc is below it as a player character, CbtActs one at or above it as a non-player, and CombatSt
    and EclVm set it; CombatAi and CombatSt mask it off to read the morale in the bits below it }
  NON_PLAYER_FLAG = $80;
  { a TCharacter.npc value, NON_PLAYER_FLAG set, that the party treats as one of its own: Money pools its credits with
    the player characters' and counts it among those it divides the pool by, and CbtActs's CheckAttackAlly leaves it on
    the team }
  PARTY_MEMBER_NPC = $B3;

implementation

end.
