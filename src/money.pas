{ Money, counted in credits: the team's credit pool -- pooling, sharing out and taking credits -- the bottom-line number
  prompt that the credit menus read amounts with, and credit transfers between characters. The pool is poolCredits,
  which PostCbt, Shop and EclVm also use; isPoolActive marks it in use. }
{$O+,F+,A-}
unit Money;

interface

uses Types, C_Npc, C_Screen, C_Keys, GDConsts, GDVars, TextRend, GameIo;

{ Empty routine with no callers. }
procedure NoopMoney;

{ Counts the members PoolMoney takes credits from.
  @returns(The number of party members whose npc byte is 0 or PARTY_MEMBER_NPC.) }
function CountPoolers: Byte;

{ Tells whether the pool holds credits and whether there are items on offer.
  @param(hasCredits True when credits sit in the pool.)
  @param(hasOther True when the available-items list holds a list: the spoils after combat, or Shop's stock.) }
procedure DetermineTreasure(var hasCredits, hasOther: Boolean);

{ Moves the credits of each member whose npc byte is 0 or PARTY_MEMBER_NPC into the pool and marks the pool active. }
procedure PoolMoney;

{ Shares the pool out among the members whose npc byte is below NON_PLAYER_FLAG, dividing by CountPoolers; the remainder
  goes a credit each to the first of them. Empties the pool and marks it inactive. Note: the divisor and the payees
  differ. A PARTY_MEMBER_NPC member is counted but not paid, so that share is lost, and a member whose npc byte is
  1..$7F is paid but not counted. }
procedure ShareMoney;

{ Shows the pool, lets the current character take credits from it, then marks whether credits remain in the pool. }
procedure TakeMoneyMenu;

{ Reads a number on the bottom line after prompt: digits, Backspace, Enter to accept, Esc to cancel. A number that would
  pass maximum becomes maximum.
  @param(maximum The largest number accepted.)
  @param(prompt The text shown before the number.)
  @param(color The prompt's color.)
  @returns(The number entered, or -1 on Esc.) }
function InputNumberMax(maximum: LongInt; prompt: Types.TString40; color: Byte): LongInt;

{ Moves credits from one character to another, unchecked.
  @param(source The character paying.)
  @param(target The character paid.)
  @param(amount The credits moved.) }
procedure TradeMoney(var source, target: Types.PCharacter; amount: Word);

{ Gives a character credits from the pool, or all of it when amount is more.
  @param(character The character paid.)
  @param(amount The credits asked for.) }
procedure TakeMoney(character: Types.PCharacter; amount: LongInt);

implementation

const
  { the typed number and its cursor }
  INPUT_COLOR = 15;
  { TakeMoneyMenu's line showing the pool }
  POOL_COLOR = 15;
  { TakeMoneyMenu's prompt }
  TAKE_PROMPT_COLOR = 10;

function InputNumberMax(maximum: LongInt; prompt: Types.TString40; color: Byte): LongInt;
var
  column: Byte;
  { Unused in this version; see the other implementations of this routine. }
  questionLength: Byte;
  promptLength: Byte;
  maximumText: String[15];
  typedText: String[15];
  key: Char;
  value: LongInt;
  errorCode: Integer;
  resultValue: LongInt;
begin
  TextRend.PrintSpaces(0, C_Screen.STATUS_ROW, 0, C_Screen.TEXT_COLUMNS);
  TextRend.DisplayString(0, C_Screen.STATUS_ROW, color, 0, prompt);
  promptLength := Length(prompt);
  column := promptLength;
  Str(maximum, maximumText);
  typedText := '';
  repeat
    TextRend.PrintSpaces(column, C_Screen.STATUS_ROW, Money.INPUT_COLOR, 1);
    TextRend.PrintSpaces(column + 1, C_Screen.STATUS_ROW, 0, 2);
    key := GameIo.ReadGameKey;
    case key of
      '0'..'9': begin
        typedText := Concat(typedText, key);
        Val(typedText, value, errorCode);
        if value <= maximum then
          Inc(column)
        else begin
          typedText := maximumText;
          column := promptLength + Length(maximumText)
        end;
        TextRend.DisplayString(promptLength, C_Screen.STATUS_ROW, Money.INPUT_COLOR, 0, typedText)
      end;
      C_Keys.BACKSPACE:
        if Length(typedText) > 0 then begin
          typedText := Copy(typedText, 1, Length(typedText) - 1);
          Dec(column)
        end
    end
  until (key = C_Keys.ENTER) or (key = C_Keys.ESCAPE);
  TextRend.PrintSpaces(0, C_Screen.STATUS_ROW, 0, C_Screen.TEXT_COLUMNS);
  if key = C_Keys.ESCAPE then
    InputNumberMax := -1
  else begin
    Val(typedText, resultValue, errorCode);
    InputNumberMax := resultValue
  end
end;

procedure TradeMoney(var source, target: Types.PCharacter; amount: Word);
begin
  Dec(source^.creditTotal, amount);
  Inc(target^.creditTotal, amount)
end;

procedure PoolMoney;
var
  current: Types.PCharacter;
  { Unused in this version; see the other implementations of this routine. }
  moneyType: Word;
begin
  current := GDVars.partyHead;
  GDVars.isPoolActive := True;
  while current <> nil do begin
    if (current^.npc = 0) or (current^.npc = C_Npc.PARTY_MEMBER_NPC) then begin
      Inc(GDVars.poolCredits, current^.creditTotal);
      current^.creditTotal := 0
    end;
    current := current^.next
  end
end;

function CountPoolers: Byte;
var
  current: Types.PCharacter;
  count: Byte;
begin
  current := GDVars.partyHead;
  count := 0;
  while current <> nil do begin
    if (current^.npc = 0) or (current^.npc = C_Npc.PARTY_MEMBER_NPC) then Inc(count);
    current := current^.next
  end;
  CountPoolers := count
end;

procedure ShareMoney;
var
  current: Types.PCharacter;
  { Unused in this version; see the other implementations of this routine. }
  receiver: array[0..3] of Byte;
  count: Byte;
  { Unused in this version; see the other implementations of this routine. }
  isDone: Byte;
  { Unused in this version; see the other implementations of this routine. }
  takable: Word;
  share: Word;
  remainder: Word;
begin
  current := GDVars.partyHead;
  isDone := 0;
  count := Money.CountPoolers;
  share := 0;
  remainder := 0;
  if GDVars.poolCredits > 0 then begin
    share := GDVars.poolCredits div count;
    remainder := GDVars.poolCredits mod count
  end else begin
    GDVars.isPoolActive := False;
    Exit
  end;
  while current <> nil do begin
    if current^.npc < C_Npc.NON_PLAYER_FLAG then begin
      Inc(current^.creditTotal, share);
      if remainder > 0 then begin
        Inc(current^.creditTotal);
        Dec(remainder)
      end
    end;
    current := current^.next
  end;
  GDVars.isPoolActive := False;
  GDVars.poolCredits := 0
end;

procedure TakeMoney(character: Types.PCharacter; amount: LongInt);
begin
  if amount > GDVars.poolCredits then amount := GDVars.poolCredits;
  Dec(GDVars.poolCredits, amount);
  Inc(character^.creditTotal, amount)
end;

procedure TakeMoneyMenu;
var
  amount: LongInt;
  { Unused in this version; see the other implementations of this routine. }
  index: Byte;
  poolText: String;
begin
  Str(GDVars.poolCredits, poolText);
  poolText := 'Credits : ' + poolText + '              ';
  TextRend.DisplayString(1, 17, Money.POOL_COLOR, 0, poolText);
  amount := Money.InputNumberMax(GDVars.poolCredits, 'How many credits will you take? ', Money.TAKE_PROMPT_COLOR);
  if amount > 0 then Money.TakeMoney(GDVars.currentCharacter, amount);
  GDVars.isPoolActive := GDVars.poolCredits > 0
end;

procedure DetermineTreasure(var hasCredits, hasOther: Boolean);
begin
  hasCredits := GDVars.poolCredits > 0;
  hasOther := GDVars.availableItems <> nil
end;

procedure NoopMoney; begin end;

begin
end.
