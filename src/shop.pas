{ The shop: its main menu, buying from the shop's item list, the ammunition counter that fills clips and reloads missile
  weapons, and the exit warning about credits left in the pool. Selling, viewing and the pool itself are ViewChar's and
  Money's routines. It uses menuNeedsRedraw, the two free ammunition items' templates and quantities, and ammoPrices;
  the shop's item list is availableItems, and the pool is poolCredits. }
{$O+,F+,V-}
unit Shop;

interface

uses Types, GDConsts, GDVars, TextRend, MenuCore, CharHlp, ViewChar, Border, Money,
  Crt, C_Equip, C_WClass, C_Ifc, C_Item, C_Keys, C_Menu, C_Msg;

{ Runs the shop until the party leaves it, with interfaceState IN_SHOP meanwhile. It empties the pool on entry, and
  credits still pooled when the party declines to go back for them at the exit are lost. }
procedure ShopMainMenu;

{ Gives currentCharacter a copy of item, joined with a like item unless it is not joinable, and takes it back when that
  leaves more than 16 items.
  @param(item The item copied.)
  @param(failed True when the copy was taken back.) }
procedure GiveItemCopyToCreature(item: Types.PItem; var failed: Boolean);

{ Puts the two free ammunition items (freeAmmoTemplates, freeAmmoQuantities) at the head of currentCharacter's item
  list, readied. }
procedure BuildAmmoItems;

implementation

const
  { a buy-menu line: the item's name, its price right-aligned }
  MENU_LINE_WIDTH = 38;
  { rounds a ROUND_AT_A_TIME_CLASSES weapon holds; it is sold a round at a time }
  AREA_AMMO_CAPACITY = 10;
  { the area weapons but the grenades }
  ROUND_AT_A_TIME_CLASSES = [C_WClass.ROCKET_LAUNCHER, C_WClass.PLASMA];
  { rounds any other missile weapon holds }
  AMMO_CAPACITY = 250;
  { rounds in one of its clips }
  CLIP_ROUNDS = 10;

{ Shows the current character's funds and the pooled funds on rows 20 and 21. }
procedure DisplayShopMoney;
var s: String[10];
begin
  Str(GDVars.currentCharacter^.creditTotal, s);
  TextRend.RightAlignString(s, 10);
  TextRend.DisplayString(1, 20, White, Black, 'Personal funds:' + s);
  Str(GDVars.poolCredits, s);
  TextRend.RightAlignString(s, 10);
  TextRend.DisplayString(1, 21, White, Black, 'Pooled funds:  ' + s)
end;

{ Prices an item for the shop.
  @param(item The item priced.)
  @returns(The item's value, scaled by zone 1's priceMultiplier / 16 when that is set.) }
function ItemPrice(item: Types.PItem): LongInt;
begin
  if GDVars.zone1^.priceMultiplier = 0 then
    ItemPrice := item^.template.value
  else
    ItemPrice := LongInt(item^.template.value) * GDVars.zone1^.priceMultiplier div 16
end;

{ Lays each shop item's price into its name's last columns (raising a value of 0 to 1), runs the buy menu, then rebuilds
  the names.
  @param(key The key that ended the menu.)
  @param(itemToBuy The item under the cursor when the menu returns.)
  @param(cursor The menu's cursor item, kept between calls.)
  @param(idx The menu's cursor index, kept between calls.) }
procedure ShopBuyItemSelection(var key: Char; var itemToBuy, cursor: Types.PItem; var idx: Integer);
var
  head: Types.PItem;
  item: Types.PItem;
  priceText: String[16];
  menuLine: String[Shop.MENU_LINE_WIDTH];
  textLength: Byte;
  charIndex: Byte;
  price: LongInt;
begin
  item := GDVars.availableItems;
  while item <> nil do begin
    menuLine := GDConsts.menuBlankLine;
    if item^.template.value = 0 then item^.template.value := 1;
    price := Shop.ItemPrice(item);
    Str(price, priceText);
    textLength := Length(priceText);
    for charIndex := 1 to textLength do
      menuLine[Shop.MENU_LINE_WIDTH - textLength + charIndex] := priceText[charIndex];
    textLength := Length(item^.name);
    for charIndex := 1 to textLength do
      menuLine[charIndex] := item^.name[charIndex];
    item^.name := menuLine;
    item^.name[0] := Chr(Shop.MENU_LINE_WIDTH);
    item := item^.next
  end;
  head := GDVars.availableItems;
  GDVars.horizontalChoice := 0;
  key := MenuCore.MenuVertical(GDConsts.itemsPrompt, GDConsts.buyMenu, 1, 1, 38, 18, Types.PMenuNode(head), True,
                               GDVars.menuNeedsRedraw, idx, Types.PMenuNode(cursor));
  itemToBuy := cursor;
  item := GDVars.availableItems;
  while item <> nil do begin
    CharHlp.PrintItemString(nil, item, 0, 0, False, False);
    item := item^.next
  end
end;

procedure GiveItemCopyToCreature(item: Types.PItem; var failed: Boolean);
var
  newItem: Types.PItem;
  tail: Types.PItem;
begin
  failed := False;
  GetMem(newItem, SizeOf(Types.TItem));
  newItem^ := item^;
  newItem^.next := nil;
  tail := GDVars.currentCharacter^.itemList;
  if tail = nil then
    GDVars.currentCharacter^.itemList := newItem
  else begin
    while tail^.next <> nil do tail := tail^.next;
    tail^.next := newItem
  end;
  if (item^.template.flags and C_Item.NOT_JOINABLE) = 0 then ViewChar.JoinItem(newItem);
  if ViewChar.CountItems(GDVars.currentCharacter) > C_Item.MAX_CARRIED_ITEMS then begin
    CharHlp.PrintBottomLine('OverLoaded');
    failed := True;
    CharHlp.RemoveItem(GDVars.currentCharacter, newItem)
  end;
  CharHlp.RecalcStats(GDVars.currentCharacter)
end;

procedure BuildAmmoItems;
var item: Types.PItem; i: Byte;
begin
  for i := 1 to SizeOf(GDConsts.freeAmmoTemplates) do begin
    GetMem(item, SizeOf(Types.TItem));
    GDVars.loopIndex := GDConsts.freeAmmoTemplates[i];
    Move(GDVars.itemTemplates[GDVars.loopIndex], item^.template, SizeOf(Types.TItemTemplate));
    item^.template.quantity := GDConsts.freeAmmoQuantities[i];
    item^.next := GDVars.currentCharacter^.itemList;
    item^.isLabel := 0;
    GDVars.currentCharacter^.itemList := item;
    item^.template.flags := item^.template.flags or C_Item.READIED
  end
end;

{ Runs the buy menu: gives currentCharacter a copy of the item chosen and charges its price to the character's credits,
  or, when they fall short, takes all of them and the rest from the pool, until the player leaves. }
procedure ShopBuyMenu;
var
  item: Types.PItem;
  key: Char;
  done: Boolean;
  price: LongInt;
  failed: Boolean;
  cursor: Types.PItem;
  idx: Integer;
begin
  item := nil;
  cursor := GDVars.availableItems;
  idx := 0;
  Border.DrawWindowFrame(Byte(True));
  GDVars.menuNeedsRedraw := True;
  repeat
    Shop.DisplayShopMoney;
    Shop.ShopBuyItemSelection(key, item, cursor, idx);
    if (key <> 'B') and (key <> C_Keys.ENTER) then
      done := True
    else begin
      done := False;
      price := Shop.ItemPrice(item);
      if price <= GDVars.currentCharacter^.creditTotal then begin
        Shop.GiveItemCopyToCreature(item, failed);
        if not failed then begin
          Dec(GDVars.currentCharacter^.creditTotal, price);
          if item^.template.quantity > 0 then
            CharHlp.PrintBottomLine(GDVars.currentCharacter^.name + ' buys ' + item^.name)
          else
            CharHlp.PrintBottomLine(GDVars.currentCharacter^.name + ' buys a ' + item^.name)
        end
      end else if price <= GDVars.poolCredits + GDVars.currentCharacter^.creditTotal then begin
        Shop.GiveItemCopyToCreature(item, failed);
        if not failed then begin
          Dec(price, GDVars.currentCharacter^.creditTotal);
          GDVars.currentCharacter^.creditTotal := 0;
          Dec(GDVars.poolCredits, price);
          if item^.template.quantity > 0 then
            CharHlp.PrintBottomLine(GDVars.currentCharacter^.name + ' buys ' + item^.name)
          else
            CharHlp.PrintBottomLine(GDVars.currentCharacter^.name + ' buys a ' + item^.name)
        end
      end else
        CharHlp.PrintBottomLine('Not enough Money.')
    end
  until done
end;

{ Lists currentCharacter's missile weapons with the price of a clip and of a fill, and sells either; the pool covers
  what the character's credits lack. }
procedure ShopAmmoMenu;
var
  tail: Types.PMenuNode;
  menuItems: Types.PMenuNode;
  weapon: Types.PItem;
  weaponIndex: Byte;
  key: Char;
  selectionIndex: Integer;
  done: Boolean;
  weapons: array[0..C_Item.MAX_CARRIED_ITEMS - 1] of Types.PItem;
  totalCost: Word;
  { Unused in this version; see the other implementations of this routine. }
  hasBoughtAmmo: Boolean;
  clipCount: Byte;
  amount: Byte;
  baseAmount: Byte;
  info: ^TItemType;
  priceText: Types.TString40;

  { Sets amount, baseAmount, clipCount and totalCost for weapons[index]: a clip ('C') or a fill ('F') up to capacity. }
  procedure AmmoValues(index: Byte; action: Char);
  begin
    if GDVars.itemTypes[weapons[index]^.template.itemType].weaponClass in Shop.ROUND_AT_A_TIME_CLASSES then begin
      baseAmount := Shop.AREA_AMMO_CAPACITY;
      amount := 1
    end else begin
      amount := Shop.CLIP_ROUNDS;
      baseAmount := Shop.AMMO_CAPACITY
    end;
    if action = 'F' then amount := baseAmount;
    amount := Byte(CharHlp.MinimumWord(amount, baseAmount - weapons[index]^.template.quantity));
    if GDVars.itemTypes[weapons[index]^.template.itemType].weaponClass in Shop.ROUND_AT_A_TIME_CLASSES then
      clipCount := amount
    else
      clipCount := (amount + (Shop.CLIP_ROUNDS - 1)) div Shop.CLIP_ROUNDS;
    totalCost := GDConsts.ammoPrices[weapons[index]^.template.itemType] * clipCount
  end;
begin
  selectionIndex := 0;
  GDVars.menuNeedsRedraw := True;
  done := False;
  repeat
    menuItems := nil;
    weapon := GDVars.currentCharacter^.itemList;
    if weapon = nil then Exit;
    weaponIndex := 0;
    FillChar(weapons, SizeOf(weapons), 0);
    while weapon <> nil do begin
      info := @GDVars.itemTypes[weapon^.template.itemType];
      if (info^.slot = C_Equip.WEAPON) and (info^.weaponClass <> C_WClass.MELEE) and
          (info^.weaponClass <> C_WClass.GRENADE) and
          ((weapon^.template.flags and C_Item.NOT_JOINABLE) <> 0) then begin
        weapons[weaponIndex] := weapon;
        CharHlp.PrintItemString(nil, weapon, 0, 0, False, False);
        AmmoValues(weaponIndex, 'C');
        Str(LongInt(totalCost), priceText);
        TextRend.RightAlignString(priceText, 32 - Length(weapon^.name));
        weapon^.name := weapon^.name + priceText;
        AmmoValues(weaponIndex, 'F');
        Str(LongInt(totalCost), priceText);
        TextRend.RightAlignString(priceText, 6);
        weapon^.name := weapon^.name + priceText;
        if menuItems = nil then begin
          GetMem(menuItems, SizeOf(Types.TMenuNode));
          menuItems^.next := nil;
          menuItems^.isLabel := 0;
          menuItems^.name := weapon^.name
        end else begin
          tail := menuItems;
          while tail^.next <> nil do tail := tail^.next;
          GetMem(tail^.next, SizeOf(Types.TMenuNode));
          tail := tail^.next;
          tail^.next := nil;
          tail^.isLabel := 0;
          tail^.name := weapon^.name
        end;
        Inc(weaponIndex)
      end;
      weapon := weapon^.next
    end;
    if menuItems = nil then begin
      CharHlp.PrintBottomLine(GDVars.currentCharacter^.name + ' has no missile weapons');
      Exit
    end;
    Border.DrawWindowFrame(Byte(True));
    tail := menuItems;
    for GDVars.loopIndex := 2 to selectionIndex do tail := tail^.next;
    Shop.DisplayShopMoney;
    TextRend.DisplayString(1, 2, White, Black, 'Weapon');
    TextRend.DisplayString(29, 2, White, Black, 'Clip  Fill');
    GDVars.canClickParty := False;
    key := MenuCore.MenuVertical('', 'Fill Clip', 1, 3, 38, 19, menuItems, True, GDVars.menuNeedsRedraw, selectionIndex,
                                 tail);
    GDVars.canClickParty := True;
    AmmoValues(selectionIndex, key);
    case key of
    C_Keys.NONE, C_Keys.ESCAPE:
      done := True;
    'C', 'F': begin
      if weapons[selectionIndex]^.template.quantity < baseAmount then begin
        if totalCost > GDVars.currentCharacter^.creditTotal then
          if totalCost <= GDVars.currentCharacter^.creditTotal + GDVars.poolCredits then begin
            Dec(GDVars.poolCredits, totalCost - GDVars.currentCharacter^.creditTotal);
            GDVars.currentCharacter^.creditTotal := totalCost
          end;
        if totalCost <= GDVars.currentCharacter^.creditTotal then begin
          hasBoughtAmmo := True;
          Dec(GDVars.currentCharacter^.creditTotal, totalCost);
          if key = 'C' then
            CharHlp.PrintBottomLine(GDVars.currentCharacter^.name + ' purchases a clip')
          else
            CharHlp.PrintBottomLine(GDVars.currentCharacter^.name + '''s weapon is reloaded');
          if weapons[selectionIndex]^.template.quantity < baseAmount then begin
            Inc(weapons[selectionIndex]^.template.quantity, amount);
            if weapons[selectionIndex]^.template.quantity > baseAmount then
              weapons[selectionIndex]^.template.quantity := baseAmount
          end;
          CharHlp.PrintItemString(nil, weapons[selectionIndex], 0, 0, False, False);
          tail^.name := weapons[selectionIndex]^.name
        end else
          CharHlp.PrintBottomLine('Not enough Money')
      end else
        CharHlp.PrintBottomLine('Already full');
      GDVars.menuNeedsRedraw := True
    end
    end;
    while menuItems <> nil do begin
      tail := menuItems^.next;
      FreeMem(menuItems, SizeOf(Types.TMenuNode));
      menuItems := tail
    end
  until done;
  CharHlp.DisplayNoncombatInterface;
  MenuCore.DisplayParty(GDVars.currentCharacter)
end;

procedure ShopMainMenu;
var
  menu: Types.TString40;
  query: String[1];
  done: Boolean;
  key: Char;
  hasMoney: Boolean;
  hasItems: Boolean;
  { Unused in this version; see the other implementations of this routine. }
  hasSold: Byte;
  item: Types.PItem;
  { UseItemMenu's combat-turn result; a shop ignores it }
  hasEndedTurn: Boolean;
  oldInterfaceState: Byte;
begin
  oldInterfaceState := GDVars.interfaceState;
  GDVars.interfaceState := C_Ifc.IN_SHOP;
  GDVars.needsExploreFrameRedraw := False;
  CharHlp.DisplayNoncombatInterface;
  GDVars.needsExploreFrameRedraw := True;
  MenuCore.DisplayParty(GDVars.currentCharacter);
  GDVars.poolCredits := 0;
  query := '';
  GDVars.isPoolActive := False;
  done := False;
  item := GDVars.availableItems;
  while item <> nil do begin
    CharHlp.PrintItemString(nil, item, 0, 0, False, False);
    item := item^.next
  end;
  repeat
    Money.DetermineTreasure(hasMoney, hasItems);
    menu := 'Buy Sell Ammo View Pool ';
    if hasMoney then menu := menu + 'Take Divvy ';
    menu := menu + 'Exit';
    GDVars.canClickParty := True;
    MenuCore.MenuHorizontal(query, menu, True, False);
    GDVars.canClickParty := False;
    key := GDVars.menuKey;
    case key of
    'A': Shop.ShopAmmoMenu;
    'B': begin
      Shop.ShopBuyMenu;
      CharHlp.DisplayNoncombatInterface;
      MenuCore.DisplayParty(GDVars.currentCharacter)
    end;
    'S': begin
      GDVars.horizontalChoice := C_Menu.SELL_CHOICE;
      GDVars.menuChecksum := C_Menu.KEEP_MENU_CHOICE;
      ViewChar.UseItemMenu(hasEndedTurn);
      CharHlp.DisplayNoncombatInterface;
      MenuCore.DisplayParty(GDVars.currentCharacter)
    end;
    'V': begin
      ViewChar.ViewCharMenu(GDVars.isExtendedKey);
      CharHlp.DisplayNoncombatInterface;
      MenuCore.DisplayParty(GDVars.currentCharacter)
    end;
    'T': begin
      Money.TakeMoneyMenu;
      TextRend.ClearRect(C_Msg.MESSAGE_LEFT, C_Msg.MESSAGE_TOP, C_Msg.MESSAGE_RIGHT, C_Msg.MESSAGE_BOTTOM)
    end;
    'P': if not GDVars.isExtendedKey then
      Money.PoolMoney
    else begin
      CharHlp.DisplayRoster(GDVars.currentCharacter, False);
      ViewChar.SelectPrevNextChar(key);
      CharHlp.DisplayRoster(GDVars.currentCharacter, True)
    end;
    'D': Money.ShareMoney;
    'E': begin
      Money.DetermineTreasure(hasMoney, hasItems);
      if hasMoney then begin
        TextRend.DisplayMessageWindow(C_Msg.MESSAGE_LEFT, C_Msg.MESSAGE_TOP,
          C_Msg.MESSAGE_RIGHT, C_Msg.MESSAGE_BOTTOM, LightGreen, Black, True,
          'As you Leave the Shopkeeper says, "Excuse me but you have Left Some Money here."  ');
        TextRend.DisplayMessageWindow(C_Msg.MESSAGE_LEFT, C_Msg.MESSAGE_TOP, C_Msg.MESSAGE_RIGHT,
                                      C_Msg.MESSAGE_BOTTOM, White, Black, False,
                                      'Do you want to go back and get your Money?');
        if MenuCore.YesNoMenu(query, C_Menu.DEFAULT_YES) = 'N' then begin
          done := True;
          TextRend.DisplayMessageWindow(C_Msg.MESSAGE_LEFT, C_Msg.MESSAGE_TOP, C_Msg.MESSAGE_RIGHT,
                                        C_Msg.MESSAGE_BOTTOM, White, Black, True,
                                        'Thanks for the tip.  Have a nice day.');
          TextRend.PauseOnly
        end else
          TextRend.ClearRect(C_Msg.MESSAGE_LEFT, C_Msg.MESSAGE_TOP, C_Msg.MESSAGE_RIGHT,
                             C_Msg.MESSAGE_BOTTOM)
      end else
        done := True
    end;
    'H': begin
      CharHlp.DisplayRoster(GDVars.currentCharacter, False);
      ViewChar.SelectPrevNextChar(key);
      CharHlp.DisplayRoster(GDVars.currentCharacter, True)
    end
    end
  until done;
  GDVars.interfaceState := oldInterfaceState
end;

begin
end.
