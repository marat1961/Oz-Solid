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
unit Oz.Solid.Types;

interface

{$Region 'Uses'}

uses
  System.Classes, System.SysUtils, System.Types, System.UITypes, System.Math,
  System.Math.Vectors, Oz.SGL.Collections;

{$EndRegion}

{$T+}

const
  LengthEps = 1e-6;
  VeryPositive = 1e10;
  VeryNegative = -1e10;
type
  TSinglePoint = type TPointF;
  ESolidError = class(Exception);

{$Region 'T2dPoint'}

  P2dPoint = ^T2dPoint;
  T2dPoint = record
    x, y: Double;
    constructor From(x, y: Double);
    procedure Setup(x, y: Double);
    procedure SetZero;
    function IsZero: Boolean;
    function Plus(const p: T2dPoint): T2dPoint;
    function Minus(const p: T2dPoint): T2dPoint;
    function ToString: string;
    function ScaledBy(s: Double): T2dPoint;
    function DivProjected(const delta: T2dPoint): Double;
    // Returns the dot product
    function Dot(const p: T2dPoint): Double;
    // Returns the cross product
    function Cross(const p: T2dPoint): Double;
    function DistanceTo(const p: T2dPoint): Double;
    function DistanceToLine(const p0, dp: T2dPoint; asSegment: Boolean): Double;
    function DistanceToLineSigned(const p0, dp: T2dPoint; asSegment: Boolean): Double;
    function ClosestPointOnLine(const p0, dp: T2dPoint; asSegment: Boolean): T2dPoint;
    function Angle: Double;
    function AngleTo(const p: T2dPoint): Double;
    function Magnitude: Double;
    function MagSquared: Double;
    function WithMagnitude(v: Double): T2dPoint;
    function Equals(const v: T2dPoint; Tol: Double = LengthEps): Boolean;
    function Normal: T2dPoint;
  end;

  T2dPointHelper = record helper for T2dPoint
  public const
    Zero: T2dPoint = (x: 0; y: 0);
    Empty: T2dPoint = (x: MaxDouble; y: MaxDouble);
  end;
  P2dPoints = ^T2dPoints;
  T2dPoints = TArray<T2dPoint>;

{$EndRegion}

{$Region 'TsdSegment'}

  TsdSegment = record
  var
    a, b: T2dPoint;
  public
    function Vector: T2dPoint; inline;
    function Cross: Double;
    function IntersectsLines(const line: TsdSegment; var cross: T2dPoint): Boolean;
  end;

{$EndRegion}

{$Region 'TsdVector'}

  PsdVector = ^TsdVector;
  TsdVector = packed record
  public
    constructor From(x, y, z: Double);
    procedure Setup(x, y, z: Double);
    function IsZero: Boolean;
    procedure SetZero;
    procedure Move(dx, dy, dz: Double);
    function Plus(Dx, Dy, Dz: Double): TsdVector; overload;
    function Plus(const v: TsdVector): TsdVector; overload;
    function Minus(const v: TsdVector): TsdVector;
    function Negated: TsdVector;
    function ToString: string;
    function Hash: NativeInt;
    function Equals(const v: TsdVector; tol: Double = LengthEps): Boolean;
    function EqualsExactly(const v: TsdVector): Boolean;
    // Returns the dot product
    function Dot(const v: TsdVector): Double;
    // Returns the cross product
    function Cross(const v: TsdVector): TsdVector;
    function Normal(which: Integer): TsdVector;
    function Magnitude: Double;
    function Normalize: TsdVector; inline;
    function WithMagnitude(value: Double): TsdVector;
    function MagSquared: Double;
    function DivProjected(const delta: TsdVector): Double;
    function ScaledBy(s: Double): TsdVector;
    function ClosestPointOnLine(const p0, dp: TsdVector): TsdVector;
    function ClosestOrtho: TsdVector;
    function DistanceTo(const p: TsdVector): Double;
    function DistanceToLine(const p0, dp: TsdVector): Double;
    function DistanceToPlane(const normal, origin: TsdVector): Double;
    function ScalarTripleProduct(const b, c: TsdVector): Double;
    function OnLineSegment(const a, b: TsdVector; tol: Double = LengthEps): Boolean;
    function RotatedAbout(const orig, axis: TsdVector; angle: Double): TsdVector; overload;
    function RotatedAbout(const axis: TsdVector; angle: Double): TsdVector; overload;
    function ScaleOutOfCsys(const u, v, n: TsdVector): TsdVector;
    function DotInToCsys(const u, v, n: TsdVector): TsdVector;
    function DirectionCosineWith(const b: TsdVector): Double;
    function ProjectXy: T2dPoint;
    function Project2d(const u, v: TsdVector): T2dPoint;
  type
    TElement = array [0 .. 2] of Double;
  var
    case Integer of
      0: (x, y, z: Double);
      1: (Element: TElement);
  end;
  P3dPoints = ^T3dPoints;
  T3dPoints = TArray<TsdVector>;

{$EndRegion}

{$Region 'TQuaternion'}

  TQuaternion = record
  public
    constructor From(w, x, y, z: Double); overload;
    constructor From(const u, v: TsdVector); overload;
    constructor From(const Vector: TsdVector; RotateAngle: Double); overload;
    class function Identity: TQuaternion; static;
    procedure SetIdentity;
    function ToString: string;
    function Magnitude: Double;
    function Normalize: TQuaternion;
    function WithMagnitude(s: Double): TQuaternion;
    function Conjugate: TQuaternion;
    function Inverse: TQuaternion;
    function Plus(const q: TQuaternion): TQuaternion; overload;
    function Add(d: Double): TQuaternion; overload;
    function Minus(const q: TQuaternion): TQuaternion; overload;
    function Times(const q: TQuaternion): TQuaternion; overload;
    function ScaledBy(s: Double): TQuaternion; overload;
    function Times(const p: TsdVector): TQuaternion; overload;
    function Rotate(const p: TsdVector): TsdVector;
    function RotationU: TsdVector;
    function RotationV: TsdVector;
    function RotationN: TsdVector;
    function Mirror: TQuaternion;
  public
    w: Double;
    case Integer of
      0: (v: TsdVector);
      1: (vx, vy, vz: Double);
  end;

{$EndRegion}

{$Region 'TsdTransformation'}

  TsdTransformation = record
    t: TsdVector;
    q: TQuaternion;
    scale: Double;
    procedure Init; overload;
    procedure Init(const t: TsdVector); overload;
    function NeedRotate: Boolean;
    function NeedTranslate: Boolean;
    function NeedScale: Boolean;
    function TransformPoint3d(const Point: TsdVector): TsdVector;
    function TransformPoint(const Point: T2dPoint): TsdVector;
    function TransformPoints3d(const Points: T3dPoints): T3dPoints;
    function TransformPoints(const Points: T2dPoints): T3dPoints;
  end;
  PsdTransformation = ^TsdTransformation;

{$EndRegion}

{$Region 'TVectorHelper'}

  TsdVectorHelper = record helper for TsdVector
  public const
    Zero: TsdVector = (x: 0; y: 0; z: 0);
    Empty: TsdVector = (x: MaxDouble; y: MaxDouble; z: MaxDouble);
  end;

{$EndRegion}

{$Region 'TRgbaColor'}

  TRgbaColor = packed record
  const
    Factor: Single = 255.1;
  var
    red, green, blue, alpha: Byte;
  public
    constructor From(r, g, b: Integer; a: Integer = 255);
    constructor FromFloat(r, g, b: Single; a: Single = 1.0);
    constructor FromPackedInt(rgba: Cardinal);
    class function FromPackedIntBGRA(bgra: Cardinal): TRgbaColor; static;
    function redF: Single;
    function greenF: Single;
    function blueF: Single;
    function alphaF: Single;
    function IsEmpty: Boolean;
    function Equals(const c: TRgbaColor): Boolean;
    function WithAlpha(newAlpha: Byte): TRgbaColor;
    function ToPackedIntBGRA: Cardinal;
    function ToPackedInt: Cardinal;
    function ToARGB32: Cardinal;
  end;

{$EndRegion}

{$Region 'TsdTriangle'}

  TsfTriMeta = record
    face: Cardinal;
    color: TRgbaColor;
    procedure Init(face: Integer; const color: TRgbaColor);
  end;

  TsdTriangle = record
  public
    constructor From(const meta: TsfTriMeta; const a, b, c: TsdVector);
    procedure Transform(const u, v, n: TsdVector; var tr: TsdTriangle);
    function Normal: TsdVector;
    procedure FlipNormal;
    function MinAltitude: Double;
    function ContainsPoint(const p: TsdVector): Boolean;
    function ContainsPointProjd(const n, p: TsdVector): Boolean;
    function SignedVolume: Double;
    function Area: Double;
    function Raytrace(const rayPoint, rayDir: TsdVector; var t: Double;
      inters: PsdVector): Boolean;
    function IsDegenerate: Boolean;
  public
    tag: Integer;
    meta: TsfTriMeta;
    case Integer of
      0: (a, b, c, an, bn, cn: TsdVector);
      1: (vertices, normals: array [0..2] of TsdVector);
  end;
  PsdTriangle = ^TsdTriangle;

{$EndRegion}

{$Region 'TBoundBox'}

  TBoundBox = record
    minp: TsdVector;
    maxp: TsdVector;
    procedure Init(const pt: TsdVector); inline;
    constructor From(const p0, p1: TsdVector); overload;
    constructor From(const tr: TsdTriangle); overload;
    constructor From(const points: T3dPoints); overload;
    procedure SetEmpty;
    function GetOrigin: TsdVector;
    function GetExtents: TsdVector;
    procedure Include(const v: TsdVector; r: Double = 0.0);
    function Overlaps(const box: TBoundBox): Boolean;
    function Contains(const p: T2dPoint; r: Double = 0.0): Boolean;
    function Disjoint(const box: TBoundBox): Boolean; overload;
    function Disjoint(const bmin, bmax: TsdVector): Boolean; overload;
    function IntersectsLine(const a, b: TsdVector; asSegment: Boolean): Boolean;
    function OutsideAndNotOn(const pt: TsdVector): Boolean;
 end;

{$EndRegion}

{$Region 'Subroutines'}

procedure Swap(var i, j: T2dPoint); overload;
procedure Swap(var i, j: TsdVector); overload;
function Bernstein(k, deg: Integer; t: Double): Double;
function BernsteinDerivative(k, deg: Integer; t: Double): Double;
function GetNormal(v: TsdVector): TsdVector;

// Return intersection point of the segments
function IntersectionOfLines(ax0, ay0, dxa, dya, bx0, by0, dxb, dyb: Double;
  var cx, cy: Double): Boolean;
// Return the intersection point of line segments
function IntersectSegments(const a, b, c, d: T2dPoint;
  var cross: T2dPoint): Boolean;
// Return the intersection point of lines
function IntersectLines(const a, b, c, d: T2dPoint;
  var cross: T2dPoint): Boolean;

{$EndRegion}

implementation

{$Region 'Subroutines'}

procedure Swap(var i, j: T2dPoint);
var
  temp: T2dPoint;
begin
  temp := i; i := j; j := temp;
end;

procedure Swap(var i, j: TsdVector);
var
  temp: TsdVector;
begin
  temp := i; i := j; j := temp;
end;

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

function GetNormal(v: TsdVector): TsdVector;
var
  Length: Double;
begin
  Length := v.Magnitude;
  Result.x := v.x / Length;
  Result.y := v.y / Length;
  Result.z := v.z / Length;
end;

function IntersectionOfLines(ax0, ay0, dxa, dya, bx0, by0, dxb, dyb: Double;
  var cx, cy: Double): Boolean;
var
  a: array [0..1, 0..1] of Double;
  b: array [0..1] of Double;
  v: Double;
begin
  if Abs(dya) > Abs(dyb) then
  begin
    a[0, 0] := dya;
    a[0, 1] := -dxA;
    b[0] := ax0 * dya - ay0 * dxa;
    a[1, 0] := dyb;
    a[1, 1] := -dxB;
    b[1] := bx0 * dyb - by0 * dxb;
  end
  else
  begin
    a[1, 0] := dya;
    a[1, 1] := -dxA;
    b[1] := ax0 * dya - ay0 * dxa;
    a[0, 0] := dyb;
    a[0, 1] := -dxB;
    b[0] := bx0 * dyb - by0 * dxb;
  end;
  if Abs(a[0, 0] * a[1, 1] - a[0, 1] * a[1, 0]) < LengthEps then
    exit(False);
  v := a[1, 0] / a[0, 0];
  a[1, 0] := a[1, 0] - a[0, 0] * v;
  a[1, 1] := a[1, 1] - a[0, 1] * v;
  b[1] := b[1] - b[0] * v;
  cy := b[1] / a[1, 1];
  cx := (b[0] - a[0, 1] * (cy)) / a[0, 0];
  result := True;
end;

function IntersectSegments(const a, b, c, d: T2dPoint;
  var cross: T2dPoint): Boolean;
var
  t, t1, t2: Double;
  ba, dc, ac: T2dPoint;
begin
  ba := b.Minus(a);
  dc := d.Minus(c);
  ac := a.Minus(c);
  t := ba.Cross(dc);
  t1 := dc.Cross(ac);
  t2 := ba.Cross(ac);
  if IsZero(t, 1e-12) then
    exit(False);
  t1 := t1 / t;
  t2 := t2 / t;
  Result :=
    InRange(t1, -LengthEps, 1 + LengthEps) and
    InRange(t2, -LengthEps, 1 + LengthEps);
  if Result then
    cross := a.Plus(ba.ScaledBy(t1));
end;

function IntersectLines(const a, b, c, d: T2dPoint;
  var cross: T2dPoint): Boolean;
var
  ab, cd:  T2dPoint;
  t, d1, d2: Double;
begin
  ab := a.Minus(b);
  cd := c.Minus(d);
  t := ab.Cross(cd);
  if Abs(t) < LengthEps then
    exit(False);
  d1 := a.Cross(b);
  d2 := c.Cross(d);
  cross.x := (d1 * cd.x - d2 * ab.x) / t;
  cross.y := (d1 * cd.y - d2 * ab.y) / t;
  Result := True;
end;

{$EndRegion}

{$Region 'T2dPoint'}

constructor T2dPoint.From(x, y: Double);
begin
  Self.x := x;
  Self.y := y;
end;

procedure T2dPoint.Setup(x, y: Double);
begin
  Self.x := x;
  Self.y := y;
end;

procedure T2dPoint.SetZero;
begin
  x := 0;
  y := 0;
end;

function T2dPoint.IsZero: Boolean;
begin
  Result := System.Math.IsZero(x) and System.Math.IsZero(y);
end;

function T2dPoint.Plus(const p: T2dPoint): T2dPoint;
begin
  Result.x := x + p.x;
  Result.y := y + p.y;
end;

function T2dPoint.Minus(const p: T2dPoint): T2dPoint;
begin
  Result.x := x - p.x;
  Result.y := y - p.y;
end;

function T2dPoint.ToString: string;
begin
  Result := Format('(x=%.2f y=%.2f)', [x, y]);
end;

function T2dPoint.ScaledBy(s: Double): T2dPoint;
begin
  Result.x := x * s;
  Result.y := y * s;
end;

function T2dPoint.DivProjected(const Delta: T2dPoint): Double;
begin
  if Abs(Delta.x) > Abs(Delta.y) then
    Result := x / Delta.x
  else
    Result := y / Delta.y;
end;

function T2dPoint.Dot(const p: T2dPoint): Double;
begin
  Result := x * p.x + y * p.y;
end;

function T2dPoint.Cross(const p: T2dPoint): Double;
begin
  Result := x * p.y - y * p.x;
end;

function T2dPoint.DistanceTo(const p: T2dPoint): Double;
begin
  Result := Hypot(x - p.x, y - p.y);
end;

function T2dPoint.DistanceToLine(const p0, dp: T2dPoint;
  asSegment: Boolean): Double;
var
  m, t: Double;
  closest: T2dPoint;
begin
  m := Sqr(dp.x) + Sqr(dp.y);
  if m < Sqr(LengthEps) then exit(VeryPositive);
  t := (dp.x * (x - p0.x) + dp.y * (y - p0.y)) / m;
  if asSegment then
  begin
    if t < 0 then exit(DistanceTo(p0));
    if t > 1 then exit(DistanceTo(p0.Plus(dp)));
  end;
  closest := p0.Plus(dp.ScaledBy(t));
  Result := DistanceTo(closest);
end;

function T2dPoint.DistanceToLineSigned(const p0, dp: T2dPoint;
  asSegment: Boolean): Double;
var
  m, dist, t, sign: Double;
  n: T2dPoint;
begin
  m := Sqr(dp.x) + Sqr(dp.y);
  if m < Sqr(LengthEps) then exit(VeryPositive);
  n := dp.Normal.WithMagnitude(1);
  dist := n.Dot(Self) - n.Dot(p0);
  if asSegment then
  begin
    t := (dp.x * (x - p0.x) + dp.y * (y - p0.y)) / m;
    if dist > 0.0 then sign := 1 else sign := -1;
    if t < 0 then exit(DistanceTo(p0) * sign);
    if t > 1 then exit(DistanceTo(p0.Plus(dp)) * sign);
  end;
  Result := dist;
end;

function T2dPoint.ClosestPointOnLine(const p0, dp: T2dPoint;
  asSegment: Boolean): T2dPoint;
var
  ap: T2dPoint;
  t, m, d: Double;
begin
  ap := Self.Minus(p0);
  m := dp.x * dp.x + dp.y * dp.y;
  d := ap.x * dp.x + ap.y * dp.y;
  t := d / m;
  if asSegment then
    if t < 0.0 then
      t := 0.0
    else if t > 1.0 then
      t := 1.0;
  Result := p0.Plus(dp.ScaledBy(t));
end;

function T2dPoint.Angle: Double;
var
  a: Double;
begin
  a := ArcTan2(y, x);
  Result := Pi + FMod(a - Pi, 2 * Pi);
end;

function T2dPoint.AngleTo(const p: T2dPoint): Double;
begin
  Result := p.Minus(Self).Angle;
end;

function T2dPoint.Equals(const v: T2dPoint; Tol: Double): Boolean;
var
  dx, dy: Double;
begin
  dx := v.x - x;
  if Abs(dx) < Tol then exit(false);
  dy := v.y - y;
  if Abs(dy) < Tol then exit(false);
  Result := Self.Minus(v).MagSquared < Sqr(Tol);
end;

function T2dPoint.Magnitude: Double;
begin
  Result := Hypot(x, y);
end;

function T2dPoint.MagSquared: Double;
begin
  Result := Sqr(x) + Sqr(y);
end;

function T2dPoint.Normal: T2dPoint;
begin
  Result.x := y;
  Result.y := -x;
end;

function T2dPoint.WithMagnitude(v: Double): T2dPoint;
var
  m: Double;
begin
  m := Magnitude;
  if m < 1e-20 then
  begin
    log.print('WithMagnitude: zero vector');
    Result.SetZero;
  end;
  Result.x := x * v / m;
  Result.y := y * v / m;
end;

{$EndRegion}

{$Region 'TsdSegment'}

function TsdSegment.Vector: T2dPoint;
begin
  Result := b.Minus(a);
end;

function TsdSegment.Cross: Double;
begin
  Result := (a.x * b.y) - (a.y * b.x);
end;

function TsdSegment.IntersectsLines(const line: TsdSegment;
  var cross: T2dPoint): Boolean;
var
  s: TsdSegment;
  c, d1, d2: Double;
begin
  s.a := Self.Vector;
  s.b := line.Vector;
  c := s.Cross;
  if Abs(c) < 1e-6 then
    exit(False);
  d1 := Self.Cross;
  d2 := line.Cross;
  cross.x := (d1 * s.b.x - d2 * s.a.x) / c;
  cross.y := (d1 * s.b.y - d2 * s.a.y) / c;
  Result := True;
end;

{$EndRegion}

{$Region 'TsdVector'}

constructor TsdVector.From(x, y, z: Double);
begin
  Self.x := x;
  Self.y := y;
  Self.z := z;
end;

procedure TsdVector.Setup(x, y, z: Double);
begin
  Self.x := x;
  Self.y := y;
  Self.z := z;
end;

function TsdVector.IsZero: Boolean;
begin
  Result := System.Math.IsZero(x) and System.Math.IsZero(y) and System.Math.IsZero(z);
end;

procedure TsdVector.SetZero;
begin
  x := 0;
  y := 0;
  z := 0;
end;

procedure TsdVector.Move(dx, dy, dz: Double);
begin
  x := x + dx;
  y := y + dy;
  z := z + dz;
end;

function TsdVector.Plus(Dx, Dy, Dz: Double): TsdVector;
begin
  Result.X := X + Dx;
  Result.Y := Y + Dy;
  Result.Z := Z + Dz;
end;

function TsdVector.Plus(const v: TsdVector): TsdVector;
begin
  Result.x := x + v.x;
  Result.y := y + v.y;
  Result.z := z + v.z;
end;

function TsdVector.Minus(const v: TsdVector): TsdVector;
begin
  Result.x := x - v.x;
  Result.y := y - v.y;
  Result.z := z - v.z;
end;

function TsdVector.ToString: string;
begin
  Result := Format('(x=%.2f y=%.2f z=%.2f)', [x, y, z]);
end;

function TsdVector.ClosestOrtho: TsdVector;
var
  mx, my, mz: Double;
begin
  mx := Abs(x);
  my := Abs(y);
  mz := Abs(z);
  Result.SetZero;
  if (mx > my) and (mx > mz) then
    if x > 0 then Result.x := 1 else Result.x := -1
  else if my > mz then
    if y > 0 then Result.y := 1 else Result.y := -1
 else
    if z > 0 then Result.z := 1 else Result.z := -1;
end;

function TsdVector.Dot(const v: TsdVector): Double;
begin
  Result := x * v.x + y * v.y + z * v.z;
end;

function TsdVector.Cross(const v: TsdVector): TsdVector;
begin
  Result.x := y * v.z - z * v.y;
  Result.y := z * v.x - x * v.z;
  Result.z := x * v.y - y * v.x;
end;

function TsdVector.Magnitude: Double;
begin
  Result := Sqrt(x * x + y * y + z * z);
end;

function TsdVector.MagSquared: Double;
begin
  Result := x * x + y * y + z * z;
end;

function TsdVector.Negated: TsdVector;
begin
  Result.x := -x;
  Result.y := -y;
  Result.z := -z;
end;

function TsdVector.Normal(which: Integer): TsdVector;
var
  a, n: TsdVector;
  xa, ya, za: Double;
begin
  xa := Abs(x);
  ya := Abs(y);
  za := Abs(z);
  a := TsdVector.From(0, 0, 1);
  if Self.Equals(a) then
    n := TsdVector.From(1, 0, 0)
  else if (xa < ya) and (xa < za) then
    n := TsdVector.From(0, z, -y)
  else if ya < za then
    n := TsdVector.From(-z, 0, x)
  else
    n := TsdVector.From(y, -x, 0);
  case which of
    0: {return n};
    1: n := Self.Cross(n);
    else raise ESolidError.Create('TVectorHelper.Normal invalid index');
  end;
  n := n.WithMagnitude(1);
  Result := n;
end;

function TsdVector.ScaledBy(s: Double): TsdVector;
begin
  Result.x := x * s;
  Result.y := y * s;
  Result.z := z * s;
end;

function TsdVector.ScaleOutOfCsys(const u, v, n: TsdVector): TsdVector;
begin
  Result := u.ScaledBy(x).Plus(v.ScaledBy(y)).Plus(n.ScaledBy(z));
end;

function TsdVector.DotInToCsys(const u, v, n: TsdVector): TsdVector;
begin
  Result.Setup(Dot(u), Dot(v), Dot(n));
end;

function TsdVector.Equals(const v: TsdVector; tol: Double): Boolean;
var
  dv: TsdVector;
begin
  dv := Self.Minus(v);
  if Abs(dv.x) > tol then exit(False);
  if Abs(dv.y) > tol then exit(False);
  if Abs(dv.z) > tol then exit(False);
  Result := dv.MagSquared < Sqr(tol);
end;

function TsdVector.EqualsExactly(const v: TsdVector): Boolean;
begin
  Result := (x = v.x) and (y = v.y) and (z = v.z);
end;

function TsdVector.ClosestPointOnLine(const p0, dp: TsdVector): TsdVector;
var
  m, pn, n: TsdVector;
  d: Double;
begin
  m := dp.WithMagnitude(1);
  pn := Self.Minus(p0).Cross(m);
  n := pn.Cross(m);
  d := m.Cross(p0.Minus(Self)).Magnitude;
  Result := Self.Plus(n.WithMagnitude(d));
end;

function TsdVector.DirectionCosineWith(const b: TsdVector): Double;
begin
  Result := Self.WithMagnitude(1).Dot(b.WithMagnitude(1));
end;

function TsdVector.DistanceTo(const p: TsdVector): Double;
begin
  Result := Sqrt(Self.Minus(p).MagSquared);
end;

function TsdVector.DistanceToLine(const p0, dp: TsdVector): Double;
var
  m: Double;
begin
  m := dp.Magnitude;
  Result := Self.Minus(p0).Cross(dp).Magnitude / m;
end;

function TsdVector.DistanceToPlane(const normal, origin: TsdVector): Double;
begin
  Result := Self.Dot(normal) - origin.Dot(normal);
end;

function TsdVector.ScalarTripleProduct(const b, c: TsdVector): Double;
begin
  Result := Self.Dot(b.Cross(c));
end;

function TsdVector.OnLineSegment(const a, b: TsdVector; tol: Double): Boolean;
var
  d: TsdVector;
  m, distsq, t: Double;
begin
  if Equals(a, tol) or Equals(b, tol) then exit(True);

  d := b.Minus(a);
  m := d.MagSquared;
  distsq := Self.Minus(a).Cross(d).MagSquared / m;
  if distsq >= tol * tol then exit(False);

  t := Self.Minus(a).DivProjected(d);
  if (t < 0) or (t > 1) then
    Result := False
  else
    Result := True;
end;

function TsdVector.DivProjected(const delta: TsdVector): Double;
var
  mx, my, mz: Double;
begin
  mx := Abs(delta.x);
  my := Abs(delta.y);
  mz := Abs(delta.z);
  if (mx > my) and (mx > mz) then
    Result := x / delta.x
  else if my > mz then
    Result := y / delta.y
  else
    Result := z / delta.z;
end;

function TsdVector.RotatedAbout(const orig, axis: TsdVector; angle: Double): TsdVector;
var
  r: TsdVector;
begin
  r := Self.Minus(orig);
  r := r.RotatedAbout(axis, angle);
  Result := r.Plus(orig);
end;

function TsdVector.RotatedAbout(const axis: TsdVector; angle: Double): TsdVector;
var
  s, c, dif: Double;
  m: TsdVector;
begin
  SinCos(angle, s, c);
  dif := 1 - c;
  m := axis.WithMagnitude(1);
  Result.x :=
    x * (c + dif * m.x * m.x) +
    y * (dif * m.x * m.y - s * m.z) +
    z * (dif * m.x * m.z + s * m.y);
  Result.y :=
    x * (dif * m.y * m.x + s * m.z) +
    y * (c + dif * m.y * m.y) +
    z * (dif * m.y * m.z - s * m.x);
  Result.z :=
    x * (dif * m.z * m.x - s * m.y) +
    y * (dif * m.z * m.y + s * m.x) +
    z * (c + dif * m.z * m.z);
end;

function TsdVector.Hash: NativeInt;
const
  Eps = LengthEps * 4;
var
  Size, xs, ys, zs: NativeInt;
begin
  Size := Trunc(Power(High(NativeInt), 1.0 / 3.0)) - 1;
  x := Abs(x) / Eps;
  y := Abs(y) / Eps;
  z := Abs(z) / Eps;
  xs := Trunc(FMod(x, Size));
  ys := Trunc(FMod(y, Size));
  zs := Trunc(FMod(z, Size));
  Result := (zs * Size + ys) * Size + xs;
end;

function TsdVector.Normalize: TsdVector;
begin
  Result := WithMagnitude(1.0)
end;

function TsdVector.WithMagnitude(value: Double): TsdVector;
var
  d: Double;
begin
  d := Magnitude;
  if d = 0.0 then
    Result.SetZero
  else
  begin
    d := value / d;
    Result.x := Result.x * d;
    Result.y := Result.y * d;
    Result.z := Result.z * d;
  end;
end;

function TsdVector.ProjectXy: T2dPoint;
begin
  Result.x := x;
  Result.y := y;
end;

function TsdVector.Project2d(const u, v: TsdVector): T2dPoint;
begin
  Result.x := Dot(u);
  Result.y := Dot(v);
end;

{$EndRegion}

{$Region 'TQuaternion'}

class function TQuaternion.Identity: TQuaternion;
begin
  Result.SetIdentity;
end;

procedure TQuaternion.SetIdentity;
begin
  w := 1;
  v.SetZero;
end;

constructor TQuaternion.From(w, x, y, z: Double);
begin
  Self.w := w;
  Self.v.x := x;
  Self.v.y := y;
  Self.v.z := z;
end;

constructor TQuaternion.From(const u, v: TsdVector);
var
  s, tr: Double;
  n: TsdVector;
begin
  n := u.Cross(v);
  tr := 1 + u.x + v.y + n.z;
  if tr > 1e-4 then
  begin
    s := 2 * Sqrt(tr);
    w := s / 4;
    vx := (v.z - n.y) / s;
    vy := (n.x - u.z) / s;
    vz := (u.y - v.x) / s;
  end
  else if (u.x > v.y) and (u.x > n.z) then
  begin
    s := 2 * Sqrt(1 + u.x - v.y - n.z);
    w := (v.z - n.y) / s;
    vx := s / 4;
    vy := (u.y + v.x) / s;
    vz := (n.x + u.z) / s;
  end
  else if v.y > n.z then
  begin
    s := 2 * Sqrt(1 - u.x + v.y - n.z);
    w := (n.x - u.z) / s;
    vx := (u.y + v.x) / s;
    vy := s / 4;
    vz := (v.z + n.y) / s;
  end
  else
  begin
    s := 2 * Sqrt(1 - u.x - v.y + n.z);
    w := (u.y - v.x) / s;
    vx := (n.x + u.z) / s;
    vy := (v.z + n.y) / s;
    vz := s / 4;
  end;
  Self := Self.WithMagnitude(1);
end;

constructor TQuaternion.From(const Vector: TsdVector; RotateAngle: Double);
var
  s, c: Double;
begin
  SinCos(RotateAngle * 0.5, s, c);
  w := c;
  v := GetNormal(Vector);
  v.x := v.x * s;
  v.y := v.y * s;
  v.z := v.z * s;
end;

function TQuaternion.ToString: string;
begin
  Result := Format('%f + %fx + %fy + %fz', [w, v.x, v.y, v.z]);
end;

function TQuaternion.Magnitude: Double;
begin
  Result := Sqrt(Sqr(w) + Sqr(v.x) + Sqr(v.y) + Sqr(v.z));
end;

function TQuaternion.Normalize: TQuaternion;
begin
  Result := WithMagnitude(1);
end;

function TQuaternion.WithMagnitude(s: Double): TQuaternion;
begin
  Result := ScaledBy(s / Magnitude);
end;

function TQuaternion.Conjugate: TQuaternion;
begin
  Result.w := w;
  Result.v.x := -v.x;
  Result.v.y := -v.y;
  Result.v.z := -v.z;
end;

function TQuaternion.Inverse: TQuaternion;
begin
  Result.w := w;
  Result.v.x := -v.x;
  Result.v.y := -v.y;
  Result.v.z := -v.z;
  Result := Result.WithMagnitude(1);
end;

function TQuaternion.Plus(const q: TQuaternion): TQuaternion;
begin
  Result.w := w + q.w;
  Result.v.x := v.x + q.v.x;
  Result.v.y := v.y + q.v.y;
  Result.v.z := v.z + q.v.z;
end;

function TQuaternion.Add(d: Double): TQuaternion;
begin
  Result.w := w + d;
  Result.v := v;
end;

function TQuaternion.Minus(const q: TQuaternion): TQuaternion;
begin
  Result.w := w - q.w;
  Result.v.x := v.x - q.v.x;
  Result.v.y := v.y - q.v.y;
  Result.v.z := v.z - q.v.z;
end;

function TQuaternion.Mirror: TQuaternion;
var
  u, v: TsdVector;
begin
  u := RotationU.ScaledBy(-1);
  v := RotationV.ScaledBy(-1);
  Result := TQuaternion.From(u, v);
end;

function TQuaternion.Times(const q: TQuaternion): TQuaternion;
begin
  Result.w := w * q.w - v.x * q.v.x - v.y * q.v.y - v.z * q.v.z;
  Result.v.x := w * q.v.x + v.x * q.w + v.y * q.v.z - v.z * q.v.y;
  Result.v.y := w * q.v.y - v.x * q.v.z + v.y * q.w + v.z * q.v.x;
  Result.v.z := w * q.v.z + v.x * q.v.y - v.y * q.v.x + v.z * q.w;
end;

function TQuaternion.Times(const p: TsdVector): TQuaternion;
begin
  Result.w := -vx * p.x - vy * p.y - vz * vz;
  Result.vx := w * p.x + vy * p.z - vz * vy;
  Result.vy := w * p.y - v.x * p.z + vz * v.x;
  Result.vz := w * p.z + v.x * p.y - vy * v.x;
end;

function TQuaternion.ScaledBy(s: Double): TQuaternion;
begin
  Result.w := w * s;
  Result.v.x := v.x * s;
  Result.v.y := v.y * s;
  Result.v.z := v.z * s;
end;

function TQuaternion.Rotate(const p: TsdVector): TsdVector;
begin
  Result := RotationU.ScaledBy(p.x)
    .Plus(RotationV.ScaledBy(p.y))
    .Plus(RotationN.ScaledBy(p.z));
end;

function TQuaternion.RotationU: TsdVector;
begin
  Result.x := w * w + vx * vx - vy * vy - vz * vz;
  Result.y := 2 * w * vz + 2 * vx * vy;
  Result.z := 2 * vx * vz - 2 * w * vy ;
end;

function TQuaternion.RotationV: TsdVector;
begin
  Result.x := 2 * vx * vy - 2 * w * vz;
  Result.y := w * w - vx  * vx  + vy * vy - vz * vz;
  Result.z := 2 * w * vx  + 2 * vy * vz;
end;

function TQuaternion.RotationN: TsdVector;
begin
  Result.x := 2 * w * vy + 2 * vx * vz;
  Result.y := 2 * vy * vz - 2 * w * vx ;
  Result.z := w * w - vx * vx - vy * vy + vz * vz;
end;

{$EndRegion}

{$Region 'TRgbaColor'}

constructor TRgbaColor.From(r, g, b: Integer; a: Integer = 255);
begin
  Self.red := Byte(r);
  Self.green := Byte(g);
  Self.blue := Byte(b);
  Self.alpha := Byte(a);
end;

constructor TRgbaColor.FromFloat(r, g, b: Single; a: Single = 1.0);
begin
  From(Round(Factor * r), Round(Factor * g), Round(Factor * b), Round(Factor * a));
end;

constructor TRgbaColor.FromPackedInt(rgba: Cardinal);
begin
  From(
    Integer((rgba) and $ff),
    Integer((rgba shr 8) and $ff),
    Integer((rgba shr 16) and $ff),
    Integer(255 - ((rgba shr 24) and $ff)));
end;

class function TRgbaColor.FromPackedIntBGRA(bgra: Cardinal): TRgbaColor;
begin
  Result := TRgbaColor.From(
    Integer((bgra shr 16) and $ff),
    Integer((bgra shr 8) and $ff),
    Integer((bgra) and $ff),
    Integer(255 - ((bgra shr 24) and $ff)));
end;

function TRgbaColor.redF: Single;
begin
  Result := Single(red) / Factor;
end;

function TRgbaColor.greenF: Single;
begin
  Result := Single(green) / Factor;
end;

function TRgbaColor.blueF: Single;
begin
  Result := Single(blue) / Factor;
end;

function TRgbaColor.alphaF: Single;
begin
  Result := Single(alpha) / Factor;
end;

function TRgbaColor.IsEmpty: Boolean;
begin
  Result := alpha = 0;
end;

function TRgbaColor.Equals(const c: TRgbaColor): Boolean;
begin
  Result := (c.red = red) and (c.green = green) and (c.blue = blue) and (c.alpha = alpha);
end;

function TRgbaColor.WithAlpha(newAlpha: Byte): TRgbaColor;
begin
  Result := Self;
  Result.alpha := newAlpha;
end;

function TRgbaColor.ToPackedIntBGRA: Cardinal;
begin
  Result := blue or Cardinal(green shl 8) or Cardinal(red shl 16) or
    Cardinal((255 - alpha) shl 24);
end;

function TRgbaColor.ToPackedInt: Cardinal;
begin
  Result := red or Cardinal(green shl 8) or Cardinal(blue shl 16) or
   Cardinal((255 - alpha) shl 24);
end;

function TRgbaColor.ToARGB32: Cardinal;
begin
  Result := blue or Cardinal(green shl 8) or Cardinal(red shl 16) or
    Cardinal(alpha shl 24);
end;

{$EndRegion}

{$Region 'TsfTriMeta'}

procedure TsfTriMeta.Init(face: Integer; const color: TRgbaColor);
begin
  Self.face := face;
  Self.color := color;
end;

{$EndRegion}

{$Region 'TsdTriangle'}

constructor TsdTriangle.From(const meta: TsfTriMeta; const a, b, c: TsdVector);
begin
  Fillchar(Self, sizeof(Self), 0);
  Self.meta := meta;
  Self.a := a;
  Self.b := b;
  Self.c := c;
end;

procedure TsdTriangle.Transform(const u, v, n: TsdVector; var tr: TsdTriangle);
begin
  tr := Self;
  tr.a := tr.a.ScaleOutOfCsys(u, v, n);
  tr.an := tr.an.ScaleOutOfCsys(u, v, n);
  tr.b := tr.b.ScaleOutOfCsys(u, v, n);
  tr.bn := tr.bn.ScaleOutOfCsys(u, v, n);
  tr.c := tr.c.ScaleOutOfCsys(u, v, n);
  tr.cn := tr.cn.ScaleOutOfCsys(u, v, n);
end;

function TsdTriangle.Normal: TsdVector;
begin
  Result := (b.Minus(a)).Cross(c.Minus(b));
end;

function TsdTriangle.Raytrace(const rayPoint, rayDir: TsdVector;
  var t: Double; inters: PsdVector): Boolean;
var
  ba, ca, rd, rp, qc: TsdVector;
  det, invDet, u, v: Double;
begin
  ba := b.Minus(a);
  ca := c.Minus(a);
  rd := rayDir.Cross(ca);
  det := ba.Dot(rd);
  if -det < LengthEps then exit(False);

  invDet := 1.0 / det;
  rp := rayPoint.Minus(a);
  u := rp.Dot(rd) * invDet;
  if (u < 0.0) or (u > 1.0) then exit(False);

  qc := rp.Cross(ba);
  v := rayDir.Dot(qc) * invDet;
  if (v < 0.0) or (u + v > 1.0) then exit(False);

  t := ca.Dot(qc) * invDet;
  if inters <> nil then
    inters^ := rayPoint.Plus(rayDir.ScaledBy(t));
  Result := True;
end;

function TsdTriangle.IsDegenerate: Boolean;
begin
  Result := a.OnLineSegment(b, c) or b.OnLineSegment(a, c) or c.OnLineSegment(a, b);
end;

function TsdTriangle.SignedVolume: Double;
begin
  Result := a.Dot(b.Cross(c)) / 6.0;
end;

function TsdTriangle.Area: Double;
var
  ab, cb: TsdVector;
begin
  ab := a.Minus(b);
  cb := c.Minus(b);
  Result := ab.Cross(cb).Magnitude * 0.5;
end;

procedure TsdTriangle.FlipNormal;
begin
  Swap(a, b);
  Swap(an, bn);
end;

function TsdTriangle.MinAltitude: Double;
var
  altA, altB, altC: Double;
begin
  altA := a.DistanceToLine(b, c.Minus(b));
  altB := b.DistanceToLine(c, a.Minus(c));
  altC := c.DistanceToLine(a, b.Minus(a));
  Result := Min(altA, Min(altB, altC));
end;

function TsdTriangle.ContainsPoint(const p: TsdVector): Boolean;
var
  n: TsdVector;
begin
  if MinAltitude < LengthEps then
    Result := False
  else
  begin
    n := Normal;
    Result := ContainsPointProjd(n.WithMagnitude(1), p);
  end;
end;

function TsdTriangle.ContainsPointProjd(const n, p: TsdVector): Boolean;
var
  ab, bc, ca, no_ab, no_bc, no_ca: TsdVector;
begin
  ab := b.Minus(a);
  bc := c.Minus(b);
  ca := a.Minus(c);
  no_ab := n.Cross(ab);
  if no_ab.Dot(p) < no_ab.Dot(a) - LengthEps then exit(False);
  no_bc := n.Cross(bc);
  if no_bc.Dot(p) < no_bc.Dot(b) - LengthEps then exit(False);
  no_ca := n.Cross(ca);
  if no_ca.Dot(p) < no_ca.Dot(c) - LengthEps then exit(False);
  Result := True;
end;

{$EndRegion}

{$Region 'TsdTransformation'}

procedure TsdTransformation.Init;
begin
  Self.t.SetZero;
  q.SetIdentity;
  scale := 1.0;
end;

procedure TsdTransformation.Init(const t: TsdVector);
begin
  Self.t := t;
  q.SetIdentity;
  scale := 1.0;
end;

function TsdTransformation.NeedTranslate: Boolean;
begin
  Result := not t.IsZero;
end;

function TsdTransformation.NeedRotate: Boolean;
begin
  Result := not (q.v.IsZero and SameValue(q.w, 1));
end;

function TsdTransformation.NeedScale: Boolean;
begin
  Result := not SameValue(scale, 1);
end;

function TsdTransformation.TransformPoint(const Point: T2dPoint): TsdVector;
begin
  Result.x := Point.x;
  Result.y := Point.y;
  Result.z := 0;
  Result := TransformPoint3d(Result);
end;

function TsdTransformation.TransformPoint3d(const Point: TsdVector): TsdVector;
begin
  Result := Point;
  if NeedScale then
    Result := Point.ScaledBy(scale);
  if NeedRotate then
    Result := q.Rotate(Result);
  if NeedTranslate then
    Result := Result.Plus(t);
end;

function TsdTransformation.TransformPoints3d(const Points: T3dPoints): T3dPoints;
var
  i: Integer;
begin
  SetLength(Result, Length(Points));
  for i := 0 to High(Points) do
    Result[i] := TransformPoint3d(Points[i]);
end;

function TsdTransformation.TransformPoints(const Points: T2dPoints): T3dPoints;
var
  i: Integer;
begin
  SetLength(Result, Length(Points));
  for i := 0 to High(Points) do
    Result[i] := TransformPoint(Points[i]);
end;

{$EndRegion}

{$Region 'TBoundBox'}

constructor TBoundBox.From(const p0, p1: TsdVector);
begin
  minp.x := Min(p0.x, p1.x);
  minp.y := Min(p0.y, p1.y);
  minp.z := Min(p0.z, p1.z);
  maxp.x := Max(p0.x, p1.x);
  maxp.y := Max(p0.y, p1.y);
  maxp.z := Max(p0.z, p1.z);
end;

constructor TBoundBox.From(const points: T3dPoints);
var
  i: Integer;
  pt: PsdVector;
begin
  minp := points[0];
  maxp := minp;
  for i := 1 to High(points) do
  begin
    pt := @points[i];
    maxp.x := Max(maxp.x, pt.x);
    maxp.y := Max(maxp.y, pt.y);
    maxp.z := Max(maxp.z, pt.z);
    minp.x := Min(minp.x, pt.x);
    minp.y := Min(minp.y, pt.y);
    minp.z := Min(minp.z, pt.z);
  end;
end;

constructor TBoundBox.From(const tr: TsdTriangle);
begin
  minp := tr.a;
  maxp := minp;
  Include(tr.b);
  Include(tr.c);
end;

procedure TBoundBox.Init(const pt: TsdVector);
begin
  minp := pt;
  maxp := minp;
end;

procedure TBoundBox.SetEmpty;
begin
  maxp := TsdVector.From(VeryNegative, VeryNegative, VeryNegative);
  minp := TsdVector.From(VeryPositive, VeryPositive, VeryPositive);
end;

function TBoundBox.GetOrigin: TsdVector;
begin
  Result := minp.Plus(maxp.Minus(minp).ScaledBy(0.5));
end;

function TBoundBox.GetExtents: TsdVector;
begin
  Result := maxp.Minus(minp).ScaledBy(0.5);
end;

procedure TBoundBox.Include(const v: TsdVector; r: Double);
begin
  minp.x := Min(minp.x, v.x - r);
  minp.y := Min(minp.y, v.y - r);
  minp.z := Min(minp.z, v.z - r);
  maxp.x := Max(maxp.x, v.x + r);
  maxp.y := Max(maxp.y, v.y + r);
  maxp.z := Max(maxp.z, v.z + r);
end;

function TBoundBox.Overlaps(const box: TBoundBox): Boolean;
var
  t, e: TsdVector;
begin
  t := box.GetOrigin.Minus(GetOrigin);
  e := box.GetExtents.Plus(GetExtents);
  Result := (Abs(t.x) < e.x) and (Abs(t.y) < e.y) and (Abs(t.z) < e.z);
end;

function TBoundBox.Contains(const p: T2dPoint; r: Double): Boolean;
begin
  Result :=
    (p.x >= minp.x - r) and (p.y >= minp.y - r) and
    (p.x <= maxp.x + r) and (p.y <= maxp.y + r);
end;

function TBoundBox.Disjoint(const box: TBoundBox): Boolean;
var
  i: Integer;
begin
  for i := 0 to 2 do
  begin
    if maxp.Element[i] < box.minp.Element[i] - LengthEps then exit(True);
    if minp.Element[i] > box.maxp.Element[i] + LengthEps then exit(True);
  end;
  Result := False;
end;

function TBoundBox.Disjoint(const bmin, bmax: TsdVector): Boolean;
var
  i: Integer;
begin
  for i := 0 to 2 do
  begin
    if maxp.Element[i] < bmin.Element[i] - LengthEps then exit(True);
    if minp.Element[i] > bmax.Element[i] + LengthEps then exit(True);
  end;
  Result := False;
end;

function TBoundBox.IntersectsLine(const a, b: TsdVector; asSegment: Boolean): Boolean;
var
  i, j, k, m: Integer;
  dp, p: TsdVector;
  lp, d, t: Double;
begin
  dp := b.Minus(a);
  lp := dp.Magnitude;
  dp := dp.ScaledBy(1 / lp);
  for i := 0 to 2 do
  begin
    j := (i + 1) mod 3;
    k := (i + 2) mod 3;
    if lp * Abs(dp.Element[i]) < LengthEps then continue;
    for m := 0 to 1 do
    begin
      if m = 0 then
        d := maxp.Element[i]
      else
        d := minp.Element[i];
      t := (d - a.Element[i]) / dp.Element[i];
      p := a.Plus(dp.ScaledBy(t));
      if asSegment and not InRange(t, -LengthEps, lp + LengthEps) then continue;
      if p.Element[j] > maxp.Element[j] + LengthEps then continue;
      if p.Element[k] > maxp.Element[k] + LengthEps then continue;
      if p.Element[j] < minp.Element[j] - LengthEps then continue;
      if p.Element[k] < minp.Element[k] - LengthEps then continue;
      exit(True);
    end;
  end;
  Result := False;
end;

function TBoundBox.OutsideAndNotOn(const pt: TsdVector): Boolean;
begin
  Result :=
    (pt.x > maxp.x + LengthEps) or (pt.x < minp.x - LengthEps) or
    (pt.y > maxp.y + LengthEps) or (pt.y < minp.y - LengthEps) or
    (pt.z > maxp.z + LengthEps) or (pt.z < minp.z - LengthEps);
end;

{$EndRegion}

end.

