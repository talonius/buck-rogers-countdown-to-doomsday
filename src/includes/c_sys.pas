{ The ship systems, TShip.systemStatus's index. }
unit C_Sys;

interface

const
  { the ship systems, TShip.systemStatus's index, in shipSystemNames' and systemShortNames' order. PostCbt's repair
    skips C_Sys.FUEL: no crew skill repairs fuel }
  HULL = 0;
  SENSORS = 1;
  CONTROL = 2;
  FUEL = 4;
  ENGINES = 5;
  { systemShortNames' last entry: the weapon mounts, which systemStatus has no entry for }
  WEAPONS = 6;

implementation

end.
