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
  Oz.SGL.Collections,
  Oz.Solid.Types;

{$EndRegion}

{$T+}

{$Region 'types'}

const
  PMAX = 1000;  // Max # of pts in polygon

type
  tInFlag = (Pin, Qin, Unknown);

  tPointi = record
    x, y: Integer
  end;

  tPointd = record
    x, y: Double;
  end;

  // type integer polygon
  tPolygoni = array [0 .. PMAX - 1] of tPointi;

{$EndRegion}

procedure ClosePostscript();
procedure PrintSharedSeg(p, q: tPointd);
function Dot(a, b: tPointi): double;
function AreaSign(a, b, c: tPointi): Integer;
function SegSegInt(a, b, c, d: tPointi; p, q: tPointd): char;
function ParallelInt(a, b, c, d: tPointi; p, q: tPointd): char;
function Between(a, b, c: tPointi): Boolean;
procedure Assigndi(p: tPointd; a: tPointi);
procedure SubVec(a, b, c: tPointi);
function LeftOn(a, b, c: tPointi): Boolean;
function Left(a, b, c: tPointi): Boolean;
procedure PrintPoly(n: Integer; P: tPolygoni);

// P has n vertices, Q has m vertices.
procedure ConvexIntersect(P, Q: tPolygoni; n, m: Integer);

function InOut(p: tPointd; inflag: tInFlag; aHB, bHA: Integer): tInFlag;
function Advance(a: Integer; var aa: PInteger;
  n: Integer; inside: Boolean; v: tPointi): Integer;
procedure OutputPolygons();

implementation

{$Region ''}

procedure ClosePostscript();
begin

end;

procedure PrintSharedSeg(p, q: tPointd);
begin

end;

function Dot(a, b: tPointi): double;
begin

end;

function AreaSign(a, b, c: tPointi): Integer;
begin

end;

function SegSegInt(a, b, c, d: tPointi; p, q: tPointd): char;
begin

end;

function ParallelInt(a, b, c, d: tPointi; p, q: tPointd): char;
begin

end;

function Between(a, b, c: tPointi): Boolean;
begin

end;

procedure Assigndi(p: tPointd; a: tPointi);
begin

end;

procedure SubVec(a, b, c: tPointi);
begin

end;

function LeftOn(a, b, c: tPointi): Boolean;
begin

end;

function Left(a, b, c: tPointi): Boolean;
begin

end;

procedure PrintPoly(n: Integer; P: tPolygoni);
begin

end;

procedure ConvexIntersect(P, Q: tPolygoni; n, m: Integer);
var
  a, b: Integer;       // indices on P and Q (resp.)
  a1, b1: Integer;     // a-1, b-1 (resp.)
  A_, B_: tPointi;     // directed edges on P and Q (resp.)
  cross: Integer;      // sign of z-component of A x B
  bHA, aHB: Integer;   // b in H(A); a in H(b).
  Origin: tPointi;
  p_: tPointd;         // double point of intersection
  q_: tPointd;         // second point of intersection
  inflag: tInFlag;     // {Pin, Qin, Unknown}: which inside
  aa, ba: Integer;     // # advances on a & b indices (after 1st inter.)
  FirstPoint: Boolean; // Is this the first point? (used to initialize).
  p0: tPointd;         // The first point.
  code: Integer;       // SegSegInt return code.
begin
  Origin.x := 0;
  Origin.y := 0;
  // Initialize variables.
  a := 0; b := 0; aa := 0; ba := 0;
  inflag := Unknown;
  FirstPoint := TRUE;

  repeat
    // Dbp('%%Before Advances:a=%d, b=%d; aa=%d, ba=%d; inflag=%d\n', a, b, aa, ba, inflag);*/
    // Computations of key variables.
    a1 := (a + n - 1) mod n;
    b1 := (b + m - 1) mod m;

    SubVec( P[a], P[a1], A_ );
    SubVec( Q[b], Q[b1], B_ );

    cross := AreaSign( Origin, A_, B_);
    aHB := AreaSign(Q[b1], Q[b], P[a]);
    bHA := AreaSign(P[a1], P[a], Q[b]);
    Dbp('%%cross=%d, aHB=%d, bHA=%d\n', [cross, aHB, bHA]);

    // If A_ & B_ intersect, update inflag.
    code := SegSegInt(P[a1], P[a], Q[b1], Q[b], p_, q_);
    Dbp('%%SegSegInt: code = %c\n', [code]);
    if (code = '1') or (code = 'v') then
    begin
       if (inflag = Unknown) and FirstPoint then
       begin
          aa := 0; ba := 0;
          FirstPoint := FALSE;
          p0[X] := p_[X];
          p0[Y] := p_[Y];
          Dbp('%8.2lf %8.2lf moveto\n', [p0[X], p0[Y]]);
       end;
       inflag := InOut(p_, inflag, aHB, bHA);
       Dbp('%%InOut sets inflag=%d\n', [inflag]);
    end;

    // Advance rule

    // Special case: A_ & B_ overlap and oppositely oriented.
    if (code = 'e' ) and (Dot( A_, B_ ) < 0) then
      PrintSharedSeg( p_, q_ ), exit(EXIT_SUCCESS);

    // Special case: A_ & B_ parallel and separated.
    if (cross = 0) and ( aHB < 0) and ( bHA < 0 ) then
    begin
      Dbp('%%P and Q are disjoint.\n');
      exit(EXIT_SUCCESS);
    end
    // Special case: A_ & B_ collinear. */
    else if (cross = 0) and ( aHB = 0) and (bHA = 0) then
    begin
      // Advance but do not output point. */
      if inflag = Pin then
        b := Advance(b, @ba, m, inflag = Qin, Q[b])
      else
        a := Advance(a, @aa, n, inflag = Pin, P[a]);
   end
   // Generic cases. */
   else if cross >= 0 then
   begin
     if bHA > 0 then
       a := Advance( a, &aa, n, inflag = Pin, P[a])
     else
       b := Advance( b, &ba, m, inflag = Qin, Q[b]);
    end;
    else // if ( cross < 0 ) */begin
       if ( aHB > 0)
          b = Advance( b, &ba, m, inflag = Qin, Q[b] );
       else
          a = Advance( a, &aa, n, inflag = Pin, P[a] );
    end;
    Dbp('%%After advances:a=%d, b=%d; aa=%d, ba=%d; inflag=%d\n', a, b, aa, ba, inflag);

  // Quit when both adv. indices have cycled, or one has cycled twice. */
  until ( ((aa < n) or (ba < m)) and (aa < 2*n) and (ba < 2*m) );

  if not FirstPoint then
    // If at least one point output, close up. */
    Dbp('%8.2lf %8.2lf lineto\n', p0[X], p0[Y]);

  // Deal with special cases: not implemented. */
  if inflag = Unknown then
    Dbp('%%The boundaries of P and Q do not cross.\n');
end;

{$EndRegion}

end.

