{ The interface states, interfaceState values. }
unit C_Ifc;

interface

const
  { interfaceState values, each by the code that sets it }
  { CharGen's MainMenu, and SaveLoad's LoadGame on its way back to it }
  MAIN_MENU = 0;
  { Shop's ShopMainMenu }
  IN_SHOP = 1;
  { CharHlp's position line adds ' camping' in it }
  CAMPING = 2;
  { EclMenu's WriteGbvm when ECL sets areaKind $A2 or $A8, EclVm's picture mode 4 }
  WILDERNESS = 3;
  { GameInit, EclVm's GameLoop and picture mode 0, EclMenu's WriteGbvm for any other areaKind }
  VIEW_3D = 4;
  { ground combat: Combat's CombatMain }
  IN_COMBAT = 5;
  { PostCbt's PostCombat, from the results to the loot menu }
  POST_COMBAT = 6;
  { the ship screen: ShipCbt's ShipCombat, and the ship views of Explore's orbit map and PostCbt's loot }
  SHIP = 8;
  { Explore, EclMenu's WriteGbvm when ECL sets areaKind $70, EclVm's picture mode 2 }
  ORBIT_MAP = 9;
  { EclVm's EclSetPictureMode for picture mode 3: CharHlp draws the exploration frame and the party list without the 3-D
    view, and EclSetPictureMode then shows the mode's picture. MenuCore takes party clicks in it, and SaveLoad's
    LoadGame loads no 3-D map or wall set back for a game saved in it }
  PICTURE_VIEW = 10;
  { Skills' EditSkills while it spends points }
  EDITING_SKILLS = 11;

implementation

end.
