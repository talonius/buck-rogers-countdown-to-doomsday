{ The equipment slots: TItemType.slot's values, the slot an item readies into. TCharacter.readiedItems is indexed by the
  first two. }
unit C_Equip;

interface

const
  { TItemType.slot values, the equipment slot an item readies into. No item has slot 5. Note: ITEMS rows 25, 29 and 31
    have slot 8, which ViewChar's ToggleReadyItem readies without testing for an item already there }
  { the weapons; readiedItems[C_Equip.WEAPON] is the readied one }
  WEAPON = 0;
  { the body armor, ITEMS rows 20..24; readiedItems[C_Equip.ARMOR] is the readied one }
  ARMOR = 1;
  { Combat's menu offers Jetpack while an item of this slot is readied }
  JETPACK = 2;
  { the Grenade Lnchr., CbtActs.GRENADE_LAUNCHER_TYPE: CbtActs launches a readied grenade from it and ViewChar's
    ReadiedWeaponRange gives the grenade range 12 }
  GRENADE_LAUNCHER = 6;
  { the ECM package: AdjustEquippedItem sets C_Armor.ECM }
  ECM = 7;

implementation

end.
