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
    // Component d is 1, all others are zero.
    procedure MakeUnit(d: Integer);

    function Zero(size: Integer): TVector;
    function GetUnit(size, d: Integer): TVector;

    property Items[Index: Integer]: Double read GetItem write SetItem;
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
    FTuple[i] := 0;
end;

procedure TVector.MakeUnit(d: Integer);
var
  i: Integer;
begin
  for i := 0 to High(FTuple) do
    if i = d then
      FTuple[d] := 1
    else
      FTuple[d] := 0;
end;

function TVector.Zero(size: Integer): TVector;
begin
  SetLength(Result.FTuple, size);
  Result.MakeZero;
end;

function TVector.GetUnit(size, d: Integer): TVector;
begin
  SetLength(Result.FTuple, size);
  Result.MakeUnit(d);
end;

{$EndRegion}

end.

