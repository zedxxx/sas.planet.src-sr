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

unit i_MapCalibration;

interface

uses
  Types,
  i_CoordConverter;

type
  IMapCalibration = interface
    ['{08085422-4267-49EC-913C-3A47866A46E9}']
    // ��� ��� ������ � ��������� ��� ������ ��� ��������.
    function GetName: WideString; safecall;
    // ����� ��������� �������� ��������
    function GetDescription: WideString; safecall;
    // ���������� �������� ��� ��������� �����.
    procedure SaveCalibrationInfo(
      const AFileName: WideString;
      const xy1, xy2: TPoint;
      Azoom: byte;
      const AConverter: ICoordConverter
    ); safecall;
  end;

  IMapCalibrationList = interface
    ['{9D1740E4-498E-4A5E-B722-C929DB6C759B}']
    function GetCount: Integer;
    property Count: Integer read GetCount;

    function Get(AIndex: Integer): IMapCalibration;
    property Items[Index: Integer]: IMapCalibration read Get; default;
  end;

implementation

end.
