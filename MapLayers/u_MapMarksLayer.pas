unit u_MapMarksLayer;

interface

uses
  GR32,
  GR32_Image,
  i_IUsedMarksConfig,
  i_MarksSimple,
  Ugeofun,
  i_IViewPortState,
  i_ILocalCoordConverter,
  u_MarksDbGUIHelper,
  u_MapLayerBasic;

type
  TMapMarksLayer = class(TMapLayerBasic)
  private
    FConfig: IUsedMarksConfig;
    FConfigStatic: IUsedMarksConfigStatic;
    FMarkDBGUI: TMarksDbGUIHelper;
    FMarksSubset: IMarksSubset;
    procedure OnConfigChange(Sender: TObject);
    function GetMarksSubset: IMarksSubset;
  protected
    procedure DoRedraw; override;
  public
    procedure StartThreads; override;
  public
    constructor Create(
      AParentMap: TImage32;
      AViewPortState: IViewPortState;
      AConfig: IUsedMarksConfig;
      AMarkDBGUI: TMarksDbGUIHelper
    );
    procedure MouseOnMyReg(var APWL: TResObj; xy: TPoint);
  end;

implementation

uses
  ActiveX,
  Types,
  Classes,
  SysUtils,
  t_GeoTypes,
  i_ICoordConverter,
  i_IBitmapLayerProvider,
  u_MapMarksBitmapLayerProviderByMarksSubset,
  u_NotifyEventListener;

{ TMapMarksLayer }

constructor TMapMarksLayer.Create(
  AParentMap: TImage32;
  AViewPortState: IViewPortState;
  AConfig: IUsedMarksConfig;
  AMarkDBGUI: TMarksDbGUIHelper
);
begin
  inherited Create(AParentMap, AViewPortState);
  FConfig := AConfig;
  FMarkDBGUI := AMarkDBGUI;

  LinksList.Add(
    TNotifyEventListener.Create(Self.OnConfigChange),
    FConfig.GetChangeNotifier
  );
end;

procedure TMapMarksLayer.DoRedraw;
var
  VProv: IBitmapLayerProvider;
  VMarksSubset: IMarksSubset;
begin
  inherited;
  FMarksSubset := GetMarksSubset;
  VMarksSubset := FMarksSubset;
  if (VMarksSubset <> nil) and (not VMarksSubset.IsEmpty) then begin
    VProv := TMapMarksBitmapLayerProviderByMarksSubset.Create(VMarksSubset);
    FLayer.BeginUpdate;
    try
      FLayer.Bitmap.DrawMode:=dmBlend;
      FLayer.Bitmap.CombineMode:=cmMerge;
      FLayer.Bitmap.Clear(0);
      VProv.GetBitmapRect(FLayer.Bitmap, BitmapCoordConverter);
    finally
      FLayer.EndUpdate;
      FLayer.Changed;
    end;
  end else begin
    FLayer.BeginUpdate;
    try
      FLayer.Bitmap.Clear(0);
    finally
      FLayer.EndUpdate;
      FLayer.Changed;
    end;
  end;
end;

procedure TMapMarksLayer.MouseOnMyReg(var APWL: TResObj; xy: TPoint);
var
  VLineOnBitmap: TArrayOfDoublePoint;
  VLonLatRect: TDoubleRect;
  VRect: TRect;
  VConverter: ICoordConverter;
  VMarkLonLatRect: TDoubleRect;
  VPixelPos: TDoublePoint;
  VZoom: Byte;
  VMark: IMarkFull;
  VMapRect: TDoubleRect;
  VLocalConverter: ILocalCoordConverter;
  VVisualConverter: ILocalCoordConverter;
  VMarksSubset: IMarksSubset;
  VMarksEnum: IEnumUnknown;
  VSquare:Double;
  i: Cardinal;
begin
  VMarksSubset := FMarksSubset;
  if VMarksSubset <> nil then begin
    if not VMarksSubset.IsEmpty then begin
      VRect.Left := xy.X - 8;
      VRect.Top := xy.Y - 16;
      VRect.Right := xy.X + 8;
      VRect.Bottom := xy.Y + 16;
      VLocalConverter := BitmapCoordConverter;
      VConverter := VLocalConverter.GetGeoConverter;
      VZoom := VLocalConverter.GetZoom;
      VVisualConverter := VisualCoordConverter;
      VMapRect := VVisualConverter.LocalRect2MapRectFloat(VRect);
      VConverter.CheckPixelRectFloat(VMapRect, VZoom);
      VLonLatRect := VConverter.PixelRectFloat2LonLatRect(VMapRect, VZoom);
      VPixelPos := VVisualConverter.LocalPixel2MapPixelFloat(xy);
      VMarksEnum := VMarksSubset.GetEnum;
      while VMarksEnum.Next(1, VMark, @i) = S_OK do begin
        VMarkLonLatRect := VMark.LLRect;
        if((VLonLatRect.Right>VMarkLonLatRect.Left)and(VLonLatRect.Left<VMarkLonLatRect.Right)and
        (VLonLatRect.Bottom<VMarkLonLatRect.Top)and(VLonLatRect.Top>VMarkLonLatRect.Bottom))then begin
          if VMark.IsPoint then begin
            APWL.name:=VMark.name;
            APWL.descr:=VMark.Desc;
            APWL.numid:=IntToStr(VMark.id);
            APWL.find:=true;
            APWL.type_:=ROTpoint;
            exit;
          end else begin
            VLineOnBitmap := VConverter.LonLatArray2PixelArrayFloat(VMark.Points, VZoom);
            if VMark.IsLine then begin
              if PointOnPath(VPixelPos, VLineOnBitmap, (VMark.Scale1 / 2) + 1) then begin
                APWL.name:=VMark.name;
                APWL.descr:=VMark.Desc;
                APWL.numid:=IntToStr(VMark.id);
                APWL.find:=true;
                APWL.type_:=ROTline;
                exit;
              end;
            end else begin
              if (PtInRgn(VLineOnBitmap,VPixelPos)) then begin
                if ((not(APWL.find))or(APWL.S <> 0)) then begin
                  VSquare := PolygonSquare(VLineOnBitmap);
                  if (not APWL.find) or (VSquare<APWL.S) then begin
                    APWL.S:=VSquare;
                    APWL.name:=VMark.name;
                    APWL.descr:=VMark.Desc;
                    APWL.numid:=IntToStr(VMark.id);
                    APWL.find:=true;
                    APWL.type_:=ROTPoly;
                  end;
                end;
              end;
            end;
          end;
        end;
      end;
    end;
  end;
end;

function TMapMarksLayer.GetMarksSubset: IMarksSubset;
var
  VList: TList;
  VConverter: ILocalCoordConverter;
  VZoom: Byte;
  VMapPixelRect: TDoubleRect;
  VLonLatRect: TDoubleRect;
  VGeoConverter: ICoordConverter;
begin
  VList := nil;
  if FConfigStatic.IsUseMarks then begin
    VConverter := BitmapCoordConverter;
    if VConverter <> nil then begin
      VZoom := VConverter.GetZoom;
      if not FConfigStatic.IgnoreCategoriesVisible then begin
        VList := FMarkDBGUI.MarksDB.GetVisibleCateroriesIDList(VZoom);
      end;
      try
        if (VList <> nil) and (VList.Count = 0) then begin
          Result := nil;
        end else begin
          VGeoConverter := VConverter.GetGeoConverter;
          VMapPixelRect := VConverter.GetRectInMapPixelFloat;
          VGeoConverter.CheckPixelRectFloat(VMapPixelRect, VZoom);
          VLonLatRect := VGeoConverter.PixelRectFloat2LonLatRect(VMapPixelRect, VZoom);
          Result := FMarkDBGUI.MarksDB.MarksDb.GetMarksSubset(VLonLatRect, VList, FConfigStatic.IgnoreMarksVisible);
        end;
      finally
        VList.Free;
      end;
    end;
  end else begin
    Result := nil;
  end;
end;

procedure TMapMarksLayer.OnConfigChange(Sender: TObject);
begin
  FConfigStatic := FConfig.GetStatic;
  if FConfigStatic.IsUseMarks then begin
    Redraw;
    Show;
  end else begin
    Hide;
    FMarksSubset := nil;
  end;
end;

procedure TMapMarksLayer.StartThreads;
begin
  inherited;
  OnConfigChange(nil);
end;

end.
