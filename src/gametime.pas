{ The game clock and what time does to the party: advancing the clock, carrying each unit into the next, running effect
  durations down, and resting. It uses effectFlags, which in C_Ifc.CAMPING lets TimeOutEffects skip members with nothing
  running down. NoopGameTimeA to NoopGameTimeD are empty placeholders. }
{$O+,F+,A-}
unit GameTime;

interface

uses FxEngine, Types, C_Combat, C_Time, GDConsts, GDVars, C_Ifc;

type
  TClock = array[0..6] of Word;

{ Empty routine with no callers. }
procedure NoopGameTimeA;

{ Advances zone 0's game clock by amount of one clock unit, then has TimeOutEffects run the party's effects down by
  amount of that unit. Note: for segments, the clock's smallest unit, that is amount minutes, ten times the clock's
  advance.
  @param(amount The count of clock units to advance by.)
  @param(timeUnit The clock unit, from segments (0) to years (6).) }
procedure AdvanceTime(amount: Byte; timeUnit: ShortInt);

{ Advances the clock by amount days and gives each party member who is okay or unconscious amount hit points, up to the
  maximum; the unconscious come round and every member healed is enabled.
  @param(amount The days of rest, and the hit points each member gains.) }
procedure RestAndHeal(amount: Byte);

{ Runs the party's effect durations, which count minutes, down by count of clock unit timeUnit, converted to minutes for
  units above C_Time.MINUTES and taken at most 10 at a time, removing each effect that runs out. Outside C_Ifc.CAMPING
  every member is checked; in it, only members effectFlags still marks, and nothing when none is marked. Note: a count
  of segments is taken as minutes, unconverted. And after an effect runs out, the walk resumes at the head of the list
  when the effect before it was the head, and otherwise at the second effect the list began with, so effects already
  passed can lose another step, and that second effect may by then have been freed.
  @param(count The count of clock units that passed.)
  @param(timeUnit The clock unit, from segments (0) to years (6).) }
procedure TimeOutEffects(count: Byte; timeUnit: ShortInt);

{ Carries each clock unit that has reached its clockUnitScale into the next; the last unit's carry ages every party
  member a year, takes the carried years off the clock and sets hasCenturyPassed.
  @param(clock The clock, normalized in place.) }
procedure ValidateClock(var clock: TClock);

{ Empty routine with no callers. }
procedure NoopGameTimeB;

{ Empty routine with no callers. }
procedure NoopGameTimeC;

{ Empty routine with no callers. }
procedure NoopGameTimeD;

implementation

const
  { the most minutes TimeOutEffects takes off a duration at once }
  MAX_EFFECT_STEP = 10;
  { the clock's smallest unit; ten segments make a minute }
  TIME_SEGMENT = 0;
  { the clock unit RestAndHeal advances by }
  TIME_DAY = 4;
  { the clock's largest unit }
  TIME_YEAR = 6;

procedure TimeOutEffects(count: Byte; timeUnit: ShortInt);
var
  u: ShortInt;
  i: Byte;
  step: Byte;
  total: Word;
  cur: Types.PCharacter;
  done: Boolean;
  found: Boolean;
  tail: Types.PEffect;
  prev: Types.PEffect;
  next: Types.PEffect;
  effect: Types.PEffect;
begin
  if GDVars.interfaceState <> C_Ifc.CAMPING then
    FillChar(GDVars.effectFlags, SizeOf(GDVars.effectFlags), 1)
  else begin
    found := False;
    i := 1;
    repeat
      if GDVars.effectFlags[i] <> 0 then found := True;
      Inc(i)
    until found or (i > GDVars.zone1^.partyCount);
    if not found then Exit
  end;
  total := count;
  u := timeUnit;
  while u > C_Time.MINUTES do begin
    total := GDConsts.clockUnitScale[Pred(u)] * total;
    u := Pred(u)
  end;
  while total > 0 do begin
    if total > GameTime.MAX_EFFECT_STEP then step := GameTime.MAX_EFFECT_STEP else step := total;
    i := 1;
    cur := GDVars.partyHead;
    while cur <> nil do begin
      if GDVars.effectFlags[i] <> 0 then begin
        GDVars.effectFlags[i] := 0;
        effect := cur^.effectList;
        tail := cur^.effectList;
        prev := cur^.effectList;
        next := prev^.next;
        if cur^.effectList <> nil then
          while tail^.next <> nil do tail := tail^.next;
        done := False;
        while (effect <> nil) and not done do begin
          if effect = tail then done := True;
          if effect^.duration = 0 then
            effect := effect^.next
          else if step < effect^.duration then begin
            Dec(effect^.duration, step);
            GDVars.effectFlags[i] := 1;
            effect := effect^.next
          end else begin
            FxEngine.RemoveEffect(cur, effect^.effectId, effect);
            if prev = cur^.effectList then effect := cur^.effectList
            else effect := next
          end;
          prev := cur^.effectList;
          while (prev <> nil) and (prev <> effect) and (prev^.next <> effect) do
            prev := prev^.next
        end;
        while effect <> nil do begin
          if effect^.duration > 0 then GDVars.effectFlags[i] := 1;
          effect := effect^.next
        end
      end;
      Inc(i);
      cur := cur^.next
    end;
    if total > GameTime.MAX_EFFECT_STEP then Dec(total, GameTime.MAX_EFFECT_STEP) else total := 0
  end
end;

procedure ValidateClock(var clock: TClock);
var
  i: ShortInt;
  cur: Types.PCharacter;
begin
  for i := GameTime.TIME_SEGMENT to GameTime.TIME_YEAR do begin
    if clock[i] >= GDConsts.clockUnitScale[i] then begin
      if i <> GameTime.TIME_YEAR then begin
        Inc(clock[Succ(i)]);
        clock[i] := clock[i] - GDConsts.clockUnitScale[i]
      end else begin
        cur := GDVars.partyHead;
        while cur <> nil do begin
          Inc(cur^.age);
          cur := cur^.next
        end;
        clock[GameTime.TIME_YEAR] := clock[GameTime.TIME_YEAR] - GDConsts.clockUnitScale[GameTime.TIME_YEAR];
        GDVars.hasCenturyPassed := True
      end
    end
  end
end;

procedure AdvanceTime(amount: Byte; timeUnit: ShortInt);
var
  clock: TClock;
  i: ShortInt;
  j: Byte;
begin
  for i := GameTime.TIME_SEGMENT to GameTime.TIME_YEAR do clock[i] := GDVars.zone0^.clock[$4BC6 + i];
  for j := 1 to amount do begin
    Inc(clock[timeUnit]);
    GameTime.ValidateClock(clock)
  end;
  for i := GameTime.TIME_SEGMENT to GameTime.TIME_YEAR do GDVars.zone0^.clock[$4BC6 + i] := clock[i];
  GameTime.TimeOutEffects(amount, timeUnit)
end;

procedure RestAndHeal(amount: Byte);
var cur: Types.PCharacter;
begin
  GameTime.AdvanceTime(amount, GameTime.TIME_DAY);
  cur := GDVars.partyHead;
  while cur <> nil do begin
    if cur^.status = Types.StUnconscious then cur^.status := Types.StOkay;
    if cur^.status = Types.StOkay then begin
      cur^.isEnabled := 1;
      Inc(cur^.hitPoints, amount);
      if cur^.hitPoints > cur^.hitPointMaximum then cur^.hitPoints := cur^.hitPointMaximum
    end;
    cur := cur^.next
  end
end;

procedure NoopGameTimeA; begin end;

procedure NoopGameTimeB; begin end;

procedure NoopGameTimeC; begin end;

procedure NoopGameTimeD; begin end;

begin
end.
