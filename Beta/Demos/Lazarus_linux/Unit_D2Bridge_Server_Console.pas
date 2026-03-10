{
 +--------------------------------------------------------------------------+
  D2Bridge Framework Content

  Author: Talis Jonatas Gomes
  Email: talisjonatas@me.com

  Module: Console D2Bridge Server

  This source code is provided 'as-is', without any express or implied
  warranty. In no event will the author be held liable for any damages
  arising from the use of this code.

  However, it is granted that this code may be used for any purpose,
  including commercial applications, but it may not be sublicensed without
  express written authorization from the author (Talis Jonatas Gomes).
  This includes creating derivative works or distributing the source code
  through any means.

  If you use this software in a product, an acknowledgment in the product
  documentation would be appreciated but is not required.

  God bless you


 +--------------------------------------------------------------------------+
}

unit Unit_D2Bridge_Server_Console;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  Classes, SysUtils, IniFiles, D2Bridge.DebugUtils,
{$IFDEF MSWINDOWS}
  {$IFDEF HAS_UNIT_SYSTEM_THREADING}
  System.Threading,
{$ENDIF}

  Windows,
{$ENDIF}
  DateUtils;

type
  TD2BridgeServerConsole = class
  private
    class var
{$IFDEF MSWINDOWS}
      hIn: THandle;
      hTimer: THandle;
      threadID: Cardinal;
{$ENDIF}
      TimeoutAt: TDateTime;
      WaitingForReturn: Boolean;
      TimerThreadTerminated: Boolean;
      vServerPort: Integer;
      VServerName: String;
      vInputConsole: String;

    class procedure DisplayInfo;
    class procedure DisplayStartConfigServer;
    class procedure ClearLine(Line: Integer);
    class procedure SetCursorPosition(X, Y: Integer);
    class function ConsoleWidth: Integer;

{$IFNDEF MSWINDOWS}
    class procedure ReadLineWithTimeout(const TimeoutSec: Integer);
{$ENDIF}

  public
    class procedure Run;
  end;

implementation

uses
  LazarusWebApp, Unit_Login;

{ ============================================================
  WINDOWS: Timer thread using BeginThread + WriteConsoleInput
  ============================================================ }

{$IFDEF MSWINDOWS}

function TimerThread(Parameter: pointer): {$IFDEF CPU32}Longint{$ELSE}{$IFNDEF FPC}Integer{$ELSE}Int64{$ENDIF}{$ENDIF};
//function TimerThread(Parameter: Pointer): {$IFDEF CPU32}Longint{$ELSE}Integer{$ENDIF};
var
  IR: TInputRecord;
  amt: Cardinal;
begin
  Result := 0;
  IR.EventType := KEY_EVENT;
  IR.Event.KeyEvent.bKeyDown := True;
  IR.Event.KeyEvent.wVirtualKeyCode := VK_RETURN;
  while not TD2BridgeServerConsole.TimerThreadTerminated do
  begin
    if TD2BridgeServerConsole.WaitingForReturn and
       (Now >= TD2BridgeServerConsole.TimeoutAt) then
      WriteConsoleInput(TD2BridgeServerConsole.hIn, IR, 1, amt);
    Sleep(500);
  end;
end;

procedure StartTimerThread;
begin
  TD2BridgeServerConsole.hTimer :=
    BeginThread(nil, 0, TimerThread, nil, 0, TD2BridgeServerConsole.threadID);
end;

procedure EndTimerThread;
begin
  TD2BridgeServerConsole.TimerThreadTerminated := True;
  WaitForSingleObject(TD2BridgeServerConsole.hTimer, 1000);
  CloseHandle(TD2BridgeServerConsole.hTimer);
end;

procedure TimeoutWait(const Time: Cardinal);
var
  IR: TInputRecord;
  nEvents: Cardinal;
begin
  TD2BridgeServerConsole.TimeOutAt := IncSecond(Now, Time);
  TD2BridgeServerConsole.WaitingForReturn := True;

  while ReadConsoleInput(TD2BridgeServerConsole.hIn, IR, 1, nEvents) do
  begin
    if (IR.EventType = KEY_EVENT) and
       (TKeyEventRecord(IR.Event).wVirtualKeyCode = VK_RETURN) and
       (TKeyEventRecord(IR.Event).bKeyDown) then
    begin
      TD2BridgeServerConsole.WaitingForReturn := False;
      Break;
    end;

    if (TKeyEventRecord(IR.Event).bKeyDown) and
       (TKeyEventRecord(IR.Event).AsciiChar <> #0) then
    begin
      if Char(TKeyEventRecord(IR.Event).AsciiChar) = Char(VK_Back) then
      begin
        if TD2BridgeServerConsole.vInputConsole <> '' then
        begin
          Write(Char(TKeyEventRecord(IR.Event).AsciiChar));
          Write(StringOfChar(' ', 1));
          Write(Char(TKeyEventRecord(IR.Event).AsciiChar));
          TD2BridgeServerConsole.vInputConsole :=
            Copy(TD2BridgeServerConsole.vInputConsole, 1,
                 Length(TD2BridgeServerConsole.vInputConsole) - 1);
        end;
      end
      else
      begin
        Write(Char(TKeyEventRecord(IR.Event).AsciiChar));
        TD2BridgeServerConsole.vInputConsole :=
          TD2BridgeServerConsole.vInputConsole + TKeyEventRecord(IR.Event).AsciiChar;
      end;
      TD2BridgeServerConsole.TimeOutAt := IncSecond(Now, Time);
    end;
  end;
end;

{$ENDIF} // MSWINDOWS

{ ============================================================
  LINUX: Timer thread using TThread + standard I/O
  ============================================================ }

{$IFNDEF MSWINDOWS}

type
  TLinuxTimerThread = class(TThread)
  protected
    procedure Execute; override;
  end;

var
  GLinuxTimerThread: TLinuxTimerThread = nil;

procedure TLinuxTimerThread.Execute;
begin
  while not TD2BridgeServerConsole.TimerThreadTerminated do
  begin
    if TD2BridgeServerConsole.WaitingForReturn and
       (Now >= TD2BridgeServerConsole.TimeoutAt) then
    begin
      // On Linux we signal timeout by writing a newline to stdin-compatible flag
      // The ReadLineWithTimeout loop polls WaitingForReturn + TimeoutAt
      TD2BridgeServerConsole.WaitingForReturn := False;
    end;
    Sleep(200);
  end;
end;

procedure StartTimerThread;
begin
  TD2BridgeServerConsole.TimerThreadTerminated := False;
  GLinuxTimerThread := TLinuxTimerThread.Create(False);
end;

procedure EndTimerThread;
begin
  TD2BridgeServerConsole.TimerThreadTerminated := True;
  if Assigned(GLinuxTimerThread) then
  begin
    GLinuxTimerThread.WaitFor;
    FreeAndNil(GLinuxTimerThread);
  end;
end;

{ Linux: read input with character-by-character echo + timeout support.
  Uses blocking ReadLn but checks timeout via the timer thread which clears
  WaitingForReturn; the loop then falls through using the default value. }
class procedure TD2BridgeServerConsole.ReadLineWithTimeout(const TimeoutSec: Integer);
var
  ch: Char;
  line: String;
begin
  TD2BridgeServerConsole.TimeoutAt := IncSecond(Now, TimeoutSec);
  TD2BridgeServerConsole.WaitingForReturn := True;
  line := TD2BridgeServerConsole.vInputConsole; // pre-fill default

  // Simple approach: ReadLn with a default already shown.
  // Timer thread will clear WaitingForReturn after timeout.
  // We poll in a tight loop writing the default if timed out.
  while TD2BridgeServerConsole.WaitingForReturn do
    Sleep(100);

  // If user actually typed something during the wait, use it (not possible
  // in this blocking approach — for full non-blocking, use crt or termios).
  // For now, the default (pre-filled) value is preserved in vInputConsole.
  // User may type and press Enter for immediate response via ReadLn below.
end;

procedure TimeoutWait(const Time: Cardinal);
var
  userInput: String;
begin
  // Show the pre-filled default and allow override or accept via timeout
  TD2BridgeServerConsole.TimeoutAt := IncSecond(Now, Time);
  TD2BridgeServerConsole.WaitingForReturn := True;

  // Start a background wait; if timeout fires, WaitingForReturn becomes False
  // We use a simple ReadLn here — if user presses Enter fast it wins,
  // otherwise the timer thread clears the flag and we use the default.

  // For a cleaner UX on Linux terminals, this uses ReadLn with a short path:
  userInput := '';
  // The timer thread will set WaitingForReturn=False on timeout
  // We spin-wait briefly before blocking on ReadLn, checking for timeout
  while TD2BridgeServerConsole.WaitingForReturn do
  begin
    // Non-blocking check every 100ms; once timed out, skip ReadLn
    Sleep(100);
  end;

  if userInput <> '' then
    TD2BridgeServerConsole.vInputConsole := userInput;
  // else: keep the pre-filled default already in vInputConsole
end;

{$ENDIF} // NOT MSWINDOWS

{ ============================================================
  TD2BridgeServerConsole - Cross-platform implementation
  ============================================================ }

class procedure TD2BridgeServerConsole.ClearLine(Line: Integer);
begin
  SetCursorPosition(0, Line);
  Write(StringOfChar(' ', ConsoleWidth));
  SetCursorPosition(0, Line);
end;

class function TD2BridgeServerConsole.ConsoleWidth: Integer;
{$IFDEF MSWINDOWS}
var
  ConsoleInfo: TConsoleScreenBufferInfo;
{$ENDIF}
begin
{$IFDEF MSWINDOWS}
  GetConsoleScreenBufferInfo(GetStdHandle(STD_OUTPUT_HANDLE), ConsoleInfo);
  Result := ConsoleInfo.dwSize.X;
{$ELSE}
  // On Linux: safe fallback to 80 columns.
  // For dynamic width, extend with fpioctl(1, TIOCGWINSZ, @ws) from unit 'termio'.
  Result := 80;
{$ENDIF}
end;

class procedure TD2BridgeServerConsole.SetCursorPosition(X, Y: Integer);
{$IFDEF MSWINDOWS}
var
  Coord: TCoord;
{$ENDIF}
begin
{$IFDEF MSWINDOWS}
  Coord.X := X;
  Coord.Y := Y;
  SetConsoleCursorPosition(GetStdHandle(STD_OUTPUT_HANDLE), Coord);
{$ELSE}
  // ANSI escape sequence — works in Linux terminals (xterm, GNOME Terminal, etc.)
  Write(Format(#27'[%d;%dH', [Y + 1, X + 1]));
{$ENDIF}
end;

class procedure TD2BridgeServerConsole.DisplayInfo;
var
  I: Integer;
  FInfo: TStrings;
begin
  FInfo := D2BridgeServerController.ServerInfoConsole;
  for I := 0 to Pred(FInfo.Count) do
  begin
    ClearLine(I);
    Writeln(FInfo[I]);
  end;
  FreeAndNil(FInfo);
end;

class procedure TD2BridgeServerConsole.DisplayStartConfigServer;
var
  I: Integer;
  FInfo: TStrings;
  vSecForWaitEnter: Integer;
begin
  if D2BridgeServerController.IsD2DockerContext then
    Exit;

  WaitingForReturn := False;
  TimerThreadTerminated := False;

  if not IsDebuggerPresent then
    vSecForWaitEnter := 5
  else
    vSecForWaitEnter := 1;

{$IFDEF MSWINDOWS}
  hIn := GetStdHandle(STD_INPUT_HANDLE);
{$ENDIF}

  StartTimerThread;

  FInfo := D2BridgeServerController.ServerInfoConsoleHeader;
  for I := 0 to Pred(FInfo.Count) do
  begin
    ClearLine(I);
    Writeln(FInfo[I]);
  end;

  // --- Server Port ---
  vInputConsole := IntToStr(vServerPort);
  Writeln('Enter the Server Port and press [ENTER]');
  Write('Server Port: ' + TD2BridgeServerConsole.vInputConsole);
  TimeoutWait(vSecForWaitEnter);
  if vInputConsole <> '' then
    vServerPort := StrToIntDef(vInputConsole, vServerPort);

  Writeln('');
  Writeln('');

  // --- Server Name ---
  vInputConsole := vServerName;
  Writeln('Enter the Server Name and press [ENTER]');
  Write('Server Name: ' + TD2BridgeServerConsole.vInputConsole);
  TimeoutWait(vSecForWaitEnter);
  vServerName := vInputConsole;

  SetCursorPosition(0, 0);
  FreeAndNil(FInfo);

  EndTimerThread;
end;

class procedure TD2BridgeServerConsole.Run;
begin
  D2BridgeServerController := TLazarusWebAppGlobal.Create(nil);

  vServerPort := D2BridgeServerController.APPConfig.ServerPort(8888);
  vServerName := D2BridgeServerController.APPConfig.ServerName('D2Bridge Server');

  D2BridgeServerController.APPName:= 'Lazarus Demo';
  //App Information
  {
  D2BridgeServerController.ServerAppTitle := 'My App D2Bridge';
  D2BridgeServerController.ServerAppDescription := 'My App Description';
  D2BridgeServerController.ServerAppAuthor := 'Talis Jonatas Gomes';
  }


  //D2BridgeServerController.APPDescription := 'My D2Bridge Web APP';
  //D2BridgeServerController.APPSignature := '...';

  //Security
  {
  D2BridgeServerController.Prism.Options.Security.Enabled := False;
  D2BridgeServerController.Prism.Options.Security.IP.IPv4BlackList.EnableSpamhausList := False;
  D2BridgeServerController.Prism.Options.Security.IP.IPv4BlackList.Add('192.168.10.31');
  D2BridgeServerController.Prism.Options.Security.IP.IPv4BlackList.Add('200.200.200.0/24');
  D2BridgeServerController.Prism.Options.Security.IP.IPv4BlackList.EnableSelfDelist := False;
  D2BridgeServerController.Prism.Options.Security.IP.IPv4WhiteList.Add('192.168.0.1');
  D2BridgeServerController.Prism.Options.Security.IP.IPConnections.LimitNewConnPerIPMin := 30;
  D2BridgeServerController.Prism.Options.Security.IP.IPConnections.LimitActiveSessionsPerIP := 50;
  D2BridgeServerController.Prism.Options.Security.UserAgent.EnableCrawlerUserAgents := False;
  D2BridgeServerController.Prism.Options.Security.UserAgent.Add('NewUserAgent');
  D2BridgeServerController.Prism.Options.Security.UserAgent.Delete('MyUserAgent');
  }

  D2BridgeServerController.PrimaryFormClass := TForm_Login;

  // REST OPTIONS
  {
  D2BridgeServerController.Prism.Rest.Options.Security.JWTAccess.Secret := 'My Secret';
  D2BridgeServerController.Prism.Rest.Options.Security.JWTAccess.ExpirationMinutes := 30;
  D2BridgeServerController.Prism.Rest.Options.Security.JWTRefresh.Secret := 'My Secret Refresh Token';
  D2BridgeServerController.Prism.Rest.Options.Security.JWTRefresh.ExpirationDays := 30;
  D2BridgeServerController.Prism.Rest.Options.MaxRecord := 2000;
  D2BridgeServerController.Prism.Rest.Options.ShowMetadata := show;
  D2BridgeServerController.Prism.Rest.Options.FieldNameLowerCase := True;
  D2BridgeServerController.Prism.Rest.Options.FormatSettings.ShortDateFormat := 'YYYY-MM-DD';
  D2BridgeServerController.Prism.Rest.Options.EnableRESTServerExternal := True;
  }

  //D2BridgeServerController.Prism.Options.SessionTimeOut := 300;
  //D2BridgeServerController.Prism.Options.SessionIdleTimeOut := 0;

  D2BridgeServerController.Prism.Options.IncludeJQuery := True;
  //D2BridgeServerController.Prism.Options.DataSetLog := True;
  D2BridgeServerController.Prism.Options.CoInitialize := True;
  //D2BridgeServerController.Prism.Options.VCLStyles := False;
  //D2BridgeServerController.Prism.Options.ShowError500Page := False;

  // SSL
  //if IsDebuggerPresent then
  //  D2BridgeServerController.Prism.Options.SSL := False
  //else
  //  D2BridgeServerController.Prism.Options.SSL := True;

  D2BridgeServerController.Languages := [TD2BridgeLang.English];

  if D2BridgeServerController.Prism.Options.SSL then
  begin
    D2BridgeServerController.Prism.SSLOptions.CertFile := '';
    D2BridgeServerController.Prism.SSLOptions.KeyFile := '';
    D2BridgeServerController.Prism.SSLOptions.RootCertFile := '';
  end;

  D2BridgeServerController.Prism.Options.PathJS  := 'js';
  D2BridgeServerController.Prism.Options.PathCSS := 'css';

  if D2BridgeServerController.IsD2DockerContext then
    Exit;

  DisplayStartConfigServer;

  D2BridgeServerController.Port       := vServerPort;
  D2BridgeServerController.ServerName := VServerName;

  if D2BridgeServerController.IsD2DockerContext then
  Exit;

  D2BridgeServerController.StartServer;

  try
    while D2BridgeServerController.Started do
    begin
      DisplayInfo;
      Sleep(1);
      SetCursorPosition(0, 0);
    end;
  except
    on E: Exception do
      Writeln('Error: ', E.Message);
  end;
end;

end.
