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
  System.Classes, System.SysUtils, System.Math, TestFramework,
  Oz.Solid.Types, Oz.Solid.Intersect, Oz.Solid.Svg, Oz.Solid.VectorInt,
  Oz.Solid.Boolean, Oz.Solid.EarTri, Oz.Solid.DelaunayTri, Oz.Solid.Polygon;

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

{$Region 'TestSvg'}

  TestSvg = class(TTestCase)
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestGenRect;
    procedure TestGenPolygon;
  end;

{$EndRegion}

{$Region 'EarTri'}

  TestEarTri = class(TTestCase)
  public
    EarTri: TEarTri;
    filename: string;
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestTri;
    procedure TestSq;
    procedure TestSnake;
    procedure Test18;
  end;

{$EndRegion}

{$Region 'DelaunayTri'}

  TestDelaunayTri = class(TTestCase)
  public
    Tri: TDelaunayTri;
    filename: string;
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestTri10;
    procedure TestTri100;
  end;

{$EndRegion}

{$Region 'Polygon'}

  TestPolygon = class(TTestCase)
  public
    Pb: TPolyBuilder;
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestSqSq;
  end;

{$EndRegion}

{$Region 'TestBool'}

  TestBool = class(TTestCase)
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure Test;
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

  // 6. extreme points coincide
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

{$Region 'TestSvg'}

procedure TestSvg.SetUp;
begin
  inherited;
end;

procedure TestSvg.TearDown;
begin
  inherited;
end;

procedure TestSvg.TestGenRect;
const
  filename = 'd:\test\rect.svg';
var
  b: TsvgBuilder;
begin
  b := TsvgBuilder.Create(1200, 400, TMeasureUnit.muCentimeter);
  try
    b.ViewBox(0, 0, 1200, 400);
    b.Rect(1, 1, 1198, 398).Fill('none').Stroke('blue').StrokeWidth(2);
    b.SaveToFile(filename);
  finally
    b.Free;
  end;
end;

procedure TestSvg.TestGenPolygon;
const
  filename = 'd:\test\polygon.svg';
var
  b: TsvgBuilder;
begin
  b := TsvgBuilder.Create(300, 200, TMeasureUnit.muCentimeter);
  try
    b.ViewBox(0, 0, 300, 200);
    b.Polygon.Point(0, 100).Point(50, 25).Point(50, 75).Point(100, 0);
    b.Polygon.Point(100, 100).Point(150, 25).Point(150, 75).Point(200, 0).
    Fill('none').Stroke('black');
    b.SaveToFile(filename);
  finally
    b.Free;
  end;
end;

{$EndRegion}

{$Region 'EarTri'}

procedure TestEarTri.SetUp;
begin
  inherited;
end;

procedure TestEarTri.TearDown;
begin
  EarTri.Free;
  inherited;
end;

procedure TestEarTri.TestTri;
begin
  filename := '..\..\..\data\i_tri';
  EarTri.Build(filename);
end;

procedure TestEarTri.TestSq;
begin
  filename := '..\..\..\data\i_sq';
  EarTri.Build(filename);
end;

procedure TestEarTri.TestSnake;
begin
  filename := '..\..\..\data\i_snake';
  EarTri.Build(filename);
end;

procedure TestEarTri.Test18;
begin
  filename := '..\..\..\data\i_18';
  EarTri.Build(filename);
end;

{$EndRegion}

{$Region 'DelaunayTri'}

procedure TestDelaunayTri.SetUp;
begin
  inherited;
end;

procedure TestDelaunayTri.TearDown;
begin
  inherited;
  Tri.Free;
end;

procedure TestDelaunayTri.TestTri10;
begin
  filename := '..\..\..\data\dt_10';
  Tri := TDelaunayTri.Create(filename);
  Tri.Build;
end;

procedure TestDelaunayTri.TestTri100;
begin
  filename := '..\..\..\data\dt_100';
  Tri := TDelaunayTri.Create(filename);
  Tri.Build;
end;

{$EndRegion}

{$Region 'Polygon'}

procedure TestPolygon.SetUp;
begin
  inherited;
end;

procedure TestPolygon.TearDown;
begin
  inherited;
end;

procedure TestPolygon.TestSqSq;
var
  filename: string;
begin
  filename := '..\..\..\data\i.sqsq';
  Pb.Build(filename);
  Pb.Free;
end;

{$EndRegion}

{$Region 'TestBool'}

procedure TestBool.SetUp;
begin
  inherited;

end;

procedure TestBool.TearDown;
begin
  inherited;

end;

procedure TestBool.Test;
const
  a1: array [0..3] of T2i = (
    (x: -7; y: 8), (x: -7; y: -3), (x: 2; y: -3), (x: 2; y: 8));
  a2: array [0..3] of T2i = (
    (x: -5; y: 6), (x: 0; y: 6), (x: 0; y: 0), (x: -5; y: 0));
  ba: array [0..10] of T2i = (
    (x: -5; y: -6), (x: 7; y: -6), (x: 7; y: 4), (x: -5; y: 4),
    (x: 0; y: 0), (x: 0; y: 2), (x: 5; y: 2), (x: 5; y: -4),
    (x: 0; y: -4), (x: 0; y: 0), (x: -5; y: 0));
var
  A, B, R: P2Polygon;
  i: Integer;
  pline: P2Contour;
  err: TErrorNumber;
begin
  A := nil;
  B := nil;
  pline := nil;

  // construct 1st polygon
  for i := 0 to High(a1) do
    T2Contour.Incl(pline, a1[i]);
  pline.Prepare;
  if not pline.IsOuter then
    // make sure the contour is outer
    pline.Invert;
  T2Polygon.InclPline(A, pline);
  pline := nil;
  for i := 0 to High(a2) do
    T2Contour.Incl(pline, a2[i]);
  pline.Prepare;
  if pline.IsOuter then
    // make sure the contour is a hole
    pline.Invert();
  T2Polygon.InclPline(A, pline);

  // construct 2nd polygon
  pline := nil;
  for i := 0 to High(ba) do
    T2Contour.Incl(pline, ba[i]);
  pline.Prepare;
  if not pline.IsOuter then
    // make sure the contour is outer
    pline.Invert;
  T2Polygon.InclPline(B, pline);

  // do Boolean operation XOR
  R := nil;
  err := T2Polygon.Bool(A, B, R, T2Polygon.TBoolOp.opXor);
  CheckTrue(err = ecOk);

  // triangulate R
  err := T2Polygon.Triangulate(R);
  CheckTrue(err = ecOk);

  // delete all polygons
  T2Polygon.Del(&A);
  T2Polygon.Del(&B);
  T2Polygon.Del(&R);

end;

{$EndRegion}

initialization
  RegisterTest(TestPolygon.Suite);
  RegisterTest(TestDelaunayTri.Suite);
  RegisterTest(TestEarTri.Suite);
  RegisterTest(Test2dPoint.Suite);
  RegisterTest(TestSvg.Suite);

end.
