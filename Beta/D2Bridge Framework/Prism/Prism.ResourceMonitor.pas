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

  Cross-platform version: Delphi/Windows, Lazarus/Windows, Lazarus/Linux
}

{$I ..\D2Bridge.inc}

unit Prism.ResourceMonitor;

interface

uses
  Classes, SysUtils
{$IFDEF MSWINDOWS}
  , Windows
  {$IFDEF FPC}
  , fgl  { TFPGMap - Lazarus/Windows }
  {$ELSE}
  , Generics.Collections  { TDictionary - Delphi }
  {$ENDIF}
{$ENDIF}
{$IFDEF LINUX}
  , BaseUnix, Unix  { FPC/Lazarus Linux }
{$ENDIF}
  ;

{ ============================================================
  Windows-specific declarations
  ============================================================ }
{$IFDEF MSWINDOWS}
type
  SIZE_T = NativeUInt;

  TProcessMemoryCounters = record
    cb: DWORD;
    PageFaultCount: DWORD;
    PeakWorkingSetSize: SIZE_T;
    WorkingSetSize: SIZE_T;
    QuotaPeakPagedPoolUsage: SIZE_T;
    QuotaPagedPoolUsage: SIZE_T;
    QuotaPeakNonPagedPoolUsage: SIZE_T;
    QuotaNonPagedPoolUsage: SIZE_T;
    PagefileUsage: SIZE_T;
    PeakPagefileUsage: SIZE_T;
  end;
  PProcessMemoryCounters = ^TProcessMemoryCounters;

  TMemoryStatusEx = record
    dwLength: DWORD;
    dwMemoryLoad: DWORD;
    ullTotalPhys: UInt64;
    ullAvailPhys: UInt64;
    ullTotalPageFile: UInt64;
    ullAvailPageFile: UInt64;
    ullTotalVirtual: UInt64;
    ullAvailVirtual: UInt64;
    ullAvailExtendedVirtual: UInt64;
  end;
  PMemoryStatusEx = ^TMemoryStatusEx;

  TProcessEntry32 = record
    dwSize: DWORD;
    cntUsage: DWORD;
    th32ProcessID: DWORD;
    th32DefaultHeapID: ULONG_PTR;
    th32ModuleID: DWORD;
    cntThreads: DWORD;
    th32ParentProcessID: DWORD;
    pcPriClassBase: LONG;
    dwFlags: DWORD;
    szExeFile: array[0..MAX_PATH - 1] of Char;
  end;
  PProcessEntry32 = ^TProcessEntry32;

const
  TH32CS_SNAPPROCESS = $00000002;

function GetProcessMemoryInfo(Process: THandle;
  ppsmemCounters: PProcessMemoryCounters;
  cb: DWORD): BOOL; stdcall; external 'psapi.dll';

function GlobalMemoryStatusEx(lpBuffer: PMemoryStatusEx): BOOL; stdcall; external 'kernel32.dll';

function CreateToolhelp32Snapshot(dwFlags, th32ProcessID: DWORD): THandle; stdcall; external 'kernel32.dll';
function Process32First(hSnapshot: THandle; lppe: PProcessEntry32): BOOL; stdcall; external 'kernel32.dll';
function Process32Next(hSnapshot: THandle; lppe: PProcessEntry32): BOOL; stdcall; external 'kernel32.dll';

{$ENDIF MSWINDOWS}

{ ============================================================
  Linux-specific declarations (Lazarus/FPC only)
  ============================================================ }
{$IFDEF LINUX}
type
  { Used to hold per-process CPU jiffies read from /proc/<pid>/stat }
  TLinuxProcessTimes = record
    PID: LongWord;
    UTime: UInt64;   { user mode jiffies }
    STime: UInt64;   { kernel mode jiffies }
    Total: UInt64;   { UTime + STime }
  end;
{$ENDIF LINUX}

{ ============================================================
  Main class
  ============================================================ }
type
  TPrismResourceMonitor = class
  private
    FEnabled: Boolean;
    FIntervalSeconds: Integer;
    FTopProcessCount: Integer;
    FCPUAlertPercent: Integer;
    FMemoryAlertMB: UInt64;

    { ---- Windows private members ---- }
{$IFDEF MSWINDOWS}
    FCurrentPID: Cardinal;
    FLastSystemTime: UInt64;
    FConsoleLastSystemTime: UInt64;
    FConsoleLastProcessTime: UInt64;
    {$IFDEF FPC}
    { Lazarus/Windows: use TFPGMap instead of TDictionary }
    FLastProcessTimes: TFPGMap<Cardinal, UInt64>;
    {$ELSE}
    { Delphi/Windows }
    FLastProcessTimes: TDictionary<Cardinal, UInt64>;
    {$ENDIF}

    function FileTimeToUInt64(const AFileTime: TFileTime): UInt64;
    function FormatFloatInvariant(const AValue: Double): string;
    function GetMemoryValueMB(const AValue: UInt64): UInt64;
    function TryGetSystemTotalTime(out ATotalTime: UInt64): Boolean;
    function TryReadProcessSnapshot(const AProcessID: Cardinal;
      const AProcessName: string;
      const APreviousSystemTime, ACurrentSystemTime: UInt64;
      out ACPUPercent: Double;
      out AWorkingSetMB, ACommitMB: UInt64): Boolean;
    function BuildTopProcessesText(const AProcesses: TStrings): string;
{$ENDIF MSWINDOWS}

    { ---- Linux private members ---- }
{$IFDEF LINUX}
    FCurrentPID: LongWord;
    FLastSystemJiffies: UInt64;     { total cpu jiffies at last snapshot }
    FLastProcessJiffies: UInt64;    { our process jiffies at last snapshot }
    FConsoleLastSysJiffies: UInt64;
    FConsoleLastProcJiffies: UInt64;

    { Map PID -> last total jiffies; implemented as a simple sorted array }
    FProcJiffiesCount: Integer;
    FProcJiffiesKeys: array of LongWord;
    FProcJiffiesVals: array of UInt64;

    function FormatFloatInvariant(const AValue: Double): string;
    function GetMemoryValueMB(const AValue: UInt64): UInt64;

    { Read /proc/stat total (user + system) jiffies }
    function TryGetSystemJiffies(out ATotalJiffies: UInt64): Boolean;

    { Read /proc/<pid>/stat utime + stime }
    function TryGetProcessJiffies(const APID: LongWord; out AJiffies: UInt64): Boolean;

    { Read /proc/<pid>/status VmRSS and VmSize in kB }
    function TryGetProcessMemoryKB(const APID: LongWord;
      out AVmRSS_KB, AVmSize_KB: UInt64): Boolean;

    { Read /proc/meminfo MemTotal and MemAvailable in kB }
    function TryGetSystemMemoryKB(out ATotalKB, AAvailKB: UInt64): Boolean;

    { Enumerate all PIDs from /proc }
    function EnumPIDs(out APIDList: array of LongWord): Integer;

    { Get process name from /proc/<pid>/comm }
    function GetProcessName(const APID: LongWord): string;

    { Lookup / store jiffies in our simple map }
    function GetStoredJiffies(const APID: LongWord; out AVal: UInt64): Boolean;
    procedure SetStoredJiffies(const APID: LongWord; const AVal: UInt64);

    function BuildTopProcessesText(const AProcesses: TStrings): string;
{$ENDIF LINUX}

  public
    constructor Create;
    destructor Destroy; override;

    procedure Configure(const AEnabled: Boolean;
      const AIntervalSeconds, ATopProcessCount, ACPUAlertPercent: Integer;
      const AMemoryAlertMB: UInt64);

    function BuildCurrentAppSnapshot: string;
    function BuildSnapshotLog(const ASessionCount: Integer;
      const AIgnoreEnabled: Boolean = False): string;
    function IntervalMilliseconds: Integer;

    property Enabled: Boolean read FEnabled;
  end;

implementation

{ ============================================================
  Windows-only: GetSystemTimes for Lazarus/FPC
  ============================================================ }
{$IFDEF MSWINDOWS}
  {$IFDEF FPC}
function GetSystemTimes(lpIdleTime, lpKernelTime, lpUserTime: PFileTime): BOOL;
  stdcall; external 'kernel32.dll';
  {$ENDIF}
{$ENDIF}

{ ============================================================
  Constructor / Destructor
  ============================================================ }
constructor TPrismResourceMonitor.Create;
begin
  inherited Create;

  FEnabled          := False;
  FIntervalSeconds  := 300;
  FTopProcessCount  := 3;
  FCPUAlertPercent  := 70;
  FMemoryAlertMB    := 2048;

{$IFDEF MSWINDOWS}
  FCurrentPID             := GetCurrentProcessId;
  FLastSystemTime         := 0;
  FConsoleLastSystemTime  := 0;
  FConsoleLastProcessTime := 0;
  {$IFDEF FPC}
  FLastProcessTimes := TFPGMap<Cardinal, UInt64>.Create;
  {$ELSE}
  FLastProcessTimes := TDictionary<Cardinal, UInt64>.Create;
  {$ENDIF}
{$ENDIF}

{$IFDEF LINUX}
  FCurrentPID              := LongWord(fpGetPID);
  FLastSystemJiffies       := 0;
  FLastProcessJiffies      := 0;
  FConsoleLastSysJiffies   := 0;
  FConsoleLastProcJiffies  := 0;
  FProcJiffiesCount        := 0;
  SetLength(FProcJiffiesKeys, 64);
  SetLength(FProcJiffiesVals, 64);
{$ENDIF}
end;

destructor TPrismResourceMonitor.Destroy;
begin
{$IFDEF MSWINDOWS}
  FreeAndNil(FLastProcessTimes);
{$ENDIF}
  inherited;
end;

{ ============================================================
  Configure / IntervalMilliseconds
  ============================================================ }
procedure TPrismResourceMonitor.Configure(const AEnabled: Boolean;
  const AIntervalSeconds, ATopProcessCount, ACPUAlertPercent: Integer;
  const AMemoryAlertMB: UInt64);
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

{ ============================================================
  Shared helpers (implemented per platform below)
  ============================================================ }
function TPrismResourceMonitor.FormatFloatInvariant(const AValue: Double): string;
var
  vFS: TFormatSettings;
begin
{$IFNDEF FPC}
  vFS := TFormatSettings.Create;   { Delphi }
{$ELSE}
  vFS := DefaultFormatSettings;    { Lazarus/FPC }
{$ENDIF}
  vFS.DecimalSeparator := '.';
  Result := FloatToStrF(AValue, ffFixed, 15, 2, vFS);
end;

function TPrismResourceMonitor.GetMemoryValueMB(const AValue: UInt64): UInt64;
begin
  Result := AValue div (1024 * 1024);
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

{ ============================================================
  WINDOWS IMPLEMENTATION
  ============================================================ }
{$IFDEF MSWINDOWS}

function TPrismResourceMonitor.FileTimeToUInt64(const AFileTime: TFileTime): UInt64;
begin
  Result := UInt64(AFileTime.dwHighDateTime) shl 32 + AFileTime.dwLowDateTime;
end;

function TPrismResourceMonitor.TryGetSystemTotalTime(out ATotalTime: UInt64): Boolean;
var
  vIdleTime, vKernelTime, vUserTime: TFileTime;
begin
{$IFDEF FPC}
  Result := GetSystemTimes(@vIdleTime, @vKernelTime, @vUserTime);
{$ELSE}
  Result := GetSystemTimes(vIdleTime, vKernelTime, vUserTime);
{$ENDIF}
  if Result then
    ATotalTime := FileTimeToUInt64(vKernelTime) + FileTimeToUInt64(vUserTime)
  else
    ATotalTime := 0;
end;

{ ---- Windows: helper to get/set FLastProcessTimes ---- }

{ Delphi uses TDictionary; Lazarus uses TFPGMap.
  We wrap them with local helpers so the rest of the code is identical. }

{$IFDEF FPC}
function WinGetProcTime(const AMap: TFPGMap<Cardinal, UInt64>;
  const APID: Cardinal; out AVal: UInt64): Boolean;
var
  vIdx: Integer;
begin
  vIdx := AMap.IndexOf(APID);
  Result := vIdx >= 0;
  if Result then AVal := AMap.Data[vIdx];
end;

procedure WinSetProcTime(const AMap: TFPGMap<Cardinal, UInt64>;
  const APID: Cardinal; const AVal: UInt64);
var
  vIdx: Integer;
begin
  vIdx := AMap.IndexOf(APID);
  if vIdx >= 0 then
    AMap.Data[vIdx] := AVal
  else
    AMap.Add(APID, AVal);
end;
{$ELSE}
{ Delphi wrappers - inline thin wrappers so the main code stays identical }
function WinGetProcTime(const AMap: TDictionary<Cardinal, UInt64>;
  const APID: Cardinal; out AVal: UInt64): Boolean;
begin
  Result := AMap.TryGetValue(APID, AVal);
end;

procedure WinSetProcTime(const AMap: TDictionary<Cardinal, UInt64>;
  const APID: Cardinal; const AVal: UInt64);
begin
  AMap.AddOrSetValue(APID, AVal);
end;
{$ENDIF}

function TPrismResourceMonitor.TryReadProcessSnapshot(
  const AProcessID: Cardinal; const AProcessName: string;
  const APreviousSystemTime, ACurrentSystemTime: UInt64;
  out ACPUPercent: Double; out AWorkingSetMB, ACommitMB: UInt64): Boolean;
var
  vCreationTime, vExitTime, vKernelTime, vUserTime: TFileTime;
  vPreviousProcessTime, vCurrentProcessTime: UInt64;
  vProcessHandle: THandle;
  vMemCounters: TProcessMemoryCounters;
begin
  Result        := False;
  ACPUPercent   := 0;
  AWorkingSetMB := 0;
  ACommitMB     := 0;

  vProcessHandle := OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ,
    False, AProcessID);
  if vProcessHandle = 0 then Exit;

  try
    if not GetProcessTimes(vProcessHandle, vCreationTime, vExitTime,
      vKernelTime, vUserTime) then Exit;

    vCurrentProcessTime := FileTimeToUInt64(vKernelTime) +
      FileTimeToUInt64(vUserTime);

    if WinGetProcTime(FLastProcessTimes, AProcessID, vPreviousProcessTime) and
       (APreviousSystemTime > 0) and
       (ACurrentSystemTime > APreviousSystemTime) and
       (vCurrentProcessTime >= vPreviousProcessTime) then
      ACPUPercent :=
        ((vCurrentProcessTime - vPreviousProcessTime) * 100.0) /
         (ACurrentSystemTime - APreviousSystemTime)
    else
      ACPUPercent := 0;

    WinSetProcTime(FLastProcessTimes, AProcessID, vCurrentProcessTime);

    ZeroMemory(@vMemCounters, SizeOf(vMemCounters));
    vMemCounters.cb := SizeOf(vMemCounters);
    if GetProcessMemoryInfo(vProcessHandle, @vMemCounters, SizeOf(vMemCounters)) then
    begin
      AWorkingSetMB := GetMemoryValueMB(vMemCounters.WorkingSetSize);
      ACommitMB     := GetMemoryValueMB(vMemCounters.PagefileUsage);
    end;

    Result := True;
  finally
    CloseHandle(vProcessHandle);
  end;
end;

function TPrismResourceMonitor.BuildCurrentAppSnapshot: string;
var
  vCurrentSystemTime, vPreviousSystemTime: UInt64;
  vCreationTime, vExitTime, vKernelTime, vUserTime: TFileTime;
  vCurrentProcessTime, vPreviousProcessTime: UInt64;
  vProcessHandle: THandle;
  vMemCounters: TProcessMemoryCounters;
  vMemStatus: TMemoryStatusEx;
  vMachineName: string;
  vAvailMB, vTotalMB: UInt64;
  vCPUPercent: Double;
  vWorkingSetMB, vCommitMB: UInt64;
  vLevel: string;
begin
  Result := '';

  if not TryGetSystemTotalTime(vCurrentSystemTime) then Exit;

  vPreviousSystemTime      := FConsoleLastSystemTime;
  FConsoleLastSystemTime   := vCurrentSystemTime;

  vProcessHandle := OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ,
    False, FCurrentPID);
  if vProcessHandle = 0 then Exit;

  try
    if not GetProcessTimes(vProcessHandle, vCreationTime, vExitTime,
      vKernelTime, vUserTime) then Exit;

    vCurrentProcessTime     := FileTimeToUInt64(vKernelTime) +
      FileTimeToUInt64(vUserTime);
    vPreviousProcessTime    := FConsoleLastProcessTime;
    FConsoleLastProcessTime := vCurrentProcessTime;

    if (vPreviousSystemTime > 0) and
       (vCurrentSystemTime > vPreviousSystemTime) and
       (vCurrentProcessTime >= vPreviousProcessTime) then
      vCPUPercent :=
        ((vCurrentProcessTime - vPreviousProcessTime) * 100.0) /
         (vCurrentSystemTime - vPreviousSystemTime)
    else
      vCPUPercent := 0;

    ZeroMemory(@vMemCounters, SizeOf(vMemCounters));
    vMemCounters.cb := SizeOf(vMemCounters);
    if not GetProcessMemoryInfo(vProcessHandle, @vMemCounters, SizeOf(vMemCounters)) then
      Exit;

    vWorkingSetMB := GetMemoryValueMB(vMemCounters.WorkingSetSize);
    vCommitMB     := GetMemoryValueMB(vMemCounters.PagefileUsage);

    ZeroMemory(@vMemStatus, SizeOf(vMemStatus));
    vMemStatus.dwLength := SizeOf(vMemStatus);
    GlobalMemoryStatusEx(@vMemStatus);

    vMachineName := SysUtils.GetEnvironmentVariable('COMPUTERNAME');
    if vMachineName = '' then vMachineName := 'unknown';

    vAvailMB := GetMemoryValueMB(vMemStatus.ullAvailPhys);
    vTotalMB := GetMemoryValueMB(vMemStatus.ullTotalPhys);

    vLevel := 'Info';
    if ((FCPUAlertPercent > 0) and (Round(vCPUPercent) >= FCPUAlertPercent)) or
       ((FMemoryAlertMB > 0) and (vWorkingSetMB >= FMemoryAlertMB)) then
      vLevel := 'Warning';

    Result :=
      'Level = '                    + vLevel +
      ' | MachineName = '           + vMachineName +
      ' | App = '                   + ExtractFileName(ParamStr(0)) +
      ' | PID = '                   + IntToStr(FCurrentPID) +
      ' | AppCPU = '                + FormatFloatInvariant(vCPUPercent) + '%' +
      ' | AppWorkingSetMB = '       + IntToStr(vWorkingSetMB) +
      ' | AppCommitMB = '           + IntToStr(vCommitMB) +
      ' | SystemAvailableMemoryMB = ' + IntToStr(vAvailMB) +
      ' | SystemTotalPhysicalMemoryMB = ' + IntToStr(vTotalMB);
  finally
    CloseHandle(vProcessHandle);
  end;
end;

function TPrismResourceMonitor.BuildSnapshotLog(const ASessionCount: Integer;
  const AIgnoreEnabled: Boolean = False): string;
var
  vCurrentSystemTime, vPreviousSystemTime: UInt64;
  vSnapshotHandle: THandle;
  vProcessEntry: TProcessEntry32;
  vMemStatus: TMemoryStatusEx;
  vMachineName: string;
  vAvailMB, vTotalMB: UInt64;
  vCPUPercent: Double;
  vWorkingSetMB, vCommitMB: UInt64;
  vAppCPUPercent: Double;
  vAppWorkingSetMB, vAppCommitMB: UInt64;
  vHasAppInfo: Boolean;
  vLevel: string;
  vTopCPU, vTopMemory: TStringList;
  vTopCPUValues: array of Double;
  vTopMemValues: array of UInt64;
  I, vIdxReplace: Integer;
  vCurrentName: string;
begin
  Result := '';

  if (not FEnabled) and (not AIgnoreEnabled) then Exit;
  if not TryGetSystemTotalTime(vCurrentSystemTime) then Exit;

  vPreviousSystemTime := FLastSystemTime;
  FLastSystemTime     := vCurrentSystemTime;

  vTopCPU    := TStringList.Create;
  vTopMemory := TStringList.Create;
  try
    SetLength(vTopCPUValues, FTopProcessCount);
    SetLength(vTopMemValues,  FTopProcessCount);
    for I := 0 to FTopProcessCount - 1 do
    begin
      vTopCPUValues[I] := -1;
      vTopMemValues[I] := 0;
    end;

    vHasAppInfo     := False;
    vAppCPUPercent  := 0;
    vAppWorkingSetMB := 0;
    vAppCommitMB    := 0;

    vSnapshotHandle := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if vSnapshotHandle = INVALID_HANDLE_VALUE then Exit;

    try
      ZeroMemory(@vProcessEntry, SizeOf(vProcessEntry));
      vProcessEntry.dwSize := SizeOf(vProcessEntry);

      if Process32First(vSnapshotHandle, @vProcessEntry) then
      repeat
        vCurrentName := string(vProcessEntry.szExeFile);

        if TryReadProcessSnapshot(vProcessEntry.th32ProcessID, vCurrentName,
          vPreviousSystemTime, vCurrentSystemTime,
          vCPUPercent, vWorkingSetMB, vCommitMB) then
        begin
          if vProcessEntry.th32ProcessID = FCurrentPID then
          begin
            vHasAppInfo      := True;
            vAppCPUPercent   := vCPUPercent;
            vAppWorkingSetMB := vWorkingSetMB;
            vAppCommitMB     := vCommitMB;
          end;

          if FTopProcessCount > 0 then
          begin
            { Top CPU }
            vIdxReplace := -1;
            for I := 0 to FTopProcessCount - 1 do
              if vCPUPercent > vTopCPUValues[I] then
              begin vIdxReplace := I; Break; end;

            if vIdxReplace >= 0 then
            begin
              while vTopCPU.Count < FTopProcessCount do vTopCPU.Add('');
              for I := FTopProcessCount - 1 downto vIdxReplace + 1 do
              begin
                vTopCPUValues[I] := vTopCPUValues[I - 1];
                vTopCPU[I]       := vTopCPU[I - 1];
              end;
              vTopCPUValues[vIdxReplace] := vCPUPercent;
              vTopCPU[vIdxReplace] :=
                vCurrentName + '(PID=' + IntToStr(vProcessEntry.th32ProcessID) +
                ', CPU=' + FormatFloatInvariant(vCPUPercent) +
                '%, WS=' + IntToStr(vWorkingSetMB) + 'MB)';
            end;

            { Top Memory }
            vIdxReplace := -1;
            for I := 0 to FTopProcessCount - 1 do
              if vWorkingSetMB > vTopMemValues[I] then
              begin vIdxReplace := I; Break; end;

            if vIdxReplace >= 0 then
            begin
              while vTopMemory.Count < FTopProcessCount do vTopMemory.Add('');
              for I := FTopProcessCount - 1 downto vIdxReplace + 1 do
              begin
                vTopMemValues[I]  := vTopMemValues[I - 1];
                vTopMemory[I]     := vTopMemory[I - 1];
              end;
              vTopMemValues[vIdxReplace] := vWorkingSetMB;
              vTopMemory[vIdxReplace] :=
                vCurrentName + '(PID=' + IntToStr(vProcessEntry.th32ProcessID) +
                ', WS=' + IntToStr(vWorkingSetMB) +
                'MB, Commit=' + IntToStr(vCommitMB) + 'MB)';
            end;
          end;
        end;
      until not Process32Next(vSnapshotHandle, @vProcessEntry);
    finally
      CloseHandle(vSnapshotHandle);
    end;

    ZeroMemory(@vMemStatus, SizeOf(vMemStatus));
    vMemStatus.dwLength := SizeOf(vMemStatus);
    GlobalMemoryStatusEx(@vMemStatus);

    vMachineName := SysUtils.GetEnvironmentVariable('COMPUTERNAME');
    if vMachineName = '' then vMachineName := 'unknown';

    vAvailMB := GetMemoryValueMB(vMemStatus.ullAvailPhys);
    vTotalMB := GetMemoryValueMB(vMemStatus.ullTotalPhys);

    vLevel := 'Info';
    if vHasAppInfo then
      if ((FCPUAlertPercent > 0) and (Round(vAppCPUPercent) >= FCPUAlertPercent)) or
         ((FMemoryAlertMB > 0) and (vAppWorkingSetMB >= FMemoryAlertMB)) then
        vLevel := 'Warning';

    Result :=
      'Level = '                         + vLevel +
      ' | MachineName = '                + vMachineName +
      ' | Sessions = '                   + IntToStr(ASessionCount) +
      ' | SystemMemoryLoad = '           + IntToStr(vMemStatus.dwMemoryLoad) + '%' +
      ' | SystemAvailableMemoryMB = '    + IntToStr(vAvailMB) +
      ' | SystemTotalPhysicalMemoryMB = '+ IntToStr(vTotalMB);

    if vHasAppInfo then
    begin
      if vPreviousSystemTime = 0 then
        Result := Result +
          ' | App = '             + ExtractFileName(ParamStr(0)) +
          ' | PID = '             + IntToStr(FCurrentPID) +
          ' | AppCPU = collecting' +
          ' | AppWorkingSetMB = ' + IntToStr(vAppWorkingSetMB) +
          ' | AppCommitMB = '     + IntToStr(vAppCommitMB)
      else
        Result := Result +
          ' | App = '             + ExtractFileName(ParamStr(0)) +
          ' | PID = '             + IntToStr(FCurrentPID) +
          ' | AppCPU = '          + FormatFloatInvariant(vAppCPUPercent) + '%' +
          ' | AppWorkingSetMB = ' + IntToStr(vAppWorkingSetMB) +
          ' | AppCommitMB = '     + IntToStr(vAppCommitMB);
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

{$ENDIF MSWINDOWS}

{ ============================================================
  LINUX IMPLEMENTATION  (Lazarus/FPC)
  ============================================================ }
{$IFDEF LINUX}

{ ---- Simple PID->UInt64 map helpers ---- }

function TPrismResourceMonitor.GetStoredJiffies(const APID: LongWord;
  out AVal: UInt64): Boolean;
var
  I: Integer;
begin
  for I := 0 to FProcJiffiesCount - 1 do
    if FProcJiffiesKeys[I] = APID then
    begin
      AVal := FProcJiffiesVals[I];
      Result := True;
      Exit;
    end;
  AVal := 0;
  Result := False;
end;

procedure TPrismResourceMonitor.SetStoredJiffies(const APID: LongWord;
  const AVal: UInt64);
var
  I: Integer;
begin
  for I := 0 to FProcJiffiesCount - 1 do
    if FProcJiffiesKeys[I] = APID then
    begin
      FProcJiffiesVals[I] := AVal;
      Exit;
    end;
  { Grow arrays if needed }
  if FProcJiffiesCount >= Length(FProcJiffiesKeys) then
  begin
    SetLength(FProcJiffiesKeys, FProcJiffiesCount + 64);
    SetLength(FProcJiffiesVals, FProcJiffiesCount + 64);
  end;
  FProcJiffiesKeys[FProcJiffiesCount] := APID;
  FProcJiffiesVals[FProcJiffiesCount] := AVal;
  Inc(FProcJiffiesCount);
end;

{ ---- /proc/stat -> total CPU jiffies (user + system, no idle) ---- }
function TPrismResourceMonitor.TryGetSystemJiffies(out ATotalJiffies: UInt64): Boolean;
var
  vF: TextFile;
  vLine: string;
  vParts: TStringList;
  vUser, vNice, vSystem: UInt64;
begin
  Result := False;
  ATotalJiffies := 0;

  if not FileExists('/proc/stat') then Exit;

  AssignFile(vF, '/proc/stat');
  {$I-}
  Reset(vF);
  {$I+}
  if IOResult <> 0 then Exit;
  try
    while not EOF(vF) do
    begin
      ReadLn(vF, vLine);
      { First line starts with "cpu " (total) }
      if Copy(vLine, 1, 4) = 'cpu ' then
      begin
        vParts := TStringList.Create;
        try
          vParts.Delimiter := ' ';
          vParts.StrictDelimiter := False;
          vParts.DelimitedText := Trim(vLine);
          { tokens: cpu user nice system idle iowait irq softirq... }
          if vParts.Count >= 4 then
          begin
            vUser   := StrToUInt64Def(vParts[1], 0);
            vNice   := StrToUInt64Def(vParts[2], 0);
            vSystem := StrToUInt64Def(vParts[3], 0);
            ATotalJiffies := vUser + vNice + vSystem;
            Result := True;
          end;
        finally
          vParts.Free;
        end;
        Break;
      end;
    end;
  finally
    CloseFile(vF);
  end;
end;

{ ---- /proc/<pid>/stat -> utime + stime ---- }
function TPrismResourceMonitor.TryGetProcessJiffies(const APID: LongWord;
  out AJiffies: UInt64): Boolean;
var
  vPath, vContent: string;
  vF: TextFile;
  vParts: TStringList;
  vUTime, vSTime: UInt64;
begin
  Result := False;
  AJiffies := 0;

  vPath := '/proc/' + IntToStr(APID) + '/stat';
  if not FileExists(vPath) then Exit;

  AssignFile(vF, vPath);
  {$I-}
  Reset(vF);
  {$I+}
  if IOResult <> 0 then Exit;
  try
    ReadLn(vF, vContent);
  finally
    CloseFile(vF);
  end;

  { /proc/<pid>/stat fields are space-separated.
    Field 14 (index 13) = utime, field 15 (index 14) = stime.
    But the comm field (2) can contain spaces and is wrapped in '()'.
    Strategy: find closing ')' and parse from there. }
  vContent := Copy(vContent, Pos(')', vContent) + 2, MaxInt);

  vParts := TStringList.Create;
  try
    vParts.Delimiter := ' ';
    vParts.StrictDelimiter := True;
    vParts.DelimitedText := Trim(vContent);
    { After the ')' the fields shift: [0]=state, [1]=ppid, ...
      utime = index 11, stime = index 12 (0-based after ')') }
    if vParts.Count >= 13 then
    begin
      vUTime := StrToUInt64Def(vParts[11], 0);
      vSTime := StrToUInt64Def(vParts[12], 0);
      AJiffies := vUTime + vSTime;
      Result := True;
    end;
  finally
    vParts.Free;
  end;
end;

{ ---- /proc/<pid>/status -> VmRSS and VmSize ---- }
function TPrismResourceMonitor.TryGetProcessMemoryKB(const APID: LongWord;
  out AVmRSS_KB, AVmSize_KB: UInt64): Boolean;
var
  vPath, vLine, vKey, vVal: string;
  vF: TextFile;
  vP: Integer;
begin
  Result := False;
  AVmRSS_KB  := 0;
  AVmSize_KB := 0;

  vPath := '/proc/' + IntToStr(APID) + '/status';
  if not FileExists(vPath) then Exit;

  AssignFile(vF, vPath);
  {$I-}
  Reset(vF);
  {$I+}
  if IOResult <> 0 then Exit;
  try
    while not EOF(vF) do
    begin
      ReadLn(vF, vLine);
      vP := Pos(':', vLine);
      if vP > 0 then
      begin
        vKey := Trim(Copy(vLine, 1, vP - 1));
        vVal := Trim(Copy(vLine, vP + 1, MaxInt));
        { Remove trailing " kB" if present }
        if Copy(vVal, Length(vVal) - 2, 3) = ' kB' then
          vVal := Trim(Copy(vVal, 1, Length(vVal) - 3));
        if vKey = 'VmRSS' then
          AVmRSS_KB := StrToUInt64Def(vVal, 0);
        if vKey = 'VmSize' then
          AVmSize_KB := StrToUInt64Def(vVal, 0);
      end;
    end;
    Result := (AVmRSS_KB > 0) or (AVmSize_KB > 0);
  finally
    CloseFile(vF);
  end;
end;

{ ---- /proc/meminfo ---- }
function TPrismResourceMonitor.TryGetSystemMemoryKB(out ATotalKB,
  AAvailKB: UInt64): Boolean;
var
  vF: TextFile;
  vLine, vKey, vVal: string;
  vP: Integer;
  vFound: Integer;
begin
  ATotalKB := 0;
  AAvailKB := 0;
  vFound   := 0;
  Result   := False;

  if not FileExists('/proc/meminfo') then Exit;

  AssignFile(vF, '/proc/meminfo');
  {$I-}
  Reset(vF);
  {$I+}
  if IOResult <> 0 then Exit;
  try
    while not EOF(vF) do
    begin
      ReadLn(vF, vLine);
      vP := Pos(':', vLine);
      if vP > 0 then
      begin
        vKey := Trim(Copy(vLine, 1, vP - 1));
        vVal := Trim(Copy(vLine, vP + 1, MaxInt));
        if Copy(vVal, Length(vVal) - 2, 3) = ' kB' then
          vVal := Trim(Copy(vVal, 1, Length(vVal) - 3));
        if vKey = 'MemTotal' then begin ATotalKB := StrToUInt64Def(vVal, 0); Inc(vFound); end;
        if vKey = 'MemAvailable' then begin AAvailKB := StrToUInt64Def(vVal, 0); Inc(vFound); end;
        if vFound = 2 then Break;
      end;
    end;
    Result := vFound = 2;
  finally
    CloseFile(vF);
  end;
end;

{ ---- Enumerate all numeric entries in /proc ---- }
function TPrismResourceMonitor.EnumPIDs(out APIDList: array of LongWord): Integer;
var
  vSearchRec: TSearchRec;
  vPID: LongInt;
  vErr: Integer;
begin
  Result := 0;
  vErr := FindFirst('/proc/*', faDirectory, vSearchRec);
  if vErr = 0 then
  try
    repeat
      if TryStrToInt(vSearchRec.Name, vPID) and (vPID > 0) then
      begin
        if Result < High(APIDList) + 1 then
        begin
          APIDList[Result] := LongWord(vPID);
          Inc(Result);
        end;
      end;
    until FindNext(vSearchRec) <> 0;
  finally
    FindClose(vSearchRec);
  end;
end;

{ ---- /proc/<pid>/comm -> process name ---- }
function TPrismResourceMonitor.GetProcessName(const APID: LongWord): string;
var
  vF: TextFile;
  vPath: string;
begin
  Result := '';
  vPath := '/proc/' + IntToStr(APID) + '/comm';
  if not FileExists(vPath) then Exit;
  AssignFile(vF, vPath);
  {$I-}
  Reset(vF);
  {$I+}
  if IOResult <> 0 then Exit;
  try
    if not EOF(vF) then ReadLn(vF, Result);
  finally
    CloseFile(vF);
  end;
  Result := Trim(Result);
end;

{ ---- Linux BuildCurrentAppSnapshot ---- }
function TPrismResourceMonitor.BuildCurrentAppSnapshot: string;
var
  vCurrentSysJ, vPrevSysJ: UInt64;
  vCurrentProcJ, vPrevProcJ: UInt64;
  vCPUPercent: Double;
  vRSS_KB, vVmSize_KB: UInt64;
  vWorkingSetMB, vCommitMB: UInt64;
  vTotalKB, vAvailKB: UInt64;
  vTotalMB, vAvailMB: UInt64;
  vMachineName, vLevel: string;
  vF: TextFile;
begin
  Result := '';

  if not TryGetSystemJiffies(vCurrentSysJ) then Exit;
  if not TryGetProcessJiffies(FCurrentPID, vCurrentProcJ) then Exit;

  vPrevSysJ                := FConsoleLastSysJiffies;
  vPrevProcJ               := FConsoleLastProcJiffies;
  FConsoleLastSysJiffies   := vCurrentSysJ;
  FConsoleLastProcJiffies  := vCurrentProcJ;

  if (vPrevSysJ > 0) and (vCurrentSysJ > vPrevSysJ) and
     (vCurrentProcJ >= vPrevProcJ) then
    vCPUPercent :=
      ((vCurrentProcJ - vPrevProcJ) * 100.0) /
       (vCurrentSysJ  - vPrevSysJ)
  else
    vCPUPercent := 0;

  if not TryGetProcessMemoryKB(FCurrentPID, vRSS_KB, vVmSize_KB) then Exit;

  vWorkingSetMB := vRSS_KB    div 1024;
  vCommitMB     := vVmSize_KB div 1024;

  if not TryGetSystemMemoryKB(vTotalKB, vAvailKB) then Exit;

  vTotalMB := vTotalKB div 1024;
  vAvailMB := vAvailKB div 1024;

  vMachineName := SysUtils.GetEnvironmentVariable('HOSTNAME');
  if vMachineName = '' then
  begin
    { Fallback: read /proc/sys/kernel/hostname }
    if FileExists('/proc/sys/kernel/hostname') then
    begin

      AssignFile(vF, '/proc/sys/kernel/hostname');
      {$I-} Reset(vF); {$I+}
      if IOResult = 0 then
      begin
        try
          ReadLn(vF, vMachineName);
          vMachineName := Trim(vMachineName);
        finally
          CloseFile(vF);
        end;
      end;
    end;
  end;
  if vMachineName = '' then vMachineName := 'unknown';

  vLevel := 'Info';
  if ((FCPUAlertPercent > 0) and (Round(vCPUPercent) >= FCPUAlertPercent)) or
     ((FMemoryAlertMB > 0) and (vWorkingSetMB >= FMemoryAlertMB)) then
    vLevel := 'Warning';

  Result :=
    'Level = '                         + vLevel +
    ' | MachineName = '                + vMachineName +
    ' | App = '                        + ExtractFileName(ParamStr(0)) +
    ' | PID = '                        + IntToStr(FCurrentPID) +
    ' | AppCPU = '                     + FormatFloatInvariant(vCPUPercent) + '%' +
    ' | AppWorkingSetMB = '            + IntToStr(vWorkingSetMB) +
    ' | AppCommitMB = '                + IntToStr(vCommitMB) +
    ' | SystemAvailableMemoryMB = '    + IntToStr(vAvailMB) +
    ' | SystemTotalPhysicalMemoryMB = '+ IntToStr(vTotalMB);
end;

{ ---- Linux BuildSnapshotLog ---- }
function TPrismResourceMonitor.BuildSnapshotLog(const ASessionCount: Integer;
  const AIgnoreEnabled: Boolean = False): string;
const
  MAX_PIDS = 4096;
var
  vCurrentSysJ, vPrevSysJ: UInt64;
  vPIDs: array[0..MAX_PIDS - 1] of LongWord;
  vPIDCount: Integer;
  I, I1, vIdxReplace: Integer;
  vPID: LongWord;
  vProcJ, vPrevProcJ: UInt64;
  vCPUPercent: Double;
  vRSS_KB, vVmSize_KB: UInt64;
  vWorkingSetMB, vCommitMB: UInt64;
  vTotalKB, vAvailKB: UInt64;
  vTotalMB, vAvailMB: UInt64;
  vMachineName, vProcName, vLevel: string;
  vAppCPUPercent: Double;
  vAppWorkingSetMB, vAppCommitMB: UInt64;
  vHasAppInfo: Boolean;
  vTopCPU, vTopMemory: TStringList;
  vTopCPUValues: array of Double;
  vTopMemValues: array of UInt64;
  vHostFile: TextFile;
  vMemLoad: UInt64;
begin
  Result := '';
  vMemLoad := 0;
  if (not FEnabled) and (not AIgnoreEnabled) then Exit;
  if not TryGetSystemJiffies(vCurrentSysJ) then Exit;

  vPrevSysJ       := FLastSystemJiffies;
  FLastSystemJiffies := vCurrentSysJ;

  vHasAppInfo      := False;
  vAppCPUPercent   := 0;
  vAppWorkingSetMB := 0;
  vAppCommitMB     := 0;

  vTopCPU    := TStringList.Create;
  vTopMemory := TStringList.Create;
  try
    SetLength(vTopCPUValues, FTopProcessCount);
    SetLength(vTopMemValues,  FTopProcessCount);
    for I := 0 to FTopProcessCount - 1 do
    begin
      vTopCPUValues[I] := -1;
      vTopMemValues[I] := 0;
    end;

    vPIDCount := EnumPIDs(vPIDs);

    for I := 0 to vPIDCount - 1 do
    begin
      vPID := vPIDs[I];

      if not TryGetProcessJiffies(vPID, vProcJ) then Continue;

      if GetStoredJiffies(vPID, vPrevProcJ) and
         (vPrevSysJ > 0) and
         (vCurrentSysJ > vPrevSysJ) and
         (vProcJ >= vPrevProcJ) then
        vCPUPercent :=
          ((vProcJ - vPrevProcJ) * 100.0) /
           (vCurrentSysJ - vPrevSysJ)
      else
        vCPUPercent := 0;

      SetStoredJiffies(vPID, vProcJ);

      vRSS_KB    := 0;
      vVmSize_KB := 0;
      TryGetProcessMemoryKB(vPID, vRSS_KB, vVmSize_KB);
      vWorkingSetMB := vRSS_KB    div 1024;
      vCommitMB     := vVmSize_KB div 1024;

      vProcName := GetProcessName(vPID);
      if vProcName = '' then vProcName := 'pid' + IntToStr(vPID);

      if vPID = FCurrentPID then
      begin
        vHasAppInfo      := True;
        vAppCPUPercent   := vCPUPercent;
        vAppWorkingSetMB := vWorkingSetMB;
        vAppCommitMB     := vCommitMB;
      end;

      if FTopProcessCount > 0 then
      begin
        { Top CPU }
        vIdxReplace := -1;
        for I1 := 0 to FTopProcessCount - 1 do
          if vCPUPercent > vTopCPUValues[I] then
          begin vIdxReplace := I1; Break; end;

        if vIdxReplace >= 0 then
        begin
          while vTopCPU.Count < FTopProcessCount do vTopCPU.Add('');
          for I1 := FTopProcessCount - 1 downto vIdxReplace + 1 do
          begin
            vTopCPUValues[I1] := vTopCPUValues[I1 - 1];
            vTopCPU[I1]       := vTopCPU[I1 - 1];
          end;
          vTopCPUValues[vIdxReplace] := vCPUPercent;
          vTopCPU[vIdxReplace] :=
            vProcName + '(PID=' + IntToStr(vPID) +
            ', CPU=' + FormatFloatInvariant(vCPUPercent) +
            '%, WS=' + IntToStr(vWorkingSetMB) + 'MB)';
        end;

        { Top Memory }
        vIdxReplace := -1;
        for I1 := 0 to FTopProcessCount - 1 do
          if vWorkingSetMB > vTopMemValues[I1] then
          begin vIdxReplace := I1; Break; end;

        if vIdxReplace >= 0 then
        begin
          while vTopMemory.Count < FTopProcessCount do vTopMemory.Add('');
          for I1 := FTopProcessCount - 1 downto vIdxReplace + 1 do
          begin
            vTopMemValues[I1]  := vTopMemValues[I1 - 1];
            vTopMemory[I1]     := vTopMemory[I1 - 1];
          end;
          vTopMemValues[vIdxReplace] := vWorkingSetMB;
          vTopMemory[vIdxReplace] :=
            vProcName + '(PID=' + IntToStr(vPID) +
            ', WS=' + IntToStr(vWorkingSetMB) +
            'MB, Commit=' + IntToStr(vCommitMB) + 'MB)';
        end;
      end;
    end;

    { System memory }
    TryGetSystemMemoryKB(vTotalKB, vAvailKB);
    vTotalMB := vTotalKB div 1024;
    vAvailMB := vAvailKB div 1024;

    { Hostname }
    vMachineName := SysUtils.GetEnvironmentVariable('HOSTNAME');
    if vMachineName = '' then
    begin
      if FileExists('/proc/sys/kernel/hostname') then
      begin
        AssignFile(vHostFile, '/proc/sys/kernel/hostname');
        {$I-} Reset(vHostFile); {$I+}
        if IOResult = 0 then
        begin
          try
            ReadLn(vHostFile, vMachineName);
            vMachineName := Trim(vMachineName);
          finally
            CloseFile(vHostFile);
          end;
        end;
      end;
    end;
    if vMachineName = '' then vMachineName := 'unknown';

    vLevel := 'Info';
    if vHasAppInfo then
      if ((FCPUAlertPercent > 0) and (Round(vAppCPUPercent) >= FCPUAlertPercent)) or
         ((FMemoryAlertMB > 0) and (vAppWorkingSetMB >= FMemoryAlertMB)) then
        vLevel := 'Warning';

    { MemoryLoad percent approximation on Linux }

    if vTotalKB > 0 then
      vMemLoad := ((vTotalKB - vAvailKB) * 100) div vTotalKB;

    Result :=
      'Level = '                         + vLevel +
      ' | MachineName = '                + vMachineName +
      ' | Sessions = '                   + IntToStr(ASessionCount) +
      ' | SystemMemoryLoad = '           + IntToStr(vMemLoad) + '%' +
      ' | SystemAvailableMemoryMB = '    + IntToStr(vAvailMB) +
      ' | SystemTotalPhysicalMemoryMB = '+ IntToStr(vTotalMB);

    if vHasAppInfo then
    begin
      if vPrevSysJ = 0 then
        Result := Result +
          ' | App = '             + ExtractFileName(ParamStr(0)) +
          ' | PID = '             + IntToStr(FCurrentPID) +
          ' | AppCPU = collecting' +
          ' | AppWorkingSetMB = ' + IntToStr(vAppWorkingSetMB) +
          ' | AppCommitMB = '     + IntToStr(vAppCommitMB)
      else
        Result := Result +
          ' | App = '             + ExtractFileName(ParamStr(0)) +
          ' | PID = '             + IntToStr(FCurrentPID) +
          ' | AppCPU = '          + FormatFloatInvariant(vAppCPUPercent) + '%' +
          ' | AppWorkingSetMB = ' + IntToStr(vAppWorkingSetMB) +
          ' | AppCommitMB = '     + IntToStr(vAppCommitMB);
    end;

    if vPrevSysJ = 0 then
      Result := Result + ' | TopCPU = collecting'
    else
      Result := Result + ' | TopCPU = ' + BuildTopProcessesText(vTopCPU);

    Result := Result + ' | TopMemory = ' + BuildTopProcessesText(vTopMemory);
  finally
    vTopCPU.Free;
    vTopMemory.Free;
  end;
end;

{$ENDIF LINUX}

{ ============================================================
  Fallback stubs for unsupported platforms
  ============================================================ }
{$IF NOT DEFINED(MSWINDOWS) AND NOT DEFINED(LINUX)}
function TPrismResourceMonitor.BuildCurrentAppSnapshot: string;
begin
  Result := '';
end;

function TPrismResourceMonitor.BuildSnapshotLog(const ASessionCount: Integer;
  const AIgnoreEnabled: Boolean = False): string;
begin
  Result := '';
end;
{$IFEND}

end.
