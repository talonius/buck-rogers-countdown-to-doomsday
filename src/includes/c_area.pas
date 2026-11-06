{ The area kinds, zone 0's areaKind values, and its zero-gravity bit. }
unit C_Area;

interface

const
  { zone 0's areaKind values: what sort of place the party is in, which picks the combat tiles, the big pictures and the
    map display }
  { CombatSt lays its arenas from the 'venuscom' tiles. Note: SaveLoad's LoadGame asks for big picture 72, which no
    BIGPIC file holds }
  VENUS_WILDERNESS = $A2;
  { CombatSt lays its arenas from the 'marscom' tiles. Note: SaveLoad's LoadGame asks for big picture 71, which no
    BIGPIC file holds }
  MARS_WILDERNESS = $A8;
  { in orbit: EclMenu's WriteGbvm switches to the orbit map and MapView shows the planet }
  ORBIT = $70;
  { set in zero gravity: CbtActs's clouds and Zero-G roll, CombatAi's grenade choice }
  ZERO_GRAVITY = $10;

implementation

end.
