{
 +--------------------------------------------------------------------------+
  D2Bridge Framework Content

  Author: Talis Jonatas Gomes
  Email: talisjonatas@me.com

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

unit Prism.Log;

interface

uses
  Classes, SysUtils, SyncObjs,
{$IFDEF HAS_UNIT_SYSTEM_IOUTILS}
  System.IOUtils,
{$ENDIF}
  Prism.Types
;

type
 TPrismLog = class
  private
    FCriticalSection: TCriticalSection;
    FFileName: string;
<<<<<<< HEAD
    FIsDaily: Boolean;
    FLogDir: string;
    FCurrentLogDate: TDate;
    procedure EnsureDailyFile;
=======
    procedure AppendText(const AMessage: string);
    procedure WriteLineSafe(const AMessage: string);
>>>>>>> 22b2070468301f69d8179d0f848d3cfb7d8ecf4e
  public
    constructor Create(const FileName: string; const AAppendIfExists: Boolean = False);
    destructor Destroy; override;
    procedure Log(const SessionIdenty, ErrorForm, ErrorObject, ErrorEvent, ErrorMsg: string);
    procedure LogDiagnostic(const ACategory, AMessage: string);
    procedure LogSecurity(const AEvent: TSecurityEvent; const AIP, AUserAgent, ADescription: string; const AIsIPV6: boolean);
    procedure LogAccess(const AIP, AUserAgent, ASessionUser, ASessionIdentity, APrismDescription: string);
  end;

implementation

Uses
 D2Bridge.ServerControllerBase;

{ TPrismLog }

procedure TPrismLog.EnsureDailyFile;
var
  NewDate: TDate;
  NewFileName: string;
begin
  if not FIsDaily then Exit;
  NewDate := Trunc(Now);
  if NewDate = FCurrentLogDate then Exit;

  // Date changed - close current file, open new daily file
  if FileExists(FFileName) then
    CloseFile(FLogFile);

  FCurrentLogDate := NewDate;
  NewFileName := FLogDir + FormatDateTime('yyyy_mm_dd', NewDate) + '.txt';
  FFileName := NewFileName;

  AssignFile(FLogFile, FFileName);
  Rewrite(FLogFile);
  WriteLn(FLogFile, 'D2Bridge Framework');
  WriteLn(FLogFile, '');
  WriteLn(FLogFile, 'LOG Started in ' + DateTimeToStr(Now));
  WriteLn(FLogFile, '');
  Flush(FLogFile);
end;

constructor TPrismLog.Create(const FileName: string; const AAppendIfExists: Boolean = False);
begin
 FFileName:= FileName;
<<<<<<< HEAD
 FIsDaily := AAppendIfExists;
 FLogDir := IncludeTrailingPathDelimiter(ExtractFileDir(FileName));
 FCurrentLogDate := Trunc(Now);
=======
 FCriticalSection := TCriticalSection.Create;

 if (ExtractFileDir(FileName) <> '') and (not DirectoryExists(ExtractFileDir(FileName))) then
  ForceDirectories(ExtractFileDir(FileName));
>>>>>>> 22b2070468301f69d8179d0f848d3cfb7d8ecf4e

 if DirectoryExists(ExtractFileDir(FileName)) then
 begin
  if AAppendIfExists and FileExists(FileName) then
  begin
   AppendText('');
   AppendText('LOG Resumed in '+DateTimeToStr(Now));
   if not D2BridgeServerControllerBase.NeedConsole then
    AppendText('No seed console');
   AppendText('');
  end
  else
  begin
   AppendText('D2Bridge Framework');
   AppendText('by Talis Jonatas Gomes');
   AppendText('https://www.d2bridge.com.br');
   AppendText('');
   AppendText('LOG Started in '+DateTimeToStr(Now));
   if not D2BridgeServerControllerBase.NeedConsole then
    AppendText('No seed console');
   AppendText('');
  end;
 end;
end;

destructor TPrismLog.Destroy;
begin
  FreeAndNil(FCriticalSection);

  inherited;
end;

procedure TPrismLog.AppendText(const AMessage: string);
var
  vBytes: TBytes;
  vStream: TFileStream;
begin
  if FFileName = '' then
    Exit;

  if (ExtractFileDir(FFileName) <> '') and (not DirectoryExists(ExtractFileDir(FFileName))) then
    ForceDirectories(ExtractFileDir(FFileName));

  if FileExists(FFileName) then
    vStream := TFileStream.Create(FFileName, fmOpenReadWrite or fmShareDenyNone)
  else
    vStream := TFileStream.Create(FFileName, fmCreate or fmShareDenyNone);

  try
    vStream.Seek(0, soEnd);
    vBytes := TEncoding.Default.GetBytes(AMessage + sLineBreak);
    if Length(vBytes) > 0 then
      vStream.WriteBuffer(vBytes[0], Length(vBytes));
  finally
    vStream.Free;
  end;
end;

procedure TPrismLog.WriteLineSafe(const AMessage: string);
begin
  try
    AppendText(AMessage);
  except
  end;
end;

procedure TPrismLog.Log(const SessionIdenty, ErrorForm, ErrorObject, ErrorEvent, ErrorMsg: string);
var
 vMsg: string;
begin
 if FileExists(FFileName) or FIsDaily then
 begin
  FCriticalSection.Enter;
  try
   EnsureDailyFile;
    vMsg:= DateTimeToStr(Now);

    if SessionIdenty <> '' then
     vMsg:= vMsg + ' | Identy = ' + SessionIdenty;

    if ErrorForm <> '' then
     vMsg:= vMsg + ' | Form = ' + ErrorForm;

    if ErrorObject <> '' then
     vMsg:= vMsg + ' | Component = ' + ErrorObject;

    if ErrorEvent <> '' then
     vMsg:= vMsg + ' | Event = ' + ErrorEvent;

    if ErrorMsg <> '' then
     vMsg:= vMsg + ' | Error = ' + ErrorMsg;

    WriteLineSafe(vMsg);
  finally
    FCriticalSection.Leave;
  end;
 end;
end;

procedure TPrismLog.LogDiagnostic(const ACategory, AMessage: string);
var
  vMsg: string;
begin
  if FileExists(FFileName) then
  begin
    FCriticalSection.Enter;
    try
      vMsg := DateTimeToStr(Now) + ' | Diagnostic = ' + ACategory;

      if AMessage <> '' then
        vMsg := vMsg + ' | ' + AMessage;

      WriteLineSafe(vMsg);
    finally
      FCriticalSection.Leave;
    end;
  end;
end;

procedure TPrismLog.LogAccess(const AIP, AUserAgent, ASessionUser, ASessionIdentity, APrismDescription: string);
var
 vMsg: string;
begin
 if FileExists(FFileName) or FIsDaily then
 begin
  FCriticalSection.Enter;
  try
   EnsureDailyFile;
   vMsg:= DateTimeToStr(Now);

   vMsg:= vMsg + ' | New Access';

   if AIP <> '' then
    vMsg:= vMsg + ' | IP = ' + AIP;

   if AUserAgent <> '' then
    vMsg:= vMsg + ' | UserAgent = ' + AUserAgent;

   if ASessionUser <> '' then
    vMsg:= vMsg + ' | User = ' + ASessionUser;

   if ASessionIdentity <> '' then
    vMsg:= vMsg + ' | Identity = ' + ASessionIdentity;

  WriteLineSafe(vMsg);
  finally
   FCriticalSection.Leave;
  end;
 end;

end;

procedure TPrismLog.LogSecurity(const AEvent: TSecurityEvent; const AIP, AUserAgent, ADescription: string; const AIsIPV6: boolean);
var
 vMsg: string;
begin
 if FileExists(FFileName) or FIsDaily then
 begin
  FCriticalSection.Enter;
  try
   EnsureDailyFile;
   vMsg:= DateTimeToStr(Now);

   case AEvent of
    secBlockBlackList : vMsg:= vMsg + ' | Event = ' + 'Blocked BlackList';
    secDelistIPBlackList : vMsg:= vMsg + ' | Event = ' + 'Delist IP BlackList';
    secNotDelistIPBlackList : vMsg:= vMsg + ' | Event = ' + 'Not Delist IP BlackList';
    secBlockUserAgent : vMsg:= vMsg + ' | Event = ' + 'Blocked Agent';
    secBlockIPLimitConn : vMsg:= vMsg + ' | Event = ' + 'Blocked IP Limit Conn';
    secBlockIPLimitSession : vMsg:= vMsg + ' | Event = ' + 'Blocked IP Limit Session';
   end;

   if AIP <> '' then
    vMsg:= vMsg + ' | IP = ' + AIP;

   if AUserAgent <> '' then
    vMsg:= vMsg + ' | UserAgent = ' + AUserAgent;

   if AIsIPV6 then
    vMsg:= vMsg + ' | IPV6 = ' + 'True'
   else
    vMsg:= vMsg + ' | IPV6 = ' + 'False';

   if ADescription <> '' then
    vMsg:= vMsg + ' | Description = ' + ADescription;

  WriteLineSafe(vMsg);
  finally
   FCriticalSection.Leave;
  end;
 end;

end;

end.