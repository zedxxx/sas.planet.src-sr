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

unit i_MainFormConfig;

interface

uses
  i_Bitmap32Static,
  i_ConfigDataElement,
  i_ActiveMapsConfig,
  i_ViewPortState,
  i_NavigationToPoint,
  i_MainFormBehaviourByGPSConfig,
  i_MainGeoCoderConfig,
  i_KeyMovingConfig,
  i_MapMovingConfig,
  i_MapZoomingConfig,
  i_DownloadUIConfig,
  i_WindowPositionConfig,
  i_LastSearchResultConfig,
  i_MainFormLayersConfig;

type
  IMainFormMainConfig = interface(IConfigDataElement)
    ['{5388E4B8-801A-445F-BF07-DE520A5AFA06}']
    function GetShowMapName: Boolean;
    procedure SetShowMapName(AValue: Boolean);
    property ShowMapName: Boolean read GetShowMapName write SetShowMapName;

    function GetDisableZoomingByMouseScroll: Boolean;
    procedure SetDisableZoomingByMouseScroll(AValue: Boolean);
    property DisableZoomingByMouseScroll: Boolean read GetDisableZoomingByMouseScroll write SetDisableZoomingByMouseScroll;

    //������������� ����������� ��� ���� ������� �����
    function GetMouseScrollInvert: Boolean;
    procedure SetMouseScrollInvert(AValue: Boolean);
    property MouseScrollInvert: Boolean read GetMouseScrollInvert write SetMouseScrollInvert;

    function GetUseNewMainLayer: Boolean;
    property UseNewMainLayer: Boolean read GetUseNewMainLayer;

    // ���������� ����� ��� ���������� ���� ��� ������
    function GetShowHintOnMarks: Boolean;
    procedure SetShowHintOnMarks(AValue: Boolean);
    property ShowHintOnMarks: Boolean read GetShowHintOnMarks write SetShowHintOnMarks;

    function GetShowHintOnlyInMapMoveMode: Boolean;
    procedure SetShowHintOnlyInMapMoveMode(AValue: Boolean);
    property ShowHintOnlyInMapMoveMode: Boolean read GetShowHintOnlyInMapMoveMode write SetShowHintOnlyInMapMoveMode;

    function GetMagnetDraw: Boolean;
    procedure SetMagnetDraw(AValue: Boolean);
    property MagnetDraw: Boolean read GetMagnetDraw write SetMagnetDraw;

    function GetRuller: IBitmap32Static;
    property Ruller: IBitmap32Static read GetRuller;

    function GetTumbler: IBitmap32Static;
    property Tumbler: IBitmap32Static read GetTumbler;
  end;

  IMainWindowToolbarsLock = interface(IConfigDataElement)
    ['{CA2386E9-10BE-4A7C-AE42-3E771BD390BA}']
    function GetIsLock: Boolean;
    procedure SetLock(AValue: Boolean);
  end;

  IMainFormConfig = interface(IConfigDataElement)
    ['{87184149-7B22-4184-A0BF-703C0C89B3AB}']
    function GetMainConfig: IMainFormMainConfig;
    property MainConfig: IMainFormMainConfig read GetMainConfig;

    function GetLayersConfig: IMainFormLayersConfig;
    property LayersConfig: IMainFormLayersConfig read GetLayersConfig;

    function GetToolbarsLock: IMainWindowToolbarsLock;
    property ToolbarsLock: IMainWindowToolbarsLock read GetToolbarsLock;

    function GetNavToPoint: INavigationToPoint;
    property NavToPoint: INavigationToPoint read GetNavToPoint;

    function GetGPSBehaviour: IMainFormBehaviourByGPSConfig;
    property GPSBehaviour: IMainFormBehaviourByGPSConfig read GetGPSBehaviour;

    function GetMainGeoCoderConfig: IMainGeoCoderConfig;
    property MainGeoCoderConfig: IMainGeoCoderConfig read GetMainGeoCoderConfig;

    function GetMainMapsConfig: IMainMapsConfig;
    property MainMapsConfig: IMainMapsConfig read GetMainMapsConfig;

    function GetViewPortState: IViewPortState;
    property ViewPortState: IViewPortState read GetViewPortState;

    function GetDownloadUIConfig: IDownloadUIConfig;
    property DownloadUIConfig: IDownloadUIConfig read GetDownloadUIConfig;

    function GetKeyMovingConfig: IKeyMovingConfig;
    property KeyMovingConfig: IKeyMovingConfig read GetKeyMovingConfig;

    function GetMapZoomingConfig: IMapZoomingConfig;
    property MapZoomingConfig: IMapZoomingConfig read GetMapZoomingConfig;

    function GetMapMovingConfig: IMapMovingConfig;
    property MapMovingConfig: IMapMovingConfig read GetMapMovingConfig;

    function GetLastSearchResultConfig: ILastSearchResultConfig;
    property LastSearchResultConfig: ILastSearchResultConfig read GetLastSearchResultConfig;

    function GetMarksExplorerWindowConfig: IWindowPositionConfig;
    property MarksExplorerWindowConfig: IWindowPositionConfig read GetMarksExplorerWindowConfig;
  end;

implementation

end.
