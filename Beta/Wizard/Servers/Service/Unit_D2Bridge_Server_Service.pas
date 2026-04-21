{
  ------------------------------------------------------------------------------
  D2Bridge Windows Service Extension
  ------------------------------------------------------------------------------

  Original Framework:
    D2Bridge Framework
    Author: Talis Jonatas Gomes

  This unit adds Windows Service support to the D2Bridge framework,
  enabling D2Bridge Web applications to run as native Windows Services.

  Windows Service integration, architecture adaptation and service lifecycle
  implementation by:
    Hamid Reza Kabiri
	hamid.kabiri@gmail.com
	https://github.com/kabiri
	
  Notes:
    - This extension does not modify the original D2Bridge core.
    - It provides an alternative hosting model (Windows Service).
    - Console and Docker modes remain fully supported.

  ------------------------------------------------------------------------------

  Good Thoughts, Good Words, Good Deeds.
}
unit Unit_D2Bridge_Server_Service;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Types,
  Vcl.SvcMgr;

type
  T{ProjectName}Service = class(TService)
	procedure ServiceDestroy(Sender: TObject);
  private
    FServerThread: TThread;
  public
    function GetServiceController: TServiceController; override;
  published
    procedure ServiceStart(Sender: TService; var Started: Boolean);
    procedure ServiceStop(Sender: TService; var Stopped: Boolean);
  end;

var
  {ProjectName}Service: T{ProjectName}Service;

implementation

uses
  {ProjectName}WebApp,
  Unit_D2Bridge_Server_Core;

{$R *.dfm}

procedure ServiceController(CtrlCode: DWord); stdcall;
begin
  {ProjectName}Service.Controller(CtrlCode);
end;

function T{ProjectName}Service.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;

procedure T{ProjectName}Service.ServiceStart(Sender: TService; var Started: Boolean);
begin
  FServerThread :=
    TThread.CreateAnonymousThread(
      procedure
      begin
        try
          T{ProjectName}ServerCore.Start;
        except
          on E: Exception do
            LogMessage('Start error: ' + E.Message);
        end;
      end
    );
  FServerThread.FreeOnTerminate:=True;
  FServerThread.Start;

  Started := True;
end;

procedure T{ProjectName}Service.ServiceStop(Sender: TService; var Stopped: Boolean);
begin
  try
    T{ProjectName}ServerCore.Stop;
    Stopped := True;
  except
    Stopped := False;
  end;
end;

procedure T{ProjectName}Service.ServiceDestroy(Sender: TObject);
begin
  if Assigned(D2BridgeServerController) then
    FreeAndNil(D2BridgeServerController);
end;

end.