{ The post-combat modes, zone 0's postCombatMode: what PostCbt's PostCombat does after a fight. }
unit C_PostCb;

interface

const
  { zone 0's postCombatMode: what PostCbt's PostCombat does after a fight. ECL may also set bit 7, so these need not be
    its only values. }
  { treat, repair and offer loot; ShipCbt sets it as a ship combat starts }
  NORMAL = 0;
  { ShipCbt: the team boarded the enemy ship; PostCombat skips treatment, the ship's repair and the experience share it
    pays out, the summary and loot }
  BOARDED = 1;

implementation

end.
