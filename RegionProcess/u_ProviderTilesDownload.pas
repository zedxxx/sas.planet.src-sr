{******************************************************************************}
{* SAS.Planet (SAS.�������)                                                   *}
{* Copyright (C) 2007-2012, SAS.Planet development team.                      *}
{* This program is free software: you can redistribute it and/or modify       *}
{* it under the terms of the GNU General Public License as published by       *}
{* the Free Software Foundation, either version 3 of the License, or          *}
{* (at your option) any later version.                                        *}
{*                                                                            *}
{* This program is distributed in the hope that it will be useful,            *}
{* but WITHOUT ANY WARRANTY; without even the implied warranty of             *}
{* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              *}
{* GNU General Public License for more details.                               *}
{*                                                                            *}
{* You should have received a copy of the GNU General Public License          *}
{* along with this program.  If not, see <http://www.gnu.org/licenses/>.      *}
{*                                                                            *}
{* http://sasgis.ru                                                           *}
{* az@sasgis.ru                                                               *}
{******************************************************************************}

unit u_ProviderTilesDownload;

interface

uses
  Types,
  Forms,
  i_NotifierOperation,
  i_MapTypeSet,
  i_GeometryLonLat,
  i_GeometryLonLatFactory,
  i_VectorGeometryProjectedFactory,
  i_CoordConverterFactory,
  i_LanguageManager,
  i_ActiveMapsConfig,
  i_MapTypeGUIConfigList,
  i_ValueToStringConverter,
  i_GlobalDownloadConfig,
  i_DownloadInfoSimple,
  i_RegionProcessProgressInfoInternalFactory,
  u_MapType,
  u_ExportProviderAbstract,
  fr_TilesDownload;

type
  TProviderTilesDownload = class(TExportProviderAbstract)
  private
    FAppClosingNotifier: INotifierOneOperation;
    FValueToStringConverterConfig: IValueToStringConverterConfig;
    FDownloadConfig: IGlobalDownloadConfig;
    FDownloadInfo: IDownloadInfoSimple;
    FProjectionFactory: IProjectionInfoFactory;
    FVectorGeometryProjectedFactory: IVectorGeometryProjectedFactory;
    FVectorGeometryLonLatFactory: IGeometryLonLatFactory;
  protected
    function CreateFrame: TFrame; override;
  public
    constructor Create(
      const AAppClosingNotifier: INotifierOneOperation;
      const AProgressFactory: IRegionProcessProgressInfoInternalFactory;
      const ALanguageManager: ILanguageManager;
      const AValueToStringConverterConfig: IValueToStringConverterConfig;
      const AMainMapsConfig: IMainMapsConfig;
      const AFullMapsSet: IMapTypeSet;
      const AGUIConfigList: IMapTypeGUIConfigList;
      const AProjectionFactory: IProjectionInfoFactory;
      const AVectorGeometryLonLatFactory: IGeometryLonLatFactory;
      const AVectorGeometryProjectedFactory: IVectorGeometryProjectedFactory;
      const ADownloadConfig: IGlobalDownloadConfig;
      const ADownloadInfo: IDownloadInfoSimple
    );
    function GetCaption: string; override;
    procedure StartProcess(const APolygon: IGeometryLonLatMultiPolygon); override;
    procedure StartBySLS(const AFileName: string);
  end;


implementation

uses
  Classes,
  SysUtils,
  IniFiles,
  i_VectorItemProjected,
  i_ConfigDataProvider,
  i_MapTypes,
  i_ProjectionInfo,
  i_RegionProcessParamsFrame,
  i_LogSimple,
  i_LogSimpleProvider,
  i_MapVersionInfo,
  u_ConfigDataProviderByIniFile,
  u_LogForTaskThread,
  u_ThreadDownloadTiles,
  u_ConfigProviderHelpers,
  u_RegionProcessProgressInfoDownload,
  u_Notifier,
  u_NotifierOperation,
  u_DownloadInfoSimple,
  frm_ProgressDownload,
  u_ResStrings;

{ TProviderTilesDownload }

constructor TProviderTilesDownload.Create(
  const AAppClosingNotifier: INotifierOneOperation;
  const AProgressFactory: IRegionProcessProgressInfoInternalFactory;
  const ALanguageManager: ILanguageManager;
  const AValueToStringConverterConfig: IValueToStringConverterConfig;
  const AMainMapsConfig: IMainMapsConfig;
  const AFullMapsSet: IMapTypeSet;
  const AGUIConfigList: IMapTypeGUIConfigList;
  const AProjectionFactory: IProjectionInfoFactory;
  const AVectorGeometryLonLatFactory: IGeometryLonLatFactory;
  const AVectorGeometryProjectedFactory: IVectorGeometryProjectedFactory;
  const ADownloadConfig: IGlobalDownloadConfig;
  const ADownloadInfo: IDownloadInfoSimple
);
begin
  inherited Create(
    AProgressFactory,
    ALanguageManager,
    AMainMapsConfig,
    AFullMapsSet,
    AGUIConfigList
  );
  FAppClosingNotifier := AAppClosingNotifier;
  FValueToStringConverterConfig := AValueToStringConverterConfig;
  FProjectionFactory := AProjectionFactory;
  FVectorGeometryLonLatFactory := AVectorGeometryLonLatFactory;
  FVectorGeometryProjectedFactory := AVectorGeometryProjectedFactory;
  FDownloadConfig := ADownloadConfig;
  FDownloadInfo := ADownloadInfo;
end;

function TProviderTilesDownload.CreateFrame: TFrame;
begin
  Result :=
    TfrTilesDownload.Create(
      Self.LanguageManager,
      FProjectionFactory,
      FVectorGeometryProjectedFactory,
      Self.MainMapsConfig,
      Self.FullMapsSet,
      Self.GUIConfigList
    );
  Assert(Supports(Result, IRegionProcessParamsFrameOneMap));
  Assert(Supports(Result, IRegionProcessParamsFrameOneZoom));
  Assert(Supports(Result, IRegionProcessParamsFrameTilesDownload));
end;

function TProviderTilesDownload.GetCaption: string;
begin
  Result := SAS_STR_OperationDownloadCaption;
end;

procedure TProviderTilesDownload.StartBySLS(const AFileName: string);
var
  VIniFile: TMemIniFile;
  VSLSData: IConfigDataProvider;
  VSessionSection: IConfigDataProvider;
  VLog: TLogSimpleProvider;
  VLogSimple: ILogSimple;
  VLogProvider: ILogSimpleProvider;
  VForm: TfrmProgressDownload;
  VCancelNotifierInternal: INotifierOperationInternal;
  VOperationID: Integer;
  VProgressInfo: TRegionProcessProgressInfoDownload;
  VGuids: string;
  VGuid: TGUID;
  VMap: IMapType;
  VZoom: Byte;
  VReplaceExistTiles: Boolean;
  VCheckExistTileSize: Boolean;
  VCheckExistTileDate: Boolean;
  VCheckTileDate: TDateTime;
  VProcessedTileCount: Int64;
  VProcessedSize: Int64;
  VSecondLoadTNE: Boolean;
  VLastProcessedPoint: TPoint;
  VElapsedTime: TDateTime;
  VMapType: TMapType;
  VPolygon: IGeometryLonLatMultiPolygon;
  VProjection: IProjectionInfo;
  VProjectedPolygon: IProjectedPolygon;
  VVersionForDownload: IMapVersionInfo;
  VVersionForCheck: IMapVersionInfo;
  VVersionString: string;
  VVersionCheckShowPrev: Boolean;
begin
  VIniFile := TMemIniFile.Create(AFileName);
  try
    VSLSData := TConfigDataProviderByIniFile.CreateWithOwn(VIniFile);
    VIniFile := nil;
  finally
    VIniFile.Free;
  end;
  VSessionSection := VSLSData.GetSubItem('Session');
  VLog := TLogSimpleProvider.Create(5000, 0);
  VLogSimple := VLog;
  VLogProvider := VLog;
  VCancelNotifierInternal := TNotifierOperation.Create(TNotifierBase.Create);
  VOperationID := VCancelNotifierInternal.CurrentOperation;

  VReplaceExistTiles := False;
  VCheckExistTileSize := False;
  VCheckExistTileDate := False;
  VCheckTileDate := Now;
  VSecondLoadTNE := False;
  VElapsedTime := 0;
  VProcessedTileCount := 0;
  if VSessionSection = nil then begin
    raise Exception.Create('No SLS data');
  end;
  VGuids := VSessionSection.ReadString('MapGUID', '');
  if VGuids = '' then begin
    raise Exception.Create('Map GUID is empty');
  end;
  VGuid := StringToGUID(VGuids);
  VMap := FullMapsSet.GetMapTypeByGUID(VGuid);
  if VMap = nil then begin
    raise Exception.CreateFmt('Map with GUID = %s not found', [VGuids]);
  end else begin
    VMapType := VMap.MapType;
    if not VMapType.GeoConvert.CheckZoom(VZoom) then begin
      raise Exception.Create('Unknown zoom');
    end;
  end;
  VVersionString := VSessionSection.ReadString('VersionDownload', '');
  if VVersionString <> '' then begin
    VVersionForDownload :=
      VMapType.VersionConfig.VersionFactory.CreateByStoreString(
        VVersionString
      );
  end else begin
    VVersionForDownload := VMapType.VersionConfig.Version;
  end;
  VVersionString := VSessionSection.ReadString('VersionCheck', '');
  if VVersionString <> '' then begin
    VVersionCheckShowPrev := VSessionSection.ReadBool('VersionCheckPrev', False);
    VVersionForCheck :=
      VMapType.VersionConfig.VersionFactory.CreateByStoreString(
        VVersionString,
        VVersionCheckShowPrev
      );
  end else begin
    VVersionForDownload := VVersionForDownload;
  end;
  VZoom := VSessionSection.ReadInteger('Zoom', 0);
  if VZoom > 0 then begin
    Dec(VZoom);
  end else begin
    raise Exception.Create('Unknown zoom');
  end;
  VReplaceExistTiles := VSessionSection.ReadBool('ReplaceExistTiles', VReplaceExistTiles);
  VCheckExistTileSize := VSessionSection.ReadBool('CheckExistTileSize', VCheckExistTileSize);
  VCheckExistTileDate := VSessionSection.ReadBool('CheckExistTileDate', VCheckExistTileDate);
  VCheckTileDate := VSessionSection.ReadDate('CheckTileDate', VCheckTileDate);
  VProcessedTileCount := VSessionSection.ReadInteger('ProcessedTileCount', VProcessedTileCount);
  VProcessedSize := trunc(VSessionSection.ReadFloat('ProcessedSize', 0) * 1024);

  VSecondLoadTNE := VSessionSection.ReadBool('SecondLoadTNE', VSecondLoadTNE);
  VElapsedTime := VSessionSection.ReadFloat('ElapsedTime', VElapsedTime);
  if FDownloadConfig.IsUseSessionLastSuccess then begin
    VLastProcessedPoint.X := VSessionSection.ReadInteger('LastSuccessfulStartX', -1);
    VLastProcessedPoint.Y := VSessionSection.ReadInteger('LastSuccessfulStartY', -1);
  end else begin
    VLastProcessedPoint.X := VSessionSection.ReadInteger('StartX', -1);
    VLastProcessedPoint.Y := VSessionSection.ReadInteger('StartY', -1);
  end;
  VPolygon := ReadPolygon(VSessionSection, FVectorGeometryLonLatFactory);
  if VPolygon.Count > 0 then begin
    VProjection :=
      FProjectionFactory.GetByConverterAndZoom(
        VMapType.GeoConvert,
        VZoom
      );
    VProjectedPolygon :=
      FVectorGeometryProjectedFactory.CreateProjectedPolygonByLonLatPolygon(
        VProjection,
        VPolygon
      );
  end else begin
    raise Exception.Create('Empty polygon');
  end;
  VProgressInfo :=
    TRegionProcessProgressInfoDownload.Create(
      VLogSimple,
      VLogProvider,
      VGuid,
      VVersionForCheck,
      VVersionForDownload,
      VZoom,
      VPolygon,
      VSecondLoadTNE,
      VReplaceExistTiles,
      VCheckExistTileSize,
      VCheckExistTileDate,
      VCheckTileDate,
      False,
      VProcessedSize,
      VProcessedTileCount,
      VLastProcessedPoint,
      VElapsedTime
    );
  VForm := TfrmProgressDownload.Create(
    LanguageManager,
    FValueToStringConverterConfig,
    VCancelNotifierInternal,
    VProgressInfo
  );
  Application.ProcessMessages;
  VForm.Show;

  if not VCancelNotifierInternal.IsOperationCanceled(VOperationID) then begin
    TThreadDownloadTiles.Create(
      VCancelNotifierInternal,
      VOperationID,
      VProgressInfo,
      FAppClosingNotifier,
      VMapType,
      VVersionForCheck,
      VVersionForDownload,
      VZoom,
      VProjectedPolygon,
      FDownloadConfig,
      TDownloadInfoSimple.Create(FDownloadInfo, VProcessedTileCount, VProcessedSize),
      VReplaceExistTiles,
      VCheckExistTileSize,
      VCheckExistTileDate,
      VCheckTileDate,
      VSecondLoadTNE,
      VLastProcessedPoint,
      VElapsedTime
    );
  end;
end;

procedure TProviderTilesDownload.StartProcess(const APolygon: IGeometryLonLatMultiPolygon);
var
  VMapType: TMapType;
  VZoom: byte;
  VLog: TLogSimpleProvider;
  VLogSimple: ILogSimple;
  VLogProvider: ILogSimpleProvider;
  VProjectedPolygon: IProjectedPolygon;
  VForm: TfrmProgressDownload;
  VCancelNotifierInternal: INotifierOperationInternal;
  VOperationID: Integer;
  VProgressInfo: TRegionProcessProgressInfoDownload;
  VThread: TThread;
begin
  VMapType := (ParamsFrame as IRegionProcessParamsFrameOneMap).MapType;
  VZoom := (ParamsFrame as IRegionProcessParamsFrameOneZoom).Zoom;

  VProjectedPolygon :=
    FVectorGeometryProjectedFactory.CreateProjectedPolygonByLonLatPolygon(
      FProjectionFactory.GetByConverterAndZoom(VMapType.GeoConvert, VZoom),
      APolygon
    );
  VLog := TLogSimpleProvider.Create(5000, 0);
  VLogSimple := VLog;
  VLogProvider := VLog;
  VCancelNotifierInternal := TNotifierOperation.Create(TNotifierBase.Create);
  VOperationID := VCancelNotifierInternal.CurrentOperation;

  VProgressInfo :=
    TRegionProcessProgressInfoDownload.Create(
      VLogSimple,
      VLogProvider,
      VMapType.Zmp.GUID,
      VMapType.VersionConfig.Version,
      VMapType.VersionConfig.Version,
      VZoom,
      APolygon,
      (ParamsFrame as IRegionProcessParamsFrameTilesDownload).IsIgnoreTne,
      (ParamsFrame as IRegionProcessParamsFrameTilesDownload).IsReplace,
      (ParamsFrame as IRegionProcessParamsFrameTilesDownload).IsReplaceIfDifSize,
      (ParamsFrame as IRegionProcessParamsFrameTilesDownload).IsReplaceIfOlder,
      (ParamsFrame as IRegionProcessParamsFrameTilesDownload).ReplaceDate,
      (ParamsFrame as IRegionProcessParamsFrameTilesDownload).IsStartPaused,
      0,
      0,
      Point(-1, -1),
      0
    );
  VForm := TfrmProgressDownload.Create(
    LanguageManager,
    FValueToStringConverterConfig,
    VCancelNotifierInternal,
    VProgressInfo
  );
  Application.ProcessMessages;
  VForm.Show;

  if not VCancelNotifierInternal.IsOperationCanceled(VOperationID) then begin
    VThread :=
      TThreadDownloadTiles.Create(
        VCancelNotifierInternal,
        VOperationID,
        VProgressInfo,
        FAppClosingNotifier,
        VMapType,
        VMapType.VersionConfig.Version,
        VMapType.VersionConfig.Version,
        VZoom,
        VProjectedPolygon,
        FDownloadConfig,
        TDownloadInfoSimple.Create(FDownloadInfo),
        (ParamsFrame as IRegionProcessParamsFrameTilesDownload).IsReplace,
        (ParamsFrame as IRegionProcessParamsFrameTilesDownload).IsReplaceIfDifSize,
        (ParamsFrame as IRegionProcessParamsFrameTilesDownload).IsReplaceIfOlder,
        (ParamsFrame as IRegionProcessParamsFrameTilesDownload).ReplaceDate,
        (ParamsFrame as IRegionProcessParamsFrameTilesDownload).IsIgnoreTne,
        Point(-1, -1),
        0
      );
    VThread.Resume;
  end;
end;

end.


