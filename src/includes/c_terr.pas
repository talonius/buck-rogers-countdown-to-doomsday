{ The arena terrain values the code names: the last kind of ground combat terrain, the cost no move can pay, the markers
  that clouds and downed combatants lay, the wilderness ground not yet laid, and the flags of a wilderness scatter rule
  (TTerrainProfile.flags). }
unit C_Terr;

interface

const
  { the last kind of ground combat terrain: CbtMap draws a cell holding a higher value as terrain 21 }
  LAST_COMBAT_TERRAIN = 154;
  { a combatTerrain cost no move can pay; CbtActs, CbtMap, CombatSt, Combat, CombatAi }
  IMPASSABLE = 255;
  { the marker a Chaff Grenade's cloud, projectile kind 8, lays on the arena cells it covers: Pathing's WalkLine reports
    crossing it, a missile or grenade whose line meets it 'hits chaff' there, and CbtActs's CalcWeaponDamage cancels a
    rocket weapon's damage across it; CombatAi tests for it }
  CHAFF_TERRAIN = 1;
  { the marker a Gas Grenade's cloud, projectile kind 7, lays: CbtMap's ProbeDirection reports it harmful, and
    FxEngine's ConsiderTerrainEffects makes a character on it helpless on a failed save, as the blast does, unless its
    armorFlags has C_Armor.BREATHING_PROTECTION }
  GAS_TERRAIN = 2;
  { the marker an Aerosol Mist Grenade's cloud, projectile kind 9, lays: WalkLine reports crossing it, and
    CalcWeaponDamage cancels a laser weapon's damage across it; CombatAi tests for it }
  AEROSOL_MIST_TERRAIN = 4;
  { the marker a downed combatant leaves on its cell, over the terrain its downedCreatures record keeps: CbtMap's
    CreatureDowned and CombatSt's PlaceAllCreatures lay it, FxEngine lays it again as a cloud over the cell clears, and
    CbtMap's lookups and CbtActs's combat cursor test for it }
  CORPSE_TERRAIN = 5;
  { wilderness ground not yet given a tile; as a profile's pairTile, no pair }
  UNSET_TERRAIN = 6;
  { the pair tile goes below the tile, not to its right }
  PROFILE_PAIR_BELOW = $01;
  { a run rolls its tiles once, for its first plot }
  PROFILE_ONE_ROLL = $02;
  { the pair tile takes the tile's roll instead of its own }
  PROFILE_PAIR_FOLLOWS = $04;
  { the variance rolls are doubled }
  PROFILE_DOUBLE_VARIANCE = $08;
  { a run keeps the previous run's center }
  PROFILE_KEEP_CENTER = $10;
  { every plot falls exactly scatter cells from the center }
  PROFILE_FIXED_SCATTER = $20;

implementation

end.
