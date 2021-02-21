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
unit Oz.Solid.Bezier;

interface

{$Region 'Uses'}

uses
  Oz.SGL.Collections,
  Oz.Solid.Types;

{$EndRegion}

{$T+}

type
  PsdDoubleList = ^TsdDoubleList;
  TsdDoubleList = TsgList<Double>;

{$Region 'TsdId, TsdEntry'}

  TsdId = record
    v: Cardinal;
  end;

  PsdEntry = ^TsdEntry;
  TsdEntry = record
    tag: Integer;
    h: TsdId;
  end;

  hEntity = record
    v: Cardinal;
  end;

{$EndRegion}

{$Region 'TsdVector4'}

  TsdVector4 = record
    w, x, y, z: Double;
    constructor From(w, x, y, z: Double); overload;
    constructor From(w: Double; const v: TsdVector); overload;
    constructor Blend(const a, b: TsdVector4; t: Double);
    function Plus(const b: TsdVector4): TsdVector4;
    function Minus(const b: TsdVector4): TsdVector4;
    function ScaledBy(s: Double): TsdVector4;
    function PerspectiveProject: TsdVector;
  end;

{$EndRegion}

{$Region 'TsdVectorHelper'}

  TsdVectorHelper = record helper for TsdVector
  public const
    Zero: TsdVector = (x: 0; y: 0; z: 0);
  public
    function Project4d: TsdVector4;
  end;

{$EndRegion}

{$Region 'TsdVectors'}

  PsdVectors = ^TsdVectors;
  TsdVectors = record
    List: TsgRecordList<TsdVector>;
    procedure Init;
    procedure Free;
    function Find(const Pt: TsdVector): Integer;
  end;

{$EndRegion}

{$Region 'TsdBezier'}

  TsdBezier = record
    deg: Integer;
    ctrl: array [0..3] of TsdVector;
    weight: array [0..3] of Double;
    auxA: Integer;
    entity: hEntity;
    constructor From(const p0, p1: TsdVector); overload;
    constructor From(const p0, p1, p2: TsdVector); overload;
    constructor From(const p0, p1, p2, p3: TsdVector); overload;
    constructor From(const p0, p1: TsdVector4); overload;
    constructor From(const p0, p1, p2: TsdVector4); overload;
    constructor From(const p0, p1, p2, p3: TsdVector4); overload;
  end;
  PsdBezierOwner = ^TsdBezierOwner;
  TsdBezierOwner = TsgRecordList<TsdBezier>;

{$EndRegion}

function Bernstein(k, deg: Integer; t: Double): Double;
function BernsteinDerivative(k, deg: Integer; t: Double): Double;

implementation

function Bernstein(k, deg: Integer; t: Double): Double;
type
  PExponents = ^TExponents;
  TExponents = record
    c0, c1, c2, c3: Double;
  end;
  TBernsteinCoeff = array [0..3, 0..3] of TExponents;
const
  BernsteinCoeff: array [0..3, 0..3] of TExponents =(
    ((c0: 1; c1: 0;  c2: 0; c3:  0), (), (), ()),
    ((c0: 1; c1: -1; c2: 0; c3:  0), (c0: 0; c1: 1; c2: 0; c3: 0), (), ()),
    ((c0: 1; c1: -2; c2: 1; c3:  0), (c0: 0; c1: 2; c2: -2; c3: 0),
     (c0: 0; c1: 0;  c2: 1; c3:  0), ()),
    ((c0: 1; c1: -3; c2: 3; c3: -1), (c0: 0; c1: 3; c2: -6; c3: 3),
     (c0: 0; c1: 0;  c2: 3; c3: -3), (c0: 0; c1: 0; c2: 0; c3: 1)));
var
  e: PExponents;
begin
  e := @BernsteinCoeff[deg][k];
  Result := (((e.c3 * t + e.c2) * t) + e.c1) * t + e.c0;
end;

function BernsteinDerivative(k, deg: Integer; t: Double): Double;
type
  PExponents = ^TExponents;
  TExponents = record
    c0, c1, c2: Double;
  end;
const
  BernsteinDerivativeCoeff: array [0..3, 0..3] of TExponents = (
    ((c0:  0; c1: 0; c2:  0), (), (), ()),
    ((c0: -1; c1: 0; c2:  0), (c0: 1; c1:   0; c2: 0), (), ()),
    ((c0: -2; c1: 2; c2:  0), (c0: 2; c1:  -4; c2: 0),
     (c0: 0;  c1: 2; c2:  0), ()),
    ((c0: -3; c1: 6; c2: -3), (c0: 3; c1: -12; c2: 9),
     (c0: 0; c1: 6; c2: -9),  (c0: 0; c1:   0; c2: 3)));
var
  e: PExponents;
begin
  e := @BernsteinDerivativeCoeff[deg][k];
  Result := ((e.c2 * t) + e.c1) * t + e.c0;
end;

{$Region 'TsdVector4'}

constructor TsdVector4.From(w, x, y, z: Double);
begin
  Self.w := w;
  Self.x := x;
  Self.y := y;
  Self.z := z;
end;

constructor TsdVector4.From(w: Double; const v: TsdVector);
begin
  From(w, w * v.x, w * v.y, w * v.z);
end;

constructor TsdVector4.Blend(const a, b: TsdVector4; t: Double);
begin
  Self := (a.ScaledBy(1 - t)).Plus(b.ScaledBy(t));
end;

function TsdVector4.Plus(const b: TsdVector4): TsdVector4;
begin
  Result := TsdVector4.From(w + b.w, x + b.x, y + b.y, z + b.z);
end;

function TsdVector4.Minus(const b: TsdVector4): TsdVector4;
begin
  Result := TsdVector4.From(w - b.w, x - b.x, y - b.y, z - b.z);
end;

function TsdVector4.ScaledBy(s: Double): TsdVector4;
begin
  Result := TsdVector4.From(w * s, x * s, y * s, z * s);
end;

function TsdVector4.PerspectiveProject: TsdVector;
begin
  Result := TsdVector.From(x / w, y / w, z / w);
end;

{$EndRegion}

{$Region 'TsdVectors'}

procedure TsdVectors.Init;
begin
  List := TsgRecordList<TsdVector>.From(nil);
end;

procedure TsdVectors.Free;
begin
  List.Free;
end;

function TsdVectors.Find(const Pt: TsdVector): Integer;
var i: Integer;
begin
  for i := 0 to List.Count - 1 do
    if List.Items[i].Equals(Pt) then exit(i);
  Result := -1;
end;

{$EndRegion}

{$Region 'TsdBezier'}

constructor TsdBezier.From(const p0, p1: TsdVector);
begin
  From(p0.Project4d, p1.Project4d);
end;

constructor TsdBezier.From(const p0, p1, p2: TsdVector);
begin
  From(p0.Project4d, p1.Project4d, p2.Project4d);
end;

constructor TsdBezier.From(const p0, p1, p2, p3: TsdVector);
begin
  From(p0.Project4d, p1.Project4d, p2.Project4d, p3.Project4d);
end;

constructor TsdBezier.From(const p0, p1: TsdVector4);
begin
  Self := Default(TsdBezier);
  deg := 1;
  weight[0] := p0.w;
  ctrl[0] := p0.PerspectiveProject;
  weight[1] := p1.w;
  ctrl[1] := p1.PerspectiveProject;
end;

constructor TsdBezier.From(const p0, p1, p2: TsdVector4);
begin
  Self := Default(TsdBezier);
  deg := 2;
  weight[0] := p0.w;
  ctrl[0] := p0.PerspectiveProject;
  weight[1] := p1.w;
  ctrl[1] := p1.PerspectiveProject;
  weight[2] := p2.w;
  ctrl[2] := p2.PerspectiveProject;
end;

constructor TsdBezier.From(const p0, p1, p2, p3: TsdVector4);
begin
  Self := Default(TsdBezier);
  deg := 3;
  weight[0] := p0.w;
  ctrl[0] := p0.PerspectiveProject;
  weight[1] := p1.w;
  ctrl[1] := p1.PerspectiveProject;
  weight[2] := p2.w;
  ctrl[2] := p2.PerspectiveProject;
  weight[3] := p3.w;
  ctrl[3] := p3.PerspectiveProject;
end;

{$EndRegion}

{$Region 'TsdVectorHelper'}

function TsdVectorHelper.Project4d: TsdVector4;
begin
  Result := TsdVector4.From(1, x, y, z);
end;

{$EndRegion}

end.

