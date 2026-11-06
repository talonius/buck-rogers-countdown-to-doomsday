{ The bits of a ship weapon slot's kind. }
unit C_Ship;

interface

const
  { TShipWeaponSlot.kind's low seven bits, the weapon, an index into shipWeapons; ShipCbt, CharHlp, PostCbt }
  KIND_MASK = $7F;

implementation

end.
