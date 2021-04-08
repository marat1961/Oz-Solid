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
unit Oz.Solid.Matrix;

interface

uses
  System.Math;

type

{$Region 'TVector'}

  TVector = record
  private
    FTuple: TArray<Double>;
    function GetItem(i: Integer): Double; inline;
    procedure SetItem(i: Integer; value: Double); inline;
  public
    // The tuple is length 'size' and the elements are uninitialized.
    constructor From(size: Integer); overload;
    // For 0 <= d <= size, element d is 1 and all others are zero.
    // If d is invalid, the zero vector is created.
    // This is a convenience for creating the standard Euclidean basis vectors;
    // see also MakeUnit(Integer, Integer) and Unit(Integer, Integer).
    constructor From(size, d: Integer); overload;
    // Member access. SetSize(Integer) does not initialize the tuple.
    // The first operator[] returns a const reference rather than
    // a Double value. This supports writing via standard file operations
    // that require a const pointer to data.
    procedure SetSize(size: Integer); inline;
    function GetSize: Integer; inline;
    // All components are 0.
    procedure MakeZero;
    // All components are 0.
    function Zero(size: Integer): TVector;
    // Component d is 1, all others are zero.
    procedure MakeUnit(d: Integer);
    // Component d is 1, all others are zero.
    function GetUnit(size, d: Integer): TVector;

    // Compare vectors
    function Equals(const v: TVector): Boolean;
    // Change the sign
    function Negative: TVector;
    // Linear-algebraic operations
    function Plus(const v: TVector): TVector;
    function Minus(const v: TVector): TVector;
    function Scale(s: Double): TVector;
    property Items[Index: Integer]: Double read GetItem write SetItem;
  end;

{$EndRegion}

{$Region 'TMatrix'}

  TMatrix = class
  public
  end;

{$EndRegion}

implementation

{$Region 'TVector'}

constructor TVector.From(size: Integer);
begin
  SetSize(size);
end;

constructor TVector.From(size, d: Integer);
begin
  SetSize(size);
  MakeUnit(d);
end;

procedure TVector.SetSize(size: Integer);
begin
  Assert(size >= 0, 'Invalid size.');
  SetLength(FTuple, size);
end;

function TVector.GetSize: Integer;
begin
  Result := Length(FTuple);
end;

function TVector.GetItem(i: Integer): Double;
begin
  Result := FTuple[i];
end;

procedure TVector.SetItem(i: Integer; Value: Double);
begin
  FTuple[i] := Value;
end;

procedure TVector.MakeZero;
var
  i: Integer;
begin
  for i := 0 to High(FTuple) do
    FTuple[i] := 0.0;
end;

function TVector.Zero(size: Integer): TVector;
begin
  SetLength(Result.FTuple, size);
  Result.MakeZero;
end;

procedure TVector.MakeUnit(d: Integer);
var
  i: Integer;
begin
  for i := 0 to High(FTuple) do
    if i = d then
      FTuple[i] := 1.0
    else
      FTuple[i] := 0.0;
end;

function TVector.GetUnit(size, d: Integer): TVector;
begin
  SetLength(Result.FTuple, size);
  Result.MakeUnit(d);
end;

function TVector.Equals(const v: TVector): Boolean;
var
  i, n: Integer;
begin
  n := GetSize;
  Result := n = v.GetSize;
  if Result then
    for i := 0 to High(FTuple) do
      if not SameValue(FTuple[i], v.FTuple[i]) then
        exit(False);
end;

function TVector.Negative: TVector;
var
  i: Integer;
begin
  for i := 0 to High(FTuple) do
    Result.FTuple[i] := FTuple[i];
end;

function TVector.Plus(const v: TVector): TVector;
var
  i: Integer;
begin
  Assert(GetSize = v.GetSize, 'Mismatched sizes');
  for i := 0 to High(FTuple) do
    Result.FTuple[i] := FTuple[i] + v.FTuple[i];
end;

function TVector.Minus(const v: TVector): TVector;
var
  i: Integer;
begin
  Assert(GetSize = v.GetSize, 'Mismatched sizes');
  for i := 0 to High(FTuple) do
    Result.FTuple[i] := FTuple[i] - v.FTuple[i];
end;

function TVector.Scale(s: Double): TVector;
var
  i: Integer;
begin
  for i := 0 to High(FTuple) do
    Result.FTuple[i] := FTuple[i] * s;
end;

{$EndRegion}

end.

