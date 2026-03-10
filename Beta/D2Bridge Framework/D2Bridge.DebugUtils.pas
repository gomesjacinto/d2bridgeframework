{$I D2Bridge.inc}

unit D2Bridge.DebugUtils;

interface

function IsDebuggerPresent: Boolean;

implementation

uses
  {$IFDEF MSWINDOWS}
    Windows,
  {$ENDIF}
  SysUtils;

function IsDebuggerPresent: Boolean;
{$IFDEF MSWINDOWS}
begin
  Result := Windows.IsDebuggerPresent;
end;
{$ELSE}
var
  F: TextFile;
  Line: string;
  TracerPid: Integer;
begin
  Result := False;
  if not FileExists('/proc/self/status') then
    Exit;
  AssignFile(F, '/proc/self/status');
  try
    Reset(F);
    while not EOF(F) do
    begin
      ReadLn(F, Line);
      if Copy(Line, 1, 10) = 'TracerPid:' then
      begin
        TracerPid := StrToIntDef(Trim(Copy(Line, 11, MaxInt)), 0);
        Result := TracerPid <> 0;
        Break;
      end;
    end;
  finally
    CloseFile(F);
  end;
end;
{$ENDIF}

end.
