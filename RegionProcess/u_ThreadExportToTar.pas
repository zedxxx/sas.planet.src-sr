unit u_ThreadExportToTar;

interface

uses
  Windows,
  SysUtils,
  Classes,
  TarWriter,
  GR32,
  i_TileFileNameGenerator,
  u_MapType,
  u_ResStrings,
  t_GeoTypes,
  u_ThreadExportAbstract;

type
  TThreadExportToTar = class(TThreadExportAbstract)
  private
    FMapType: TMapType;
    FTileNameGen: ITileFileNameGenerator;

    FTargetFile: string;
    FTar: TTarWriter;
  protected
    procedure ProcessRegion; override;
  public
    constructor Create(
      ATargetFile: string;
      APolygon: TArrayOfDoublePoint;
      Azoomarr: array of boolean;
      AMapType: TMapType;
      ATileNameGen: ITileFileNameGenerator
    );
    destructor Destroy; override;
  end;

implementation

uses
  Variants,
  i_TileIterator,
  i_TileInfoBasic,
  u_TileIteratorStuped,
  u_TileStorageAbstract;

constructor TThreadExportToTar.Create(
  ATargetFile: string;
  APolygon: TArrayOfDoublePoint;
  Azoomarr: array of boolean;
  AMapType: TMapType;
  ATileNameGen: ITileFileNameGenerator);
begin
  inherited Create(APolygon, Azoomarr);
  FTargetFile := ATargetFile;
  FTileNameGen := ATileNameGen;
  FMapType := AMapType;
  FTar := TTarWriter.Create(FTargetFile);
end;

destructor TThreadExportToTar.Destroy;
begin
  inherited;
  FTar.free;
end;

procedure TThreadExportToTar.ProcessRegion;
var
  i: integer;
  VZoom: Byte;
  VExt: string;
  VPath: string;
  VTile: TPoint;
  VTileIterators: array of ITileIterator;
  VTileIterator: ITileIterator;
  VTileStorage: TTileStorageAbstract;
  VMemStream: TMemoryStream;
  VFileTime: TDateTime;
  VTileInfo: ITileInfoBasic;
begin
  inherited;
  FTilesToProcess := 0;
  SetLength(VTileIterators, Length(FZooms));
  for i := 0 to Length(FZooms) - 1 do begin
    VZoom := FZooms[i];
    VTileIterators[i] := TTileIteratorStuped.Create(VZoom, FPolygLL, FMapType.GeoConvert);
    FTilesToProcess := FTilesToProcess + VTileIterators[i].TilesTotal;
  end;
  try
    ProgressFormUpdateCaption(
      SAS_STR_ExportTiles,
      SAS_STR_AllSaves + ' ' + inttostr(FTilesToProcess) + ' ' + SAS_STR_Files
    );
    VMemStream := TMemoryStream.Create;
    try
      VTileStorage := FMapType.TileStorage;
      FTilesProcessed := 0;
      ProgressFormUpdateOnProgress;
      for i := 0 to Length(FZooms) - 1 do begin
        VZoom := FZooms[i];
        VExt := FMapType.TileStorage.TileFileExt;
        VPath := IncludeTrailingPathDelimiter(IncludeTrailingPathDelimiter(FTargetFile) + FMapType.GetShortFolderName);
        VTileIterator := VTileIterators[i];
        while VTileIterator.Next(VTile) do begin
          if IsCancel then begin
            exit;
          end;
          VMemStream.Position := 0;
          VTileInfo := VTileStorage.GetTileInfo(VTile, VZoom, Unassigned);
          if VTileStorage.LoadTile(VTile, VZoom, Unassigned, VMemStream, VTileInfo) then begin
            VFileTime := VTileInfo.GetLoadDate;
            VMemStream.Position := 0;   
            FTar.AddStream(
              VMemStream,
              FTileNameGen.GetTileFileName(VTile, VZoom)+ VTileStorage.GetTileFileExt,
              VFileTime
            );
          end;
          inc(FTilesProcessed);
          if FTilesProcessed mod 100 = 0 then begin
            ProgressFormUpdateOnProgress;
          end;
        end;
      end;
    finally
      VMemStream.Free;
    end;
  finally
    for i := 0 to Length(FZooms) - 1 do begin
      VTileIterators[i] := nil;
    end;
    VTileIterators := nil;
  end;
  ProgressFormUpdateOnProgress;
  FTileNameGen := nil;
end;

end.
