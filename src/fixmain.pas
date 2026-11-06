{ The program: Buck Rogers. It initializes the game, shows the title and its menu (D, or no key before the timeout, runs
  the demo), then loops: outside the demo the character menus and the copy protection, then GameLoop and a soft
  reinitialization; after a demo it offers the title menu again. }
{$F+,O+}
program FixMain;

uses
  Overlay, Dos, Crt, EmptyA,
  { the game's data }
  GDConsts, GDVars,
  C_Msg, C_Keys, C_Pic,
  Joystick,
  Mouse,
  GameIo, Music, TextRend, Blit,
  GameBoot,
  Border, Debug, Pathing,
  EmptyC,
  View3D, MapView, MenuCore, CharHlp, FxEngine, Money, GameTime, ViewChar, SaveLoad,
  MapCurs, EclMenu, CharGen, Explore, GameInit, Combat, PostCbt, CopyProt, EclVm,
  Intro,
  HeapErr;

const
  TITLE_QUERY = 'Buck Rogers v1.3 ';
  TITLE_MENU = 'Play Demo';
  { the title menu's demo choice, and its answer on a timeout }
  DEMO_KEY = 'D';
  { ECL1.dax and the other set-1 data files }
  START_DATA_SET = 1;

{$O HeapErr}
{$O Intro}
{$O EclVm}
{$O ShipCbt}
{$O CopyProt}
{$O PostCbt}
{$O Combat}
{$O CombatAi}
{$O CombatSt}
{$O GameInit}
{$O EffHndlr}
{$O CbtActs}
{$O Explore}
{$O CharGen}
{$O Shop}
{$O EclMenu}
{$O MapCurs}
{$O SaveLoad}
{$O ViewChar}
{$O Skills}
{$O GameTime}
{$O Money}
{$O FxEngine}
{$O CharHlp}
{$O OrbitMap}
{$O MenuCore}
{$O MapView}
{$O Portrait}
{$O View3D}
{$O Pathing}
{$O CbtMap}
{$O MapTiles}
{$O Debug}
{$O Sym8x8}

begin
  GDVars.rootScratchPair := 0;
  GameInit.InitializeGame;
  Intro.Introduction;

  GDVars.menuTimeout := 12000;
  GDVars.menuTimeoutKey := DEMO_KEY;
  MenuCore.MenuHorizontal(TITLE_QUERY, TITLE_MENU, False, False);
  GDVars.menuResult := GDVars.menuKey;
  Blit.SetDacPalette(C_Pic.VIEW_DAC_FIRST, C_Pic.VIEW_DAC_COUNT, GDVars.viewPalette);
  GDVars.menuTimeout := 0;
  GDVars.menuTimeoutKey := C_Keys.NONE;
  if GDVars.menuResult = DEMO_KEY then GDVars.isDemoRunning := True;
  repeat
    Music.StopMusic;
    Music.FreeLoadedDriver;

    if GDVars.isDemoRunning then begin
      GDVars.dataSet := START_DATA_SET;
      GDVars.zone0^.messageSpeed := C_Msg.SLOWEST_MESSAGE_SPEED
    end else
      GDVars.dataSet := START_DATA_SET;

    if not GDVars.isDemoRunning then begin
      CharGen.MainMenu;
      if CopyProt.CopyProtection <> True then GameIo.ExitGame;
      for GDVars.protectionIndex := 1 to SizeOf(GDVars.protectionFlags) do
        if GDVars.protectionFlags[GDVars.protectionIndex] = 0 then GameIo.ExitGame;
      CharHlp.DisplayNoncombatInterface
    end;

    View3D.SetView3DColors(GDVars.skyColor, GDVars.horizonColor1, GDVars.horizonColor2, GDVars.floorColor);
    EclVm.GameLoop;
    GameInit.ResetGameState;

    if GDVars.isDemoRunning then begin
      Music.SendSoundCommand(GDConsts.soundDriverOff);
      Intro.Introduction;
      GameIo.FlushKeys;
      GDVars.menuTimeout := 3000;
      GDVars.menuTimeoutKey := DEMO_KEY;
      GDVars.wallSets[0].fileId := 0;
      MenuCore.MenuHorizontal(TITLE_QUERY, TITLE_MENU, False, False);
      GDVars.menuResult := GDVars.menuKey;
      Blit.SetDacPalette(C_Pic.VIEW_DAC_FIRST, C_Pic.VIEW_DAC_COUNT, GDVars.viewPalette);
      GDVars.menuTimeout := 0;
      GDVars.menuTimeoutKey := C_Keys.NONE;
      GDVars.isDemoRunning := GDVars.menuResult = DEMO_KEY;
      Music.SendSoundCommand(GDConsts.silenceSounds)
    end
  until False
end.
