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
  System.SysUtils, System.Math;

type

  EMatrixError = class(Exception)
  end;

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

  TMatrix = record
  private
    // The matrix is stored as a 1-dimensional array.
    // The convention of row-major or column-major is your choice.
    FNumRows: Integer;
    FNumCols: Integer;
    FElements: TArray<Double>;
    function GetElement(r, c: Integer): PDouble; inline;
    procedure CheckIndex(r, c: Integer); inline;
  public
    // The table is length = numRows * numCols
    // and the elements are initialized to zero.
    constructor From(numRows, numCols: Integer); overload;
    // For 0 <= r < numRows and 0 <= c < numCols,
    // element (r, c) is 1 and all others are 0.
    // If either of r or c is invalid, the zero matrix is created.
    // This is a convenience for creating the standard Euclidean basis matrices;
    // see also MakeUnit(Integer,Integer) and Unit(Integer,Integer).
    constructor From(numRows, numCols, r, c: Integer); overload;
    // Member access for which the storage representation is transparent.
    // The matrix entry in row r and column c is A(r,c).  The first
    // operator() returns a const reference rather than a Double value.
    // This supports writing via standard file operations that require a
    // const pointer to data.
    procedure SetSize(numRows, numCols: Integer);
    procedure GetSize(var numRows, numCols: Integer); inline;

    function GetNumRows: Integer; inline;
    function GetNumCols: Integer; inline;
    function GetNumElements: Integer; inline;

    (* Special matrices *)

    // All components are 0.
    procedure MakeZero;
    // Component (r,c) is 1, all others zero.
    procedure MakeUnit(r, c: Integer);
    // Result := Self * M
    function Multiply(const M: TMatrix): TMatrix;
    property Element[r, c: Integer]: PDouble read GetElement; default;
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

{$Region 'TMatrix'}

constructor TMatrix.From(numRows, numCols: Integer);
begin
  SetSize(numRows, numCols);
end;

constructor TMatrix.From(numRows, numCols, r, c: Integer);
begin
  SetSize(numRows, numCols);
  MakeUnit(r, c);
end;

procedure TMatrix.GetSize(var numRows, numCols: Integer);
begin
  numRows := FNumRows;
  numCols := FNumCols;
end;

function TMatrix.GetNumCols: Integer;
begin
  Result := FNumCols;
end;

function TMatrix.GetNumElements: Integer;
begin
  Result := Length(FElements);
end;

function TMatrix.GetNumRows: Integer;
begin
  Result := FNumRows;
end;

procedure TMatrix.CheckIndex(r, c: Integer);
begin
  if (Cardinal(r) >= Cardinal(GetNumRows)) or
     (Cardinal(c) >= Cardinal(GetNumCols)) then
    raise EMatrixError.Create('Invalid index');
end;

function TMatrix.GetElement(r, c: Integer): PDouble;
begin
  CheckIndex(r, c);
  Result := @FElements[c + FNumCols * r];
end;

procedure TMatrix.SetSize(numRows, numCols: Integer);
begin
  if (numRows > 0) and (numCols > 0) then
  begin
    FNumRows := numRows;
    FNumCols := numCols;
    SetLength(FElements, FNumRows * FNumCols);
  end
  else
  begin
    FNumRows := 0;
    FNumCols := 0;
    FElements := [];
  end;
end;

procedure TMatrix.MakeZero;
var
  i: Integer;
begin
  for i := 0 to High(FElements) do
    FElements[i] := 0.0;
end;

procedure TMatrix.MakeUnit(r, c: Integer);
begin
  CheckIndex(r, c);
  MakeZero();
  Element[r, c]^ := 1.0;
end;

function TMatrix.Multiply(const M: TMatrix): TMatrix;
var
  numCommon, r, c, i: Integer;
  p: PDouble;
begin
  Assert(Self.GetNumCols = M.GetNumRows, 'Mismatched sizes');
  Result := TMatrix.From(Self.GetNumRows, M.GetNumCols);
  numCommon := Self.GetNumCols();
  for r := 0 to result.GetNumRows - 1 do
  begin
    for c := 0 to result.GetNumCols - 1 do
    begin
      Result.Element[r, c]^ := 0.0;
      for i := 0 to numCommon - 1 do
      begin
        p := Result.Element[r, c];
        p^ := p^ + p^ * M.Element[i, c]^;
      end;
    end;
  end;
end;

{$EndRegion}

end.

