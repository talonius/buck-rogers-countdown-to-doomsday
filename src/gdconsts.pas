{ Initialized data: the data segment's typed constants, grouped by the subsystem that reads them and kept in address
  order. A new section starts wherever the data needs a word boundary. }
unit GDConsts;

interface

uses Types, C_Terr, C_Dir, C_Effect, C_Keys, C_Skill, C_Msg, C_Screen, C_Sys, C_Save;

{ ECL sounds. }
const
  { sound command for each ECL sound argument. Note: EclPlaySound accepts any argument up to 127, past the table's end }
  eclSoundCommands: array[0..20] of Byte = (
    0, 12, 9, 16, 7, 10, 11, 18, 14, 3, 4, 5, 6, 8, 13, 17, 16, 19, 19, 19, 20
  );

{ Shop stock: the item lists ECL's shop command stocks a shop from. }
const
  { first itemListEntries entry of each list a shop can stock. Note: EclShop does not bound the list number }
  itemListStarts: array[1..16] of Byte = (
    1, 17, 22, 26, 33, 37, 42, 46, 51, 61, 69, 73, 79, 83, 88, 92
  );
  { number of entries in each item list }
  itemListCounts: array[1..16] of Byte = (
    16, 5, 4, 7, 4, 5, 4, 5, 10, 8, 4, 6, 4, 5, 4, 38
  );
  { item-source index of each item-list entry }
  itemListEntries: array[1..129] of Byte = (
    1, 3, 4, 6, 7, 9, 10, 12, 14, 15, 20, 21, 28, 29, 30, 31, 2, 8, 11, 13, 16, 22, 27, 29, 30, 2, 3, 4, 6,
    8, 9, 13, 20, 21, 27, 31, 2, 8, 11, 13, 16, 20, 26, 28, 29, 39, 42, 45, 47, 51, 26, 27, 30, 31, 35, 36,
    37, 38, 92, 93, 1, 2, 3, 4, 8, 19, 40, 41, 9, 13, 45, 48, 26, 34, 35, 36, 37, 38, 1, 3, 14, 16, 20, 21,
    22, 27, 30, 10, 11, 46, 50, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21,
    22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38
  );

{ Ship combat: where a hit on a ship lands. }
const
  { percent chance a random hit strikes each ship system, 100 in all }
  systemHitChances: array[0..6] of ShortInt = (
    28, 9, 9, 13, 10, 18, 13
  );

{ The copy-protection questions, the post-combat treasure line, and the ship repair tables. }
const
  { the questions, text encoded }
  protectionQuestions: array[1..39] of Types.TProtectionEntry = (
    (page: 1; displayText: '4678';
     wordIndex: 4; answer: 'Dwem'),
    (page: 2; displayText: '/123%Klt&';
     wordIndex: 7; answer: 'QHR'),
    (page: 3; displayText: 'BdgZ'#21'dc'#21'6W^a^i^Zh';
     wordIndex: 8; answer: 'tubsu'),
    (page: 4; displayText: ':_XiXZk\i'#23'IXZ\j';
     wordIndex: 8; answer: 'sbdft'),
    (page: 5; displayText: 'B`qddqr';
     wordIndex: 9; answer: 'htqo'),
    (page: 6; displayText: 'Rogues';
     wordIndex: 1; answer: 'nkxg'),
    (page: 7; displayText: 'Skills';
     wordIndex: 5; answer: 'sj'),
    (page: 8; displayText: 'Ngnl^]'#25'Ldbeel';
     wordIndex: 2; answer: 'ihz'),
    (page: 9; displayText: 'G_^c]'#26'Mecffm';
     wordIndex: 8; answer: 'nature'),
    (page: 10; displayText: 'Ogehho'#28'Iet';
     wordIndex: 4; answer: 'apgrga_j'),
    (page: 11; displayText: 'Npofz';
     wordIndex: 10; answer: 'asppclaw'),
    (page: 12; displayText: 'Damage';
     wordIndex: 9; answer: 'damage'),
    (page: 13; displayText: 'Sbohf';
     wordIndex: 6; answer: 'tipsu'),
    (page: 14; displayText: 'Mj^f`oncdkn';
     wordIndex: 3; answer: 'fu|'),
    (page: 15; displayText: 'Ldqbtqx';
     wordIndex: 4; answer: 'vxq'),
    (page: 16; displayText: 'Fbsui';
     wordIndex: 5; answer: 'humans'),
    (page: 17; displayText: 'Octu';
     wordIndex: 2; answer: 'jqog'),
    (page: 18; displayText: 'R`ku`fd';
     wordIndex: 6; answer: 'an`qcdc'),
    (page: 19; displayText: 'JYf_]\'#24'O]Yhgfk';
     wordIndex: 1; answer: 'Dqnv'),
    (page: 21; displayText: 'A_[l'#26'Ko[fcns';
     wordIndex: 7; answer: 'xct{'),
    (page: 22; displayText: 'Sdqqhmd';
     wordIndex: 2; answer: 'killer'),
    (page: 23; displayText: 'M]in!m'#26';f[lg';
     wordIndex: 4; answer: '|rx'),
    (page: 24; displayText: 'Nb_'#26'?f_p[nil';
     wordIndex: 5; answer: 'nkgu'),
    (page: 26; displayText: 'AYYh]b['#20'k]h\'#20'FcVch';
     wordIndex: 4; answer: 'UDP'),
    (page: 27; displayText: 'K_\'#23'B`e^'#23'`e'#23'''$>';
     wordIndex: 3; answer: 'Htqi'),
    (page: 28; displayText: 'JgZgl'#24'Yf\'#24':m[c';
     wordIndex: 5; answer: 'dwsdmcr'),
    (page: 29; displayText: ':m[c'#31'k'#24'Kh]][`&';
     wordIndex: 7; answer: 'ujkr'),
    (page: 30; displayText: 'Alg`k\i'#23'8ii`mXc';
     wordIndex: 6; answer: 'jdv'),
    (page: 31; displayText: '9ZhZgi'#21'6eZ'#21'E^adih';
     wordIndex: 2; answer: 'dsptt'),
    (page: 32; displayText: 'L`]'#24'?j]Yl'#24'Ja^l';
     wordIndex: 3; answer: 'tkhv'),
    (page: 33; displayText: 'LYdgf'#31'k'#24'Kh]][`';
     wordIndex: 5; answer: 'mknn'),
    (page: 34; displayText: '=^bfhl'#25'Ikblhg';
     wordIndex: 10; answer: 'xs'),
    (page: 35; displayText: ':m[c'#31'k'#24';Yhlmj]';
     wordIndex: 8; answer: 'ufbst'),
    (page: 36; displayText: '9[a\a['#24'Na[lgjq';
     wordIndex: 7; answer: 'Mkpi'),
    (page: 37; displayText: ';f_ln'#26'M]l__h';
     wordIndex: 3; answer: 'sfbet'),
    (page: 38; displayText: 'E^gl'#25'Mk^Zmbl^';
     wordIndex: 9; answer: 'citing'),
    (page: 39; displayText: '?nnclbgv';
     wordIndex: 1; answer: 'Racial'),
    (page: 41; displayText: 'J[Y^d_YWb'#22'Ia_bbi';
     wordIndex: 2; answer: 'Qcaspgrw'),
    (page: 42; displayText: 'Spmm/';
     wordIndex: 4; answer: 'vgto')
  );
  { head of the after-combat treasure line }
  treasureFoundText: String[21] = 'The team has found ';
  { tail of the treasure line, after 'no ' when there is none }
  treasureBootyText: String[7] = 'booty!';
  { skill that repairs each ship system (255: fuel has none), then Repair Weapon }
  repairSkills: array[C_Sys.HULL..C_Sys.WEAPONS] of Byte = (
    C_Skill.REPAIR_HULL, C_Skill.REPAIR_ELECTRICAL, C_Skill.REPAIR_MECHANICAL,
    C_Skill.REPAIR_LIFE_SUPPORT,
    255, C_Skill.REPAIR_ENGINE, C_Skill.REPAIR_WEAPON
  );
  { how many d10 RepairShip rolls to repair each ship system; it skips C_Sys.FUEL }
  repairDice: array[C_Sys.HULL..C_Sys.ENGINES] of Byte = (
    20, 4, 4, 8, 0, 12
  );

{ Combat AI: the step turns and the area blast shapes. }
const
  { turn, in eighths, added to a creature's heading on each attempt to step, by approach. Note: when all five attempts
    fail, AiMoveStep reads a sixth entry past the end of the row into a direction it never uses }
  aiDirOffsets: array[1..6, 1..5] of Byte = (
    (8, 7, 6, 1, 2), (8, 1, 2, 7, 6), (7, 1, 8, 6, 2), (1, 7, 8, 2, 6), (8, 7, 6, 5, 4), (8, 1, 2, 3, 4)
  );
  { half-width of an area blast per row offset and area class, negative for none }
  areaHalfWidths: array[-3..3, 1..3] of ShortInt = (
    (-3, -3, 1), (-3, 1, 2), (1, 2, 3), (1, 2, 3), (1, 2, 3), (-3, 1, 2), (-3, -3, 1)
  );

{ Combat set-up: the placement rings, the arena blocks a map square lays and the wilderness scatter rules; then the
  default palette, the acid message and the projectile kinds. }
const
  { direction 0..7 from a team's placement origin to the block that ring 1..3 is tried in, by facing quarter; column 0
    holds 8, no direction, and FindPlacement indexes it by ring 1..3 }
  ringBlockDirections: array[0..3, 0..3] of Byte = (
    (8, 4, 6, 2), (8, 6, 4, 0), (8, 0, 6, 2), (8, 2, 0, 4)
  );
  { direction 0..7 a placement ring is laid out facing, by the team's facing quarter and ring; FindPlacement halves it
    to a quarter }
  facingDirections: array[0..3, 0..3] of Byte = (
    (0, 0, 2, 6), (2, 2, 0, 4), (4, 4, 2, 6), (6, 6, 4, 0)
  );
  { direction 0..7 of each quarter, for FindPlacement's steps along a placement ring; PlaceAllCreatures also stores it
    in each placed creature's combat record }
  quarterDirections: array[0..3] of Byte = (
    7, 2, 3, 6
  );
  { column a placement ring starts at, [0] for ring 0 and [1] for the later rings, by the quarter it faces }
  ringStartColumns: array[0..1, 0..3] of ShortInt = (
    (5, 4, 5, 6), (3, 8, 7, 2)
  );
  { row a placement ring starts at, [0] for ring 0 and [1] for the later rings, by the quarter it faces }
  ringStartRows: array[0..1, 0..3] of ShortInt = (
    (3, 2, 2, 3), (0, 2, 5, 3)
  );
  { first and last open column of each row of a ring's placement grid, by facing quarter, 4 for ring 1; lo > hi opens
    none }
  columnRanges: array[0..4, 0..5] of Types.TColumnRange = (
    ((lo: 1; hi: 0), (lo: 1; hi: 0), (lo: 1; hi: 0), (lo: 2; hi: 9), (lo: 3; hi: 10), (lo: 4; hi: 10)),
    ((lo: 0; hi: 2), (lo: 0; hi: 3), (lo: 1; hi: 4), (lo: 2; hi: 5), (lo: 3; hi: 6), (lo: 4; hi: 7)),
    ((lo: 0; hi: 6), (lo: 0; hi: 7), (lo: 1; hi: 8), (lo: 1; hi: 0), (lo: 1; hi: 0), (lo: 1; hi: 0)),
    ((lo: 3; hi: 6), (lo: 4; hi: 7), (lo: 5; hi: 8), (lo: 6; hi: 9), (lo: 7; hi: 10), (lo: 8; hi: 10)),
    ((lo: 0; hi: 6), (lo: 0; hi: 7), (lo: 1; hi: 8), (lo: 2; hi: 9), (lo: 3; hi: 10), (lo: 4; hi: 10))
  );
  { tile at rows 0..1, columns 1..2 of a map square's arena block, by the walls at its left corner as a state 1..15; 255
    leaves the cell }
  leftWallTiles: array[1..15, 0..1, 1..2] of Byte = (
    ((24, 24), (25, 25)), ((36, 255), (28, 26)), ((7, 24), (9, 10)), ((31, 255), (32, 255)),
    ((24, 24), (25, 25)), ((14, 255), (13, 26)), ((11, 24), (13, 10)), ((34, 255), (38, 255)),
    ((17, 24), (18, 25)), ((26, 255), (28, 26)), ((15, 24), (28, 10)), ((22, 255), (23, 255)),
    ((21, 24), (25, 25)), ((16, 255), (13, 26)), ((40, 24), (13, 10))
  );
  { tile at rows 0..1, columns 5..6 of a map square's arena block, by the walls at its right corner as a state 1..15;
    255 leaves the cell }
  rightWallTiles: array[1..15, 0..1, 5..6] of Byte = (
    ((255, 31), (255, 33)), ((255, 35), (255, 39)), ((255, 255), (255, 8)), ((24, 24), (25, 25)),
    ((24, 24), (25, 25)), ((24, 24), (25, 12)), ((24, 24), (25, 12)), ((27, 29), (255, 37)),
    ((27, 28), (255, 27)), ((27, 28), (255, 27)), ((27, 28), (255, 27)), ((19, 20), (25, 25)),
    ((19, 20), (25, 25)), ((19, 20), (25, 12)), ((19, 20), (25, 12))
  );
  { the wilderness scatter rules, by the profile number BuildWilderness is handed }
  terrainProfiles: array[1..22] of Types.TTerrainProfile = (
    (chance: 50; diceCount: 6; diceSides: 12; clearance: 0; scatter: 12; scatterBonus: 12;
     flags: $00; tile: 112; pairTile: C_Terr.UNSET_TERRAIN; tileVariance: 3; pairVariance: 0),
    (chance: 50; diceCount: 4; diceSides: 10; clearance: 0; scatter: 30; scatterBonus: 0;
     flags: $00; tile: 112; pairTile: C_Terr.UNSET_TERRAIN; tileVariance: 3; pairVariance: 0),
    (chance: 80; diceCount: 4; diceSides: 10; clearance: 0; scatter: 10; scatterBonus: 10;
     flags: $00; tile: 115; pairTile: C_Terr.UNSET_TERRAIN; tileVariance: 3; pairVariance: 0),
    (chance: 90; diceCount: 3; diceSides: 8; clearance: 0; scatter: 30; scatterBonus: 0;
     flags: $00; tile: 115; pairTile: C_Terr.UNSET_TERRAIN; tileVariance: 3; pairVariance: 0),
    (chance: 80; diceCount: 3; diceSides: 8; clearance: 0; scatter: 12; scatterBonus: 0;
     flags: C_Terr.PROFILE_PAIR_BELOW; tile: 118; pairTile: 130; tileVariance: 0; pairVariance: 0),
    (chance: 80; diceCount: 4; diceSides: 10; clearance: 0; scatter: 40; scatterBonus: 0;
     flags: C_Terr.PROFILE_PAIR_BELOW; tile: 119; pairTile: 127; tileVariance: 4; pairVariance: 3),
    (chance: 80; diceCount: 4; diceSides: 20; clearance: 0; scatter: 10; scatterBonus: 10;
     flags: C_Terr.PROFILE_PAIR_BELOW + C_Terr.PROFILE_ONE_ROLL;
     tile: 119; pairTile: 127; tileVariance: 8; pairVariance: 3),
    (chance: 80; diceCount: 2; diceSides: 12; clearance: 0; scatter: 20; scatterBonus: 0;
     flags: $00; tile: 104; pairTile: C_Terr.UNSET_TERRAIN; tileVariance: 0; pairVariance: 0),
    (chance: 90; diceCount: 4; diceSides: 10; clearance: 0; scatter: 10; scatterBonus: 5;
     flags: C_Terr.PROFILE_ONE_ROLL; tile: 102; pairTile: C_Terr.UNSET_TERRAIN; tileVariance: 6; pairVariance: 0),
    (chance: 80; diceCount: 2; diceSides: 5; clearance: 0; scatter: 8; scatterBonus: 10;
     flags: $00; tile: 110; pairTile: 111; tileVariance: 0; pairVariance: 0),
    (chance: 80; diceCount: 2; diceSides: 10; clearance: 1; scatter: 40; scatterBonus: 0;
     flags: C_Terr.PROFILE_PAIR_FOLLOWS + C_Terr.PROFILE_DOUBLE_VARIANCE;
     tile: 69; pairTile: 70; tileVariance: 5; pairVariance: 0),
    (chance: 80; diceCount: 3; diceSides: 8; clearance: 0; scatter: 15; scatterBonus: 20;
     flags: $00; tile: 79; pairTile: C_Terr.UNSET_TERRAIN; tileVariance: 3; pairVariance: 0),
    (chance: 80; diceCount: 4; diceSides: 12; clearance: 0; scatter: 15; scatterBonus: 20;
     flags: $00; tile: 82; pairTile: C_Terr.UNSET_TERRAIN; tileVariance: 7; pairVariance: 0),
    (chance: 100; diceCount: 10; diceSides: 20; clearance: 0; scatter: 9; scatterBonus: 4;
     flags: $00; tile: 91; pairTile: C_Terr.UNSET_TERRAIN; tileVariance: 0; pairVariance: 0),
    (chance: 80; diceCount: 5; diceSides: 10; clearance: 0; scatter: 10; scatterBonus: 10;
     flags: C_Terr.PROFILE_PAIR_BELOW + C_Terr.PROFILE_ONE_ROLL;
     tile: 100; pairTile: 98; tileVariance: 2; pairVariance: 2),
    (chance: 100; diceCount: 1; diceSides: 6; clearance: 0; scatter: 5; scatterBonus: 0;
     flags: C_Terr.PROFILE_KEEP_CENTER; tile: 92; pairTile: 93; tileVariance: 0; pairVariance: 0),
    (chance: 80; diceCount: 1; diceSides: 10; clearance: 1; scatter: 5; scatterBonus: 10;
     flags: $00; tile: 92; pairTile: 93; tileVariance: 0; pairVariance: 0),
    (chance: 80; diceCount: 5; diceSides: 10; clearance: 0; scatter: 15; scatterBonus: 15;
     flags: C_Terr.PROFILE_ONE_ROLL; tile: 94; pairTile: C_Terr.UNSET_TERRAIN; tileVariance: 4; pairVariance: 0),
    (chance: 100; diceCount: 10; diceSides: 8; clearance: 0; scatter: 0; scatterBonus: 0;
     flags: C_Terr.PROFILE_KEEP_CENTER + C_Terr.PROFILE_FIXED_SCATTER;
     tile: 79; pairTile: C_Terr.UNSET_TERRAIN; tileVariance: 10; pairVariance: 0),
    (chance: 80; diceCount: 3; diceSides: 10; clearance: 0; scatter: 10; scatterBonus: 10;
     flags: C_Terr.PROFILE_PAIR_BELOW + C_Terr.PROFILE_ONE_ROLL;
     tile: 137; pairTile: 135; tileVariance: 2; pairVariance: 2),
    (chance: 80; diceCount: 3; diceSides: 10; clearance: 0; scatter: 15; scatterBonus: 15;
     flags: C_Terr.PROFILE_ONE_ROLL; tile: 131; pairTile: C_Terr.UNSET_TERRAIN; tileVariance: 4; pairVariance: 0),
    (chance: 80; diceCount: 10; diceSides: 10; clearance: 0; scatter: 15; scatterBonus: 10;
     flags: $00; tile: 154; pairTile: C_Terr.UNSET_TERRAIN; tileVariance: 0; pairVariance: 0)
  );
  { The 16 colors; InitializeGame loads them into the palette. }
  defaultPalette: array[0..15] of Types.TRgb = (
    ($00, $00, $00), ($00, $00, $AA), ($00, $AA, $00), ($00, $AA, $AA), ($AA, $00, $00), ($AA, $00, $AA),
    ($AA, $55, $00), ($AA, $AA, $AA), ($55, $55, $55), ($55, $55, $FF), ($55, $FF, $55), ($55, $FF, $FF),
    ($FF, $55, $55), ($FF, $55, $FF), ($FF, $FF, $55), ($FF, $FF, $FF)
  );
  { combat line after a creature's name when it spits acid }
  acidMessage: String = 'spits acid';
  { area effect of projectile kinds 4..12: MakeAttack launches 5..12, and CombatLaunchProjectile tests kind 4; kinds
    below 4 have no entry }
  projectileKinds: array[4..12] of Types.TProjectileKindInfo = (
    (effectId: C_Effect.HELPLESS; radius: 1; isLingering: True; saveType: 1; saveReduction: C_Save.CANCELS),
    (effectId: C_Effect.BLIND; radius: 1; isLingering: False; saveType: 3; saveReduction: C_Save.CANCELS),
    (effectId: 0; radius: 1; isLingering: False; saveType: 2; saveReduction: C_Save.HALVES),
    (effectId: C_Effect.HELPLESS; radius: 1; isLingering: True; saveType: 1; saveReduction: C_Save.CANCELS),
    (effectId: 0; radius: 1; isLingering: True; saveType: 7; saveReduction: C_Save.NO_EFFECT),
    (effectId: 0; radius: 1; isLingering: True; saveType: 7; saveReduction: C_Save.NO_EFFECT),
    (effectId: 0; radius: 3; isLingering: False; saveType: 2; saveReduction: C_Save.HALVES),
    (effectId: 0; radius: 2; isLingering: False; saveType: 2; saveReduction: C_Save.HALVES),
    (effectId: C_Effect.STUNNED; radius: 1; isLingering: False; saveType: 0; saveReduction: C_Save.CANCELS)
  );

{ Exploration and character creation menus: the map menu lines, message speeds, the party order menu and orbit steps,
  the main menu, starting icons, free ammunition and ammunition prices, and the character sheet's blanks and ability
  names. }
const
  { the dungeon's main menu line }
  dungeonMenu: String[40] = 'Move Area View Look Change Save';
  { the Change menu's first options, left off on the orbit map }
  changeMenuHead: String[40] = 'Order Purge ';
  { the difficulty level menu line }
  difficultyMenu: String[40] = 'Novice Cadet Trooper Veteran Ace Exit';
  { the Change menu's remaining options }
  changeMenuTail: String[40] = 'Messages Anim Level Exit';
  { words naming a message speed }
  speedWords: array[0..2] of String[7] = (
    'Slow', 'Average', 'Fast'
  );
  { suffixes that grade a speed word }
  speedSuffixes: array[0..2] of String[3] = (
    '', 'er', 'est'
  );
  { per message speed, the speed word (high nibble) and suffix (low bits) }
  speedWordCodes: array[0..C_Msg.SLOWEST_MESSAGE_SPEED] of Byte = (
    $22, $21, $21, $20, $10, $10, $00, $01, $01, $02
  );
  { party order menu line, [0] before a member is picked, [1] after }
  partyOrderMenus: array[0..1] of String[40] = (
    'Select Exit', 'Place Exit'
  );
  { orbit-map column step for directions 0..7 counterclockwise from north }
  mapStepX: array[0..7] of ShortInt = (
    0, -1, -1, -1, 0, 1, 1, 1
  );
  { orbit-map row step for directions 0..7 counterclockwise from north }
  mapStepY: array[0..7] of ShortInt = (
    -1, -1, 0, 1, 1, 1, 0, -1
  );
  { the main menu's entries, each listed while enabled }
  menuTable: array[0..12] of Types.TMenuRow = (
    (name: 'Create New Character'; isEnabled: True),
    (name: 'Purge Character'; isEnabled: False),
    (name: 'Modify Character'; isEnabled: False),
    (name: 'Icon Select'; isEnabled: False),
    (name: 'Train Character'; isEnabled: False),
    (name: 'View Character'; isEnabled: False),
    (name: 'Add Character to Team'; isEnabled: True),
    (name: 'Remove Character from Team'; isEnabled: False),
    (name: 'Load Saved Game'; isEnabled: True),
    (name: 'Save Current Game'; isEnabled: False),
    (name: 'Begin Adventuring'; isEnabled: False),
    (name: 'JoyStick/Mouse Initialize'; isEnabled: True),
    (name: 'Exit to DOS'; isEnabled: True)
  );
  { starting icon by gender and career; no Scout column, as the class menu offers Scout to no race }
  characterIcons: array[Types.TGender, Types.CareerRocketJock..Types.CareerRogue] of Byte = (
    (32, 0, 3, 7, 21),
    (33, 1, 6, 15, 25)
  );
  { ammo template of each of the two free ammo items }
  freeAmmoTemplates: array[1..2] of Byte = (
    7, 20
  );
  { quantity each of the two free ammo items gets in place of its template's }
  freeAmmoQuantities: array[1..2] of Byte = (
    100, 0
  );
  { price of one clip of ammo by weapon type }
  ammoPrices: array[5..18] of Word = (
    10, 5, 10, 0, 35, 50, 100, 50, 35, 100, 80, 0, 80, 100
  );
  { 15 spaces that pad a character name to its full width }
  nameBlanks: String[15] = '               ';
  { abbreviated name of each ability, on the character sheet }
  abilityAbbreviations: array[0..6] of String[4] = (
    'STR', 'DEX', 'CON', 'INT', 'WIS', 'CHA', 'TCH'
  );

{ Character rules and screens: the ability adjustments, the ship meters, the screen frames and the 3-D view's layout;
  then the game's names and prompts, the skills, item and compass names, and the first CGA drawing tables. }
const
  { The effects RemoveIncapacitatingEffects strips. }
  incapacitatingEffects: array[1..4] of Byte = (
    C_Effect.SCARED, C_Effect.HELPLESS, C_Effect.STUNNED, C_Effect.DIZZY
  );
  { armor class adjustment by dexterity }
  dexArmorAdjustments: array[1..22] of ShortInt = (
    -5, -5, -4, -3, -2, -1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 4, 4, 4, 5, 5
  );
  { adjustment by dexterity, through DexMissileAdjust: to-hit with a readied weapon that is not melee, CbtActs's
    initiative roll, a crew member's gunnery in ShipCbt's TargetValue and CombatAi's priority for a weapon that is not
    melee }
  dexMissileAdjustments: array[1..22] of ShortInt = (
    -6, -4, -3, -2, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 2, 3, 3, 4, 4
  );
  { to-hit adjustment by strength, melee and unarmed }
  strToHitAdjustments: array[1..22] of ShortInt = (
    -5, -4, -3, -2, -2, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 3, 4, 4
  );
  { damage adjustment by strength, melee and unarmed }
  strDamageAdjustments: array[1..22] of ShortInt = (
    -4, -3, -2, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 2, 4, 6, 8, 10
  );
  { weight allowance by strength; RecalcMovement halves movement past half of it }
  weightAllowances: array[1..22] of Word = (
    2, 4, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 170, 220, 400, 600, 900, 1200
  );
  { color of the upper line of each ship-system meter bar, by meter }
  meterUpperColors: array[0..5] of Byte = (
    15, 11, 12, 14, 9, 13
  );
  { color of the lower line of each ship-system meter bar, by meter }
  meterLowerColors: array[0..5] of Byte = (
    7, 3, 4, 12, 1, 5
  );
  { ship-combat maneuver names, shown over the combat scene by DrawShipSceneText, which indexes them by the Boolean
    isEnemyRetreating: 'Maneuvering' is never shown }
  maneuverNames: array[0..2] of String[11] = (
    'Closing    ', 'Retreating ', 'Maneuvering'
  );
  { orbit map frame }
  orbitMapFrame: record runs: array[0..5] of Types.TFrameRun; stop: array[0..1] of Byte end = (
    runs: (
      (x1: 2; y1: 2; x2: 14; y2: 2; firstSel: 0; lastSel: 1),
      (x1: 2; y1: 2; x2: 2; y2: 14; firstSel: 0; lastSel: 3),
      (x1: 14; y1: 2; x2: 14; y2: 14; firstSel: 1; lastSel: 2),
      (x1: 2; y1: 14; x2: 14; y2: 14; firstSel: 3; lastSel: 2),
      (x1: 16; y1: 0; x2: 16; y2: 23; firstSel: 6; lastSel: 8),
      (x1: 0; y1: 16; x2: 16; y2: 16; firstSel: 9; lastSel: 7)
    );
    { the end marker Border.DrawFrameSegments stops at }
    stop: (C_Screen.FRAME_SCRIPT_END, 0)
  );
  { scan code of the key for each direction N, NE .. NW; an arena click answers the key toward the clicked cell }
  directionKeys: array[0..7] of Char = 'HIMQPOKG';
  { sky color for each of an area's sky indexes }
  skyColors: array[0..15] of Byte = (
    0, 15, 4, 11, 13, 2, 9, 14, 0, 15, 4, 11, 13, 2, 9, 14
  );
  { where the 3-D view draws each of its ten wall slots }
  viewWallSlots: Types.TWallSlots = (
    start: (0, 2, 6, 10, 22, 38, 54, 110, 132, 154);
    cols: (1, 1, 1, 3, 2, 2, 7, 2, 2, 1);
    rows: (2, 4, 4, 4, 8, 8, 8, 11, 11, 2);
    xCol: (5, 4, 6, 4, 2, 7, 2, 0, 9, 5);
    yRow: (4, 3, 3, 3, 1, 1, 1, 0, 0, 4)
  );
  { the main screen frame }
  mainFrame: Types.TBoxFrame = (
    runs: (
      (x1: 0; y1: 0; x2: 39; y2: 0; firstSel: 0; lastSel: 1),
      (x1: 0; y1: 0; x2: 0; y2: 23; firstSel: 0; lastSel: 3),
      (x1: 39; y1: 0; x2: 39; y2: 23; firstSel: 1; lastSel: 2),
      (x1: 0; y1: 23; x2: 39; y2: 23; firstSel: 3; lastSel: 2)
    );
    stop: (C_Screen.FRAME_SCRIPT_END, 0)
  );
  { the credits screen's frame: the same runs as mainFrame }
  creditsFrame: Types.TBoxFrame = (
    runs: (
      (x1: 0; y1: 0; x2: 39; y2: 0; firstSel: 0; lastSel: 1),
      (x1: 0; y1: 0; x2: 0; y2: 23; firstSel: 0; lastSel: 3),
      (x1: 39; y1: 0; x2: 39; y2: 23; firstSel: 1; lastSel: 2),
      (x1: 0; y1: 23; x2: 39; y2: 23; firstSel: 3; lastSel: 2)
    );
    stop: (C_Screen.FRAME_SCRIPT_END, 0)
  );
  { the exploration screen's divider and the box that holds the 3-D view or a picture, drawn over the text screen's
    frame }
  exploreFrame: Types.TBoxLineFrame = (
    runs: (
      (x1: 16; y1: 0; x2: 16; y2: 16; firstSel: 6; lastSel: 8),
      (x1: 2; y1: 2; x2: 14; y2: 2; firstSel: 0; lastSel: 1),
      (x1: 2; y1: 14; x2: 14; y2: 14; firstSel: 3; lastSel: 2),
      (x1: 2; y1: 2; x2: 2; y2: 14; firstSel: 0; lastSel: 3),
      (x1: 14; y1: 2; x2: 14; y2: 14; firstSel: 1; lastSel: 2)
    );
    stop: (C_Screen.FRAME_SCRIPT_END, 0)
  );
  { the ship screen, for ship combat and the ship views: the scene, the system meters and weapons at the right, messages
    below }
  shipFrame: record runs: array[0..6] of Types.TFrameRun; stop: array[0..1] of Byte end = (
    runs: (
      (x1: 0; y1: 0; x2: 39; y2: 0; firstSel: 0; lastSel: 1),
      (x1: 0; y1: 0; x2: 0; y2: 22; firstSel: 0; lastSel: 3),
      (x1: 39; y1: 0; x2: 39; y2: 22; firstSel: 1; lastSel: 2),
      (x1: 0; y1: 22; x2: 39; y2: 22; firstSel: 3; lastSel: 2),
      (x1: 0; y1: 18; x2: 39; y2: 18; firstSel: 9; lastSel: 7),
      (x1: 25; y1: 0; x2: 25; y2: 18; firstSel: 6; lastSel: 8),
      (x1: 25; y1: 13; x2: 39; y2: 13; firstSel: 9; lastSel: 7)
    );
    stop: (C_Screen.FRAME_SCRIPT_END, 0)
  );
  { the ground combat screen: the battle map at the left, the combatant's details at the right of column 22 }
  combatFrame: Types.TBoxLineFrame = (
    runs: (
      (x1: 0; y1: 0; x2: 39; y2: 0; firstSel: 0; lastSel: 1),
      (x1: 0; y1: 0; x2: 0; y2: 22; firstSel: 0; lastSel: 3),
      (x1: 39; y1: 0; x2: 39; y2: 22; firstSel: 1; lastSel: 2),
      (x1: 0; y1: 22; x2: 39; y2: 22; firstSel: 3; lastSel: 2),
      (x1: 22; y1: 0; x2: 22; y2: 22; firstSel: 6; lastSel: 8)
    );
    stop: (C_Screen.FRAME_SCRIPT_END, 0)
  );
  { the character sheet's dividers inside the main frame: under the identity rows, under the combat rows, and between
    the abilities and the career skills }
  characterSheetFrame: record runs: array[0..2] of Types.TFrameRun; stop: array[0..1] of Byte end = (
    runs: (
      (x1: 0; y1: 8; x2: 39; y2: 8; firstSel: 9; lastSel: 7),
      (x1: 0; y1: 13; x2: 39; y2: 13; firstSel: 9; lastSel: 7),
      (x1: 11; y1: 13; x2: 11; y2: 23; firstSel: 6; lastSel: 8)
    );
    stop: (C_Screen.FRAME_SCRIPT_END, 0)
  );
  { CGA color 0..3 standing in for each of the 16 colors, in Hline and Vline }
  cgaLineColors: array[0..15] of Byte = (
    0, 1, 0, 1, 2, 2, 2, 3, 0, 2, 1, 3, 2, 2, 3, 3
  );
  { punctuation a line may break after }
  breakChars: set of ' '..'?' = ['!', ',', '-', '.', ':', ';', '?'];
  { characters SanitizeFileName strips from a file name }
  invalidFileChars: array[1..10] of Char = ' .*,?/\:;|';
  { The career skills, each career's eight as skillDefinitions indices, which CharGen, Skills and ViewChar read. }
  careerSkills: array[Types.CareerRocketJock..Types.CareerScout, 1..8] of Byte = (
    { Rocket Jock }
    (C_Skill.NOTICE, C_Skill.MANEUVER_IN_0G, C_Skill.USE_JETPACK,
     C_Skill.PILOT_ROCKET, 52, 53,
     54, C_Skill.DRIVE_JETCAR),
    { Medic }
    (C_Skill.TREAT_LIGHT, C_Skill.TREAT_SERIOUS, C_Skill.TREAT_CRITICAL,
     C_Skill.DIAGNOSE, C_Skill.TREAT_POISONING, C_Skill.TREAT_STUN,
     C_Skill.TREAT_DISEASE, 16),
    { Warrior }
    (C_Skill.NOTICE, C_Skill.LEADERSHIP, C_Skill.BATTLE_TACTICS,
     C_Skill.MANEUVER_IN_0G, C_Skill.USE_JETPACK, C_Skill.MOVE_SILENTLY,
     11, C_Skill.REPAIR_WEAPON),
    { Engineer }
    (C_Skill.NOTICE, C_Skill.REPAIR_ELECTRICAL, C_Skill.REPAIR_MECHANICAL,
     C_Skill.REPAIR_ENGINE, C_Skill.REPAIR_LIFE_SUPPORT, C_Skill.REPAIR_HULL,
     C_Skill.JURY_RIG, C_Skill.MANEUVER_IN_0G),
    { Rogue }
    (C_Skill.NOTICE, C_Skill.BYPASS_SECURITY, C_Skill.OPEN_LOCK,
     C_Skill.HIDE_IN_SHADOWS, C_Skill.MOVE_SILENTLY, C_Skill.PICK_POCKETS,
     C_Skill.CLIMB, C_Skill.FAST_TALK),
    { Scout }
    (C_Skill.NOTICE, 60, C_Skill.BEFRIEND_ANIMAL,
     C_Skill.MOVE_SILENTLY, C_Skill.CLIMB, 80,
     C_Skill.PLANETARY_SURVIVAL, C_Skill.PLANETOLOGY)
  );
  { The status line's prompt to go on, which TextRend's PauseContinue shows and EclMenu's EclInflictDamage hands to
    TextRend's DisplayAndPause. }
  continuePrompt: String[33] = 'Press button or enter to continue';
  { The ECL continue menu's prompt, which EclVm's EclContinuePrompt and EclLogbookEntry offer, and buck.cfg's file name,
    which GameBoot creates and reads and CharGen's InitMouseJoystick rewrites. }
  { ~ marks the menu's key }
  continueMenuPrompt: String[34] = '~Press button or enter to continue';
  { the configuration file's name; GameBoot creates and reads it, CharGen reads its first five lines and rewrites it }
  configFileName: String[8] = 'buck.cfg';
  { The ships' text: the names new ships take, which SaveLoad's LoadShipData hands out (GameInit takes one as the combat
    debug password), the weapon and system names ShipCbt's menus and messages and CharHlp's ship panels show, PostCbt's
    repair list, and the ship type names. }
  { name a new ship takes, by [kind, serial]; SaveLoad, GameInit }
  shipNames: array[0..4, 0..4] of String[10] = (
    ('Van Allen', 'Hubble', 'Copernicus', 'Kepler', 'Goddard'),
    ('Adder', 'Viper', 'Anaconda', 'Sidewinder', 'Boomslang'),
    ('Mohave', 'Sahara', 'Gobi', 'Outback', 'Kalihari'),
    ('Flare', 'Corona', 'Hermes', 'Osiris', 'Apollo'),
    ('Liberator', 'Eclipse', 'Daisy', 'Gambit', 'Dervish')
  );
  { short name of each ship weapon kind; ShipCbt, CharHlp }
  weaponShortNames: array[1..8] of String[8] = (
    'Laser', 'P-laser', 'Gyrocann', 'Missile', 'Hv-missl', 'K-cannon', 'acl-Cann', 'hv-Accel'
  );
  { short name of each ship system; entry 6 is the weapons, which have no long name in shipSystemNames; ShipCbt,
    CharHlp }
  systemShortNames: array[0..6] of String[4] = (
    'Hull', 'Sens', 'Ctrl', 'Life', 'Fuel', 'Engn', 'Weap'
  );
  { name of each ship system; ShipCbt, PostCbt }
  shipSystemNames: array[0..5] of String[17] = (
    'Hull', 'Sensors', 'Control systems', 'Life support', 'Fuel', 'Engines'
  );
  { name of each ship type; CharHlp, ShipCbt }
  shipTypeNames: array[1..11] of String[17] = (
    'Fighter', 'Asterover', 'Scout cruiser', 'Lt freighter', 'Hv freighter', 'Md cruiser', 'Lt transport',
    'Hv transport', 'Hv cruiser', 'Space liner', 'Battler'
  );
  { The characters' text: the names of the careers, races, genders and statuses, which CharGen, ViewChar, CharHlp and
    ShipCbt show (a ship has a race too), and the skill groups' headings on Skills' skill screen. }
  { CharGen, ViewChar }
  careerNames: array[Types.CareerRocketJock..Types.CareerScout] of String[11] = (
    'Rocket Jock', 'Medic', 'Warrior', 'Engineer', 'Rogue', 'Scout'
  );
  { for characters and ships }
  raceNames: array[Types.TRace] of String[13] = (
    'Monster', 'Terran', 'Martian', 'Venusian', 'Mercurian', 'Tinker', 'Desert Runner', 'lunarian', 'lowlander'
  );
  { name of each gender; ViewChar, CharGen }
  genderNames: array[Types.TGender] of String[6] = (
    'Male', 'Female'
  );
  { name of each character status; CharHlp, ViewChar }
  statusNames: array[Types.TStatus] of String[12] = (
    'No status', 'Okay', 'Gone', 'Dead', 'Dying', 'Unconc', 'Fleeing', 'Poisoned', 'Comatose', 'Not here', 'Dodging',
    'Sprinting', 'Failed ZeroG', 'Used Jetpack',
    { cut to fit the 12-letter field }
    'Using Jetpac'
  );
  { no skill is in GroupConstitution }
  skillGroupNames: array[Types.TSkillGroup] of String[20] = (
    'Career Skills', 'Dexterity Skills', 'Constitution Skills', 'Intelligence Skills', 'Wisdom Skills',
    'Charisma Skills', 'technical Skills'
  );
  { The skills by skill number, TCharacter.skillLevels' index: each skill's name, whether the general skill list offers
    it, and its group, which Skills' screens, CharHlp's skill values, ViewChar's character sheet and EclVm's skill
    checks read; and after them epithetWords. }
  skillDefinitions: array[1..84] of Types.TSkill = (
    (name: 'Repair Electrical'; isOffered: 1; group: Types.GroupTechnical),
    (name: 'Repair Mechanical'; isOffered: 1; group: Types.GroupTechnical),
    (name: 'Repair Nuclear Engine'; isOffered: 1; group: Types.GroupTechnical),
    (name: 'Repair Life Support'; isOffered: 1; group: Types.GroupTechnical),
    (name: 'Repair Rocket Hull'; isOffered: 1; group: Types.GroupTechnical),
    (name: 'Jury Rig'; isOffered: 1; group: Types.GroupTechnical),
    (name: 'Bypass Security'; isOffered: 1; group: Types.GroupTechnical),
    (name: 'Open Lock'; isOffered: 1; group: Types.GroupTechnical),
    (name: 'Commo Operation'; isOffered: 1; group: Types.GroupTechnical),
    (name: 'Sensor Operation'; isOffered: 1; group: Types.GroupTechnical),
    (name: 'Demolitions'; isOffered: 1; group: Types.GroupTechnical),
    (name: 'Cook'; isOffered: 0; group: Types.GroupTechnical),
    (name: 'First Aid'; isOffered: 1; group: Types.GroupTechnical),
    (name: 'Repair Weapon'; isOffered: 1; group: Types.GroupTechnical),
    (name: 'Repair Computer'; isOffered: 0; group: Types.GroupTechnical),
    (name: 'Life Suspension Tech'; isOffered: 1; group: Types.GroupTechnical),
    (name: 'Treat Light Wounds'; isOffered: 1; group: Types.GroupTechnical),
    (name: 'Treat Serious Wounds'; isOffered: 1; group: Types.GroupTechnical),
    (name: 'Treat Critical Wounds'; isOffered: 1; group: Types.GroupTechnical),
    (name: 'Treat Poisoning'; isOffered: 1; group: Types.GroupTechnical),
    (name: 'Treat Stun/Paralysis'; isOffered: 1; group: Types.GroupTechnical),
    (name: 'Treat Disease'; isOffered: 1; group: Types.GroupTechnical),
    (name: 'Diagnose'; isOffered: 1; group: Types.GroupTechnical),
    (name: 'General Knowledge'; isOffered: 0; group: Types.GroupIntelligence),
    (name: 'Ship Lore'; isOffered: 0; group: Types.GroupIntelligence),
    (name: 'Composition'; isOffered: 0; group: Types.GroupIntelligence),
    (name: 'Mathematics'; isOffered: 1; group: Types.GroupIntelligence),
    (name: 'Physics'; isOffered: 0; group: Types.GroupIntelligence),
    (name: 'Geology'; isOffered: 0; group: Types.GroupIntelligence),
    (name: 'Planetology'; isOffered: 1; group: Types.GroupIntelligence),
    (name: 'Battle Tactics'; isOffered: 1; group: Types.GroupIntelligence),
    (name: 'Chemistry'; isOffered: 0; group: Types.GroupIntelligence),
    (name: 'Biology'; isOffered: 0; group: Types.GroupIntelligence),
    (name: 'Design Engineering'; isOffered: 0; group: Types.GroupIntelligence),
    (name: 'History'; isOffered: 0; group: Types.GroupIntelligence),
    (name: 'Astronomy'; isOffered: 1; group: Types.GroupIntelligence),
    (name: 'Botany'; isOffered: 0; group: Types.GroupIntelligence),
    (name: 'Literature'; isOffered: 0; group: Types.GroupIntelligence),
    (name: 'Economics'; isOffered: 0; group: Types.GroupIntelligence),
    (name: 'Metallurgy'; isOffered: 0; group: Types.GroupIntelligence),
    (name: 'Speak/Read Lang.'; isOffered: 0; group: Types.GroupIntelligence),
    (name: 'Law'; isOffered: 0; group: Types.GroupIntelligence),
    (name: 'Programming'; isOffered: 1; group: Types.GroupIntelligence),
    (name: 'Crytography'; isOffered: 0; group: Types.GroupIntelligence),
    (name: 'Library Search'; isOffered: 1; group: Types.GroupIntelligence),
    (name: 'Astrogation'; isOffered: 1; group: Types.GroupIntelligence),
    (name: 'Navigation'; isOffered: 1; group: Types.GroupIntelligence),
    (name: 'Mimic'; isOffered: 0; group: Types.GroupIntelligence),
    (name: 'Memorize'; isOffered: 0; group: Types.GroupIntelligence),
    (name: 'Disguise'; isOffered: 1; group: Types.GroupIntelligence),
    (name: 'Pilot Rocket'; isOffered: 1; group: Types.GroupDexterity),
    (name: 'Pilot Fixed Wing'; isOffered: 1; group: Types.GroupDexterity),
    (name: 'Drive Ground Car'; isOffered: 1; group: Types.GroupDexterity),
    (name: 'Pilot Rotor Wing'; isOffered: 1; group: Types.GroupDexterity),
    (name: 'Drive Motorcycle'; isOffered: 0; group: Types.GroupDexterity),
    (name: 'Use Jetpack'; isOffered: 1; group: Types.GroupDexterity),
    (name: 'Pilot Ship/Sub'; isOffered: 0; group: Types.GroupDexterity),
    (name: 'Drive Hvy Grnd Vehc'; isOffered: 0; group: Types.GroupDexterity),
    (name: 'Drive Jetcar'; isOffered: 1; group: Types.GroupDexterity),
    (name: 'Animal Riding'; isOffered: 0; group: Types.GroupDexterity),
    (name: 'Hide in Shadows'; isOffered: 1; group: Types.GroupDexterity),
    (name: 'Move Silently'; isOffered: 1; group: Types.GroupDexterity),
    (name: 'Pick Pockets'; isOffered: 1; group: Types.GroupDexterity),
    (name: 'Acrobatics'; isOffered: 1; group: Types.GroupDexterity),
    (name: 'Climb'; isOffered: 1; group: Types.GroupDexterity),
    (name: 'Swimming'; isOffered: 0; group: Types.GroupDexterity),
    (name: 'Maneuver in 0G'; isOffered: 1; group: Types.GroupDexterity),
    (name: 'Play Instrumnt'; isOffered: 0; group: Types.GroupDexterity),
    (name: 'Paint/Draw'; isOffered: 0; group: Types.GroupDexterity),
    (name: 'Hypnosis'; isOffered: 0; group: Types.GroupCharisma),
    (name: 'Act'; isOffered: 1; group: Types.GroupCharisma),
    (name: 'Intimidate'; isOffered: 1; group: Types.GroupCharisma),
    (name: 'Leadership'; isOffered: 1; group: Types.GroupCharisma),
    (name: 'Befriend Animal'; isOffered: 1; group: Types.GroupCharisma),
    (name: 'Animal Training'; isOffered: 0; group: Types.GroupCharisma),
    (name: 'Fast Talk/Convince'; isOffered: 1; group: Types.GroupCharisma),
    (name: 'Singing'; isOffered: 1; group: Types.GroupCharisma),
    (name: 'Distract'; isOffered: 1; group: Types.GroupCharisma),
    (name: 'Etiquette'; isOffered: 1; group: Types.GroupCharisma),
    (name: 'Tracking'; isOffered: 1; group: Types.GroupWisdom),
    (name: 'Shadowing'; isOffered: 1; group: Types.GroupWisdom),
    (name: 'Read Lips'; isOffered: 0; group: Types.GroupWisdom),
    (name: 'Notice'; isOffered: 1; group: Types.GroupWisdom),
    (name: 'Planetary Survival'; isOffered: 1; group: Types.GroupWisdom)
  );
  { ten spare words. Note: EclVm's skill handlers, EclSkillCheck and EclSkillDamage, do not bound the ECL skill number,
    so a skill from 85 to 92 reads these words' bytes as skillDefinitions[85..92] }
  epithetWords: array[0..9] of String[20] = (
    'Evil', 'Nuclear', 'Death', 'Martian', 'From', 'Chicago', 'Good', 'Wholesome', 'Space', 'Cadet'
  );
  { the words an item's name is built from, by its name ids, 0 for none; CharHlp's PrintItemString }
  itemNameParts: array[1..44] of String[20] = (
    'Knife', 'Mono', 'Cutlass', 'Sword', 'D.R. X-bow', 'Needle', 'Gun',
    'Bolt', 'Laser', 'Pistol', 'Rocket', 'Microwave', 'Rifle', 'Heat', 'Sonic Stunner', 'Grenade', 'Lnchr.',
    'Plasma Thrwr', 'Martian', 'Venusian', 'Mercurian', 'Lunarian', 'Spacesuit', 'Smartsuit', 'Heavy Body', 'Armor',
    'Battle armor', 'w/fields', 'Explosive', 'Gas', 'Stun', 'Dazzle', 'Chaff', 'Aerosol Mist', 'Demo Charge',
    'ECM package', 'Protective', 'Goggles', 'Breathing Mask', 'Rope', 'Jetpack', 'Poison Antidote', 'Polearm', 'mini'
  );
  { the compass name of each direction, 0 north, clockwise, which CharHlp's PrintMiscInfo shows in the party's position
    line }
  directionNames: array[0..7] of String[2] = (
    'N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'
  );
  { Pathing's step directions, then the display modes' drawing tables: the CGA fill words, text colors, pixel masks and
    pixel colors, and the EGA plane bits and plane mask. Blit, TextRend and DaxIo read the drawing tables, and
    textrend.asm's CGA blitter reads cgaTextColors as an external. }
  { direction 0..7 of a step by [dy + 1, dx + 1], 8 for none; Pathing }
  directionByDelta: array[0..2, 0..2] of Byte = (
    (C_Dir.NORTHWEST, C_Dir.NORTH, C_Dir.NORTHEAST),
    (C_Dir.WEST, C_Dir.CENTER, C_Dir.EAST),
    (C_Dir.SOUTHWEST, C_Dir.SOUTH, C_Dir.SOUTHEAST)
  );
  { unused }
  egaPlaneMask: array[0..3] of Byte = ($08, $04, $02, $01);
  { CGA fill word of colors 0..3; TextRend reads words, Blit their low bytes }
  cgaFillWords: array[0..3] of Word = (
    $0000, $5555, $AAAA, $FFFF
  );
  { CGA color 0..3 for each text color; DaxIo, TextRend }
  cgaTextColors: array[0..15] of Byte = (
    0, 0, 0, 1, 2, 2, 2, 3, 0, 1, 1, 1, 2, 2, 3, 3
  );
  { mask of each 2-bit CGA pixel in a word, leftmost first; Blit }
  cgaPixelMasks: array[0..7] of Word = (
    $C000, $3000, $0C00, $0300, $00C0, $0030, $000C, $0003
  );

{ Drawing tables and color maps, the sound commands, the disk prompts, the ship weapons and pictures, and the orbit
  map's layout. }
const
  { EGA map-mask bit for planes 0..3; Blit }
  egaPlaneBits: array[0..3] of Byte = (
    $01, $02, $04, $08
  );
  { CGA color (row) shifted into pixel 0..3 of a byte; Blit }
  cgaPixelColors: array[0..3, 0..3] of Byte = (
    ($00, $00, $00, $00),
    ($40, $10, $04, $01),
    ($80, $20, $08, $02),
    ($C0, $30, $0C, $03)
  );
  { The color maps callers hand to Blit: the packed color map CharGen and View3D pass to FillPicRect, and the two
    16-color tables MapTiles' icon recolor passes to RemapPic, the colors it finds and what it turns them into. }
  { colors 0..15 onto CGA colors 0..3, two to a byte, even color in the high nibble. Note: FillPicRect hands it on to
    SrcNibble, which ignores it }
  packedColorMap: Types.TColorMap = (
    $00, $11, $22, $12, $01, $21, $30, $33
  );
  { colors 0..15 in order, the colors MapTiles' icon recolor finds }
  identityColors: Types.TPalette16 = (
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15
  );
  { what MapTiles' icon recolor turns each color into: 8 becomes 0, dark gray to black in the 16-color palette }
  iconRecolors: Types.TPalette16 = (
    0, 1, 2, 3, 4, 5, 6, 7, 0, 9, 10, 11, 12, 13, 14, 15
  );
  { The sound commands the game sends through SoundDrv's SoundCommand and Music's SendSoundCommand: the three that stop,
    silence and restart the drivers, the game's sounds by number, and the sound each kind of ship weapon fires with. }
  { sound command that stops the driver: SoundDrv's silences both devices and gives back INT 8; GameIo, Music, DaxIo,
    FixMain }
  soundDriverOff: Word = 255;
  { sound command that starts song 0 on both devices, the speaker and the Tandy, which silences them; GameIo's Ctrl-S
    when sound is switched off, FixMain, CharGen before it loads the character icons }
  silenceSounds: Word = 0;
  { sound command that sets SoundDrv's output flag to 1, its value at start; GameIo's Ctrl-S when sound is switched back
    on, CharGen after it loads the character icons }
  soundOutputOn: Word = 1;
  { sound CharHlp plays over a creature hurt by an effect, or stunned, in combat }
  damageSound: Word = 2;
  { sound of a launched shot: CbtActs's grenade launcher, plasma thrower and rocket launcher, and a creature spitting
    acid in EffHndlr }
  launchSound: Word = 3;
  { sound of a grenade bursting into a cloud: CbtActs's projectile kinds 7..9 and 12 }
  cloudGrenadeSound: Word = 4;
  { sound CbtMap plays when a creature goes down }
  downedSound: Word = 5;
  { sound of a Sonic Stunner shot (SONIC_STUNNER_TYPE); CbtActs }
  sonicStunnerSound: Word = 6;
  { sound of each attack that hits for damage, a Sonic Stunner's stun excepted; CbtActs }
  hitSound: Word = 7;
  { sound of a blinding grenade's flash: CbtActs's projectile kind 5 }
  dazzleGrenadeSound: Word = 8;
  { sound of an attack round with no hit for damage; CbtActs }
  missSound: Word = 9;
  { sound of a step: Explore's 3-D steps and turns, EclVm after a 3-D move, CbtActs's combat moves, and Intro once a
    second through each title wait }
  stepSound: Word = 10;
  { sound of an explosion: CbtActs's blast grenades and missiles, CharHlp over the damage they do, ShipCbt when the
    enemy ship is destroyed }
  explosionSound: Word = 11;
  { sound of a D.R. X-bow or Bolt Gun shot (CROSSBOW_TYPE, BOLT_GUN_TYPE); CbtActs }
  boltSound: Word = 12;
  { sound of a Heat Gun shot (HEAT_GUN_TYPE); CbtActs }
  heatGunSound: Word = 13;
  { sound of a Laser Pistol or Laser Rifle shot (LASER_PISTOL_TYPE, LASER_RIFLE_TYPE); CbtActs }
  laserSound: Word = 14;
  { a Rocket Pistol or Rocket Rifle shot (ROCKET_PISTOL_TYPE, ROCKET_RIFLE_TYPE); CbtActs }
  rocketSound: Word = 16;
  { sound of a Needle Gun shot (NEEDLE_GUN_TYPE); CbtActs }
  needleGunSound: Word = 17;
  { sound of a Microwave Gun shot (MICROWAVE_GUN_TYPE); CbtActs }
  microwaveGunSound: Word = 18;
  { sound a ship weapon fires with, ShipCbt: [0] the K-cannon, [1] the others, [2] the two lasers. [3] and [4] are
    spare, and 21 is no sound: SoundDrv's command 21 arms its fake run-time error 209 }
  shipWeaponSounds: array[0..4] of Word = (
    16, 11, 19, 20, 21
  );
  { The prompts that ask for a game disk, by data set: DaxIo's OpenDax asks with the data set's own, SaveLoad asks for a
    character's files with it (saveDiskPrompt when it wants the save disk), and GameInit with it for the ITEMS file. }
  { prompt to insert a game disk, by data-set number (the digit in ECL<n> and BACK<n>), not by the disk it names }
  diskPrompts: array[0..6] of String[29] = (
    { data set 0, OrbitMap's tiles: disk 3, as [2] }
    'Insert disk 3 in drive ',
    'Insert disk 2 in drive ',
    'Insert disk 3 in drive ',
    'Insert disk 4 in drive ',
    'Insert disk 5 in drive ',
    'Insert disk 6 in drive ',
    'Insert disk 7 in drive '
  );
  { The ship weapons, by kind: the range each fires at, the rounds a reload adds, the damage of a hit, the bonus it
    gives the firer's hit roll, and its name. ShipCbt fires them and PostCbt repairs them. }
  { by weapon kind, TShipWeaponSlot.kind's KIND_MASK bits }
  shipWeapons: array[1..8] of Types.TShipWeaponDef = (
    (maxRange: 6; maxRangeTail: 1; reloadAmmo: 0; damage: 10; targetBonus: 1;
     targetBonusTail: (0, 0); name: 'Beam laser'),
    (maxRange: 4; maxRangeTail: 2; reloadAmmo: 0; damage: 20; targetBonus: 0;
     targetBonusTail: (0, 0); name: 'Pumped laser'),
    (maxRange: 4; maxRangeTail: 1; reloadAmmo: 50; damage: 10; targetBonus: 1;
     targetBonusTail: (100, 400); name: 'Gyrocannon'),
    (maxRange: 6; maxRangeTail: 1; reloadAmmo: 4; damage: 40; targetBonus: 0;
     targetBonusTail: (300, 400); name: 'Missile mount'),
    (maxRange: 6; maxRangeTail: 2; reloadAmmo: 4; damage: 60; targetBonus: -1;
     targetBonusTail: (900, 1200); name: 'Heavy missile mount'),
    (maxRange: 4; maxRangeTail: 5; reloadAmmo: 6; damage: 100; targetBonus: -3;
     targetBonusTail: (1500, 4000); name: 'K-cannon'),
    (maxRange: 2; maxRangeTail: 1; reloadAmmo: 15; damage: 20; targetBonus: -1;
     targetBonusTail: (200, 1500); name: 'Light acceleration gun'),
    (maxRange: 2; maxRangeTail: 2; reloadAmmo: 10; damage: 30; targetBonus: -2;
     targetBonusTail: (400, 3000); name: 'Heavy acceleration gun')
  );
  { The 'ships' pictures' layout: each picture's size, whether it loads transparent, and the screen cell or effect
    offset it is drawn at. OrbitMap loads the pictures by it, CharHlp draws the ship screen and ShipCbt the weapon
    effects. }
  { entry i is 'ships' picture i + OrbitMap's FIRST_SHIP_PICTURE }
  shipPictures: array[0..28] of Types.TShipPic = (
    (height: 48; width: 24; widthTail: 1; isTransparent: False; x: 0; y: 11),
    (height: 72; width: 10; widthTail: 1; isTransparent: True; x: 0; y: 0),
    (height: 48; width: 10; widthTail: 1; isTransparent: True; x: 2; y: 0),
    (height: 48; width: 10; widthTail: 1; isTransparent: True; x: 1; y: 0),
    (height: 40; width: 7; widthTail: 1; isTransparent: True; x: 0; y: 2),
    (height: 40; width: 8; widthTail: 1; isTransparent: True; x: 0; y: 1),
    (height: 32; width: 8; widthTail: 1; isTransparent: True; x: 0; y: 2),
    (height: 32; width: 5; widthTail: 1; isTransparent: True; x: 1; y: 2),
    (height: 24; width: 5; widthTail: 1; isTransparent: True; x: 0; y: 3),
    (height: 24; width: 5; widthTail: 1; isTransparent: True; x: 0; y: 3),
    (height: 24; width: 4; widthTail: 1; isTransparent: True; x: 1; y: 3),
    (height: 24; width: 4; widthTail: 1; isTransparent: True; x: 0; y: 3),
    (height: 16; width: 4; widthTail: 1; isTransparent: True; x: 0; y: 4),
    (height: 16; width: 2; widthTail: 1; isTransparent: True; x: 2; y: 4),
    (height: 24; width: 3; widthTail: 1; isTransparent: True; x: 0; y: 3),
    (height: 16; width: 2; widthTail: 1; isTransparent: True; x: 1; y: 4),
    (height: 32; width: 3; widthTail: 1; isTransparent: True; x: 26; y: 14),
    (height: 16; width: 3; widthTail: 1; isTransparent: False; x: 26; y: 1),
    (height: 16; width: 3; widthTail: 1; isTransparent: True; x: 26; y: 3),
    (height: 16; width: 3; widthTail: 1; isTransparent: True; x: 26; y: 5),
    (height: 16; width: 3; widthTail: 1; isTransparent: True; x: 26; y: 7),
    (height: 16; width: 3; widthTail: 1; isTransparent: True; x: 26; y: 9),
    (height: 16; width: 3; widthTail: 1; isTransparent: True; x: 26; y: 11),
    (height: 8; width: 2; widthTail: 1; isTransparent: True; x: 1; y: 12),
    (height: 8; width: 2; widthTail: 1; isTransparent: True; x: 1; y: 13),
    (height: 8; width: 2; widthTail: 1; isTransparent: True; x: 1; y: 14),
    (height: 8; width: 2; widthTail: 1; isTransparent: True; x: 1; y: 15),
    (height: 8; width: 2; widthTail: 1; isTransparent: True; x: 1; y: 16),
    (height: 8; width: 2; widthTail: 1; isTransparent: True; x: 1; y: 17)
  );
  { The orbit map's layout: every body position, orbit by orbit, each orbit's first position, length and starting phase,
    and the phases of orbit 4's eight extra bodies. OrbitMap reads all five tables, and GameInit the positions, first
    positions and starting phases when it sets up a new game. }
  { the body positions, orbit by orbit }
  orbitPositions: array[0..57] of Types.TOrbitPosition = (
    (x: 12; y: 10; sprite: 1), (x: 10; y: 10; sprite: 2),
    (x: 12; y: 9; sprite: 3), (x: 12; y: 11; sprite: 6), (x: 10; y: 11; sprite: 5), (x: 10; y: 9; sprite: 4),
    (x: 11; y: 7; sprite: 9), (x: 13; y: 8; sprite: 8), (x: 14; y: 10; sprite: 7), (x: 13; y: 12; sprite: 14),
    (x: 11; y: 13; sprite: 13), (x: 9; y: 12; sprite: 12), (x: 8; y: 10; sprite: 11), (x: 9; y: 8; sprite: 10),
    (x: 11; y: 4; sprite: 19), (x: 13; y: 5; sprite: 18), (x: 15; y: 6; sprite: 17), (x: 16; y: 8; sprite: 16),
    (x: 17; y: 10; sprite: 15), (x: 16; y: 12; sprite: 30), (x: 15; y: 14; sprite: 29), (x: 13; y: 15; sprite: 28),
    (x: 11; y: 16; sprite: 27), (x: 9; y: 15; sprite: 26), (x: 7; y: 14; sprite: 25), (x: 6; y: 12; sprite: 24),
    (x: 5; y: 10; sprite: 23), (x: 6; y: 8; sprite: 22), (x: 7; y: 6; sprite: 21), (x: 9; y: 5; sprite: 20),
    (x: 12; y: 0; sprite: 66), (x: 14; y: 1; sprite: 65), (x: 16; y: 2; sprite: 64), (x: 18; y: 3; sprite: 63),
    (x: 19; y: 5; sprite: 62), (x: 20; y: 7; sprite: 61), (x: 21; y: 9; sprite: 60), (x: 21; y: 11; sprite: 59),
    (x: 20; y: 13; sprite: 86), (x: 19; y: 15; sprite: 85), (x: 18; y: 17; sprite: 84), (x: 16; y: 18; sprite: 83),
    (x: 14; y: 19; sprite: 82), (x: 12; y: 20; sprite: 81), (x: 10; y: 20; sprite: 80), (x: 8; y: 19; sprite: 79),
    (x: 6; y: 18; sprite: 78), (x: 4; y: 17; sprite: 77), (x: 3; y: 15; sprite: 76), (x: 2; y: 13; sprite: 75),
    (x: 1; y: 11; sprite: 74), (x: 1; y: 9; sprite: 73), (x: 2; y: 7; sprite: 72), (x: 3; y: 5; sprite: 71),
    (x: 4; y: 3; sprite: 70), (x: 6; y: 2; sprite: 69), (x: 8; y: 1; sprite: 68), (x: 10; y: 0; sprite: 67)
  );
  { each orbit's first position in orbitPositions }
  orbitFirstPositions: array[0..4] of Byte = (0, 2, 6, 14, 30);
  { positions per orbit }
  orbitLengths: array[0..4] of Byte = (2, 4, 8, 16, 28);
  { phases of orbit 4's eight extra bodies }
  outerBodyPhases: array[0..7] of Byte = (3, 6, 9, 12, 17, 19, 22, 26);
  { each orbit's starting phase }
  orbitStartPhases: array[0..4] of Byte = (0, 0, 7, 9, 7);

{ Tile sets and ground combat: the tile-set spans, direction steps, combat terrain, icon cells and the effect texts and
  names. }
const
  { The tile-set slots' spans: the first and last tile number of each slot, which Sym8x8 reads to find and draw a tile
    and View3D's LoadWallSet reads tileSetFirst of. }
  { first tile of each tile-set slot }
  tileSetFirst: array[0..6] of Word = (0, 46, 116, 186, 256, 296, 391);
  { last tile of each tile-set slot }
  tileSetLast: array[0..6] of Word = (255, 115, 185, 255, 295, 390, 402);
  { Combat: direction steps, combat terrain, icon cells, post-combat effects and three effect texts }
  { x step of each direction 0..7 clockwise from north, 8 for none; CbtActs, CbtMap, CombatSt, CharHlp, FxEngine,
    Pathing, View3D, Explore }
  dirStepX: array[0..8] of ShortInt = (
    0, 1, 1, 1, 0, -1, -1, -1, 0
  );
  { y step of each direction, north -1; read with dirStepX }
  dirStepY: array[0..8] of ShortInt = (
    -1, -1, 0, 1, 1, 1, 0, -1, 0
  );
  { each kind of ground combat terrain, by the value an arena cell holds }
  combatTerrain: array[1..C_Terr.LAST_COMBAT_TERRAIN] of Types.TCombatTerrain = (
    (cost: 1; lineClass: 0; blastResult: 0; tile: 0), (cost: 1; lineClass: 0; blastResult: 0; tile: 1),
    (cost: 1; lineClass: 0; blastResult: 0; tile: 2), (cost: 1; lineClass: 0; blastResult: 0; tile: 3),
    (cost: 1; lineClass: 0; blastResult: 0; tile: 4), (cost: 1; lineClass: 0; blastResult: 0; tile: 5),
    (cost: 1; lineClass: 0; blastResult: 0; tile: 0), (cost: 255; lineClass: 1; blastResult: 0; tile: 1),
    (cost: 1; lineClass: 0; blastResult: 0; tile: 2), (cost: 255; lineClass: 1; blastResult: 0; tile: 3),
    (cost: 255; lineClass: 1; blastResult: 0; tile: 4), (cost: 255; lineClass: 1; blastResult: 0; tile: 5),
    (cost: 1; lineClass: 0; blastResult: 0; tile: 6), (cost: 255; lineClass: 1; blastResult: 0; tile: 7),
    (cost: 255; lineClass: 1; blastResult: 0; tile: 8), (cost: 255; lineClass: 1; blastResult: 0; tile: 9),
    (cost: 255; lineClass: 1; blastResult: 0; tile: 10), (cost: 255; lineClass: 1; blastResult: 0; tile: 11),
    (cost: 1; lineClass: 0; blastResult: 0; tile: 12), (cost: 255; lineClass: 1; blastResult: 0; tile: 13),
    (cost: 255; lineClass: 1; blastResult: 0; tile: 14), (cost: 255; lineClass: 1; blastResult: 0; tile: 15),
    (cost: 255; lineClass: 1; blastResult: 0; tile: 16), (cost: 1; lineClass: 0; blastResult: 0; tile: 17),
    (cost: 255; lineClass: 1; blastResult: 0; tile: 18), (cost: 1; lineClass: 0; blastResult: 0; tile: 19),
    (cost: 255; lineClass: 1; blastResult: 0; tile: 20), (cost: 1; lineClass: 0; blastResult: 0; tile: 21),
    (cost: 255; lineClass: 1; blastResult: 0; tile: 22), (cost: 255; lineClass: 1; blastResult: 0; tile: 23),
    (cost: 255; lineClass: 1; blastResult: 0; tile: 24), (cost: 255; lineClass: 1; blastResult: 0; tile: 25),
    (cost: 1; lineClass: 0; blastResult: 0; tile: 26), (cost: 1; lineClass: 0; blastResult: 0; tile: 27),
    (cost: 255; lineClass: 1; blastResult: 0; tile: 28), (cost: 1; lineClass: 0; blastResult: 0; tile: 29),
    (cost: 255; lineClass: 1; blastResult: 0; tile: 30), (cost: 1; lineClass: 0; blastResult: 0; tile: 31),
    (cost: 1; lineClass: 0; blastResult: 0; tile: 32), (cost: 1; lineClass: 0; blastResult: 0; tile: 33),
    (cost: 255; lineClass: 1; blastResult: 0; tile: 49), (cost: 255; lineClass: 1; blastResult: 0; tile: 50),
    (cost: 255; lineClass: 1; blastResult: 0; tile: 51), (cost: 255; lineClass: 1; blastResult: 0; tile: 52),
    (cost: 1; lineClass: 0; blastResult: 0; tile: 34), (cost: 2; lineClass: 2; blastResult: 0; tile: 35),
    (cost: 2; lineClass: 2; blastResult: 0; tile: 36), (cost: 2; lineClass: 2; blastResult: 0; tile: 37),
    (cost: 2; lineClass: 2; blastResult: 0; tile: 38), (cost: 2; lineClass: 2; blastResult: 0; tile: 39),
    (cost: 2; lineClass: 2; blastResult: 0; tile: 40), (cost: 2; lineClass: 2; blastResult: 0; tile: 41),
    (cost: 2; lineClass: 2; blastResult: 0; tile: 42), (cost: 2; lineClass: 2; blastResult: 0; tile: 43),
    (cost: 2; lineClass: 2; blastResult: 0; tile: 44), (cost: 1; lineClass: 0; blastResult: 0; tile: 45),
    (cost: 1; lineClass: 0; blastResult: 0; tile: 46), (cost: 1; lineClass: 0; blastResult: 0; tile: 47),
    (cost: 1; lineClass: 0; blastResult: 0; tile: 48), (cost: 2; lineClass: 0; blastResult: 0; tile: 34),
    (cost: 1; lineClass: 0; blastResult: 0; tile: 35), (cost: 2; lineClass: 2; blastResult: 0; tile: 36),
    (cost: 2; lineClass: 2; blastResult: 0; tile: 37), (cost: 2; lineClass: 2; blastResult: 0; tile: 38),
    (cost: 2; lineClass: 2; blastResult: 0; tile: 39), (cost: 2; lineClass: 2; blastResult: 0; tile: 40),
    (cost: 2; lineClass: 2; blastResult: 0; tile: 41), (cost: 2; lineClass: 2; blastResult: 0; tile: 42),
    (cost: 255; lineClass: 1; blastResult: 0; tile: 1), (cost: 255; lineClass: 1; blastResult: 0; tile: 2),
    (cost: 255; lineClass: 1; blastResult: 0; tile: 3), (cost: 255; lineClass: 1; blastResult: 0; tile: 4),
    (cost: 255; lineClass: 1; blastResult: 0; tile: 5), (cost: 255; lineClass: 1; blastResult: 0; tile: 6),
    (cost: 255; lineClass: 1; blastResult: 0; tile: 7), (cost: 255; lineClass: 1; blastResult: 0; tile: 8),
    (cost: 255; lineClass: 1; blastResult: 0; tile: 9), (cost: 255; lineClass: 1; blastResult: 0; tile: 10),
    (cost: 255; lineClass: 2; blastResult: 0; tile: 11), (cost: 255; lineClass: 2; blastResult: 0; tile: 12),
    (cost: 255; lineClass: 2; blastResult: 0; tile: 13), (cost: 4; lineClass: 2; blastResult: 0; tile: 14),
    (cost: 4; lineClass: 2; blastResult: 0; tile: 15), (cost: 4; lineClass: 2; blastResult: 0; tile: 16),
    (cost: 4; lineClass: 2; blastResult: 0; tile: 17), (cost: 4; lineClass: 2; blastResult: 0; tile: 18),
    (cost: 4; lineClass: 2; blastResult: 0; tile: 19), (cost: 4; lineClass: 2; blastResult: 0; tile: 20),
    (cost: 1; lineClass: 0; blastResult: 139; tile: 21), (cost: 1; lineClass: 0; blastResult: 139; tile: 22),
    (cost: 2; lineClass: 0; blastResult: 0; tile: 23), (cost: 255; lineClass: 0; blastResult: 0; tile: 24),
    (cost: 255; lineClass: 0; blastResult: 0; tile: 25), (cost: 3; lineClass: 2; blastResult: 131; tile: 26),
    (cost: 3; lineClass: 2; blastResult: 132; tile: 27), (cost: 3; lineClass: 2; blastResult: 133; tile: 28),
    (cost: 3; lineClass: 2; blastResult: 134; tile: 29), (cost: 1; lineClass: 2; blastResult: 135; tile: 30),
    (cost: 1; lineClass: 2; blastResult: 136; tile: 31), (cost: 255; lineClass: 2; blastResult: 137; tile: 32),
    (cost: 255; lineClass: 2; blastResult: 138; tile: 33), (cost: 3; lineClass: 2; blastResult: 140; tile: 1),
    (cost: 3; lineClass: 2; blastResult: 141; tile: 2), (cost: 3; lineClass: 2; blastResult: 142; tile: 3),
    (cost: 3; lineClass: 2; blastResult: 143; tile: 4), (cost: 3; lineClass: 2; blastResult: 144; tile: 5),
    (cost: 3; lineClass: 2; blastResult: 145; tile: 6), (cost: 1; lineClass: 0; blastResult: 146; tile: 7),
    (cost: 1; lineClass: 0; blastResult: 146; tile: 8), (cost: 255; lineClass: 0; blastResult: 0; tile: 9),
    (cost: 255; lineClass: 0; blastResult: 0; tile: 10), (cost: 2; lineClass: 0; blastResult: 0; tile: 11),
    (cost: 2; lineClass: 0; blastResult: 0; tile: 12), (cost: 2; lineClass: 0; blastResult: 0; tile: 13),
    (cost: 3; lineClass: 2; blastResult: 147; tile: 14), (cost: 3; lineClass: 2; blastResult: 148; tile: 15),
    (cost: 3; lineClass: 0; blastResult: 153; tile: 16), (cost: 255; lineClass: 2; blastResult: 250; tile: 17),
    (cost: 255; lineClass: 2; blastResult: 250; tile: 18), (cost: 255; lineClass: 2; blastResult: 250; tile: 19),
    (cost: 255; lineClass: 2; blastResult: 250; tile: 20), (cost: 255; lineClass: 2; blastResult: 250; tile: 21),
    (cost: 255; lineClass: 2; blastResult: 251; tile: 22), (cost: 255; lineClass: 2; blastResult: 251; tile: 23),
    (cost: 255; lineClass: 2; blastResult: 252; tile: 24), (cost: 255; lineClass: 2; blastResult: 252; tile: 25),
    (cost: 1; lineClass: 2; blastResult: 151; tile: 26), (cost: 1; lineClass: 2; blastResult: 151; tile: 27),
    (cost: 1; lineClass: 2; blastResult: 151; tile: 28), (cost: 1; lineClass: 2; blastResult: 151; tile: 29),
    (cost: 2; lineClass: 0; blastResult: 0; tile: 34), (cost: 2; lineClass: 0; blastResult: 0; tile: 35),
    (cost: 2; lineClass: 0; blastResult: 0; tile: 36), (cost: 2; lineClass: 0; blastResult: 0; tile: 37),
    (cost: 1; lineClass: 2; blastResult: 0; tile: 38), (cost: 1; lineClass: 2; blastResult: 0; tile: 39),
    (cost: 255; lineClass: 2; blastResult: 0; tile: 40), (cost: 255; lineClass: 2; blastResult: 0; tile: 41),
    (cost: 1; lineClass: 0; blastResult: 0; tile: 42), (cost: 2; lineClass: 0; blastResult: 0; tile: 30),
    (cost: 2; lineClass: 0; blastResult: 0; tile: 31), (cost: 2; lineClass: 2; blastResult: 0; tile: 42),
    (cost: 2; lineClass: 0; blastResult: 0; tile: 33), (cost: 2; lineClass: 0; blastResult: 0; tile: 34),
    (cost: 2; lineClass: 0; blastResult: 0; tile: 35), (cost: 1; lineClass: 0; blastResult: 0; tile: 36),
    (cost: 2; lineClass: 2; blastResult: 0; tile: 37), (cost: 2; lineClass: 0; blastResult: 0; tile: 38),
    (cost: 255; lineClass: 0; blastResult: 251; tile: 39), (cost: 255; lineClass: 2; blastResult: 252; tile: 40),
    (cost: 1; lineClass: 2; blastResult: 0; tile: 41), (cost: 255; lineClass: 0; blastResult: 250; tile: 32),
    (cost: 2; lineClass: 0; blastResult: 0; tile: 43), (cost: 2; lineClass: 0; blastResult: 0; tile: 44)
  );
  { cells of a size 1..4 icon; dx < 0 is no cell; CbtMap }
  iconCells: array[1..4, 0..3] of Types.TIconDelta = (
    ((dx: 0; dy: 0), (dx: -1; dy: -1), (dx: -1; dy: -1), (dx: -1; dy: -1)),
    ((dx: 0; dy: 0), (dx: 0; dy: 1), (dx: -1; dy: -1), (dx: -1; dy: -1)),
    ((dx: 0; dy: 0), (dx: 1; dy: 0), (dx: -1; dy: -1), (dx: -1; dy: -1)),
    ((dx: 0; dy: 0), (dx: 1; dy: 0), (dx: 0; dy: 1), (dx: 1; dy: 1))
  );
  { unused }
  iconCellsTail: Byte = 1;
  { effects PostCbt clears at the end of combat: the five that have a name in effectStatusNames }
  postCombatClearedEffects: array[1..5] of Byte = (
    C_Effect.SCARED, C_Effect.DIZZY, C_Effect.STUNNED, C_Effect.BLIND, C_Effect.HELPLESS
  );
  { unused: CbtActs and FxEngine spell their own 'is ' }
  isText: String = 'is ';
  { unused }
  affectedText: String = 'Affected';
  { unused: CbtActs and FxEngine spell their own 'is Unaffected' }
  unaffectedText: String = 'Unaffected';
  { name of each effect a creature can be under, by effect number, '' for most; CbtActs builds 'is ' and the name for
    FxEngine to print }
  effectStatusNames: array[1..32] of String[40] = (
    'Helpless', 'Scared', '', '', '', '', '', '', '', '', '', '',
    'Blind', 'Stunned', '', '', '', '', '', '', '', '', '', '', '', '', '', '',
    'Dizzy', '', '', ''
  );
  { the directions of a 3x3 block, center first; CbtMap, FxEngine, CbtActs }
  blockCellDirections: array[1..9] of Byte = (
    C_Dir.CENTER, C_Dir.EAST, C_Dir.SOUTHEAST, C_Dir.SOUTH, C_Dir.SOUTHWEST, C_Dir.WEST,
        C_Dir.NORTHWEST, C_Dir.NORTH, C_Dir.NORTHEAST
  );

{ Key maps, the trade prompts, the clock's scale, save files, the career and race rules, the shop's text, the
  copy-protection prompts, the mouse cursors, the joystick maps and the fill bytes. }
const
  { The key maps: keypadScanCodes, the cursor key's scan code for each keypad digit, which CharGen, MenuCore and Explore
    read, and clickArrowKeys, the arrow key for a click on MenuCore's 11x11 grid. }
  { scan code of the cursor key on keypad digits 1..9, a space for 5; CharGen and MenuCore index it by digit - '1',
    Explore by facing }
  keypadScanCodes: array[0..8] of Char = (
    C_Keys.END_KEY, C_Keys.DOWN, C_Keys.PAGE_DOWN, C_Keys.LEFT, ' ', C_Keys.RIGHT, C_Keys.HOME,
    C_Keys.UP, C_Keys.PAGE_UP
  );
  { [y, x] of a click on the 11x11 grid to the scan code of the arrow toward it: H up, K left, M right, P down;
    MenuCore }
  clickArrowKeys: array[3..13, 3..13] of Char = (
    'HHHHHHHHHHH',
    'KHHHHHHHHHM',
    'KKHHHHHHHMM',
    'KKKHHHHHMMM',
    'KKKKHHHMMMM',
    'KKKKKHMMMMM',
    'KKKKPPPMMMM',
    'KKKPPPPPMMM',
    'KKPPPPPPPMM',
    'KPPPPPPPPPM',
    'PPPPPPPPPPP'
  );
  { unused }
  clickArrowKeysTail: array[0..1] of Byte = ($00, $00);
  { The prompts of a credit trade: the one ViewChar's TradeTreasureMenu asks who receives the credits with, and beside
    it the coin-type prompt and the two halves of the trade amount question, which are unused. }
  { prompt to pick who receives a credit trade; ViewChar }
  tradeToPrompt: String[9] = 'Trade to?';
  { a coin-type menu prompt; unused }
  coinTypePrompt: String[20] = 'Select type of coin ';
  { the trade amount question's head, before the coin name; unused }
  tradeAmountHead: String[9] = 'How much ';
  { the trade amount question's tail; unused }
  tradeAmountTail: String[16] = 'will you trade? ';
  { The game calendar's scale: how many of each game-clock unit make one of the next, which GameTime carries the clock
    and runs effect durations down by. }
  { per unit, smallest first (segment, minute, turn, hour, day, month, year, as GameTime's TClock indexes them), how
    many make one of the next; when the years reach 100, GameTime ages each party member a year and sets
    hasCenturyPassed }
  clockUnitScale: array[0..6] of Word = (
    10, 10, 6, 24, 30, 12, 100
  );
  { The file-name parts and the prompt SaveLoad saves and loads with: the extensions of a saved character's item, second
    item list and effect files, the stem of a saved game's file name, and the prompt that asks for the save disk. }
  { extension of a saved character's item file; SaveLoad }
  itemFileExt: String[4] = '.stf';
  { extension of a saved character's second item list file; SaveLoad }
  alternateItemFileExt: String[4] = '.hid';
  { extension of a saved character's effect file; SaveLoad }
  effectFileExt: String[4] = '.sfx';
  { a saved game's file name ahead of its slot letter and '.dat'; SaveLoad }
  saveGameStem: String[6] = 'savgam';
  { the save-disk prompt; SaveLoad follows it with savePath's drive letter and ':', LoadGame with the whole savePath,
    and a character load passes it bare to OpenWithRetry }
  saveDiskPrompt: String[17] = 'Put save disk in ';
  { The race and career rules a character is made and trained by: the highest level, the base combat value by career and
    level, the careers each race may take, the hit-point bonus by constitution, the experience each level needs, the
    saving throws and each race's adjustments to them, each race's adjustments to the abilities and each career's
    minimums. CharGen reads them all, and MenuCore MAX_LEVEL and experienceNeeded. }
  { base combat value by career and level }
  careerBaseCombat: array[Types.CareerRocketJock..Types.CareerScout, 0..9] of Byte = (
    (40, 40, 40, 41, 41, 42, 42, 43, 43, 44),
    (40, 40, 40, 40, 42, 42, 42, 44, 44, 44),
    (40, 40, 41, 42, 43, 44, 45, 46, 47, 48),
    (40, 40, 40, 40, 42, 42, 42, 44, 44, 44),
    (40, 40, 40, 41, 41, 42, 42, 43, 43, 44),
    (40, 40, 41, 42, 43, 44, 45, 46, 47, 48)
  );
  { by career, the first level whose hit points are a fixed gain, not a roll; unused, as CharGen fixes that gain from
    level 9 for every career }
  firstFixedHpLevel: array[Types.CareerRocketJock..Types.CareerScout] of Byte = (21, 15, 10, 10, 11, 12);
  { how many careers each race may take, then its careers; CharGen's class menu offers the first count }
  raceCareers: array[Types.RaceTerran..Types.RaceLowlander] of record count: ShortInt;
    careers: array[1..6] of Types.TCareer end = (
    (count: 5; careers: (Types.CareerRocketJock, Types.CareerMedic, Types.CareerWarrior, Types.CareerEngineer,
                         Types.CareerRogue, Types.CareerScout)),
    (count: 5; careers: (Types.CareerRocketJock, Types.CareerMedic, Types.CareerWarrior, Types.CareerEngineer,
                         Types.CareerRogue, Types.CareerScout)),
    (count: 5; careers: (Types.CareerRocketJock, Types.CareerMedic, Types.CareerWarrior, Types.CareerEngineer,
                         Types.CareerRogue, Types.CareerScout)),
    (count: 5; careers: (Types.CareerRocketJock, Types.CareerMedic, Types.CareerWarrior, Types.CareerEngineer,
                         Types.CareerRogue, Types.CareerScout)),
    (count: 2; careers: (Types.CareerMedic, Types.CareerEngineer, Types.CareerNone, Types.CareerNone, Types.CareerNone,
                         Types.CareerNone)),
    (count: 3; careers: (Types.CareerRocketJock, Types.CareerWarrior, Types.CareerEngineer, Types.CareerNone,
                         Types.CareerNone, Types.CareerNone)),
    (count: 5; careers: (Types.CareerRocketJock, Types.CareerMedic, Types.CareerWarrior, Types.CareerEngineer,
                         Types.CareerRogue, Types.CareerScout)),
    (count: 2;
     careers: (Types.CareerWarrior, Types.CareerEngineer, Types.CareerNone, Types.CareerNone, Types.CareerNone,
                         Types.CareerNone))
  );
  { bonus to each level's hit-point roll, by constitution }
  constitutionLevelBonus: array[1..22] of ShortInt = (
    -3, -2, -2, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 4, 5, 5, 6, 6
  );
  { experience each career needs for levels 2..9 }
  experienceNeeded: array[Types.CareerRocketJock..Types.CareerScout, 2..9] of LongInt = (
    (1250, 2500, 5000, 10000, 20000, 40000, 70000, 110000),
    (1500, 3000, 6000, 12000, 24000, 48000, 96000, 192000),
    (2000, 4000, 8000, 16000, 32000, 64000, 125000, 250000),
    (1250, 2500, 5000, 10000, 20000, 40000, 70000, 110000),
    (1250, 2500, 5000, 10000, 20000, 40000, 70000, 110000),
    (2250, 4500, 9000, 18000, 36000, 75000, 150000, 300000)
  );
  { each race's adjustment to a new character's eight saving throws, subtracted from baseSavingThrows, so a positive
    entry makes that save easier }
  raceSaveAdjust: array[Types.RaceTerran..Types.RaceLowlander, 0..7] of ShortInt = (
    (1, 0, 0, 0, 0, 0, 0, 0),
    (-1, 0, 0, 0, 1, 1, -1, 1),
    (1, 3, 0, 1, 1, -2, 3, -2),
    (1, 0, 0, 0, 3, 1, 4, -3),
    (0, -1, -3, -2, 0, 0, 0, 0),
    (2, 0, 1, 1, 2, 2, -3, 4),
    (0, -1, 0, 0, 2, 2, -1, -1),
    (2, 4, 2, 3, 1, -4, 6, -6)
  );
  { a new character's eight saving throws before its race adjusts them, each the d20 roll FxEngine's RollSavingThrow
    needs to meet or beat }
  baseSavingThrows: array[0..7] of Byte = (
    15, 14, 14, 13, 13, 16, 13, 13
  );
  { each race's adjustment to the seven abilities, added to the rolled scores; CharGen's Modify also keeps each ability
    between it + 3 and it + 18 }
  raceStatAdjust: array[Types.RaceTerran..Types.RaceLowlander, 0..6] of ShortInt = (
    (0, 0, 1, 0, 1, 0, 0),
    (-1, 1, -1, 0, -1, 1, 0),
    (0, -1, 1, 0, 1, -1, 0),
    (-1, 1, 1, 0, 0, 0, 0),
    (-2, 3, -2, 0, 0, 0, 3),
    (2, 2, 1, 0, 0, -1, 0),
    (-2, 1, -1, 2, 0, 0, 0),
    (3, 0, 1, 0, 0, -3, 1)
  );
  { each career's minimum for the seven abilities }
  careerStatMinimum: array[Types.CareerRocketJock..Types.CareerScout, 0..6] of Byte = (
    (1, 13, 1, 11, 1, 12, 1),
    (1, 12, 1, 12, 12, 1, 1),
    (10, 8, 10, 8, 1, 1, 1),
    (10, 1, 12, 8, 1, 1, 13),
    (1, 13, 1, 8, 9, 13, 1),
    (1, 1, 8, 8, 9, 8, 1)
  );
  { unused }
  careerStatMinimumTail: array[0..1] of Byte = (0, 0);
  { The shop's buy-menu text, Shop's ShopBuyItemSelection's: the prompt over the menu and its option line, which it
    hands to MenuCore's MenuVertical, and the blank line each item's menu line starts from: it copies the blank into a
    local line, lays the item's price and name into that, and copies the line into the item's name. }
  { the prompt over the shop's buy menu; Shop }
  itemsPrompt: String[7] = 'Items: ';
  { the shop's buy menu option line; Shop }
  buyMenu: String[3] = 'Buy';
  { 38 spaces that blank a menu line; Shop }
  menuBlankLine: String[39] = '                                      ';
  { The copy-protection text CopyProt's CopyProtection builds each question from: the log-book prompt's two lines, the
    question's head and tail, and the ordinal that names the word to type. }
  { the prompt's first line }
  logBookPrompt: String[25] = 'In the Log Book on page';
  { its second line }
  headingPrompt: String[21] = 'following the heading';
  { the question, before the ordinal }
  questionHead: String[12] = 'what is the ';
  { the question, after the ordinal }
  questionTail: String[6] = 'word? ';
  { the ordinal naming the word to type }
  wordOrdinals: array[1..10] of String[18] = (
    'first  ', 'second ', 'third  ', 'fourth ', 'fifth  ',
    'sixth  ', 'seventh', 'eighth ', 'ninth', 'tenth'
  );
  { the mouse cursors SetMouseCursor takes }
  { the arrow for every mode but CGA; GameInit, CharGen }
  arrowCursor: Types.TMouseCursor = (
    screenMask: ($3FFF, $1FFF, $0FFF, $07FF, $03FF, $01FF, $00FF, $007F,
                 $003F, $003F, $01FF, $00FF, $10FF, $F87F, $F87F, $FC7F);
    cursorMask: ($0000, $4000, $6000, $7000, $7800, $7C00, $7E00, $7F00,
                 $7F80, $7C00, $6C00, $4600, $0600, $0300, $0300, $0000)
  );
  { the CGA arrow, two bits a pixel; GameInit, CharGen }
  cgaArrowCursor: Types.TMouseCursor = (
    screenMask: ($0FFF, $03FF, $00FF, $003F, $000F, $0003, $0000, $0003,
                 $0003, $3F03, $FF00, $FF00, $FFC3, $FFFF, $FFFF, $FFFF);
    cursorMask: ($0000, $3000, $3C00, $3F00, $3FC0, $3FF0, $3FFC, $3FC0,
                 $3CF0, $00F0, $003C, $003C, $0000, $0000, $0000, $0000)
  );
  { stick [row, col] band to zone 0..7 clockwise from up, or NO_ZONE }
  joystickZones: array[0..5, 0..5] of Byte = (
    (7, 7, 0, 0, 1, 1),
    (7, 8, 8, 8, 8, 1),
    (6, 8, 8, 8, 8, 2),
    (6, 8, 8, 8, 8, 2),
    (5, 8, 8, 8, 8, 3),
    (5, 5, 4, 4, 3, 3)
  );
  { the keypad digit GameIo's ReadGameKey answers for each joystick zone; it reads 0..7, as zone 8 is centered }
  joystickKeys: array[0..9] of Char = (
    '8', '9', '6', '3', '2', '1', '4', '7', ' ', #0
  );
  { The fill bytes: for each color, the byte that paints a whole CGA or Tandy byte of a picture with it, which Blit's
    FillPicRect fills rows with. }
  { CGA fill byte for each CGA color 0..3, as Blit's SrcNibble gives it }
  cgaFillBytes: array[0..3] of Byte = (
    $00, $55, $AA, $FF
  );
  { Tandy fill byte for each color; Blit }
  tandyFillBytes: array[0..15] of Byte = (
    $00, $11, $22, $33, $44, $55, $66, $77, $88, $99, $AA, $BB, $CC, $DD, $EE, $FF
  );

implementation

end.
