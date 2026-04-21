{$IFDEF D2DOCKER}library{$ELSE}program{$ENDIF} D2BridgeWebAppVCL;

{$IFNDEF D2WindowsService}
{$IFDEF D2BRIDGE}
 //{$APPTYPE CONSOLE}
{$ENDIF}
{$ENDIF}

{Language Support Resource}

uses
  {$IFDEF D2WindowsService}
  Vcl.SvcMgr,
  Unit_D2Bridge_Server_Service in 'Unit_D2Bridge_Server_Service.pas',
  Unit_D2Bridge_Server_Core in 'Unit_D2Bridge_Server_Core.pas',  
  {$ELSE}
  Vcl.Forms,
  {$ENDIF}
  D2Bridge.ServerControllerBase in '{D2BridgePath}D2Bridge.ServerControllerBase.pas' {D2BridgeServerControllerBase: TDataModule},
  Prism.SessionBase in '{D2BridgePath}Prism\Prism.SessionBase.pas' {PrismSessionBase: TPrismSessionBase},
  {ProjectName}WebApp in '{ProjectName}WebApp.pas' {{ProjectName}WebAppGlobal},
  {ProjectName}_Session in '{ProjectName}_Session.pas' {{ProjectName}Session},
  D2BridgeFormTemplate in 'D2BridgeFormTemplate.pas',
  {Units}
  {Language Support}
  Unit1 in 'Unit1.pas' {Form1};

{$R *.res}

begin
  {$IFDEF D2WindowsService}
  if not Application.DelayInitialize or Application.Installing then
    Application.Initialize;

  Application.CreateForm(T{ProjectName}Service, {ProjectName}Service);
  Application.Run;
  {$ELSE}
  Application.Initialize;
  Application.MainFormOnTaskbar:= True;
  {Server}
  {Application.Run;}
  {$ENDIF}
end.
