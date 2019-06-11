{******************************************************************************}
{* SAS.Planet (SAS.�������)                                                   *}
{* Copyright (C) 2007-2019, SAS.Planet development team.                      *}
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
{* http://sasgis.org                                                          *}
{* info@sasgis.org                                                            *}
{******************************************************************************}

unit u_SearchBackgroundTask;

interface

uses
  Classes,
  SysUtils,
  i_GeoCoder,
  i_BackgroundTask,
  i_NotifierOperation,
  i_SearchBackgroundTask,
  i_LocalCoordConverterChangeable,
  u_BaseInterfacedObject;

type
  TSearchBackgroundTask = class(TBaseInterfacedObject, ISearchBackgroundTask)
  private
    type
      TTaskStatus = (tsWhait, tsBusy, tsReady);
      TTaskRec = record
        Data: Pointer;
        OnResult: TOnSearchTaskResult;
        Status: TTaskStatus;
        Result: IGeoCodeResult;
      end;
      PTaskRec = ^TTaskRec;
  private
    FLock: IReadWriteSync;
    FTasks: TList;
    FWorker: IBackgroundTask;

    FAppClosingNotifier: INotifierOneOperation;
    FCoordConverter: ILocalCoordConverterChangeable;

    procedure OnExec(
      AOperationID: Integer;
      const ACancelNotifier: INotifierOperation
    );
    procedure OnResultSync;
    procedure ClearTasksList;
  private
    { ISearchBackgroundTask }
    procedure Run(
      const ATaskData: PSearchTaskData;
      const AOnTaskResult: TOnSearchTaskResult
    );
  public
    constructor Create(
      const AAppClosingNotifier: INotifierOneOperation;
      const ACoordConverter: ILocalCoordConverterChangeable
    );
    destructor Destroy; override;
  end;

implementation

uses
  i_ThreadConfig,
  u_BackgroundTask,
  u_ThreadConfig,
  u_NotifierOperation,
  u_Synchronizer;

{ TSearchBackgroundTask }

constructor TSearchBackgroundTask.Create(
  const AAppClosingNotifier: INotifierOneOperation;
  const ACoordConverter: ILocalCoordConverterChangeable
);
begin
  inherited Create;

  FAppClosingNotifier := AAppClosingNotifier;
  FCoordConverter := ACoordConverter;

  FLock := GSync.SyncStd.Make(Self.ClassName);

  FTasks := TList.Create;
end;

destructor TSearchBackgroundTask.Destroy;
begin
  ClearTasksList;
  FTasks.Free;
  inherited Destroy;
end;

procedure TSearchBackgroundTask.ClearTasksList;
var
  I: Integer;
  VItem: PTaskRec;
begin
  FLock.BeginWrite;
  try
    for I := 0 to FTasks.Count - 1 do begin
      VItem := FTasks.Items[I];
      if VItem <> nil then begin
        Dispose(VItem);
      end;
    end;
    FTasks.Clear;
  finally
    FLock.EndWrite;
  end;
end;

procedure TSearchBackgroundTask.OnExec(
  AOperationID: Integer;
  const ACancelNotifier: INotifierOperation
);
var
  I: Integer;
  VItem: PTaskRec;
  VData: PSearchTaskData;
begin
  FLock.BeginRead;
  try
    VItem := nil;

    for I := 0 to FTasks.Count - 1 do begin
      VItem := FTasks.Items[I];
      if (VItem <> nil) and (VItem.Status = tsWhait) then begin
        VItem.Status := tsBusy;
        Break;
      end else begin
        VItem := nil;
      end;
    end;

    if VItem = nil then begin
      Exit;
    end;
  finally
    FLock.EndRead;
  end;

  try
    if not ACancelNotifier.IsOperationCanceled(AOperationID) then begin
      VData := VItem.Data;
      if (VData <> nil) and (VData.GeoCoder <> nil) then begin
        VItem.Result :=
          VData.GeoCoder.GetLocations(
            VData.CancelNotifier,
            VData.OperationID,
            VData.Text,
            FCoordConverter.GetStatic
          );
      end;
    end;
  finally
    VItem.Status := tsReady;
    TThread.Synchronize(nil, OnResultSync);
  end;
end;

procedure TSearchBackgroundTask.OnResultSync;
var
  I: Integer;
  VItem: PTaskRec;
begin
  FLock.BeginWrite;
  try
    for I := FTasks.Count - 1 downto 0 do begin
      VItem := FTasks.Items[I];
      if (VItem <> nil) and (VItem.Status = tsReady) then begin
        try
          VItem.OnResult(VItem.Data, VItem.Result);
        finally
          Dispose(VItem);
          FTasks.Delete(I);
        end;
      end;
    end;
  finally
    FLock.EndWrite;
  end;
end;

procedure TSearchBackgroundTask.Run(
  const ATaskData: PSearchTaskData;
  const AOnTaskResult: TOnSearchTaskResult
);
var
  VItem: PTaskRec;
begin
  if (ATaskData = nil) or not Assigned(AOnTaskResult) then begin
    Assert(False);
    Exit;
  end;

  if not Assigned(FWorker) then begin
    FWorker :=
      TBackgroundTask.Create(
        FAppClosingNotifier,
        Self.OnExec,
        TThreadConfig.Create(tpNormal) as IThreadConfig,
        Self.ClassName
      );
    FWorker.Start;
  end;

  New(VItem);

  VItem.Data := ATaskData;
  VItem.OnResult := AOnTaskResult;
  VItem.Result := nil;
  VItem.Status := tsWhait;

  FLock.BeginWrite;
  try
    FTasks.Add(VItem);
  finally
    FLock.EndWrite;
  end;

  FWorker.StartExecute;
end;

end.
