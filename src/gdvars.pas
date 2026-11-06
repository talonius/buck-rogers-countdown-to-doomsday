{ Global variables: the data segment's variables, grouped by the subsystem that owns them and kept in address order. A
  new section starts wherever the data needs a word boundary. }
unit GDVars;

interface

uses Types, C_Combat, C_Side;

{ Start-up: the title menu's answer and the copy-protection check's loop. }
var
  { the key FixMain's title menu answered, from menuKey; 'D' runs the demo }
  menuResult: Char;
  { unused }
  extendedKey: Byte;
  { FixMain's loop over protectionFlags after CopyProtection, which ends the game at a stage still 0 }
  protectionIndex: Byte;

{ Title sequence and ECL script loading: the data set Intro puts back, and what EclVm has loaded and must redo. }
var
  { unused }
  savedDataSetLead: Byte;
  { the caller's data set, restored when the title sequence ends }
  savedDataSet: Byte;
  { stops EclVm's CallEclScript after the command it is running, which clears it as it starts and ends: EclExit and
    EclNewEcl set it, and EclDamage's loop over the party stops on it }
  isEclStopped: Boolean;
  { set by EclVm's EclNewEcl when it has loaded another script, which NewEclDone then starts in place of the rest of the
    old one's entry points; NewEclDone and GameLoop clear it }
  isNewEclLoaded: Boolean;
  { set by EclVm's EclLoadCharacter, which makes another character current: EclExit and EclProgram put eclSavedCharacter
    back as the current character and clear it, and GameLoop clears it }
  restoresCharacter: Boolean;
  { set by EclVm's EclLoadFiles; NewEclDone then redraws the 3-D view, and GameLoop clears it }
  hasLoadedFiles: Boolean;
  { set by EclLoadFiles when it loads wall sets; with hasLoadedMap it redraws the exploration screen on coming out of
    the wilderness; GameLoop clears it }
  hasLoadedPieces: Boolean;
  { set by EclLoadFiles when it loads a 3-D map; GameLoop clears it }
  hasLoadedMap: Boolean;
  { creatures EclVm's EclLoadMonster has added to the encounter, at most 63; EclClearMonsters clears it }
  creatureCnt: Byte;

{ Post-combat outcome and the combat AI's step history. }
var
  { a hostile fell or a combat creature was removed: PostCombatSummary prints won or fled }
  hasOutcomeToReport: Boolean;
  { DetermineCombatResults sets it when a creature ahead of the first out of play is fleeing and, outside a solo combat,
    clears it again when one of them is okay; PostCombat and PostCombatSummary then discard the treasure }
  hasPartyFled: Boolean;
  { Money's DetermineTreasure answer that the pool holds credits, for PostCombatSummary's line and LootMenu's Take }
  treasureHasMoney: Boolean;
  { its answer that the pool holds items; the same readers }
  treasureHasItems: Boolean;
  { the direction AiMoveStep last stepped in, C_Dir.CENTER as AiMoveAttack starts }
  lastMoveDir: Byte;
  { the times since AiMoveAttack began that AiMoveStep found no step or reversed }
  stuckCount: Byte;
  { unused; AiMoveAttack clears it }
  aiMoveState: Byte;

{ Combat set-up: placing the combatants and laying the arena, and the wilderness scatter's state. }
var
  { 1 for each open placement cell, by team, ring, row, column }
  quadFree: array[0..1, 0..3, 0..5, 0..10] of Byte;
  { the column of each team's placement origin, in map squares from the party }
  placeX: array[0..1] of ShortInt;
  { the row of each team's placement origin }
  placeY: array[0..1] of ShortInt;
  { the tries a first-pass leg of FindPlacement makes, from the team's size }
  teamRows: array[0..1] of ShortInt;
  { each team's facing quarter, 0..3 }
  teamDir: array[0..1] of ShortInt;
  { the map square being laid, -6..6 from the party's column }
  arenaOX: ShortInt;
  { and -2..2 from its row }
  arenaOY: ShortInt;
  { WallBetween's kind on the north side of the square being laid }
  wallNorth: Byte;
  { the kind on its west side }
  wallWest: Byte;
  { the kind on its east side }
  wallEast: Byte;
  { the kind on its south side }
  wallSouth: Byte;
  { the team being placed, the creature's side }
  team: ShortInt;
  { unused }
  teamTail: array[0..1] of Byte;
  { the square's map-event bit $40: ScatterWallTiles' richer choices }
  squareVariant: Byte;
  { unused }
  squareVariantTail: array[0..5] of Byte;
  { RandSeed as ReseedRandom found it }
  savedSeed: LongInt;
  { the column of the center BuildWilderness plots a run around, kept for the next run when that has
    C_Terr.PROFILE_KEEP_CENTER }
  randomCenterX: Byte;
  { the center's row, likewise }
  randomCenterY: Byte;
  { above 0, replaces every run's scatter; -1 for none }
  scatterOverride: ShortInt;

{ Game start-up: GameInit's loop counters, its mouse probe and the ITEMS file. }
var
  { GameInit's loop counter over the palette entries and the scanline tables }
  index: Byte;
  { GameInit's loop counter over a default palette entry's red, green and blue }
  component: Byte;
  { unused }
  maskIndex: array[0..1] of Byte;
  { OpenWithRetry's answer for ITEMS; not tested }
  hasOpenedItems: Boolean;
  { unused }
  hasOpenedItemsTail: array[0..42] of Byte;
  { the buttons GameInit's mouse probe reads back; unused }
  mBtn: Integer;
  { the x GameInit's mouse probe reads back after moving the mouse to 639: below 321 the driver halves x }
  mX: Integer;
  { the y the probe reads back; unused }
  mY: Integer;
  { the ITEMS file, which GameInit reads into itemTypes at start-up }
  itemsFile: file;
  { unused }
  itemsFileTail: Byte;

{ Shop: the buy and clip menus' redraw flag. }
var
  { the redraw flag Shop hands MenuCore's MenuVertical for its item and clip menus; Shop sets it before each menu }
  menuNeedsRedraw: Boolean;

{ Character sheet: its character, the trade selectors and the patients to treat. }
var
  { the character ViewChar's sheet shows, the current character as the sheet is drawn }
  sheetCharacter: Types.PCharacter;
  { the trade selectors' start: the menu's character, then the last one traded with }
  tradePartner: Types.PCharacter;
  { combat slots of the characters TreatPatients can treat }
  patientSlots: array[1..8] of Byte;
  { patients FindPatients listed; TreatPatients counts it down per treatment }
  patientCount: Byte;

{ Skill screen: the group shown and the general skills known. }
var
  { the skill group Skills' screen is spending points in, career skills first, then each general group in turn }
  currentGroup: Types.TSkillGroup;
  { the general skills the character has a level in: Skills counts them, and caps a new one past them }
  knownGeneralCount: ShortInt;
  { EditSkills got maxPerSkill 0: list only the general skills the character has, to view }
  isViewOnly: Boolean;

{ Effects running down, line-of-fire results, and GameBoot's start-up dialog and heap set-aside. }
var
  { by position in partyHead's list, which in combat holds every combatant, CombatSt's slot order: 1 while that member
    may have an effect running down }
  effectFlags: array[1..C_Combat.MAX_COMBATANTS] of Byte;
  { WalkLine sets the three saw flags. Its first two cells that are neither chaff nor aerosol mist are grace cells:
    lineClass 2 terrain there does not set sawBlockedTerrain. CbtActs's CalcWeaponDamage also sets sawChaff or
    sawAerosolMist when the cell its WalkLine ends on holds that cloud. }
  { WalkLine crossed a CHAFF_TERRAIN cell }
  sawChaff: Boolean;
  { WalkLine crossed an AEROSOL_MIST_TERRAIN cell }
  sawAerosolMist: Boolean;
  { WalkLine crossed lineClass 2 terrain past its grace cells }
  sawBlockedTerrain: Boolean;
  { WalkLine stops at the first chaff cell; the caller sets it, WalkLine clears it }
  stopsAtChaff: Boolean;
  { the free list's new place, below the heap set aside for Tandy video memory, which GameBoot moves FreePtr to }
  newFreePtr: Types.PFreeBlk;
  { a buck.cfg line's letter, or a digit key the dialog takes }
  cfgChar: Char;
  { the number GameBoot's first-run dialog read for its display, sound and input questions }
  menuChoice: Byte;
  { buck.cfg, which GameBoot writes on the first run and reads at each start }
  cfgText: Text;
  { unused }
  cfgFile: file;
  { IOResult of creating a missing buck.cfg; non-zero has GameBoot report a write-protected disk }
  cfgErr: Byte;
  { GameBoot's loop counter over the save path's letters and the joystick calibration }
  ix: Byte;
  { the save path the first-run dialog reads, upper-cased and ending in a backslash, for buck.cfg }
  pathBuf: Types.TString80;
  { the name part FSplit gives for the program's path; unused }
  fsName: String[8];
  { the extension part FSplit gives; unused }
  fsExt: String[4];
  { the save path the first-run dialog offers, gAltPath's SAVE directory }
  defaultSavePath: String[79];

{ Data paths: where GameBoot looks for the data files. }
var
  { where a name without a directory is looked for first; GameBoot sets it to the current directory }
  gDataPath: string[79];
  { swapped with gDataPath when a file is not found: GameBoot sets it to the other floppy drive's root (B:\ for A:, else
    A:\) on a floppy, else to gDataPath }
  gAltPath: string[79];
  { drive letter named in the floppy prompt: gAltPath's at start-up }
  gPromptDrive: Char;

{ The music driver's entry point and the sound driver's countdown; then the session: start-up flags, the GBVM zones, the
  ECL entry points and the interface state. }
var
  { the music driver's entry, which MusDrv's StartDriver points at the loaded code and DriverCall calls through }
  driverEntry: Types.TDriverEntry;
  { the music bank's address as StartDriver copies it, split into offset and segment }
  bankCopy: Types.TPtrWords;
  { stored after every call }
  driverResult: Word;
  { the music bank's offset, which StartDriver passes to the driver's function 0 }
  bankOffset: Word;
  { the music bank's segment, passed with bankOffset }
  bankSegment: Word;
  { points at ExitCount, the ISR's fake-error countdown, which command 21 sets }
  timeoutPtr: ^Word;
  { Two flags the start-up sets: buck.cfg's intro choice, which GameBoot reads from the file, and whether a game is
    under way, which Intro and GameInit set and HeapErr tests before it quits for lack of memory. }
  { True when buck.cfg's intro line is F; GameBoot sets it from the file, and the game does not otherwise use it }
  isFullIntro: Boolean;
  { True: HeapErr saves the game before it quits for lack of memory; GameInit's InitializeGame clears it at start-up,
    and Intro's FinishIntroduction and GameInit's ResetGameState set it }
  isGameUp: Boolean;
  { Pointers to the four GBVM zones, the memory ECL reads and writes by address: GameInit allocates them, SaveLoad saves
    and loads zones 0 to 2 with the game, zone 3 holds the loaded ECL script, and most of the game reaches the zones'
    named fields and cells through them. }
  { GBVM zone 0, saved with the game }
  zone0: Types.PZone0;
  { GBVM zone 1, saved with the game }
  zone1: Types.PZone1;
  { GBVM zone 2, saved with the game; EclMenu reads and writes it by GBVM address }
  zone2: Types.PZone2;
  { GBVM zone 3, the ECL script: EclMenu's LoadEclScript loads a script into it, EclMenu and EclVm read the script from
    it, and EclMenu also reads and writes it by GBVM address }
  zone3: Types.PZone3;
  { Positions in the loaded ECL script: its five entry addresses and the instruction pointer. }
  { the five entry addresses at the head of the loaded ECL script, which EclMenu's EclInit copies here: EclVm runs [5]
    after a script loads (NewEclDone then [1] and [2]); each GameLoop turn runs [1] before the party moves and [2] after
    it, and [2] while a Look (Explore's MapMainMenu sets LOOK_PENDING) or 'E' is pending }
  eclEntryPoints: array[1..5] of Word;
  { the ECL instruction pointer, a GBVM address in zone3: EclMenu's EclInit and GameInit set it to the script's start,
    EclVm's CallEclScript to the entry point it runs, EclMenu's LoadEclVars, SkipEclCmd and EclGosub and EclVm's
    commands advance it and jump it, and Explore's MapMainMenu sets it to entry point [2] on Look }
  eclIp: Word;
  { reserved }
  eclIpTail: array[0..3] of Byte;
  { The screen the game is in, one of C_Ifc's values, and the one it was in before: the units that open a screen set it,
    and the menus, input and drawing branch on it. SaveLoad saves and loads both with the game. After them
    isDemoRunning, which FixMain sets while it runs the demo. }
  { the screen the game is in, a C_Ifc value; EclMenu, Combat, PostCbt and others set it }
  interfaceState: Byte;
  { interfaceState as EclMenu, EclVm, CharGen or SaveLoad kept it before changing it; saved with the game; GameInit
    clears it }
  previousInterfaceState: Byte;
  { True while FixMain runs the demo, chosen at its title menu by D or the menu's timeout; GameIo's ReadGameKey then
    answers #0 at once when no key waits and no mouse or joystick is in use, and TextRend's ReadString takes one key;
    GameInit clears it at start-up }
  isDemoRunning: Boolean;

{ Session, continued: the display switches, run flags, rest bookkeeping, defeat and message pacing. }
var
  { The display switches: arePicturesEnabled and areAnimationsEnabled, which a saved game keeps; isBigPictureShown,
    while a big picture covers the party list; and showsMonsterPictures, which lets a monster's close-up show. }
  { saved with the game in zone0's displayOptions as twice its value plus areAnimationsEnabled, and loaded back as that
    byte div 2; GameInit sets it to 1 }
  arePicturesEnabled: Byte;
  { True while EclVm's big picture covers the party list, and CharHlp's DisplayRoster and MenuCore's DisplayParty then
    draw no party list; EclVm and GameInit clear it }
  isBigPictureShown: Boolean;
  { Explore's Anim toggle, saved with the game as bit 0 of zone0's displayOptions; GameInit sets it to 1; only the
    toggle and SaveLoad's save read it }
  areAnimationsEnabled: Byte;
  { lets EclMenu show a monster's close-up during an encounter menu. Note: nothing sets it, so the close-ups stay off }
  showsMonsterPictures: Boolean;
  { Two run flags: isDebugMode, GameIo's Ctrl-D log switch, and hasLoadedSave, which SaveLoad sets when a saved game
    loads. }
  { GameIo's Ctrl-D flips it, opening debug.txt as it sets it and closing the file as it clears it; while it is set
    Sym8x8 logs to the file, Debug's PrintDebug shows its values and message, CharHlp's PrintMiscInfo adds a *, GameIo's
    Ctrl-Z walks partyHead through its empty DumpWhoList and ExitGame closes the file. GameInit clears it at start-up
    and in ResetGameState, which leaves debug.txt open }
  isDebugMode: Boolean;
  { SaveLoad sets it when a saved game loads; EclVm's GameLoop redraws the view for it outside the wilderness and clears
    it, GameInit clears it too; while it is set EclMenu's EclInit leaves zone0's entryBytes and zone1's newGameBytes
    alone }
  hasLoadedSave: Byte;
  { The party's state between turns: rest bookkeeping, defeat, free training and message pacing. }
  { reserved; GameInit clears it at start-up and on a soft restart }
  restTicks: Word;
  { reserved }
  portHeadId: Byte;
  { reserved }
  portBodyId: Byte;
  { ends EclVm's GameLoop and its script runs. Each writer sets it, then clears it again when its own test finds a
    member: PostCbt's DetermineCombatResults one on C_Side.TEAM that is enabled and not out of play, and, outside a solo
    combat while no demo runs, one ahead of the first out of play that is fleeing, or okay on C_Side.TEAM with npc below
    NON_PLAYER_FLAG; CharGen's DropCharacterMenu, when a confirmation is refused or there is no current character, one
    on C_Side.TEAM that is enabled and not a companion; EclVm's EclDamage one that is enabled, on either side. MapView's
    DisplayMapView and Explore's MapMainMenu stop while it is set, and PostCbt's PostCombat shows the defeat; GameLoop
    clears it on the way out, and GameInit clears it }
  isPartyDefeated: Boolean;
  { True while CharGen trains a character level after level for free; GameInit clears it }
  isFreeTraining: Boolean;
  { while it is set, TextRend waits after each character of a message for the message speed; GameInit, EclVm, Combat and
    PostCbt set it and EclVm and CombatSt clear it }
  isMessageDelayed: Boolean;

{ Skill lists, and the video state: BIOS registers, EGA pages and video modes. }
var
  { The skills the skill screen lists, the career's eight then the rest by group; Skills. Note: Skills' EditSkills reads
    the byte before it as skillList[0] for a skill group with no entries }
  skillList: array[1..84] of Byte;
  { first skillList position of each skill group; Skills keeps the list of every general skill, which it shows to view
    them, in GroupConstitution's, which no skill is in }
  groupStart: array[Types.TSkillGroup] of Byte;
  { last skillList position of each skill group; Skills }
  groupEnd: array[Types.TSkillGroup] of Byte;
  { the registers of the video BIOS calls, Blit's, GameIo's, DaxIo's, GameBoot's and TextRend's, and of Mouse's INT 33h
    calls }
  regs: Types.TRegisters;
  { segment of the EGA page shown, set by TextRend's SetupEgaCurrentPage; otherwise unused }
  egaShownSegment: Word;
  { segment of the EGA page TextRend's FillRectEga fills, set by SetupEgaOtherPage }
  egaDrawSegment: Word;
  { the EGA page drawn on, which TextRend points egaDrawSegment back at; GameBoot sets it to 0 }
  egaDrawPage: Byte;
  { the EGA page shown; GameBoot sets it to 0 and nothing sets it non-zero }
  egaShownPage: Byte;
  { the BIOS video mode Blit's SetVideoMode replaced, which RestoreVideoMode and GameIo go back to; GameBoot starts it
    at the mode it finds }
  savedVideoMode: Byte;
  { the BIOS video mode Blit's SetVideoMode last set; GameBoot starts both at the mode it finds }
  curVideoMode: Byte;
  { the display adapter buck.cfg names; GameBoot sets it, the drawing units branch on it }
  displayMode: Types.TVideoMode;

{ Drawing: the view picture, the save-under buffer, the dirty-row tables and the scanline tables. }
var
  { the picture the game draws into, which Blit's FlushView copies to the screen row by row as dirtyRows marks them:
    GameInit allocates it screen-sized, 200 lines by 40 columns; CombatSt's CombatStart sets its size to the combat map
    view's, 168 lines by 21 columns, and Combat's CombatDoneCleanup sets it back to 200 by 40 }
  viewPicture: Types.PImgBuf;
  { where Blit's BlitTileClipped saves the pixels a masked tile covers; GameInit allocates it, CharHlp hands it to
    BlitTileClipped, and ShipCbt swaps in a picture of its own for each weapon effect }
  saveUnder: Types.PImgBuf;
  { unused }
  saveUnderTail: array[0..15] of Byte;
  { per row of viewPicture, non-zero once drawn: blit.asm's row loops set it, naming it as an external, and Blit's
    FillPicRect; Blit's FlushView copies the marked rows to the screen and clears it, and GameInit and MapCurs's
    DrawCursor clear it too. Note: neither writer bounds the row: a tile or rectangle on rows 168..199 of a 200-row
    picture writes past each of the four tables into the next one }
  dirtyRows: array[0..167] of Byte;
  { per row, the screen byte of the leftmost dirty cell: blit.asm's row loops store it with dirtyRowFirst, and
    FillPicRect; FlushView reads it; GameInit and DrawCursor clear it }
  dirtyRowLeft: array[0..167] of Word;
  { per row, the picture offset of the first dirty byte, $FFFF when none: blit.asm's row loops lower it, and
    FillPicRect; FlushView reads it and resets it, and so do GameInit and DrawCursor }
  dirtyRowFirst: array[0..167] of Word;
  { per row, the picture offset of the last dirty byte: blit.asm's row loops raise it, and FillPicRect; FlushView reads
    it and clears it, and so do GameInit and DrawCursor }
  dirtyRowLast: array[0..167] of Word;
  { spare. Note: blit.asm's row loops and FillPicRect write its first 64 bytes as dirtyRowLast[168..199] for a tile or
    rectangle on rows 168..199 of a 200-row picture }
  dirtyRowLastTail: array[0..671] of Byte;
  { screen segment of each CGA scanline; GameInit fills it, Blit reads it }
  cgaRowSegments: array[0..199] of Word;
  { offset of each EGA scanline; GameInit fills it, Blit reads it }
  egaRowOffsets: array[0..199] of Word;
  { screen segment of each Tandy scanline; GameInit fills it, Blit reads it }
  tandyRowSegments: array[0..199] of Word;
  { GameInit's InitializeGame and ResetGameState set it to 1; otherwise unused. Note: Blit's ShowPic, which does not
    bound its row, reads it and the byte after it as tandyRowSegments[200] }
  clipFlag: Byte;

{ Sound: the sound state and the music driver. }
var
  { the config file's sound letter as a soundState value: GameBoot sets it, GameIo's Ctrl-S sets C_Sound.OFF and puts
    savedSoundState back; SoundDrv reads it, and Music's StartMusic ignores requests while it is C_Sound.OFF }
  soundState: Byte;
  { soundState as SoundDrv's StartSound copies it on every resume, and GameIo's Ctrl-S when it turns sound off; Ctrl-S
    puts it back only when it is C_Sound.TANDY or C_Sound.SPEAKER }
  savedSoundState: Byte;
  { GameIo's Ctrl-U toggle, which stops the music driver when it turns it off; GameInit sets it on }
  isMusicOn: Boolean;
  { the block Music allocates for the MUSIC.dax driver; MusDrv frees it }
  driverCode: Pointer;
  { the paragraph boundary in driverCode the driver is copied to and run at }
  alignedDriverCode: Pointer;
  { a second pointer to the driver code at alignedDriverCode, which Music copies the code through }
  driverCopy: Pointer;
  { bytes of driver code loaded from MUSIC.dax; Music, MusDrv }
  driverCodeSize: Word;
  { MUSIC.dax's second record, the music data: a 'GLBR' timbre bank with an 'SLBR' song library at +$1BC, which the
    driver's function 0 reads; Music, MusDrv; GameInit sets it to nil }
  musicBank: Pointer;
  { bytes of musicBank; Music, MusDrv; GameInit clears it }
  musicBankSize: Word;
  { port $61 as MusDrv's StartDriver found it, restored when the driver stops }
  savedPort61: Byte;
  { soundMode DaxIo saves while it suspends sound for disk access; GameInit clears it }
  savedSoundMode: Byte;
  { the driver commands go to, a soundMode value: SoundDrv and MusDrv set and clear it, DaxIo's PushSoundState clears it
    for a disk access and PopSoundState puts it back, GameIo and Music test it to stop or start the right driver, and
    GameInit clears it }
  soundMode: Byte;
  { True while the loaded driver's code is allocated; Music, MusDrv; GameInit clears it. Note: Blit's ShowPic, which
    does not bound its row, reads it and the byte after it as tandyRowSegments[214] for a picture reaching row 214 }
  isDriverReady: Boolean;

{ Disk and game: the data set and save path, the ships, the orbit map, the party lists, item tables and the text
  window. }
var
  { the data files' set number, the digit in ECL<n> and the others; indexes diskPrompts; saved with the game; FixMain
    and GameInit set it, SaveLoad's LoadGame takes it back from zone1's savedDataSet, and Intro, OrbitMap and DaxIo's
    PushState switch it for a while }
  dataSet: Byte;
  { dataSet before DaxIo's PushState replaced it, for PopState; GameInit starts it at 1 }
  previousDataSet: Byte;
  { where saved games and characters go, buck.cfg's fourth line; GameBoot, SaveLoad }
  savePath: String;
  { non-zero: DaxIo's OpenDax gives up on a missing file instead of asking for the disk, or on a hard disk aborting with
    'Check install'; SaveLoad sets it while it loads a character's optional SPC and ITM records; GameInit clears it }
  isDiskPromptSuppressed: Byte;
  { SaveLoad sets it once a game is saved, CharGen and GameInit clear it; CharGen and HeapErr test it before quitting }
  isGameSaved: Boolean;
  { Ships: ship picture buffers, ships and pilot, text window rows, ship-combat range and boosts }
  { the 'ships' pictures, one per shipPictures entry; OrbitMap loads them for ship combat and the ship screen, ShipCbt
    and CharHlp draw them; GameInit clears them }
  shipPictureBuffers: array[0..28] of Types.PImgBuf;
  { the team's ship, zone0's partyShip: GameInit's InitShipAndOrbit points it there and loads the ship through it;
    ShipCbt, CharHlp, PostCbt and Explore reach the ship through it }
  partyShip: Types.PShip;
  { the enemy ship's record during ship combat, nil outside it; ShipCbt allocates, loads and frees it, GameInit sets it
    to nil }
  enemyShip: Types.PShip;
  { the character flying the team's ship in ship combat; ShipCbt tests its Pilot Rocket skill }
  activePilot: Types.PCharacter;
  { column TextRend's DisplayWindowText starts each line at; TextRend's ClearTextWindow and Explore's CampSpeedMenu
    reset it to windowLeft }
  textLeft: Byte;
  { the row of the text window's next line: TextRend's ClearTextWindow, and Explore's CampSpeedMenu, reset it to
    windowTop, and DisplayWindowText prints at it and counts it up; PostCbt prints its columns on the row
    DisplayWindowText left, and ShipCbt's BuildPlayerMenu adds blank lines until it reaches 21 }
  windowTextRow: Byte;
  { non-zero once the text window holds a line the player has not been paused on: TextRend's DisplayWindowText sets it
    as it prints a line. While it is 0 and windowTextRow is past windowTop, the next line clears the window first; while
    it is set, a full window waits on PauseContinue before it is cleared. ClearTextWindow clears it; ShipCbt's
    FireWeapon and BuildPlayerMenu pause on it the same way, and BuildPlayerMenu and CharHlp's DisplayNoncombatInterface
    clear it }
  windowTextPending: Byte;
  { distance between the two ships in ship combat, 8 at the start; ShipCbt, shown by CharHlp }
  shipCombatRange: ShortInt;
  { True while the enemy ship retreats; ShipCbt sets it, CharHlp shows its maneuverNames[Byte(it)] }
  isEnemyRetreating: Boolean;
  { CharHlp sets it from its mode flag and the team ship's sensors; while it is 0 the enemy ship's values show as ? }
  enemyDetailsShown: Byte;
  { speed boosts the team's ship has taken this ship combat, offered while below 2; ShipCbt, added to its speed by
    CharHlp }
  playerBoosts: ShortInt;
  { speed boosts the enemy ship has taken this ship combat; ShipCbt, added to its speed by CharHlp }
  enemyBoosts: Byte;
  { Orbit: orbit pictures, orbit view, saved cell and cursor }
  { True while OrbitMap's orbit-map tiles, cursor cell and backdrop are loaded; GameInit clears it }
  areOrbitPicturesLoaded: Boolean;
  { True while OrbitMap has shipPictureBuffers loaded; GameInit clears it }
  areShipPictureBuffersLoaded: Boolean;
  { the orbit state in zone 0: GameInit's InitShipAndOrbit points it there and sets the rocket's start through it;
    OrbitMap draws the orbit map from it, and Explore's MoveRocket moves the rocket and the bodies' phase through it }
  orbitView: Types.POrbitView;
  { the orbit-map cell under the cursor, grabbed so OrbitMap can put it back when the cursor moves }
  savedOrbitCell: Types.PImgBuf;
  { orbit-map column of the cell in savedOrbitCell, -1 when none is saved; Explore sets it too }
  savedCursorX: ShortInt;
  { orbit-map row of the cell in savedOrbitCell; Explore sets it too }
  savedCursorY: ShortInt;
  { Party: saved ECL character, item types, party pointers, item templates, ship-combat experience, last missile and
    century flag }
  { the current character EclVm's ECL commands keep and put back: GameLoop, NewEclDone and EclDump store
    currentCharacter here, EclExit, EclProgram and NewEclDone restore it, and EclLoadCharacter compares it }
  eclSavedCharacter: Types.PCharacter;
  { the ITEMS rows, by an item's itemType: GameInit's InitializeGame reads the ITEMS file into it at start-up, asking
    for all 129 rows; the ITEMS file holds 39 }
  itemTypes: array[0..128] of Types.TItemType;
  { the character whose party-list row CharHlp's DisplayRoster redraws, which takes its argument when this is nil and
    clears it after; MenuCore's party click stores the current character here before it moves to another, and GameInit
    clears it }
  partyRowCharacter: Types.PCharacter;
  { the character the menus and commands act on: SaveLoad's AddCharToParty and LoadGame, CharGen, MenuCore's party
    click, ViewChar's pickers and trade, EclVm's ECL commands (and ViewChar's SelectChar for EclVm's EclWho), ShipCbt's
    ship menu, Combat's CreatureAction and CbtActs's attacks set it. CombatSt and PostCbt point it at each creature they
    drop through CharGen's RemoveCreature, which unlinks and frees it and moves to the member before it, or after it
    when it was first; PostCbt's PostCombatCreatureCleanup then sets the first member }
  currentCharacter: Types.PCharacter;
  { the first of the party list, the team and the creatures that join it: SaveLoad's AddCharToParty starts the list,
    CharGen's RemoveCreature moves it past a removed first member, Explore's order menu reorders it }
  partyHead: Types.PCharacter;
  { the templates a new item copies: EclMenu's LoadItemTemplates, which GameInit calls at start-up, marks every slot
    empty and loads ITEM0.DAX's 16-byte records into the slots from 1, at most 127 and stopping at the end of the data;
    EclVm's treasure and shop item lists, Shop's BuildAmmoItems for CharGen's new characters, and ViewChar's weapon
    specialization menu read it }
  itemTemplates: array[1..254] of Types.TItemTemplate;
  { experience for a ship combat, by the enemy ship's type: ShipCbt's ShipCombat sets it as the combat starts and clears
    it when the enemy recedes off the scanners, and saves the enemy ship in zone0 only while it is non-zero; PostCbt's
    RepairShip shares it out among the enabled members and clears it }
  shipCombatExperience: Word;
  { unused; CombatSt's CombatStart sets it to nil }
  lastMissileItem: Types.PItem;
  { GameTime's ValidateClock sets it when the clock's year count reaches 100 and carries; GameInit clears it, and
    nothing tests it }
  hasCenturyPassed: Boolean;
  { Scratch file: deletion file and items read }
  { the file variable DaxIo's DeleteIfPresent erases a file through }
  deletionFile: file;
  { the bytes of ITEMS GameInit's InitializeGame read into itemTypes }
  itemsRead: Word;
  { Text cursor: font, glyph bits, text cursor and window }
  { the 8x8 font; GameInit allocates it, TextRend loads and draws it; textrend.asm also reads it }
  gameFont: Types.PFont;
  { Rows of the character being drawn, from TextRend; textrend.asm also reads them. }
  glyphBits: Types.TGlyph;
  { column the next character of TextRend's wrapped text goes to; EclMenu, EclVm and PostCbt also set it }
  cursorColumn: Byte;
  { row the next character of TextRend's wrapped text goes to; CharHlp, EclMenu, EclVm and PostCbt also set it, and the
    combat messages start below it }
  cursorRow: Byte;
  { the text window's left column; TextRend's SetTextWindow sets the window, and Border's ScreenText and DrawCombatFrame
    and OrbitMap's EnterOrbitMap set its four edges themselves }
  windowLeft: Byte;
  { the text window's top row }
  windowTop: Byte;
  { the text window's right column }
  windowRight: Byte;
  { the text window's bottom row }
  windowBottom: Byte;
  { the color the text window is cleared to }
  windowColor: Byte;
  { unused }
  windowColorTail: array[0..20] of Byte;
  { Tile sets: tile sets and wilderness cells }
  { the 8x8 tile sets Sym8x8 loads, slot 6 the borders; tileSetFirst and tileSetLast give each slot's tile numbers.
    GameInit clears them, and OrbitMap's FreeOrbitPictures frees slot 5 }
  tileSets: array[0..6] of Types.PImgBuf;
  { a one-tile 8x8 picture GameInit allocates; Sym8x8's Put8x8Sym copies a tile into it to show it }
  tileScratch: Types.PImgBuf;
  { the 8x8 cell MapCurs's DrawCursor grabs before shading it, which RestoreCursorBackground puts back; GameInit
    allocates it }
  savedWildernessCell: Types.PImgBuf;
  { the copy of savedWildernessCell that DrawCursor shades through cursorPicture's mask and shows; GameInit allocates
    it }
  wildernessCursorCell: Types.PImgBuf;
  { Combat: arena, icons, combatants, grid, creatures, downed creatures and path targets }
  { the combat arena's 59 terrain tiles, 24 by 24: CombatSt allocates it, MapTiles' Load24x24Set fills it, CbtMap draws
    the arena from it, Combat frees it; GameInit sets it to nil }
  arenaTiles: Types.PImgBuf;
  { icon and effect pictures, two frames a row. GameInit clears the table and loads the COMSPR icons into rows 13..37,
    MapTiles' LoadIconAnim loads a row and DrawIconAnimSprite draws it, and CharGen's icon screen allocates a
    character's row. CbtMap draws the skull in row 31 over a downed creature and its arena cell markers in rows 33..35.
    Blit's CopyIconTile copies a frame of whichever row CbtActs names, or CharHlp and EffHndlr through BuildIconFrames,
    into movingIcon }
  iconFrames: array[0..37, 0..1] of Types.PImgBuf;
  { combatant slots in use in ground combat; CombatSt counts them as it places the combatants }
  combatantCount: Byte;
  { where each combatant stands and its icon size, by slot: CombatSt places them, CbtMap and CbtActs move them, CbtMap
    and FxEngine take one out of play }
  combatantCells: array[1..C_Combat.MAX_COMBATANTS] of Types.TCombatantCell;
  { each combatant's column on the combat map view, its arena column less the view's origin: CbtMap works it out and
    draws by it, CharHlp reads it }
  gridX: array[1..C_Combat.MAX_COMBATANTS] of ShortInt;
  { each combatant's row on the combat map view; the same writer and readers }
  gridY: array[1..C_Combat.MAX_COMBATANTS] of ShortInt;
  { the combatant slot on each arena cell, [row, column], 0 for none; CbtMap clears it whole and rebuilds it from
    combatantCells }
  cellCombatant: array[0..24, 0..49] of Byte;
  { each combatant's character record, by slot; CombatSt fills it }
  creatures: array[1..C_Combat.MAX_COMBATANTS] of Types.PCharacter;
  { corpse records, downedCount of them, one appended each time a combatant in play is down: CombatSt's
    PlaceAllCreatures appends those already down as it places them and CbtMap's CreatureDowned those that fall, both
    marking the cell as a corpse. CbtMap's terrain lookups see through a corpse to its terrain and IsValidCreatureLoc
    zeroes the record of a creature that moves, CbtActs's ManualAimCursor picks the creature on a corpse cell, and
    FxEngine's CountDownAreaEffects puts a corpse back as a cloud clears; CombatSt's CombatStart clears it. Note: the
    scans in CbtMap, CbtActs and FxEngine run from 1 to downedCount with no bound at 8, so a count above 8 has them read
    past the table }
  downedCreatures: array[1..8] of Types.TDownedCreature;
  { the records appended to downedCreatures since CombatSt's CombatStart cleared it: PlaceAllCreatures and CbtMap's
    CreatureDowned count each append in, and IsValidCreatureLoc zeroes a record in place. Note: CreatureDowned's test
    for a creature already recorded indexes by a local it has not set, so the appends need not be distinct creatures,
    and neither appender tests the count against 8: a ninth append writes past the table, over this count and
    combatArena }
  downedCount: Byte;
  { the ground combat arena: its view origin and its 25 by 50 terrain cells, which CombatSt lays; Combat frees it }
  combatArena: Types.PArena;
  { entries in pathTargets; Pathing's BuildTargetList sets it, CharHlp's CountTargets cuts it }
  pathTargetCount: Byte;
  { the combatants Pathing's BuildTargetList finds, nearest first; CharHlp's CountTargets keeps only one side's. Note:
    BuildTargetList does not bound pathTargets at MAX_COMBATANTS, and neither does CombatSt's PlaceAllCreatures bound
    combatantCount, so a 73rd target writes past the table }
  pathTargets: array[1..C_Combat.MAX_COMBATANTS] of Types.TTarget;

{ Treasure and combat rules: the pool, the team counts and the effect and attack state of the hit being resolved. }
var
  { the credits in the team's pool. Money's PoolMoney moves members' credits in, and ShareMoney, TakeMoneyMenu and
    TakeMoney pay them out. PostCbt's DetermineLootExp adds the fallen hostiles' credits and its loot menu offers them;
    EclVm's EclTreasure (ECL $27) adds to it and EclClearMonsters (ECL $1C) clears it. Shop clears it on entry and
    spends it when a character's own credits fall short, and PostCbt's ClearTreasure clears it }
  poolCredits: LongInt;
  { the pooled item list the current ECL event offers, treasure or shop stock. EclVm's EclTreasure (ECL $27) and
    PostCbt's DetermineLootExp push treasure onto it and PostCbt's loot menus take items off it. EclVm's EclShop (ECL
    $4B) frees it and builds a shop's stock on it, which Shop sells copies of. EclClearMonsters (ECL $1C) and PostCbt's
    ClearTreasure free it, GameInit sets it to nil, and Money's DetermineTreasure reports whether it holds a list }
  availableItems: Types.PItem;
  { combatants in play on each side; CharHlp's CountTeams counts them, and its InflictDamage takes one off a side when a
    combatant falls in ground combat }
  teamCounts: array[C_Side.TEAM..C_Side.HOSTILE] of Byte;
  { Effects: the rolls, damage, projectile and effect handlers }
  { the saving-throw roll in progress: FxEngine's RollSavingThrow rolls it and adds the modifier, runs trigger condition
    12, whose C_Effect.BLIND handler, EffHndlr's EffBlind, takes 4 off it, and then tests it against the character's
    save }
  saveRoll: Byte;
  { the effect FxEngine's AddEffectWithMessage is about to add: it stores the effect's number, runs trigger condition 9,
    and adds nothing when a handler has set it to 0. EffHndlr's handlers test it for the effect they block and clear it
    through ClearEffectMode, and EffUnkillable clears it }
  pendingEffectId: Byte;
  { damage of the hit being resolved: CbtActs's CalcWeaponDamage rolls it and RollAttacks clears it, FxEngine's
    InflictNonWeaponDamage and ShipCbt set it, and EffHndlr sets, caps and clears it }
  effectDamage: Byte;
  { the animation the damage message of a missile or grenade plays: CbtActs's CombatLaunchProjectile sets it by
    projectile kind, 15 unless the kind picks 23, 17 or 16, and FxEngine's InflictNonWeaponDamage hands it to CharHlp's
    PrintNameStringAnim; CbtActs's CalcWeaponDamage clears it }
  projectileEffect: Byte;
  { attacks per round, doubled, as CbtActs sets up an attack slot: BeginRound takes the character's scale and
    RecalcAttacksLeft the readied weapon's attacksDoubled or baseScale. Each runs trigger condition 18, whose
    C_Effect.DIZZY handler, EffHndlr's EffDizzy, halves it, and then halves it into the slot's attacks }
  attackRate: Byte;
  { a character's moves per turn, doubled: CharHlp's RecalcMovement works it out from currentMovement and the team's
    movementBonus and returns it. Note: EffHndlr's EffDizzy, C_Effect.DIZZY's handler, halves it with attackRate, but
    RecalcMovement sets it before it reads it and calls nothing between, so the halving never reaches the movement
    RecalcMovement returns }
  movementRate: Byte;
  { the dice count FxEngine's RollDamageDice was last called with; unused }
  currentDiceCount: Byte;
  { unused }
  currentDiceCountTail: array[0..1] of Byte;
  { CbtActs's MakeAttack clears it and tests it once CombatLaunchProjectile, which sets it, may have fired }
  isProjectileActive: Boolean;
  { makes ViewChar's gear screen redraw its heading, and ViewChar then clears it; nothing sets it }
  needsGearRefresh: Boolean;
  { the d20 roll of the attack being made, 100 for a natural 20: FxEngine's AttackRoll and AttackRollNoAttacker roll it,
    test it for at least 0 and add it to the to-hit total. In AttackRoll, trigger condition 10's C_Effect.BLIND handler,
    EffHndlr's EffBlind, takes 4 off it first. EffHndlr's ClearEffectMode and CombatSt's CombatStart clear it }
  currentAttackRoll: ShortInt;
  { arena column a shot or thrown weapon is aimed at: CbtActs's AttackGroundTarget sets it, and CombatLaunchProjectile
    moves it where the shot goes astray or hits chaff }
  projectileTargetX: ShortInt;
  { arena row of the same aim; CbtActs }
  projectileTargetY: ShortInt;
  { the hits for damage of the attacks being made, per attack slot: CbtActs's RollAttacks clears both and counts each
    hit for damage in its slot, a Sonic Stunner's stun excepted, and EffHndlr's EffDodgeSlugHits,
    C_Effect.DODGE_SLUG_HITS's handler under trigger condition 5, takes one off slot 1 when the defender dodges }
  hitCounts: array[1..2] of Byte;
  { a monster's morale as CombatAi's CheckMorale works it out from its npc byte and tests it }
  morale: Byte;
  { the creature an effect acts on: EffHndlr's EffDizzyingPoison, EffLethalPoison, EffStrikeAdjacent and EffSpitAcid set
    it to the combat target of the character the effect is on, and CbtActs's IntimidateTarget passes each target through
    it }
  activeTarget: Types.PCharacter;
  { the saving throw FxEngine's RollSavingThrow is making, set before its effects run; unused }
  currentSaveType: Byte;
  { the result of FxEngine's RollSavingThrow, which it also returns }
  isSaveMade: Boolean;
  { the handler for each effect number: EffHndlr's InitEffectHandlers fills it, and FxEngine's CallEffectHandler calls
    through it by the effect's number. Note: nothing bounds that number at 32 (effect records also load from saved and
    monster data), so a number past 32 calls through whatever follows the table }
  effectHandlers: array[1..32] of Types.TEffectHandler;

{ The 3-D view and the map: wall definitions, the geo map, view colors, the party's position and wall sets; then the
  portrait animation and big picture, and the menus' state. }
var
  { the loaded WALLDEF banks: GameInit allocates $924 bytes, three banks. View3D's LoadWallSet copies a set loaded into
    slot n into banks n + 1 onward, and DrawWallSlice reads its slices, wall types 1..15, from banks 1..3. EclVm's
    EclLoadFiles loads a script's sets into slots 1..3 while its first set is not 127 and zone 0's mapGraphics1 and
    mapGraphics2 are not both set. Note: LoadWallSet's guard admits a set whose banks and slot sum to 4, whose last bank
    lies past the allocation. Each WALLDEF record is three banks: one loaded into slot 1 writes bank 4, and one loaded
    into slot 2 or 3 stops the game }
  wallDefs: Types.PWallDefs;
  { the 3-D map's four planes: GameInit allocates them, View3D's Load3DMap fills them from GEO<n>.DAX and its wall,
    barrier and event lookups read them }
  geoMap: Types.PGeoMap;
  { Map state: view colors, automap, party position and wall sets }
  { color of the 3-D view's sky band: MapView sets it from its skyColors by bit $80 of the square's event byte, and
    View3D's SetView3DColors; LoadBackdrop also passes it to LoadPic }
  skyColor: Byte;
  { first horizon color: MapView sets it in CGA mode from horizonColorCode, and View3D's SetView3DColors }
  horizonColor1: Byte;
  { color of the horizon band DrawBackdrop fills below the sky: MapView sets it in CGA mode from horizonColorCode, and
    View3D's SetView3DColors }
  horizonColor2: Byte;
  { color of the 3-D view's floor band: MapView sets it in CGA mode from floorColorCode, or to 8 when color is off, and
    View3D's SetView3DColors }
  floorColor: Byte;
  { while it is set, View3D draws the automap in place of the 3-D view; Explore's Area command toggles it, and EclMenu,
    MapView and GameInit clear it }
  isAutomapOn: Boolean;
  { where the party stands on the 3-D map and what it faces; TPartyPosition's fields say who writes and reads each }
  partyPosition: Types.TPartyPosition;
  { the WALLDEF set in each wall-set cache slot, as View3D's LoadWallSet records it. EclVm empties slots, SaveLoad saves
    and loads slot 0 with the game, GameInit clears all four at start-up and on a soft restart gives slot 1 set 0 and
    empties 2 and 3, and FixMain clears slot 0's set before the demo }
  wallSets: array[0..3] of Types.TWallSet;
  { Portrait: portrait and animation state, big picture }
  { True while the animation Portrait's LoadAnimation has loaded comes from a sprite archive, one whose name starts with
    S. While it is set, LoadAnimation decodes every frame into imageFrames, even in VGA mode, swaps colors 0 and $0D and
    loads DAC range $B0..$FF; DisplayImageBuf and FreeAnimation then take the frames from imageFrames, and MenuCore's
    MenuHorizontal does not animate the portrait }
  isSpriteArchive: Boolean;
  { the animation Portrait's LoadAnimation has loaded, which MenuCore's menu loop plays; LoadAnimation and GameInit
    clear it whole }
  portraitAnimation: Types.TPortraitAnimation;
  { the animation Portrait's loader has loaded, in VGA mode: FreeAnimation frees it and clears it; GameInit clears it.
    Note: FreeAnimation's clear runs on into imageFrames }
  vgaAnimation: Types.TVgaAnimation;
  { the animation's frames as pictures outside VGA mode, or from a sprite archive: Portrait's loader builds them,
    DisplayImageBuf and Show3DSprite draw them, FreeAnimation frees and clears them; GameInit clears them }
  imageFrames: array[0..8] of Types.PImgBuf;
  { the count EclVm steps as it shows the animation's current frame; GameInit clears it }
  displayCounter: Types.TDisplayCounter;
  { two picture slots GameInit empties and CombatSt's CombatStart and Explore's 3-D step free and reset }
  portraitSlots: array[1..2] of Types.TPortraitSlot;
  { the archive of the animation Portrait has loaded, which its loader compares with the next one asked for;
    FreeAnimation empties it, and GameInit clears it }
  cachedName: String[8];
  { cachedName as the camp keeps it across its menu; EclVm's NewEclDone and GameInit clear it; unused otherwise }
  savedPicArcName: String[8];
  { the record of the animation Portrait has loaded, NO_ANIMATION for none: its loader sets it, FreeAnimation and
    GameInit set it to NO_ANIMATION }
  cachedAnimationId: Byte;
  { cachedAnimationId as the camp keeps it with savedPicArcName; EclVm's NewEclDone and GameInit set it to NO_ANIMATION;
    unused otherwise }
  savedPicArcId: Byte;
  { the big picture: Portrait's LoadBigPic loads 'bigpic' into it and shows it, OrbitMap loads the orbit map's backdrop
    and SaveLoad a ship picture into it, and CharHlp draws it behind the ship scene. Portrait, OrbitMap, CombatSt and
    ShipCbt free it, GameInit sets it to nil }
  bigPicture: Types.PImgBuf;
  { the BIGPIC record Portrait's LoadBigPic last loaded into bigPicture, NO_BIG_PICTURE for none: LoadBigPic sets it and
    skips the load while it matches and bigPicture is not nil. OrbitMap's EnterOrbitMap and SaveLoad's LoadShipData for
    the enemy ship, which load pictures of their own into bigPicture, and SaveLoad's LoadGame before it loads a big
    picture set it to NO_BIG_PICTURE, as GameInit does. EclVm's EclCombat sets NO_BIG_PICTURE after a combat, first
    keeping it in C_Ifc.WILDERNESS to load that picture again }
  bigPictureId: Byte;
  { EclVm's EclSetPictureMode sets it in its mode 4 and clears it otherwise; MapCurs shades and restores the cursor cell
    only while it is set }
  isViewActive: Boolean;
  { Menu: selector, menu, panel, colors and editor flags }
  { True while ViewChar's SelectChar picks a character other than the current one, which it sets from its
    usesSelectorMode argument and then clears: MenuCore's party click then moves selectorAnchor, not the current
    character; GameInit clears it }
  isSelectorMode: Boolean;
  { the character a party click picks while isSelectorMode is set: ViewChar's SelectChar starts it at the current
    character and moves its cursor to it, MenuCore's party click sets it }
  selectorAnchor: Types.PCharacter;
  { the first list line on the page of MenuCore's MenuVertical, which pages and scrolls it; GameInit sets it to 1 }
  menuTop: Integer;
  { the option MenuCore's MenuHorizontal highlights, from 1. MenuHorizontal starts on it, sets it back to 1 when it is 0
    or past the menu's last option, or when the menu's text sums differently from menuChecksum unless that is
    C_Menu.KEEP_MENU_CHOICE, and moves it with keys and clicks; YesNoMenu sets the default answer in it. Callers set the
    option their next menu starts on. Shop's Sell sets C_Menu.SELL_CHOICE, which ViewChar's UseItemMenu replaces with
    the position after its Join: Sell while the gear menu offers it, else the option MenuVertical adds next, Next, Prev
    or Exit }
  horizontalChoice: Byte;
  { True when the key MenuCore's MenuHorizontal leaves in menuKey is an extended scan code, which it sets for a key or
    for a click it turns into one; the menus' callers test it. CharGen's ModifyCharacterMenu sets it for its own key
    reads, Skills' EditSkills clears it for a clicked line, and Shop and PostCbt hand it to ViewChar's ViewCharMenu as
    the hasEndedTurn flag that it clears and tests }
  isExtendedKey: Boolean;
  { ticks after which MenuCore's MenuHorizontal answers menuTimeoutKey by itself, 0 for never: FixMain sets 12000 or
    3000 for its title menu and clears it after }
  menuTimeout: LongInt;
  { the key MenuHorizontal answers when menuTimeout runs out: FixMain sets 'D', for the demo, and clears it after }
  menuTimeoutKey: Char;
  { the screen row of each selectable line on the page of MenuCore's MenuVertical, 255 for none: its page drawing fills
    them, and MenuHorizontal's click on the list reads them }
  menuHotRows: array[1..25] of Byte;
  { the first column a click on MenuVertical's list selects in, 127 with no list: MenuCore's MenuVertical sets it,
    MenuHorizontal's click on the list reads it }
  menuClickLeft: ShortInt;
  { the last such column, -128 with no list; the same writer and reader }
  menuClickRight: ShortInt;
  { the first column of the party list, where a click in MenuHorizontal picks a character: MenuCore's DisplayParty and
    CharHlp's DisplayRoster set the list's four edges, MenuCore's party click reads them }
  panelLeft: Byte;
  { the party list's last column, 38; the same writers and reader }
  panelRight: Byte;
  { the party list's first row, 4; the same writers and reader }
  panelTop: Byte;
  { the party list's last row, counted up from 3 as the writers list each character }
  panelBottom: Byte;
  { the character-sheet field a click on CharGen's modify screen picks: MenuCore's MenuHorizontal sets it while
    isModifyActive is set, CharGen's ModifyCharacterMenu sets it to NO_MODIFY_FIELD before each menu and then moves to
    the field }
  modifyFieldSelection: Byte;
  { the line a click picks on Skills' skill screen, C_Ifc.EDITING_SKILLS: MenuCore's MenuHorizontal sets it from the
    click's row, or NO_SKILL_LINE for a click elsewhere, and Skills' EditSkills selects that skill and sets it to
    NO_SKILL_LINE }
  clickedSkillLine: ShortInt;
  { the color of a menu's query: MenuCore's menus draw with it and set it back to $0D after, and YesNoMenu keeps it
    across its loop; CharGen, CbtActs and Explore set $0E before a menu, GameInit sets $0D }
  promptColor: Byte;
  { the color of a menu's options: MenuCore's menus draw with it and set it back to $0A after, and YesNoMenu keeps it
    across its loop; GameInit sets $0A }
  menuColor: Byte;
  { the color of a menu's current option: MenuCore's menus draw with it and set it back to $0F after, and YesNoMenu
    keeps it across its loop; GameInit sets $0F }
  highlightColor: Byte;
  { the sum, in a byte, of the character codes of the menu text MenuCore's MenuHorizontal last showed, spaces and '@'
    included. MenuHorizontal stores it on every call and, when the new menu's text sums differently, sets
    horizontalChoice back to 1, unless menuChecksum is C_Menu.KEEP_MENU_CHOICE. YesNoMenu sets it before each of its
    menus, and callers that preset horizontalChoice set it too, so the preset survives the next menu }
  menuChecksum: Byte;
  { the key MenuCore's menus, MenuHorizontal and YesNoMenu, answer; their callers read it after the call. Explore and
    ViewChar set it before their menu loops, Skills and ViewChar rewrite it, and CharGen stores YesNoMenu's answer in
    it }
  menuKey: Char;
  { True while Explore's PartyOrderMenu runs, which then clears it; unused otherwise }
  isInPartyOrderMenu: Boolean;
  { True while MenuCore's MenuVertical runs MenuHorizontal for its list, which then tries a click against the list, and
    at the main menu takes a click on the current character in the party list as a choice; GameInit clears it }
  isVerticalMenuActive: Boolean;
  { True once a click picks the current character from the party list at CharGen's main menu: MenuCore's MenuHorizontal
    sets it, in C_Ifc.MAIN_MENU while MenuVertical runs, for a click on the row of the character already current, and
    answers with the highlighted option. CharGen's MainMenu clears it before its menu and, while it is set, turns
    Create, Add, Load, Save, Begin and Exit into View; MainMenu's Icon, View and Remove and CharGen's modify, drop and
    training menus then act on the current character without ViewChar's PickCharacter }
  isPartyClicked: Boolean;
  { unused }
  gTargetX: ShortInt;
  { unused }
  gTargetY: ShortInt;
  { the first of the lingering clouds on the arena: CbtActs's CombatLaunchProjectile puts each new cloud first,
    FxEngine's CountDownAreaEffects counts them down and unlinks and frees those that clear, and LayAreaEffectMarkers
    lays their markers again; CbtMap's DrawTerrainCell, ResolveTerrain and SetTerrain see through them to the terrain
    beneath; Combat's CombatDoneCleanup frees the rest, and GameInit's orbit set-up sets it to nil }
  areaEffects: Types.PAreaEffect;
  { unused }
  usingItem: Boolean;
  { True while credits sit in the team's pool; Money sets and clears it, Shop clears it; unused otherwise }
  isPoolActive: Boolean;
  { reserved }
  isPoolActiveTail: array[0..24] of Byte;
  { moves the message CharHlp's PrintCreatureMessage writes one row down, outside C_Ifc.IN_COMBAT and C_Ifc.SHIP, ground
    and ship combat; GameInit clears it, and nothing sets it }
  isCombatLineLowered: Boolean;

{ The big picture's redraw request. }
var
  { asks MapView's DisplayMapView to show the big picture again in the $A2 and $A8 areas, and DisplayMapView clears it:
    Explore's 3-D step, EclVm, EclMenu and CharHlp set it, and EclVm clears it too }
  isPortraitPending: Boolean;

{ A start-up flag nothing reads. }
var
  { GameInit clears it; unused otherwise }
  overrideFlag: Byte;

{ Character editing: the icon editor, free training and the modify screen; and the door-opening flags. }
var
  { True while CharGen's CustomizeIcon runs, which sets it and clears it as it ends: MenuCore's MenuHorizontal then
    takes a left click above the menu lines as a pick on the icon grid, answering '!' for one on the grid and ignoring
    the rest; GameInit's InitShipAndOrbit clears it }
  isIconEditorActive: Boolean;
  { ends CharGen's free-training loop, once the next level needs more experience }
  isTrainingComplete: Boolean;
  { CharGen's main menu, character creation and training clear it, and training tests it for 0; nothing sets it
    non-zero }
  trainingMode: Byte;
  { True while CharGen's ModifyCharacterMenu runs, which sets it and clears it on each way out: MenuCore's
    MenuHorizontal then takes a click on the character sheet, of either button, as a pick of the field under it, which
    it stores in modifyFieldSelection; GameInit clears it }
  isModifyActive: Boolean;
  { the door-opening flags (bash, pick, knock); GameInit and Explore's 3-D step set all three to 1, and nothing else
    uses them }
  doorOpen: array[0..2] of Byte;

{ Ground combat's round: the round count, targets and attacks, the hostiles' strength and the moving icon. }
var
  { unused }
  attackedAllies: Byte;
  { the ground combat's round, from 0: CombatSt's CombatStart clears it and Combat's EndOfRound counts it up. Combat's
    CombatMain ends the combat once it reaches combatEndRound. CbtActs's BeginRound and RecalcAttacksLeft add its low
    bit to attackRate before they halve it, so an odd rate rounds up on odd rounds }
  combatRound: Byte;
  { the round at which the ground combat ends if nobody attacks: CombatSt's CombatStart sets C_Combat.IDLE_ROUNDS and
    CbtActs's MakeAttack sets combatRound + C_Combat.IDLE_ROUNDS at each attack. Combat's CombatMain ends the combat
    once combatRound reaches it }
  combatEndRound: Byte;
  { the slots of the targets CharHlp's CountTargets keeps, in pathTargets' order: CbtActs and CombatAi pick a target
    from them by index 1..count, and CombatAi clears the ones it rules out }
  targetOrder: array[1..C_Combat.MAX_COMBATANTS] of Byte;
  { attacks made in the current action with each of a combatant's two attack slots: CbtActs's RollAttacks clears and
    counts them, and MakeAttack takes slot 1's count off the weapon's quantity }
  attackCounts: array[1..2] of Byte;
  { the hostiles' hit points left, as a percentage in steps of 5. CbtActs's UpdateHostileHpPercent, which CombatSt's
    CombatStart and Combat's EndOfRound call, sums the enabled hostiles' hit points and all the hostiles' maximum hit
    points in Words and stores ((20 * hitPoints) div maximum) * 5; it leaves it as it was when the maximum sum is 0.
    Note: past 3276 hit points, 20 * hitPoints overflows 16 bits (4000 of 4000 gives 15). CombatAi's CheckMorale, once a
    companion's own morale fails against its wounds, tests it in that morale's place; AiMoveStep lets a team-side
    creature whose npc byte is NON_PLAYER_FLAG or above step only while it is at most morale plus a d100 roll }
  hostileHpPercent: Byte;
  { unused }
  quickMagic: Boolean;
  { a four-frame picture, 24 by 24 pixels, for combat's moving icons and shots: CombatSt allocates it, Blit's
    CopyIconTile copies icon frames into it, CharHlp and CbtActs draw it, Combat frees it }
  movingIcon: Types.PImgBuf;

{ Ground combat's cursor, tactics and turn order; then the ECL machine: its registers, stack, comparisons, operands and
  strings, and its post-combat state. }
var
  { the arena column of the combat cursor: CbtActs's ManualAimCursor starts and moves it, MenuCore moves it to a clicked
    cell; CbtActs's CombatUseJetpack flies to it }
  combatCursorX: ShortInt;
  { the arena row of the combat cursor; the same writers }
  combatCursorY: ShortInt;
  { True while CbtActs's ManualAimCursor runs the combat cursor, and MenuCore then takes a click in the arena as a
    cursor move; CombatSt and GameInit clear it }
  isCursorActive: Boolean;
  { per side, 1 once one of its characters has made the Battle Tactics roll this combat: CbtActs's RollTactics clears
    and sets them, CharHlp's RecalcStats adds 1 to that side's accuracy. Combat clears C_Side.TEAM's when combat ends,
    GameInit clears both }
  tacticsSides: array[C_Side.TEAM..C_Side.HOSTILE] of Byte;
  { how the attack being resolved is made, an Attack value, which picks its combat line: CbtActs's RollAttacks sets
    C_Attack.PLAIN, ATTACK_FROM_BEHIND or ATTACK_BACKSTAB; EffHndlr sets C_Attack.PLAIN before its own attacks }
  attackManner: Byte;
  { the sides the hostiles of the next ground combat come from, bit n for direction 2n: north, east, south, west.
    EclVm's EclSetupMonster (ECL $0C) stores its fourth operand here. CombatSt's PlaceAllCreatures counts the sides it
    sets to size the hostiles' placement rings, then places each hostile in turn on the next side it sets, facing the
    party, or all of them ahead of the party while it is 0. Note: a value with none of bits 0..3 set but others set
    leaves that search for a side without end }
  monsterApproach: Byte;
  { True while Combat's MoveMenu runs, and MenuCore then takes a click in the arena as a move; CombatSt and GameInit
    clear it }
  isInMoveMenu: Boolean;
  { set by CombatAi's AiMoveAttack, which clears it first, when the creature's target, or one it picks from targetOrder,
    is within reach, so it attacks instead of moving; AiMoveStep then shows the step }
  isTargetInReach: Boolean;
  { True asks CharHlp's CombatPrintCreatureInfo to redraw the ground combat's side panel for the creature it is given,
    and it clears it as it does; a call while it is False draws nothing. Combat and CbtActs set it before they call it }
  needsCreatureInfoRedraw: Boolean;
  { True while the acting creature's moves and effects are drawn on the combat map: Combat's CreatureAction sets it for
    each creature of the team or in sight, CombatAi's AiMoveStep for each step and CbtActs for an attack; GameInit sets
    it }
  isMapVisible: Boolean;
  { the combatants in the order they act this round, highest initiative first: Combat's OrderCreatures sorts them in,
    and a creature that waits moves to the end }
  combatOrder: array[1..C_Combat.MAX_COMBATANTS] of Types.PCharacter;
  { the position in combatOrder of the creature acting: Combat's round loop steps it, and steps it back when a creature
    waits or takes its turn again }
  currentCombatant: Byte;
  { ECL registers: view color codes and read registers }
  { the floor color code ECL sets through EclMenu, which MapView turns into floorColor in CGA mode; GameInit and
    EclMenu's EclInit give it a start value }
  floorColorCode: Byte;
  { the horizon color code ECL sets through EclMenu, which MapView turns into horizonColor1 and horizonColor2 in CGA
    mode; GameInit and EclMenu's EclInit give it a start value }
  horizonColorCode: Byte;
  { reserved read-only GBVM registers; EclMenu's ReadGbvm maps none of them, so all three are unused }
  readReg1: Word;
  { unused }
  readReg2: Word;
  { unused }
  readReg3: Word;
  { ECL execution: ECL stack, compare flags, opcodes and monster ids }
  { the top of the ECL GOSUB return stack: EclMenu's EclGosub pushes onto it and its EclInit empties it, EclVm's
    EclReturn and EclExit pop it }
  eclStack: Types.PEclRet;
  { the node below the top while EclMenu's EclGosub pushes and EclVm pops; EclMenu's EclInit clears it }
  eclStackPrevious: Types.PEclRet;
  { the last ECL comparison: equal, not equal, less, greater, less or equal, greater or equal. EclMenu's EclCompareStr
    and EclCompareInt and EclVm's EclCompareAnd, EclYesNoCompare and EclFindItem set them, EclMenu's EclInit clears
    them, EclVm's EclIf tests them }
  compareFlags: array[0..5] of Boolean;
  { the opcode before currentOpcode, which EclVm's CallEclScript keeps; unused otherwise }
  previousOpcode: Byte;
  { the ECL opcode being run: EclVm's CallEclScript fetches it from zone3, and EclMenu's SkipEclCmd the one it skips;
    EclVm's DispatchEclCommand and commands branch on it }
  currentOpcode: Byte;
  { unused }
  currentOpcodeTail: Byte;
  { the SPRIT record ECL's SETUP MONSTER names: EclVm's EclSetupMonster sets it and passes it, as EclApproach does, to
    EclMenu's DisplayMonster }
  monsterSpriteId: Byte;
  { the PIC record of that monster's close-up, NO_ANIMATION for none; the same writer and readers }
  monsterPictureId: Byte;
  { the icon slot the next creatures ECL adds are loaded into: EclVm's EclLoadMonster gives it to each and counts it up;
    EclMenu's EclInit and EclVm's EclClearMonsters set it to FIRST_CREATURE_ICON_SLOT }
  nextCreatureIconSlot: Byte;
  { reserved }
  nextCreatureIconSlotTail: array[0..129] of Byte;
  { ECL operands: their types and values, and the strings they carry }
  { the type of each operand EclMenu's LoadEclVars reads: 0, 2 and 4 a byte, word or long value, 1, 3 and 5 the GBVM
    address of one, $80 a string, $81 the GBVM address of one; GetEclVar and EclVm read them }
  eclVarTypes: array[1..64] of Byte;
  { byte 1 of each operand: LoadEclVars fills it; EclMenu and EclVm read it }
  eclVarHigh: array[1..64] of Byte;
  { byte 0 of each operand, a string's length: the same writer and readers }
  eclVarLow: array[1..64] of Byte;
  { byte 3 of a type 4 operand: LoadEclVars fills it, GetEclVar reads it }
  eclVarByte3: array[1..64] of Byte;
  { byte 2 of a type 4 operand: the same writer and reader }
  eclVarByte2: array[1..64] of Byte;
  { True once Border's DrawFrameSegments reaches the end mark of the frame script it draws: it sets it False, then True
    at the mark, and loops until it is set. CbtActs's ManualAimCursor and EclMenu's EclInit also set it False, and
    EffHndlr's EffStrikeAdjacent and EffSpitAcid set it True }
  isFrameScriptDone: Boolean;
  { a loop counter the units share instead of keeping their own. Shop also holds an ammo template in it, Combat moves a
    waiting creature down combatOrder with it, and EclVm's CallEclScript sets it to 1 }
  loopIndex: ShortInt;
  { the string operands in order: EclMenu's LoadEclVars stores the k-th in slot k and EclVm's EclPrint writes slot 1;
    EclVm's menus and messages read slots 1 to the count ECL gives. Note: nothing bounds that count, or the string
    operands LoadEclVars stores, at 20, so a 21st string runs past the table into the variables after it }
  eclStrings: array[1..20] of String;
  { ECL post-combat: monster flags, write registers and post-combat state }
  { which of the monster's pictures EclMenu's DisplayMonster has shown, the sprite and the close-up: EclVm passes it to
    DisplayMonster, sets and clears it, and EclMenu's EclInit and UpdateEclDisplay clear it }
  monsterFlags: Types.TMonFlags;
  { unused }
  monsterFlagsTail: array[0..1] of Byte;
  { the sound EclVm's EclCall sends for one of its selectors, a driver command above $7F and a sound command otherwise }
  selectorSound: Word;
  { reserved GBVM write registers; EclMenu's WriteGbvm maps neither, so both are unused }
  writeReg1: Word;
  { unused }
  writeReg2: Word;
  { EclVm's EclLoadCharacter tests it with isCharacterNameCleared before it removes the creature and redraws the party,
    and clears both; EclMenu's EclInit clears it }
  refreshCharacterA: Byte;
  { set by EclMenu's SpecialWriteZ1 when ECL writes 0 to zone1's first byte, the current character's first name
    character; EclInit and EclVm's EclLoadCharacter clear it, and EclLoadCharacter tests it with refreshCharacterA }
  isCharacterNameCleared: Boolean;
  { makes CharHlp's DisplayNoncombatInterface redraw the exploration frame for C_Ifc.IN_SHOP: Shop's ShopMainMenu clears
    it for its own call and sets it after }
  needsExploreFrameRedraw: Boolean;

{ Combat's aftermath: solo combat, the experience share, treatment and ship repair. }
var
  { True while ECL $4A fights a combat with the current character alone: EclVm's EclSoloCombat sets it and runs
    EclCombat, which disables the other team members for the fight, enables them again by their status after it, runs
    PostCbt's PostCombat and clears it. While it is set CombatSt's PlaceAllCreatures places no disabled creature,
    CombatAi's AiMoveAttack bandages no one, and PostCbt's DetermineCombatResults sets isCombatWon and zone1's
    combatResult by the current character alone, gives it the whole experience and takes no loot; its isPartyDefeated
    test still scans the whole party. GameInit clears it }
  isSoloCombat: Boolean;
  { the members of partyHead's list whose isEnabled byte is 0, ahead of the first whose combat state has isOutOfPlay 1:
    PostCbt's DetermineCombatResults clears it, and counts them after combat outside a solo combat and no demo runs;
    DetermineLootExp takes it off zone1's partyCount before it divides the experience }
  disabledCount: Byte;
  { each character's share of the experience: PostCbt's DetermineLootExp works it out and AwardExperience gives it;
    PostCombat clears it and shows its summary when non-zero, RepairShip shares out the unshared experience through it
    and tests it }
  experienceShare: LongInt;
  { True once PostCbt's DetermineCombatResults, which clears it first, finds a character still up after combat; it then
    shares out the experience }
  isCombatWon: Boolean;
  { True once a fight has taken place: PostCbt's TreatInjuries runs the medics' poison and wound treatment only while it
    is set, and clears it. Combat's CombatMain sets it when the combat starts with combatants on both sides, ShipCbt's
    ShipCombat with isShipRepairPending when the team has not boarded the enemy; GameInit's orbit set-up clears it.
    PostCbt's PostCombat skips the treatment after a defeat, in the demo, while zone0's postCombatMode is
    C_PostCb.BOARDED and while its skipsTreatment is set, and leaves it set }
  isTreatmentPending: Boolean;
  { makes PostCbt's PostCombat run RepairShip, which repairs the ship and clears it: ShipCbt sets it after a ship combat
    that ends without boarding, PostCombat when zone0's postCombatMode is POST_COMBAT_REPAIR_SHIP; LootMenu and
    GameInit's orbit set-up clear it }
  isShipRepairPending: Boolean;

{ ECL flags: the script loaded, the redraw requests, the move mode and the loop start; then the overlay manager's
  reader. }
var
  { the ECL script loaded: EclVm's EclNewEcl sets it, saving the one before in zone0's savedEclId, and GameLoop sets
    $10, $12 or savedEclId. View3D's map lookups treat squares off the map as empty in NO_ECL_SCRIPT and $50; CombatSt
    seeds the dungeon arena's random numbers with it }
  eclId: Byte;
  { zone1's searchFlags' C_Search.SEARCHING bit: EclVm's GameLoop keeps it here while it sets searchFlags to
    C_Search.SEARCHING and runs the script's entry point 2, then puts it back as the whole byte; GameInit clears it }
  zone1LoBit: Byte;
  { EclVm's EclClearBox sets it to 1 and EclExit clears it, and so does GameInit; unused otherwise }
  eclDisplaying: Byte;
  { True while a picture covers the 3-D view: EclVm's ShowPicture sets it, and redraws the view and clears it; EclMenu's
    DisplayMonster sets it for a close-up, UpdateEclDisplay redraws and clears it. EclVm's horizontal menus animate
    while it is set; EclExit, EclCombat, GameLoop, EclMenu's EclInit and GameInit clear it }
  isPictureShown: Boolean;
  { set while the protection text is shown; EclInit and EclVm's GameLoop clear it. Unused, as opcode $3C, the protection
    command, is EclNoop }
  protTextShown: Byte;
  { set by EclMenu's DisplayMonster when it loads a monster sprite outdoors; UpdateEclDisplay and EclVm's ShowPicture
    then redraw the 3-D view and clear it; GameInit clears it }
  isMonsterSpriteShown: Boolean;
  { while it is False, Explore's MapMainMenu clears the text window after its menu, on its way out, and then sets it;
    EclVm's EclPrint and EclVMenu clear it }
  isBottomClear: Boolean;
  { set by EclMenu's EclInit and when ECL changes the wall color or the ceiling and floor color: in CGA mode MapView's
    DisplayMapView then works out the 3-D view's colors, and UpdateEclDisplay redraws the view and clears it }
  haveViewColorsChanged: Boolean;
  { set by EclMenu when ECL moves the party, and by EclVm's NewEclDone; EclMenu's UpdateEclDisplay then redraws the view
    and clears it }
  hasPartyMoved: Boolean;
  { set when ECL loads creatures (EclVm's EclLoadMonster, whatever their side) or makes a character hostile (EclMenu's
    SpecialWriteZ1, zone1's byte $10C with bit 0 set); only EclClearMonsters clears it, so it stays set after a fight.
    EclCombat sets it from its AnyHostile test when it is clear and fights only while it or isSoloCombat is set }
  areMonstersLoaded: Boolean;
  { set by EclMenu's WriteGbvm when ECL writes zone0's skyIndexLo or skyIndexHi; UpdateEclDisplay then redraws the view
    and clears it }
  needsSkyRedraw: Boolean;
  { while it is 0, EclMenu's DisplayMonster shows a monster's close-up even when showsMonsterPictures is False; GameInit
    clears it }
  inEncounterMenu: Byte;
  { set when EclVm's EclLoadCharacter finds no character at the place ECL gives, else cleared; EclWho clears it;
    EclMenu's SpecialReadZ1 answers 0 for zone1's byte $100 while it is set }
  hasSelectFailed: Boolean;
  { EclVm's GameLoop sets it to 1, or 0 when zone0's savedEclId is NO_ECL_SCRIPT, and redraws the noncombat interface
    through CharHlp while it is 1; EclLoadFiles redraws the exploration screen while it is set; EclClearBox and
    CharHlp's DisplayNoncombatInterface clear it }
  refreshState: Byte;
  { GameInit clears it; unused otherwise }
  victoryStart: Byte;
  { True while the map menu's Move is on. Explore's MapMainMenu sets it for Move in the 3-D view, the wilderness and the
    orbit map, and clears it for Exit, in the wilderness for an Exit that is not a click on the picture; MoveRocket
    clears it for Done, Enter or Escape that is not a click on the orbit map. While it is set the 3-D view's and the
    wilderness's menus offer only Exit and take the direction keys, the orbit map's menu returns at once and
    ResolveMovement's MoveRocket reads the move, and MenuCore's MenuHorizontal takes a click on the 3-D view, the
    wilderness picture or the orbit map as a move and, in the 3-D view, ignores one on the party list. EclVm's
    EclCombat, EclWho and EclProgram clear it and put it back after, GameLoop clears it before the map loop, and
    CombatSt's CombatStart and GameInit clear it }
  isMoveMode: Boolean;
  { the second operand of ECL $1D, which EclVm's EclSetSpeaker stores; unused otherwise }
  speakerArg2: Byte;
  { the first operand of ECL $1D; the same writer }
  speakerArg1: Byte;
  { the ECL address EclVm's EclLoopInitialize records, which EclLoopAdvance jumps back to while zone0's eclLoopCounter
    is at most eclLoopLimit }
  eclLoopStart: Word;
  { FreePtr after GameBoot sets heap aside for Tandy video memory; unused otherwise }
  graphicsReserve: Pointer;
  { unused }
  graphicsReserveTail: Byte;
  { the overlay manager's own read routine, which GameBoot saves before it installs GameIo's OverlayReadWithBeep as the
    reader; OverlayReadWithBeep calls it, beeping and retrying while it fails }
  originalOvrReader: Types.TOverlayReader;

{ The debug log, and the wilderness cursor's picture. }
var
  { the debug log, debug.txt, which Sym8x8's Load8x8Set writes to while isDebugMode is set: GameIo's Ctrl-D opens it as
    it turns isDebugMode on and closes it as it turns it off; ExitGame closes it while isDebugMode is set }
  debugFile: Text;
  { unused }
  cursorImageId: Byte;
  { the picture that marks the party's cell on the wilderness map: GameInit loads it from 'cursor'; MapCurs's DrawCursor
    draws it masked over a copy of the party's cell, at zone0's wildernessX + 1, wildernessY + 1 }
  cursorPicture: Types.PImgBuf;

{ Copy protection: the combat debug password and the protection flags. }
var
  { What lets play and the combat debug key through. CopyProt's CopyProtection clears protectionFlags and sets them one
    by one as the check passes each stage, and FixMain aborts the game if any is still 0 after it, so skipping a stage
    does not get past the check. }
  { ParamStr(1) must match it for CbtActs's debug key; GameInit sets it to 'Sahara' }
  combatDebugPassword: String[20];
  { one per stage of the check, nonzero once that stage has passed }
  protectionFlags: array[1..4] of Byte;

{ Input devices: the mouse's state and the joystick's calibration. }
var
  { True when the driver gives x in screen pixels, so GetMouse and SetMouse leave x alone; False halves and doubles it.
    GameInit and CharGen's InitMouseJoystick move the mouse to x 639 and set it by whether the x read back is below
    321 }
  isMouseScaled: Boolean;
  { True lets a click on the party list pick a character, which MenuCore's MenuHorizontal allows in C_Ifc.MAIN_MENU,
    C_Ifc.IN_SHOP, C_Ifc.VIEW_3D (not while isMoveMode is set), C_Ifc.POST_COMBAT and C_Ifc.PICTURE_VIEW. CharHlp's
    DisplayNoncombatInterface sets it by whether interfaceState is one of those five; menus that pick a character set it
    for their run, and some others clear it for theirs }
  canClickParty: Boolean;
  { True while a mouse is in use: GameBoot sets it from buck.cfg's input line, InitMouse by the driver's answer, and
    CharGen's InitMouseJoystick turns it on and off. Every Mouse call but InitMouse does nothing without it, and GameIo
    reads input from the mouse while it is set }
  isMouseOn: Boolean;
  { True when GameIo's ReadGameKey, which sets it on every call, took its key from a mouse button, the left as Enter and
    the right as Escape: MenuCore's menus then act on the click's place and clear it }
  isMouseClick: Boolean;
  { the mouse driver's button count, which InitMouse stores; GameInit and CharGen's InitMouseJoystick clear it before
    they call InitMouse }
  mouseButtons: Byte;
  { the mouse's x, which GameIo's ReadGameKey and InputPending fetch into it through GetMouse; GameInit and CharGen's
    InitMouseJoystick start it at 160; MenuCore, Explore and CharGen read it }
  mouseX: Integer;
  { the mouse's y; the same writers and readers, GameInit and CharGen starting it at 100 }
  mouseY: Integer;
  { the mouse's previous position; GameInit and CharGen's InitMouseJoystick clear it once they have set the mouse up,
    and nothing else uses it }
  mouseOldX: Integer;
  { cleared with mouseOldX }
  mouseOldY: Integer;
  { the cursor GameInit and CharGen's InitMouseJoystick hand to SetMouseCursor: arrowCursor, or cgaArrowCursor in CGA
    mode }
  mouseCursorMask: Types.PMouseCursor;
  { the mouse's button state as the game last saw it; GameInit's InitializeGame clears it with mouseButtons before it
    calls InitMouse, and nothing reads it }
  mouseButtonState: Byte;
  { per stick, the axis readings that bound JoyZone's zones; ProbeJoystick clears both, only stick 1 is measured, here
    or by CharGen's copy, and GameBoot and CharGen keep it in buck.cfg }
  joystickCalibration: array[1..2] of Types.TJoyCal;
  { True while the joystick is on, calibrated or not: GameBoot sets it from buck.cfg's input line or the first run's
    answer, and CharGen's InitMouseJoystick turns it on and off; ProbeJoystick clears it when stick 1 does not answer,
    and CalibrateJoystick sets it when it completes (an aborted one leaves it set) }
  isJoystickOn: Boolean;
  { 160, the screen's middle x, which GameInit sets while the joystick is on; unused }
  joystickCenterX: Integer;
  { 100, the screen's middle y, set with joystickCenterX; unused }
  joystickCenterY: Integer;

{ The 3-D view's backdrops, the palettes and color tables, and FixMain's root scratch pair. }
var
  { the 3-D view's two backdrops from BACK<n>.DAX: View3D's LoadBackdrop loads them, its DrawBackdrop draws one, and
    GameInit clears both at start-up. [0] is record fileId, drawn while bit $80 of partyPosition.mapEvent is set; [1] is
    record fileId + $80, drawn otherwise }
  backdropPictures: array[0..1] of Types.PImgBuf;
  { The palettes and color tables: the colors of the picture last loaded and the shadow copies Blit's
    ShadowPaletteEntries keeps of it for the combat screen, the exploration screen, the cached big picture and the
    cached animation, the 4-bit and CGA color tables Blit's PreparePic builds from a picture's header, and whether the
    exploration colors are stale. C_Pic names the DAC ranges more than one unit loads or shadows. }
  { Blit's SrcNibble reads paletteCgaColors when set, else nibbleCgaColors through paletteNibbles: PreparePic sets it
    for a picture that fills slots $20..$8F, clears it for any other, and Portrait's LoadAnimation clears it }
  usesPaletteCgaColors: Boolean;
  { in VGA mode, the colors of the big picture Portrait has cached, copied in by ShadowPaletteEntries when it loads and
    set again when the cached picture is asked for again }
  bigPicturePalette: Types.TPalette256;
  { in VGA mode, the colors of the animation Portrait has cached, copied in by ShadowPaletteEntries when it loads and
    set again when the cached animation is asked for again, except one asked for on the orbit map }
  animationPalette: Types.TPalette256;
  { the ground combat screen's colors, in VGA mode. Blit's ShadowPaletteEntries copies ranges into it from
    picturePalette as each picture loads: GameInit's InitializeGame entries 0..14 at start-up and $40..$5F after the
    COMSPR icons, MapTiles' LoadIconAnim $60..$8F after CHARS icons and $90..$FF after CPIC icons, and CombatSt's
    LoadCombatTileSet $20..$3F after the arena tiles. CombatSt's CombatStart loads DAC $20..$FF from it }
  combatPalette: Types.TPalette256;
  { the exploration screen's colors, in VGA mode. Blit's ShadowPaletteEntries copies ranges into it from picturePalette
    as each picture loads: GameInit's InitializeGame entries 0..14 at start-up and $10..$1F after the tile sets, and
    View3D's LoadWallSet $20..$B3 after a wall set's tiles and backdrops. MapView's DisplayMapView loads DAC $20..$B3
    from it while isViewPaletteStale is set, and FixMain after its title menu and Intro's Credits load DAC $10..$1F from
    it }
  viewPalette: Types.TPalette256;
  { the colors of the picture last loaded: Blit's PreparePic moves each picture's colors in from the first entry its
    header names, Portrait's LoadAnimation an animation's, and GameInit's InitializeGame puts defaultPalette in entries
    0..15 at start-up. In VGA mode Blit's ShadowPaletteEntries copies ranges of it into combatPalette, viewPalette,
    bigPicturePalette and animationPalette, and GameInit's InitializeGame, CharGen's LoadCharacterImages, OrbitMap's
    EnterOrbitMap, Portrait's LoadBigPic, ShipCbt's ShipCombat, SaveLoad's LoadShipData and Intro's Introduction load
    DAC ranges from it once their colors or pictures are in }
  picturePalette: Types.TPalette256;
  { 4-bit color of each palette index, from a picture's header; GameInit starts entries 0..15 at their own index }
  paletteNibbles: array[0..255] of Byte;
  { CGA color 0..3 of each 4-bit color, from a picture's header; GameInit starts entries 0..3 at their own index }
  nibbleCgaColors: array[0..15] of Byte;
  { CGA color 0..3 of each palette index, for a picture that fills slots $20..$8F; Blit }
  paletteCgaColors: array[0..255] of Byte;
  { set once a picture may have loaded DAC entries $20..$B3 over viewPalette's: EclMenu's DisplayMonster sets it for a
    monster's close-up, EclVm's ShowPicture for a picture and as it clears one to redraw the view, EclCombat for a
    combat, and View3D's LoadWallSet for a wall set, whose colors it copies into viewPalette. MapView's DisplayMapView,
    drawing the 3-D view, loads DAC $20..$B3 from viewPalette while it is set and clears it }
  isViewPaletteStale: Boolean;
  { FixMain zeroes it, as one 4-byte value, first thing }
  rootScratchPair: LongInt;

implementation

end.
