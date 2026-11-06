{ The 3-D map's empty markers: no map loaded, an empty wall-set cache entry, and no fixed position readout. }
unit C_Map;

interface

const
  { zone 0's geoMapId when no 3-D map is loaded: EclVm's EclLoadFiles sets it for that GEO operand, and SaveLoad's
    LoadGame then loads no map }
  NO_GEO_MAP = 127;
  { TWallSet.fileId of an empty wall-set cache entry, with NO_WALL_SET_SLOT: EclVm's EclLoadFiles and GameInit empty an
    entry with the two }
  NO_WALL_SET_FILE = -1;
  { TWallSet.slot of an empty entry }
  NO_WALL_SET_SLOT = 65535;
  { zone 0's readoutX when CharHlp's position line shows the party's own x,y; MapView keeps the automap off while it is
    anything else }
  NO_READOUT = 255;

implementation

end.
