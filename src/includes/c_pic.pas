{ Pictures and animations: the ids that name none, the color they are transparent in, and the DAC ranges their palettes
  load into. }
unit C_Pic;

interface

const
  { a resourceId naming no animation, for which Portrait's LoadAnimation returns at once; the picture id ECL passes for
    none (monsterPictureId, EclMenu's DisplayMonster, EclVm's ShowPicture); and cachedAnimationId and savedPicArcId with
    none loaded }
  NO_ANIMATION = 255;
  { bigPictureId when bigPicture holds no BIGPIC record, so that Portrait's LoadBigPic loads the next one asked for }
  NO_BIG_PICTURE = 255;
  { the color tile sets, portrait animations and the wilderness cursor are transparent in: Sym8x8 and GameInit load
    theirs keyed on it; Portrait keys each frame on it, and swaps it with 0 in a sprite archive's }
  KEY_COLOR = 13;
  { the DAC ranges, first register and count, that more than one unit loads or shadows }
  { viewPalette's $10..$1F: GameInit shadows the tile sets' colors there, FixMain after its title menu and Intro's
    Credits load it, and Intro's title pictures load their colors into it }
  VIEW_DAC_FIRST = $10;
  VIEW_DAC_COUNT = 16;
  { $20..$FF, where Portrait loads an animation or the big picture, and OrbitMap's EnterOrbitMap and ShipCbt's
    ShipCombat a ship picture }
  PICTURE_DAC_FIRST = $20;
  PICTURE_DAC_COUNT = 224;
  { $40..$FF, where Portrait's LoadAnimation loads an animation shown in C_Ifc.ORBIT_MAP, and SaveLoad's LoadShipData
    the enemy ship's picture }
  ORBIT_DAC_FIRST = $40;
  ORBIT_DAC_COUNT = 192;
  { $20..$B3: View3D's LoadWallSet shadows a wall set's colors into viewPalette there, and MapView's DisplayMapView
    loads it }
  WALL_DAC_FIRST = $20;
  WALL_DAC_COUNT = 148;
  { $60..$8F: MapTiles' LoadIconAnim shadows CHARS icons' colors into combatPalette there, and CharGen's icon screen
    loads it from picturePalette }
  CHARS_ICON_DAC_FIRST = $60;
  CHARS_ICON_DAC_COUNT = 48;

implementation

end.
