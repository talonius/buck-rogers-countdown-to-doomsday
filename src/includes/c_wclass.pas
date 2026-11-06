{ The weapon classes, TItemType.weaponClass's values, and C_WClass.FIRST_AREA_WEAPON, the first of the area weapons. }
unit C_WClass;

interface

const
  { TItemType.weaponClass values for a weapon, each named for the ITEMS rows that hold it. The effects that cancel hits
    and the armor bits test them one by one }
  { the weapons of range 0: ITEMS rows 1..4, 8 and 19 }
  MELEE = 0;
  { D.R. X-bow, Needle Gun and Bolt Gun }
  SLUG = 1;
  { Rocket Pistol and Rocket Rifle }
  ROCKET = 2;
  { Laser Pistol and Laser Rifle }
  LASER = 3;
  { Microwave Gun }
  MICROWAVE = 4;
  { Rocket Lnchr.; it and the next two are the area weapons }
  ROCKET_LAUNCHER = 7;
  { ITEMS rows 32..38, the grenades: ITEM0.DAX's template 32 is a mini Explosive Grenade }
  GRENADE = 8;
  { Plasma Thrwr }
  PLASMA = 9;
  { C_WClass.ROCKET_LAUNCHER..C_WClass.PLASMA are the area weapons }
  FIRST_AREA_WEAPON = C_WClass.ROCKET_LAUNCHER;

implementation

end.
