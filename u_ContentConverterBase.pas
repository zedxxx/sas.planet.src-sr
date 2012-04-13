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

unit u_ContentConverterBase;

interface

uses
  i_BinaryData,
  i_ContentTypeInfo,
  i_ContentConverter;

type
  TContentConverterAbstract = class(TInterfacedObject, IContentConverter)
  private
    FSource: IContentTypeInfoBasic;
    FTarget: IContentTypeInfoBasic;
  protected
    function GetSource: IContentTypeInfoBasic;
    function GetTarget: IContentTypeInfoBasic;
    function GetIsSimpleCopy: Boolean; virtual; abstract;
    function Convert(AData: IBinaryData): IBinaryData; virtual; abstract;
  public
    constructor Create(
      ASource: IContentTypeInfoBasic;
      ATarget: IContentTypeInfoBasic
    );
    destructor Destroy; override;
  end;

  TContentConverterBase = class(TContentConverterAbstract)
  protected
    function GetIsSimpleCopy: Boolean; override;
  end;

  TContentConverterSimpleCopy = class(TContentConverterAbstract)
  protected
    function GetIsSimpleCopy: Boolean; override;
    function Convert(AData: IBinaryData): IBinaryData; override;
  end;

implementation

{ TContentConverterAbstract }

constructor TContentConverterAbstract.Create(ASource,
  ATarget: IContentTypeInfoBasic);
begin
  FSource := ASource;
  FTarget := ATarget;
end;

destructor TContentConverterAbstract.Destroy;
begin
  FSource := nil;
  FTarget := nil;
  inherited;
end;

function TContentConverterAbstract.GetSource: IContentTypeInfoBasic;
begin
  Result := FSource;
end;

function TContentConverterAbstract.GetTarget: IContentTypeInfoBasic;
begin
  Result := FTarget;
end;

{ TContentConverterBase }

function TContentConverterBase.GetIsSimpleCopy: Boolean;
begin
  Result := False;
end;

{ TContentConverterSimpleCopy }

function TContentConverterSimpleCopy.Convert(AData: IBinaryData): IBinaryData;
begin
  Result := AData;
end;

function TContentConverterSimpleCopy.GetIsSimpleCopy: Boolean;
begin
  Result := True;
end;

end.
