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

unit i_MarkCategory;

interface

type
  ICategory = interface
    ['{B870BAEC-8ADD-4D29-9A9E-B9131C0C5681}']
    function GetName: string; stdcall;
    property Name: string read GetName;

    function IsSame(const ACategory: ICategory): Boolean;
    function IsEqual(const ACategory: ICategory): Boolean;
  end;

  IMarkCategory = interface(ICategory)
    ['{00226B68-9915-41AA-90B7-3F2348E53527}']
    function GetVisible: boolean; stdcall;
    property Visible: boolean read GetVisible;

    function GetAfterScale: integer; stdcall;
    property AfterScale: integer read GetAfterScale;

    function GetBeforeScale: integer; stdcall;
    property BeforeScale: integer read GetBeforeScale;
  end;

implementation

end.