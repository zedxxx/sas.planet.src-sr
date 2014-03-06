unit u_TileMatrixElement;

interface

uses
  Types,
  SysUtils,
  i_Bitmap32Static,
  i_LocalCoordConverter,
  i_TileMatrix,
  u_BaseInterfacedObject;

type
  TTileMatrixElement = class(TBaseInterfacedObject, ITileMatrixElement)
  private
    FSync: IReadWriteSync;

    FTile: TPoint;
    FLocalConverter: ILocalCoordConverter;

    FReadyID: Integer;
    FExpectedID: Integer;
    FShownID: Integer;
    FBitmap: IBitmap32Static;
  private
    function GetTile: TPoint;
    function GetLocalConverter: ILocalCoordConverter;
    function GetReadyID: Integer;
    function GetExpectedID: Integer;
    function GetShownId: Integer;
    function CheckForShow: Boolean;
    function GetBitmap: IBitmap32Static;

    procedure IncExpectedID;
    procedure UpdateBitmap(
      AID: Integer;
      const ABitmap: IBitmap32Static
    );
  public
    constructor Create(
      const ATile: TPoint;
      const ALocalConverter: ILocalCoordConverter;
      const ABitmap: IBitmap32Static
    );
  end;

implementation

uses
  i_CoordConverter,
  u_Synchronizer;

{ TTileMatrixElement }

constructor TTileMatrixElement.Create(
  const ATile: TPoint;
  const ALocalConverter: ILocalCoordConverter;
  const ABitmap: IBitmap32Static
);
var
  VZoom: Byte;
  VConverter: ICoordConverter;
begin
  inherited Create;
  FTile := ATile;
  FLocalConverter := ALocalConverter;
  FBitmap := ABitmap;
  FSync := MakeSyncRW_Var(Self);
  FReadyID := 0;
  FExpectedID := 1;
  VZoom := FLocalConverter.Zoom;
  VConverter := FLocalConverter.GeoConverter;
  Assert(EqualRect(FLocalConverter.GetRectInMapPixel, VConverter.TilePos2PixelRect(FTile, VZoom)));
end;

function TTileMatrixElement.GetBitmap: IBitmap32Static;
begin
  FSync.BeginRead;
  try
    Result := FBitmap;
  finally
    FSync.EndRead;
  end;
end;

function TTileMatrixElement.GetExpectedID: Integer;
begin
  FSync.BeginRead;
  try
    Result := FExpectedID;
  finally
    FSync.EndRead;
  end;
end;

function TTileMatrixElement.CheckForShow: Boolean;
begin
  FSync.BeginRead;
  try
    Result := FReadyID <> FShownID;
    FShownID := FReadyID;
  finally
    FSync.EndRead;
  end;
end;

function TTileMatrixElement.GetLocalConverter: ILocalCoordConverter;
begin
  Result := FLocalConverter;
end;

function TTileMatrixElement.GetReadyID: Integer;
begin
  FSync.BeginRead;
  try
    Result := FReadyID;
  finally
    FSync.EndRead;
  end;
end;

function TTileMatrixElement.GetShownId: Integer;
begin
  FSync.BeginRead;
  try
    Result := FShownID;
  finally
    FSync.EndRead;
  end;
end;

function TTileMatrixElement.GetTile: TPoint;
begin
  Result := FTile;
end;

procedure TTileMatrixElement.IncExpectedID;
begin
  FSync.BeginWrite;
  try
    Inc(FExpectedID);
  finally
    FSync.EndWrite;
  end;
end;

procedure TTileMatrixElement.UpdateBitmap(
  AID: Integer;
  const ABitmap: IBitmap32Static
);
begin
  FSync.BeginWrite;
  try
    FReadyID := AID;
    FBitmap := ABitmap;
  finally
    FSync.EndWrite;
  end;
end;

end.