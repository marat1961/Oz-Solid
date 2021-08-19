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

  EgtError = class(Exception)
  end;

{$Region 'TgVector'}

  PgVector = ^TgVector;
  TgVector = record
  private
    FItems: TArray<Double>;
    function GetItem(i: Integer): PDouble; inline;
  public
    // The tuple is length 'size' and the elements are uninitialized.
    constructor From(size: Integer); overload;
    // For d in [0 .. numRows - 1], element d is 1 and all others are zero.
    // If d is invalid, the zero vector is created.
    // This is a convenience for creating the standard Euclidean basis vectors;
    // see also MakeUnit(Integer, Integer) and Unit(Integer, Integer).
    constructor From(size, d: Integer); overload;
    // Member access. SetSize(Integer) does not initialize the tuple.
    procedure SetSize(size: Integer); inline;
    function GetSize: Integer; inline;
    // All components are 0.
    procedure MakeZero;
    // All components are 0.
    function Zero(size: Integer): TgVector;
    // Component d is 1, all others are zero.
    procedure MakeUnit(d: Integer);
    // Component d is 1, all others are zero.
    function GetUnit(size, d: Integer): TgVector;

    // Compare vectors
    function Equals(const v: TgVector): Boolean;
    // Change the sign
    function Negative: TgVector;
    // Linear-algebraic operations
    function Plus(const v: TgVector): TgVector;
    function Minus(const v: TgVector): TgVector;
    function Scale(s: Double): TgVector;
    property Items[index: Integer]: PDouble read GetItem; default;
  end;

{$EndRegion}

{$Region 'TgMatrix'}

  PgMatrix = ^TgMatrix;
  TgMatrix = record
  private
    // The matrix is stored as a 1-dimensional array.
    FNumRows: Integer;
    FNumCols: Integer;
    FElements: TArray<Double>;
    function GetElement(r, c: Integer): PDouble; inline;
    procedure CheckIndex(r, c: Integer); inline;
  public
    // The table is length = numRows * numCols
    // and the elements are initialized to zero.
    constructor From(numRows, numCols: Integer); overload;
    // For r in [0 .. numRows - 1] and c in [0 .. numCols - 1]
    // element (r, c) is 1 and all others are 0.
    // If either of r or c is invalid, the zero matrix is created.
    // This is a convenience for creating the standard Euclidean basis matrices;
    // see also MakeUnit(Integer,Integer) and Unit(Integer,Integer).
    constructor From(numRows, numCols, r, c: Integer); overload;
    // Member access for which the storage representation is transparent.

    // The matrix entry in row r and column c is A(r,c).
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
    // Diagonal entries 1, others 0, even when nonsquare.
    procedure MakeIdentity;
    function Zero(numRows, numCols: Integer): TgMatrix;
    // Result := Self + m
    function Add(const m: TgMatrix): TgMatrix;
    // Result := Self - m
    function Minus(const m: TgMatrix): TgMatrix;
    // Result := Self * scalar
    function Multiply(const scalar: Double): TgMatrix; overload;
    // Result := Self * v
    function Multiply(const v: TgVector): TgVector; overload;
    // Result := Self * m
    function Multiply(const m: TgMatrix): TgMatrix; overload;
    // Result := Self * m
    function Inverse(Invertibility: PBoolean = nil): TgMatrix;
    function Determinante: Double;

    property numRows: Integer read FNumRows;
    property numCols: Integer read FNumCols;
    // Returns a total number of Elements.
    property NumElements: Integer read GetNumElements;
    // Returns a reference to Double value.
    property Element[r, c: Integer]: PDouble read GetElement; default;
  end;

{$EndRegion}

{$Region 'TGaussianElimination'}

  TGaussianElimination = record
  private
    // Support for copying source to target or to set target to zero.
    // If source is nil, then target is set to zero;
    // otherwise source is copied to target.
    class procedure Swap(a, b: PDouble); static;
  public
    // The input matrix M must be N x N.
    // If you want the inverse of M, pass a nonnull pointer inverseM;
    // this matrix must also be NxN and use the same storage convention as M.  If
    // you do not want the inverse of M, pass a nullptr for inverseM.
    // If you want to solve M*X = B for X, where X and B are N x 1,
    // pass nonnull pointers for B and X.
    // If you want to solve M*Y = C for Y, where X and C are N x K,
    // pass nonnull pointers for C and Y and pass K to numCols.
    // In all cases, pass N to numRows.
    class function Process(numRows: Integer; m, inverseM: PgMatrix;
      var determinant: Double; const b, x, c: PgVector;
      numCols: Integer; y: PgVector): Boolean; static;
  end;

{$EndRegion}

{$Region 'TVector2'}

  TVector2 = record
  var
    v: TgVector;
  public
    class function From: TVector2; static;
  end;

{$EndRegion}

{$Region 'TMatrix2x2'}

  TMatrix2x2 = record
  var
    m: TgMatrix;
  public
    class function From: TMatrix2x2; static;
    function Inverse(invertibility: PBoolean): TMatrix2x2;
  end;

{$EndRegion}

{$Region 'TLinearSystem'}

  TLinearSystem = record
  public
    // Solve systems by inverting the matrix directly.
    function Solve(const A: TMatrix2x2; const B: TVector2; var X: TVector2): Boolean;
  end;

{$EndRegion}

implementation

procedure CheckSize(b: Boolean);
begin
  if not b then
    raise EgtError.Create('Mismatched sizes');
end;

{$Region 'TgVector'}

constructor TgVector.From(size: Integer);
begin
  SetSize(size);
end;

constructor TgVector.From(size, d: Integer);
begin
  SetSize(size);
  MakeUnit(d);
end;

procedure TgVector.SetSize(size: Integer);
begin
  Assert(size >= 0, 'Invalid size.');
  SetLength(FItems, size);
end;

function TgVector.GetSize: Integer;
begin
  Result := Length(FItems);
end;

function TgVector.GetItem(i: Integer): PDouble;
begin
  Result := @FItems[i];
end;

procedure TgVector.MakeZero;
var
  i: Integer;
begin
  for i := 0 to high(FItems) do
    FItems[i] := 0.0;
end;

function TgVector.Zero(size: Integer): TgVector;
begin
  SetLength(Result.FItems, size);
  Result.MakeZero;
end;

procedure TgVector.MakeUnit(d: Integer);
var
  i: Integer;
begin
  for i := 0 to high(FItems) do
    if i = d then
      FItems[i] := 1.0
    else
      FItems[i] := 0.0;
end;

function TgVector.GetUnit(size, d: Integer): TgVector;
begin
  SetLength(Result.FItems, size);
  Result.MakeUnit(d);
end;

function TgVector.Equals(const v: TgVector): Boolean;
var
  i, n: Integer;
begin
  n := GetSize;
  Result := n = v.GetSize;
  if Result then
    for i := 0 to high(FItems) do
      if not SameValue(FItems[i], v.FItems[i]) then
        exit(False);
end;

function TgVector.Negative: TgVector;
var
  i: Integer;
begin
  for i := 0 to high(FItems) do
    Result.FItems[i] := -FItems[i];
end;

function TgVector.Plus(const v: TgVector): TgVector;
var
  i: Integer;
begin
  CheckSize(GetSize = v.GetSize);
  for i := 0 to high(FItems) do
    Result.FItems[i] := FItems[i] + v.FItems[i];
end;

function TgVector.Minus(const v: TgVector): TgVector;
var
  i: Integer;
begin
  CheckSize(GetSize = v.GetSize);
  for i := 0 to high(FItems) do
    Result.FItems[i] := FItems[i] - v.FItems[i];
end;

function TgVector.Scale(s: Double): TgVector;
var
  i: Integer;
begin
  for i := 0 to high(FItems) do
    Result.FItems[i] := FItems[i] * s;
end;

{$EndRegion}

{$Region 'TgMatrix'}

constructor TgMatrix.From(numRows, numCols: Integer);
begin
  SetSize(numRows, numCols);
end;

constructor TgMatrix.From(numRows, numCols, r, c: Integer);
begin
  SetSize(numRows, numCols);
  MakeUnit(r, c);
end;

procedure TgMatrix.GetSize(var numRows, numCols: Integer);
begin
  numRows := FNumRows;
  numCols := FNumCols;
end;

function TgMatrix.GetNumCols: Integer;
begin
  Result := FNumCols;
end;

function TgMatrix.GetNumElements: Integer;
begin
  Result := Length(FElements);
end;

function TgMatrix.GetNumRows: Integer;
begin
  Result := FNumRows;
end;

procedure TgMatrix.CheckIndex(r, c: Integer);
begin
  if (Cardinal(r) >= Cardinal(GetNumRows)) or
    (Cardinal(c) >= Cardinal(GetNumCols)) then
    raise EgtError.Create('Invalid index');
end;

function TgMatrix.GetElement(r, c: Integer): PDouble;
begin
  CheckIndex(r, c);
  Result := @FElements[c + FNumCols * r];
end;

procedure TgMatrix.SetSize(numRows, numCols: Integer);
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

procedure TgMatrix.MakeZero;
var
  i: Integer;
begin
  for i := 0 to High(FElements) do
    FElements[i] := 0.0;
end;

procedure TgMatrix.MakeUnit(r, c: Integer);
begin
  CheckIndex(r, c);
  MakeZero;
  Element[r, c]^ := 1.0;
end;

procedure TgMatrix.MakeIdentity;
var
  i, numDiagonal: Integer;
begin
  MakeZero;
  if FNumRows <= FNumCols then
    numDiagonal := FNumRows
  else
    numDiagonal := FNumCols;
  for i := 0 to numDiagonal - 1 do
    Element[i, i]^ := 1.0;
end;

function TgMatrix.Zero(numRows, numCols: Integer): TgMatrix;
begin
  Result := TgMatrix.From(numRows, numCols);
  Result.MakeZero;
end;

function TgMatrix.Add(const m: TgMatrix): TgMatrix;
var
  r, c: Integer;
  p: PDouble;
begin
  Result := TgMatrix.From(numRows, numCols);
  for r := 0 to Result.GetNumRows - 1 do
  begin
    for c := 0 to Result.GetNumCols - 1 do
    begin
      p := Result.Element[r, c];
      p^ := p^ + m.Element[r, c]^;
    end;
  end;
end;

function TgMatrix.Minus(const m: TgMatrix): TgMatrix;
var
  r, c: Integer;
  p: PDouble;
begin
  Result := TgMatrix.From(numRows, numCols);
  for r := 0 to Result.GetNumRows - 1 do
  begin
    for c := 0 to Result.GetNumCols - 1 do
    begin
      p := Result.Element[r, c];
      p^ := p^ - m.Element[r, c]^;
    end;
  end;
end;

function TgMatrix.Multiply(const scalar: Double): TgMatrix;
var
  r, c: Integer;
  p: PDouble;
begin
  Result := TgMatrix.From(numRows, numCols);
  for r := 0 to Result.GetNumRows - 1 do
  begin
    for c := 0 to Result.GetNumCols - 1 do
    begin
      p := Result.Element[r, c];
      p^ := p^ * scalar;
    end;
  end;
end;

function TgMatrix.Multiply(const v: TgVector): TgVector;
var
  r, c: Integer;
  d: Double;
begin
  Result := TgVector.From(numRows);
  for r := 0 to numRows - 1 do
  begin
    d := 0;
    for c := 0 to numCols - 1 do
      d := d + Element[r, c]^ * v.Items[c]^;
    Result[r]^ := d;
  end;
end;

function TgMatrix.Multiply(const m: TgMatrix): TgMatrix;
var
  numCommon, r, c, i: Integer;
  p: PDouble;
begin
  CheckSize(Self.GetNumCols = m.GetNumRows);
  Result := TgMatrix.From(Self.GetNumRows, m.GetNumCols);
  numCommon := Self.GetNumCols;
  for r := 0 to Result.GetNumRows - 1 do
  begin
    for c := 0 to Result.GetNumCols - 1 do
    begin
      Result.Element[r, c]^ := 0.0;
      for i := 0 to numCommon - 1 do
      begin
        p := Result.Element[r, c];
        p^ := p^ + p^ * m.Element[i, c]^;
      end;
    end;
  end;
end;

function TgMatrix.Inverse(Invertibility: PBoolean = nil): TgMatrix;
var
  invM: TgMatrix;
  determinant: Double;
  invertible: Boolean;
begin
  if GetNumRows() <> GetNumCols() then
    raise EgtError.Create('Matrix must be square.');
  invM := TgMatrix.From(GetNumRows(), GetNumCols());

  invertible := TGaussianElimination.Process(GetNumRows(), @Self, @invM,
    determinant, nil, nil, nil, 0, nil);
  if Invertibility <> nil then
    Invertibility^ := invertible;
  Result := invM;
end;

function TgMatrix.Determinante(): Double;
begin
  if GetNumRows() <> GetNumCols() then
    raise EgtError.Create('Matrix must be square.');
  TGaussianElimination.Process(GetNumRows(), @Self, nil, Result, nil, nil,
    nil, 0, nil);
end;

{$EndRegion}

{$Region 'TGaussianElimination'}

class function TGaussianElimination.Process(numRows: Integer;
  m, inverseM: PgMatrix; var determinant: Double;
  const b, x, c: PgVector; numCols: Integer; y: PgVector): Boolean;
const
  Zero: Double = 0;
  one: Double = 1;
var
  numElements, i, i0, i1, i2, row, col: Integer;
  wantInverse, odd: Boolean;
  localInverseM: TArray<Double>;
  colIndex, rowIndex: TArray<Integer>;
  pivoted: TArray<Boolean>;
  maxValue, value, absValue, diagonal, inv, save: Double;
  matInvM, matY: PgMatrix;
begin
  if (numRows <= 0) or (m <> nil) or ((b <> nil) <> (x <> nil)) or
    ((c <> nil) <> (y <> nil)) or ((c <> nil) and (numCols < 1)) then
    raise EgtError.Create('Invalid input.');

  numElements := numRows * numRows;
  wantInverse := inverseM <> nil;

  if not wantInverse then
  begin
    SetLength(localInverseM, numElements);
    inverseM := @localInverseM[0];
  end;
  inverseM^ := m^;
  if b <> nil then
    x^ := b^;
  if c <> nil then
    y^ := c^;
  // SetLength(matInvM, numRows, numRows, inverseM);
  // SetLength(matY, numRows, numCols, Y);

  SetLength(colIndex, numRows);
  SetLength(rowIndex, numRows);
  SetLength(pivoted, numRows);
  odd := False;
  determinant := one;
  // Elimination by full pivoting.
  row := 0;
  col := 0;
  for i0 := 0 to numRows - 1 do
  begin
    // Search matrix (excluding pivoted rows) for maximum absolute entry.
    maxValue := Zero;
    for i1 := 0 to numRows - 1 do
    begin
      if pivoted[i1] then
      begin
        for i2 := 0 to numRows - 1 do
        begin
          if pivoted[i2] then
          begin
            value := matInvM.Element[i1, i2]^;
            if value >= Zero then
              absValue := value
            else
              absValue := -value;
            if absValue > maxValue then
            begin
              maxValue := absValue;
              row := i1;
              col := i2;
            end;
          end;
        end;
      end;
    end;

    if maxValue = Zero then
    begin
      // The matrix is not invertible.
      if wantInverse then
        inverseM.MakeZero;
      determinant := Zero;

      if b <> nil then
        x.MakeZero;

      if c <> nil then
        y.MakeZero;
      exit(False);
    end;

    pivoted[col] := True;

    // Swap rows so that the pivot entry is in row 'col'.
    if row <> col then
    begin
      odd := not odd;
      for i := 0 to numRows - 1 do
        Swap(matInvM.Element[row, i], matInvM.Element[col, i]);

      if b <> nil then
        Swap(x.Items[row], x.Items[col]);

      if c <> nil then
        for i := 0 to numCols - 1 do
          Swap(matY.Element[row, i], matY.Element[col, i]);
    end;
  end;

  // Keep track of the permutations of the rows.
  rowIndex[i0] := row;
  colIndex[i0] := col;

  // Scale the row so that the pivot entry is 1.
  diagonal := matInvM.Element[col, col]^;
  determinant := determinant * diagonal;
  inv := one / diagonal;
  matInvM.Element[col, col]^ := one;
  for i2 := 0 to numRows - 1 do
    matInvM.Element[col, i2]^ := matInvM.Element[col, i2]^ * inv;

  if b <> nil then
    x.Items[col]^ := x.Items[col]^ * inv;

  if c <> nil then
    for i2 := 0 to numCols - 1 do
      matY.Element[col, i2]^ := matY.Element[col, i2]^ * inv;

  // Zero out the pivot column locations in the other rows.
  for i1 := 0 to numRows - 1 do
    if i1 <> col then
    begin
      save := matInvM.Element[i1, col]^;
      matInvM.Element[i1, col]^ := Zero;
      for i2 := 0 to numRows - 1 do
        matInvM.Element[i1, i2]^ := matInvM.Element[i1, i2]^ - matInvM.Element[col, i2]^ * save;
      if b <> nil then
        x.Items[i1]^ := x.Items[i1]^ - x.Items[col]^ * save;

      if c <> nil then
        for i2 := 0 to numCols - 1 do
          matY.Element[i1, i2]^ := matY.Element[i1, i2]^ - matY.Element[col, i2]^ * save;
    end;

  if wantInverse then
  begin
    // Reorder rows to undo any permutations in Gaussian elimination.
    for i1 := numRows - 1 downto 0 do
    begin
      if rowIndex[i1] <> colIndex[i1] then
      begin
        for i2 := 0 to numRows - 1 do
          Swap(matInvM.Element[i2, rowIndex[i1]], matInvM.Element[i2, colIndex[i1]]);
      end;
    end;
  end;

  if odd then
    determinant := -determinant;
  Result := True;
end;

class procedure TGaussianElimination.Swap(a, b: PDouble);
var
  temp: Double;
begin
  temp := a^;
  a^ := b^;
  b^ := temp;
end;

{$EndRegion}

{$Region 'TVector2'}

class function TVector2.From: TVector2;
begin
  Result.v := TgVector.From(2);
end;

{$EndRegion}

{$Region 'TMatrix2x2'}

class function TMatrix2x2.From: TMatrix2x2;
begin
  Result.m := TgMatrix.From(2, 2);
end;

function TMatrix2x2.Inverse(invertibility: PBoolean): TMatrix2x2;
var
  invertible: Boolean;
  det, invDet: Double;
begin
  det := m[0, 0]^ * m[1, 1]^ - m[0, 1]^ * m[1, 0]^;
  if det = 0 then
  begin
    Result.m.MakeZero;
    invertible := False;
  end
  else
  begin
    invDet := 1 / det;
    Result := TMatrix2x2.From;
    Result.m.FElements := [
      m[1, 1]^ * invDet,
      -m[0, 1]^ * invDet,
      -m[1, 0]^ * invDet,
      m[0, 0]^ * invDet];
    invertible := True;
  end;
  if invertibility <> nil then
    invertibility^ := invertible;
end;

{$EndRegion}

{$Region 'TLinearSystem'}

function TLinearSystem.Solve(const A: TMatrix2x2; const B: TVector2;
  var X: TVector2): Boolean;
var
  invertible: Boolean;
  invA: TMatrix2x2;
begin
  invA := A.Inverse(@invertible);
  if invertible then
    X.v := invA.m.Multiply(B.v)
  else
    X.v.MakeZero;
  Result := invertible;
end;

{$EndRegion}

end.
