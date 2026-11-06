{ The log-book copy protection. Outside the demo, FixMain runs CopyProtection before play: the player is asked for a
  word from a page of the log book. The questions, encoded, the prompt texts and the ordinal words ("first", "second",
  ...) are in GDConsts, and each stage of the check sets one of protectionFlags. }
{$O+,F+,A-}
unit CopyProt;

interface

{ Asks for a word from the log book, up to three times, each time a random question. The answer is matched case-blind:
  ReadString upper-cases the typed word, and the expected one is upper-cased to match.
  @returns(True when an answer matched.) }
function CopyProtection: Boolean;

implementation

uses Crt, Border, TextRend, GDConsts, GDVars, Types;

const
  MAX_ATTEMPTS = 3;
  { ReadString's limit on the typed answer }
  ANSWER_MAX_LENGTH = 20;
  { key of the stored text's encoding; see Decode }
  CODE_OFFSET = 6;

function CopyProtection: Boolean;
var
  i: Byte;
  entryNumber: Byte;
  attempt: Byte;
  { Unused in this version; see the other implementations of this routine. }
  index: Byte;
  expected: String;
  reply: String;

  { Empty routine with no callers. }
  procedure Noop;
  begin
  end;

  { The question's heading (isDisplayText) or its answer, decoded: each code less CODE_OFFSET plus the text's length. }
  function Decode(isDisplayText: Boolean; entryNumber: Byte): String;
  var
    i: Byte;
    decoded: Byte;
    result: String;
  begin
    result := '';
    with GDConsts.protectionQuestions[entryNumber] do
    if isDisplayText <> False then begin
      for i := 1 to Length(displayText) do begin
        decoded := Ord(displayText[i]) - CopyProt.CODE_OFFSET + Length(displayText);
        result := result + Chr(decoded)
      end
    end else begin
      for i := 1 to Length(answer) do begin
        decoded := Ord(answer[i]) - CopyProt.CODE_OFFSET + Length(answer);
        result := result + Chr(decoded)
      end
    end;
    Decode := result
  end;

  { The width of the ordinal word wordOrdinals[ordinal] plus one space, where the question's tail starts. }
  function OrdinalWidth(ordinal: Byte): Byte;
  begin
    case ordinal of
      7: OrdinalWidth := 8;
      2, 4, 8: OrdinalWidth := 7
    else
      OrdinalWidth := 6
    end
  end;

begin
  FillChar(GDVars.protectionFlags, SizeOf(GDVars.protectionFlags), 0);
  Border.DrawWindowFrame(1);
  attempt := 0;
  repeat
    Inc(attempt);
    expected := '';
    entryNumber := Random(SizeOf(GDConsts.protectionQuestions) div SizeOf(Types.TProtectionEntry)) + 1;
    with GDConsts.protectionQuestions[entryNumber] do begin
      GDVars.protectionFlags[1] := 1;
      TextRend.DisplayString(3, 2, LightGreen, Black, GDConsts.logBookPrompt);
      TextRend.DisplayString(29, 2, White, Black, TextRend.ByteToString(page) + '   ');
      TextRend.DisplayString(3, 4, LightGreen, Black, GDConsts.headingPrompt);
      Border.ClearBox(1, 5, 38, 5);
      TextRend.DisplayString(20 - Length(displayText) div 2, 5, White, Black, Decode(True, entryNumber));
      TextRend.DisplayString(3, 7, LightGreen, Black, GDConsts.questionHead + '  ');
      TextRend.DisplayString(15, 7, White, Black, GDConsts.wordOrdinals[wordIndex] + ' ');
      TextRend.DisplayString(OrdinalWidth(wordIndex) + 15, 7, LightGreen, Black, GDConsts.questionTail);
      GDVars.protectionFlags[2] := 1;
      expected := Decode(False, entryNumber);
      reply := TextRend.ReadString('', Yellow, Black, CopyProt.ANSWER_MAX_LENGTH);
      for i := 1 to Length(expected) do expected[i] := UpCase(expected[i])
    end;
  until (attempt = CopyProt.MAX_ATTEMPTS) or (reply = expected);
  GDVars.protectionFlags[3] := 1;
  if reply = expected then
    CopyProtection := True
  else
    CopyProtection := False;
  GDVars.protectionFlags[4] := 1
end;

begin
end.
