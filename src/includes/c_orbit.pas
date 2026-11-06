{ The orbit map: where it stands on the screen, its center cell, and the rocket's tiles, one for each heading. }
unit C_Orbit;

interface

const
  { TOrbitView.rocketIcon at heading 0, north; at heading d it is FIRST_ROCKET_ICON + d: GameInit starts the rocket on
    it, and Explore's MoveRocket turns it through FIRST_ROCKET_ICON..LAST_ROCKET_ICON }
  FIRST_ROCKET_ICON = 87;
  { screen column of the orbit map's left edge }
  MAP_LEFT = 17;
  { screen row of its top edge }
  MAP_TOP = 1;
  { the center body's map cell, which the rocket never enters }
  CENTER_X = 11;
  CENTER_Y = 10;

implementation

end.
