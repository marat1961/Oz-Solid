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

unit Oz.Solid.Polygon;

interface

{$Region 'Uses'}

uses
  System.Classes, System.SysUtils, System.Math,
  Oz.SGL.Heap, Oz.SGL.Collections,
  Oz.Solid.Utils, Oz.Solid.Types, Oz.Solid.VectorInt, Oz.Solid.Svg;

{$EndRegion}

{$T+}

{$Region 'types'}

const
  EXIT_SUCCESS = 0;
  EXIT_FAILURE = 1;
  LengthEps = 1e-6;
  KdTreeEps = 10 * LengthEps;

type
  tInFlag = (Pin, Qin, Unknown);

  tPointd = record
    x, y: Double;
  end;

  // type integer polygon
  tPolygoni = TArray<T2i>;

{$EndRegion}

{$Region 'TsvgIO'}

  TsvgIO = record
  private
    filename: string;
    svg: TsvgBuilder;
    log: TStrings;
  public
    procedure Init(const filename: string);
    procedure Free;
    // Prints svg and log
    procedure PrintAll;
    // Debug print
    procedure Dbp; overload;
    procedure Dbp(const line: string); overload;
    procedure Dbp(const fs: string; const args: array of const); overload;
  end;

{$EndRegion}

{$Region 'TPolyBuilder'}

  TPolyBuilder = record
  private
    io: TsvgIO;
    n, m: Integer;
    P, Q: tPolygoni;
    procedure ClosePostscript();
    procedure PrintSharedSeg(p, q: tPointd);

    function Dot(a, b: T2i): Double;
    function AreaSign(a, b, c: T2i): Integer;
    // SegSegInt: Finds the point of intersection p between two closed
    // segments ab and cd.  Returns p and a char with the following meaning:
    //   'e': The segments collinearly overlap, sharing a point.
    //   'v': An endpoint (vertex) of one segment is on the other segment,
    //        but 'e' doesn't hold.
    //   '1': The segments intersect properly (i.e., they share a point and
    //        neither 'v' nor 'e' holds).
    //   '0': The segments do not intersect (i.e., they share no points).
    //  Note that two collinear segments that share just one point, an endpoint
    //  of each, returns 'e' rather than 'v' as one might expect.
    function SegSegInt(a, b, c, d: T2i; p, q: tPointd): Char;
    //
    function ParallelInt(a, b, c, d: T2i; p, q: tPointd): Char;
    // Returns TRUE iff point c lies on the closed segement ab.
    // Assumes it is already known that abc are collinear.
    function Between(a, b, c: T2i): Boolean;

    function Collinear(a, b, c: T2i): Boolean;

    procedure Assigndi(var p: tPointd; const a: T2i);
    procedure SubVec(const a, b:  T2i; var c: T2i);

    function InOut(p: tPointd; inflag: tInFlag; aHB, bHA: Integer): tInFlag;

    function Advance(poly: TsvgPolygon; a: Integer; var aa: Integer;
      n: Integer; inside: Boolean; v: T2i): Integer;
    // Read polygons
    procedure ReadPolygons(const filename: string);
    // Write to svg
    procedure OutputPolygons;
  public
    procedure Build(const filename: string);
    procedure Free;
    // P has n vertices, Q has m vertices.
    function ConvexIntersect(P, Q: tPolygoni; n, m: Integer): Integer;
  end;

{$EndRegion}

{$Region 'TsdPoint'}

  TEarType = (eUnknown, eNotEar, eEar);

  TsdPoint = record
    tag: Integer;
    ear: TEarType;
    p: TsdVector;
    auxv: TsdVector;
    procedure Init(const pt: TsdVector);
  end;
  PsdPoint = ^TsdPoint;

{$EndRegion}

{$Region 'TsdPoints'}

  PsdPoints = ^TsdPoints;
  TsdPoints = record
    List: TsdTaggedList<TsdPoint>;
    procedure Init;
    procedure Free;
    function ContainsPoint(const Pt: TsdVector): Boolean;
    function IndexForPoint(const Pt: TsdVector): Integer;
    procedure IncrementTagFor(const Pt: TsdVector);
    function Add(const Pt: TsdVector): PsdPoint;
  end;

{$EndRegion}

{$Region 'TsdEdge'}

  PsdEdge = ^TsdEdge;
  TsdEdge = record
    tag: Integer;
    auxA, auxB: Integer;
    a, b: TsdVector;
    constructor From(const a, b: TsdVector);
    function Length: Double;
    function EdgeCrosses(const ea, eb: TsdVector; cross: PsdVector = nil;
      points: PsdPoints = nil): Boolean;
  end;

{$EndRegion}

{$Region 'TsdEdges'}

  PsdPolygon = ^TsdPolygon;
  PsdContour = ^TsdContour;

  PsdEdges = ^TsdEdges;
  TsdEdges = record
  var
    List: TsdTaggedList<TsdEdge>;
  public
    procedure Init;
    procedure Clear;
    procedure Free;
    procedure AddEdge(const a, b: TsdVector;
      auxA: Integer = 0; auxB: Integer = 0; tag: Integer = 0);
    function AssemblePolygon(dest: PsdPolygon;
      errorAt: PsdEdge; keepDir: Boolean): Boolean;
    function AssembleContour(const first, last: TsdVector; dest: PsdContour;
      errorAt: PsdEdge; keepDir: Boolean; start: Integer): Boolean;
    function AnyEdgeCrossings(const a, b: TsdVector;
      cross: PsdVector = nil; points: PsdPoints = nil): Integer;
    function ContainsEdgeFrom(edges: PsdEdges): Boolean;
    function ContainsEdge(e: PsdEdge): Boolean;
    procedure CullExtraneousEdges(both: Boolean);
    procedure MergeCollinearSegments(const a, b: TsdVector);
  end;

{$EndRegion}

{$Region 'TsdContour'}

  TsdContour = record
  var
    tag: Integer;
    TimesEnclosed: Integer;
    XminPt: TsdVector;
    List: TsdTaggedList<TsdPoint>;
  public
    procedure Init;
    procedure Free;
    procedure AddPoint(const pt: TsdVector);
    procedure MakeEdgesInto(sl: PsdEdges);
    procedure Reverse;
    function ComputeNormal: TsdVector;
    function SignedAreaProjdToNormal(const n: TsdVector): Double;
    function IsClockwiseProjdToNormal(const n: TsdVector): Boolean;
    function ContainsPointProjdToNormal(const n, p: TsdVector): Boolean;
    procedure OffsetInto(var dest: TsdContour; r: Double);
    procedure CopyInto(var dest: TsdContour);
    procedure FindPointWithMinX;
    function AnyEdgeMidpoint: TsdVector;
  end;

{$EndRegion}

{$Region 'TsdPolygon'}

  TsdPolygon = record
  var
    ctx: TsdContext;
    List: TsdTaggedList<TsdContour>;
    Normal: TsdVector;
  public
    procedure Init(ctx: TsdContext);
    procedure Free;
    function IsEmpty: Boolean;
    function ComputeNormal: TsdVector;
    function AddEmptyContour: PsdContour;
    function ContainsPoint(const p: TsdVector): Boolean;
    function WindingNumberForPoint(const p: TsdVector): Integer;
    function SignedArea: Double;
    procedure InverseTransformInto(poly: PsdPolygon; const u, v, n: TsdVector);
    procedure MakeEdgesInto(edges: PsdEdges);
    procedure FixContourDirections;
    function SelfIntersecting(var intersectsAt: TsdVector): Boolean;
    function AnyPoint: TsdVector;
    procedure OffsetInto(dest: PsdPolygon; r: Double);
  end;

{$EndRegion}

{$Region 'TsdKdEdgesTree'}

  PsdEdgeLl = ^TsdEdgeLl;
  PsdKdNodeEdges = ^TsdKdNodeEdges;

  TsdKdEdgesTree = record
    redge, rnode: PSegmentedRegion;
    root: PsdKdNodeEdges;
    procedure Init(ctx: TsdContext; const List: TsdEdges);
    procedure Free;
    function AllocEdgeLl: PsdEdgeLl;
    function AllocNodeEdges: PsdKdNodeEdges;
  end;

  TsdEdgeLl = record
    se: PsdEdge;
    next: PsdEdgeLl;
  end;

  TsdKdNodeEdges = record
  private
    which: Integer;
    c: Double;
    gt, lt: PsdKdNodeEdges;
    edges: PsdEdgeLl;
    class function From(const tree: TsdKdEdgesTree;
      const edges: TsdEdges): PsdKdNodeEdges; overload; static;
    class function From(const tree: TsdKdEdgesTree;
      const ell: PsdEdgeLl): PsdKdNodeEdges; overload; static;
    function AnyEdgeCrossings(const a, b: TsdVector; cnt: Integer;
      pi: PsdVector = nil; points: PsdPoints = nil): Integer;
  end;

{$EndRegion}

implementation

uses
  Oz.Solid.Intersect;

{$Region 'TsvgIO'}

procedure TsvgIO.Init(const filename: string);
begin
  Self.filename := filename;
  svg := TsvgBuilder.Create(800, 600);
  log := TStringList.Create;
end;

procedure TsvgIO.Free;
begin
  FreeAndNil(svg);
  FreeAndNil(log);
end;

procedure TsvgIO.PrintAll;
begin
  svg.SaveToFile(filename + '.svg');
  log.SaveToFile(filename + '.txt');
end;

procedure TsvgIO.Dbp;
begin
  log.Add('');
end;

procedure TsvgIO.Dbp(const line: string);
begin
  log.Add(line);
end;

procedure TsvgIO.Dbp(const fs: string; const args: array of const);
begin
  log.Add(Format(fs, args));
end;

{$EndRegion}

{$Region 'TPolyBuilder'}

procedure TPolyBuilder.Build(const filename: string);
begin
  io.Init(filename);
  ReadPolygons(io.filename);
  OutputPolygons;
  ConvexIntersect(P, Q, n, m);
  ClosePostscript;
end;

procedure TPolyBuilder.Free;
begin
  io.Free;
end;

procedure TPolyBuilder.ReadPolygons(const filename: string);
var
  str: TStrings;
  i: Integer;

  procedure ReadPoly(var P: tPolygoni; var n: Integer);
  var
    line: string;
    j: Integer;
    sa: TArray<string>;
  begin
    n := 0;
    str.LoadFromFile(filename);
    line := str.Strings[i];
    Inc(i);
    n := Integer.Parse(line);
    io.Dbp('Polygon: %d', [n]);
    SetLength(P, n);
    for j := 0 to n - 1 do
    begin
      Assert(i < str.Count, 'eof - invalid file');
      line := str.Strings[i];
      Inc(i);
      sa := line.Split([Chr(9)]);
      Assert(Length(sa) = 2, 'there must be two numbers separated by tabs');
      if sa = nil then break;
      P[j].x := Integer.Parse(sa[0]);
      P[j].y := Integer.Parse(sa[1]);
      io.Dbp('  i   x   y');
      io.Dbp('%3d%4d%4d', [n, P[j].x, P[j].y]);
    end;
  end;

begin
  str := TStringList.Create;
  try
    i := 0;
    ReadPoly(P, n);
    ReadPoly(Q, m);
  finally
    str.Free;
  end;
end;

procedure TPolyBuilder.ClosePostscript;
begin
  //  Dbp('closepath stroke');
  //  Dbp('showpage\n%%%%EOF');
end;

procedure TPolyBuilder.PrintSharedSeg(p, q: tPointd);
begin
  //  Dbp('%%A int B:');
  //  Dbp('%8.2lf %8.2lf moveto', p.x, p.y );
  //  Dbp('%8.2lf %8.2lf lineto', q.x, q.y );
  //  ClosePostscript();
end;

function TPolyBuilder.Dot(a, b: T2i): Double;
begin
  Result := a.Dot(b);
end;

function TPolyBuilder.AreaSign(a, b, c: T2i): Integer;
var
  area2: double;
begin
  area2 := (b.x - a.x ) * double(c.y - a.y) -
           (c.x - a.x ) * double(b.y - a.y);
  // The area should be an integer.
  if area2 > 0.5 then
    Result := 1
  else if area2 < -0.5 then
    Result := -1
  else
    Result := 0;
end;

function TPolyBuilder.SegSegInt(a, b, c, d: T2i; p, q: tPointd): Char;
var
  s, t: double;       // The two parameters of the parametric eqns.
  num, denom: double; // Numerator and denoninator of equations.
  code: char;         // Return char characterizing intersection.
begin
  code := '?';
  // Dbp('%%SegSegInt: a,b,c,d: (%d,%d), (%d,%d), (%d,%d), (%d,%d)'
  // a.x,a.y, b.x,b.y, c.x,c.y, d.x,d.y);*/
  denom := a.x * double(d.y - c.y) +
           b.x * double(c.y - d.y) +
           d.x * double(b.y - a.y) +
           c.x * double(a.y - b.y);

   // If denom is zero, then segments are parallel: handle separately.
   if denom = 0.0 then
     Result := ParallelInt(a, b, c, d, p, q)
   else
   begin
     num := a.x * double(d.y - c.y) +
            c.x * double(a.y - d.y) +
            d.x * double(c.y - a.y);
     if (num = 0.0) or (num = denom) then
       code := 'v';
     s := num / denom;
     // Dbp('num=%lf, denom=%lf, s=%lf' num, denom, s);

     num := -(a.x * double(c.y - b.y) +
              b.x * double(a.y - c.y) +
              c.x * double(b.y - a.y) );
     if (num = 0.0) or (num = denom) then code := 'v';
     t := num / denom;
     // Dbp('num=%lf, denom=%lf, t=%lf' num, denom, t);

     if (0.0 < s) and (s < 1.0) and (0.0 < t) and (t < 1.0) then
       code := '1'
     else if (0.0 > s) or (s > 1.0) or (0.0 > t) or (t > 1.0) then
       code := '0';

     p.x := a.x + s * (b.x - a.x);
     p.y := a.y + s * (b.y - a.y);

     Result := code;
   end;
end;

function TPolyBuilder.ParallelInt(a, b, c, d: T2i; p, q: tPointd): Char;
begin
  // printf('ParallelInt: a,b,c,d: (%d,%d), (%d,%d), (%d,%d), (%d,%d)',
  // a.x,a.y, b.x,b.y, c.x,c.y, d.x,d.y);
  if not Collinear(a, b, c) then
    Result :=  '0'
  else if Between(a, b, c) and Between(a, b, d) then
  begin
    Assigndi(p, c);
    Assigndi(q, d);
    Result := 'e';
  end
  else if Between(c, d, a) and Between(c, d, b) then
  begin
    Assigndi(p, a);
    Assigndi(q, b);
    Result := 'e';
  end
  else if Between(a, b, c) and Between(c, d, b) then
  begin
    Assigndi(p, c);
    Assigndi(q, b);
    Result := 'e';
  end
  else if Between(a, b, c) and Between(c, d, a) then
  begin
    Assigndi(p, c);
    Assigndi(q, a);
    Result := 'e';
  end
  else if Between(a, b, d) and Between(c, d, b) then
  begin
    Assigndi(p, d);
    Assigndi(q, b);
    Result := 'e';
  end
  else if Between(a, b, d) and Between(c, d, a) then
  begin
    Assigndi(p, d);
    Assigndi(q, a);
    Result := 'e';
  end
  else
    Result := '0';
end;

function TPolyBuilder.Collinear(a, b, c: T2i): Boolean;
begin
  Result := AreaSign(a, b, c) = 0;
end;

function TPolyBuilder.Between(a, b, c: T2i): Boolean;
begin
  // If ab not vertical, check betweenness on x; else on y.
  if a.x <> b.x then
    Result := ((a.x <= c.x) and (c.x <= b.x)) or
              ((a.x >= c.x) and (c.x >= b.x))
  else
     Result := ((a.y <= c.y) and (c.y <= b.y)) or
               ((a.y >= c.y) and (c.y >= b.y));
end;

procedure TPolyBuilder.Assigndi(var p: tPointd; const a: T2i);
begin
  p.x := a.x;
  p.y := a.y;
end;

procedure TPolyBuilder.SubVec(const a, b:  T2i; var c: T2i);
begin
  c := a.Minus(b);
end;

function TPolyBuilder.ConvexIntersect(P, Q: tPolygoni; n, m: Integer): Integer;
var
  pi, qi: Integer;     // indices on P and Q (resp.)
  pi1, qo1: Integer;   // pi1, qi1 (resp.)
  pe, qe: T2i;         // directed edges on P and Q (resp.)
  Qp, Pp: TsvgPolygon;
  cross: Integer;      // sign of z-component of pi x qi
  bHA, aHB: Integer;   // qi in H(pi); pi in H(qi).
  Origin: T2i;
  pcpt: tPointd;       // Double point of intersection
  qcpt: tPointd;       // second point of intersection
  inflag: tInFlag;     // {Pin, Qin, Unknown}: which inside
  aa, ba: Integer;     // # advances on pi & qi indices (after 1st inter.)
  FirstPoint: Boolean; // Is this the first point? (used to initialize).
  p0: tPointd;         // The first point.
  code: Char;          // SegSegInt return code.
begin
  Origin.x := 0;
  Origin.y := 0;
  // Initialize variables.
  pi := 0; qi := 0; aa := 0; ba := 0;
  inflag := Unknown;
  FirstPoint := TRUE;

  Qp := TsvgPolygon.Create;
  Pp := TsvgPolygon.Create;
  repeat
    io.Dbp('Before Advances: a=%d, b=%d; aa=%d, ba=%d; inflag=%d',
      [pi, qi, aa, ba, Ord(inflag)]);
    // Computations of key variables.
    pi1 := (pi + n - 1) mod n;
    qo1 := (qi + m - 1) mod m;

    SubVec(P[pi], P[pi1], pe);
    SubVec(Q[qi], Q[qo1], qe);

    cross := AreaSign(Origin, pe, qe);
    aHB := AreaSign(Q[qo1], Q[qi], P[pi]);
    bHA := AreaSign(P[pi1], P[pi], Q[qi]);
    io.Dbp('cross=%d, aHB=%d, bHA=%d', [cross, aHB, bHA]);

    // If pe & qe intersect, update inflag.
    code := SegSegInt(P[pi1], P[pi], Q[qo1], Q[qi], pcpt, qcpt);
    io.Dbp('SegSegInt: code = %s', [code]);
    if (code = '1') or (code = 'v') then
    begin
      if (inflag = Unknown) and FirstPoint then
      begin
        aa := 0; ba := 0;
        FirstPoint := FALSE;
        p0.x := pcpt.x;
        p0.y := pcpt.y;
        io.Dbp('%8.2f %8.2f moveto', [p0.x, p0.y]);
      end;
      inflag := InOut(pcpt, inflag, aHB, bHA);
      io.Dbp('InOut sets inflag=%d', [Ord(inflag)]);
    end;

    // Advance rule

    // Special case: pe & qe overlap and oppositely oriented.
    if (code = 'e' ) and (Dot(pe, qe) < 0) then
    begin
      PrintSharedSeg( pcpt, qcpt);
      exit(EXIT_SUCCESS);
    end;

    // Special case: pe & qe parallel and separated.
    if (cross = 0) and (aHB < 0) and (bHA < 0) then
    begin
      io.Dbp('P and Q are disjoint.');
      exit(EXIT_SUCCESS);
    end
    // Special case: pe & qe collinear.
    else if (cross = 0) and ( aHB = 0) and (bHA = 0) then
    begin
      // Advance but do not output point.
      if inflag = Pin then
        qi := Advance(Qp, qi, ba, m, inflag = Qin, Q[qi])
      else
        pi := Advance(Pp, pi, aa, n, inflag = Pin, P[pi]);
    end
    // Generic cases.
    else if cross >= 0 then
    begin
      if bHA > 0 then
        pi := Advance(Pp, pi, aa, n, inflag = Pin, P[pi])
      else
        qi := Advance(Qp, qi, ba, m, inflag = Qin, Q[qi]);
    end
    else // if ( cross < 0 )
    begin
      if aHB > 0 then
        qi := Advance(Qp, qi, ba, m, inflag = Qin, Q[qi])
      else
        pi := Advance(Pp, pi, aa, n, inflag = Pin, P[pi]);
    end;
    io.Dbp('After advances:a=%d, b=%d; aa=%d, ba=%d; inflag=%d',
      [pi, qi, aa, ba, Ord(inflag)]);

    // Quit when both adv. indices have cycled, or one has cycled twice.
  until not (((aa < n) or (ba < m)) and (aa < 2 * n) and (ba < 2 * m));

  if not FirstPoint then
    // If at least one point output, close up.
    io.Dbp('%8.2f %8.2f lineto', [p0.x, p0.y]);

  // Deal with special cases: not implemented.
  if inflag = Unknown then
    io.Dbp('The boundaries of P and Q do not cross.');

  Result := EXIT_FAILURE;
end;

function TPolyBuilder.Advance(poly: TsvgPolygon; a: Integer; var aa: Integer;
  n: Integer; inside: Boolean; v: T2i): Integer;
begin
  if inside then
    poly.Point(v);
  Inc(aa);
  Result := (a + 1) mod n;
end;

function TPolyBuilder.InOut(p: tPointd; inflag: tInFlag; aHB, bHA: Integer): tInFlag;
begin
  io.Dbp('%8.2f %8.2f lineto', [p.x, p.y]);
  // Update inflag.
  if aHB > 0 then
    Result := Pin
  else if bHA > 0 then
    Result := Qin
  else
    // Keep status quo.
    Result := inflag;
end;

procedure TPolyBuilder.OutputPolygons;
var
  xmin, ymin, xmax, ymax: Integer;
  width, height: Integer;

  // Compute Bounding Box
  procedure BBox(const P: tPolygoni);
  var
    i: Integer;
  begin
    for i := 1 to High(P) do
    begin
      if P[i].x > xmax then
        xmax := P[i].x
      else if P[i].x < xmin then
        xmin := P[i].x;
      if P[i].y > ymax then
        ymax := P[i].y
      else if P[i].y < ymin then
        ymin := P[i].y;
    end;
  end;

  // Write polygon to svg
  procedure PolygonToSvg(const P: tPolygoni; const color: string);
  var
    i: Integer;
    g: TsvgPolygon;
  begin
    g := io.svg.Polygon;
    for i := 0 to High(P) do
      g.Point(P[i].x, P[i].y);
    g.Stroke(color).StrokeWidth(0.2);
  end;

begin
  // Compute Bounding Box
  xmin := P[0].x;
  xmax := P[0].x;
  ymin := P[0].y;
  ymax := P[0].y;
  BBox(P);
  BBox(Q);

  // ViewBox
  width := xmax - xmin + 1;
  height := xmax - xmin + 1;
  io.svg.ViewBox(xmin, ymin, width, height);

  PolygonToSvg(P, 'green');
  PolygonToSvg(Q, 'red');
end;

{$EndRegion}

{$Region 'TsdPoint'}

procedure TsdPoint.Init(const pt: TsdVector);
begin
  Self := Default(TsdPoint);
  p := pt;
end;

{$EndRegion}

{$Region 'TsdPoints'}

procedure TsdPoints.Init;
begin
  List.Init;
end;

procedure TsdPoints.Free;
begin
  List.Free;
end;

function TsdPoints.ContainsPoint(const Pt: TsdVector): Boolean;
begin
  Result := IndexForPoint(Pt) >= 0;
end;

function TsdPoints.IndexForPoint(const Pt: TsdVector): Integer;
var i: Integer;
begin
  for i := 0 to List.Count - 1 do
    if Pt.Equals(List.Items[i].P) then
      exit(i);
  Result := -1;
end;

procedure TsdPoints.IncrementTagFor(const Pt: TsdVector);
var
  i: Integer;
  p: PsdPoint;
begin
  for i := 0 to List.Count - 1 do
  begin
    p := List.Items[i];
    if Pt.Equals(p.p) then
    begin
      Inc(p.tag);
      exit;
    end;
  end;
  p := Add(Pt);
  p.tag := 1;
end;

function TsdPoints.Add(const Pt: TsdVector): PsdPoint;
var p: TsdPoint;
begin
  p.Init(Pt);
  Result := List.Items[List.Add(@p)];
end;

{$EndRegion}

{$Region 'TsdEdge'}

constructor TsdEdge.From(const a, b: TsdVector);
begin
  Self.a := a;
  Self.b := b;
  auxA := 0;
  auxB := 0;
  tag := 0;
end;

function TsdEdge.Length: Double;
begin
  Result := a.Minus(b).Magnitude;
end;

function TsdEdge.EdgeCrosses(const ea, eb: TsdVector; cross: PsdVector;
  points: PsdPoints): Boolean;
var
  eps, tthis_eps, m, t, tthis: Double;
  inters, skew, inOrEdge0, inOrEdge1: Boolean;
  d, dthis, pi: TsdVector;
begin
  d := eb.Minus(ea);
  eps := LengthEps / d.Magnitude;
  dthis := b.Minus(a);
  tthis_eps := LengthEps / dthis.Magnitude;
  if (ea.Equals(a) and eb.Equals(b)) or
     (eb.Equals(a) and ea.Equals(b)) then
  begin
    if cross <> nil then cross^ := a;
    if points <> nil then points.Add(a);
    exit(True);
  end;

  m := Sqrt(d.Magnitude * dthis.Magnitude);
  if Sqrt(Abs(d.Dot(dthis))) > (m - LengthEps) then
  begin
    if Abs(a.DistanceToLine(ea, d)) > LengthEps then
      exit(False);
    inters := False;
    t := a.Minus(ea).DivProjected(d);
    if (t > eps) and (t < (1 - eps)) then inters := True;
    t := b.Minus(ea).DivProjected(d);
    if (t > eps) and (t < (1 - eps)) then inters := True;
    t := ea.Minus(a).DivProjected(dthis);
    if (t > tthis_eps) and (t < (1 - tthis_eps)) then inters := True;
    t := eb.Minus(a).DivProjected(dthis);
    if (t > tthis_eps) and (t < (1 - tthis_eps)) then inters := True;
    if not inters then
      exit(False)
    else
    begin
      if cross <> nil then cross^ := A;
      if points <> nil then points.Add(A);
      exit(True);
    end;
  end;
  pi := AtIntersectionOfLines(ea, eb, a, b, @skew, @t, @tthis);
  if skew then exit(False);

  inOrEdge0 := (t > -eps) and (t < (1 + eps));
  inOrEdge1 := (tthis > -tthis_eps) and (tthis < (1 + tthis_eps));
  if inOrEdge0 and inOrEdge1 then
  begin
    if a.Equals(ea) or b.Equals(ea) or a.Equals(eb) or b.Equals(eb) then
      exit(False);
    if cross <> nil then cross^ := pi;
    if points <> nil then points.Add(pi);
    exit(True);
  end;
  Result := False;
end;

{$EndRegion}

{$Region 'TsdEdges'}

procedure TsdEdges.Init;
begin
  List.Init;
end;

procedure TsdEdges.Clear;
begin
  List.Clear;
end;

procedure TsdEdges.Free;
begin
  List.Free;
end;

var LineStart, LineDirection: TsdVector;

function ByAlongLineEdge(av, bv: Pointer): Integer;
var
  a, b: PsdEdge;
  ta, tb: Double;
begin
  a := PsdEdge(av);
  b := PsdEdge(bv);
  ta := (a.a.Minus(LineStart)).DivProjected(LineDirection);
  tb := (b.a.Minus(LineStart)).DivProjected(LineDirection);
  Result := CompareValue(ta, tb);
end;

procedure TsdEdges.AddEdge(const a, b: TsdVector; auxA, auxB, tag: Integer);
var
  e: TsdEdge;
begin
  e := TsdEdge.From(a, b);
  e.auxA := auxA;
  e.auxB := auxB;
  e.tag := tag;
  List.Add(@e);
end;

function TsdEdges.AssemblePolygon(dest: PsdPolygon;
  errorAt: PsdEdge; keepDir: Boolean): Boolean;
var
  allClosed: Boolean;
  i: Integer;
  e: PsdEdge;
  sc: PsdContour;
begin
  dest.List.Clear;
  allClosed := True;
  for i := 0 to List.Count - 1 do
  begin
    e := List.Items[i];
    if e.tag = 0  then
    begin
      e.tag := 1;
      sc := dest.AddEmptyContour;
      if not AssembleContour(e.a, e.b, sc, errorAt, keepDir, i + 1) then
        allClosed := False;
    end;
  end;
  Result := allClosed;
end;

function TsdEdges.AnyEdgeCrossings(const a, b: TsdVector;
  cross: PsdVector; points: PsdPoints): Integer;
var
  i: Integer;
  e: PsdEdge;
begin
  Result := 0;
  for i := 0 to List.Count - 1 do
  begin
    e := List.Items[i];
    if e.EdgeCrosses(a, b, cross, points) then
      Inc(Result);
  end;
end;

function TsdEdges.AssembleContour(const first, last: TsdVector;
  dest: PsdContour; errorAt: PsdEdge; keepDir: Boolean; start: Integer): Boolean;
var
  i: Integer;
  e: PsdEdge;
  lastPoint: TsdVector;
begin
  dest.AddPoint(first);
  dest.AddPoint(last);
  lastPoint := last;
  repeat
    i := start;
    while i < List.Count do
    begin
      e := List.Items[i];
      if e.tag = 0 then
      begin
        if e.a.Equals(lastPoint) then
        begin
          dest.AddPoint(e.b);
          lastPoint := e.b;
          e.tag := 1;
          break;
        end;
        if not keepDir and e.b.Equals(lastPoint) then
        begin
          dest.AddPoint(e.a);
          lastPoint := e.a;
          e.tag := 1;
          break;
        end;
      end;
      Inc(i);
    end;
    if i >= List.Count then
    begin
      if errorAt <> nil then
      begin
        errorAt.a := first;
        errorAt.b := last;
      end;
      exit(False);
    end;
  until lastPoint.Equals(first);
  Result := True;
end;

function TsdEdges.ContainsEdgeFrom(edges: PsdEdges): Boolean;
var
  i: Integer;
  e: PsdEdge;
begin
  for i := 0 to List.Count - 1 do
  begin
    e := List.Items[i];
    if edges.ContainsEdge(e) then exit(True);
  end;
  Result := False;
end;

function TsdEdges.ContainsEdge(e: PsdEdge): Boolean;
var
  i: Integer;
  t: PsdEdge;
begin
  for i := 0 to List.Count - 1 do
  begin
    t := List.Items[i];
    if t.a.Equals(e.a) and t.b.Equals(e.b) then exit(True);
    if t.b.Equals(e.a) and t.a.Equals(e.b) then exit(True);
  end;
  Result := False;
end;

procedure TsdEdges.CullExtraneousEdges(both: Boolean);
var
  i, j: Integer;
  e, t: PsdEdge;
begin
  List.ClearTags;
  for i := 0 to List.Count - 1 do
  begin
    e := List.Items[i];
    for j := i + 1 to List.Count - 1 do
    begin
      t := List.Items[j];
      if t.a.Equals(e.a) and t.b.Equals(e.b) then
        t.tag := 1;
      if t.a.Equals(e.b) and t.b.Equals(e.a) then
      begin
        if both then
          e.tag := 1;
        t.tag := 1;
      end;
    end;
  end;
  List.RemoveTagged;
end;

procedure TsdEdges.MergeCollinearSegments(const a, b: TsdVector);
var
  i: Integer;
  prev, now: PsdEdge;
begin
  LineStart := a;
  LineDirection := b.Minus(a);
  List.Sort(ByAlongLineEdge);
  List.ClearTags;
  for i := 1 to List.Count - 1 do
  begin
    prev := List.Items[i - 1];
    now := List.Items[i];
    if prev.b.Equals(now.a) and (prev.auxA = now.auxA) then
    begin
      prev.tag := 1;
      now.a := prev.a;
    end;
  end;
  List.RemoveTagged;
end;

{$EndRegion}

{$Region 'TsdPolygon'}

procedure TsdPolygon.Init(ctx: TsdContext);
begin
  Self.ctx := ctx;
  List.Init;
  Normal.SetZero;
end;

procedure TsdPolygon.Free;
begin
  List.Free;
end;

function TsdPolygon.IsEmpty: Boolean;
begin
  Result := List.Count = 0;
end;

function TsdPolygon.ComputeNormal: TsdVector;
begin
  if List.Count < 1 then
    Result.SetZero
  else
    Result := List.Items[0].ComputeNormal;
end;

function TsdPolygon.AddEmptyContour: PsdContour;
var c: TsdContour;
begin
  c.Init;
  Result := List.Items[List.Add(@c)];
end;

function TsdPolygon.ContainsPoint(const p: TsdVector): Boolean;
begin
  Result := WindingNumberForPoint(p) mod 2 = 1;
end;

function TsdPolygon.WindingNumberForPoint(const p: TsdVector): Integer;
var
  i: Integer;
  sc: PsdContour;
begin
  Result := 0;
  for i := 0 to List.Count - 1 do
  begin
    sc := List.Items[i];
    if sc.ContainsPointProjdToNormal(normal, p) then
      Inc(Result);
  end;
end;

function TsdPolygon.SignedArea: Double;
var
  i: Integer;
  sc: PsdContour;
begin
  Result := 0;
  Normal := ComputeNormal;
  for i := 0 to List.Count - 1 do
  begin
    sc := List.Items[i];
    Result := Result + sc.SignedAreaProjdToNormal(Normal);
  end;
end;

procedure TsdPolygon.InverseTransformInto(poly: PsdPolygon;
  const u, v, n: TsdVector);
var
  i, j: Integer;
  tsc: TsdContour;
  c: PsdContour;
  pt: PsdPoint;
begin
  for i := 0 to List.Count - 1 do
  begin
    c := List.Items[i];
    tsc.Init;
    tsc.timesEnclosed := c.timesEnclosed;
    for j := 0 to c.List.Count - 1 do
    begin
      pt := c.List.Items[j];
      tsc.AddPoint(pt.p.DotInToCsys(u, v, n));
    end;
    poly.List.Add(@tsc);
  end;
end;

procedure TsdPolygon.MakeEdgesInto(edges: PsdEdges);
var
  i: Integer;
begin
  for i := 0 to List.Count - 1 do
    List.Items[i].MakeEdgesInto(edges);
end;

procedure TsdPolygon.FixContourDirections;
var
  i, j: Integer;
  sc, sct: PsdContour;
  pt: TsdVector;
  outer, clockwise: Boolean;
begin
  List.ClearTags;
  for i := 0 to List.Count - 1 do
  begin
    sc := List.Items[i];
    if sc.List.Count < 2 then continue;
    pt := sc.List.Items[0].p.Plus(sc.List.Items[1].p).ScaledBy(0.5);
    sc.timesEnclosed := 0;
    outer := True;
    for j := 0 to List.Count - 1 do
    begin
      if i = j then continue;
      sct := List.Items[j];
      if sct.ContainsPointProjdToNormal(normal, pt) then
      begin
        outer := not outer;
        Inc(sc.timesEnclosed);
      end;
    end;

    clockwise := sc.IsClockwiseProjdToNormal(normal);
    if (clockwise and outer) or (not clockwise and not outer) then
    begin
      sc.Reverse;
      sc.tag := 1;
    end;
  end;
end;

function TsdPolygon.SelfIntersecting(var intersectsAt: TsdVector): Boolean;
var
  el: TsdEdges;
  i, cnt, inters: Integer;
  kdtree: TsdKdEdgesTree;
  se: PsdEdge;
begin
  Result := False;
  el.Init;
  try
    MakeEdgesInto(@el);
    kdtree.Init(ctx, el);
    try
      cnt := 1;
      el.List.ClearTags;
      for i := 0 to el.List.Count - 1 do
      begin
        se := el.List.Items[i];
        inters := kdtree.Root.AnyEdgeCrossings(se.a, se.b, cnt, @intersectsAt);
        if inters <> 1 then
        begin
          Result := True;
          break;
        end;
        Inc(cnt);
      end;
    finally
      kdtree.Free;
    end
  finally
    el.Free;
  end
end;

function TsdPolygon.AnyPoint: TsdVector;
begin
  Result := List.Items[0].List.Items[0].p;
end;

procedure TsdPolygon.OffsetInto(dest: PsdPolygon; r: Double);
var
  i: Integer;
  sc, sct: PsdContour;
begin
  dest.List.Clear;
  for i := 0 to List.Count - 1 do
  begin
    sc := List.Items[i];
    dest.AddEmptyContour;
    sct := dest.List.Items[dest.List.Count - 1];
    sc.OffsetInto(sct^, r);
  end;
end;

{$EndRegion}

{$Region 'TsdContour'}

procedure TsdContour.Init;
begin
  tag := 0;
  TimesEnclosed := 0;
  XminPt.SetZero;
  List.Init;
end;

procedure TsdContour.Free;
begin
  List.Free;
end;

procedure TsdContour.AddPoint(const pt: TsdVector);
var
  p: TsdPoint;
begin
  p.Init(pt);
  List.Add(@p);
end;

procedure TsdContour.MakeEdgesInto(sl: PsdEdges);
var
  i: Integer;
begin
  for i := 0 to List.Count - 2 do
    sl.AddEdge(List.Items[i].p, List.Items[i + 1].p);
end;

procedure TsdContour.Reverse;
begin
  List.Reverse;
end;

function TsdContour.ComputeNormal: TsdVector;
var
  i: Integer;
  n, u, v, nt: TsdVector;
begin
  n.SetZero;
  for i := 0 to List.Count - 3 do
  begin
    u := (List.Items[i + 1].p).Minus(List.Items[i + 0].p).WithMagnitude(1);
    v := (List.Items[i + 2].p).Minus(List.Items[i + 1].p).WithMagnitude(1);
    nt := u.Cross(v);
    if nt.Magnitude > n.Magnitude then
      n := nt;
  end;
  Result := n.WithMagnitude(1);
end;

function TsdContour.SignedAreaProjdToNormal(const n: TsdVector): Double;
var
  i: Integer;
  u, v: TsdVector;
  p: PsdVector;
  area, u0, v0, u1, v1: Double;
begin
  u := n.Normal(0);
  v := n.Normal(1);
  area := 0;
  for i := 0 to List.Count - 2 do
  begin
    p := @List.Items[i].p;
    u0 := p.Dot(u);
    v0 := p.Dot(v);
    p := @List.Items[i + 1].p;
    u1 := p.Dot(u);
    v1 := p.Dot(v);
    area := area + 0.5 * (v0 + v1) * (u1 - u0);
  end;
  Result := area;
end;

function TsdContour.IsClockwiseProjdToNormal(const n: TsdVector): Boolean;
begin
  Result := (n.Magnitude < 0.01) or (SignedAreaProjdToNormal(n) < 0);
end;

function TsdContour.ContainsPointProjdToNormal(const n, p: TsdVector): Boolean;
var
  u, v: TsdVector;
  up, vp, ua, va, ub, vb: Double;
  inside: Boolean;
  i, j: Integer;
begin
  u := n.Normal(0);
  v := n.Normal(1);
  up := p.Dot(u);
  vp := p.Dot(v);
  inside := False;
  for i := 0 to List.Count - 2 do
  begin
    ua := List.Items[i].p.Dot(u);
    va := List.Items[i].p.Dot(v);
    j := (i + 1) mod (List.Count - 1);
    ub := List.Items[j].p.Dot(u);
    vb := List.Items[j].p.Dot(v);
    if (((va <= vp) and (vp < vb)) or
        ((vb <= vp) and (vp < va))) and
         (up < (ub - ua) * (vp - va) / (vb - va) + ua) then
      inside := not inside;
  end;
  Result := inside;
end;

procedure TsdContour.OffsetInto(var dest: TsdContour; r: Double);
var
  i, n: Integer;
  a, b, c, dp, dn, p, pp, pn, tmp: TsdVector;
  thetan, thetap, theta: Double;
  px0, py0, pdx, pdy: Double;
  nx0, ny0, ndx, ndy, x, y: Double;
begin
  n := List.Count - 1;
  for i := 0 to n do
  begin
    a := List.Items[Wrap(i - 1, n)].p;
    b := List.Items[Wrap(i, n)].p;
    c := List.Items[Wrap(i + 1, n)].p;
    dp := a.Minus(b);
    thetap := ArcTan2(dp.y, dp.x);
    dn := b.Minus(c);
    thetan := ArcTan2(dn.y, dn.x);
    if (dp.Magnitude < LengthEps) or (dn.Magnitude < LengthEps) then
      continue;
    if (thetan > thetap) and (thetan - thetap > Pi) then
      thetap := thetap + 2 * Pi;
    if (thetan < thetap) and (thetap - thetan > Pi) then
      thetan := thetan + 2 * Pi;
    if (Abs(thetan - thetap) < (1 * Pi) / 180) then
    begin
      p.Setup(b.x - r * Sin(thetap), b.y + r * Cos(thetap), 0);
      dest.AddPoint(p);
    end
    else if thetan < thetap then
    begin
      x := 0;
      y := 0;
      px0 := b.x - r * Sin(thetap);
      py0 := b.y + r * Cos(thetap);
      pdx := Cos(thetap);
      pdy := Sin(thetap);
      nx0 := b.x - r * Sin(thetan);
      ny0 := b.y + r * Cos(thetan);
      ndx := Cos(thetan);
      ndy := Sin(thetan);
      IntersectionOfLines(
        px0, py0, pdx, pdy,
        nx0, ny0, ndx, ndy,
        x, y);
      tmp := TsdVector.From(x, y, 0);
      dest.AddPoint(tmp);
    end
    else if (Abs(thetap - thetan) < (6 * Pi) / 180) then
    begin
      pp.Setup(b.x - r * Sin(thetap), b.y + r * Cos(thetap), 0);
      dest.AddPoint(pp);
      pn.Setup(b.x - r * Sin(thetan), b.y + r * Cos(thetan), 0);
      dest.AddPoint(pn);
    end
    else
    begin
      theta := thetap;
      while theta <= thetan do
      begin
        p.Setup(b.x - r * Sin(theta), b.y + r * Cos(theta), 0);
        dest.AddPoint(p);
        theta := theta + (6 * Pi) / 180;
      end;
    end;
  end;
end;

procedure TsdContour.CopyInto(var dest: TsdContour);
var
  i: Integer;
begin
  for i := 0 to List.Count - 2 do
    dest.AddPoint(List.Items[i].p);
end;

procedure TsdContour.FindPointWithMinX;
var
  i: Integer;
  p: TsdVector;
begin
  xminPt.Setup(1E10, 1e10, 1e10);
  for i := 0 to List.Count - 1 do
  begin
    p := List.Items[i].p;
    if p.x < xminPt.x then
      xminPt := p;
  end;
end;

function TsdContour.AnyEdgeMidpoint: TsdVector;
begin
  if List.Count < 2 then
    raise ESolidError.Create(
      'TsdContour.AnyEdgeMidpoint: To find the midpoint you need two points');
  Result := (List.Items[0].p.Plus(List.Items[1].p)).ScaledBy(0.5);
end;

{$EndRegion}

{$Region 'TsdKdEdgesTree'}

procedure TsdKdEdgesTree.Init(ctx: TsdContext; const List: TsdEdges);
begin
  redge := ctx.Heap.CreateRegion(SysCtx.CreateMeta<TsdEdgeLl>);
  rnode := ctx.Heap.CreateRegion(SysCtx.CreateMeta<TsdKdNodeEdges>);
  root := TsdKdNodeEdges.From(Self, List);
end;

procedure TsdKdEdgesTree.Free;
begin
  redge.Free;
  rnode.Free;
  root := nil;
end;

function TsdKdEdgesTree.AllocEdgeLl: PsdEdgeLl;
begin
  Result := redge.AddItem;
end;

function TsdKdEdgesTree.AllocNodeEdges: PsdKdNodeEdges;
begin
  Result := rnode.AddItem;
end;

{$EndRegion}

{$Region 'TsdKdNodeEdges'}

class function TsdKdNodeEdges.From(const tree: TsdKdEdgesTree;
  const edges: TsdEdges): PsdKdNodeEdges;
var
  i: Integer;
  ell, n: PsdEdgeLl;
  e: PsdEdge;
begin
  ell := nil;
  for i := 0 to edges.List.Count - 1 do
  begin
    e := edges.List.Items[i];
    n := tree.AllocEdgeLl;
    n.se := e;
    n.next := ell;
    ell := n;
  end;
  Result := From(tree, ell);
end;

class function TsdKdNodeEdges.From(const tree: TsdKdEdgesTree;
  const ell: PsdEdgeLl): PsdKdNodeEdges;
var
  ptAve: TsdVector;
  n: PsdKdNodeEdges;
  flip, gtl, ltl, elln: PsdEdgeLl;
  i, totaln: Integer;
  ltln, gtln: array [0..2] of Integer;
  badness: array [0..2] of Double;
begin
  n := tree.AllocNodeEdges;
  ptAve.SetZero;
  totaln := 0;
  flip := ell;
  while flip <> nil do
  begin
    ptAve := ptAve.Plus(flip.se.a);
    ptAve := ptAve.Plus(flip.se.b);
    Inc(totaln);
    flip := flip.next;
  end;
  ptAve := ptAve.ScaledBy(1 / (2 * totaln));
  for i := 0 to 2 do
  begin
    ltln[i] := 0;
    gtln[i] := 0;
  end;
  flip := ell;
  while flip <> nil do
  begin
    for i := 0 to 2 do
    begin
      if (flip.se.a.Element[i] < ptAve.Element[i] + KdTreeEps) or
         (flip.se.b.Element[i] < ptAve.Element[i] + KdTreeEps) then
        Inc(ltln[i]);
      if (flip.se.a.Element[i] > ptAve.Element[i] - KdTreeEps) or
         (flip.se.b.Element[i] > ptAve.Element[i] - KdTreeEps) then
        Inc(gtln[i]);
    end;
    flip := flip.next;
  end;
  for i := 0 to 2 do
    badness[i] := Power(ltln[i], 4) + Power(gtln[i], 4);

  if (badness[0] < badness[1]) and (badness[0] < badness[2]) then
    n.which := 0
  else if badness[1] < badness[2] then
    n.which := 1
  else
    n.which := 2;
  n.c := ptAve.Element[n.which];
  if (totaln < 3) or (totaln = gtln[n.which]) or (totaln = ltln[n.which]) then
  begin
    n.edges := ell;
    exit(n);
  end;
  gtl := nil;
  ltl := nil;
  flip := ell;
  while flip <> nil do
  begin
    if (flip.se.a.Element[n.which] < n.c + KdTreeEps) or
       (flip.se.b.Element[n.which] < n.c + KdTreeEps) then
    begin
      elln := tree.AllocEdgeLl;
      elln.se := flip.se;
      elln.next := ltl;
      ltl := elln;
    end;
    if (flip.se.a.Element[n.which] > n.c - KdTreeEps) or
       (flip.se.b.Element[n.which] > n.c - KdTreeEps) then
    begin
      elln := tree.AllocEdgeLl;
      elln.se := flip.se;
      elln.next := gtl;
      gtl := elln;
    end;
    flip := flip.next;
  end;
  n.lt := TsdKdNodeEdges.From(tree, ltl);
  n.gt := TsdKdNodeEdges.From(tree, gtl);
  Result := n;
end;

function TsdKdNodeEdges.AnyEdgeCrossings(const a, b: TsdVector;
  cnt: Integer; pi: PsdVector; points: PsdPoints): Integer;
var
  inters: Integer;
  sell: PsdEdgeLl;
  se: PsdEdge;
begin
  inters := 0;
  if (gt <> nil) and (lt <> nil) then
  begin
    if (a.Element[which] < c + KdTreeEps) or
       (b.Element[which] < c + KdTreeEps) then
      inters := inters + lt.AnyEdgeCrossings(a, b, cnt, pi, points);
    if (a.Element[which] > c - KdTreeEps) or
       (b.Element[which] > c - KdTreeEps) then
      inters := inters + gt.AnyEdgeCrossings(a, b, cnt, pi, points);
  end
  else
  begin
    sell := edges;
    while sell <> nil do
    begin
      se := sell.se;
      if se.tag <> cnt then
      begin
        if se.EdgeCrosses(a, b, pi, points) then
          Inc(inters);
        se.tag := cnt;
      end;
      sell := sell.next
    end;
  end;
  Result := inters;
end;

{$EndRegion}

end.

