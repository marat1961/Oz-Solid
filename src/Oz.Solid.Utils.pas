(* Oz Solid Library for Pascal
 * Copyright (c) 2020 Marat Shaimardanov
 *
 * This file is part of Oz Solid Library for Pascal
 * is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This file is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this file. If not, see <https://www.gnu.org/licenses/>.
 *)

unit Oz.Solid.Utils;

interface

{$Region 'Uses'}

uses
  System.Classes, System.SysUtils, System.Math, Oz.SGL.Heap, Oz.SGL.Collections,
  Oz.Solid.Types;

{$EndRegion}

{$T+}

type
  TsdDoubleList = TsgList<Double>;

{$Region 'TsdId, TsdEntry'}

  TsdId = record
    v: Cardinal;
  end;

  PsdEntry = ^TsdEntry;
  TsdEntry = record
    tag: Integer; // the tag field is at the beginning and has a zero offset
    h: TsdId;     // if there is a 'h' field it is right after the 'tag' field
  end;

{$EndRegion}

{$Region 'TCustomTaggedList'}

  TCustomTaggedList = record
  private
    FList: TsgPointerList;
    function Get(Index: Integer): Pointer;
    procedure Put(Index: Integer; Item: Pointer);
    function GetCount: Integer;
    procedure SetCount(Value: Integer);
  public
    procedure Init(meta: PsgItemMeta);
    procedure Free; inline;
    procedure Clear; inline;
    function First: Pointer; inline;
    function Last: Pointer; inline;
    function NextAfter(prev: Pointer): Pointer; inline;
    function Add(Item: Pointer): Integer; inline;
    procedure AddToBeginning(Item: Pointer);
    procedure Insert(Index: Integer; Item: Pointer); inline;
    procedure Delete(Index: Integer); inline;
    procedure Exchange(Index1, Index2: Integer); inline;
    function IndexOf(Item: Pointer): Integer; inline;
    procedure Assign(const Source: TCustomTaggedList);
    procedure Sort(Compare: TListSortCompare); inline;
    procedure Reverse; inline;
    procedure ClearTags;
    procedure RemoveTagged;
    function FindByTag(tag: Integer): Pointer;
    function IsEmpty: Boolean; inline;
    property Count: Integer read GetCount write SetCount;
  end;

{$EndRegion}

{$Region 'TsdTaggedList<T>'}

  TsdTaggedList<T> = record
  public type
    PItem = ^T;
  private
    FList: TCustomTaggedList;
    function Get(Index: Integer): PItem; inline;
    procedure Put(Index: Integer; Item: PItem); inline;
    function GetCount: Integer; inline;
    procedure SetCount(Value: Integer); inline;
  public
    procedure Init;
    procedure Free;
    procedure Clear; inline;
    function First: PItem; inline;
    function Last: PItem; inline;
    function NextAfter(prev: PItem): PItem; inline;
    function Add(Item: PItem): Integer; inline;
    procedure AddToBeginning(Item: PItem);
    procedure Insert(Index: Integer; Item: PItem); inline;
    procedure Delete(Index: Integer); inline;
    procedure Exchange(Index1, Index2: Integer); inline;
    function IndexOf(Item: PItem): Integer; inline;
    procedure Assign(const Source: TsdTaggedList<T>); inline;
    procedure Sort(Compare: TListSortCompare); inline;
    procedure Reverse; inline;
    procedure ClearTags;
    procedure RemoveTagged;
    function FindByTag(tag: Integer): PItem;
    function IsEmpty: Boolean; inline;
    property Count: Integer read GetCount write SetCount;
    property Items[Index: Integer]: PItem read Get write Put;
    property List: TCustomTaggedList read FList;
  end;

{$EndRegion}

{$Region 'TsdIdList<T>'}

  TsdIdList<T: record> = record
  public type
    PItem = ^T;
  private
    FList: TsgPointerList;
    function Get(Index: Integer): PItem;
    procedure Put(Index: Integer; Item: PItem);
    function GetCount: Integer;
  public
    constructor From(OnFree: TFreeProc);
    procedure Free; inline;
    procedure Clear; inline;
    function MaximumId: Cardinal;
    function IndexOf(id: Cardinal): Integer;
    function Add(Item: PItem): Integer; overload;
    function Add(id: Cardinal): PItem; overload;
    procedure Delete(Index: Integer); inline;
    procedure Assign(const Source: TsdIdList<T>);
    procedure ClearTags;
    procedure RemoveTagged;
    function FindByTag(tag: Integer): PItem;
    function AddAndAssignId(item: PItem): Cardinal;
    function FindById(id: Cardinal): PItem;
    function FindByIdNoOops(id: Cardinal): PItem;
    procedure RemoveById(id: Cardinal);
    function IsEmpty: Boolean; inline;
    property Count: Integer read GetCount;
    property Items[Index: Integer]: PItem read Get write Put;
    property List: TsgPointerList read FList;
  end;

{$EndRegion}

{$Region 'TsdIdMap<T>'}

  TsdIdMap<T: record> = record
  public type
    PItem = ^T;
  private
    FMap: TsgMap<Cardinal, T>;
    FOnFree: TFreeProc;
  public
    constructor From(OnFree: TFreeProc; MaxId: Cardinal = 0);
    procedure Free; inline;
    procedure Clear; inline;
    function Add(id: Cardinal): PItem;
    function Get(id: Cardinal): PItem;
    procedure Put(id: Cardinal; Item: PItem);
    property Items[id: Cardinal]: PItem read Get write Put;
    property Map: TsgMap<Cardinal, T> read FMap;
  end;

{$EndRegion}

{$Region 'TsdContext'}

  TsdContext = class
  protected
    FHeap: THeapPool;
    FExprRegion: PMemoryRegion;
    procedure Init; virtual;
  public
    constructor Create;
    destructor Destroy; override;
    function AllocExpr: Pointer;
    procedure FreeAllTemporary;
    property Heap: THeapPool read FHeap;
  end;

{$EndRegion}

function IdCompare(a, b: Pointer): Integer;

// Limit the value to a range of (0, n)
function Wrap(v, n: Integer): Integer; inline;

implementation

function IdCompare(a, b: Pointer): Integer;
type PCardinal = ^Cardinal;
begin
  if PCardinal(a)^ = PCardinal(b)^ then
    Result := 0
  else if PCardinal(a)^ < PCardinal(b)^ then
    Result := -1
  else
    Result := 1;
end;

function Wrap(v, n: Integer): Integer;
begin
  while v >= n do v := v - n;
  while v < 0 do v := v + n;
  Result := v;
end;

{$Region 'TCustomTaggedList'}

procedure TCustomTaggedList.Init(meta: PsgItemMeta);
begin
  FList := TsgPointerList.From(meta);
end;

procedure TCustomTaggedList.Free;
begin
  FList.Free;
end;

procedure TCustomTaggedList.Clear;
begin
  FList.Clear;
end;

function TCustomTaggedList.First: Pointer;
begin
  Result := FList.First;
end;

function TCustomTaggedList.Last: Pointer;
begin
  Result := FList.Last;
end;

function TCustomTaggedList.NextAfter(prev: Pointer): Pointer;
begin
  Result := FList.NextAfter(prev);
end;

function TCustomTaggedList.Add(Item: Pointer): Integer;
begin
  Result := FList.Add(Item);
end;

procedure TCustomTaggedList.Insert(Index: Integer; Item: Pointer);
begin
  FList.Insert(Index, Item);
end;

procedure TCustomTaggedList.AddToBeginning(Item: Pointer);
begin
  FList.Insert(0, Item);
end;

procedure TCustomTaggedList.Delete(Index: Integer);
begin
  FList.Delete(Index);
end;

procedure TCustomTaggedList.Exchange(Index1, Index2: Integer);
begin
  FList.Exchange(Index1, Index2);
end;

function TCustomTaggedList.IndexOf(Item: Pointer): Integer;
begin
  Result := FList.IndexOf(Item);
end;

procedure TCustomTaggedList.Assign(const Source: TCustomTaggedList);
var i: Integer;
begin
  Count := 0;
  for i := 0 to Source.Count - 1 do
    Add(Source.Get(i));
end;

procedure TCustomTaggedList.Sort(Compare: TListSortCompare);
begin
  FList.Sort(Compare);
end;

procedure TCustomTaggedList.Reverse;
begin
  FList.Reverse;
end;

procedure TCustomTaggedList.ClearTags;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
    PsdEntry(FList.Items[i]).tag := 0;
end;

procedure TCustomTaggedList.RemoveTagged;
begin
  FList.RemoveBy(
    function(Item: Pointer): Boolean
    begin
      Result := PsdEntry(Item).tag <> 0;
    end);
end;

function TCustomTaggedList.FindByTag(tag: Integer): Pointer;
var
  i: Integer;
  item: Pointer;
begin
  for i := 0 to Count - 1 do
  begin
    item := Get(i);
    if PsdEntry(item).tag = tag then
      exit(item);
  end;
  Result := nil;
end;

function TCustomTaggedList.IsEmpty: Boolean;
begin
  Result := FList.IsEmpty;
end;

function TCustomTaggedList.Get(Index: Integer): Pointer;
begin
  Result := FList.Items[Index];
end;

procedure TCustomTaggedList.Put(Index: Integer; Item: Pointer);
begin
  FList.Items[Index] := Item;
end;

function TCustomTaggedList.GetCount: Integer;
begin
  Result := FList.Count;
end;

procedure TCustomTaggedList.SetCount(Value: Integer);
begin
  FList.Count := Value;
end;

{$EndRegion}

{$Region 'TsdTaggedList<T>'}

procedure TsdTaggedList<T>.Init;
var
  meta: PsgItemMeta;
begin
  meta := SysCtx.CreateMeta<T>;
  FList.Init(meta);
end;

procedure TsdTaggedList<T>.Free;
begin
  FList.Free;
end;

procedure TsdTaggedList<T>.Clear;
begin
  FList.Clear;
end;

function TsdTaggedList<T>.First: PItem;
begin
  Result := FList.First;
end;

function TsdTaggedList<T>.Last: PItem;
begin
  Result := FList.Last;
end;

function TsdTaggedList<T>.NextAfter(prev: PItem): PItem;
begin
  Result := FList.NextAfter(prev);
end;

function TsdTaggedList<T>.Add(Item: PItem): Integer;
begin
  Result := FList.Add(Item);
end;

procedure TsdTaggedList<T>.Insert(Index: Integer; Item: PItem);
begin
  FList.Insert(Index, Item);
end;

procedure TsdTaggedList<T>.AddToBeginning(Item: PItem);
begin
  FList.Insert(0, Item);
end;

procedure TsdTaggedList<T>.Delete(Index: Integer);
begin
  FList.Delete(Index);
end;

procedure TsdTaggedList<T>.Exchange(Index1, Index2: Integer);
begin
  FList.Exchange(Index1, Index2);
end;

function TsdTaggedList<T>.IndexOf(Item: PItem): Integer;
begin
  Result := FList.IndexOf(Item);
end;

procedure TsdTaggedList<T>.Assign(const Source: TsdTaggedList<T>);
begin
  FList.Assign(Source.FList);
end;

procedure TsdTaggedList<T>.Sort(Compare: TListSortCompare);
begin
  FList.Sort(Compare);
end;

procedure TsdTaggedList<T>.Reverse;
begin
  FList.Reverse;
end;

procedure TsdTaggedList<T>.ClearTags;
begin
  FList.ClearTags;
end;

procedure TsdTaggedList<T>.RemoveTagged;
begin
  FList.RemoveTagged;
end;

function TsdTaggedList<T>.FindByTag(tag: Integer): PItem;
begin
  FList.FindByTag(tag);
end;

function TsdTaggedList<T>.IsEmpty: Boolean;
begin
  Result := FList.IsEmpty;
end;

function TsdTaggedList<T>.Get(Index: Integer): PItem;
begin
  Result := FList.Get(Index);
end;

procedure TsdTaggedList<T>.Put(Index: Integer; Item: PItem);
begin
  FList.Put(Index, Item);
end;

function TsdTaggedList<T>.GetCount: Integer;
begin
  Result := FList.Count;
end;

procedure TsdTaggedList<T>.SetCount(Value: Integer);
begin
  FList.Count := Value;
end;

{$EndRegion}

{$Region 'TsdIdList<T> '}

constructor TsdIdList<T>.From(OnFree: TFreeProc);
var
  meta: PsgItemMeta;
begin
  meta := SysCtx.CreateMeta<T>(OnFree);
  FList := TsgPointerList.From(meta);
end;

procedure TsdIdList<T>.Free;
begin
  FList.Free;
end;

procedure TsdIdList<T>.Clear;
begin
  FList.Clear;
end;

function TsdIdList<T>.IndexOf(id: Cardinal): Integer;
var
  l, h, i: Integer;
  mv: Cardinal;
begin
  l := 0;
  h := Count - 1;
  while l <= h do
  begin
    i := (l + h) div 2;
    mv := PsdEntry(Get(i)).h.v;
    if mv > id then
      h := i - 1
    else if mv < id then
      l := i + 1
    else
      exit(i);
  end;
  Result := -1;
end;

function TsdIdList<T>.Add(Item: PItem): Integer;
var
  l, h, i: Integer;
  id, mv: Cardinal;
begin
  if Count = 0 then
  begin
    Result := FList.Add(Item);
    exit;
  end;
  l := 0;
  h := Count - 1;
  id := PsdEntry(Item).h.v;
  while l <= h do
  begin
    i := (l + h) div 2;
    mv := PsdEntry(Get(i)).h.v;
    Check(mv <> id, 'Handle isn''t unique');
    if mv > id then
      h := i - 1
    else if mv < id then
      l := i + 1;
  end;
  Result := l;
  FList.Insert(Result, Item);
end;

function TsdIdList<T>.Add(id: Cardinal): PItem;
var
  idx: Integer;
begin
  idx := IndexOf(id);
  Check(idx < 0, 'Handle isn''t unique');
  Result := FList.Add;
  PsdEntry(Result).h.v := id;
end;

procedure TsdIdList<T>.Delete(Index: Integer);
begin
  FList.Delete(Index);
end;

procedure TsdIdList<T>.ClearTags;
begin
  FList.TraverseBy(
    function(Item: Pointer): Boolean
    begin
      PsdEntry(Item).tag := 0;
      Result := False;
    end);
end;

procedure TsdIdList<T>.RemoveTagged;
begin
  FList.RemoveBy(
    function(Item: Pointer): Boolean
    begin
      Result := PsdEntry(Item).tag <> 0;
    end);
end;

function TsdIdList<T>.FindByTag(tag: Integer): PItem;
begin
  Result := FList.TraverseBy(
    function(Item: Pointer): Boolean
    begin
      Result := PsdEntry(Item).tag = tag;
    end);
end;

function TsdIdList<T>.Get(Index: Integer): PItem;
begin
  Result := PItem(FList.Items[Index]);
end;

procedure TsdIdList<T>.Put(Index: Integer; Item: PItem);
begin
  FList.Items[Index] := Item;
end;

function TsdIdList<T>.GetCount: Integer;
begin
  Result := FList.Count;
end;

function TsdIdList<T>.MaximumId: Cardinal;
begin
  if Count = 0 then
    Result := 0
  else
    Result := PsdEntry(Items[Count - 1]).h.v;
end;

function TsdIdList<T>.AddAndAssignId(item: PItem): Cardinal;
begin
  Result := MaximumId + 1;
  PsdEntry(item).h.v := Result;
  FList.Add(item);
end;

procedure TsdIdList<T>.Assign(const Source: TsdIdList<T>);
var i: Integer;
begin
  Clear;
  for i := 0 to Source.Count - 1 do
    Add(Source.Items[i]);
end;

function TsdIdList<T>.FindById(id: Cardinal): PItem;
begin
  Result := FindByIdNoOops(id);
  Check(Result <> nil, Format('FindById(id=%d) error', [id]));
end;

function TsdIdList<T>.FindByIdNoOops(id: Cardinal): PItem;
var i: Integer;
begin
  i := IndexOf(id);
  if i < 0 then
    Result := nil
  else
    Result := Get(i);
end;

procedure TsdIdList<T>.RemoveById(id: Cardinal);
var i: Integer;
begin
  i := IndexOf(id);
  if i < 0 then exit;
  FList.Delete(i);
end;

function TsdIdList<T>.IsEmpty: Boolean;
begin
  Result := FList.IsEmpty;
end;

{$EndRegion}

{$Region 'TsdIdMap<T>'}

constructor TsdIdMap<T>.From(OnFree: TFreeProc; MaxId: Cardinal = 0);
begin
  FMap := TsgMap<Cardinal, T>.From(IdCompare, OnFree);
  FOnFree := OnFree;
end;

procedure TsdIdMap<T>.Free;
begin
  FMap.Free;
end;

procedure TsdIdMap<T>.Clear;
begin
  FMap.Clear;
end;

function TsdIdMap<T>.Get(id: Cardinal): PItem;
begin
  Result := FMap.Get(id);
end;

procedure TsdIdMap<T>.Put(id: Cardinal; Item: PItem);
begin
  FMap.Put(id, Item);
end;

function TsdIdMap<T>.Add(id: Cardinal): PItem;
var node: TsgMap<Cardinal, T>.PNode;
begin
  node := FMap.Emplace(id);
  Result := @node.v;
end;

{$EndRegion}

{$Region 'TsdContext'}

function TsdContext.AllocExpr: Pointer;
begin

end;

constructor TsdContext.Create;
begin
  inherited;
  FHeap := THeapPool.Create(8192);
  Init;
end;

procedure TsdContext.Init;
begin
end;

destructor TsdContext.Destroy;
begin
  FreeAndNil(FHeap);
  inherited;
end;

procedure TsdContext.FreeAllTemporary;
begin
  FreeAndNil(FHeap);
end;

{$EndRegion}

end.

