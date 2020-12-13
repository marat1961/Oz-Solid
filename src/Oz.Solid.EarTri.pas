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
  System.Classes, System.SysUtils, Oz.Solid.VectorInt;

{$EndRegion}

{$T+}

type

  tVertex = ^tsVertex;
  tsVertex = record
    vnum: Integer; // Index
    v: t2i;        // Coordinates
    ear: Boolean;
    next, prev: tVertex;
  end;

// Returns twice the signed area of the triangle determined by a, b, c.
// The area is positive if a,b,c are oriented ccw, negative if cw,
// and zero if the points are collinear.
function Area2(a, b, c: t2i): Integer;

// Returns True iff c is strictly to the left of the directed line
// through a to b.
function Left(a, b, c: t2i): Boolean;

// Returns True iff ab properly intersects cd: they share
// a point interior to both segments. The properness of the
// intersection is ensured by using strict leftness.
function IntersectProp(a, b, c, d: t2i): Boolean;

function LeftOn(a, b, c: t2i): Boolean;

function Collinear(a, b, c: t2i): Boolean;

// Returns True iff point c lies on the closed segement ab.
// First checks that c is collinear with a and b.
function Between(a, b, c: t2i): Boolean;

// Returns True iff segments ab and cd intersect, properly or improperly.
function Intersect(a, b, c, d: t2i): Boolean;

// Returns True iff (a, b) is a proper internal or external
// diagonal of P, ignoring edges incident to a and b.
function Diagonalie(a, b: tVertex): Boolean;

// This function initializes the data structures, and calls
// Triangulate2 to clip off the ears one by one.
procedure EarInit;

// Prints out n-3 diagonals (as pairs of integer indices)
// which form a triangulation of P.
procedure Triangulate;

// Returns True iff the diagonal (a,b) is strictly internal to the
// polygon in the neighborhood of the a endpoint.
function InCone(a, b: tVertex): Boolean;

// Returns True iff (a,b) is a proper internal diagonal.
function Diagonal(a, b: tVertex): Boolean;

// ReadVertices: Reads in the vertices, and links them into a circular
// list with MakeNullVertex.  There is no need for the # of vertices to be
// the first line: the function looks for EOF instead.
procedure ReadVertices(const filename: string);

// MakeNullVertex: Makes a vertex.
function MakeNullVertex: tVertex;

// For debugging; not currently invoked.
procedure PrintPoly;

// Print: Prints out the vertices.  Uses the vnum indices
// corresponding to the order in which the vertices were input.
// Output is in SVG format.
procedure PrintVertices;

procedure PrintDiagonal(a, b: tVertex);

function AreaPoly2: Integer;
function AreaSign(a, b, c: t2i): Integer;

procedure main;

implementation

var
  // 'Head' of circular list.
  vertices: tVertex = nil;
  // Total number of polygon vertices.
  nvertices: Integer = 0;

function Area2( a, b, c: t2i ): Integer;
begin
  exit(
    (b.x - a.x) * (c.y - a.y) -
    (c.x - a.x) * (b.y - a.y));
end;

function IntersectProp(a, b, c, d: t2i): Boolean;
begin
  // Eliminate improper cases.
  if (Collinear(a, b, c) or Collinear(a, b, d) or
      Collinear(c, d, a) or Collinear(c, d, b)) then
    exit(False);
  Result :=
    (Left(a, b, c) xor Left(a, b, d)) and
    (Left(c, d, a) xor Left(c, d, b));
end;

function Left(a, b, c: t2i): Boolean;
begin
  Result := AreaSign(a, b, c) > 0;
end;

function LeftOn(a, b, c: t2i): Boolean;
begin
  Result := AreaSign(a, b, c) >= 0;
end;

function Collinear(a, b, c: t2i): Boolean;
begin
  Result := AreaSign(a, b, c) = 0;
end;

function Between(a, b, c: t2i): Boolean;
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

function Intersect(a, b, c, d: t2i): Boolean;
begin
   if IntersectProp( a, b, c, d ) then
     Result := True
   else if Between(a, b, c) or Between(a, b, d) or Between(c, d, a)
        or Between(c, d, b) then
     Result := True
   else
     Result := False;
end;

function Diagonalie(a, b: tVertex): Boolean;
var
  c, c1: tVertex;
begin
  // For each edge (c, c1) of P
  c := vertices;
  repeat
    c1 := c.next;
    // Skip edges incident to a or b
    if (c <> a) and (c1 <> a) and (c <> b) and (c1 <> b) and
       Intersect(a.v, b.v, c.v, c1.v) then
      exit(False);
    c := c.next;
   until c = vertices;
   Result := True;
end;

procedure EarInit;
var
  v0, v1, v2: tVertex;   // three consecutive vertices
begin
  // Initialize v1.ear for all vertices.
  v1 := vertices;
  writeln('newpath');
  repeat
    v2 := v1.next;
    v0 := v1.prev;
    v1.ear := Diagonal(v0, v2);
    v1 := v1.next;
   until v1 = vertices;
   writeln('closepath stroke'#13#10);
end;

procedure Triangulate;
var
  n: Integer; // number of vertices; shrinks to 3.
  v0, v1, v2, v3, v4: tVertex; // five consecutive vertices
  earfound: Boolean; // for debugging and error detection only.
begin
  n := nvertices;
  EarInit();
  writeln(#13#10'newpath');
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
        PrintDiagonal(v1, v3);
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
      writeln('Error in Triangulate: No ear found.');
      PrintPoly;
      Halt;
    end;
  end;
  writeln('closepath stroke');
end;

function InCone(a, b: tVertex): Boolean;
var
  a0, a1: tVertex ;  // a0, a, a1 are consecutive vertices.
begin
  a1 := a.next;
  a0 := a.prev;
  // If a is a convex vertex ...
  if LeftOn(a.v, a1.v, a0.v) then
    Result := Left(a.v, b.v, a0.v) and Left(b.v, a.v, a1.v)
  else
    // Else a is reflex:
    Result := not (LeftOn(a.v, b.v, a1.v) and LeftOn(b.v, a.v, a0.v));
end;

function Diagonal(a, b: tVertex): Boolean;
begin
  Result := InCone(a, b) and InCone(b, a) and Diagonalie(a, b);
end;

procedure ReadVertices(const filename: string);
var
  v: tVertex;
  i, x, y, vnum: Integer;
  str: TStrings;
  line, err: string;
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
    nvertices := vnum;
    if nvertices < 3 then
    begin
      err := Format('Error in ReadVertices: nvertices=%d<3\n', [nvertices]);
      writeln(err);
      raise Exception.Create(err);
    end;
  finally
    str.Free;
  end;
end;

procedure Add(head, p: tVertex);
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

function MakeNullVertex: tVertex;
var
  v: tVertex;
begin
  New(v);
  Add(vertices, v);
  Result := v;
end;

procedure PrintPoly;
var
  v: tVertex;
begin
  writeln('Polygon circular list:');
  v := vertices;
  repeat
    writeln(Format(' vnum=%5d:'#9'tear=%d', [v.vnum, v.ear]));
    v := v.next;
  until v = vertices;
end;

procedure PrintVertices;
var
  // Pointers to vertices, edges, faces.
  v: tVertex;
  xmin, ymin, xmax, ymax: Integer;
begin
  // Compute bounding box for Encapsulated SVG.
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
  until v = vertices;

  // SVG header
//  writeln(Format('BoundingBox: %d %d %d %d\n', xmin, ymin, xmax, ymax);
//  writeln(Format('EndComments\n');
//  writeln(Format('.00 .00 setlinewidth\n');
//  writeln(Format('%d %d translate\n', -xmin+72, -ymin+72 );
//  // The +72 shifts the figure one inch from the lower left corner
//
//  // Output vertex info as a PostScript comment.
//  writeln(Format('\n number of vertices = %d\n', nvertices);
//  v = vertices;
//  repeat
//    printf( '%% vnum=%5d:\tx=%5d\ty=%5d\n', v.vnum, v.v.x, v.v.y );
//    v := v.next;
//  until v = vertices;
//
//  // Draw the polygon.
//  writeln(Format('\n%%Polygon:\n');
//  writeln(Format('newpath\n');
//  v = vertices;
//  writeln(Format('%d\t%d\tmoveto\n', v.v.x, v.v.y );
//  v = v.next;
//  repeat
//      writeln(Format('%d\t%d\tlineto\n', v.v.x, v.v.y );
//      v = v.next;
//  until v = vertices;
//  writeln(Format('closepath stroke\n');
end;

procedure PrintDiagonal(a, b: tVertex);
begin
//  writeln(Format('Diagonal: (%d,%d)\n', a.vnum, b.vnum );
//  writeln(Format('%d\t%d\tmoveto\n', a.v.x, a.v.y );
//  writeln(Format('%d\t%d\tlineto\n', b.v.x, b.v.y );
end;

function AreaPoly2: Integer;
var
  sum: Integer;
  p, v: tVertex;
begin
  sum := 0;
  p := vertices; // Fixed.
  v := p.next;   // Moving.
  repeat
    sum := sum + Area2(p.v, v.v, v.next.v);
    v := v.next;
  until v = vertices;
  Result := sum;
end;

function AreaSign(a, b, c: t2i): Integer;
var
  area2: Double;
begin
  area2 := (b.x - a.x) * Double(c.y - a.y) -
           (c.x - a.x) * Double(b.x - a.x);
  // The area should be an integer.
  if area2 > 0.5 then
    Result := 1
  else if area2 < -0.5 then
    Result := -1
  else
    Result := 0;
end;

procedure main;
var
  filename: string;
begin
  filename := 'test.dat';
  ReadVertices(filename);
  PrintVertices;
  writeln(Format('Area of polygon = %g', [0.5 * AreaPoly2]));
  Triangulate;
  writeln;
end;

end.

