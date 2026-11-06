{ The eight compass directions and C_Dir.CENTER. dirStepX and dirStepY are indexed by them, and blockCellDirections and
  directionByDelta hold them. }
unit C_Dir;

interface

const
  { the directions, clockwise from north; dirStepX's and dirStepY's index. The 3-D view's partyPosition.facing takes the
    four even ones }
  NORTH = 0;
  NORTHEAST = 1;
  EAST = 2;
  SOUTHEAST = 3;
  SOUTH = 4;
  SOUTHWEST = 5;
  WEST = 6;
  NORTHWEST = 7;
  { the cell itself, no direction; dirStepX's and directionByDelta's 8 entry steps nowhere. Used for Combat's MoveMenu
    with no direction key, CombatAi's lastMoveDir before a first step, CbtActs's combat cursor at rest, and Explore's
    MoveRocket with no move }
  CENTER = 8;

implementation

end.
