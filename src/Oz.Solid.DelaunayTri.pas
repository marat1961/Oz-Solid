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
  System.Classes, System.SysUtils, Oz.Solid.VectorInt, Oz.Solid.Svg;

{$EndRegion}

{$T+}

const
  // Define flags
  ONHULL = True;
  REMOVED = True;
  VISIBLE = True;
  PROCESSED = True;
  SAFE = 1000000;    // Range of safe coord values

type
  // Define structures for vertices, edges and faces
  tVertex = ^tsVertex;
  tEdge = ^tsEdge;
  tFace = ^tsFace;

  Ti3 = record
    x, y, z: Integer;
  end;

  tsVertex = record
    v: Ti3;
    vnum: Integer;
    duplicate: tEdge;  // pointer to incident cone edge (or nil)
    onhull: Boolean;   // T iff point on hull.
    mark: Boolean;     // T iff point already processed.
    next: tVertex;
    prev: tVertex;
  end;

  tsEdge = record
    adjface: array [0..1] of tFace;
    endpts: array [0..1] of tVertex;
    newface: tFace;     // pointer to incident cone face.
    delete: Boolean;    // T iff edge should be delete.
    next: tEdge;
    prev: tEdge;
  end;

  tsFace = record
    edge: array [0..2] of tEdge;
    vertex: array [0..2] of tVertex;
    visible: Boolean;   // T iff face visible from new point.
    lower: Boolean;     // T iff on the lower hull
    next: tFace;
    prev: tFace;
  end;

  TDelaunayTri = class
    function MakeNullVertex: tVertex;
    procedure ReadVertices;
    procedure Print;
    procedure SubVec(a, b, c: Ti3);
    procedure DoubleTriangle;
    procedure ConstructHull;
    function AddOne(p: tVertex): Boolean;
    function VolumeSign(f: tFace; p: tVertex): Integer;
    function Volumei(f: tFace; p: tVertex): Integer;
    function MakeConeFace(e: tEdge; p: tVertex): tFace;
    procedure MakeCcw(f: tFace; e: tEdge; p: tVertex);
    function MakeNullEdge: tEdge;
    function MakeNullFace: tFace;
    function MakeFace(v0, v1, v2: tVertex; f: tFace): tFace;
    procedure CleanUp;
    procedure CleanEdges;
    procedure CleanFaces;
    procedure CleanVertices;
    function Collinear(a, b, c: tVertex): Boolean;
    function Normz(f: tFace): Integer;
    procedure CheckEuler(V, E, F: Integer);
    procedure PrintPoint(p: tVertex);
    procedure Checks;
    procedure Consistency;
    procedure Convexity;
    procedure PrintOut(v: tVertex);
    procedure PrintVertices;
    procedure PrintEdges;
    procedure PrintFaces;
    procedure LowerFaces;
  end;

implementation

var
  vertices: tVertex = nil;
  edges: tEdge = nil;
  faces: tFace = nil;
  debug: Boolean = False;
  check: Boolean = False;

{ TDelaunayTri }

function TDelaunayTri.AddOne(p: tVertex): Boolean;
begin

end;

procedure TDelaunayTri.CheckEuler(V, E, F: Integer);
begin

end;

procedure TDelaunayTri.Checks;
begin

end;

procedure TDelaunayTri.CleanEdges;
begin

end;

procedure TDelaunayTri.CleanFaces;
begin

end;

procedure TDelaunayTri.CleanUp;
begin

end;

procedure TDelaunayTri.CleanVertices;
begin

end;

function TDelaunayTri.Collinear(a, b, c: tVertex): Boolean;
begin

end;

procedure TDelaunayTri.Consistency;
begin

end;

procedure TDelaunayTri.ConstructHull;
begin

end;

procedure TDelaunayTri.Convexity;
begin

end;

procedure TDelaunayTri.DoubleTriangle;
begin

end;

procedure TDelaunayTri.LowerFaces;
begin

end;

procedure TDelaunayTri.MakeCcw(f: tFace; e: tEdge; p: tVertex);
begin

end;

function TDelaunayTri.MakeConeFace(e: tEdge; p: tVertex): tFace;
begin

end;

function TDelaunayTri.MakeFace(v0, v1, v2: tVertex; f: tFace): tFace;
begin

end;

function TDelaunayTri.MakeNullEdge: tEdge;
begin

end;

function TDelaunayTri.MakeNullFace: tFace;
begin

end;

function TDelaunayTri.MakeNullVertex: tVertex;
begin

end;

function TDelaunayTri.Normz(f: tFace): Integer;
begin

end;

procedure TDelaunayTri.Print;
begin

end;

procedure TDelaunayTri.PrintEdges;
begin

end;

procedure TDelaunayTri.PrintFaces;
begin

end;

procedure TDelaunayTri.PrintOut(v: tVertex);
begin

end;

procedure TDelaunayTri.PrintPoint(p: tVertex);
begin

end;

procedure TDelaunayTri.PrintVertices;
begin

end;

procedure TDelaunayTri.ReadVertices;
begin

end;

procedure TDelaunayTri.SubVec(a, b, c: Ti3);
begin

end;

function TDelaunayTri.Volumei(f: tFace; p: tVertex): Integer;
begin

end;

function TDelaunayTri.VolumeSign(f: tFace; p: tVertex): Integer;
begin

end;

end.

