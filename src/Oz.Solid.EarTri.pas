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
unit Oz.Solid.EarTri;

interface

{$Region 'Uses'}

uses
  System.Classes, System.SysUtils, Oz.Solid.VectorInt, Oz.Solid.Svg;

{$EndRegion}

{$T+}

{$Region 'TsvgBuilder'}

type
  tVertex = ^tsVertex;
  tsVertex = record
    vnum: Integer; // Index
    v: t2i;        // Coordinates
    ear: Boolean;
    next, prev: tVertex;
  end;

{$EndRegion}

{$Region 'TsvgIO'}

  TsvgIO = record
  strict private
    filename: string;
    svg: TsvgBuilder;
    log: TStrings;
    xmin, ymin, xmax, ymax: Integer;
    // Compute bounding box for Encapsulated SVG.
    function CalcBounds(vertices: tVertex): Integer;
    // Uses the vnum indices corresponding to the order
    // in which the vertices were input.
    procedure AddVertices(vertices: tVertex);
    // Add vertices to log
    procedure AddVerticesToLog(vertices: tVertex; nvertices: Integer);
  public
    procedure Init(const filename: string);
    procedure Free;
    procedure AddPolygon(vertices: tVertex);
    // Prints svg and log
    procedure PrintAll;
    // Add edge to svg
    procedure AddEdge(a, b: tVertex);
    // Prints out the vertices
    procedure PrintPoly(vertices: tVertex);
    // Debug print
    procedure Dbp; overload;
    procedure Dbp(const line: string); overload;
    procedure Dbp(const fs: string; const args: array of const); overload;
  end;

{$EndRegion}

{$Region 'T2iFn'}

  T2iFn = record
    // Returns twice the signed area of the triangle determined by a, b, c.
    // The area is positive if a, b, c are oriented ccw, negative if cw,
    // and zero if the points are collinear.
    class function Area2(const a, b, c: t2i): Integer; static;
    // Sign of area
    class function AreaSign(a, b, c: t2i): Integer; static;
    // Returns True iff c is strictly to the left of the directed line
    // through a to b.
    class function Left(const a, b, c: t2i): Boolean; static;
    // Returns True iff c is to the left or on of the directed line
    // through a to b.
    class function LeftOn(const a, b, c: t2i): Boolean; static;
    // Returns True iff a, b, c lie on a straight line
    class function Collinear(const a, b, c: t2i): Boolean; static;
    // Returns True iff ab properly intersects cd: they share
    // a point interior to both segments. The properness of the
    // intersection is ensured by using strict leftness.
    class function IntersectProp(const a, b, c, d: t2i): Boolean; static;
    // Returns True iff point c lies on the closed segement ab.
    // First checks that c is collinear with a and b.
    class function Between(const a, b, c: t2i): Boolean; static;
    // Returns True iff segments ab and cd intersect, properly or improperly.
    class function Intersect(const a, b, c, d: t2i): Boolean; static;
  end;

{$EndRegion}

{$Region 'TEarTri'}

  TEarTri = record
  private
    io: TsvgIO;
    vertices: tVertex;  // 'Head' of circular list.
    nvertices: Integer; // Total number of polygon vertices.
    // Returns True iff (a, b) is a proper internal diagonal.
    function Diagonal(a, b: tVertex): Boolean;
    // Returns True iff the diagonal (a, b) is strictly internal to the
    // polygon in the neighborhood of the a endpoint.
    function InCone(a, b: tVertex): Boolean;
    // Returns True iff (a, b) is a proper internal or external
    // diagonal of P, ignoring edges incident to a and b.
    function Diagonalie(a, b: tVertex): Boolean;
    // This function initializes the data structures, and calls
    // Triangulate2 to clip off the ears one by one.
    procedure EarInit;
    // Reads in the vertices, and links them into a circular
    // list with MakeNullVertex. There is no need for the # of vertices
    // to be the first line: the function looks for EOF instead.
    function ReadVertices(const filename: string): Integer;
    // MakeNullVertex: Makes a vertex.
    function MakeNullVertex: tVertex;
    procedure Add(var head: tVertex; p: tVertex);
    procedure Init(const filename: string);
  public
    procedure Build(const filename: string);
    procedure Free;
    // Prints out n-3 diagonals (as pairs of integer indices)
    // which form a triangulation of P.
    procedure Triangulate;
    // Area of polygon
    function AreaPoly2: Integer;
  end;

{$EndRegion}

implementation

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

procedure TsvgIO.AddEdge(a, b: tVertex);
begin
  log.Add(Format('Diagonal: (%d, %d)', [a.vnum, b.vnum]));
  svg.Line(a.v.x, a.v.y, b.v.x, b.v.y).Stroke('green').StrokeWidth(0.2);
end;

procedure TsvgIO.AddPolygon(vertices: tVertex);
var
  nvertices: Integer;
begin
  nvertices := CalcBounds(vertices);
  svg.ViewBox(xmin, ymin, xmax, ymax);
  AddVertices(vertices);
  AddVerticesToLog(vertices, nvertices);
end;

procedure TsvgIO.PrintAll;
begin
  svg.SaveToFile(filename + '.svg');
  log.SaveToFile(filename + '.txt');
end;

function TsvgIO.CalcBounds(vertices: tVertex): Integer;
var
  v: tVertex;
begin
  Result := 0;
  v := vertices;
  xmin := v.v.x; xmax := v.v.x;
  ymin := v.v.y; ymax := v.v.y;
  repeat
    if v.v.x > xmax then
      xmax := v.v.x
    else if v.v.x < xmin then
      xmin := v.v.x;
    if v.v.y > ymax then
      ymax := v.v.y
    else if v.v.y < ymin then
      ymin := v.v.y;
    v := v.next;
    Inc(Result);
  until v = vertices;
end;

procedure TsvgIO.AddVertices(vertices: tVertex);
var
  polygon: TsvgPolygon;
  v: tVertex;
begin
  // add vertices
  polygon := svg.Polygon;
  v := vertices;
  repeat
    polygon.Point(v.v);
    v := v.next;
  until v = vertices;
  polygon.Fill('none').Stroke('black').StrokeWidth(0.2);
end;

procedure TsvgIO.AddVerticesToLog(vertices: tVertex; nvertices: Integer);
var
  v: tVertex;
begin
  // Output vertex info as a .
  log.Add(Format('BoundingBox: %d %d %d %d', [xmin, ymin, xmax, ymax]));
  log.Add(Format(' number of vertices = %d', [nvertices]));
  v := vertices;
  repeat
    log.Add(Format(' vnum=%5d'#9'x=%5d'#9'y=%5d', [v.vnum, v.v.y, v.v.x]));
    v := v.next;
  until v = vertices;
end;

procedure TsvgIO.PrintPoly(vertices: tVertex);
var
  v: tVertex;
begin
  Dbp('Polygon circular list:');
  v := vertices;
  repeat
    Dbp('vnum=%d v=(%d, %d) ear=%d', [v.vnum, v.v.x, v.v.y, Ord(v.ear)]);
    v := v.next;
  until v = vertices;
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

{$Region 'T2iFn'}

class function T2iFn.Area2(const a, b, c: t2i): Integer;
begin
  Result := (b.x - a.x) * (c.y - a.y) - (c.x - a.x) * (b.y - a.y);
end;

class function T2iFn.AreaSign(a, b, c: t2i): Integer;
var
  area2: Double;
begin
  area2 := (b.x - a.x) * Double(c.y - a.y) -
           (c.x - a.x) * Double(b.y - a.y);
  // The area should be an integer.
  if area2 > 0.5 then
    Result := 1
  else if area2 < -0.5 then
    Result := -1
  else
    Result := 0;
end;

class function T2iFn.Left(const a, b, c: t2i): Boolean;
begin
  Result := AreaSign(a, b, c) > 0;
end;

class function T2iFn.LeftOn(const a, b, c: t2i): Boolean;
begin
  Result := AreaSign(a, b, c) >= 0;
end;

class function T2iFn.Collinear(const a, b, c: t2i): Boolean;
begin
  Result := AreaSign(a, b, c) = 0;
end;

class function T2iFn.IntersectProp(const a, b, c, d: t2i): Boolean;
begin
  // Eliminate improper cases.
  if (Collinear(a, b, c) or Collinear(a, b, d) or
      Collinear(c, d, a) or Collinear(c, d, b)) then
    Result := False
  else
    Result := (Left(a, b, c) xor Left(a, b, d)) and
              (Left(c, d, a) xor Left(c, d, b));
end;

class function T2iFn.Between(const a, b, c: t2i): Boolean;
begin
   if not Collinear(a, b, c) then
     exit(False);
   // If ab not vertical, check betweenness on x; else on y.
   if a.x <> b.x then
     Result := ((a.x <= c.x) and (c.x <= b.x)) or
               ((a.x >= c.x) and (c.x >= b.x))
   else
     Result := ((a.y <= c.y) and (c.y <= b.y)) or
               ((a.y >= c.y) and (c.y >= b.y));
end;

class function T2iFn.Intersect(const a, b, c, d: t2i): Boolean;
begin
   if IntersectProp(a, b, c, d) then
     Result := True
   else if Between(a, b, c) or Between(a, b, d) or Between(c, d, a)
        or Between(c, d, b) then
     Result := True
   else
     Result := False;
end;

{$EndRegion}

{$Region 'TEarTri'}

procedure TEarTri.Build(const filename: string);
begin
  Init(filename);
  io.AddPolygon(vertices);
  Triangulate;
  io.PrintAll;
  io.Dbp('Area of polygon = %g', [0.5 * AreaPoly2]);
  io.Dbp;
end;

procedure TEarTri.Init(const filename: string);
begin
  io.Init(filename);
  vertices := nil;
  nvertices := ReadVertices(filename);
end;

procedure TEarTri.Free;
begin
  io.Free;
end;

function TEarTri.Diagonalie(a, b: tVertex): Boolean;
var
  c, c1: tVertex;
begin
  // For each edge (c, c1) of P
  c := vertices;
  repeat
    c1 := c.next;
    // Skip edges incident to a or b
    if (c <> a) and (c1 <> a) and
       (c <> b) and (c1 <> b) and
       T2iFn.Intersect(a.v, b.v, c.v, c1.v) then
      exit(False);
    c := c.next;
   until c = vertices;
   Result := True;
end;

procedure TEarTri.EarInit;
var
  v0, v1, v2: tVertex;   // three consecutive vertices
begin
  // Initialize v1.ear for all vertices.
  v1 := vertices;
  io.Dbp('newpath');
  repeat
    v2 := v1.next;
    v0 := v1.prev;
    v1.ear := Diagonal(v0, v2);
    v1 := v1.next;
  until v1 = vertices;
  io.Dbp('closepath stroke');
end;

procedure TEarTri.Triangulate;
var
  n: Integer; // number of vertices; shrinks to 3.
  v0, v1, v2, v3, v4: tVertex; // five consecutive vertices
  earfound: Boolean; // for debugging and error detection only.
begin
  n := nvertices;
  EarInit;
  io.Dbp('newpath');
  // Each step of outer loop removes one ear.
  while n > 3 do
  begin
    // Inner loop searches for an ear.
    v2 := vertices;
    earfound := False;
    repeat
      if v2.ear then
      begin
        earfound := True;
        // Ear found. Fill variables.
        v3 := v2.next; v4 := v3.next;
        v1 := v2.prev; v0 := v1.prev;
        // (v1,v3) is a diagonal
        io.AddEdge(v1, v3);
        // Update earity of diagonal endpoints
        v1.ear := Diagonal(v0, v3);
        v3.ear := Diagonal(v1, v4);
        // Cut off the ear v2
        v1.next := v3;
        v3.prev := v1;
        vertices := v3;  // In case the head was v2.
        Dec(n);
        break;   // out of inner loop; resume outer loop
      end; // end if ear found
      v2 := v2.next;
    until v2 = vertices;
    if not earfound then
    begin
      io.PrintPoly(vertices);
      raise Exception.Create('Error in Triangulate: No ear found.');
    end;
  end;
end;

function TEarTri.InCone(a, b: tVertex): Boolean;
var
  a0, a1: tVertex ;  // a0, a, a1 are consecutive vertices.
begin
  a1 := a.next;
  a0 := a.prev;
  // If a is a convex vertex ...
  if T2iFn.LeftOn(a.v, a1.v, a0.v) then
    Result := T2iFn.Left(a.v, b.v, a0.v) and
              T2iFn.Left(b.v, a.v, a1.v)
  else
    // Else a is reflex:
    Result := not (T2iFn.LeftOn(a.v, b.v, a1.v) and
                   T2iFn.LeftOn(b.v, a.v, a0.v));
end;

function TEarTri.Diagonal(a, b: tVertex): Boolean;
begin
  Result := InCone(a, b) and InCone(b, a) and Diagonalie(a, b);
end;

function TEarTri.ReadVertices(const filename: string): Integer;
var
  v: tVertex;
  i, x, y, vnum: Integer;
  str: TStrings;
  line: string;
  sa: TArray<string>;
begin
  vnum := 0;
  str := TStringList.Create;
  try
    str.LoadFromFile(filename);
    for i := 0 to str.Count - 1 do
    begin
      line := str.Strings[i];
      sa := line.Split([Chr(9)]);
      if sa = nil then break;
      x := Integer.Parse(sa[0]);
      y := Integer.Parse(sa[1]);
      v := MakeNullVertex;
      v.v.x := x;
      v.v.y := y;
      v.vnum := vnum;
      Inc(vnum);
    end;
    if vnum < 3 then
      raise Exception.CreateFmt('ReadVertices: nvertices=%d < 3', [vnum]);
  finally
    str.Free;
  end;
  Result := vnum;
end;

procedure TEarTri.Add(var head: tVertex; p: tVertex);
begin
  if head <> nil then
  begin
    p.next := head;
    p.prev := head.prev;
    head.prev := p;
    p.prev.next := p;
  end
  else
  begin
    head := p;
    head.next := p;
    head.prev := p;
  end;
end;

function TEarTri.MakeNullVertex: tVertex;
var
  v: tVertex;
begin
  New(v);
  Add(vertices, v);
  Result := v;
end;

function TEarTri.AreaPoly2: Integer;
var
  sum: Integer;
  p, v: tVertex;
begin
  sum := 0;
  p := vertices; // Fixed.
  v := p.next;   // Moving.
  repeat
    sum := sum + T2iFn.Area2(p.v, v.v, v.next.v);
    v := v.next;
  until v = vertices;
  Result := sum;
end;

{$EndRegion}

end.

