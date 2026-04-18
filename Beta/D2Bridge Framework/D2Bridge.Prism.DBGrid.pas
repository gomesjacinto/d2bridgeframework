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

unit D2Bridge.Prism.DBGrid;

interface

{$IFNDEF FMX}
uses
  SysUtils, Graphics, Generics.Collections,
  D2Bridge.Interfaces, D2Bridge.FrameworkItem.DataWare, D2Bridge.FrameworkItem.GridColumns,
  D2Bridge.Prism.Item, D2Bridge.Prism;


type
 PrismDBGrid = class(TD2BridgePrismItem, ID2BridgeFrameworkItemDBGrid)
  private
   FProcSetSelectedRow: TOnSetValue;
   FProcGetSelectedRow: TOnGetValue;
   FProcGetEditable: TOnGetValue;
   FColumns: TD2BridgeFrameworkItemGridColumns;
   FDataware: TD2BridgeDatawareOnlyDataSource;
   FMultiSelect: Boolean;
  FImportStylesComponents: Boolean;
  FTitleFontSize: Integer;
  FTitleFontColor: TColor;
  FTitleFontStyles: TFontStyles;
  FTitleBackgroundColor: TColor;
  FZebraGrid: Boolean;
  FZebraOddColor: TColor;
  FZebraPairColor: TColor;
   function GetMultiSelect: Boolean;
   Procedure SetMultiSelect(AMultiSelect: Boolean);
  function GetImportStylesComponents: Boolean;
  procedure SetImportStylesComponents(Value: Boolean);
   procedure SetOnGetSelectedRow(AOnGetSelectedRow: TOnGetValue);
   function GetOnGetSelectedRow: TOnGetValue;
   procedure SetOnSetSelectedRow(AOnSetSelectedRow: TOnSetValue);
   function GetOnSetSelectedRow: TOnSetValue;
   function GetProcEditable: TOnGetValue;
   procedure SetProcEditable(const Value: TOnGetValue);
  function GetTitleFontSize: Integer;
  procedure SetTitleFontSize(Value: Integer);
  function GetTitleFontColor: TColor;
  procedure SetTitleFontColor(Value: TColor);
  function GetTitleFontStyles: TFontStyles;
  procedure SetTitleFontStyles(Value: TFontStyles);
  function GetTitleBackgroundColor: TColor;
  procedure SetTitleBackgroundColor(Value: TColor);
  function GetZebraGrid: Boolean;
  procedure SetZebraGrid(Value: Boolean);
  function GetZebraOddColor: TColor;
  procedure SetZebraOddColor(Value: TColor);
  function GetZebraPairColor: TColor;
  procedure SetZebraPairColor(Value: TColor);
  public
   constructor Create(AD2BridgePrismFramework: TD2BridgePrismFramework); override;
   destructor Destroy; override;

   procedure Clear; override;
   function FrameworkClass: TClass; override;
   procedure ProcessPropertyClass(VCLObj, NewObj: TObject); override;
   procedure ProcessEventClass(VCLObj, NewObj: TObject); override;
   procedure ProcessPropertyByName(VCLObj, NewObj: TObject; PropertyName: string; PropertyValue: Variant); override;

   function Columns: ID2BridgeFrameworkItemGridColumns;
   function Dataware : ID2BridgeDatawareOnlyDataSource;

   property MultiSelect: Boolean read GetMultiSelect write SetMultiSelect;
  property ImportStylesComponents: Boolean read GetImportStylesComponents write SetImportStylesComponents;
   property OnGetSelectedRow: TOnGetValue read GetOnGetSelectedRow write SetOnGetSelectedRow;
   property OnSetSelectedRow: TOnSetValue read GetOnSetSelectedRow write SetOnSetSelectedRow;
   property GetEditable: TOnGetValue read GetProcEditable write SetProcEditable;
   property TitleFontSize: Integer read GetTitleFontSize write SetTitleFontSize;
   property TitleFontColor: TColor read GetTitleFontColor write SetTitleFontColor;
   property TitleFontStyles: TFontStyles read GetTitleFontStyles write SetTitleFontStyles;
   property TitleBackgroundColor: TColor read GetTitleBackgroundColor write SetTitleBackgroundColor;
   property ZebraGrid: Boolean read GetZebraGrid write SetZebraGrid;
   property ZebraOddColor: TColor read GetZebraOddColor write SetZebraOddColor;
   property ZebraPairColor: TColor read GetZebraPairColor write SetZebraPairColor;
 end;


implementation

{ PrismDBGrid }

uses
  Classes,
  DBGrids,
  Prism.DBGrid, Prism.Grid.Columns, Prism.Types, D2Bridge.Types;

procedure PrismDBGrid.Clear;
begin
 inherited;

 FProcSetSelectedRow:= nil;
 FProcGetSelectedRow:= nil;
 FProcGetEditable:= nil;
 FMultiSelect:= False;
 FImportStylesComponents:= false;
 FTitleFontSize:= 0;
 FTitleFontColor:= clNone;
 FTitleFontStyles:= [];
 FTitleBackgroundColor:= clNone;
 FZebraGrid:= false;
 FZebraOddColor:= clWhite;
 FZebraPairColor:= $00F3F3F3;
 Columns.Clear;
 Dataware.Clear;
end;

function PrismDBGrid.Columns: ID2BridgeFrameworkItemGridColumns;
begin
 Result:= FColumns;
end;

constructor PrismDBGrid.Create(AD2BridgePrismFramework: TD2BridgePrismFramework);
begin
 inherited;

 FColumns:= TD2BridgeFrameworkItemGridColumns.Create;
 FDataware := TD2BridgeDatawareOnlyDataSource.Create;
 FMultiSelect:= False;
 FImportStylesComponents:= false;
 FTitleFontColor:= clNone;
 FTitleBackgroundColor:= clNone;
 FZebraOddColor:= clWhite;
 FZebraPairColor:= $00F3F3F3;
end;

function PrismDBGrid.Dataware: ID2BridgeDatawareOnlyDataSource;
begin
 Result:= FDataware;
end;

destructor PrismDBGrid.Destroy;
begin
 FreeAndNil(FColumns);
 FreeAndNil(FDataware);

 inherited;
end;

function PrismDBGrid.FrameworkClass: TClass;
begin
 inherited;

 Result:= TPrismDBGrid;
end;

function PrismDBGrid.GetMultiSelect: Boolean;
begin
 Result:= FMultiSelect;
end;

function PrismDBGrid.GetImportStylesComponents: Boolean;
begin
 Result:= FImportStylesComponents;
end;

function PrismDBGrid.GetOnGetSelectedRow: TOnGetValue;
begin
 Result:= FProcGetSelectedRow;
end;

function PrismDBGrid.GetOnSetSelectedRow: TOnSetValue;
begin
 Result:= FProcSetSelectedRow;
end;

function PrismDBGrid.GetProcEditable: TOnGetValue;
begin
 Result:= FProcGetEditable;
end;

function PrismDBGrid.GetTitleBackgroundColor: TColor;
begin
 Result:= FTitleBackgroundColor;
end;

function PrismDBGrid.GetTitleFontColor: TColor;
begin
 Result:= FTitleFontColor;
end;

function PrismDBGrid.GetTitleFontSize: Integer;
begin
 Result:= FTitleFontSize;
end;

function PrismDBGrid.GetTitleFontStyles: TFontStyles;
begin
 Result:= FTitleFontStyles;
end;

function PrismDBGrid.GetZebraGrid: Boolean;
begin
 Result:= FZebraGrid;
end;

function PrismDBGrid.GetZebraOddColor: TColor;
begin
 Result:= FZebraOddColor;
end;

function PrismDBGrid.GetZebraPairColor: TColor;
begin
 Result:= FZebraPairColor;
end;

procedure PrismDBGrid.ProcessEventClass(VCLObj, NewObj: TObject);
begin
 inherited;

// TPrismDBGrid(NewObj).Events.Add(EventOnClick,
//  procedure(EventParams: TStrings)
//  begin
//   if Assigned(TPrismDBGrid(NewObj).Events.Item(EventOnCellClick)) then
//    TPrismDBGrid(NewObj).Events.Item(EventOnCellClick).CallEvent(EventParams);
//  end);

// TPrismDBGrid(NewObj).Events.Add(EventOnSelect,
//  procedure(EventParams: TStrings)
//  var
//   Col: Integer;
//  begin
//   if TryStrToInt(EventParams.Values['col'], col) then
//   begin
//    if Assigned(TPrismDBGrid(NewObj).Events.Item(EventOnCellClick)) then
//     TPrismDBGrid(NewObj).Events.Item(EventOnCellClick).CallEvent(EventParams);
//   end;
//  end);


// TPrismDBGrid(NewObj).Events.Add(EventOnUncheck,
//  procedure(EventParams: TStrings)
//  begin
//
//  end);

// TPrismDBGrid(NewObj).Events.Add(EventOnSelectAll,
//  procedure(EventParams: TStrings)
//  begin
//
//  end);

// TPrismDBGrid(NewObj).Events.Add(EventOnUnselectAll,
//  procedure(EventParams: TStrings)
//  begin
//
//  end);


end;

procedure PrismDBGrid.ProcessPropertyByName(VCLObj, NewObj: TObject;
  PropertyName: string; PropertyValue: Variant);
begin
 inherited;

end;

procedure PrismDBGrid.ProcessPropertyClass(VCLObj, NewObj: TObject);
var
 I: Integer;
begin
 inherited;

 if Assigned(Dataware.DataSource) then
 TPrismDBGrid(NewObj).DataSource:= Dataware.DataSource;

 TPrismDBGrid(NewObj).Columns.Clear;

 for I := 0 to Columns.Items.Count -1 do
 with (TPrismDBGrid(NewObj).Columns.Add as TPrismGridColumn) do
 begin
  DataField:= Columns.Items[I].DataField;
  Title:= Columns.Items[I].Title;
  Visible:= Columns.Items[I].Visible;
  Width:= Columns.Items[I].Width;
  Editable:= Columns.Items[I].Editable;
  DataFieldType:= Columns.Items[I].DataFieldType;
  SelectItems := Columns.Items[I].SelectItems;
  FontColor:= Columns.Items[I].FontColor;
  FontStyles:= Columns.Items[I].FontStyles;
  TitleFontColor:= Columns.Items[I].TitleFontColor;
  TitleFontStyles:= Columns.Items[I].TitleFontStyles;
  case Columns.Items[I].Alignment of
    D2BridgeAlignColumnsLeft: Alignment:= PrismAlignLeft;
    D2BridgeAlignColumnsRight: Alignment:= PrismAlignRight;
    D2BridgeAlignColumnsCenter: Alignment:= PrismAlignCenter;
  end;
 end;

 TPrismDBGrid(NewObj).MultiSelect:= FMultiSelect;

 if Assigned(FProcSetSelectedRow) then
 TPrismDBGrid(NewObj).ProcSetSelectedRow:= FProcSetSelectedRow;

 if Assigned(FProcGetSelectedRow) then
 TPrismDBGrid(NewObj).ProcGetSelectedRow:= FProcGetSelectedRow;

 if Assigned(FProcGetEditable) then
 TPrismDBGrid(NewObj).ProcGetEditable:= FProcGetEditable;

 TPrismDBGrid(NewObj).TitleFontSize:= FTitleFontSize;
 TPrismDBGrid(NewObj).TitleFontColor:= FTitleFontColor;
 TPrismDBGrid(NewObj).TitleFontStyles:= FTitleFontStyles;
 TPrismDBGrid(NewObj).TitleBackgroundColor:= FTitleBackgroundColor;
 TPrismDBGrid(NewObj).ZebraGrid:= FZebraGrid;
 TPrismDBGrid(NewObj).ZebraOddColor:= FZebraOddColor;
 TPrismDBGrid(NewObj).ZebraPairColor:= FZebraPairColor;
end;

procedure PrismDBGrid.SetMultiSelect(AMultiSelect: Boolean);
begin
 FMultiSelect:= AMultiSelect;
end;

procedure PrismDBGrid.SetImportStylesComponents(Value: Boolean);
begin
 FImportStylesComponents:= Value;
end;

procedure PrismDBGrid.SetOnGetSelectedRow(AOnGetSelectedRow: TOnGetValue);
begin
 FProcGetSelectedRow:= AOnGetSelectedRow;
end;

procedure PrismDBGrid.SetOnSetSelectedRow(AOnSetSelectedRow: TOnSetValue);
begin
 FProcSetSelectedRow:= AOnSetSelectedRow;
end;

procedure PrismDBGrid.SetProcEditable(const Value: TOnGetValue);
begin
 FProcGetEditable:= Value;
end;

procedure PrismDBGrid.SetTitleBackgroundColor(Value: TColor);
begin
 FTitleBackgroundColor:= Value;
end;

procedure PrismDBGrid.SetTitleFontColor(Value: TColor);
begin
 FTitleFontColor:= Value;
end;

procedure PrismDBGrid.SetTitleFontSize(Value: Integer);
begin
 FTitleFontSize:= Value;
end;

procedure PrismDBGrid.SetTitleFontStyles(Value: TFontStyles);
begin
 FTitleFontStyles:= Value;
end;

procedure PrismDBGrid.SetZebraGrid(Value: Boolean);
begin
 FZebraGrid:= Value;
end;

procedure PrismDBGrid.SetZebraOddColor(Value: TColor);
begin
 FZebraOddColor:= Value;
end;

procedure PrismDBGrid.SetZebraPairColor(Value: TColor);
begin
 FZebraPairColor:= Value;
end;
{$ELSE}
implementation
{$ENDIF}

end.