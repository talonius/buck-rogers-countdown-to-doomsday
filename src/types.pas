{ The types several units use. The unit holds no storage and no code; the game's shared data is in GDConsts and
  GDVars. }
{$F+}
{$A-}
unit Types;

interface

uses C_Equip;

type
  { a character's career, one for each of careerNames; CareerNone, which careerNames has no name for, is the career of a
    record CharGen clears before its career menu picks one, and pads raceCareers' shorter lists }
  TCareer = (CareerNone, CareerRocketJock, CareerMedic, CareerWarrior, CareerEngineer, CareerRogue, CareerScout);
  { a character's or a ship's race, one for each of raceNames }
  TRace = (RaceMonster, RaceTerran, RaceMartian, RaceVenusian, RaceMercurian, RaceTinker, RaceDesertRunner,
    RaceLunarian, RaceLowlander);
  { a character's gender, one for each of genderNames }
  TGender = (GenderMale, GenderFemale);
  { a character's status, one for each of statusNames; StUnconscious and StUsingJetpack spell out the words statusNames
    cuts to fit }
  TStatus = (StNoStatus, StOkay, StGone, StDead, StDying, StUnconscious, StFleeing, StPoisoned, StComatose, StNotHere,
    StDodging, StSprinting, StFailedZeroG, StUsedJetpack, StUsingJetpack);
  { a skill's group, one for each of skillGroupNames }
  TSkillGroup = (GroupCareer, GroupDexterity, GroupConstitution, GroupIntelligence, GroupWisdom, GroupCharisma,
    GroupTechnical);

  { a border run, in character cells; a script ends with C_Screen.FRAME_SCRIPT_END }
  TFrameRun = record
    x1: Byte;
    y1: Byte;
    x2: Byte;
    y2: Byte;
    { border-cell selectors for the run's two ends }
    firstSel: Byte;
    lastSel: Byte
  end;

  { a frame script of one box: GDConsts.mainFrame and creditsFrame }
  TBoxFrame = record
    { the box's four sides }
    runs: array[0..3] of TFrameRun;
    { C_Screen.FRAME_SCRIPT_END, 0: where Border.DrawFrameSegments stops }
    stop: array[0..1] of Byte
  end;
  { a frame script of one box and one more line: GDConsts.exploreFrame (the line first) and combatFrame (the box
    first) }
  TBoxLineFrame = record
    { the box's four sides and the line }
    runs: array[0..4] of TFrameRun;
    { C_Screen.FRAME_SCRIPT_END, 0: where Border.DrawFrameSegments stops }
    stop: array[0..1] of Byte
  end;

  { a packed color map, as in packedColorMap: Blit copies one between pictures in TImgBuf.colorMap, and SrcNibble and
    FillPicRect take one by value }
  TColorMap = array[0..7] of Byte;
  { colors Blit.RemapPic finds, or the colors it puts in their place }
  TPalette16 = array[0..15] of Byte;

  { one kind of ground combat terrain, the value an arena cell holds }
  TCombatTerrain = record
    { movement cost, doubled for a straight step and tripled for a diagonal; 255 impassable }
    cost: Byte;
    { what Pathing.WalkLine meets: 1 stops the line while the arena's distance mode is 0, 2 marks it blocked past the
      line's grace cells }
    lineClass: Byte;
    { what CbtActs's area blast lays: 0 none; $FA..$FC 146 one time in four (147 or 153 below), else 152, 149 or 150 }
    blastResult: Byte;
    { the tile drawn; for terrains 1..5 also the icon frame CbtMap draws over the terrain beneath, and CbtActs's
      cloud-grenade symbol }
    tile: Byte
  end;

  { a cell a combat icon covers, relative to its anchor cell }
  TIconDelta = record
    dx: ShortInt;
    dy: ShortInt
  end;

  { the first and last open column of one row of a ring's placement grid; lo > hi opens none }
  TColumnRange = record
    lo: ShortInt;
    hi: ShortInt
  end;

  { bytes indexed from 0; the bound is a placeholder, which $R- never checks: a picture's mask, the buffer DaxIo's
    loaders read a DAX record into, Portrait's buffers that decode an animation's frames, and the VGA screen row
    TextRend fills }
  TByteArr = array[0..65000] of Byte;
  PByteArr = ^TByteArr;
  { A decoded VGA animation frame's pixels, one byte each: every buffer VgaFrame and Portrait expand a frame into. }
  TVgaFrame = array[0..7743] of Byte;
  { One EGA scanline in one plane, 8 pixels a byte: GameInit spaces egaRowOffsets by it, Blit's FlushView and TextRend's
    FillRectEga step by it. }
  TEgaRow = array[0..39] of Byte;
  { One mode-13h scanline, a byte a pixel: Blit, Border and TextRend step by it. }
  TVgaRow = array[0..319] of Byte;

  { A VGA color: red, green, blue. }
  TRgb = array[0..2] of Byte;
  { The 256 VGA colors. }
  TPalette256 = array[0..255] of TRgb;
  { one CGA scanline, 4 pixels a byte: Blit's Hline and Vline and Border index the CGA banks as arrays of it }
  TCgaRow = array[0..79] of Byte;
  { one Tandy scanline, 2 pixels a byte: Border and TextRend index the Tandy banks as arrays of it }
  TTandyRow = array[0..159] of Byte;

  TString3 = String[3];
  TString40 = String[40];
  TString80 = String[80];
  { a pointer's offset and segment words: GameBoot's FreePtr, MusDrv's bank }
  TPtrWords = record ofs: Word; seg: Word end;

  PImgBuf = ^TImgBuf;
  { a picture in the display mode's layout; Blit builds, draws and frees it }
  TImgBuf = record
    { scanlines per frame }
    height: Word;
    { 8-pixel columns per frame }
    width: Word;
    { copied from the DAX header; Portrait keeps an image's x position here }
    hdrC: Word;
    { likewise; Portrait keeps the y position here }
    hdrD: Word;
    { frames }
    count: Word;
    { copied between pictures and passed to SrcNibble; PreparePic fills it from an uninitialized local }
    colorMap: TColorMap;
    { bytes per frame: height * width * the mode's bytes per 8-pixel row (CGA 2, EGA and Tandy 4, VGA 8) }
    frameSize: Word;
    { size FreePic releases: the 27-byte header plus frameSize*count, or the loaded file's size when PreparePic builds
      the picture on its buffer }
    allocSize: Word;
    { the VGA blits key on it, having no mask }
    transparentColor: Byte;
    { mask, one byte per data byte; nil unless requested, and always nil in VGA mode }
    transp: PByteArr;
    { the frames, inline after the header; the length varies, so [0..0] stands for it }
    data: array[0..0] of Byte;
  end;

  PEclRet = ^TEclRet;
  { one ECL GOSUB return, a node EclMenu's EclGosub allocates }
  TEclRet = record
    { GBVM address to return to }
    addr: Word;
    { the return below it }
    next: PEclRet
  end;

  { [0] the monster's sprite is loaded, [1] its close-up picture; EclMenu's DisplayMonster }
  TMonFlags = array[0..1] of Boolean;

  { One 8x8 glyph, a byte per pixel row. }
  TGlyph = array[0..7] of Byte;
  { The 8x8 game font: the glyph of each character code. }
  TFont = array[0..255] of TGlyph;
  PFont = ^TFont;

  { one byte per square of a 16x16 3-D map, [y][x] }
  TGeoPlane = array[0..15, 0..15] of Byte;
  { a 3-D map's four planes, as View3D loads them from GEO<n>.DAX }
  TGeoMap = record
    { north wall in the high nibble, east in the low }
    wallsNE: TGeoPlane;
    { south wall in the high nibble, west in the low }
    wallsSW: TGeoPlane;
    { each square's event byte }
    events: TGeoPlane;
    { 2 bits per facing }
    barriers: TGeoPlane;
  end;
  PGeoMap = ^TGeoMap;
  { where the party stands on the 3-D map and what it faces there: SaveLoad saves and loads it whole with the game, and
    GameInit clears it whole and starts the party on it }
  TPartyPosition = record
    { the party's column on the 16 by 16 map: Explore steps it, ECL sets and steps it through EclMenu, GameInit starts
      it at 7 }
    mapX: ShortInt;
    { the party's row; the same writers, GameInit starting it at 13 }
    mapY: ShortInt;
    { 0..7 clockwise from north: Explore turns it, ECL sets it through EclMenu, CombatSt turns it while it lays out the
      combat arena and puts it back, GameInit starts it at 0, or 2 on a soft restart }
    facing: Byte;
    { View3D's GetWallType for the facing side of the party's square, which EclMenu, EclVm and Explore store; EclMenu's
      ReadGbvm gives it to ECL }
    wallAhead: Byte;
    { the event byte of the party's square, View3D's GetMapEvent, which EclMenu, EclVm, Explore and MapView store;
      MapView picks the sky and View3D's DrawBackdrop the backdrop by its bit $80, and ReadGbvm gives it to ECL }
    mapEvent: Byte
  end;
  { a WALLDEF bank: five wall slices of 156 cells }
  TWallDef = array[1..5, 0..155] of Byte;
  TWallDefs = array[1..4] of TWallDef;
  PWallDefs = ^TWallDefs;

  { the display adapter buck.cfg names, VGA in mode 13h; GameBoot sets it up }
  TVideoMode = (VmCga, VmEga, VmTandy, VmVga);

  { one ITEMS row: what every item of one type shares }
  TItemType = record
    case Byte of
      { equipment slot, a C_Equip value }
      0: (slot: Byte;
          { attacks per round times two; halved where used }
          attacksDoubled: Byte;
          { a weapon's C_WClass value; for armor, armor class plus 50 }
          weaponClass: Byte;
          { non-zero: readying it in combat ends the turn }
          isHeavy: Byte;
          { damage dice }
          diceCount: Byte;
          { sides of each damage die }
          diceSides: Byte;
          { added to the damage roll }
          damageBonus: ShortInt;
          { reach in cells; above 1 is a ranged weapon }
          range: Byte;
          { non-zero: the item is removed when its quantity runs out }
          isConsumable: Byte);
      { the same nine bytes, for readers that index them }
      1: (values: array[0..8] of Byte)
  end;
  { a row of GDVars.itemTemplates, and TItem.template: the bytes a new item copies }
  TItemTemplate = record
    { index into itemTypes; EMPTY_TEMPLATE marks an empty template }
    itemType: Byte;
    { words of the item's name }
    nameIds: array[1..3] of Byte;
    { enchantment bonus }
    plus: ShortInt;
    { saving-throw bonus }
    saveBonus: ShortInt;
    { the bits C_Item.READIED, C_Item.NOT_TREASURE and C_Item.NOT_JOINABLE }
    flags: Byte;
    { the debug view labels it 'german' }
    unidentifiedMask: Byte;
    { encumbrance the item adds }
    weight: Word;
    { how many the item holds }
    quantity: Byte;
    { what the item is worth }
    value: Word;
    { special 2 is a projectile kind, fired while special 3 is non-zero }
    special: array[1..3] of Byte
  end;
  { where one combatant stands in the arena }
  TCombatantCell = record
    { arena cell }
    x: ShortInt;
    y: ShortInt;
    { its own slot, which CombatSt stores; otherwise unused }
    slotIndex: Byte;
    { icon size; 0 takes the combatant out of play }
    size: Byte
  end;
  { one entry of Pathing's target list }
  TTarget = record
    { the target's combatant slot }
    slot: Byte;
    { walking distance, doubled }
    distance: Byte;
    { compass direction 0..7 towards the target }
    direction: Byte
  end;
  { Pathing's line-walk state: PathFind starts a Bresenham walk from (sx, sy) to (ex, ey), and each NextPathStep
    advances it one cell. }
  TPathReq = record
    { start and end points }
    sx: Integer;
    sy: Integer;
    ex: Integer;
    ey: Integer;
    { error accumulator }
    err: Integer;
    { Abs(ex - sx) }
    adx: Integer;
    { Abs(ey - sy) }
    ady: Integer;
    { current x }
    cx: Integer;
    { current y }
    cy: Integer;
    { x step sign }
    stepX: Integer;
    { y step sign }
    stepY: Integer;
    { distance walked: 2 per straight step, 3 per diagonal }
    dist: Byte;
    { direction of last step (0..8) }
    step: Byte;
  end;
  { one wall-set cache entry }
  TWallSet = record
    { the WALLDEF set loaded here; NO_WALL_SET_FILE when empty }
    fileId: Integer;
    { the cache slot it was loaded into; NO_WALL_SET_SLOT when empty }
    slot: Word
  end;
  { a picture and the id it was loaded for }
  TPortraitSlot = record
    { reset to 255 wherever picture is freed or cleared }
    id: Byte;
    { GameInit sets it to nil; CombatSt and Explore free it }
    picture: PImgBuf
  end;
  PCharacter = ^TCharacter;
  { an effect handler's var parameter: the caller's pointer to the character }
  TEffectOwner = record
    { the character the effect is on }
    character: PCharacter
  end;
  PEffect = ^TEffect;
  { removed: 1 at its end }
  TEffectHandler = procedure(var owner: TEffectOwner; effect: PEffect; removed: Byte);
  { an overlay read routine, assignable to Overlay's OvrReadBuf; 0 when the read succeeds }
  TOverlayReader = function(overlaySegment: Word): Integer;
  { an animation as Portrait's LoadAnimation reads it from its DAX resource }
  TPortraitAnimation = record
    { each frame's time on screen in tens of ticks, byte 2 of its entry: LoadAnimation stores them, MenuCore's menu loop
      waits by them }
    frameDelays: array[0..8] of Byte;
    { bytes of each frame's encoded data: LoadAnimation reads them from the record and steps, allocates and decodes by
      them; VgaFrame decodes by them }
    encodedSizes: array[0..8] of Word;
    { the frame held whole, which the others are XOR deltas of: LoadAnimation reads it from the record; VgaFrame and
      Portrait decode against it }
    keyFrameIndex: Byte;
    { the frame MenuCore's menu loop goes back to after lastFrameIndex; LoadAnimation reads it from the record }
    loopStartFrame: Byte;
    { the last frame, at most 8: LoadAnimation sets it, FreeAnimation frees frames 0 to it, MenuCore's menu loop wraps
      after it }
    lastFrameIndex: Byte;
    { the frame shown: MenuCore's menu loop steps it and shows it, EclVm shows it with Portrait's DisplayImageBuf }
    currentFrame: Byte
  end;
  { a portrait animation's frames and picture in VGA mode }
  TVgaAnimation = record
    { the frames, the key frame decoded and the rest encoded: Portrait's loader allocates and fills them, FreeAnimation
      frees them, and VgaFrame decodes one into display }
    frames: array[0..8] of Pointer;
    { the picture VgaFrame's PrepareVgaFrame decodes a frame into: Portrait's loader allocates it and DisplayImageBuf
      draws it, FreeAnimation frees it }
    display: PImgBuf
  end;
  { a count EclVm's EclCall steps each time it shows the animation's current frame for ECL }
  TDisplayCounter = record
    { the value position wraps after; GameInit clears it }
    limit: Byte;
    { counted up by EclCall and back to 1 past limit }
    position: Byte;
    { unused; GameInit clears them with limit and position }
    frames: array[$02..$41] of Byte
  end;

  { one effect a character is under, a node of its effect list; FxEngine's AddEffect allocates and fills it,
    RemoveEffect unlinks and frees it }
  TEffect = record
    { the effect number, which picks its handler in effectHandlers }
    effectId: Byte;
    { game minutes left, 0 for an effect that does not run out: GameTime counts it down and removes the effect when it
      runs out }
    duration: Word;
    { the modifier EffHndlr's handlers pass to FxEngine's RollSavingThrow }
    strength: Byte;
    { non-zero: RemoveEffect calls the effect's handler as it ends it }
    callsOnRemove: Byte;
    { the character's next effect, nil at the end of the list }
    next: PEffect
  end;

  PMenuNode = ^TMenuNode;
  { one line of a list MenuCore's MenuVertical shows; an item's first 46 bytes have the same shape, so an item list is
    shown in place }
  TMenuNode = record
    { the line's text }
    name: String[40];
    { non-zero: a label line, drawn in promptColor, which the cursor skips }
    isLabel: Byte;
    { the next line, nil after the last }
    next: PMenuNode
  end;

  PItem = ^TItem;
  { one item, a node of a character's item list or of a treasure or shop list }
  TItem = record
    { the name a menu shows }
    name: String[40];
    { TMenuNode's label flag: EclVm, Shop and ViewChar clear it in the items they build, so a menu shows each item as a
      line it can select }
    isLabel: Byte;
    { the next item in its list, nil at the end }
    next: PItem;
    { the bytes an item template holds, which a new item copies from GDVars.itemTemplates }
    template: TItemTemplate
  end;

  PCombatState = ^TCombatState;
  { a combatant's state: CombatSt allocates and clears it for ground combat, ShipCbt for ship combat; CharGen and
    PostCbt free it }
  TCombatState = record
    { CbtActs's BeginRound sets it to 1 as the combatant's round starts }
    active: Byte;
    { this round's initiative, 0..20: BeginRound rolls it, Combat orders combatOrder by it; CharHlp's EndActions,
      CbtMap's CreatureDowned and CombatAi's AiMoveAttack clear it, and CombatAi's space key sets 20 }
    initiative: ShortInt;
    { the attack slot, 2 then 1, the combatant's attacks go on from: BeginRound sets 2, RollAttacks each attack's slot }
    attackSlot: Byte;
    { moves left this turn: BeginRound sets it and CombatMoveCreature spends it, for Combat's MoveMenu and CombatAi
      alike; Combat doubles it for a sprint and MoveMenu puts it back on an undo, CbtActs's jetpack and zero-gravity
      roll and CombatAi's AiMoveStep also change it, and EndActions and CbtMap's CreatureDowned clear it }
    movement: Byte;
    { True while the combatant guards: CbtActs's Guard sets it, GuardersAttack clears it once the guard attacks, Combat,
      EndActions and CbtMap's CreatureDowned clear it }
    isGuarding: Boolean;
    { 1..127, rolled with the initiative to order equal initiatives }
    tieBreaker: Byte;
    { True once the combatant has attacked this round: BeginRound clears it, RollAttacks sets it }
    hasAttacked: Boolean;
    { the way the combatant faces, 0..7 }
    direction: Byte;
    { the creature it attacks }
    target: PCharacter;
    { CharHlp's InflictDamage starts it at the damage past 0 hit points as the character starts dying;
      ProcessDyingCharacters counts it up each round and past 9 the character slips into a coma; ViewChar's
      TreatPatients clears it }
    dyingCount: Byte;
    { attacks made on the combatant since it last acted or moved: CbtActs's NoteAttackDirection counts each before
      MakeAttack resolves it, from Combat's MeleeAttack, CombatAi, CbtActs's ConfirmAttackTarget and GuardersAttack
      alike; CombatMoveCreature and Combat's CreatureAction clear it. MakeAttack turns the combatant to face its
      attacker while it is below 2, and IsRearAttack needs more than 1 }
    attacksDrawn: Byte;
    { the angles the attacks attacksDrawn counts came from, each 0..4 eighths off the combatant's facing, summed mod 8;
      the same writers, and NoteAttackDirection reads it as it adds to it }
    directionTotal: Byte;
    { 1 keeps the combatant out of the fight: CombatSt sets it for creatures past the party limit, PostCbt for a hostile
      that recovers; CbtActs, CombatSt, CbtMap, CharHlp, Combat, CombatAi, FxEngine, PostCbt and ViewChar test it }
    isOutOfPlay: Byte;
    { True while CombatAi runs the creature away }
    isFleeing: Boolean;
    { the aiDirOffsets row, 1..6, CombatAi steps the creature by }
    approach: Byte
  end;

  { a character's icon sequence, which CharGen's icon editor saves and puts back whole }
  TIconSequence = array[0..15] of Byte;
  { a character or creature, a party member or combatant: SaveLoad saves, loads and allocates its $103 bytes. ECL reads
    and writes bytes $10..$B9 through EclMenu's zone 1 bytes at the same offsets }
  TCharacter = record
    name: String[15];
    { STR DEX CON INT WIS CHA TCH, ViewChar's abilityAbbreviations; all but Strength head a skill group, TSkillGroup's
      GroupDexterity..GroupTechnical }
    abilities: array[0..6] of Byte;
    { the abilities as they stand; CharGen copies abilities into them }
    currentAbilities: array[0..6] of Byte;
    { the eight saving throws FxEngine's RollSavingThrow reads by save type; CharGen sets them and lowers each by 1 at
      every third level trained }
    saves: array[0..7] of Byte;
    gender: TGender;
    race: TRace;
    career: TCareer;
    level: ShortInt;
    levelTail: Byte;
    { the character's credits }
    creditTotal: LongInt;
    experience: LongInt;
    { CharGen sets it from careerBaseCombat. CharHlp's WeaponAdjust and RecalcStats start attackBonus from it, and
      ShipCbt's TargetValue starts a crew member's gunnery from it }
    baseCombat: Byte;
    { the combat icon's size in the ICON_SIZE_MASK bits, as CbtMap and CbtActs read it; CombatSt takes only the low
      three }
    iconDimensions: Byte;
    iconDimensionsTail: Byte;
    { CharHlp's RecalcMovement starts from it }
    baseMovement: Byte;
    { RecalcStats starts armorClass, an array of Byte, from it; CharGen sets it to 50 for a new character }
    baseArmorClass: ShortInt;
    { CharGen rolls it, GameTime ages the party, ViewChar shows it }
    age: Byte;
    ageTail: array[$39..$3A] of Byte;
    { attacks per round, doubled, with no weapon: CbtActs's first attack slot }
    baseScale: Byte;
    { attacks per round, doubled: CbtActs's second attack slot }
    scale: Byte;
    { damage dice per attack slot with no weapon, which RecalcStats copies into currentRolls }
    unarmedRolls: array[1..2] of Byte;
    { sides of those dice, copied into currentDice }
    unarmedDice: array[1..2] of Byte;
    { added to that damage, copied into currentModifiers }
    unarmedModifiers: array[1..2] of ShortInt;
    unarmedModifiersTail: array[$43..$44] of Byte;
    hitPointMaximum: Word;
    hitPointMaximumTail: Byte;
    { the Armor bits CharHlp's AdjustEquippedItem sets for each readied item as RecalcStats rebuilds it; CombatAi weighs
      C_Armor.ECM and C_Armor.BODY }
    armorFlags: Byte;
    armorFlagsTail: array[$49..$4B] of Byte;
    { non-zero marks a companion, a party member the player does not command: Combat runs it on quickfight unless, as
      combat starts, a team member that is not a companion makes a Leadership roll for it, which puts it under the
      player's command. An ally, which fights on the team's side in combat but is not in the party, is a different
      thing, and so is npc's bit NON_PLAYER_FLAG, the non-player character mark. EclMenu's SpecialWriteZ1 stores here
      bit $40 of what ECL writes to zone 1 byte $10C, and the whole of what ECL writes to zone 1 byte $4C; SpecialReadZ1
      answers $80 for byte $4C while it is non-zero, and adds $40 to byte $10C. CbtActs's UseLeadership sets a team
      member's isQuickfight from it, and a team member that is not a companion, with Leadership, may take a companion
      still on quickfight off it; Combat's and CombatAi's space key takes the team members that are not companions and
      still in play off quickfight and leaves the rest as they are; CombatAi's CheckMorale tests morale only while it is
      non-zero; CharGen's icon editor refuses it and its drop scan looks for a member that is not a companion }
    isCompanion: Byte;
    { Each skill's level, by skillDefinitions index. }
    skillLevels: array[1..84] of Byte;
    { unused. Note: CharGen's InitializeAllSkills runs its loop to $55, one past skillLevels, and so writes the first
      byte }
    skillLevelsTail: array[$A1..$B1] of Byte;
    { experience the party gains for defeating the creature; PostCbt }
    xpAward: Word;
    { a second item list, saved in the .hid file }
    alternateItems: PItem;
    icon: Byte;
    { the icon slot MapTiles loads the character's combat icon into, which CbtMap and CbtActs draw from: SaveLoad's
      AddCharToParty gives a member the first of 0..7 no other member holds, and EclVm gives each creature ECL adds
      nextCreatureIconSlot; CharGen sets 10 for a new character }
    orderNumber: Byte;
    { The item types the character has trained in: ViewChar trains at most three of one type, each into the first empty
      slot; CharHlp counts them, and ECL reaches them as zone 1 bytes $C4..$CD; SaveLoad's .who scan tests byte $C2,
      slot 9. }
    weaponSpecializations: array[1..10] of Byte;
    { CharGen's icon editor keeps and restores it }
    iconSequence: TIconSequence;
    status: TStatus;
    { non-zero while the character can act, kept beside status: EclMenu sets it with status, 1 only for StOkay; CharGen,
      GameTime and PostCbt set 1 as they make a character StOkay, and CharHlp, FxEngine, CbtActs and PostCbt clear it as
      they set a status it cannot act in; EclVm's UpdateCharacters sets it from status, 1 for StOkay and
      StDodging..StFailedZeroG, or clears it }
    isEnabled: Byte;
    { C_Side.TEAM or C_Side.HOSTILE }
    side: ShortInt;
    { non-zero: Combat runs the character itself }
    isQuickfight: Byte;
    { CharHlp's WeaponAdjust and RecalcStats work it out from baseCombat; FxEngine's AttackRoll adds it }
    attackBonus: Byte;
    { [0] from the front, [1] from behind; RecalcStats }
    armorClass: array[0..1] of Byte;
    { attacks left this round per attack slot; CbtActs }
    attacks: array[1..2] of Byte;
    { damage dice per attack slot, as RecalcStats works them out }
    currentRolls: array[1..2] of Byte;
    { sides of those dice }
    currentDice: array[1..2] of Byte;
    { added to that damage }
    currentModifiers: array[1..2] of ShortInt;
    hitPoints: Word;
    { moves per turn, as RecalcStats works them out }
    currentMovement: Byte;
    currentMovementTail: Byte;
    { bit NON_PLAYER_FLAG marks a non-player character, a different flag from isCompanion: CharGen admits at most six
      members without it, and one with it only while partyCount is below MAX_PARTY_SIZE, and saves a member without it
      as it leaves the party; Money pools the credits of members whose npc is 0 or PARTY_MEMBER_NPC and shares them out
      only to members below NON_PLAYER_FLAG, PostCbt staves off defeat and SaveLoad loads the icon from CHARS, not CPIC,
      only for a member below it, and ViewChar tests it too. The low seven bits are a morale: CombatAi's CheckMorale
      doubles them, CombatSt can set the byte to zone 1's moraleBase plus NON_PLAYER_FLAG, and EclVm's EclAddNpc sets
      the creature SaveLoad's AddCreatureToParty adds to NON_PLAYER_FLAG plus half the value ECL gives; with the party
      full AddCreatureToParty adds none, and the write lands on the current character }
    npc: Byte;
    { the weight of what the character carries: CharHlp works it out, ViewChar shows it }
    encumbrance: Word;
    { 1 marks the crew member picked to pilot the team's ship, saved with the character: ShipCbt sets it as the pilot
      takes over and clears it when the pilot falls; as ship combat starts it takes the first enabled holder as
      activePilot and clears it on any later one }
    isPilot: Byte;
    { the readied weapon and body armor, by ITEMS slot }
    readiedItems: array[C_Equip.WEAPON..C_Equip.ARMOR] of PItem;
    { the character's state in combat }
    combatState: PCombatState;
    { the items the character carries }
    itemList: PItem;
    { the effects the character is under }
    effectList: PEffect;
    { the next member of its list, nil after the last }
    next: PCharacter
  end;

  { one weapon mount of a ship }
  TShipWeaponSlot = record
    { the weapon, index into shipWeapons, in the KIND_MASK bits, 0 for none; ShipCbt lets the pilot fire a mount without
      CREW_MOUNT, the crew one with it }
    kind: Byte;
    { how many of the mount's weapons work when it is whole; PostCbt's repair and ShipCbt's jury-rig bring status back
      up to it }
    maxStatus: Byte;
    { how many of them work: hits take one away, and a round fires each once }
    status: Byte;
    statusTail: Byte;
    { rounds loaded: a shot from a kind above 2 spends one, and a reload adds the kind's reloadAmmo }
    ammo: Byte;
    { reloads left; ShipCbt's ReloadWeapon spends one }
    reloads: Byte
  end;

  PShip = ^TShip;
  { a ship, as SaveLoad's LoadShipData loads its $6C bytes from 'ships': the team's ship lives in zone 0, ShipCbt
    allocates the enemy's }
  TShip = record
    name: String[15];
    { CharHlp's ship screen shows it; in a ram ShipCbt does each ship's tonnage to the other's hull }
    tonnage: Integer;
    { CharHlp's ship screen shows it }
    shipLength: Integer;
    { CharHlp's ship screen shows it }
    shipWidth: Integer;
    { each system's strength, in shipSystemNames' order: hits lower it, and a system at 0 is destroyed }
    systemStatus: array[0..5] of Integer;
    { each system's strength when whole, which repairs stop at }
    systemMaximum: array[0..5] of Integer;
    { CharHlp's ship screen shows it }
    cargo: Integer;
    { CharHlp's ship screen shows it; ShipCbt splits the enemy ship's actions each round by it, and hits can lower it }
    crew: Integer;
    { the ship screen's AC; ShipCbt's TargetValue takes it and the firer's value from 60 for the roll a shot at the ship
      needs }
    armorClass: ShortInt;
    { the ship's own value for a Pilot Rocket check no crew member makes; ShipCbt sets the enemy's from its ECL
      arguments }
    alternateSkill: Byte;
    { the ship's own value for a skill 3 or 6 check no crew member makes }
    systemSkill: Byte;
    { the ship's own gunnery when no crew member fires; ShipCbt sets the enemy's from its ECL arguments }
    systemValue: Byte;
    { CharHlp's ShipSpeed starts from it }
    baseSpeed: ShortInt;
    { the ship screen's react; ShipCbt's pilot contest adds the team ship's and takes off the enemy's }
    reaction: ShortInt;
    { ShipCbt's TargetValue adds a target ship's to the firer's value }
    maneuver: Byte;
    { index into shipTypeNames }
    shipType: Byte;
    race: TRace;
    raceTail: Byte;
    weapons: array[0..7] of TShipWeaponSlot
  end;

  PArena = ^TArena;
  { the ground combat arena: CombatSt allocates it and lays its cells, Combat frees it }
  TArena = record
    viewOriginXLead: array[$00..$01] of Byte;
    { the arena column at the combat map view's left edge }
    viewOriginX: ShortInt;
    { the arena row at its top edge }
    viewOriginY: ShortInt;
    { CbtMap draws the cursor sprite while it is True; CombatSt clears it, and CbtMap and CbtActs set and clear it }
    isCursorShown: Boolean;
    { the icon size of the cursor CbtMap draws }
    cursorSize: Byte;
    { non-zero lets Pathing's WalkLine through lineClass 1 terrain }
    distMode: Byte;
    { the terrain of each cell, [row, column], an index into combatTerrain }
    cells: array[0..24, 0..49] of Byte
  end;

  { a combatant lying down in the arena, one entry of downedCreatures }
  TDownedCreature = record
    { the combatant }
    character: PCharacter;
    { the arena cell it lies on, CORPSE_TERRAIN unless a cloud covers it }
    x: ShortInt;
    y: ShortInt;
    { the terrain beneath the corpse, which CbtMap's lookups return }
    terrain: Byte
  end;

  { a target choice CbtActs's Aim menu and cursor make: the creature, nil if none, and the cell chosen }
  TAimTarget = packed record
    character: PCharacter;
    x: Byte;
    y: Byte;
    yTail: Byte
  end;

  PAreaEffect = ^TAreaEffect;
  { a lingering projectile's cloud on the arena, a node of the list the combat units keep in areaEffects: CbtActs's
    CombatLaunchProjectile lays one for a lingering projectile kind, FxEngine's CountDownAreaEffects frees it as it
    clears, and Combat frees the rest as combat ends }
  TAreaEffect = record
    { the next cloud, nil after the last }
    next: PAreaEffect;
    { the terrain beneath each cell of the cloud's 3x3 block, by blockCellDirections index: CbtMap's ResolveTerrain and
      DrawTerrainCell see through the cloud to it, SetTerrain changes it, and FxEngine puts it back on the arena as the
      cloud clears }
    underlyingTerrain: array[1..9] of Byte;
    { non-zero for each block cell the cloud covers: one on the arena whose terrain was passable when CbtActs laid the
      cloud }
    active: array[1..9] of Byte;
    { the arena cell at the block's center, where the projectile came down }
    x: ShortInt;
    y: ShortInt;
    { rounds left: CbtActs starts it at 4, or 1 in zero gravity, and CountDownAreaEffects counts it down each round and
      clears the cloud once it is at most 1 }
    countdown: Byte;
    { the terrain CbtActs lays on each covered arena cell, one of CLOUD_TERRAINS by the projectile kind; FxEngine's
      LayAreaEffectMarkers lays it again }
    markerTerrain: Byte
  end;

  { an orbit-map cell }
  TOrbitCell = record
    x: Byte;
    y: Byte
  end;
  POrbitView = ^TOrbitView;
  { the orbit map's state, which TZone0's orbit arm lays over zone 0: GameInit's InitShipAndOrbit clears tick and phase
    and puts the rocket on orbit 2's body, and OrbitMap and Explore reach it through orbitView }
  TOrbitView = record
    { the cell of each body OrbitMap's PaintOrbitMap last drew: [0..4] one per orbit, [5..12] orbit 4's eight others }
    bodyPositions: array[0..12] of TOrbitCell;
    { zone 0's bytes up to areItemsStashed, which TZone0's arm 1 declares }
    bodyPositionsTail: array[$1A..$33] of Byte;
    { time on the orbit map: Explore's MoveRocket adds 3 for each step and, past 31, takes 32 off and steps phase down;
      GameInit clears it }
    tick: Byte;
    { zone 0's shipCombatOutcome, declared in TZone0's arm 1 }
    shipCombatOutcome: Byte;
    { where the bodies stand: PaintOrbitMap draws orbit i's body at position (orbitStartPhases[i] + phase) mod
      orbitLengths[i]; MoveRocket counts it down, and from 0 back to 223; GameInit clears it }
    phase: Byte;
    phaseTail: Byte;
    { the rocket's tile, 87..94 by its heading: MoveRocket turns it toward the way it steps and OrbitMap draws it;
      GameInit sets 87 }
    rocketIcon: Byte;
    { the rocket's orbit-map column, 0..21: MoveRocket steps it, never onto the center cell 11, 10, and OrbitMap draws
      the rocket there; GameInit starts it on orbit 2's body as it stands at phase 0 }
    rocketX: Byte;
    { the rocket's row; the same writers and reader }
    rocketY: Byte
  end;

  { The GBVM zones, one byte per GBVM address; zone 3 holds the ECL script. Each is indexed from its GBVM base, zones 0
    and 1 through their records' cells arm, so a full GBVM address subscripts it directly. Their second arm names the
    fields the Pascal code uses, each bounded by its GBVM addresses, with the spare bytes between them; zone 0's third
    arm lays TOrbitView over the orbit block. }
  TZone0 = record
    case Byte of
      { every zone 0 address, as the ECL reads and writes them by address }
      0: (cells: array[$4B00..$4EFF] of Byte);
      1: (skipsTreatmentLead: array[$4B00..$4B7F] of Byte;
          { non-zero keeps PostCbt's PostCombat from offering poison and wound treatment after a combat; PostCombat then
            clears it, and ShipCbt clears it at the end of a ship combat }
          skipsTreatment: Byte;
          { four spare bytes, then the orbit arm's orbit.bodyPositions and six bytes more }
          skipsTreatmentTail: array[$4B81..$4BA4] of Byte;
          { the planet Portrait names under the picture in C_Ifc.ORBIT_MAP: 1 Mercury, 2 Venus, 3 Earth, 4 Mars, above 4
            the asteroids, 0 none }
          planet: Byte;
          { the mode EclVm's EclSetPictureMode was last given: 0 the 3-D view, 2 C_Ifc.ORBIT_MAP, 3 C_Ifc.PICTURE_VIEW,
            4 C_Ifc.WILDERNESS with isViewActive, 1 the interface state as it was }
          pictureMode: Byte;
          pictureModeTail: array[$4BA7..$4BA9] of Byte;
          { non-zero keeps PostCbt's PostCombatCreatureCleanup from removing the hostile creatures after a combat, but
            for those out of play }
          preservesHostiles: Byte;
          preservesHostilesTail: array[$4BAB..$4BB3] of Byte;
          { EclVm's EclSetSpeaker clears them }
          speakerCells: array[$4BB4..$4BB5] of Byte;
          { the difficulty level, DIFFICULTY_NOVICE to DIFFICULTY_ACE: Explore's Level menu sets it and GameInit starts
            it at DIFFICULTY_TROOPER; FxEngine's AttackRoll gives a team attacker +2 down to -2 by it, and EclVm gives
            each hostile creature it adds (difficulty + 2) quarters of its hit points }
          difficulty: Byte;
          { the terrain CombatSt's BuildWildernessArena lays a wilderness arena from, 10 more in an area whose areaKind
            has 8 in its low nibble }
          wildernessTerrain: Byte;
          { 1 once EclVm's EclTransferCharacterLists moves each member's items onto its alternateItems list, 0 once it
            moves them back }
          areItemsStashed: Byte;
          { the orbit arm's orbit.tick }
          areItemsStashedTail: Byte;
          { how ShipCbt's last ship combat ended: 0 the enemy ship destroyed or boarded, 1 the team's ship destroyed or
            the enemy out of range }
          shipCombatOutcome: Byte;
          { the orbit arm's orbit.phase, orbit.phaseTail, then orbit.rocketIcon, rocketX and rocketY, then three spare
            bytes }
          shipCombatOutcomeTail: array[$4BBB..$4BC2] of Byte;
          { the party's column on a wilderness picture, 0..37: Explore's MovePartyWilderness steps it, MapCurs shades
            the cell it names }
          wildernessX: Byte;
          { the party's row on a wilderness picture, 0..14; the same writer and reader }
          wildernessY: Byte;
          { the GEO record of the 3-D map loaded, NO_GEO_MAP for none: View3D's Load3DMap and EclVm's EclLoadFiles set
            it, SaveLoad's LoadGame loads the map back from it }
          geoMapId: Byte;
          { the game clock, smallest unit first, each unit clockUnitScale of the one before, so the fourth is the hour,
            the third the ten-minute turn and the second the minute within it: GameTime advances it, and CharHlp's
            position line shows those three }
          clock: array[$4BC6..$4BCC] of Byte;
          clockTail: array[$4BCD..$4BE4] of Byte;
          { EclMenu's EclInit clears it as a script loads }
          antimagic: Byte;
          { what the party is in, which ECL sets: $A2 and $A8 wilderness shown as a big picture, $70 C_Ifc.ORBIT_MAP's
            picture, others the 3-D view; bit $10 zero gravity, which CbtActs and CombatAi test; CombatSt builds the
            ground combat arena by it }
          areaKind: Byte;
          { with mapGraphics2 non-zero too, EclVm's EclLoadFiles loads the first wall set into cache slot 0 and the
            third into slot 3, not the three into slots 1..3 }
          mapGraphics1: Byte;
          mapGraphics2: Byte;
          { EclMenu's ReadGbvm answers partyPosition.facing for $4BEA instead of reading it }
          mapGraphics2Tail: array[$4BE9..$4BEF] of Byte;
          { the party's column before its last step: EclVm's map loop keeps partyPosition.mapX here and plays stepSound
            when the step moved the party, Explore's MovePartyWilderness keeps wildernessX }
          previousX: Byte;
          { the party's row before its last step, likewise }
          previousY: Byte;
          { the ECL script EclVm's GameLoop loads to start the map loop, NO_ECL_SCRIPT for none, when it loads $10, or
            $12 in the demo: the map loop keeps eclId here, and EclNewEcl keeps the script it replaces until the new one
            loads; GameInit clears it }
          savedEclId: Byte;
          savedEclIdTail: array[$4BF3..$4BFA] of Byte;
          { non-zero refuses Explore's Area command, and MapView turns the automap off while it is set }
          isAutomapLocked: Byte;
          { 0..SLOWEST_MESSAGE_SPEED, the higher the slower: TextRend waits it times 3 ms after each character of a
            message and it times 100 ms in PauseOnly; Explore's Messages menu sets it, GameInit starts it at 4,
            FixMain's demo sets SLOWEST_MESSAGE_SPEED, and CharHlp's PrintNameStringAnim plays a damage animation
            (messageSpeed shr 1) + 1 times, but once for an explosion }
          messageSpeed: Byte;
          { the index into MapView's skyColors it draws the 3-D view's sky from on a square whose event byte is at most
            $7F }
          skyIndexLo: Byte;
          { the same above $7F }
          skyIndexHi: Byte;
          { arePicturesEnabled times two plus areAnimationsEnabled, which SaveLoad's SaveGame stores here and LoadGame
            takes back }
          displayOptions: Byte;
          { EclMenu's EclInit clears them as a script loads, unless a saved game has just loaded }
          entryBytes: array[$4C00..$4C1F] of Byte;
          entryBytesTail: array[$4C20..$4C62] of Byte;
          { the team's medical supplies, which CharHlp's ship panel shows }
          medicalSupplies: Byte;
          medicalSuppliesTail: array[$4C64..$4CF5] of Byte;
          { the count of ECL's loop: EclVm's EclLoopInitialize sets it and EclLoopAdvance counts it up, jumping back to
            eclLoopStart while it is at most eclLoopLimit }
          eclLoopCounter: Byte;
          { the count's last value, which EclLoopInitialize sets }
          eclLoopLimit: Byte;
          eclLoopLimitTail: array[$4CF8..$4CFC] of Byte;
          { the column CharHlp's position line shows in place of partyPosition.mapX, NO_READOUT to show the party's
            own }
          readoutX: Byte;
          { the row it shows in place of partyPosition.mapY }
          readoutY: Byte;
          { added to partyPosition.facing, doubled while areaKind is non-zero, for the direction CharHlp's position line
            shows }
          directionOffset: Byte;
          { the team's ship, which GameInit's InitShipAndOrbit loads here with SaveLoad's LoadShipData; ShipCbt,
            CharHlp, PostCbt and Explore reach it through GDVars.partyShip }
          partyShip: TShip;
          { the systemStatus of the enemy ship ShipCbt's last ship combat left, or 0s when that ship got out of range }
          savedSystemStatus: array[0..5] of Integer;
          { that ship's shipType }
          savedShipType: Byte;
          { the low byte of its crew }
          savedCrewLo: Byte;
          { the high byte of its crew }
          savedCrewHi: Byte;
          { its systemValue }
          savedSystemValue: Byte;
          { a C_PostCb value, to which ECL may add bit 7; ShipCbt asks for the ship's repair itself while it is
            C_PostCb.NORMAL }
          postCombatMode: Byte;
          { ShipCbt clears them with savedWeaponCount and postCombatFlag }
          savedWeapons: array[$4D7D..$4D80] of Byte;
          { the weapons of the enemy ship that still work, the sum of its mounts' status, which ShipCbt counts at the
            end of a ship combat }
          savedWeaponCount: Byte;
          { ShipCbt sets it to 0 at the end of a ship combat }
          postCombatFlag: Byte;
          postCombatFlagTail: array[$4D83..$4D90] of Byte;
          { per ship kind 0..4, how many ships SaveLoad's LoadShipData has named: the count picks the name from
            shipNames, and above 1 it is added to the name }
          shipNameCounts: array[$4D91..$4D95] of Byte;
          shipNameCountsTail: array[$4D96..$4EFF] of Byte);
      { arm 1's bytes ahead of the orbit block }
      2: (beforeOrbit: array[$4B00..$4B84] of Byte;
          { the orbit map's state, whose address GameInit's InitShipAndOrbit stores in orbitView }
          orbit: TOrbitView)
  end;
  PZone0 = ^TZone0;
  TZone1 = record
    case Byte of
      { every zone 1 address, as the ECL reads and writes them by address }
      0: (cells: array[$7C00..$7FFF] of Byte);
      1: (trainingMaskLead: array[$7C00..$7EA7] of Byte;
          { CharGen's main menu offers Train Character while it is non-zero; CharGen sets it to $FF through its free
            training and clears it as the team sets out }
          trainingMask: Byte;
          trainingMaskTail: array[$7EA9..$7EBF] of Byte;
          { how far off ECL's SETUP MONSTER asks for the monster; EclVm's EclSetupMonster stores it }
          monsterMaxDistance: Byte;
          { how far off the monster shows: EclSetupMonster caps monsterMaxDistance at what the walls allow, and
            EclCombat caps it again; EclApproach brings it nearer, EclMenu's MaxMonsterDist sets 2 while areaKind is 0,
            and CombatSt spaces the sides by it }
          monsterDistance: Byte;
          monsterDistanceTail: array[$7EC2..$7EC5] of Byte;
          { a morale ECL sets for the fight: CombatAi's CheckMorale tests morale against 100 less it, and CombatSt gives
            it, NON_PLAYER_FLAG set, as the npc byte of team-side creatures past partyCount that have none }
          moraleBase: Byte;
          { how the last combat ended, which PostCbt sets: 0 won, 1 a monster fled, $80 the team was beaten, $81 the
            team fled }
          combatResult: Byte;
          { PostCbt's PostCombatCreatureCleanup clears it and counts in each creature it removes that can no longer
            act }
          monstersDefeated: Byte;
          { 255 holds the party in place: Explore's ResolveMovement clears it instead of moving; MapMainMenu and EclVm's
            EclLoadFiles clear it too }
          moveBlocked: Byte;
          { C_Search.SEARCHING while the team searches; LOOK_PENDING asks EclVm's map loop for one look, which Explore's
            Look sets }
          searchFlags: Byte;
          { bit 0 the team, bit 1 the hostiles: CbtActs's BeginRound takes 6 from those sides' initiative; Combat's
            CombatMain clears it each round once the combatants' actions are set up, so a mask ECL sets reaches the
            first round only }
          sideMask: Byte;
          sideMaskTail: array[$7ECC..$7ED1] of Byte;
          { ECL's rest interruption timing; EclMenu's EclInit clears it and restInterruptChance }
          restSafeTime: Byte;
          { the chance that ECL interrupts a rest }
          restInterruptChance: Byte;
          restInterruptChanceTail: Byte;
          { 1 once Explore's MoveForward stops the party at the 3-D map's edge; MoveForward and EclVm's NewEclDone clear
            it }
          hasLeftMap: Byte;
          hasLeftMapTail: array[$7ED6..$7EE2] of Byte;
          { 1 keeps PostCbt from taking the fallen creatures' items as treasure; PostCbt clears it after the combat }
          skipsCombatItems: Byte;
          skipsCombatItemsTail: array[$7EE4..$7EE5] of Byte;
          { non-zero: PostCbt puts dying and unconscious members back on their feet with 1 hit point after the combat,
            and then clears it }
          revivesParty: Byte;
          revivesPartyTail: array[$7EE7..$7F11] of Byte;
          { dataSet, which SaveLoad's SaveGame stores and LoadGame takes back }
          savedDataSet: Byte;
          savedDataSetTail: array[$7F13..$7F32] of Byte;
          { 1 once the team attacks an ally: CbtActs's CheckAttackAlly sets it, CombatSt's CombatStart clears it }
          hasAttackedAlly: Byte;
          hasAttackedAllyTail: array[$7F34..$7F3D] of Byte;
          { the party's members: SaveLoad counts each in as it joins, and CharGen's RemoveCreature counts one out unless
            told not to; GameInit, LoadGame, PostCbt and CharGen's add menu, on an empty party, clear it; CombatSt takes
            out of play the creatures past it, PostCbt shares the experience by it, and GameTime's TimeOutEffects and
            EclVm's EclDamage read it too }
          partyCount: Byte;
          { the remainder of ECL's last division: EclVm's EclArithmetic stores it }
          divisionRemainder: LongInt;
          divisionRemainderTail: array[$7F43..$7F6C] of Byte;
          { Shop's prices in sixteenths of an item's value; 0 sells at the value }
          priceMultiplier: Byte;
          priceMultiplierTail: array[$7F6E..$7F6F] of Byte;
          { FxEngine's AttackRoll adds it to a hostile attacker's roll; PostCbt clears it after the combat }
          monsterThac0Modifier: Byte;
          { the same for a team attacker }
          partyThac0Modifier: Byte;
          { CharHlp's RecalcMovement adds it to a team member's movement; PostCbt clears it after the combat }
          movementBonus: Byte;
          movementBonusTail: array[$7F73..$7F78] of Byte;
          { EclMenu's EclInit clears them as a script loads, unless a saved game has just loaded }
          newGameBytes: array[$7F79..$7F82] of Byte;
          newGameBytesTail: array[$7F83..$7FFF] of Byte)
  end;
  PZone1 = ^TZone1;
  TZone2 = array[$7A00..$7BFF] of Byte; PZone2 = ^TZone2;
  TZone3 = array[$8000..$A400] of Byte; PZone3 = ^TZone3;

type
  { area effect of one projectile kind }
  TProjectileKindInfo = record
    { the effect AddEffectWithMessage gives each creature hit, its save allowing; its effectStatusNames entry makes the
      combat message; 0 for none }
    effectId: Byte;
    radius: Byte;
    isLingering: Boolean;
    saveType: Byte;
    saveReduction: Byte
  end;
  { one main menu entry }
  TMenuRow = record
    name: String[40];
    isEnabled: Boolean
  end;
  { one wilderness scatter rule: runs of plots around a center }
  TTerrainProfile = record
    { percent chance that a run happens }
    chance: Byte;
    { a run makes diceCount d diceSides plots }
    diceCount: Byte;
    diceSides: Byte;
    { above 0, every cell within this many of a plot must be open }
    clearance: Byte;
    { how far from the center a plot may fall; 0 plots on the center }
    scatter: Byte;
    { a d scatterBonus roll added to scatter }
    scatterBonus: Byte;
    { C_Terr's PROFILE_ flags }
    flags: Byte;
    { the tile a plot lays, plus a 0..tileVariance - 1 roll }
    tile: Byte;
    { the tile laid beside it, plus a 0..pairVariance - 1 roll; UNSET_TERRAIN lays none }
    pairTile: Byte;
    tileVariance: Byte;
    pairVariance: Byte
  end;
  { one copy-protection question }
  TProtectionEntry = record
    { log-book page to look on }
    page: Byte;
    { heading on that page, encoded }
    displayText: String[18];
    { which word under the heading, an index into GDConsts.wordOrdinals }
    wordIndex: Byte;
    { that word, encoded }
    answer: String[8]
  end;
  { the free-list block at FreePtr, moved whole }
  TFreeBlk = array[0..7] of Byte;
  PFreeBlk = ^TFreeBlk;
  TSkill = record
    name: String[24];
    { 0 keeps it out of the general skills Skills' BuildSkillLists offers }
    isOffered: Byte;
    group: TSkillGroup
  end;
  TShipWeaponDef = record
    { longest range it fires at; ShipCbt }
    maxRange: Byte;
    { unused }
    maxRangeTail: Byte;
    { rounds one reload adds }
    reloadAmmo: Byte;
    { damage per hit, also ShipCbt's choice priority }
    damage: Byte;
    { added to the firer's hit total, so negative is harder to land; ShipCbt }
    targetBonus: ShortInt;
    { unused }
    targetBonusTail: array[0..1] of Word;
    { ShipCbt's combat messages, PostCbt's repair list }
    name: String[24]
  end;
  { one 'ships' picture: its buffer size, load flag and position }
  TShipPic = record
    { pixel rows, the height ShipCbt passes Blit.AllocPic }
    height: Byte;
    { 8-pixel columns, the width ShipCbt passes Blit.AllocPic }
    width: Byte;
    { unused }
    widthTail: Byte;
    { Blit.LoadPic's hasMask when OrbitMap loads the picture }
    isTransparent: Boolean;
    { CharHlp's screen cell for it; ShipCbt adds it to an effect's origin }
    x: ShortInt;
    y: ShortInt
  end;
  TOrbitPosition = record
    { map cell }
    x: Byte;
    y: Byte;
    { tile index, before OrbitMap adds ORBIT_TILES or OUTER_BODY_TILES }
    sprite: Byte
  end;
  { an INT 33h function 9 cursor: the AND mask, then the XOR mask }
  TMouseCursor = record
    screenMask: array[0..15] of Word;
    cursorMask: array[0..15] of Word
  end;
  PMouseCursor = ^TMouseCursor;
  { 0 low extreme, 1..5 zone thresholds with 3 the center, 6 high extreme }
  TJoyAxis = array[0..6] of Word;
  { one stick's calibration }
  TJoyCal = record
    x: TJoyAxis;
    y: TJoyAxis
  end;
  TDriverEntry = function(segment, offset, func: Word): Word;
  { the ten wall positions of the 3-D view }
  TWallSlots = record
    { first cell of the slot's rectangle in a 156-cell wall slice }
    start: array[0..9] of Byte;
    { rectangle size in cells }
    cols: array[0..9] of Byte;
    rows: array[0..9] of Byte;
    { screen cell of the rectangle's top left }
    xCol: array[0..9] of Integer;
    yRow: array[0..9] of Integer
  end;
  { The register block for software interrupts, laid out as Dos.Registers so storage can hold one without using Dos;
    callers pass it to Intr as a Registers. }
  TRegisters = record
    case Integer of
      0: (ax: Word;
          bx: Word;
          cx: Word;
          dx: Word;
          bp: Word;
          si: Word;
          di: Word;
          ds: Word;
          es: Word;
          flags: Word);
      1: (al: Byte;
          ah: Byte;
          bl: Byte;
          bh: Byte;
          cl: Byte;
          ch: Byte;
          dl: Byte;
          dh: Byte);
  end;

implementation

end.
