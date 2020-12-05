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
unit Oz.Solid.Boolean;

interface

{$Region 'Uses'}

uses
  System.Classes, System.SysUtils, System.Types, System.UITypes, System.Math,
  System.Math.Vectors, Oz.SGL.Collections;

{$EndRegion}

{$T+}

{$Region 'T2di'}

type

  T2di = record
    x, y: Integer;
    function Plus(const p: T2di): T2di;
    function Minus(const p: T2di): T2di;
    function ScaledBy(s: Integer): T2di;
    function Dot(const p: T2di): Int64;
    function Cross(const p: T2di): Int64;
    function Equals(const p: T2di): Boolean;
  end;

{$EndRegion}

// t lies inside [a, b)
function AngleInside(const t, a, b: T2di): Boolean; inline;
// a > b
function Gt(const a, b: T2di): Boolean; inline;
// a < b
function Ls(const a, b: T2di): Boolean; inline;
// a >= b
function Ge(const a, b: T2di): Boolean; inline;
// a <= b
function Le(const a, b: T2di): Boolean; inline;
// if a < b then a else b
function Ymin(const a, b: T2di): T2di; inline;
// if a > b then a else b
function Ymax(const a, b: T2di): T2di; inline;
function Cross(const vp, vc, vn: T2di): Int64; inline;
function IsLeft(const v, v0, v1: T2di): Boolean; inline;

implementation

function AngleInside(const t, a, b: T2di): Boolean;
begin
  if a.Cross(b) >= 0 then
  begin
    if (a.Cross(t) >= 0) and (t.Cross(b) > 0) then
      exit(True);
  end
  else
  begin
    if (a.Cross(t) >= 0) or (t.Cross(b) > 0) then
      exit(True);
  end;
  Result := False;
end;

function Gt(const a, b: T2di): Boolean;
begin
  Result := (a.y > b.y) or (a.y = b.y) and (a.x > b.x);
end;

function Ls(const a, b: T2di): Boolean;
begin
  Result := (a.y < b.y) or (a.y = b.y) and (a.x < b.x);
end;

function Ge(const a, b: T2di): Boolean;
begin
  Result := (a.y > b.y) or (a.y = b.y) and (a.x >= b.x);
end;

function Le(const a, b: T2di): Boolean;
begin
  Result := (a.y < b.y) or (a.y = b.y) and (a.x <= b.x);
end;

function Ymin(const a, b: T2di): T2di;
begin
  if Ls(a, b) then
    Result := a
  else
    Result := b;
end;

function Ymax(const a, b: T2di): T2di;
begin
  if Gt(a, b) then
    Result := a
  else
    Result := b;
end;

function Cross(const vp, vc, vn: T2di): Int64;
begin
   Result := vp.Minus(vc).Cross(vn.Minus(vc));
end;

function IsLeft(const v, v0, v1: T2di): Boolean;
begin
  if v1.y = v.y then
    exit(v.x < v1.x);
  if v0.y = v.y then
    exit(v.x < v0.x);
  if ls(v1, v0) then
    Result := Cross(v0, v1, v) > 0
  else
    Result := Cross(v1, v0, v) > 0;
end;

{$Region 'T2di'}

function T2di.Plus(const p: T2di): T2di;
begin
  Result.x := x + p.x;
  Result.y := y + p.y;
end;

function T2di.Minus(const p: T2di): T2di;
begin
  Result.x := x - p.x;
  Result.y := y - p.y;
end;

function T2di.ScaledBy(s: Integer): T2di;
begin
  Result.x := x * s;
  Result.y := y * s;
end;

function T2di.Dot(const p: T2di): Int64;
begin
  Result := x * p.x + y * p.y;
end;

function T2di.Cross(const p: T2di): Int64;
begin
  Result := Int64(Self.x) * Int64(p.y) - Int64(Self.y) * Int64(p.x);
end;

function T2di.Equals(const p: T2di): Boolean;
begin
  Result := (Self.x = p.x) and (Self.y = p.y);
end;

{$EndRegion}

end.

