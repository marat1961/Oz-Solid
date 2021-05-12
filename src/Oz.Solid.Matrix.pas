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

  TgVector = record
  private
    FItems: TArray<Double>;
    function GetItem(i: Integer): Double; inline;
    procedure SetItem(i: Integer; value: Double); inline;
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
    property Items[Index: Integer]: Double read GetItem write SetItem;
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
    // Result := Self + M
    function Add(const M: TgMatrix): TgMatrix;
    // Result := Self - M
    function Minus(const M: TgMatrix): TgMatrix;
    // Result := Self * scalar
    function Multiply(const scalar: Double): TgMatrix; overload;
    // Result := Self * M
    function Multiply(const M: TgMatrix): TgMatrix; overload;
    // Result := Self * M
    function Inverse(Invertibility: PBoolean = nil): TgMatrix;
    function Determinante: Double;

    property NumRows: Integer read FNumRows;
    property NumCols: Integer read FNumCols;
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
    // If source is nil, then target is set to zero; otherwise source is
    // copied to target.  This function hides the type traits used to
    // determine whether Double is native floating-point or otherwise (such
    // as BSNumber or BSRational).
    class procedure Setv(numElements: Integer; source, target: PDouble); static;
  public
    class function Process(numRows: Integer; M, inverseM: PgMatrix;
      var determinant: Double; const B, X, C: PDouble;
      numCols: integer; Y: PDouble): Boolean; static;
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

function TgVector.GetItem(i: Integer): Double;
begin
  Result := FItems[i];
end;

procedure TgVector.SetItem(i: Integer; Value: Double);
begin
  FItems[i] := Value;
end;

procedure TgVector.MakeZero;
var
  i: Integer;
begin
  for i := 0 to High(FItems) do
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
  for i := 0 to High(FItems) do
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
    for i := 0 to High(FItems) do
      if not SameValue(FItems[i], v.FItems[i]) then
        exit(False);
end;

function TgVector.Negative: TgVector;
var
  i: Integer;
begin
  for i := 0 to High(FItems) do
    Result.FItems[i] := -FItems[i];
end;

function TgVector.Plus(const v: TgVector): TgVector;
var
  i: Integer;
begin
  CheckSize(GetSize = v.GetSize);
  for i := 0 to High(FItems) do
    Result.FItems[i] := FItems[i] + v.FItems[i];
end;

function TgVector.Minus(const v: TgVector): TgVector;
var
  i: Integer;
begin
  CheckSize(GetSize = v.GetSize);
  for i := 0 to High(FItems) do
    Result.FItems[i] := FItems[i] - v.FItems[i];
end;

function TgVector.Scale(s: Double): TgVector;
var
  i: Integer;
begin
  for i := 0 to High(FItems) do
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

function TgMatrix.Add(const M: TgMatrix): TgMatrix;
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
      p^ := p^ + M.Element[r, c]^;
    end;
  end;
end;

function TgMatrix.Minus(const M: TgMatrix): TgMatrix;
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
      p^ := p^ - M.Element[r, c]^;
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

function TgMatrix.Multiply(const M: TgMatrix): TgMatrix;
var
  numCommon, r, c, i: Integer;
  p: PDouble;
begin
  CheckSize(Self.GetNumCols = M.GetNumRows);
  Result := TgMatrix.From(Self.GetNumRows, M.GetNumCols);
  numCommon := Self.GetNumCols;
  for r := 0 to Result.GetNumRows - 1 do
  begin
    for c := 0 to Result.GetNumCols - 1 do
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

function TgMatrix.Inverse(Invertibility: PBoolean = nil): TgMatrix;
var
  invM: TgMatrix;
  determinant: Double;
  invertible: Boolean;
begin
  if GetNumRows() <> GetNumCols() then
    raise EgtError.Create('Matrix must be square.');
  invM := TgMatrix.From(GetNumRows(), GetNumCols());

  invertible := TGaussianElimination.Process(GetNumRows(), @Self,
      @invM, determinant, nil, nil, nil, 0, nil);
  if Invertibility <> nil then
    Invertibility^ := invertible;
  Result := invM;
end;

function TgMatrix.Determinante(): Double;
begin
  if GetNumRows() <> GetNumCols() then
    raise EgtError.Create('Matrix must be square.');
  TGaussianElimination.Process(GetNumRows(), @Self, nil,
      Result, nil, nil, nil, 0, nil);
end;

{$EndRegion}

{$Region 'TGaussianElimination'}

class function TGaussianElimination.Process(numRows: Integer; M, inverseM: PgMatrix;
  var determinant: Double; const B, X, C: PDouble; numCols: integer;
  Y: PDouble): Boolean;
const
  zero: Double = 0;
  one: Double = 1;
var
  numElements, i0, i1, i2, row, col: Integer;
  wantInverse, odd: Boolean;
  localInverseM: TArray<Double>;
  colIndex, rowIndex, pivoted: TArray<Integer>;
  maxValue: Double;
begin
  if (numRows <= 0) or (M <> nil) or
     ((B <> nil) <> (X <> nil)) or
     ((C <> nil) <> (Y <> nil)) or
     ((C <> nil) and (numCols < 1)) then
    raise EgtError.Create('Invalid input.');

  numElements := numRows * numRows;
  wantInverse := inverseM <> nil;

  if not wantInverse then
  begin
    SetLength(localInverseM, numElements);
    inverseM.FElements := localInverseM;
  end;
  Setv(numElements, @M.FElements[0], @inverseM.FElements[0]);

  if B <> nil then
    Setv(numRows, B, X);

  if C <> nil  then
    Setv(numRows * numCols, C, Y);

  SetLength(colIndex, numRows);
  SetLength(rowIndex, numRows);
  SetLength(pivoted, numRows);

  odd := False;
  determinant := one;

  // Elimination by full pivoting.
  row := 0; col := 0;
  for i0 := 0 to numRows - 1 do
  begin
    // Search matrix (excluding pivoted rows) for maximum absolute entry.
    maxValue := zero;
    for i1 := 0 to numRows - 1 do
    begin
      if pivoted[i1] = nil then
      begin
        for i2 := 0 to numRows - 1 do
        begin
          if not pivoted[i2] then
          begin
            Double value = matInvM(i1, i2);
            Double absValue = (value >= zero ? value : -value);
            if (absValue > maxValue)
            begin
              maxValue = absValue;
              row = i1;
              col = i2;
            end;
          end;
        end;
      end;
    end;

    if (maxValue = zero)
    begin
        // The matrix is not invertible.
        if (wantInverse)
        begin
            Set(numElements, nil, inverseM);
        end;
        determinant = zero;

        if (B)
        begin
            Set(numRows, nil, X);
        end;

        if (C)
        begin
            Set(numRows * numCols, nil, Y);
        end;
        return false;
    end;

    pivoted[col] = true;

    // Swap rows so that the pivot entry is in row 'col'.
    if (row <> col)
    begin
        odd = not odd;
        for (Integer i = 0; i < numRows; ++i)
        begin
            std::swap(matInvM(row, i), matInvM(col, i));
        end;

        if (B)
        begin
            std::swap(X[row], X[col]);
        end;

        if (C)
        begin
            for (Integer i = 0; i < numCols; ++i)
            begin
                std::swap(matY(row, i), matY(col, i));
            end;
        end;
    end;

    // Keep track of the permutations of the rows.
    rowIndex[i0] = row;
    colIndex[i0] = col;

    // Scale the row so that the pivot entry is 1.
    Double diagonal = matInvM(col, col);
    determinant *= diagonal;
    Double inv = one / diagonal;
    matInvM(col, col) = one;
    for (i2 = 0; i2 < numRows; ++i2)
    begin
        matInvM(col, i2) *= inv;
    end;

    if (B)
    begin
        X[col] *= inv;
    end;

    if (C)
    begin
        for (i2 = 0; i2 < numCols; ++i2)
        begin
            matY(col, i2) *= inv;
        end;
    end;

    // Zero out the pivot column locations in the other rows.
    for (i1 = 0; i1 < numRows; ++i1)
    begin
        if (i1 <> col)
        begin
            Double save = matInvM(i1, col);
            matInvM(i1, col) = zero;
            for (i2 = 0; i2 < numRows; ++i2)
            begin
                matInvM(i1, i2) -= matInvM(col, i2) * save;
            end;

            if (B)
            begin
                X[i1] -= X[col] * save;
            end;

            if (C)
            begin
                for (i2 = 0; i2 < numCols; ++i2)
                begin
                    matY(i1, i2) -= matY(col, i2) * save;
                end;
            end;
        end;
      end;
    end;

    if (wantInverse)
    begin
        // Reorder rows to undo any permutations in Gaussian elimination.
        for (i1 = numRows - 1; i1 >= 0; --i1)
        begin
            if (rowIndex[i1] <> colIndex[i1])
            begin
                for (i2 = 0; i2 < numRows; ++i2)
                begin
                    std::swap(matInvM(i2, rowIndex[i1]),
                        matInvM(i2, colIndex[i1]));
                end;
            end;
        end;
    end;

    if (odd)
    begin
        determinant = -determinant;
    end;

    return true;
end;

class procedure TGaussianElimination.Setv(numElements: Integer; source, target: PDouble);
begin
    if (std::is_floating_point<Double>() = std::true_type())
    begin
        // Fast set/copy for native floating-point.
        size_t numBytes = numElements * sizeof(Double);
        if (source)
        begin
            std::memcpy(target, source, numBytes);
        end;
        else
        begin
            std::memset(target, 0, numBytes);
        end;
    end;
    else
    begin
        // The inputs are not std containers, so ensure assignment works
        // correctly.
        if (source)
        begin
            for (Integer i = 0; i < numElements; ++i)
            begin
                target[i] = source[i];
            end;
        end;
        else
        begin
            Double const zero = (Double)0;
            for (Integer i = 0; i < numElements; ++i)
            begin
                target[i] = zero;
            end;
        end;
    end;
end;

{$EndRegion}

end.

