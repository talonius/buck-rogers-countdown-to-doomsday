{ The combat sides, TCharacter.side's values. }
unit C_Side;

interface

const
  { TCharacter.side of the team and its companions in combat }
  TEAM = 0;
  { TCharacter.side of the combatants hostile to the team: ECL sets it through EclMenu's record writes, and CbtActs's
    CheckAttackAlly turns non-player characters hostile }
  HOSTILE = 1;

implementation

end.
