{******************************************************************************}
{* SAS.Planet (SAS.�������)                                                   *}
{* Copyright (C) 2007-2011, SAS.Planet development team.                      *}
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

unit u_MainMemCacheConfig;

interface

uses
  i_ConfigDataProvider,
  i_ConfigDataWriteProvider,
  i_MainMemCacheConfig,
  u_ConfigDataElementBase;

type
  TMainMemCacheConfig = class(TConfigDataElementBase, IMainMemCacheConfig)
  private
    FMaxSize: Integer;
  protected
    procedure DoReadConfig(AConfigData: IConfigDataProvider); override;
    procedure DoWriteConfig(AConfigData: IConfigDataWriteProvider); override;
  protected
    function GetMaxSize: Integer;
    procedure SetMaxSize(AValue: Integer);
  public
    constructor Create;
  end;

implementation

{ TMainMemCacheConfig }

constructor TMainMemCacheConfig.Create;
begin
  inherited;
  FMaxSize := 150;
end;

procedure TMainMemCacheConfig.DoReadConfig(AConfigData: IConfigDataProvider);
begin
  inherited;
  if AConfigData <> nil then begin
    SetMaxSize(AConfigData.ReadInteger('MainMemCacheSize', FMaxSize));
  end;
end;

procedure TMainMemCacheConfig.DoWriteConfig(
  AConfigData: IConfigDataWriteProvider);
begin
  inherited;
  AConfigData.WriteInteger('MainMemCacheSize', FMaxSize);
end;

function TMainMemCacheConfig.GetMaxSize: Integer;
begin
  LockRead;
  try
    Result := FMaxSize;
  finally
    UnlockRead;
  end;
end;

procedure TMainMemCacheConfig.SetMaxSize(AValue: Integer);
var
  VMaxSize: Integer;
begin
  VMaxSize := AValue;
  if VMaxSize < 0 then begin
    VMaxSize := 0;
  end;
  LockWrite;
  try
    if FMaxSize <> VMaxSize then begin
      FMaxSize := VMaxSize;
      SetChanged;
    end;
  finally
    UnlockWrite;
  end;
end;

end.
