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

unit u_CommonFormAndFrameParents;

interface

uses
  Classes,
  Forms,
  i_JclNotify,
  i_LanguageManager;

type
  TCommonFormParent = class(TForm)
  public
    constructor Create(AOwner : TComponent); override;
    procedure RefreshTranslation; virtual;
  end;

  TFormWitghLanguageManager = class(TForm)
  private
    FLanguageChangeListener: IJclListener;
    FLanguageManager: ILanguageManager;
    procedure OnLangChange;
  protected
    procedure RefreshTranslation; virtual;
  public
    constructor Create(ALanguageManager: ILanguageManager); reintroduce;
    destructor Destroy; override;
  end;

  TCommonFrameParent = class(Forms.TFrame)
  public
    constructor Create(AOwner : TComponent); override;
    procedure RefreshTranslation; virtual;
  end;

  TFrame = class(TCommonFrameParent);

implementation

uses
  gnugettext,
  u_NotifyEventListener;

{ TCommonFormParent }

constructor TCommonFormParent.Create(AOwner: TComponent);
begin
  inherited;
  TranslateComponent(self);
end;

procedure TCommonFormParent.RefreshTranslation;
begin
  ReTranslateComponent(self);
end;

{ TFrame }

constructor TCommonFrameParent.Create(AOwner: TComponent);
begin
  inherited;
  if (Owner = Application) or (Owner = nil) then begin
    TranslateComponent(self);
  end;
end;

procedure TCommonFrameParent.RefreshTranslation;
begin
  if (Owner = Application) or (Owner = nil) then begin
    ReTranslateComponent(self);
  end;
end;

{ TFormWitghLanguageManager }

constructor TFormWitghLanguageManager.Create(
  ALanguageManager: ILanguageManager);
begin
  inherited Create(nil);
  TranslateComponent(self);
  FLanguageManager := ALanguageManager;
  FLanguageChangeListener := TNotifyNoMmgEventListener.Create(Self.OnLangChange);
  FLanguageManager.ChangeNotifier.Add(FLanguageChangeListener);
end;

destructor TFormWitghLanguageManager.Destroy;
begin
  FLanguageManager.ChangeNotifier.Remove(FLanguageChangeListener);
  FLanguageChangeListener := nil;
  FLanguageManager := nil;

  inherited;
end;

procedure TFormWitghLanguageManager.OnLangChange;
begin
  RefreshTranslation;
end;

procedure TFormWitghLanguageManager.RefreshTranslation;
begin
  ReTranslateComponent(self);
end;

end.
