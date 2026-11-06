{ DisplayMapView redraws the picture area for whatever zone 0's areaKind says the party is in: the wilderness big
  picture, the orbit picture, or the 3-D view with its sky, horizon and floor colors. NoopMapView is an empty
  placeholder. }
{$O+,F+,A+}
unit MapView;

interface

{ Redraws the picture area unless the party has been defeated. In CGA mode, once ECL has changed the view colors, it
  maps ECL's horizon and floor color codes to the colors View3D draws the 3-D view's bands with; until then the floor is
  color 8. The 3-D view drops the automap while it is locked or a readout position is shown. }
procedure DisplayMapView;

{ Empty routine with no callers. }
procedure NoopMapView;

implementation

uses Types, C_Map, GDConsts, GDVars, Blit, Portrait, View3D, C_Ifc, C_Area, C_Pic;

procedure DisplayMapView;
var
  { Unused in this version; see the other implementations of this routine. }
  wildernessX: Integer;
  { Unused in this version; see the other implementations of this routine. }
  wildernessY: Integer;

  { The CGA color of the horizon's upper band for ECL's color code; 15 for a code not listed. }
  function HorizonUpperColorOf(colorCode: Byte): Byte;
  begin
    case colorCode of
      $08: HorizonUpperColorOf := 0;
      $41: HorizonUpperColorOf := 0;
      $E8: HorizonUpperColorOf := 15
    else
      HorizonUpperColorOf := 15
    end
  end;

  { The CGA color of the horizon's lower band for ECL's color code; 7 for a code not listed. }
  function HorizonLowerColorOf(colorCode: Byte): Byte;
  begin
    case colorCode of
      $08: HorizonLowerColorOf := 8;
      $41: HorizonLowerColorOf := 7;
      $E8: HorizonLowerColorOf := 7
    else
      HorizonLowerColorOf := 7
    end
  end;

  { The CGA floor color for ECL's color code; 6 for a code not listed. }
  function FloorColorOf(colorCode: Byte): Byte;
  begin
    case colorCode of
      $0B: FloorColorOf := 8;
      $09: FloorColorOf := 6;
      $DB: FloorColorOf := 6;
      $06: FloorColorOf := 1
    else
      FloorColorOf := 6
    end
  end;

begin
  if GDVars.isPartyDefeated then Exit;
  case GDVars.zone0^.areaKind of
    { the wilderness is shown as one big picture }
    C_Area.VENUS_WILDERNESS, C_Area.MARS_WILDERNESS:
      if GDVars.isPortraitPending then Portrait.DisplayBigPic;
    C_Area.ORBIT:
      Portrait.DisplayImageBuf(3, 3, True, 0)
  else begin
      if GDVars.interfaceState <> C_Ifc.VIEW_3D then Exit;
      GDVars.partyPosition.mapEvent := View3D.GetMapEvent(GDVars.partyPosition.mapX, GDVars.partyPosition.mapY);
      if GDVars.partyPosition.mapEvent > $7F then
        GDVars.skyColor := GDConsts.skyColors[GDVars.zone0^.skyIndexHi]
      else
        GDVars.skyColor := GDConsts.skyColors[GDVars.zone0^.skyIndexLo];
      if GDVars.displayMode = Types.VmCga then
        if GDVars.haveViewColorsChanged then begin
          GDVars.horizonColor1 := HorizonUpperColorOf(GDVars.horizonColorCode);
          GDVars.horizonColor2 := HorizonLowerColorOf(GDVars.horizonColorCode);
          GDVars.floorColor := FloorColorOf(GDVars.floorColorCode);
          View3D.SetView3DColors(GDVars.skyColor, GDVars.horizonColor1, GDVars.horizonColor2, GDVars.floorColor)
        end else
          GDVars.floorColor := 8;
      if GDVars.isViewPaletteStale then begin
        Blit.SetDacPalette(C_Pic.WALL_DAC_FIRST, C_Pic.WALL_DAC_COUNT, GDVars.viewPalette);
        GDVars.isViewPaletteStale := False
      end;
      if (GDVars.zone0^.isAutomapLocked <> 0) or
          (GDVars.zone0^.readoutX <> C_Map.NO_READOUT) then GDVars.isAutomapOn := False;
      View3D.Display3DMapView(GDVars.partyPosition.mapX, GDVars.partyPosition.mapY, GDVars.partyPosition.facing)
    end
  end;
  GDVars.isPortraitPending := False
end;

procedure NoopMapView; begin end;

begin
end.
