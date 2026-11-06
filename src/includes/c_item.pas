{ Items: the flag bits of TItemTemplate.flags, the marker of an empty item template, the most items a character carries,
  and the itemTypes rows the code names. }
unit C_Item;

interface

const
  { TItemTemplate.flags: the item is readied. CbtActs clears it on the grenade or missile it fires, and PostCbt on each
    item it copies as treasure }
  READIED = $80;
  { TItemTemplate.flags: PostCbt's DetermineLootExp never takes the item as treasure; ViewChar shows it }
  NOT_TREASURE = $40;
  { TItemTemplate.flags: the item is never joined with a like item, nor halved }
  NOT_JOINABLE = $20;
  { TItemTemplate.itemType of an empty itemTemplates slot: EclMenu's LoadItemTemplates fills every byte with it first,
    and EclVm's EclTreasure and EclShop and ViewChar's SpecializationMenu skip a slot holding it }
  EMPTY_TEMPLATE = 255;
  { the most items a character carries: Shop takes back a bought item past it, and ViewChar offers Halve and accepts a
    trade only below it }
  MAX_CARRIED_ITEMS = 16;
  { the Sonic Stunner's itemTypes row: a hit with it stuns, and CharHlp's WeaponAdjust adds no specialization or plus to
    its damage; CbtActs, CharHlp, CombatAi }
  SONIC_STUNNER_TYPE = 15;
  { the area weapons' itemTypes rows, named by ITEM0.DAX's templates of the same number; CombatAi aims and scores them }
  { Plasma Thrwr, C_WClass.PLASMA }
  PLASMA_THROWER_TYPE = 17;
  { Rocket Lnchr., C_WClass.ROCKET_LAUNCHER }
  ROCKET_LAUNCHER_TYPE = 18;
  { the grenades are C_WClass.GRENADE, each firing its projectile kind: this one kind 12 }
  STUN_GRENADE_TYPE = 35;
  { kind 5 }
  DAZZLE_GRENADE_TYPE = 36;

implementation

end.
