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

unit Prism.Grid;

interface

uses
  Classes, SysUtils, Generics.Collections,
{$IFDEF FMX}
  FMX.Graphics, FMX.Types,
{$ELSE}
  Graphics, Grids, DBGrids,
{$ENDIF}
  Prism.Forms.Controls, Prism.Interfaces, Prism.Grid.Columns;


type
 TPrismGrid = class(TPrismControl, IPrismGrid)
  private
   FPrismGridColumns: TPrismGridColumns;
   FMultiSelect: Boolean;
   FMultiSelectWidth: integer;
   FMaxRecords: Integer;
   FRecordsPerPage: Integer;
   FShowPager: boolean;
   FTitleFontSize: Integer;
   FTitleFontColor: {$IFNDEF FMX}TColor{$ELSE}TAlphaColor{$ENDIF};
   FTitleFontStyles: TFontStyles;
   FTitleBackgroundColor: {$IFNDEF FMX}TColor{$ELSE}TAlphaColor{$ENDIF};
  FImportStylesComponents: Boolean;
   FZebraGrid: Boolean;
   FZebraOddColor: {$IFNDEF FMX}TColor{$ELSE}TAlphaColor{$ENDIF};
   FZebraPairColor: {$IFNDEF FMX}TColor{$ELSE}TAlphaColor{$ENDIF};
{$IFDEF FPC}
  protected
{$ENDIF}
   function GetMaxRecords: integer;
   Procedure SetMaxRecords(AMaxRecords: Integer);
   function GetRecordsPerPage: integer;
   Procedure SetRecordsPerPage(ARecordsPerPage: Integer);
   function GetMultiSelect: Boolean;
   Procedure SetMultiSelect(AMultiSelect: Boolean);
   function GetShowPager: Boolean;
   Procedure SetShowPager(Value: Boolean);
   function GetMultiSelectWidth: integer;
   Procedure SetMultiSelectWidth(Value: integer);
   function GetTitleFontSize: Integer;
   Procedure SetTitleFontSize(Value: Integer);
   function GetTitleFontColor: {$IFNDEF FMX}TColor{$ELSE}TAlphaColor{$ENDIF};
   Procedure SetTitleFontColor(Value: {$IFNDEF FMX}TColor{$ELSE}TAlphaColor{$ENDIF});
   function GetTitleFontStyles: TFontStyles;
   Procedure SetTitleFontStyles(Value: TFontStyles);
   function GetTitleBackgroundColor: {$IFNDEF FMX}TColor{$ELSE}TAlphaColor{$ENDIF};
   procedure SetTitleBackgroundColor(Value: {$IFNDEF FMX}TColor{$ELSE}TAlphaColor{$ENDIF});
  function GetImportStylesComponents: Boolean;
  procedure SetImportStylesComponents(Value: Boolean);
   function GetZebraGrid: Boolean;
   procedure SetZebraGrid(Value: Boolean);
   function GetZebraOddColor: {$IFNDEF FMX}TColor{$ELSE}TAlphaColor{$ENDIF};
   procedure SetZebraOddColor(Value: {$IFNDEF FMX}TColor{$ELSE}TAlphaColor{$ENDIF});
   function GetZebraPairColor: {$IFNDEF FMX}TColor{$ELSE}TAlphaColor{$ENDIF};
   procedure SetZebraPairColor(Value: {$IFNDEF FMX}TColor{$ELSE}TAlphaColor{$ENDIF});

  protected
    procedure ApplyImportedComponentStyles; virtual;
    procedure ApplyImportedBaseStyle(const AFont: TFont; const ABackgroundColor: {$IFNDEF FMX}TColor{$ELSE}TAlphaColor{$ENDIF}); virtual;
    procedure ApplyImportedDBGridStyles(AGrid: TDBGrid); virtual;
    procedure ApplyImportedStringGridStyles(AGrid: TStringGrid); virtual;
    function ClientGridSelectorJS: string;
    function ClientGridReloadDataJS(const AJSONData: string): string;
    function ClientGridHydrationJS(const AJSONData: string; const ADelayMS: Integer): string;
    function BuildColumnLabelHTML(AColumn: IPrismGridColumn; const ATextAlign: string): string;
    function BuildGridStyleBlock: string;
    function ColorStyle(const APropertyName: string; const AColor: {$IFNDEF FMX}TColor{$ELSE}TAlphaColor{$ENDIF}; const AAllowNone: Boolean = false): string;
    function FontStylesToCSS(const AFontStyles: TFontStyles): string;
   //Abstract
   procedure SetDataToJSON; virtual; abstract;
   function GetDataToJSON: String; virtual; abstract;
   function GetSelectedRowsID: TList<Integer>; virtual; abstract;
   procedure SetSelectedRowsID(Value: TList<Integer>); virtual; abstract;
   procedure CellPostbyJSON(AJSON: string; out ARowID: string; out AErrorMessage: string); virtual; abstract;
   function GetEditable: Boolean; virtual; abstract;
   function RecNo: integer; overload; virtual; abstract;
   function RecNo(AValue: Integer): boolean; overload; virtual; abstract;
  public
   constructor Create(AOwner: TObject); override;
   destructor Destroy; override;

   function Columns: IPrismGridColumns;

   property MaxRecords: Integer read GetMaxRecords write SetMaxRecords;
   property RecordsPerPage: Integer read GetRecordsPerPage write SetRecordsPerPage;
   property MultiSelect: Boolean read GetMultiSelect write SetMultiSelect;
   property MultiSelectWidth: integer read GetMultiSelectWidth write SetMultiSelectWidth;
   property SelectedRowsID: TList<Integer> read GetSelectedRowsID write SetSelectedRowsID;
   property ShowPager: Boolean read GetShowPager write SetShowPager;
   property Editable: Boolean read GetEditable;
   property DataToJSON: String read GetDataToJSON;
   property TitleFontSize: Integer read GetTitleFontSize write SetTitleFontSize;
   property TitleFontColor: {$IFNDEF FMX}TColor{$ELSE}TAlphaColor{$ENDIF} read GetTitleFontColor write SetTitleFontColor;
   property TitleFontStyles: TFontStyles read GetTitleFontStyles write SetTitleFontStyles;
   property TitleBackgroundColor: {$IFNDEF FMX}TColor{$ELSE}TAlphaColor{$ENDIF} read GetTitleBackgroundColor write SetTitleBackgroundColor;
   property ImportStylesComponents: Boolean read GetImportStylesComponents write SetImportStylesComponents;
   property ZebraGrid: Boolean read GetZebraGrid write SetZebraGrid;
   property ZebraOddColor: {$IFNDEF FMX}TColor{$ELSE}TAlphaColor{$ENDIF} read GetZebraOddColor write SetZebraOddColor;
   property ZebraPairColor: {$IFNDEF FMX}TColor{$ELSE}TAlphaColor{$ENDIF} read GetZebraPairColor write SetZebraPairColor;
 end;


implementation

uses
  D2Bridge.Util, D2Bridge.Item.VCLObj.Style;

{ TPrismGrid }

function TPrismGrid.BuildColumnLabelHTML(AColumn: IPrismGridColumn;
  const ATextAlign: string): string;
var
 vStyle: string;
begin
 vStyle:= 'text-align: ' + ATextAlign + '; ';
 vStyle:= vStyle + FontStylesToCSS(AColumn.TitleFontStyles);
 vStyle:= vStyle + ColorStyle('color', AColumn.TitleFontColor);

 Result:= '<div class="d2bridgedbgridtitle" style="' + vStyle + '">' + AColumn.Title + '</div>';
end;

function TPrismGrid.BuildGridStyleBlock: string;
var
 I: Integer;
 vStyle: TStringList;
 vGridSelector: string;
 vHeaderSelector: string;
 vHeaderStyle: string;
 vHeaderTextStyle: string;
begin
 vStyle:= TStringList.Create;
 try
  vGridSelector:= '#gbox_' + AnsiUpperCase(NamePrefix);
  vStyle.Add('<style>');

  vHeaderStyle:= ColorStyle('background-color', TitleBackgroundColor) +
                 ColorStyle('border-color', TitleBackgroundColor);
  if TitleBackgroundColor <> {$IFNDEF FMX}clNone{$ELSE}TAlphaColors.Null{$ENDIF} then
   vHeaderStyle:= vHeaderStyle + 'background-image: none; box-shadow: none; ';
  if vHeaderStyle <> '' then
   vStyle.Add(vGridSelector + ' .ui-jqgrid-htable th { ' + vHeaderStyle + '}');

  vHeaderTextStyle:= '';
  if TitleFontSize > 0 then
   vHeaderTextStyle:= vHeaderTextStyle + 'font-size: ' + IntToStr(TitleFontSize) + 'px; ';
  vHeaderTextStyle:= vHeaderTextStyle + FontStylesToCSS(TitleFontStyles);
  vHeaderTextStyle:= vHeaderTextStyle + ColorStyle('color', TitleFontColor);
  if vHeaderTextStyle <> '' then
   vStyle.Add(vGridSelector + ' .ui-jqgrid-htable .d2bridgedbgridtitle { ' + vHeaderTextStyle + '}');

  if ZebraGrid then
  begin
   vStyle.Add(vGridSelector + ' .ui-jqgrid-btable > tbody > tr.jqgrow:nth-child(odd) > td { ' +
     ColorStyle('background-color', ZebraOddColor) + '}');
   vStyle.Add(vGridSelector + ' .ui-jqgrid-btable > tbody > tr.jqgrow:nth-child(even) > td { ' +
     ColorStyle('background-color', ZebraPairColor) + '}');
  end;

  for I := 0 to Pred(Columns.Items.Count) do
  begin
   vHeaderSelector:= vGridSelector + ' th#' + AnsiUpperCase(NamePrefix) + '_' + Columns.Items[I].ColName;
   vHeaderStyle:= ColorStyle('background-color', Columns.Items[I].TitleBackgroundColor) +
                  ColorStyle('border-color', Columns.Items[I].TitleBackgroundColor);
   if vHeaderStyle <> '' then
    vStyle.Add(vHeaderSelector + ' { ' + vHeaderStyle + 'background-image: none; box-shadow: none; }');

   vHeaderStyle:= FontStylesToCSS(Columns.Items[I].FontStyles) +
                  ColorStyle('color', Columns.Items[I].FontColor) +
                  ColorStyle('background-color', Columns.Items[I].BackgroundColor);
   if vHeaderStyle <> '' then
    vStyle.Add(vGridSelector + ' .ui-jqgrid-btable td[aria-describedby="' +
      AnsiUpperCase(NamePrefix) + '_' + Columns.Items[I].ColName + '"] { ' + vHeaderStyle + '}');
  end;

  vStyle.Add('</style>');
  if vStyle.Count = 2 then
   Result:= ''
  else
   Result:= vStyle.Text;
 finally
  vStyle.Free;
 end;
end;

function TPrismGrid.ClientGridHydrationJS(const AJSONData: string;
  const ADelayMS: Integer): string;
begin
 Result:=
  '(function(){' +
  'var d2bridgeGridData = ' + AJSONData + ';' +
  'var d2bridgeGridName = "' + AnsiUpperCase(NamePrefix) + '";' +
  'function d2bridgeGridLog(msg){' +
  ' if(window.console && window.D2BridgeDebugGridTiming){' +
  '  console.debug("[D2Grid][" + d2bridgeGridName + "] " + msg);' +
  ' }' +
  '}' +
  'function d2bridgeSchedule(callback, delay){' +
  ' setTimeout(function(){' +
  '  if(window.requestAnimationFrame){' +
  '   window.requestAnimationFrame(callback);' +
  '  }else{' +
  '   callback();' +
  '  }' +
  ' }, delay);' +
  '}' +
  'function d2bridgeStartQueue(){' +
  ' if(window.__d2bridgeGridQueueBusy){' +
  '  return;' +
  ' }' +
  ' window.__d2bridgeGridQueueBusy = true;' +
  ' (function d2bridgeDrainQueue(){' +
  '  var nextJob = window.__d2bridgeGridQueue.shift();' +
  '  if(!nextJob){' +
  '   window.__d2bridgeGridQueueBusy = false;' +
  '   return;' +
  '  }' +
  '  nextJob(function(){ setTimeout(d2bridgeDrainQueue, 25); });' +
  ' })();' +
  '}' +
  'window.__d2bridgeGridQueue = window.__d2bridgeGridQueue || [];' +
  'window.__d2bridgeGridQueue.push(function(done){' +
  ' var d2bridgeHydrationTries = 0;' +
  ' function d2bridgeHydrateGrid(){' +
  '  var grid = ' + ClientGridSelectorJS + ';' +
  '  if(!grid.length){' +
  '   d2bridgeGridLog("grid ainda nao encontrada, tentativa " + d2bridgeHydrationTries);' +
  '   if(d2bridgeHydrationTries < 20){' +
  '    d2bridgeHydrationTries++;' +
  '    d2bridgeSchedule(d2bridgeHydrateGrid, ' + IntToStr(ADelayMS) + ');' +
  '   }else{' +
  '    done();' +
  '   }' +
  '   return;' +
  '  }' +
  '  try{' +
  '   grid.jqGrid("clearGridData")' +
  '   .jqGrid("setGridParam", { data: d2bridgeGridData, datatype: "local" })' +
  '   .trigger("reloadGrid", { page: 1 });' +
  '   if((d2bridgeGridData.length === 0) || (grid.jqGrid("getDataIDs").length > 0)){' +
  '    d2bridgeGridLog("hidratada com " + grid.jqGrid("getDataIDs").length + " linhas");' +
  '    done();' +
  '    return;' +
  '   }' +
  '  }catch(e){' +
  '   d2bridgeGridLog("erro na hidratacao: " + e.message);' +
  '  }' +
  '  if(d2bridgeHydrationTries < 20){' +
  '   d2bridgeHydrationTries++;' +
  '   d2bridgeSchedule(d2bridgeHydrateGrid, ' + IntToStr(ADelayMS) + ');' +
  '  }else{' +
  '   d2bridgeGridLog("encerrando hidratacao sem linhas visiveis");' +
  '   done();' +
  '  }' +
  ' }' +
  ' d2bridgeGridLog("enfileirada hidratacao");' +
  ' d2bridgeSchedule(d2bridgeHydrateGrid, ' + IntToStr(ADelayMS) + ');' +
  '});' +
  'd2bridgeStartQueue();' +
  '})();';
end;

function TPrismGrid.ClientGridReloadDataJS(const AJSONData: string): string;
begin
 Result:=
  '(function(){' +
  'var d2bridgeGridData = ' + AJSONData + ';' +
  'var d2bridgeGridName = "' + AnsiUpperCase(NamePrefix) + '";' +
  'function d2bridgeGridLog(msg){' +
  ' if(window.console && window.D2BridgeDebugGridTiming){' +
  '  console.debug("[D2Grid][" + d2bridgeGridName + "] " + msg);' +
  ' }' +
  '}' +
  'function d2bridgeSchedule(callback, delay){' +
  ' setTimeout(function(){' +
  '  if(window.requestAnimationFrame){' +
  '   window.requestAnimationFrame(callback);' +
  '  }else{' +
  '   callback();' +
  '  }' +
  ' }, delay);' +
  '}' +
  'function d2bridgeStartQueue(){' +
  ' if(window.__d2bridgeGridQueueBusy){' +
  '  return;' +
  ' }' +
  ' window.__d2bridgeGridQueueBusy = true;' +
  ' (function d2bridgeDrainQueue(){' +
  '  var nextJob = window.__d2bridgeGridQueue.shift();' +
  '  if(!nextJob){' +
  '   window.__d2bridgeGridQueueBusy = false;' +
  '   return;' +
  '  }' +
  '  nextJob(function(){ setTimeout(d2bridgeDrainQueue, 25); });' +
  ' })();' +
  '}' +
  'window.__d2bridgeGridQueue = window.__d2bridgeGridQueue || [];' +
  'window.__d2bridgeGridQueue.push(function(done){' +
  ' var d2bridgeReloadTries = 0;' +
  ' function d2bridgeReloadGrid(){' +
  '  var grid = ' + ClientGridSelectorJS + ';' +
  '  if(!grid.length){' +
  '   d2bridgeGridLog("grid ainda nao encontrada para reload, tentativa " + d2bridgeReloadTries);' +
  '   if(d2bridgeReloadTries < 10){' +
  '    d2bridgeReloadTries++;' +
  '    d2bridgeSchedule(d2bridgeReloadGrid, 75);' +
  '   }else{' +
  '    done();' +
  '   }' +
  '   return;' +
  '  }' +
  '  try{' +
  '   grid.jqGrid("clearGridData")' +
  '   .jqGrid("setGridParam", { data: d2bridgeGridData, datatype: "local" })' +
  '   .trigger("reloadGrid", { page: 1 });' +
  '   if((d2bridgeGridData.length === 0) || (grid.jqGrid("getDataIDs").length > 0)){' +
  '    d2bridgeGridLog("reload concluido com " + grid.jqGrid("getDataIDs").length + " linhas");' +
  '    done();' +
  '    return;' +
  '   }' +
  '  }catch(e){' +
  '   d2bridgeGridLog("erro no reload: " + e.message);' +
  '  }' +
  '  if(d2bridgeReloadTries < 10){' +
  '   d2bridgeReloadTries++;' +
  '   d2bridgeSchedule(d2bridgeReloadGrid, 75);' +
  '  }else{' +
  '   d2bridgeGridLog("encerrando reload sem linhas visiveis");' +
  '   done();' +
  '  }' +
  ' }' +
  ' d2bridgeGridLog("enfileirado reload");' +
  ' d2bridgeSchedule(d2bridgeReloadGrid, 0);' +
  '});' +
  'd2bridgeStartQueue();' +
  '})();';
end;

function TPrismGrid.ClientGridSelectorJS: string;
begin
 Result:=
  '$("[id]").filter(function(){return this.id.toUpperCase() === "' +
  AnsiUpperCase(NamePrefix) + '";})';
end;

function TPrismGrid.Columns: IPrismGridColumns;
begin
 Result:= FPrismGridColumns;
end;

function TPrismGrid.ColorStyle(const APropertyName: string;
  const AColor: {$IFNDEF FMX}TColor{$ELSE}TAlphaColor{$ENDIF};
  const AAllowNone: Boolean): string;
begin
 Result:= '';
 if (AColor = {$IFNDEF FMX}clNone{$ELSE}TAlphaColors.Null{$ENDIF}) and (not AAllowNone) then
  Exit;

 Result:= APropertyName + ': ' + ColorToHex(AColor) + '; ';
end;

procedure TPrismGrid.ApplyImportedBaseStyle(const AFont: TFont;
  const ABackgroundColor: {$IFNDEF FMX}TColor{$ELSE}TAlphaColor{$ENDIF});
begin
 if not Assigned(FFStoredVCLStyle) then
  FFStoredVCLStyle:= TD2BridgeItemVCLObjStyle.Create
 else
  FFStoredVCLStyle.Default;

 if AFont.Size <> DefaultFontSize then
  FFStoredVCLStyle.FontSize:= AFont.Size;

 if AFont.Color <> DefaultFontColor then
  FFStoredVCLStyle.FontColor:= AFont.Color;

 if not IsColor(ABackgroundColor, [clWindow, clDefault]) then
  FFStoredVCLStyle.Color:= ABackgroundColor;

 FFStoredVCLStyle.FontStyles:= AFont.Style;
end;

procedure TPrismGrid.ApplyImportedComponentStyles;
begin
{$IFNDEF FMX}
 if not FImportStylesComponents then
  Exit;

 if VCLComponent is TDBGrid then
  ApplyImportedDBGridStyles(TDBGrid(VCLComponent))
 else
 if VCLComponent is TStringGrid then
  ApplyImportedStringGridStyles(TStringGrid(VCLComponent));
{$ENDIF}
end;

procedure TPrismGrid.ApplyImportedDBGridStyles(AGrid: TDBGrid);
var
 I: Integer;
 vColumn: IPrismGridColumn;
begin
 ApplyImportedBaseStyle(AGrid.Font, AGrid.Color);

 if AGrid.TitleFont.Size <> DefaultFontSize then
  TitleFontSize:= AGrid.TitleFont.Size;
 if AGrid.TitleFont.Color <> DefaultFontColor then
  TitleFontColor:= AGrid.TitleFont.Color;
 if AGrid.TitleFont.Style <> [] then
  TitleFontStyles:= AGrid.TitleFont.Style;
 if not IsColor(AGrid.FixedColor, [clBtnFace, clDefault]) then
  TitleBackgroundColor:= AGrid.FixedColor;

 for I := 0 to Columns.Items.Count - 1 do
 begin
  if I >= AGrid.Columns.Count then
   Break;

  vColumn:= Columns.Items[I];
  if AGrid.Columns[I].Font.Color <> DefaultFontColor then
   vColumn.FontColor:= AGrid.Columns[I].Font.Color;
  if AGrid.Columns[I].Font.Style <> [] then
   vColumn.FontStyles:= AGrid.Columns[I].Font.Style;
  if AGrid.Columns[I].Title.Font.Color <> DefaultFontColor then
   vColumn.TitleFontColor:= AGrid.Columns[I].Title.Font.Color;
  if AGrid.Columns[I].Title.Font.Style <> [] then
   vColumn.TitleFontStyles:= AGrid.Columns[I].Title.Font.Style;
 end;
end;

procedure TPrismGrid.ApplyImportedStringGridStyles(AGrid: TStringGrid);
var
 I: Integer;
 vColumn: IPrismGridColumn;
begin
 ApplyImportedBaseStyle(AGrid.Font, AGrid.Color);

 if AGrid.Font.Size <> DefaultFontSize then
  TitleFontSize:= AGrid.Font.Size;
 if AGrid.Font.Color <> DefaultFontColor then
  TitleFontColor:= AGrid.Font.Color;
 if AGrid.Font.Style <> [] then
  TitleFontStyles:= AGrid.Font.Style;
 if not IsColor(AGrid.FixedColor, [clBtnFace, clDefault]) then
  TitleBackgroundColor:= AGrid.FixedColor;

 for I := 0 to Columns.Items.Count - 1 do
 begin
  vColumn:= Columns.Items[I];
  if AGrid.Font.Color <> DefaultFontColor then
   vColumn.FontColor:= AGrid.Font.Color;
  if AGrid.Font.Style <> [] then
   vColumn.FontStyles:= AGrid.Font.Style;
 end;
end;

constructor TPrismGrid.Create(AOwner: TObject);
begin
 inherited;

 FPrismGridColumns:= TPrismGridColumns.Create(Self);

 FMultiSelectWidth:= 30;
 FShowPager:= true;
 FRecordsPerPage:= 100;
 FMaxRecords:= 5000;
 FMultiSelect:= false;
 FImportStylesComponents:= false;
  FTitleFontSize:= 0;
  FTitleFontColor:= {$IFNDEF FMX}clNone{$ELSE}TAlphaColors.Null{$ENDIF};
  FTitleFontStyles:= [];
  FTitleBackgroundColor:= {$IFNDEF FMX}clNone{$ELSE}TAlphaColors.Null{$ENDIF};
  FZebraGrid:= false;
  FZebraOddColor:= {$IFNDEF FMX}clWhite{$ELSE}TAlphaColors.White{$ENDIF};
  FZebraPairColor:= {$IFNDEF FMX}$00F3F3F3{$ELSE}#00F3F3F3{$ENDIF};
end;

destructor TPrismGrid.Destroy;
begin
 FreeAndNil(FPrismGridColumns);

 inherited;
end;

function TPrismGrid.GetMaxRecords: integer;
begin
 result:= FMaxRecords;
end;

function TPrismGrid.GetMultiSelect: Boolean;
begin
 result:= FMultiSelect;
end;

function TPrismGrid.GetImportStylesComponents: Boolean;
begin
 Result:= FImportStylesComponents;
end;

function TPrismGrid.GetMultiSelectWidth: integer;
begin
 result:= FMultiSelectWidth;
end;

function TPrismGrid.GetTitleBackgroundColor: {$IFNDEF FMX}TColor{$ELSE}TAlphaColor{$ENDIF};
begin
 Result:= FTitleBackgroundColor;
end;

function TPrismGrid.GetTitleFontColor: {$IFNDEF FMX}TColor{$ELSE}TAlphaColor{$ENDIF};
begin
 Result:= FTitleFontColor;
end;

function TPrismGrid.GetTitleFontSize: Integer;
begin
 Result:= FTitleFontSize;
end;

function TPrismGrid.GetTitleFontStyles: TFontStyles;
begin
 Result:= FTitleFontStyles;
end;

function TPrismGrid.GetZebraGrid: Boolean;
begin
 Result:= FZebraGrid;
end;

function TPrismGrid.GetZebraOddColor: {$IFNDEF FMX}TColor{$ELSE}TAlphaColor{$ENDIF};
begin
 Result:= FZebraOddColor;
end;

function TPrismGrid.GetZebraPairColor: {$IFNDEF FMX}TColor{$ELSE}TAlphaColor{$ENDIF};
begin
 Result:= FZebraPairColor;
end;

function TPrismGrid.GetRecordsPerPage: integer;
begin
 Result:= FRecordsPerPage;
end;

function TPrismGrid.GetShowPager: Boolean;
begin
 Result:= FShowPager;
end;

function TPrismGrid.FontStylesToCSS(const AFontStyles: TFontStyles): string;
begin
 Result:= '';
 if fsBold in AFontStyles then
  Result:= Result + 'font-weight: bold; ';
 if fsItalic in AFontStyles then
  Result:= Result + 'font-style: italic; ';
 if fsUnderline in AFontStyles then
  Result:= Result + 'text-decoration: underline; ';
 if fsStrikeOut in AFontStyles then
  Result:= Result + 'text-decoration: line-through; ';
end;

procedure TPrismGrid.SetMaxRecords(AMaxRecords: Integer);
begin
 FMaxRecords:= AMaxRecords;
end;

procedure TPrismGrid.SetImportStylesComponents(Value: Boolean);
begin
 FImportStylesComponents:= Value;

 if not Value then
  Exit;

 ApplyImportedComponentStyles;
 if Initilized then
 begin
  ProcessHTML;
  RefreshHTMLControl;
  Refresh;
 end;
end;

procedure TPrismGrid.SetMultiSelect(AMultiSelect: Boolean);
begin
 FMultiSelect:= AMultiSelect;
end;

procedure TPrismGrid.SetMultiSelectWidth(Value: integer);
begin
 FMultiSelectWidth:= Value;
end;

procedure TPrismGrid.SetTitleBackgroundColor(
  Value: {$IFNDEF FMX}TColor{$ELSE}TAlphaColor{$ENDIF});
begin
 FTitleBackgroundColor:= Value;
end;

procedure TPrismGrid.SetTitleFontColor(
  Value: {$IFNDEF FMX}TColor{$ELSE}TAlphaColor{$ENDIF});
begin
 FTitleFontColor:= Value;
end;

procedure TPrismGrid.SetTitleFontSize(Value: Integer);
begin
 FTitleFontSize:= Value;
end;

procedure TPrismGrid.SetTitleFontStyles(Value: TFontStyles);
begin
 FTitleFontStyles:= Value;
end;

procedure TPrismGrid.SetZebraGrid(Value: Boolean);
begin
 FZebraGrid:= Value;
end;

procedure TPrismGrid.SetZebraOddColor(
  Value: {$IFNDEF FMX}TColor{$ELSE}TAlphaColor{$ENDIF});
begin
 FZebraOddColor:= Value;
end;

procedure TPrismGrid.SetZebraPairColor(
  Value: {$IFNDEF FMX}TColor{$ELSE}TAlphaColor{$ENDIF});
begin
 FZebraPairColor:= Value;
end;

procedure TPrismGrid.SetRecordsPerPage(ARecordsPerPage: Integer);
begin
 FRecordsPerPage:= ARecordsPerPage;
end;

procedure TPrismGrid.SetShowPager(Value: Boolean);
begin
 FShowPager:= Value;
end;

end.