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

{$I D2Bridge.inc}

unit D2Bridge.APPConfig.Version;

interface

uses
 Classes, SysUtils, IniFiles, TypInfo,
{$IFDEF MSWINDOWS}
 Windows,
{$ENDIF}
{$IFDEF LINUX}
 baseunix,
 linux,
{$ENDIF}
 D2Bridge.Interfaces;

type
 TD2BridgeAppConfigVersion = class(TInterfacedPersistent, ID2BridgeAPPConfigVersion)
  private
   FBuild: Integer;
   FMajor: Integer;
   FMinor: Integer;
   FRelease: Integer;
   function GetBuild: Integer;
   function GetMajor: Integer;
   function GetMinor: Integer;
   function GetRelease: Integer;
   function GetVersionStr: string;
   procedure SetBuild(const Value: Integer);
   procedure SetMajor(const Value: Integer);
   procedure SetMinor(const Value: Integer);
   procedure SetRelease(const Value: Integer);
   procedure SetVersionStr(const Value: string);
  public
   constructor Create;

  published
   property Build: Integer read GetBuild write SetBuild;
   property Major: Integer read GetMajor write SetMajor;
   property Minor: Integer read GetMinor write SetMinor;
   property Release: Integer read GetRelease write SetRelease;
   property VersionStr: string read GetVersionStr write SetVersionStr;
 end;

implementation

function GetExecutableVersion: string;
{$IFDEF MSWINDOWS}
var
  VerInfoSize, VerHandle: DWORD;
  VerBuffer: Pointer;
  FixedInfo: PVSFixedFileInfo;
  FileName: array[0..MAX_PATH - 1] of Char;
{$ENDIF}
{$IFDEF LINUX}
var
 FileName: string;
 VersionFile: TextFile;
 VersionLine: string;
 FileStream: TFileStream;
 Buffer: array[0..255] of Byte;
 BytesRead: Integer;
 VersionStr: string;
 Major, Minor, Release, Build: Integer;
{$ENDIF}
begin
  {$IFDEF MSWINDOWS}
  Result := '0.0.0.0';

  // Pega o caminho do módulo atual (EXE ou DLL)
  if GetModuleFileName(HInstance, FileName, MAX_PATH) = 0 then
    Exit;

  VerInfoSize := GetFileVersionInfoSize(FileName, VerHandle);
  if VerInfoSize = 0 then Exit;

  GetMem(VerBuffer, VerInfoSize);
  try
    if GetFileVersionInfo(FileName, VerHandle, VerInfoSize, VerBuffer) then
    begin
      if VerQueryValue(VerBuffer, '\', Pointer(FixedInfo), VerInfoSize) then
      begin
        Result := Format('%d.%d.%d.%d',
          [HiWord(FixedInfo.dwFileVersionMS),
           LoWord(FixedInfo.dwFileVersionMS),
           HiWord(FixedInfo.dwFileVersionLS),
           LoWord(FixedInfo.dwFileVersionLS)]);
      end;
    end;
  finally
    FreeMem(VerBuffer);
  end;
  {$ENDIF}

  {$IFDEF LINUX}
  Result := '1.0.0.0'; // Versão padrão para Linux
  
  // Estratégia 1: Tentar ler do arquivo .version no mesmo diretório
  FileName := ExtractFilePath(ParamStr(0)) + '.version';
  if FileExists(FileName) then
  begin
    try
      AssignFile(VersionFile, FileName);
      Reset(VersionFile);
      try
        ReadLn(VersionFile, VersionLine);
        VersionLine := Trim(VersionLine);
        if VersionLine <> '' then
          Result := VersionLine;
      finally
        CloseFile(VersionFile);
      end;
    except
      // Ignora erros de leitura
    end;
  end
  else
  begin
    // Estratégia 2: Tentar ler variável de ambiente
    VersionLine := GetEnvironmentVariable('APP_VERSION');
    if VersionLine <> '' then
      Result := VersionLine
    else
    begin
      // Estratégia 3: Usar data de compilação como versão
      {$IFDEF DEBUG}
      Result := '1.0.0.0-DEBUG';
      {$ELSE}
      Result := Format('1.0.0.%d', [
        Trunc((Now - EncodeDate(2024, 1, 1)) / 1)
      ]);
      {$ENDIF}
    end;
  end;
  
  // Garantir que a versão está no formato correto (X.X.X.X)
  Major := 1; Minor := 0; Release := 0; Build := 0;
  
  // Tenta extrair números da string de versão
  VersionStr := Result;
  if VersionStr.Contains('.') then
  begin
    // Aqui você pode implementar a lógica de parsing
    // Por enquanto, mantém o resultado como está
  end;
  {$ENDIF}
end;

{ TD2BridgeAppConfigVersion }

constructor TD2BridgeAppConfigVersion.Create;
begin
 inherited;

 FMajor:= -1;
 FMinor:= -1;
 FRelease:= -1;
 FBuild:= -1;
end;

function TD2BridgeAppConfigVersion.GetBuild: Integer;
begin
 if (FMajor < 0) and (FMinor < 0) and (FRelease < 0) and (FBuild < 0) then
  SetVersionStr(GetVersionStr);

 Result := FBuild;
end;

function TD2BridgeAppConfigVersion.GetMajor: Integer;
begin
 if (FMajor < 0) and (FMinor < 0) and (FRelease < 0) and (FBuild < 0) then
  SetVersionStr(GetVersionStr);

 Result := FMajor;
end;

function TD2BridgeAppConfigVersion.GetMinor: Integer;
begin
 if (FMajor < 0) and (FMinor < 0) and (FRelease < 0) and (FBuild < 0) then
  SetVersionStr(GetVersionStr);

 Result := FMinor;
end;

function TD2BridgeAppConfigVersion.GetRelease: Integer;
begin
 if (FMajor < 0) and (FMinor < 0) and (FRelease < 0) and (FBuild < 0) then
  SetVersionStr(GetVersionStr);

 Result := FRelease;
end;

function TD2BridgeAppConfigVersion.GetVersionStr: string;
begin
 if (FMajor < 0) and (FMinor < 0) and (FRelease < 0) and (FBuild < 0) then
  Result := GetExecutableVersion
 else
  Result := Format('%d.%d.%d.%d', [FMajor, FMinor, FRelease, FBuild]);
end;

procedure TD2BridgeAppConfigVersion.SetBuild(const Value: Integer);
begin
 FBuild := Value;
end;

procedure TD2BridgeAppConfigVersion.SetMajor(const Value: Integer);
begin
 FMajor := Value;
end;

procedure TD2BridgeAppConfigVersion.SetMinor(const Value: Integer);
begin
 FMinor := Value;
end;

procedure TD2BridgeAppConfigVersion.SetRelease(const Value: Integer);
begin
 FRelease := Value;
end;

procedure TD2BridgeAppConfigVersion.SetVersionStr(const Value: string);
var
 Parts: TArray<string>;
 i: Integer;
 TempStr: string;
begin
 // Remove qualquer texto adicional (como -DEBUG)
 TempStr := Value;
 i := Pos('-', TempStr);
 if i > 0 then
  TempStr := Copy(TempStr, 1, i - 1);
 
 Parts := TempStr.Split(['.']);
  
 FMajor := 0;
 FMinor := 0;
 FRelease := 0;
 FBuild := 0;
 
 if Length(Parts) > 0 then FMajor := StrToIntDef(Parts[0], 1);
 if Length(Parts) > 1 then FMinor := StrToIntDef(Parts[1], 0);
 if Length(Parts) > 2 then FRelease := StrToIntDef(Parts[2], 0);
 if Length(Parts) > 3 then FBuild := StrToIntDef(Parts[3], 0);
  
 // Garantir valores mínimos
 if FMajor < 1 then FMajor := 1;
 if FMinor < 0 then FMinor := 0;
 if FRelease < 0 then FRelease := 0;
 if FBuild < 0 then FBuild := 0;
end;

end.
