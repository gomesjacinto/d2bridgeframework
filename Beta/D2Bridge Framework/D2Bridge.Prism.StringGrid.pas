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

unit D2Bridge.Prism.StringGrid;

interface

uses
  SysUtils, Graphics, Generics.Collections,
{$IFDEF FMX}
  FMX.Grid,
{$ELSE}
  Grids,
{$ENDIF}
  D2Bridge.Interfaces, D2Bridge.FrameworkItem.DataWare, D2Bridge.FrameworkItem.GridColumns,
  D2Bridge.Prism.Item, D2Bridge.Prism;


type
 PrismStringGrid = class(TD2BridgePrismItem, ID2BridgeFrameworkItemStringGrid)
  private
   FProcSetSelectedRow: TOnSetValue;
   FProcGetSelectedRow: TOnGetValue;
   FProcGetEditable: TOnGetValue;
   FDataware: TD2BridgeDatawareStringGrid;
   FColumns: TD2BridgeFrameworkItemGridColumns;
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

   function Dataware: ID2BridgeDatawareStringGrid;
   function Columns: ID2BridgeFrameworkItemGridColumns;

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

{ PrismStringGrid }

uses
  Classes,
  Prism.StringGrid, Prism.Grid.Columns, Prism.Types, D2Bridge.Types;

procedure PrismStringGrid.Clear;
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

function PrismStringGrid.Columns: ID2BridgeFrameworkItemGridColumns;
begin
 Result:= FColumns;
end;

constructor PrismStringGrid.Create(AD2BridgePrismFramework: TD2BridgePrismFramework);
begin
 inherited;

 FColumns:= TD2BridgeFrameworkItemGridColumns.Create;
 FDataware := TD2BridgeDatawareStringGrid.Create;
 FMultiSelect:= False;
 FImportStylesComponents:= false;
 FTitleFontColor:= clNone;
 FTitleBackgroundColor:= clNone;
 FZebraOddColor:= clWhite;
 FZebraPairColor:= $00F3F3F3;
end;

function PrismStringGrid.Dataware: ID2BridgeDatawareStringGrid;
begin
 Result:= FDataware;
end;

destructor PrismStringGrid.Destroy;
begin
 FreeAndNil(FColumns);
 FreeAndNil(FDataware);

 inherited;
end;

function PrismStringGrid.FrameworkClass: TClass;
begin
 inherited;

 Result:= TPrismStringGrid;
end;

function PrismStringGrid.GetMultiSelect: Boolean;
begin
 Result:= FMultiSelect;
end;

function PrismStringGrid.GetImportStylesComponents: Boolean;
begin
 Result:= FImportStylesComponents;
end;

function PrismStringGrid.GetOnGetSelectedRow: TOnGetValue;
begin
 Result:= FProcGetSelectedRow;
end;

function PrismStringGrid.GetOnSetSelectedRow: TOnSetValue;
begin
 Result:= FProcSetSelectedRow;
end;

function PrismStringGrid.GetProcEditable: TOnGetValue;
begin
 Result:= FProcGetEditable;
end;

function PrismStringGrid.GetTitleBackgroundColor: TColor;
begin
 Result:= FTitleBackgroundColor;
end;

function PrismStringGrid.GetTitleFontColor: TColor;
begin
 Result:= FTitleFontColor;
end;

function PrismStringGrid.GetTitleFontSize: Integer;
begin
 Result:= FTitleFontSize;
end;

function PrismStringGrid.GetTitleFontStyles: TFontStyles;
begin
 Result:= FTitleFontStyles;
end;

function PrismStringGrid.GetZebraGrid: Boolean;
begin
 Result:= FZebraGrid;
end;

function PrismStringGrid.GetZebraOddColor: TColor;
begin
 Result:= FZebraOddColor;
end;

function PrismStringGrid.GetZebraPairColor: TColor;
begin
 Result:= FZebraPairColor;
end;

procedure PrismStringGrid.ProcessEventClass(VCLObj, NewObj: TObject);
begin
 inherited;

// TPrismGrid(NewObj).Events.Add(EventOnClick,
//  procedure(EventParams: TStrings)
//  begin
//   if Assigned(TPrismGrid(NewObj).Events.Item(EventOnCellClick)) then
//    TPrismGrid(NewObj).Events.Item(EventOnCellClick).CallEvent(EventParams);
//  end);

// TPrismGrid(NewObj).Events.Add(EventOnSelect,
//  procedure(EventParams: TStrings)
//  var
//   Col: Integer;
//  begin
//   if TryStrToInt(EventParams.Values['col'], col) then
//   begin
//    if Assigned(TPrismGrid(NewObj).Events.Item(EventOnCellClick)) then
//     TPrismGrid(NewObj).Events.Item(EventOnCellClick).CallEvent(EventParams);
//   end;
//  end);


// TPrismGrid(NewObj).Events.Add(EventOnUncheck,
//  procedure(EventParams: TStrings)
//  begin
//
//  end);

// TPrismGrid(NewObj).Events.Add(EventOnSelectAll,
//  procedure(EventParams: TStrings)
//  begin
//
//  end);

// TPrismGrid(NewObj).Events.Add(EventOnUnselectAll,
//  procedure(EventParams: TStrings)
//  begin
//
//  end);


end;

procedure PrismStringGrid.ProcessPropertyByName(VCLObj, NewObj: TObject;
  PropertyName: string; PropertyValue: Variant);
begin
 inherited;

end;

procedure PrismStringGrid.ProcessPropertyClass(VCLObj, NewObj: TObject);
var
 I: Integer;
begin
 inherited;

 if Assigned(Dataware.StringGrid) then
 TPrismStringGrid(NewObj).StringGrid:= Dataware.StringGrid;

 TPrismStringGrid(NewObj).Columns.Clear;

 for I := 0 to Columns.Items.Count -1 do
 with (TPrismStringGrid(NewObj).Columns.Add as TPrismGridColumn) do
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
    D2BridgeAlignColumnsRight: Alignment:= PrismAlignJustified;
    D2BridgeAlignColumnsCenter: Alignment:= PrismAlignCenter;
  end;
 end;

 TPrismStringGrid(NewObj).MultiSelect:= FMultiSelect;

 if Assigned(FProcSetSelectedRow) then
 TPrismStringGrid(NewObj).ProcSetSelectedRow:= FProcSetSelectedRow;

 if Assigned(FProcGetSelectedRow) then
 TPrismStringGrid(NewObj).ProcGetSelectedRow:= FProcGetSelectedRow;

 if Assigned(FProcGetEditable) then
 TPrismStringGrid(NewObj).ProcGetEditable:= FProcGetEditable;

 TPrismStringGrid(NewObj).TitleFontSize:= FTitleFontSize;
 TPrismStringGrid(NewObj).TitleFontColor:= FTitleFontColor;
 TPrismStringGrid(NewObj).TitleFontStyles:= FTitleFontStyles;
 TPrismStringGrid(NewObj).TitleBackgroundColor:= FTitleBackgroundColor;
 TPrismStringGrid(NewObj).ZebraGrid:= FZebraGrid;
 TPrismStringGrid(NewObj).ZebraOddColor:= FZebraOddColor;
 TPrismStringGrid(NewObj).ZebraPairColor:= FZebraPairColor;
end;

procedure PrismStringGrid.SetMultiSelect(AMultiSelect: Boolean);
begin
 FMultiSelect:= AMultiSelect;
end;

procedure PrismStringGrid.SetImportStylesComponents(Value: Boolean);
begin
 FImportStylesComponents:= Value;
end;

procedure PrismStringGrid.SetOnGetSelectedRow(AOnGetSelectedRow: TOnGetValue);
begin
 FProcGetSelectedRow:= AOnGetSelectedRow;
end;

procedure PrismStringGrid.SetOnSetSelectedRow(AOnSetSelectedRow: TOnSetValue);
begin
 FProcSetSelectedRow:= AOnSetSelectedRow;
end;

procedure PrismStringGrid.SetProcEditable(const Value: TOnGetValue);
begin
 FProcGetEditable:= Value;
end;

procedure PrismStringGrid.SetTitleBackgroundColor(Value: TColor);
begin
 FTitleBackgroundColor:= Value;
end;

procedure PrismStringGrid.SetTitleFontColor(Value: TColor);
begin
 FTitleFontColor:= Value;
end;

procedure PrismStringGrid.SetTitleFontSize(Value: Integer);
begin
 FTitleFontSize:= Value;
end;

procedure PrismStringGrid.SetTitleFontStyles(Value: TFontStyles);
begin
 FTitleFontStyles:= Value;
end;

procedure PrismStringGrid.SetZebraGrid(Value: Boolean);
begin
 FZebraGrid:= Value;
end;

procedure PrismStringGrid.SetZebraOddColor(Value: TColor);
begin
 FZebraOddColor:= Value;
end;

procedure PrismStringGrid.SetZebraPairColor(Value: TColor);
begin
 FZebraPairColor:= Value;
end;

end.