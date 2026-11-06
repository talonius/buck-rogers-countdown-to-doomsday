{ The GBVM address of the current character's record. }
unit C_Gbvm;

interface

const
  { the base EclMenu's SpecialReadZ1 and SpecialWriteZ1 take off a zone 1 address before they dispatch on what is left:
    the current character's bytes, or at $2B1 and $312 its place in the party and the data set; WriteGbvmString and
    DerefGbString take a string at it as the current character's name }
  CURRENT_CHARACTER = $7C00;

implementation

end.
