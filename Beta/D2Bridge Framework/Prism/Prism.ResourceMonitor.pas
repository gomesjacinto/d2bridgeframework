{
 +--------------------------------------------------------------------------+
  D2Bridge Framework Content

  Author: Alisson Suart
  Email: alissonsuart@gmail.com

  This source code is distributed under the terms of the
  GNU Lesser General Public License (LGPL) version 2.1.

  This library is free software; you can redistribute it and/or modify it
  under the terms of the GNU Lesser General Public License as published by
  the Free Software Foundation; either version 2.1 of the License, or
  (at your option) any later version.

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
  GNU Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General Public License
  along with this library; if not, see <https://www.gnu.org/licenses/>.

  If you use this software in a product, an acknowledgment in the product
  documentation would be appreciated but is not required.

  God bless you
 +--------------------------------------------------------------------------+
}

{$I ..\D2Bridge.inc}

unit Prism.ResourceMonitor;

interface

uses
  Classes, SysUtils
{$IFDEF MSWINDOWS}
  , Windows, TlHelp32, PsAPI, Generics.Collections
{$ENDIF}
  ;

type
  TPrismResourceMonitor = class
  private
    FEnabled: Boolean;
    FIntervalSeconds: Integer;
    FTopProcessCount: Integer;
    FCPUAlertPercent: Integer;
    FMemoryAlertMB: UInt64;
{$IFDEF MSWINDOWS}
    FCurrentPID: Cardinal;
    FLastSystemTime: UInt64;
    FConsoleLastSystemTime: UInt64;
    FConsoleLastProcessTime: UInt64;
    FLastProcessTimes: TDictionary<Cardinal, UInt64>;
    function FileTimeToUInt64(const AFileTime: TFileTime): UInt64;
    function FormatFloatInvariant(const AValue: Double): string;
    function GetMemoryValueMB(const AValue: UInt64): UInt64;
    function TryGetSystemTotalTime(out ATotalTime: UInt64): Boolean;
    function TryReadProcessSnapshot(const AProcessID: Cardinal; const AProcessName: string;
      const APreviousSystemTime, ACurrentSystemTime: UInt64; out ACPUPercent: Double;
      out AWorkingSetMB, ACommitMB: UInt64): Boolean;
    function BuildTopProcessesText(const AProcesses: TStrings): string;
{$ENDIF}
  public
    constructor Create;
    destructor Destroy; override;
    procedure Configure(const AEnabled: Boolean; const AIntervalSeconds, ATopProcessCount,
      ACPUAlertPercent: Integer; const AMemoryAlertMB: UInt64);
    function BuildCurrentAppSnapshot: string;
    function BuildSnapshotLog(const ASessionCount: Integer; const AIgnoreEnabled: Boolean = False): string;
    function IntervalMilliseconds: Integer;
    property Enabled: Boolean read FEnabled;
  end;

implementation

constructor TPrismResourceMonitor.Create;
begin
  inherited Create;

  FEnabled := False;
  FIntervalSeconds := 300;
  FTopProcessCount := 3;
  FCPUAlertPercent := 70;
  FMemoryAlertMB := 2048;

{$IFDEF MSWINDOWS}
  FCurrentPID := GetCurrentProcessId;
  FLastSystemTime := 0;
  FConsoleLastSystemTime := 0;
  FConsoleLastProcessTime := 0;
  FLastProcessTimes := TDictionary<Cardinal, UInt64>.Create;
{$ENDIF}
end;

destructor TPrismResourceMonitor.Destroy;
begin
{$IFDEF MSWINDOWS}
  FreeAndNil(FLastProcessTimes);
{$ENDIF}
  inherited;
end;

procedure TPrismResourceMonitor.Configure(const AEnabled: Boolean; const AIntervalSeconds,
  ATopProcessCount, ACPUAlertPercent: Integer; const AMemoryAlertMB: UInt64);
begin
  FEnabled := AEnabled;

  if AIntervalSeconds >= 15 then
    FIntervalSeconds := AIntervalSeconds
  else
    FIntervalSeconds := 15;

  if ATopProcessCount > 0 then
    FTopProcessCount := ATopProcessCount
  else
    FTopProcessCount := 3;

  if ACPUAlertPercent >= 0 then
    FCPUAlertPercent := ACPUAlertPercent
  else
    FCPUAlertPercent := 0;

  FMemoryAlertMB := AMemoryAlertMB;
end;

function TPrismResourceMonitor.IntervalMilliseconds: Integer;
begin
  Result := FIntervalSeconds * 1000;
end;

{$IFDEF MSWINDOWS}
function TPrismResourceMonitor.BuildCurrentAppSnapshot: string;
var
  vCurrentSystemTime: UInt64;
  vPreviousSystemTime: UInt64;
  vCreationTime: TFileTime;
  vExitTime: TFileTime;
  vKernelTime: TFileTime;
  vUserTime: TFileTime;
  vCurrentProcessTime: UInt64;
  vPreviousProcessTime: UInt64;
  vProcessHandle: THandle;
  vMemoryCounters: TProcessMemoryCounters;
  vMemoryStatus: TMemoryStatusEx;
  vMachineName: string;
  vAvailableMemoryMB: UInt64;
  vTotalPhysicalMemoryMB: UInt64;
  vCPUPercent: Double;
  vWorkingSetMB: UInt64;
  vCommitMB: UInt64;
  vLevel: string;
begin
  Result := '';

  if not TryGetSystemTotalTime(vCurrentSystemTime) then
    Exit;

  vPreviousSystemTime := FConsoleLastSystemTime;
  FConsoleLastSystemTime := vCurrentSystemTime;

  vProcessHandle := OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, False, FCurrentPID);
  if vProcessHandle = 0 then
    Exit;

  try
    if not GetProcessTimes(vProcessHandle, vCreationTime, vExitTime, vKernelTime, vUserTime) then
      Exit;

    vCurrentProcessTime := FileTimeToUInt64(vKernelTime) + FileTimeToUInt64(vUserTime);
    vPreviousProcessTime := FConsoleLastProcessTime;
    FConsoleLastProcessTime := vCurrentProcessTime;

    if (vPreviousSystemTime > 0) and (vCurrentSystemTime > vPreviousSystemTime) and
       (vCurrentProcessTime >= vPreviousProcessTime) then
      vCPUPercent := ((vCurrentProcessTime - vPreviousProcessTime) * 100.0) /
        (vCurrentSystemTime - vPreviousSystemTime)
    else
      vCPUPercent := 0;

    ZeroMemory(@vMemoryCounters, SizeOf(vMemoryCounters));
    vMemoryCounters.cb := SizeOf(vMemoryCounters);
    if not GetProcessMemoryInfo(vProcessHandle, @vMemoryCounters, SizeOf(vMemoryCounters)) then
      Exit;

    vWorkingSetMB := GetMemoryValueMB(vMemoryCounters.WorkingSetSize);
    vCommitMB := GetMemoryValueMB(vMemoryCounters.PagefileUsage);

    ZeroMemory(@vMemoryStatus, SizeOf(vMemoryStatus));
    vMemoryStatus.dwLength := SizeOf(vMemoryStatus);
    GlobalMemoryStatusEx(vMemoryStatus);

    vMachineName := GetEnvironmentVariable('COMPUTERNAME');
    if vMachineName = '' then
      vMachineName := 'unknown';

    vAvailableMemoryMB := GetMemoryValueMB(vMemoryStatus.ullAvailPhys);
    vTotalPhysicalMemoryMB := GetMemoryValueMB(vMemoryStatus.ullTotalPhys);

    vLevel := 'Info';
    if ((FCPUAlertPercent > 0) and (Round(vCPUPercent) >= FCPUAlertPercent)) or
       ((FMemoryAlertMB > 0) and (vWorkingSetMB >= FMemoryAlertMB)) then
      vLevel := 'Warning';

    Result := 'Level = ' + vLevel +
      ' | MachineName = ' + vMachineName +
      ' | App = ' + ExtractFileName(ParamStr(0)) +
      ' | PID = ' + IntToStr(FCurrentPID) +
      ' | AppCPU = ' + FormatFloatInvariant(vCPUPercent) + '%'+
      ' | AppWorkingSetMB = ' + IntToStr(vWorkingSetMB) +
      ' | AppCommitMB = ' + IntToStr(vCommitMB) +
      ' | SystemAvailableMemoryMB = ' + IntToStr(vAvailableMemoryMB) +
      ' | SystemTotalPhysicalMemoryMB = ' + IntToStr(vTotalPhysicalMemoryMB);
  finally
    CloseHandle(vProcessHandle);
  end;
end;

function TPrismResourceMonitor.BuildTopProcessesText(const AProcesses: TStrings): string;
var
  I: Integer;
begin
  Result := '';

  for I := 0 to AProcesses.Count - 1 do
  begin
    if Result <> '' then
      Result := Result + '; ';

    Result := Result + AProcesses[I];
  end;

  if Result = '' then
    Result := 'n/a';
end;

function TPrismResourceMonitor.FileTimeToUInt64(const AFileTime: TFileTime): UInt64;
begin
  Result := UInt64(AFileTime.dwHighDateTime) shl 32 + AFileTime.dwLowDateTime;
end;

function TPrismResourceMonitor.FormatFloatInvariant(const AValue: Double): string;
var
  vFormatSettings: TFormatSettings;
begin
{$IFNDEF FPC}
  vFormatSettings := TFormatSettings.Create;
{$ELSE}
  vFormatSettings := DefaultFormatSettings;
{$ENDIF}
  vFormatSettings.DecimalSeparator := '.';
  Result := FloatToStrF(AValue, ffFixed, 15, 2, vFormatSettings);
end;

function TPrismResourceMonitor.GetMemoryValueMB(const AValue: UInt64): UInt64;
begin
  Result := AValue div (1024 * 1024);
end;

function TPrismResourceMonitor.TryGetSystemTotalTime(out ATotalTime: UInt64): Boolean;
var
  vIdleTime: TFileTime;
  vKernelTime: TFileTime;
  vUserTime: TFileTime;
begin
  Result := GetSystemTimes(vIdleTime, vKernelTime, vUserTime);

  if Result then
    ATotalTime := FileTimeToUInt64(vKernelTime) + FileTimeToUInt64(vUserTime)
  else
    ATotalTime := 0;
end;

function TPrismResourceMonitor.TryReadProcessSnapshot(const AProcessID: Cardinal;
  const AProcessName: string; const APreviousSystemTime, ACurrentSystemTime: UInt64;
  out ACPUPercent: Double; out AWorkingSetMB, ACommitMB: UInt64): Boolean;
var
  vCreationTime: TFileTime;
  vExitTime: TFileTime;
  vKernelTime: TFileTime;
  vUserTime: TFileTime;
  vPreviousProcessTime: UInt64;
  vCurrentProcessTime: UInt64;
  vProcessHandle: THandle;
  vMemoryCounters: TProcessMemoryCounters;
begin
  Result := False;
  ACPUPercent := 0;
  AWorkingSetMB := 0;
  ACommitMB := 0;

  vProcessHandle := OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, False, AProcessID);
  if vProcessHandle = 0 then
    Exit;

  try
    if not GetProcessTimes(vProcessHandle, vCreationTime, vExitTime, vKernelTime, vUserTime) then
      Exit;

    vCurrentProcessTime := FileTimeToUInt64(vKernelTime) + FileTimeToUInt64(vUserTime);

    if FLastProcessTimes.TryGetValue(AProcessID, vPreviousProcessTime) and
       (APreviousSystemTime > 0) and
       (ACurrentSystemTime > APreviousSystemTime) and
       (vCurrentProcessTime >= vPreviousProcessTime) then
      ACPUPercent := ((vCurrentProcessTime - vPreviousProcessTime) * 100.0) /
        (ACurrentSystemTime - APreviousSystemTime)
    else
      ACPUPercent := 0;

    if FLastProcessTimes.ContainsKey(AProcessID) then
      FLastProcessTimes[AProcessID] := vCurrentProcessTime
    else
      FLastProcessTimes.Add(AProcessID, vCurrentProcessTime);

    ZeroMemory(@vMemoryCounters, SizeOf(vMemoryCounters));
    vMemoryCounters.cb := SizeOf(vMemoryCounters);
    if GetProcessMemoryInfo(vProcessHandle, @vMemoryCounters, SizeOf(vMemoryCounters)) then
    begin
      AWorkingSetMB := GetMemoryValueMB(vMemoryCounters.WorkingSetSize);
      ACommitMB := GetMemoryValueMB(vMemoryCounters.PagefileUsage);
    end;

    Result := True;
  finally
    CloseHandle(vProcessHandle);
  end;
end;
{$ENDIF}

function TPrismResourceMonitor.BuildSnapshotLog(const ASessionCount: Integer; const AIgnoreEnabled: Boolean = False): string;
{$IFDEF MSWINDOWS}
var
  vCurrentSystemTime: UInt64;
  vPreviousSystemTime: UInt64;
  vSnapshotHandle: THandle;
  vProcessEntry: TProcessEntry32;
  vMemoryStatus: TMemoryStatusEx;
  vMachineName: string;
  vAvailableMemoryMB: UInt64;
  vTotalPhysicalMemoryMB: UInt64;
  vCPUPercent: Double;
  vWorkingSetMB: UInt64;
  vCommitMB: UInt64;
  vAppCPUPercent: Double;
  vAppWorkingSetMB: UInt64;
  vAppCommitMB: UInt64;
  vHasAppInfo: Boolean;
  vLevel: string;
  vTopCPU: TStringList;
  vTopMemory: TStringList;
  vTopCPUValues: array of Double;
  vTopMemoryValues: array of UInt64;
  I: Integer;
  vIndexToReplace: Integer;
  vCurrentName: string;
begin
  Result := '';

  if (not FEnabled) and (not AIgnoreEnabled) then
    Exit;

  if not TryGetSystemTotalTime(vCurrentSystemTime) then
    Exit;

  vPreviousSystemTime := FLastSystemTime;
  FLastSystemTime := vCurrentSystemTime;

  vTopCPU := TStringList.Create;
  vTopMemory := TStringList.Create;
  try
    SetLength(vTopCPUValues, FTopProcessCount);
    SetLength(vTopMemoryValues, FTopProcessCount);
    for I := 0 to FTopProcessCount - 1 do
    begin
      vTopCPUValues[I] := -1;
      vTopMemoryValues[I] := 0;
    end;

    vHasAppInfo := False;
    vAppCPUPercent := 0;
    vAppWorkingSetMB := 0;
    vAppCommitMB := 0;

    vSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if vSnapshotHandle = INVALID_HANDLE_VALUE then
      Exit;

    try
      ZeroMemory(@vProcessEntry, SizeOf(vProcessEntry));
      vProcessEntry.dwSize := SizeOf(vProcessEntry);

      if Process32First(vSnapshotHandle, vProcessEntry) then
      repeat
        vCurrentName := string(vProcessEntry.szExeFile);

        if TryReadProcessSnapshot(vProcessEntry.th32ProcessID, vCurrentName,
          vPreviousSystemTime, vCurrentSystemTime, vCPUPercent, vWorkingSetMB, vCommitMB) then
        begin
          if vProcessEntry.th32ProcessID = FCurrentPID then
          begin
            vHasAppInfo := True;
            vAppCPUPercent := vCPUPercent;
            vAppWorkingSetMB := vWorkingSetMB;
            vAppCommitMB := vCommitMB;
          end;

          if FTopProcessCount > 0 then
          begin
            vIndexToReplace := -1;
            for I := 0 to FTopProcessCount - 1 do
              if vCPUPercent > vTopCPUValues[I] then
              begin
                vIndexToReplace := I;
                Break;
              end;

            if vIndexToReplace >= 0 then
            begin
              while vTopCPU.Count < FTopProcessCount do
                vTopCPU.Add('');

              for I := FTopProcessCount - 1 downto vIndexToReplace + 1 do
              begin
                vTopCPUValues[I] := vTopCPUValues[I - 1];
                vTopCPU[I] := vTopCPU[I - 1];
              end;

              vTopCPUValues[vIndexToReplace] := vCPUPercent;
              vTopCPU[vIndexToReplace] := vCurrentName + '(PID=' + IntToStr(vProcessEntry.th32ProcessID) +
                ', CPU=' + FormatFloatInvariant(vCPUPercent) + '%, WS=' + IntToStr(vWorkingSetMB) + 'MB)';
            end;

            vIndexToReplace := -1;
            for I := 0 to FTopProcessCount - 1 do
              if vWorkingSetMB > vTopMemoryValues[I] then
              begin
                vIndexToReplace := I;
                Break;
              end;

            if vIndexToReplace >= 0 then
            begin
              while vTopMemory.Count < FTopProcessCount do
                vTopMemory.Add('');

              for I := FTopProcessCount - 1 downto vIndexToReplace + 1 do
              begin
                vTopMemoryValues[I] := vTopMemoryValues[I - 1];
                vTopMemory[I] := vTopMemory[I - 1];
              end;

              vTopMemoryValues[vIndexToReplace] := vWorkingSetMB;
              vTopMemory[vIndexToReplace] := vCurrentName + '(PID=' + IntToStr(vProcessEntry.th32ProcessID) +
                ', WS=' + IntToStr(vWorkingSetMB) + 'MB, Commit=' + IntToStr(vCommitMB) + 'MB)';
            end;
          end;
        end;
      until not Process32Next(vSnapshotHandle, vProcessEntry);
    finally
      CloseHandle(vSnapshotHandle);
    end;

    ZeroMemory(@vMemoryStatus, SizeOf(vMemoryStatus));
    vMemoryStatus.dwLength := SizeOf(vMemoryStatus);
    GlobalMemoryStatusEx(vMemoryStatus);
    vMachineName := GetEnvironmentVariable('COMPUTERNAME');
    if vMachineName = '' then
      vMachineName := 'unknown';
    vAvailableMemoryMB := GetMemoryValueMB(vMemoryStatus.ullAvailPhys);
    vTotalPhysicalMemoryMB := GetMemoryValueMB(vMemoryStatus.ullTotalPhys);

    vLevel := 'Info';
    if vHasAppInfo then
      if ((FCPUAlertPercent > 0) and (Round(vAppCPUPercent) >= FCPUAlertPercent)) or
         ((FMemoryAlertMB > 0) and (vAppWorkingSetMB >= FMemoryAlertMB)) then
        vLevel := 'Warning';

    Result := 'Level = ' + vLevel +
      ' | MachineName = ' + vMachineName +
      ' | Sessions = ' + IntToStr(ASessionCount) +
      ' | SystemMemoryLoad = ' + IntToStr(vMemoryStatus.dwMemoryLoad) + '%' +
      ' | SystemAvailableMemoryMB = ' + IntToStr(vAvailableMemoryMB) +
      ' | SystemTotalPhysicalMemoryMB = ' + IntToStr(vTotalPhysicalMemoryMB);

    if vHasAppInfo then
    begin
      if vPreviousSystemTime = 0 then
        Result := Result +
          ' | App = ' + ExtractFileName(ParamStr(0)) +
          ' | PID = ' + IntToStr(FCurrentPID) +
          ' | AppCPU = collecting' +
          ' | AppWorkingSetMB = ' + IntToStr(vAppWorkingSetMB) +
          ' | AppCommitMB = ' + IntToStr(vAppCommitMB)
      else
        Result := Result +
          ' | App = ' + ExtractFileName(ParamStr(0)) +
          ' | PID = ' + IntToStr(FCurrentPID) +
          ' | AppCPU = ' + FormatFloatInvariant(vAppCPUPercent) + '%'+
          ' | AppWorkingSetMB = ' + IntToStr(vAppWorkingSetMB) +
          ' | AppCommitMB = ' + IntToStr(vAppCommitMB);
    end;

    if vPreviousSystemTime = 0 then
      Result := Result + ' | TopCPU = collecting'
    else
      Result := Result + ' | TopCPU = ' + BuildTopProcessesText(vTopCPU);

    Result := Result + ' | TopMemory = ' + BuildTopProcessesText(vTopMemory);
  finally
    vTopCPU.Free;
    vTopMemory.Free;
  end;
end;
{$ELSE}
begin
  Result := '';
end;
{$ENDIF}

end.