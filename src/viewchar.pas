{ The character sheet and its menu. It shows a character's stats, career skills, weapon and armor, and runs the gear
  menu (ready, trade, drop, halve, join, sell), credit trading and weapon specialization; it also holds the party
  character selector, the equipped weapon's range, and the bandaging and treating of party members. NoopViewCharA and
  NoopViewCharB are empty placeholders. It uses the sheet's character, the trade selectors' start, the list of patients
  FindPatients leaves for TreatPatients, and the abilities' abbreviations the sheet shows. }
{$F+,O+,S-,R-,V-,B-,I-}
unit ViewChar;

interface

uses Types, C_Npc, C_Side, GDConsts, GDVars, Crt, Border, TextRend, CharHlp, MenuCore,
  CbtMap, FxEngine, Money, Skills, C_Equip, C_Effect, C_Skill, C_WClass, C_Ifc, C_Item, C_Keys, C_Menu;

{ Lets the player move a cursor over the party and pick a character.
  @param(query The prompt.)
  @param(offersExit True offers Exit, which picks nil.)
  @param(usesSelectorMode True turns on selector mode while it runs, which sends a party click to selectorAnchor, set to
    the member clicked, instead of to currentCharacter; the current character can still be picked.)
  @param(character In, where the cursor starts; out, the character picked.)
  @param(offersView When set, offers View, the character sheet.) }
procedure SelectChar(query: Types.TString40; offersExit, usesSelectorMode: Boolean; var character: Types.PCharacter;
                     offersView: Boolean);

{ Lists in patientSlots the party members the medic can treat: the dying, with First Aid or Treat Light Wounds, and the
  dizzy or stunned, with Treat Stun/Paralysis; in combat only adjacent ones.
  @param(character The medic.)
  @returns(True when there is at least one.) }
function FindPatients(character: Types.PCharacter): Boolean;

{ Bandages each dying patient FindPatients lists and treats the others on a skill roll.
  @param(character The medic.) }
procedure TreatPatients(character: Types.PCharacter);

{ Gives the range of a character's readied weapon.
  @param(character The character.)
  @returns(The range: 1 for none or a range of 0 or 255, 12 for a grenade with a grenade launcher readied.) }
function ReadiedWeaponRange(character: Types.PCharacter): Byte;

{ Draws the character sheet for currentCharacter, which becomes the sheet's character. }
procedure DisplayChar;

{ Recalculates currentCharacter's stats and redraws the sheet's hit points, armor class, THAC0 (60 less attackBonus),
  encumbrance, movement and damage dice. }
procedure PrintCombatStats;

{ Lists currentCharacter's eight career skills with their values, a skill whose prerequisite is unmet in yellow. }
procedure DisplayCareerSkills;

{ Redraws one ability score.
  @param(statIndex The ability.)
  @param(isModifying True draws it in the modify color.) }
procedure PrintStat(statIndex: ShortInt; isModifying: Boolean);

{ Redraws currentCharacter's credits on the sheet, with commas. }
procedure PrintMoney;

{ Runs the character sheet's menu: gear, skills, credit trade and weapon specialization.
  @param(hasEndedTurn True when an action from the gear menu ended a combat turn.) }
procedure ViewCharMenu(var hasEndedTurn: Boolean);

{ The gear menu: view, ready, trade, drop, halve, join and, in a shop, sell.
  @param(hasEndedTurn True when readying a heavy weapon ended a combat turn.) }
procedure UseItemMenu(var hasEndedTurn: Boolean);

{ Readies an item, or unreadies it, in currentCharacter's slots, unless its slot is taken.
  @param(item The item.)
  @param(hasEndedTurn True when a heavy weapon readied in combat ends the turn.) }
procedure ToggleReadyItem(item: Types.PItem; var hasEndedTurn: Boolean);

{ Empty routine with no callers. }
procedure NoopViewCharA;

{ Tests whether a character has room for one more item; the item's weight is worked out but never compared.
  @param(character The character.)
  @param(item The item offered.)
  @returns(True when the character already carries C_Item.MAX_CARRIED_ITEMS items.) }
function CannotCarryItem(character: Types.PCharacter; item: Types.PItem): Boolean;

{ Moves currentCharacter to the previous or next member, wrapping around; nothing on a mouse click.
  @param(key C_Keys.UP for the previous member, C_Keys.DOWN for the next.) }
procedure SelectPrevNextChar(key: Char);

{ Empty routine with no callers. }
procedure NoopViewCharB;

{ Shows an item's raw fields, the debug view.
  @param(item The item.) }
procedure ViewItemDetail(item: Types.PItem);

{ Finds a character's readied item in an equipment slot.
  @param(character The character.)
  @param(slot The equipment slot looked for.)
  @returns(The first readied item whose type takes that slot, or nil.) }
function FindReadiedItem(character: Types.PCharacter; slot: Byte): Types.PItem;

{ Lets the player select a character.
  @returns(True when the player selected a character, False on Exit.) }
function PickCharacter: Boolean;

{ Joins currentCharacter's like items into an item, up to 100 a stack; nothing for a non-joinable item.
  @param(item The item joined into.) }
procedure JoinItem(item: Types.PItem);

{ Weapon specialization: lists the specializable weapons, itemTemplates 1..LAST_SPECIALIZABLE_TEMPLATE (all when
  isTraining, else those the character is specialized in) and, when isTraining, adds one specialization, at most three a
  weapon.
  @param(isTraining True to train a specialization, False only to list them.) }
procedure SpecializationMenu(isTraining: Boolean);

{ Counts a character's items.
  @param(character The character.)
  @returns(The number of items on its list.) }
function CountItems(character: Types.PCharacter): Byte;

{ Gives an item to a character the player picks, joining it into their gear.
  @param(item The item given.) }
procedure ItemTradeMenu(item: Types.PItem);

{ Splits off half of an item's quantity as a new item beside it; not for a non-joinable item.
  @param(item The item halved.) }
procedure HalveItem(item: Types.PItem);

{ Offers half of an item's value, times its quantity when that is above 1 and the item is joinable, and sells or
  discards it.
  @param(item The item sold.) }
procedure SellItem(item: Types.PItem);

{ Gives credits to characters the player picks until they stop or have none left. }
procedure TradeTreasureMenu;

{ Tests whether an item may be traded, dropped or sold.
  @param(item The item.)
  @returns(False, saying so, while item is readied.) }
function CheckItemAvail(item: Types.PItem): Boolean;

implementation

{ the most a joined stack holds }
const MAX_STACK = 100;
      { the specialization menu offers itemTemplates 1..15: in ITEM0.DAX they are item types 1..15, C_Equip.WEAPON
        weapons of C_WClass.MELEE to EffHndlr.WEAPON_CLASS_SONIC, none heavy; the other C_Equip.WEAPON types, 17..19 and
        32..38, are not offered }
      LAST_SPECIALIZABLE_TEMPLATE = 15;
      { the most specializations a character takes in one weapon }
      MAX_SPECIALIZATION = 3;

function CountItems(character: Types.PCharacter): Byte;
var count: Byte;
    item: Types.PItem;
begin
  count := 0;
  item := character^.itemList;
  while item <> nil do begin
    Inc(count);
    item := item^.next
  end;
  CountItems := count
end;

procedure DisplayChar;
var
  { Unused in this version; see the other implementations of this routine. }
  statRow: Byte;
  { Unused in this version; see the other implementations of this routine. }
  row: Byte;
  { Unused in this version; see the other implementations of this routine. }
  col: Byte;
  { Unused in this version; see the other implementations of this routine. }
  statColumn: Byte;
  statIndex: ShortInt;
  { Unused in this version; see the other implementations of this routine. }
  j: Byte;
  s: String;
  { Unused in this version; see the other implementations of this routine. }
  multi: Byte;
  { Unused in this version; see the other implementations of this routine. }
  multiSeen: Byte;
  status: Types.TStatus;
begin
  GDVars.sheetCharacter := GDVars.currentCharacter;
  Border.DrawCharViewFrame;
  TextRend.DisplayString(1, 1, LightGreen, Black, 'name  :');
  TextRend.DisplayString(28, 1, LightGreen, Black, 'hp:');
  TextRend.DisplayString(1, 2, LightGreen, Black, 'race  :');
  TextRend.DisplayString(28, 2, LightGreen, Black, 'ac:');
  TextRend.DisplayString(1, 3, LightGreen, Black, 'gender:');
  TextRend.DisplayString(25, 3, LightGreen, Black, 'thaco:');
  TextRend.DisplayString(1, 4, LightGreen, Black, 'career:');
  TextRend.DisplayString(25, 4, LightGreen, Black, 'level:');
  TextRend.DisplayString(1, 6, LightGreen, Black, 'status:');
  TextRend.DisplayString(20, 6, LightGreen, Black, 'experience:');
  TextRend.DisplayString(1, 7, LightGreen, Black, 'credit:');
  TextRend.DisplayString(27, 7, LightGreen, Black, 'age:');
  TextRend.DisplayString(1, 9, LightGreen, Black, 'movmnt:');
  TextRend.DisplayString(19, 9, LightGreen, Black, 'encumbrance:');
  TextRend.DisplayString(1, 10, LightGreen, Black, 'damage:');
  TextRend.DisplayString(1, 11, LightGreen, Black, 'weapon:');
  TextRend.DisplayString(1, 12, LightGreen, Black, 'armor :');
  TextRend.DisplayString(1, 14, LightGreen, Black, 'abilities:');
  TextRend.DisplayString(12, 14, LightGreen, Black, 'career skills:');
  MenuCore.DisplayCreatureName(GDVars.sheetCharacter, 8, 1, False);
  status := GDVars.sheetCharacter^.status;
  TextRend.DisplayString(8, 2, White, Black, GDConsts.raceNames[GDVars.sheetCharacter^.race]);
  TextRend.DisplayString(8, 3, White, Black, GDConsts.genderNames[GDVars.sheetCharacter^.gender]);
  TextRend.DisplayString(8, 4, White, Black, GDConsts.careerNames[GDVars.sheetCharacter^.career]);
  s := TextRend.ByteToString(GDVars.sheetCharacter^.level);
  TextRend.RightAlignString(s, 3);
  TextRend.DisplayString(35, 4, White, Black, s);
  TextRend.DisplayString(8, 6, White, Black, GDConsts.statusNames[status]);
  s := TextRend.ByteToString(GDVars.sheetCharacter^.age);
  TextRend.RightAlignString(s, 3);
  TextRend.DisplayString(35, 7, White, Black, s);
  s := TextRend.CommaLongToString(GDVars.sheetCharacter^.experience);
  TextRend.RightAlignString(s, 7);
  TextRend.DisplayString(31, 6, White, Black, s);
  for statIndex := 0 to SizeOf(GDConsts.abilityAbbreviations) div SizeOf(GDConsts.abilityAbbreviations[0]) - 1 do begin
    TextRend.DisplayString(2, statIndex + 15, LightGreen, Black, GDConsts.abilityAbbreviations[statIndex]);
    ViewChar.PrintStat(statIndex, False)
  end;
  ViewChar.PrintMoney;
  ViewChar.PrintCombatStats;
  ViewChar.DisplayCareerSkills;
  if GDVars.sheetCharacter^.readiedItems[C_Equip.WEAPON] <> nil then
    CharHlp.PrintItemString(GDVars.sheetCharacter, GDVars.sheetCharacter^.readiedItems[C_Equip.WEAPON], 8, 11, False,
                            True);
  if GDVars.sheetCharacter^.readiedItems[C_Equip.ARMOR] <> nil then
    CharHlp.PrintItemString(GDVars.sheetCharacter, GDVars.sheetCharacter^.readiedItems[C_Equip.ARMOR], 8, 12, False,
                            True)
end;

procedure PrintMoney;
var s: String;
begin
  s := TextRend.CommaLongToString(GDVars.currentCharacter^.creditTotal);
  TextRend.RightAlignString(s, 10);
  TextRend.DisplayString(8, 7, White, Black, s)
end;

procedure PrintCombatStats;
var character: Types.PCharacter;
    { Unused in this version; see the other implementations of this routine. }
    row: Byte;
    armorColumn: Byte;
    { Unused in this version; see the other implementations of this routine. }
    movement: Byte;
    s: Types.TString40;
    { Unused in this version; see the other implementations of this routine. }
    effect: Pointer;
begin
  character := GDVars.currentCharacter;
  CharHlp.RecalcStats(character);
  Border.ClearBox(31, 1, 38, 1);
  MenuCore.PrintHitPoints(character, 31, 1, False, True);
  case character^.armorClass[0] of
    1..50: armorColumn := 36;
    51..60: armorColumn := 37;
    61..69: armorColumn := 36
  else
    armorColumn := 35
  end;
  Border.ClearBox(31, 2, 38, 2);
  MenuCore.PrintArmorClass(character, armorColumn, 2);
  Str(60 - character^.attackBonus:0, s);
  TextRend.RightAlignString(s, 3);
  TextRend.DisplayString(35, 3, White, Black, s);
  s := TextRend.WordToString(character^.encumbrance);
  TextRend.RightAlignString(s, 5);
  TextRend.DisplayString(33, 9, White, Black, s);
  movement := CharHlp.RecalcMovement(character);
  s := TextRend.ByteToString(character^.currentMovement);
  TextRend.RightAlignString(s, 7);
  TextRend.DisplayString(8, 9, White, Black, s);
  s := TextRend.ByteToString(character^.currentRolls[1]) + 'd' + TextRend.ByteToString(character^.currentDice[1]);
  if character^.currentModifiers[1] > 0 then
    s := s + '+' + TextRend.ByteToString(Byte(character^.currentModifiers[1]));
  if character^.currentModifiers[1] < 0 then
    s := s + '-' + TextRend.ByteToString(Byte(Abs(character^.currentModifiers[1])));
  TextRend.RightAlignString(s, 7);
  TextRend.DisplayString(8, 10, White, Black, s)
end;

procedure DisplayCareerSkills;
var
  row: Byte;
  skill: Byte;
    s: String;
    color: Byte;
begin
  with GDVars.currentCharacter^ do begin
    for row := 1 to SizeOf(GDConsts.careerSkills[career]) do begin
      skill := GDConsts.careerSkills[career, row];
      if CharHlp.MeetsSkillPrerequisite(GDVars.currentCharacter, skill) then
        color := LightGreen
      else
        color := Yellow;
      s := GDConsts.skillDefinitions[skill].name;
      TextRend.DisplayString(12, row + 14, color, Black, s);
      s := TextRend.ByteToString(CharHlp.SkillValue(GDVars.currentCharacter, skill));
      TextRend.RightAlignString(s, 3);
      TextRend.DisplayString(34, row + 14, White, Black, s)
    end
  end
end;

procedure PrintStat(statIndex: ShortInt; isModifying: Boolean);
var s: Types.TString3;
    highlight: Byte;
begin
  if isModifying then
    highlight := LightMagenta
  else
    highlight := White;
  Border.ClearBox(7, statIndex + 15, 9, statIndex + 15);
  s := TextRend.ByteToString(GDVars.currentCharacter^.abilities[statIndex]);
  TextRend.RightAlignString(s, 2);
  TextRend.DisplayString(7, statIndex + 15, highlight, Black, s)
end;

procedure SpecializationMenu(isTraining: Boolean);
var
  selected: Types.PMenuNode;
  menuList: Types.PMenuNode;
    weaponList: Types.PItem;
    weapon: Types.PItem;
    count: Byte;
    key: Char;
    index: Integer;
    hasTrained: Boolean;
    { menu line to weapon; the menu fills at most 15 }
    weaponMap: array[0..15] of Types.PItem;
    needsRedraw: Boolean;
    valueText: String[2];
    i: Byte;
    menuText: String[6];
    queryText: String[20];
begin
  Border.DrawWindowFrame(Byte(True));
  TextRend.DisplayString(6, 3, LightGreen, Black, 'Weapon Specialization');
  weaponList := nil;
  for i := 1 to ViewChar.LAST_SPECIALIZABLE_TEMPLATE do
    if GDVars.itemTemplates[i].itemType <> C_Item.EMPTY_TEMPLATE then begin
      GetMem(weapon, SizeOf(Types.TItem));
      Move(GDVars.itemTemplates[i], weapon^.template, SizeOf(Types.TItemTemplate));
      weapon^.next := weaponList;
      weaponList := weapon;
      weapon^.isLabel := 0
    end;
  index := 0;
  needsRedraw := True;
  hasTrained := False;
  menuText := 'Train';
  queryText := 'Select a weapon ';
  repeat
    menuList := nil;
    weapon := weaponList;
    count := 0;
    FillChar(weaponMap, SizeOf(weaponMap), 0);
    while weapon <> nil do begin
      if isTraining or (CharHlp.SpecializationLevel(GDVars.currentCharacter, weapon) > 0) then begin
        weapon^.template.quantity := 0;
        CharHlp.PrintItemString(nil, weapon, 0, 0, False, False);
        if menuList = nil then begin
          GetMem(menuList, SizeOf(Types.TMenuNode));
          selected := menuList
        end else begin
          selected := menuList;
          while selected^.next <> nil do
            selected := selected^.next;
          GetMem(selected^.next, SizeOf(Types.TMenuNode));
          selected := selected^.next
        end;
        selected^.next := nil;
        selected^.isLabel := 0;
        selected^.name := weapon^.name;
        if CharHlp.SpecializationLevel(GDVars.currentCharacter, weapon) > 0 then begin
          while Length(selected^.name) < 25 do
            selected^.name := selected^.name + ' ';
          Str(CharHlp.SpecializationLevel(GDVars.currentCharacter, weapon):0, valueText);
          selected^.name := selected^.name + '(+' + valueText + ')'
        end;
        weaponMap[count] := weapon;
        Inc(count)
      end;
      weapon := weapon^.next
    end;
    selected := menuList;
    if hasTrained or not isTraining then begin
      menuText := '';
      queryText := ''
    end;
    key := MenuCore.MenuVertical(queryText, menuText, 3, 5, 38, 22, menuList, not isTraining or hasTrained, needsRedraw,
                                 index, selected);
    if key = 'T' then begin
      weapon := weaponMap[index];
      if CharHlp.SpecializationLevel(GDVars.currentCharacter, weapon) < ViewChar.MAX_SPECIALIZATION then begin
        for i := 1 to SizeOf(GDVars.currentCharacter^.weaponSpecializations) do
          if GDVars.currentCharacter^.weaponSpecializations[i] = 0 then begin
            GDVars.currentCharacter^.weaponSpecializations[i] := weapon^.template.itemType;
            { ends the for loop after this pass }
            i := SizeOf(GDVars.currentCharacter^.weaponSpecializations);
            hasTrained := True
          end
      end else
        CharHlp.PrintBottomLine('Maximum specialization reached')
    end;
    while menuList <> nil do begin
      selected := menuList^.next;
      FreeMem(menuList, SizeOf(Types.TMenuNode));
      menuList := selected
    end
  { C_Keys.ESCAPE never arrives: MenuVertical answers Escape as C_Keys.NONE }
  until (key in [C_Keys.NONE, C_Keys.ESCAPE, 'E']) and (hasTrained or not isTraining);
  while weaponList <> nil do begin
    weapon := weaponList;
    weaponList := weaponList^.next;
    FreeMem(weapon, SizeOf(Types.TItem))
  end
end;

procedure ViewCharMenu(var hasEndedTurn: Boolean);
var key: Char;
    { Unused in this version; see the other implementations of this routine. }
    choice: Byte;
    menuText: Types.TString40;
    { Unused in this version; see the other implementations of this routine. }
    hasMoney: Byte;
    { Unused in this version; see the other implementations of this routine. }
    index: Integer;
begin
  GDVars.canClickParty := False;
  if GDVars.interfaceState = C_Ifc.IN_COMBAT then
    CbtMap.SetNoncombatPalette;
  key := ' ';
  hasEndedTurn := False;
  GDVars.tradePartner := GDVars.currentCharacter;
  ViewChar.DisplayChar;
  while not (key in [C_Keys.NONE, 'E']) and not hasEndedTurn do begin
    menuText := '';
    GDVars.horizontalChoice := 2;
    if GDVars.sheetCharacter^.itemList <> nil then begin
      menuText := menuText + 'Gear ';
      Inc(GDVars.horizontalChoice)
    end;
    menuText := menuText + 'Skills ';
    if ((GDVars.sheetCharacter^.npc < C_Npc.NON_PLAYER_FLAG) or (GDVars.sheetCharacter^.isEnabled = 0)) and
        not (GDVars.interfaceState in [C_Ifc.IN_COMBAT, C_Ifc.SHIP]) then begin
      menuText := menuText + 'Trade ';
      Inc(GDVars.horizontalChoice)
    end;
    if GDVars.sheetCharacter^.career = Types.CareerWarrior then
      menuText := menuText + 'Wpn spec ';
    menuText := menuText + 'Exit';
    MenuCore.MenuHorizontal('', menuText, False, False);
    key := GDVars.menuKey;
    index := -1;
    case key of
      'G': ViewChar.UseItemMenu(hasEndedTurn);
      'T': ViewChar.TradeTreasureMenu;
      'S': Skills.EditSkills(0, 0, 0);
      'W': begin
            ViewChar.SpecializationMenu(False);
            ViewChar.DisplayChar
          end
    end;
    if not hasEndedTurn and (key in ['G', 'S', 'T']) then
      ViewChar.DisplayChar
  end;
  if GDVars.interfaceState = C_Ifc.IN_COMBAT then
    CbtMap.SetCombatPalette
end;

function CheckItemAvail(item: Types.PItem): Boolean;
begin
  CheckItemAvail := False;
  if (item^.template.flags and C_Item.READIED) <> 0 then
    CharHlp.PrintBottomLine('Must be unreadied')
  else
    CheckItemAvail := True;
  Border.ClearBox(1, 21, 38, 22)
end;

procedure ViewItemDetail(item: Types.PItem);
var
  notJoinable: Char;
  notTreasure: Char;
  ready: Char;
begin
  Border.DrawWindowFrame(Byte(True));
  with item^ do begin
    if (item^.template.flags and C_Item.NOT_JOINABLE) <> 0 then notJoinable := 'T' else notJoinable := 'F';
    if (item^.template.flags and C_Item.NOT_TREASURE) <> 0 then notTreasure := 'T' else notTreasure := 'F';
    if (item^.template.flags and C_Item.READIED) <> 0 then ready := 'T' else ready := 'F';
    TextRend.DisplayString(1, 1, LightGreen, Black, 'itemptr:      ');
    TextRend.DisplayString(1, 2, LightGreen, Black, 'namenum(1):   ');
    TextRend.DisplayString(1, 3, LightGreen, Black, 'namenum(2):   ');
    TextRend.DisplayString(1, 4, LightGreen, Black, 'namenum(3):   ');
    TextRend.DisplayString(1, 5, LightGreen, Black, 'plus:         ');
    TextRend.DisplayString(1, 6, LightGreen, Black, 'plussave:     ');
    TextRend.DisplayString(1, 7, LightGreen, Black, 'not joinable: ');
    TextRend.DisplayString(1, 8, LightGreen, Black, 'not treasure: ');
    TextRend.DisplayString(1, 9, LightGreen, Black, 'ready:        ');
    TextRend.DisplayString(1, 10, LightGreen, Black, 'german:       ');
    TextRend.DisplayString(1, 11, LightGreen, Black, 'encumberance: ');
    TextRend.DisplayString(1, 12, LightGreen, Black, 'numitems:     ');
    TextRend.DisplayString(1, 13, LightGreen, Black, 'value:        ');
    TextRend.DisplayString(1, 14, LightGreen, Black, 'special 1:    ');
    TextRend.DisplayString(1, 15, LightGreen, Black, 'special 2:    ');
    TextRend.DisplayString(1, 16, LightGreen, Black, 'special 3:    ');
    TextRend.DisplayString(1, 17, LightGreen, Black, 'dice:         ');
    TextRend.DisplayString(1, 18, LightGreen, Black, 'sides:        ');
    TextRend.DisplayString(1, 19, LightGreen, Black, 'adds:         ');
    TextRend.DisplayString(20, 1, LightGreen, Black, TextRend.ByteToString(template.itemType));
    TextRend.DisplayString(20, 2, LightGreen, Black, TextRend.ByteToString(template.nameIds[1]));
    TextRend.DisplayString(20, 3, LightGreen, Black, TextRend.ByteToString(template.nameIds[2]));
    TextRend.DisplayString(20, 4, LightGreen, Black, TextRend.ByteToString(template.nameIds[3]));
    TextRend.DisplayString(20, 5, LightGreen, Black, TextRend.ByteToString(Byte(template.plus)));
    TextRend.DisplayString(20, 6, LightGreen, Black, TextRend.ByteToString(Byte(template.saveBonus)));
    TextRend.DisplayString(20, 7, LightGreen, Black, notJoinable);
    TextRend.DisplayString(20, 8, LightGreen, Black, notTreasure);
    TextRend.DisplayString(20, 9, LightGreen, Black, ready);
    TextRend.DisplayString(20, 10, LightGreen, Black, TextRend.ByteToString(template.unidentifiedMask));
    TextRend.DisplayString(20, 11, LightGreen, Black, TextRend.WordToString(template.weight));
    TextRend.DisplayString(20, 12, LightGreen, Black, TextRend.ByteToString(template.quantity));
    TextRend.DisplayString(20, 13, LightGreen, Black, TextRend.WordToString(template.value));
    TextRend.DisplayString(20, 14, LightGreen, Black, TextRend.ByteToString(template.special[1]));
    TextRend.DisplayString(20, 15, LightGreen, Black, TextRend.ByteToString(template.special[2]));
    TextRend.DisplayString(20, 16, LightGreen, Black, TextRend.ByteToString(template.special[3]));
    TextRend.DisplayString(20, 17, LightGreen, Black,
                           TextRend.ByteToString(GDVars.itemTypes[template.itemType].diceCount));
    TextRend.DisplayString(20, 18, LightGreen, Black,
                           TextRend.ByteToString(GDVars.itemTypes[template.itemType].diceSides));
    TextRend.DisplayString(20, 19, LightGreen, Black,
                           TextRend.ByteToString(Byte(GDVars.itemTypes[template.itemType].damageBonus)))
  end;
  TextRend.DisplayAndPause(LightGreen, Black, 'press a key')
end;

procedure UseItemMenu(var hasEndedTurn: Boolean);
var menuText: String;
    needsRedraw: Boolean;
    menuNeedsRedraw: Boolean;
    item: Types.PItem;
    selected: Types.PItem;
    index: Integer;
    { Unused in this version; see the other implementations of this routine. }
    previous: Types.PItem;
    character: Types.PCharacter;
    itemCount: Byte;
    { Unused in this version; see the other implementations of this routine. }
    count: Byte;
    optionCount: Byte;
    ch: Char;
begin
  GDVars.canClickParty := False;
  character := GDVars.currentCharacter;
  { unused: the loop starts from '@' }
  ch := ' ';
  selected := character^.itemList;
  if selected = nil then begin
    CharHlp.PrintBottomLine(character^.name + ' has no gear.');
    Exit
  end;
  index := 0;
  menuNeedsRedraw := True;
  needsRedraw := True;
  hasEndedTurn := False;
  ch := '@';
  while not (ch in [C_Keys.NONE, 'E']) and not hasEndedTurn and (character^.itemList <> nil) do begin
    menuText := 'Ready';
    optionCount := 4;
    if ((character^.npc < C_Npc.NON_PLAYER_FLAG) or (character^.isEnabled = 0)) and
        not (GDVars.interfaceState in [C_Ifc.IN_COMBAT, C_Ifc.SHIP]) then begin
      menuText := menuText + ' Trade';
      Inc(optionCount)
    end;
    menuText := menuText + ' Drop';
    if ViewChar.CountItems(character) < C_Item.MAX_CARRIED_ITEMS then begin
      menuText := menuText + ' Halve';
      Inc(optionCount)
    end;
    menuText := menuText + ' Join';
    if ((character^.npc < C_Npc.NON_PLAYER_FLAG) or (character^.isEnabled = 0)) and
        (GDVars.interfaceState = C_Ifc.IN_SHOP) then
      menuText := menuText + ' Sell';
    item := character^.itemList;
    if (GDVars.horizontalChoice = C_Menu.SELL_CHOICE) or (ch = 'S') then begin
      GDVars.horizontalChoice := optionCount;
      GDVars.menuChecksum := C_Menu.KEEP_MENU_CHOICE
    end;
    while item <> nil do begin
      CharHlp.PrintItemString(character, item, 0, 0, True, False);
      item := item^.next
    end;
    if needsRedraw or GDVars.needsGearRefresh then begin
      Border.DrawListFrame;
      MenuCore.DisplayCreatureName(character, 1, 1, True);
      TextRend.DisplayString(Length(character^.name) + 4, 1, LightGreen, Black, 'Gear');
      TextRend.DisplayString(1, 3, White, Black, 'Ready Item');
      menuNeedsRedraw := True;
      needsRedraw := False;
      GDVars.needsGearRefresh := False
    end;
    itemCount := ViewChar.CountItems(character);
    ch := MenuCore.MenuVertical('', menuText, 1, 5, 38, 22, Types.PMenuNode(character^.itemList), True,
                                menuNeedsRedraw, index, Types.PMenuNode(selected));
    if selected <> nil then
      case ch of
        'V': begin
              ViewChar.ViewItemDetail(selected);
              menuNeedsRedraw := True;
              needsRedraw := True
            end;
        'R': begin
              ViewChar.ToggleReadyItem(selected, hasEndedTurn);
              if hasEndedTurn then
                CharHlp.PrintBottomLine(character^.name + ' loads a heavy weapon.')
            end;
        'T': begin
              if ViewChar.CheckItemAvail(selected) then
                ViewChar.ItemTradeMenu(selected);
              ch := ' ';
              needsRedraw := True
            end;
        'D': if ViewChar.CheckItemAvail(selected) then begin
              CharHlp.PrintItemString(character, selected, 0, 0, False, False);
              TextRend.DisplayMessageWindow(1, 21, 38, 22, Yellow, Black, True,
                                            'Your ' + selected^.name + ' will be gone forever');
              if MenuCore.YesNoMenu('Drop It? ', C_Menu.DEFAULT_NO) = 'Y' then begin
                CharHlp.RemoveItem(GDVars.currentCharacter, selected);
                menuNeedsRedraw := True
              end;
              Border.ClearBox(1, 21, 38, 22)
            end else
              ch := ' ';
        'H': ViewChar.HalveItem(selected);
        'J': ViewChar.JoinItem(selected);
        'S': if ViewChar.CheckItemAvail(selected) then
              ViewChar.SellItem(selected)
            else
              ch := ' '
      end;
    CharHlp.RecalcStats(character);
    if ViewChar.CountItems(character) <> itemCount then
      menuNeedsRedraw := True
  end;
end;

function FindReadiedItem(character: Types.PCharacter; slot: Byte): Types.PItem;
var item: Types.PItem;
begin
  item := character^.itemList;
  while item <> nil do begin
    if ((item^.template.flags and C_Item.READIED) <> 0) and
        (GDVars.itemTypes[item^.template.itemType].slot = slot) then begin
      FindReadiedItem := item;
      Exit
    end else
      item := item^.next
  end;
  FindReadiedItem := nil
end;

procedure ToggleReadyItem(item: Types.PItem; var hasEndedTurn: Boolean);
var
  { Unused in this version; see the other implementations of this routine. }
  hasSpecial: Boolean;
  slot: ShortInt;
  character: Types.PCharacter;
  occupied: Types.PItem;
begin
  hasEndedTurn := False;
  hasSpecial := item^.template.special[3] > $7F;
  character := GDVars.currentCharacter;
  slot := GDVars.itemTypes[item^.template.itemType].slot;
  if (item^.template.flags and C_Item.READIED) <> 0 then begin
    item^.template.flags := item^.template.flags xor C_Item.READIED;
    { readiedItems' slots }
    if Byte(slot) < Succ(C_Equip.ARMOR) then
      character^.readiedItems[slot] := nil
  end else begin
    case Byte(slot) of
      C_Equip.WEAPON..C_Equip.ARMOR: begin
             occupied := character^.readiedItems[slot];
             if occupied = nil then
               character^.readiedItems[slot] := item
           end;
      C_Equip.JETPACK..C_Equip.ECM: occupied := ViewChar.FindReadiedItem(character, Byte(slot))
      else occupied := nil
    end;
    if occupied <> nil then begin
      CharHlp.PrintItemString(character, occupied, 0, 0, False, False);
      CharHlp.PrintBottomLine('already using ' + occupied^.name)
    end else begin
      item^.template.flags := item^.template.flags or C_Item.READIED;
      hasEndedTurn := (GDVars.itemTypes[item^.template.itemType].isHeavy <> 0) and
        (GDVars.interfaceState = C_Ifc.IN_COMBAT);
      if hasEndedTurn then
        hasEndedTurn := CharHlp.EndActions(GDVars.currentCharacter)
    end
  end
end;

procedure ItemTradeMenu(item: Types.PItem);
var target: Types.PCharacter;
    savedCharacter: Types.PCharacter;
    itemCursor: Types.PItem;
begin
  target := GDVars.tradePartner;
  CharHlp.DisplayNoncombatInterface;
  ViewChar.SelectChar('Trade with Whom?', True, True, target, False);
  if (GDVars.currentCharacter <> nil) and (target <> nil) then begin
    GDVars.tradePartner := target;
    if ViewChar.CannotCarryItem(target, item) then
      CharHlp.PrintBottomLine('Overloaded')
    else begin
      CharHlp.AddItemCopy(target, item);
      CharHlp.RemoveItem(GDVars.currentCharacter, item);
      CharHlp.RecalcStats(target);
      if target <> GDVars.currentCharacter then begin
        itemCursor := target^.itemList;
        while itemCursor^.next <> nil do
          itemCursor := itemCursor^.next;
        savedCharacter := GDVars.currentCharacter;
        GDVars.currentCharacter := target;
        ViewChar.JoinItem(itemCursor);
        GDVars.currentCharacter := savedCharacter
      end
    end
  end
end;

procedure HalveItem(item: Types.PItem);
var newItem: Types.PItem;
    half: Byte;
    remainder: Byte;
begin
  half := item^.template.quantity div 2;
  if ((item^.template.flags and C_Item.NOT_JOINABLE) = 0) and (half > 0) then begin
    remainder := item^.template.quantity - half;
    GetMem(newItem, SizeOf(Types.TItem));
    Move(item^, newItem^, SizeOf(Types.TItem));
    newItem^.template.quantity := half;
    newItem^.template.flags := item^.template.flags and not C_Item.READIED;
    newItem^.next := item^.next;
    item^.template.quantity := remainder;
    item^.next := newItem
  end else
    CharHlp.PrintBottomLine('Can''t halve that')
end;

procedure JoinItem(item: Types.PItem);
var
  current: Types.PItem;
  next: Types.PItem;
  destination: Types.PItem;
    quantity: Byte;
begin
  if (item^.template.flags and C_Item.NOT_JOINABLE) <> 0 then
    Exit;
  if item^.template.quantity = 0 then
    item^.template.quantity := 1;
  destination := item;
  quantity := destination^.template.quantity;
  current := GDVars.currentCharacter^.itemList;
  while current <> nil do begin
    next := current^.next;
    if (current <> destination) and (current^.template.nameIds[1] = destination^.template.nameIds[1]) and
        (current^.template.nameIds[2] = destination^.template.nameIds[2]) and
        (current^.template.nameIds[3] = destination^.template.nameIds[3]) and
        (current^.template.itemType = destination^.template.itemType) and
        (current^.template.plus = destination^.template.plus) and
        (current^.template.saveBonus = destination^.template.saveBonus) and
        (current^.template.weight = destination^.template.weight) and
        (current^.template.special[1] = destination^.template.special[1]) and
        (current^.template.special[2] = destination^.template.special[2]) and
        (current^.template.special[3] = destination^.template.special[3]) then begin
      if current^.template.quantity = 0 then
        current^.template.quantity := 1;
      if quantity + current^.template.quantity <= ViewChar.MAX_STACK then begin
        Inc(quantity, current^.template.quantity);
        CharHlp.RemoveItem(GDVars.currentCharacter, current)
      end else begin
        destination^.template.quantity := ViewChar.MAX_STACK;
        current^.template.quantity := current^.template.quantity - (ViewChar.MAX_STACK - quantity);
        quantity := current^.template.quantity;
        destination := current
      end
    end;
    current := next
  end;
  destination^.template.quantity := quantity
end;

procedure SellItem(item: Types.PItem);
var
  price: Word;
  amount: Word;
    { Unused in this version; see the other implementations of this routine. }
    gold: Word;
    { Unused in this version; see the other implementations of this routine. }
    takable: Word;
    prompt: Types.TString40;
begin
  price := 0;
  if item^.template.value > 0 then
    price := item^.template.value div 2;
  if (item^.template.quantity > 1) and ((item^.template.flags and C_Item.NOT_JOINABLE) = 0) then
    price := price * item^.template.quantity;
  CharHlp.PrintItemString(GDVars.sheetCharacter, item, 0, 0, False, False);
  if price > 0 then begin
    TextRend.DisplayMessageWindow(1, 21, 38, 22, Yellow, Black, True,
                                  'I''ll give you ' + TextRend.WordToString(price) + ' credits for your ' + item^.name);
    prompt := 'Will you sell ';
    if item^.template.quantity < 2 then
      prompt := prompt + 'it? '
    else
      prompt := prompt + 'them? '
  end else begin
    if item^.template.quantity < 2 then begin
      TextRend.DisplayMessageWindow(1, 21, 38, 22, Yellow, Black, True,
                                    'Your ' + item^.name + ' is worthless to me.');
      prompt := 'Shall I dispose of it for you? '
    end else begin
      TextRend.DisplayMessageWindow(1, 21, 38, 22, Yellow, Black, True,
                                    'Your ' + item^.name + ' are worthless.');
      prompt := 'Would you like to discard them? '
    end
  end;
  if MenuCore.YesNoMenu(prompt, C_Menu.DEFAULT_YES) = 'Y' then begin
    if price > 0 then
      CharHlp.PrintBottomLine('Sold!')
    else if item^.template.quantity < 2 then
      CharHlp.PrintBottomLine('I will give it to one of my sons.')
    else
      CharHlp.PrintBottomLine('Very well.  I''ll recycle them.');
    CharHlp.RemoveItem(GDVars.currentCharacter, item);
    amount := price;
    Inc(GDVars.currentCharacter^.creditTotal, amount)
  end;
  Border.ClearBox(1, 21, 38, 22)
end;

procedure TradeTreasureMenu;
var target: Types.PCharacter;
    isDone: Boolean;
    isTargetDone: Boolean;
    amount: LongInt;
begin
  isDone := False;
  isTargetDone := False;
  repeat
    target := GDVars.tradePartner;
    CharHlp.DisplayNoncombatInterface;
    ViewChar.SelectChar(GDConsts.tradeToPrompt, True, True, target, False);
    if (target = nil) or (target = GDVars.currentCharacter) then
      isDone := True
    else begin
      ViewChar.DisplayChar;
      repeat
        ViewChar.PrintMoney;
        GDVars.tradePartner := target;
        amount := Money.InputNumberMax(GDVars.currentCharacter^.creditTotal, 'how many credits will you give?', 10);
        if amount > 0 then begin
          Money.TradeMoney(GDVars.currentCharacter, target, Word(amount));
          isTargetDone := GDVars.currentCharacter^.creditTotal = 0
        end else
          isTargetDone := True;
        isDone := GDVars.currentCharacter^.creditTotal = 0
      until isTargetDone
    end
  until isDone
end;

function CannotCarryItem(character: Types.PCharacter; item: Types.PItem): Boolean;
var cannotCarry: Boolean;
    { item's weight, times its quantity when that is above 0 and the item is joinable; never compared: only the item
      count decides }
    weight: Word;
begin
  CharHlp.RecalcStats(character);
  cannotCarry := False;
  weight := item^.template.weight;
  if (item^.template.quantity > 0) and ((item^.template.flags and C_Item.NOT_JOINABLE) = 0) then
    weight := weight * item^.template.quantity;
  if ViewChar.CountItems(character) >= C_Item.MAX_CARRIED_ITEMS then
    cannotCarry := True;
  CannotCarryItem := cannotCarry
end;

procedure SelectPrevNextChar(key: Char);
var current: Types.PCharacter;
begin
  if not GDVars.isMouseOn or not GDVars.isMouseClick then begin
    if GDVars.currentCharacter = nil then
      GDVars.currentCharacter := GDVars.partyHead;
    if GDVars.currentCharacter <> nil then
      case key of
        C_Keys.UP: begin
              if GDVars.currentCharacter = GDVars.partyHead then begin
                while GDVars.currentCharacter^.next <> nil do
                  GDVars.currentCharacter := GDVars.currentCharacter^.next
              end else begin
                current := GDVars.partyHead;
                while (current <> nil) and (current^.next <> GDVars.currentCharacter) do
                  current := current^.next;
                GDVars.currentCharacter := current
              end
            end;
        C_Keys.DOWN: if GDVars.currentCharacter^.next <> nil then
              GDVars.currentCharacter := GDVars.currentCharacter^.next
            else
              GDVars.currentCharacter := GDVars.partyHead
      end
  end
end;

function PickCharacter: Boolean;
var savedCanClickParty: Boolean;
begin
  savedCanClickParty := GDVars.canClickParty;
  GDVars.canClickParty := True;
  repeat
    MenuCore.MenuHorizontal('Pick Character ', 'Select Exit', True, False);
    if GDVars.isExtendedKey then begin
      CharHlp.DisplayRoster(GDVars.currentCharacter, False);
      ViewChar.SelectPrevNextChar(GDVars.menuKey);
      CharHlp.DisplayRoster(GDVars.currentCharacter, True)
    end
  until not GDVars.isExtendedKey and (GDVars.menuKey in [C_Keys.NONE, 'E', 'S']);
  CharHlp.DisplayRoster(GDVars.currentCharacter, True);
  PickCharacter := GDVars.menuKey = 'S';
  GDVars.canClickParty := savedCanClickParty
end;

function ReadiedWeaponRange(character: Types.PCharacter): Byte;
var
  item: Types.PItem;
  secondary: Types.PItem;
    weaponRange: Byte;
begin
  item := character^.readiedItems[C_Equip.WEAPON];
  if item <> nil then begin
    weaponRange := GDVars.itemTypes[item^.template.itemType].range;
    if (weaponRange = 0) or (weaponRange = 255) then
      weaponRange := 1;
    if GDVars.itemTypes[item^.template.itemType].weaponClass = C_WClass.GRENADE then begin
      secondary := ViewChar.FindReadiedItem(character, C_Equip.GRENADE_LAUNCHER);
      if secondary <> nil then
        weaponRange := 12
    end;
    ReadiedWeaponRange := weaponRange
  end else
    ReadiedWeaponRange := 1
end;

function FindPatients(character: Types.PCharacter): Boolean;
var candidate: Types.PCharacter;
    effect: Types.PEffect;
    sourceX: ShortInt;
    sourceY: ShortInt;
    deltaX: ShortInt;
    deltaY: ShortInt;
begin
  GDVars.patientCount := 0;
  sourceX := CbtMap.CombatCellX(character);
  sourceY := CbtMap.CombatCellY(character);
  candidate := GDVars.partyHead;
  while candidate <> nil do begin
    deltaX := CbtMap.CombatCellX(candidate) - sourceX;
    deltaY := CbtMap.CombatCellY(candidate) - sourceY;
    if (candidate^.side = C_Side.TEAM) and (candidate^.combatState^.isOutOfPlay = 0) and
        ((GDVars.interfaceState <> C_Ifc.IN_COMBAT) or
         ((deltaX >= -1) and (deltaX <= 1) and (deltaY >= -1) and (deltaY <= 1))) and
        (((candidate^.status = Types.StDying) and
          ((character^.skillLevels[C_Skill.FIRST_AID] > 0) or
           (character^.skillLevels[C_Skill.TREAT_LIGHT] > 0))) or
        ((candidate^.isEnabled <> 0) and
         (CharHlp.HasEffect(candidate, C_Effect.DIZZY, effect) or
          CharHlp.HasEffect(candidate, C_Effect.STUNNED, effect)) and
        (character^.skillLevels[C_Skill.TREAT_STUN] > 0))) then begin
      Inc(GDVars.patientCount);
      GDVars.patientSlots[GDVars.patientCount] := CbtMap.CombatSlot(candidate)
    end;
    candidate := candidate^.next
  end;
  FindPatients := GDVars.patientCount > 0
end;

procedure TreatPatients(character: Types.PCharacter);
var target: Types.PCharacter;
    { Unused in this version; see the other implementations of this routine. }
    isFound: Byte;
    effect: Types.PEffect;
begin
  if ViewChar.FindPatients(character) then begin
    for GDVars.loopIndex := 1 to GDVars.patientCount do begin
      target := GDVars.creatures[GDVars.patientSlots[GDVars.loopIndex]];
      if (target^.status = Types.StDying) and
          ((character^.skillLevels[C_Skill.FIRST_AID] > 0) or
           (character^.skillLevels[C_Skill.TREAT_LIGHT] > 0)) then begin
        Dec(GDVars.patientCount);
        target^.status := Types.StUnconscious;
        target^.combatState^.dyingCount := 0;
        CharHlp.PrintCreatureMessage(target, 'is bandaged', 10, True);
        TextRend.PauseOnly
      end else if
        (CharHlp.HasEffect(target, C_Effect.DIZZY, effect) or
         CharHlp.HasEffect(target, C_Effect.STUNNED, effect)) and
          (CharHlp.SelectSkillCharacter(C_Skill.TREAT_STUN, 2, False, character) >= 2) then begin
        Dec(GDVars.patientCount);
        CharHlp.PrintCreatureMessage(target, 'is treated', 10, True);
        FxEngine.RemoveEffect(target, C_Effect.DIZZY, nil);
        FxEngine.RemoveEffect(target, C_Effect.STUNNED, nil)
      end
    end
  end
end;

procedure SelectChar(query: Types.TString40; offersExit, usesSelectorMode: Boolean; var character: Types.PCharacter;
                     offersView: Boolean);
var isAnimated: Boolean;
    cursor: Types.PCharacter;
    menuText: Types.TString40;
    savedCanClickParty: Boolean;
    { ViewCharMenu's combat-turn result; ignored here }
    hasEndedTurn: Boolean;
begin
  savedCanClickParty := GDVars.canClickParty;
  GDVars.isSelectorMode := usesSelectorMode;
  GDVars.selectorAnchor := GDVars.currentCharacter;
  GDVars.menuKey := ' ';
  menuText := 'Select';
  if offersView then
    menuText := menuText + ' View';
  if offersExit then
    menuText := menuText + ' Exit';
  { Note: meant as Escape, which MenuHorizontal answers as C_Keys.NONE }
  while not (GDVars.menuKey in [C_Keys.NONE, C_Keys.ENTER, C_Keys.RIGHT_BRACKET, 'E', 'S']) do begin
    MenuCore.DisplayParty(character);
    if (GDVars.interfaceState = C_Ifc.CAMPING) or (GDVars.interfaceState = C_Ifc.POST_COMBAT) then
      isAnimated := True
    else
      isAnimated := False;
    GDVars.canClickParty := True;
    MenuCore.MenuHorizontal(query + ' ', menuText, True, isAnimated);
    GDVars.canClickParty := savedCanClickParty;
    cursor := character;
    if GDVars.isExtendedKey then begin
      case GDVars.menuKey of
        C_Keys.DOWN: begin
              cursor := cursor^.next;
              if cursor = nil then
                cursor := GDVars.partyHead
            end;
        C_Keys.UP: if GDVars.isMouseClick then begin
              if GDVars.isSelectorMode then begin
                if cursor = GDVars.selectorAnchor then
                  GDVars.menuKey := 'S';
                cursor := GDVars.selectorAnchor
              end else begin
                if cursor = GDVars.currentCharacter then
                  GDVars.menuKey := 'S';
                cursor := GDVars.currentCharacter
              end
            end else begin
              cursor := GDVars.partyHead;
              if character <> GDVars.partyHead then begin
                while cursor^.next <> character do
                  cursor := cursor^.next
              end else begin
                while cursor^.next <> nil do
                  cursor := cursor^.next
              end
            end
      end
    end else begin
      if GDVars.menuKey = 'V' then begin
        cursor := GDVars.currentCharacter;
        ViewChar.ViewCharMenu(hasEndedTurn);
        GDVars.currentCharacter := cursor;
        CharHlp.DisplayNoncombatInterface;
        GDVars.menuKey := 'V'
      end else if offersExit and ((GDVars.menuKey = 'E') or (GDVars.menuKey = C_Keys.NONE)) then
        cursor := nil
    end;
    character := cursor
  end;
  GDVars.isSelectorMode := False
end;

procedure NoopViewCharA;
begin
end;

procedure NoopViewCharB;
begin
end;
begin
end.
