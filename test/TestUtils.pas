(* Oz CSG, for Delphi
 * Copyright (c) 2020 Tomsk, Marat Shaimardanov
 *
 * This file is part of Oz CSG, for Delphi
 * is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This file is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this file. If not, see <https://www.gnu.org/licenses/>.
*)

unit TestUtils;

interface

uses
  System.Classes, System.Math, TestFramework, Oz.Solid.Types;

{$Region 'Test2dPoint'}

type
  Test2dPoint = class(TTestCase)
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestCollinearity;
    procedure TestDistanceToLine;
    procedure TestClosestPointOnLine;
    procedure TestIntersectLines;
    procedure TestIntersectSegments;
  end;

{$EndRegion}

implementation

{$Region 'Test2dPoint'}

procedure Test2dPoint.SetUp;
begin
  inherited;

end;

procedure Test2dPoint.TearDown;
begin
  inherited;

end;

procedure Test2dPoint.TestCollinearity;
var
  a, b, c: T2dPoint;
  s: Double;
begin
  a := T2dPoint.From(0, 0);
  b := T2dPoint.From(15, 15);
  c := T2dPoint.From(10000, 10000);
  s := b.Minus(a).Cross(c.Minus(a));
  CheckTrue(Abs(s) <= 1e-6);
  c := T2dPoint.From(500, 500.2);
  s := b.Minus(a).Cross(c.Minus(a));
  CheckTrue(Abs(s) > 1e-6);
end;

procedure Test2dPoint.TestDistanceToLine;
var
  pt, ps, pf: T2dPoint;
  d: Double;
begin
  pt := T2dPoint.From(1, 1);
  ps := T2dPoint.From(0, 0);
  pf := T2dPoint.From(10, 0);
  d := pt.DistanceToLine(ps, pf.Minus(ps), False);
  CheckTrue(SameValue(d, 1));
end;

procedure Test2dPoint.TestClosestPointOnLine;
var
  pt, ps, pf, r, t: T2dPoint;
begin
  pt := T2dPoint.From(5, 8);
  ps := T2dPoint.From(1, 1);
  pf := T2dPoint.From(100, 1);
  r := pt.ClosestPointOnLine(ps, pf.Minus(ps), False);
  t := T2dPoint.From(5, 1);
  CheckTrue(r.DistanceTo(t) < 1E-6);

  pf := T2dPoint.From(100, 4);
  r := pt.ClosestPointOnLine(ps, pf.Minus(ps), False);
  t := T2dPoint.From(5.208256880734, 1.1275229358);
  CheckTrue(r.DistanceTo(t) < 1E-6);
end;

procedure Test2dPoint.TestIntersectLines;
var
  a, b, c, d, cross, t: T2dPoint;
begin
  a := T2dPoint.From(0, 2);
  b := T2dPoint.From(1, 2);
  c := T2dPoint.From(3, 0);
  d := T2dPoint.From(3, 1);
  IntersectLines(a, b, c, d, cross);
  t := T2dPoint.From(3, 2);
  CheckTrue(cross.DistanceTo(t) < 1E-6);

  a := T2dPoint.From(1, 1);
  b := T2dPoint.From(3, 3);
  c := T2dPoint.From(1, 3);
  d := T2dPoint.From(3, 1);
  IntersectLines(a, b, c, d, cross);
  t := T2dPoint.From(2, 2);
  CheckTrue(cross.DistanceTo(t) < 1E-6);
end;

procedure Test2dPoint.TestIntersectSegments;
var
  a, b, c, d, cross, t: T2dPoint;
  ok: Boolean;
begin
  // 1. the segments intersect
  a := T2dPoint.From(1, 1);
  b := T2dPoint.From(3, 3);
  c := T2dPoint.From(1, 3);
  d := T2dPoint.From(3, 1);
  ok := IntersectSegments(a, b, c, d, cross);
  CheckTrue(ok);
  t := T2dPoint.From(2, 2);
  CheckTrue(cross.DistanceTo(t) < 1E-6);
  // 2. parallel lines
  a := T2dPoint.From(1, 1);
  b := T2dPoint.From(3, 3);
  c := T2dPoint.From(0, 1);
  d := T2dPoint.From(2, 3);
  ok := IntersectSegments(a, b, c, d, cross);
  CheckTrue(not ok);
  // 3. coinciding line segments
  a := T2dPoint.From(1, 1);
  b := T2dPoint.From(3, 3);
  c := T2dPoint.From(1, 1);
  d := T2dPoint.From(3, 3);
  ok := IntersectSegments(a, b, c, d, cross);
  CheckTrue(not ok);
  // 4. the segments do not intersect
  a := T2dPoint.From(1, 1);
  b := T2dPoint.From(3, 3);
  c := T2dPoint.From(2, 0);
  d := T2dPoint.From(2, 1);
  ok := IntersectSegments(a, b, c, d, cross);
  CheckTrue(not ok);
  a := T2dPoint.From(1, 1);
  b := T2dPoint.From(3, 3);
  c := T2dPoint.From(-1, 1);
  d := T2dPoint.From(1, -1);
  ok := IntersectSegments(a, b, c, d, cross);
  CheckTrue(not ok);

  // 5. the extreme point lies on the inside of the segment
  a := T2dPoint.From(1, 1);
  b := T2dPoint.From(3, 3);
  c := T2dPoint.From(1, 3);
  d := T2dPoint.From(2, 2);
  ok := IntersectSegments(a, b, c, d, cross);
  CheckTrue(ok);
  t := T2dPoint.From(2, 2);
  CheckTrue(cross.DistanceTo(t) < 1E-6);

  // 5. extreme points coincide
  a := T2dPoint.From(1, 1);
  b := T2dPoint.From(3, 3);
  c := T2dPoint.From(1, 1);
  d := T2dPoint.From(1, 5);
  ok := IntersectSegments(a, b, c, d, cross);
  CheckTrue(ok);
  t := T2dPoint.From(1, 1);
  CheckTrue(cross.DistanceTo(t) < 1E-6);
end;

{$EndRegion}

initialization
  RegisterTest(Test2dPoint.Suite);

end.
