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
unit Oz.Solid.Intersect;

interface

{$Region 'Uses'}

uses
  System.Math, Oz.Solid.Types;

{$EndRegion}

{$T+}

{$Region 'TsdTriangle'}

type
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
    // Signed volume
    function SignedVolume: Double;
    // Signed area
    function Area: Double;
    function IsDegenerate: Boolean;
    // "Fast, Minimum Storage Ray/Triangle Intersection",
    // Tomas Moeller and Ben Trumbore.
    function Raytrace(const rayPoint, rayDir: TsdVector; var t: Double;
      inters: PsdVector): Boolean;
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

{$Region 'Intersect subroutines'}

// Return intersection point of the segments
function IntersectionOfLines(ax0, ay0, dxa, dya, bx0, by0, dxb, dyb: Double;
  var cx, cy: Double): Boolean;
// Return the intersection point of line segments
function IntersectSegments(const a, b, c, d: T2dPoint;
  var cross: T2dPoint): Boolean;
// Return the intersection point of lines
function IntersectLines(const a, b, c, d: T2dPoint;
  var cross: T2dPoint): Boolean;
function AtIntersectionOfLines(const a0, a1, b0, b1: TsdVector;
  skew: PBoolean; pa, pb: PDouble): TsdVector;
procedure ClosestPointBetweenLines(const a0, da, b0, db: TsdVector;
  var pa, pb: Double);

// Return signed area
function GetSignedArea(const points: TArray<T2dPoint>): Double;

{$EndRegion}

implementation

{$Region 'Intersect subroutines'}

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

function AtIntersectionOfLines(const a0, a1, b0, b1: TsdVector;
  skew: PBoolean; pa, pb: PDouble): TsdVector;
var
  da, db: TsdVector;
  a, b: Double;
begin
  da := a1.Minus(a0);
  db := b1.Minus(b0);
  ClosestPointBetweenLines(a0, da, b0, db, a, b);
  if pa <> nil then pa^ := a;
  if pb <> nil then pb^ := b;
  var r := a0.Plus(da.ScaledBy(a));
  if skew <> nil then
    skew^ := not r.Equals(b0.Plus(db.ScaledBy(b)));
 Result := r;
end;

procedure ClosestPointBetweenLines(const a0, da, b0, db: TsdVector;
  var pa, pb: Double);
var
  dn, dna, dnb: TsdVector;
begin
  dn := da.Cross(db);
  dna := dn.Cross(da);
  dnb := dn.Cross(db);
  pb := a0.Minus(b0).Dot(dna) / db.Dot(dna);
  pa := -a0.Minus(b0).Dot(dnb) / da.Dot(dnb);
end;

function GetSignedArea(const points: TArray<T2dPoint>): Double;
var
  i, n: Integer;
  r: Double;
begin
  n := High(points);
  if n < 1 then exit(0);
  r := (points[0].X - points[n].X) * (points[0].Y + points[n].Y);
  for i := 0 to n - 1 do
    r := r + (points[i + 1].X - points[i].X) * (points[i + 1].Y + points[i].Y);
  Result := r * 0.5;
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

