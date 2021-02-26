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
unit Oz.Solid.DelaunayTri;

interface

{$Region 'Uses'}

uses
  System.Classes, System.SysUtils, System.Math, Oz.Solid.VectorInt, Oz.Solid.Svg;

{$EndRegion}

{$T+}

type
  PVertex = ^TVertex;
  PFace = ^TFace;
  PEdge = ^TEdge;

  T3i = record
    x, y, z: Integer;
  end;

{$Region 'TVertex, tVertexHelper: vertices'}

  TVertex = record
    v: T3i;
    vnum: Integer;
    duplicate: PEdge;  // pointer to incident cone edge (or nil)
    onhull: Boolean;   // T iff point on hull.
    mark: Boolean;     // T iff point already processed.
    next: PVertex;
    prev: PVertex;
  end;

  TVertexList = record
    head: PVertex;
    procedure Free;
    procedure Add(p: PVertex);
    procedure Del(p: PVertex);
  end;

{$EndRegion}

{$Region 'TEdge, tEdgeHelper: edges'}

  TEdge = record
    adjface: array [0..1] of PFace;
    endpts: array [0..1] of PVertex;
    newface: PFace;     // pointer to incident cone face.
    delete: Boolean;    // T iff edge should be delete.
    next: PEdge;
    prev: PEdge;
  end;

  TEdgeList = record
    head: PEdge;
    procedure Free;
    procedure Add(p: PEdge);
    procedure Del(p: PEdge);
  end;

{$EndRegion}

{$Region 'TFace, tFaceHelper: faces'}

  TFace = record
    edge: array [0..2] of PEdge;
    vertex: array [0..2] of PVertex;
    visible: Boolean;   // T iff face visible from New point.
    lower: Boolean;     // T iff on the lower hull
    next: PFace;
    prev: PFace;
  end;

  TFaceList = record
    head: PFace;
    procedure Free;
    procedure Add(p: PFace);
    procedure Del(p: PFace);
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
    function CalcBounds(vertices: PVertex): Integer;
  public
    debug: Boolean;
    check: Boolean;
    procedure Init(const filename: string);
    procedure Free;
    // Prints out the vertices and the faces. Uses the vnum indices
    // corresponding to the order in which the vertices were input.
    procedure Print(vertices: PVertex; edges: PEdge; faces: PFace);
    // CheckEuler checks Euler's relation, as well as its implications when
    // all faces are known to be triangles.  Only prints positive information
    // when debug is true, but always prints negative information.
    procedure CheckEuler(V, E, F: Integer);
    // Debug print
    procedure Dbp; overload;
    procedure Dbp(const line: string); overload;
    procedure Dbp(const fs: string; const args: array of const); overload;
  end;

{$EndRegion}

{$Region 'TDelaunayTri'}

  TDelaunayTri = class
  private
    io: TsvgIO;
    vertices: TVertexList;
    edges: TEdgeList;
    faces: TFaceList;
    // Volumed is the same as VolumeSign but computed with doubles.
    // For protection against overflow.
    function Volumed(f: PFace; p: PVertex): Double;
    function Volumei(f: PFace; p: PVertex): Integer;
  public
    constructor Create(const filename: string);
    destructor Destroy; override;
    procedure Build;
    // MakeNullVertex: Makes a vertex, nulls out fields
    function MakeNullVertex: PVertex;
    // Reads in the vertices, and links them into a circular
    // list with MakeNullVertex. There is no need for the # of vertices
    // to be the first line: the function looks for EOF instead.
    function ReadVertices(const filename: string): Integer;
    // SubVec: Computes a - b and puts it into c.
    procedure SubVec(const a, b: T3i; var c: T3i);
    // DoubleTriangle builds the initial Double triangle.  It first finds 3
    // noncollinear points and makes two faces out of them, in opposite order.
    // It then finds a fourth point that is not coplanar with that face.  The
    // vertices are stored in the face structure in counterclockwise order so
    // that the volume between the face and the point is negative. Lastly, the
    // 3 newfaces to the fourth point are constructed and the data structures
    // are cleaned up.
    procedure DoubleTriangle;
    // ConstructHull adds the vertices to the hull one at a time.
    // The hull vertices are those in the list marked as onhull.
    procedure ConstructHull;
    // AddOne is passed a vertex.  It first determines all faces visible from
    // that point.  If none are visible then the point is marked as not
    // onhull.  Next is a loop over edges.  If both faces adjacent to an edge
    // are visible, then the edge is marked for deletion.  If just one of the
    // adjacent faces is visible then a New face is constructed.
    function AddOne(p: PVertex): Boolean;
    // VolumeSign returns the sign of the volume of the tetrahedron determined by f
    // and p.  VolumeSign is +1 iff p is on the negative side of f,
    // where the positive side is determined by the rh-rule.  So the volume
    // is positive if the ccw normal to f points outside the tetrahedron.
    // The final fewer-multiplications form is due to Robert Fraczkiewicz.
    function VolumeSign(f: PFace; p: PVertex): Integer;
    // MakeConeFace makes a New face and two New edges between the
    // edge and the point that are passed to it. It returns a pointer to
    // the New face.
    function MakeConeFace(e: PEdge; p: PVertex): PFace;
    // MakeCcw puts the vertices in the face structure in counterclock wise
    // order. We want to store the vertices in the same
    // order as in the visible face.  The third vertex is always p.
    procedure MakeCcw(f: PFace; e: PEdge; p: PVertex);
    // MakeNullEdge creates a New cell and initializes all pointers to nil
    // and sets all flags to off.  It returns a pointer to the empty cell.
    function MakeNullEdge: PEdge;
    // MakeNullFace creates a New face structure and initializes all of its
    // flags to nil and sets all the flags to off.  It returns a pointer
    // to the empty cell.
    function MakeNullFace: PFace;
    // MakeFace creates a New face structure from three vertices
    // (in ccw order).  It returns a pointer to the face.
    function MakeFace(v0, v1, v2: PVertex; fold: PFace): PFace;
    // CleanUp goes through each data structure list and clears all
    // flags and NULLs out some pointers.  The order of processing
    // (edges, faces, vertices) is important.
    procedure CleanUp;
    // CleanEdges runs through the edge list and cleans up the structure.
    // If there is a newface then it will put that face in place of the
    // visible face and nil out newface. It also deletes so marked edges.
    procedure CleanEdges;
    // CleanFaces runs through the face list and deletes any face marked visible.
    procedure CleanFaces;
    // CleanVertices runs through the vertex list and deletes the
    // vertices that are marked as processed but are not incident to any
    // undeleted edges.
    procedure CleanVertices;
    // Collinear checks to see if the three points given are collinear,
    // by checking to see if each element of the cross product is zero.
    function Collinear(a, b, c: PVertex): Boolean;
    // Computes the z-coordinate of the vector normal to face f.
    function Normz(f: PFace): Integer;
    procedure PrintPoint(p: PVertex);
    procedure Checks;
    // Consistency runs through the edge list and checks that all
    // adjacent faces have their endpoints in opposite order.
    // This verifies that the vertices are in counterclockwise order.
    procedure Consistency;
    // Convexity checks that the volume between every face and every
    // point is negative.  This shows that each point is inside every face
    // and therefore the hull is convex.
    procedure Convexity;
    // These functions are used whenever the debug flag is set.
    // They print out the entire contents of each data structure.
    procedure PrintOut(v: PVertex);
    procedure PrintVertices;
    procedure PrintEdges;
    procedure PrintFaces;
    procedure LowerFaces;
  end;

{$EndRegion}

implementation

const
  // Define flags
  ONHULL = True;
  REMOVED = True;
  VISIBLE = True;
  PROCESSED = True;
  SAFE = 1000000;    // Range of safe coordinate values

procedure Swap(var a, b: PEdge);
var
  temp: PEdge;
begin
  temp := a;
  a := b;
  b := temp;
end;

{$Region 'TVertexList'}

procedure TVertexList.Free;
begin
  while head <> nil do Del(head);
end;

procedure TVertexList.Add(p: PVertex);
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

procedure TVertexList.Del(p: PVertex);
begin
  if head = head.next then
    head := nil
  else if p = head then
    head := head.next;
  p.next.prev := p.prev;
  p.prev.next := p.next;
  Dispose(p);
end;

{$EndRegion}

{$Region 'TEdgeList'}

procedure TEdgeList.Free;
begin
  while head <> nil do Del(head);
end;

procedure TEdgeList.Add(p: PEdge);
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

procedure TEdgeList.Del(p: PEdge);
begin
  if head = head.next then
    head := nil
  else if p = head then
    head := head.next;
  p.next.prev := p.prev;
  p.prev.next := p.next;
  Dispose(p);
end;

{$EndRegion}

{$Region 'TFaceList'}

procedure TFaceList.Free;
begin
  while head <> nil do Del(head);
end;

procedure TFaceList.Add(p: PFace);
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

procedure TFaceList.Del(p: PFace);
begin
  if head = head.next then
    head := nil
  else if p = head then
    head := head.next;
  p.next.prev := p.prev;
  p.prev.next := p.next;
  Dispose(p);
end;

{$EndRegion}

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

procedure TsvgIO.Print(vertices: PVertex; edges: PEdge; faces: PFace);
var
  v: PVertex; // Pointers to vertices
  e: PEdge;   // Pointers to edges
  f: PFace;   // Pointers to faces
  Vc, Ec, Fc: Integer;
  width, height: Integer;
begin
  // Counters for Euler's formula.
  Vc := 0; Ec := 0; Fc := 0;
  CalcBounds(vertices);

  // ViewBox
  width := xmax - xmin + 1;
  height := xmax - xmin + 1;
  svg.ViewBox(xmin, ymin, width, height);

  // Vertices
  v := vertices;
  repeat
    if v.mark then Inc(Vc);
    v := v.next;
  until v = vertices;
  Dbp('  Vertices: %d', [Vc]);
  repeat
    v := v.next;
  until v = vertices;

  // Faces.
  // visible faces are printed as PS output
  f := faces;
  repeat
    Inc(Fc);
    f := f.next;
  until f = faces;
  Dbp('  Faces: F = %d', [Fc]);
  Dbp('  Visible faces only: ');
  repeat
    // Print face only if it is lower
    if f.lower then
    begin
      Dbp(Format('vnums: %d  %d  %d',
        [f.vertex[0].vnum, f.vertex[1].vnum, f.vertex[2].vnum]));
      svg.Polygon
        .Point(f.vertex[0].v.x, f.vertex[0].v.y)
        .Point(f.vertex[1].v.x, f.vertex[1].v.y)
        .Point(f.vertex[2].v.x, f.vertex[2].v.y)
        .Stroke('green').StrokeWidth(0.2);
    end;
    f := f.next;
  until f = faces;

  // prints a list of all faces
  Dbp('List of all faces');
  Dbp('v0 v1 v2 (vertex indices)');
  repeat
    Dbp(Format('%d %d %d',
      [f.vertex[0].vnum, f.vertex[1].vnum, f.vertex[2].vnum]));
    f := f.next;
  until f = faces;

  // Edges.
  e := edges;
  repeat
    Inc(Ec);
    e := e.next;
  until e = edges;
  Dbp(Format('Edges: E = %d', [Ec]));
  // Edges not printed out (but easily added).

  check := True;
  CheckEuler(Vc, Ec, Fc);

  svg.SaveToFile(filename + '.svg');
  log.SaveToFile(filename + '.txt');
end;

procedure TsvgIO.CheckEuler(V, E, F: Integer);
begin
  if check then
    Dbp(Format('Checks: V, E, F = %d %d %d:', [V, E, F]));
  if (V - E + F) <> 2 then
    Dbp('Checks: V - E + F <> 2')
  else if check then
    Dbp('V - E + F = 2');
  if F <> (2 * V - 4) then
    Dbp(Format('Checks: F=%d <> 2 * V - 4=%d; V=%d', [F, 2 * V - 4, V]))
  else if check then
    Dbp('F = 2 * V - 4');
  if 2 * E <> 3 * F then
    Dbp(Format('Checks: 2E=%d <> 3F=%d; E=%d, F=%d', [2 * E, 3 * F, E, F]))
  else if check then
    Dbp('2 * E = 3 * F');
end;

function TsvgIO.CalcBounds(vertices: PVertex): Integer;
var
  v: PVertex;
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

procedure TsvgIO.Dbp;
begin
  Log.Add('');
end;

procedure TsvgIO.Dbp(const line: string);
begin
  Log.Add(line);
end;

procedure TsvgIO.Dbp(const fs: string; const args: array of const);
begin
  Log.Add(Format(fs, args));
end;

{$EndRegion}

{$Region 'TDelaunayTri'}

constructor TDelaunayTri.Create(const filename: string);
begin
  io.Init(filename);
  io.debug := True;
  ReadVertices(filename);
end;

destructor TDelaunayTri.Destroy;
begin
  io.Free;
  faces.Free;
  edges.Free;
  vertices.Free;
  inherited;
end;

procedure TDelaunayTri.Build;
begin
  DoubleTriangle;
  ConstructHull;
  LowerFaces;
  io.Print(vertices.head, edges.head, faces.head);
end;

function TDelaunayTri.MakeNullVertex: PVertex;
var
  v: PVertex;
begin
  New(v);
  v.duplicate := nil;
  v.onhull := not ONHULL;
  v.mark := not PROCESSED;
  vertices.Add(v);
  Result := v;
end;

function TDelaunayTri.ReadVertices(const filename: string): Integer;
var
  v: PVertex;
  i, x, y, z, vnum: Integer;
  str: TStrings;
  line: string;
  sa: TArray<string>;
begin
  vnum := 0;
  str := TStringList.Create;
  try
    str.LoadFromFile(filename);
    for i := 1 to str.Count - 1 do
    begin
      line := str.Strings[i];
      sa := line.Split([Chr(9)]);
      if sa = nil then break;
      x := Integer.Parse(sa[0]);
      y := Integer.Parse(sa[1]);
      z := x * x + y * y;
      v := MakeNullVertex;
      v.v.x := x;
      v.v.y := y;
      v.v.z := z;
      v.vnum := vnum;
      Inc(vnum);
      if (Abs(x) > SAFE) or (Abs(y) > SAFE) or (Abs(z) > SAFE) then
      begin
        PrintPoint(v);
        raise Exception.Create('Too large coordinate of vertex');
      end;
    end;
    if vnum < 3 then
      raise Exception.CreateFmt('ReadVertices: nvertices=%d < 3', [vnum]);
  finally
    str.Free;
  end;
  Result := vnum;
end;

procedure TDelaunayTri.SubVec(const a, b: T3i; var c: T3i);
begin
  c.x := a.x - b.x;
  c.y := a.y - b.y;
  c.z := a.z - b.z;
end;

procedure TDelaunayTri.DoubleTriangle;
var
  v0, v1, v2, v3: PVertex;
  f0, f1: PFace;
  vol: Integer;
begin
  f1 := nil;
  (* Find 3 non-Collinear points. *)
  v0 := vertices.head;
  while Collinear(v0, v0.next, v0.next.next) do
  begin
    v0 := v0.next;
    if v0 = vertices.head then
      raise Exception.Create('DoubleTriangle:  All points are Collinear!');
  end;
  v1 := v0.next;
  v2 := v1.next;

  // Mark the vertices as processed.
  v0.mark := PROCESSED;
  v1.mark := PROCESSED;
  v2.mark := PROCESSED;

  // Create the two 'twin' faces.
  f0 := MakeFace( v0, v1, v2, f1 );
  f1 := MakeFace( v2, v1, v0, f0 );

  // Link adjacent face fields.
  f0.edge[0].adjface[1] := f1;
  f0.edge[1].adjface[1] := f1;
  f0.edge[2].adjface[1] := f1;
  f1.edge[0].adjface[1] := f0;
  f1.edge[1].adjface[1] := f0;
  f1.edge[2].adjface[1] := f0;

  // Find a fourth, non-coplanar point to form tetrahedron.
  v3 := v2.next;
  vol := VolumeSign(f0, v3);
  while IsZero(vol) do
  begin
    v3 := v3.next;
    if v3 = v0 then
      raise Exception.Create('DoubleTriangle:  All points are coplanar!');
    vol := VolumeSign(f0, v3);
  end;

  // Insure that v3 will be the first added.
  vertices.head := v3;
  if io.debug then
  begin
    io.Dbp('DoubleTriangle: finished. Head repositioned at v3.');
    PrintOut(vertices.head);
  end;
end;

procedure TDelaunayTri.ConstructHull;
var
  v, vnext: PVertex ;
  changed: Boolean;  // T if addition changes hull; not used.
begin
  v := vertices.head;
  repeat
    vnext := v.next;
    if not v.mark then
    begin
      v.mark := PROCESSED;
      changed := AddOne(v);
      CleanUp;
      if io.check then
      begin
        io.Dbp(Format('ConstructHull: After Add of %d & Cleanup:', [v.vnum]));
        Checks;
      end;
      if io.debug then PrintOut(v);
    end;
    v := vnext;
  until v = vertices.head;
end;

function TDelaunayTri.AddOne(p: PVertex): Boolean;
var
  f: PFace;
  e, temp: PEdge;
  vol: Integer;
  vis: Boolean;
begin
  vis := False;
  if io.debug then
  begin
    io.Dbp('AddOne: starting to add v%d.', [p.vnum]);
    PrintOut(vertices.head);
  end;

  // Mark faces visible from p.
  f := faces.head;
  repeat
    vol := VolumeSign(f, p);
    if io.debug then
      io.Dbp('faddr: %6x   paddr: %6x   Vol = %d', [Integer(f), Integer(p), vol]);
    if vol < 0 then
    begin
      f.visible := VISIBLE;
      vis := True;
    end;
    f := f.next;
  until f = faces.head;

  // If no faces are visible from p, then p is inside the hull.
  if not vis then
  begin
    p.onhull := not ONHULL;
    exit(False);
  end;

  // Mark edges in interior of visible region for deletion.
  // Erect a newface based on each border edge.
  e := edges.head;
  repeat
    temp := e.next;
    if e.adjface[0].visible and e.adjface[1].visible then
      // e interior: mark for deletion.
      e.delete := REMOVED
    else if e.adjface[0].visible or e.adjface[1].visible then
      // e border: make a New face.
      e.newface := MakeConeFace(e, p);
    e := temp;
  until e = edges.head;
  Result := True;
end;

function TDelaunayTri.VolumeSign(f: PFace; p: PVertex): Integer;
var
  vol: Double;
  ax, ay, az, bx, by, bz, cx, cy, cz, dx, dy, dz: Double;
  bxdx, bydy, bzdz, cxdx, cydy, czdz: Double;
begin
  ax := f.vertex[0].v.x;
  ay := f.vertex[0].v.y;
  az := f.vertex[0].v.z;
  bx := f.vertex[1].v.x;
  by := f.vertex[1].v.y;
  bz := f.vertex[1].v.z;
  cx := f.vertex[2].v.x;
  cy := f.vertex[2].v.y;
  cz := f.vertex[2].v.z;
  dx := p.v.x;
  dy := p.v.y;
  dz := p.v.z;

  bxdx := bx - dx;
  bydy := by - dy;
  bzdz := bz - dz;
  cxdx := cx - dx;
  cydy := cy - dy;
  czdz := cz - dz;
  vol := (az - dz) * (bxdx * cydy - bydy * cxdx)
       + (ay - dy) * (bzdz * cxdx - bxdx * czdz)
       + (ax - dx) * (bydy * czdz - bzdz * cydy);
  if io.debug then
    io.Dbp('Face=%x Vertex=%d vol=%f', [Integer(f), p.vnum, vol]);

  // The volume should be an integer.
  if vol > 0.5 then
    Result := 1
  else if vol < -0.5 then
    Result := -1
  else
    Result := 0;
end;

function TDelaunayTri.Volumei(f: PFace; p: PVertex): Integer;
var
  vol: Integer;
  ax, ay, az, bx, by, bz, cx, cy, cz, dx, dy, dz: Integer;
  bxdx, bydy, bzdz, cxdx, cydy, czdz: Integer;
begin
  ax := f.vertex[0].v.x;
  ay := f.vertex[0].v.y;
  az := f.vertex[0].v.z;
  bx := f.vertex[1].v.x;
  by := f.vertex[1].v.y;
  bz := f.vertex[1].v.z;
  cx := f.vertex[2].v.x;
  cy := f.vertex[2].v.y;
  cz := f.vertex[2].v.z;
  dx := p.v.x;
  dy := p.v.y;
  dz := p.v.z;

  bxdx := bx - dx;
  bydy := by - dy;
  bzdz := bz - dz;
  cxdx := cx - dx;
  cydy := cy - dy;
  czdz := cz - dz;
  vol := (az - dz) * (bxdx * cydy - bydy * cxdx)
       + (ay - dy) * (bzdz * cxdx - bxdx * czdz)
       + (ax - dx) * (bydy * czdz - bzdz * cydy);

  Result := vol;
end;

function TDelaunayTri.Volumed(f: PFace; p: PVertex): Double;
var
  vol, ax, ay, az, bx, by, bz, cx, cy, cz, dx, dy, dz: Double;
  bxdx, bydy, bzdz, cxdx, cydy, czdz: Double;
begin
  ax := f.vertex[0].v.x;
  ay := f.vertex[0].v.y;
  az := f.vertex[0].v.z;
  bx := f.vertex[1].v.x;
  by := f.vertex[1].v.y;
  bz := f.vertex[1].v.z;
  cx := f.vertex[2].v.x;
  cy := f.vertex[2].v.y;
  cz := f.vertex[2].v.z;
  dx := p.v.x;
  dy := p.v.y;
  dz := p.v.z;

  bxdx := bx - dx;
  bydy := by - dy;
  bzdz := bz - dz;
  cxdx := cx - dx;
  cydy := cy - dy;
  czdz := cz - dz;
  vol := (az - dz) * (bxdx * cydy - bydy * cxdx)
       + (ay - dy) * (bzdz * cxdx - bxdx * czdz)
       + (ax - dx) * (bydy * czdz - bzdz * cydy);

  Result := vol;
end;

function TDelaunayTri.MakeConeFace(e: PEdge; p: PVertex): PFace;
var
  i, j: Integer;
  new_edge: array [0..1] of PEdge;
  new_face: PFace;
begin
  // Make two New edges (if don't already exist).
  for i := 0 to 1 do
  begin
    new_edge[i] := e.endpts[i].duplicate;
    // If the edge exists, copy it into new_edge.
    if new_edge[i] = nil then
    begin
      // Otherwise (duplicate is nil), MakeNullEdge.
      new_edge[i] := MakeNullEdge;
      new_edge[i].endpts[0] := e.endpts[i];
      new_edge[i].endpts[1] := p;
      e.endpts[i].duplicate := new_edge[i];
    end;
  end;

  // Make the New face.
  new_face := MakeNullFace();
  new_face.edge[0] := e;
  new_face.edge[1] := new_edge[0];
  new_face.edge[2] := new_edge[1];
  MakeCcw(new_face, e, p);

  // Set the adjacent face pointers.
  for i := 0 to 1 do
    for j := 0 to 1 do
      // Only one nil link should be set to new_face.
      if new_edge[i].adjface[j] = nil then
      begin
        new_edge[i].adjface[j] := new_face;
        break;
      end;

  Result := new_face;
end;

procedure TDelaunayTri.MakeCcw(f: PFace; e: PEdge; p: PVertex);
var
  fv: PFace;  // The visible face adjacent to e
  i: Integer; // Index of e.endpoint[0] in fv.
begin
  if e.adjface[0].visible then
    fv := e.adjface[0]
  else
    fv := e.adjface[1];
  // Set vertex[0] & [1] of f to have the same orientation
  // as do the corresponding vertices of fv.
  i := 0;
  while fv.vertex[i] <> e.endpts[0] do Inc(i);
  // Orient f the same as fv.
  if fv.vertex[(i + 1) mod 3] <> e.endpts[1] then
  begin
    f.vertex[0] := e.endpts[1];
    f.vertex[1] := e.endpts[0];
  end
  else
  begin
    f.vertex[0] := e.endpts[0];
    f.vertex[1] := e.endpts[1];
    Swap(f.edge[1], f.edge[2]);
  end;
  // This swap is tricky. e is edge[0]. edge[1] is based on endpt[0],
  // edge[2] on endpt[1]. So if e is oriented 'forwards' we
  // need to move edge[1] to follow [0], because it precedes.
  f.vertex[2] := p;
end;

function TDelaunayTri.MakeNullEdge: PEdge;
var
  e: PEdge;
begin
  New(e);
  e.adjface[0] := nil;
  e.adjface[1] := nil;
  e.newface := nil;
  e.endpts[0] := nil;
  e.endpts[1] := nil;
  e.delete := not REMOVED;
  edges.Add(e);
  Result := e;
end;

procedure TDelaunayTri.Checks;
var
  v: PVertex;
  e: PEdge;
  f: PFace;
  Vc, Ec, Fc: Integer;
begin
  Vc := 0; Ec := 0; Fc := 0;
  Consistency;
  Convexity;
  v := vertices.head;
  while v <> vertices.head do
  begin
    if v.mark then Inc(Vc);
    v := v.next;
  end;
  e := edges.head;
  while e <> edges.head do
  begin
    Inc(Ec);
    e := e.next;
  end;
  f := faces.head;
  while f <> faces.head do
  begin
    Inc(Fc);
    f := f.next;
  end;
  io.CheckEuler(Vc, Ec, Fc);
end;

procedure TDelaunayTri.CleanEdges;
var
  e: PEdge;  // Primary index into edge list.
  t: PEdge;  // Temporary edge pointer.
begin
  // Integrate the newface's into the data structure.
  // Check every edge.
  e := edges.head;
  repeat
    if e.newface <> nil then
    begin
      if e.adjface[0].visible then
        e.adjface[0] := e.newface
      else
        e.adjface[1] := e.newface;
      e.newface := nil;
    end;
    e := e.next;
  until e = edges.head;

  (* Delete any edges marked for deletion. *)
  while (edges.head <> nil) and edges.head.delete do
  begin
    e := edges.head;
    edges.Del(e);
  end;
  e := edges.head.next;
  repeat
    if e.delete then
    begin
      t := e;
      e := e.next;
      edges.Del(t);
    end
    else
      e := e.next;
  until e = edges.head;
end;

procedure TDelaunayTri.CleanFaces;
var
  f: PFace;  // Primary pointer into face list.
  t: PFace;  // Temporary pointer, for deleting.
begin
  while (faces.head <> nil) and faces.head.visible do
  begin
    f := faces.head;
    faces.Del(f);
  end;
  f := faces.head.next;
  repeat
    if f.visible then
    begin
      t := f;
      f := f.next;
      faces.Del(t);
    end
    else
      f := f.next;
  until f = faces.head;
end;

procedure TDelaunayTri.CleanUp;
begin
  CleanEdges();
  CleanFaces();
  CleanVertices();
end;

procedure TDelaunayTri.CleanVertices;
var
  e: PEdge;
  v, t: PVertex;
begin
  // Mark all vertices incident to some undeleted edge as on the hull.
  e := edges.head;
  repeat
    e.endpts[0].onhull := ONHULL;
    e.endpts[1].onhull := ONHULL;
    e := e.next;
  until e = edges.head;

  // Delete all vertices that have been processed but are not on the hull.
  while (vertices.head <> nil) and vertices.head.mark and not vertices.head.onhull do
  begin
    v := vertices.head;
    vertices.Del(v);
  end;
  v := vertices.head.next;
  repeat
    if v.mark and not v.onhull then
    begin
      t := v;
      v := v.next;
      vertices.Del(t);
    end
    else
      v := v.next;
  until v = vertices.head;

  // Reset flags.
  v := vertices.head;
  repeat
    v.duplicate := nil;
    v.onhull := not ONHULL;
    v := v.next;
  until v = vertices.head;
end;

function TDelaunayTri.Collinear(a, b, c: PVertex): Boolean;
begin
  Result :=
    ((c.v.z - a.v.z) * (b.v.y - a.v.y) -
     (b.v.z - a.v.z) * (c.v.y - a.v.y) = 0) and
    ((b.v.z - a.v.z) * (c.v.x - a.v.x) -
     (b.v.x - a.v.x) * ( c.v.z - a.v.z) = 0) and
    ((b.v.x - a.v.x) * ( c.v.y - a.v.y) -
     (b.v.y - a.v.y) * ( c.v.x - a.v.x) = 0);
end;

procedure TDelaunayTri.Consistency;
var
  e: PEdge;
  i, j: Integer;
begin
  e := edges.head;
  repeat
    // find index of endpoint[0] in adjacent face[0]
    i := 0;
    while e.adjface[0].vertex[i] <> e.endpts[0] do Inc(i);
    // find index of endpoint[0] in adjacent face[1]
    j := 0;
    while e.adjface[1].vertex[j] <> e.endpts[0] do Inc(j);
    // check if the endpoints occur in opposite order
    if not ((e.adjface[0].vertex[(i + 1) mod 3] = e.adjface[1].vertex[(j + 2) mod 3]) or
            (e.adjface[0].vertex[(i + 2) mod 3] = e.adjface[1].vertex[(j + 1) mod 3])) then
      break;
    e := e.next;
  until e = edges.head;
  if e <> edges.head then
    io.Dbp('Checks: edges are NOT consistent.')
  else
    io.Dbp('Checks: edges consistent.');
end;

procedure TDelaunayTri.Convexity;
var
  f: PFace;
  v: PVertex;
  vol: Integer;
begin
  f := faces.head;
  repeat
    v := vertices.head;
    repeat
      if v.mark then
      begin
        vol := VolumeSign(f, v);
        if vol < 0 then
           break;
      end;
      v := v.next;
    until v = vertices.head;
    f := f.next;
  until f = faces.head;

  if f <> faces.head then
    io.Dbp('Checks: NOT convex.')
  else if io.check then
    io.Dbp('Checks: convex.');
end;

procedure TDelaunayTri.LowerFaces;
var
  f: PFace;
  Flower, z: Integer; // Total number of lower faces.
begin
  f := faces.head;
  Flower := 0;
  repeat
    z := Normz(f);
    if z < 0 then
    begin
      Inc(Flower);
      f.lower := True;
      io.Dbp(Format('z=%10d; lower face indices: %d, %d, %d',
        [z, f.vertex[0].vnum, f.vertex[1].vnum, f.vertex[2].vnum]));
    end
    else
      f.lower := False;
    f := f.next;
   until f = faces.head;
   io.Dbp(Format('A total of %d lower faces identified.', [Flower]));
end;

function TDelaunayTri.MakeFace(v0, v1, v2: PVertex; fold: PFace): PFace;
var
  f: PFace;
  e0, e1, e2: PEdge;
begin
  // Create edges of the initial triangle.
  if fold = nil then
  begin
    e0 := MakeNullEdge();
    e1 := MakeNullEdge();
    e2 := MakeNullEdge();
  end
  else
  begin
    // Copy from fold, in reverse order.
    e0 := fold.edge[2];
    e1 := fold.edge[1];
    e2 := fold.edge[0];
  end;
  e0.endpts[0] := v0; e0.endpts[1] := v1;
  e1.endpts[0] := v1; e1.endpts[1] := v2;
  e2.endpts[0] := v2; e2.endpts[1] := v0;

  // Create face for triangle.
  f := MakeNullFace();
  f.edge[0] := e0; f.edge[1] := e1; f.edge[2] := e2;
  f.vertex[0] := v0; f.vertex[1] := v1; f.vertex[2] := v2;

  // Link edges to face.
  e0.adjface[0] := f;
  e1.adjface[0] := f;
  e2.adjface[0] := f;

  Result := f;
end;

function TDelaunayTri.MakeNullFace: PFace;
var
  f: PFace;
  i: Integer;
begin
  New(f);
  for i := 0 to 2 do
  begin
    f.edge[i] := nil;
    f.vertex[i] := nil;
  end;
  f.visible := not VISIBLE;
  faces.Add(f);
  Result := f;
end;

function TDelaunayTri.Normz(f: PFace): Integer;
var
  a, b, c: PVertex;
begin
  a := f.vertex[0];
  b := f.vertex[1];
  c := f.vertex[2];
  Result :=
    (b.v.x - a.v.x) * (c.v.y - a.v.y) -
    (b.v.y - a.v.y) * (c.v.x - a.v.x);
end;

procedure TDelaunayTri.PrintEdges;
var
  temp: PEdge;
  i: Integer;
begin
  temp := edges.head;
  io.Dbp('Edge List');
  if edges.head <> nil then
  repeat
    io.Dbp(Format('  addr: %6x'#9, [Integer(edges.head)]));
    io.Dbp('adj: ');
    for i := 0 to 1 do
      io.Dbp(Format('%6x', [Integer(edges.head.adjface[i])]));
    io.Dbp('  endpts:');
    for i := 0 to 1 do
      io.Dbp(Format('%4d', [edges.head.endpts[i].vnum]));
    io.Dbp(Format('  del:%3d', [Ord(edges.head.delete)]));
    edges.head := edges.head.next;
  until edges.head = temp;
end;

procedure TDelaunayTri.PrintFaces;
var
  temp: PFace;
  i: Integer;
begin
  temp := faces.head;
  io.Dbp('Face List');
  if faces.head <> nil then
  repeat
    io.Dbp(Format('  addr: %6x'#9, [Integer(faces.head)]));
    io.Dbp('  edges:');
    for i := 0 to 2 do
      io.Dbp(Format('%6x', [Integer(faces.head.edge[i])]));
    io.Dbp('  vert:');
    for i := 0 to 2 do
      io.Dbp(Format('%4d', [faces.head.vertex[i].vnum]));
    io.Dbp(Format('  vis: %d', [Ord(faces.head.visible)]));
    faces.head := faces.head.next;
  until faces.head = temp;
end;

procedure TDelaunayTri.PrintOut(v: PVertex);
begin
  io.Dbp(Format('Head vertex %d = %6x :', [v.vnum, Integer(v)]));
  PrintVertices;
  PrintEdges;
  PrintFaces;
end;

procedure TDelaunayTri.PrintPoint(p: PVertex);
begin
  io.Dbp(Format(#9'%d', [p.v.x, p.v.y, p.v.z]));
  io.Dbp('');
end;

procedure TDelaunayTri.PrintVertices;
var
  temp: PVertex;
begin
  io.Dbp('Vertex List');
  temp := vertices.head;
  if vertices.head <> nil then
  repeat
    io.Dbp(Format('  addr %6x'#9, [Integer(vertices.head)]));
    io.Dbp(Format('  vnum %4d', [vertices.head.vnum]));
    io.Dbp(Format('   (%6d, %6d, %6d)',
      [vertices.head.v.x, vertices.head.v.y, vertices.head.v.z]));
    io.Dbp(Format('   active:%3d', [Ord(vertices.head.onhull)]));
    io.Dbp(Format('   dup:%5x', [Integer(vertices.head.duplicate)]));
    io.Dbp(Format('   mark:%2d', [Ord(vertices.head.mark)]));
    vertices.head := vertices.head.next;
  until vertices.head = temp;
end;

{$EndRegion}

end.

