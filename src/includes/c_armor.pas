{ The armor bits, TCharacter.armorFlags, set for the readied gear. }
unit C_Armor;

interface

const
  { TCharacter.armorFlags bits, which CharHlp's AdjustEquippedItem sets for the readied gear }
  { the CharHlp.EQUIP_GOGGLES gear, the Protective Goggles: CbtActs spares the wearer a Dazzle Grenade }
  GOGGLES = $08;
  { the C_Equip.ECM gear, the ECM package: CbtActs cancels a C_WClass.ROCKET hit half the time }
  ECM = $10;
  { Battle armor w/fields: CbtActs cancels a C_WClass.ROCKET hit three times in four }
  FIELDS = $20;
  { any body armor: CbtActs cancels a C_WClass.MICROWAVE hit }
  BODY = $40;
  { the CharHlp.EQUIP_BREATHING_MASK gear, the Breathing Mask, and any body armor: FxEngine spares the wearer harmful
    terrain and CbtActs a Gas Grenade }
  BREATHING_PROTECTION = $80;

implementation

end.
