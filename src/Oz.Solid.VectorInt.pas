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
unit Oz.Solid.VectorInt;

interface

{$T+}

const
  // ranges for the integer coordinates
  INT20_MAX = 524287;
  INT20_MIN = -524288;

{$Region 'T2i'}

type
  P2i = ^T2i;
  T2i = record
  var
    x, y: Integer;
  public
    // t lies inside [a, b)
    class function AngleInside(const t, a, b: T2i): Boolean; inline; static;
    // a > b
    class function Gt(const a, b: T2i): Boolean; inline; static;
    // a < b
    class function Ls(const a, b: T2i): Boolean; inline; static;
    // a >= b
    class function Ge(const a, b: T2i): Boolean; inline; static;
    // a <= b
    class function Le(const a, b: T2i): Boolean; inline; static;
    // if a < b then a else b
    class function Ymin(const a, b: T2i): T2i; inline; static;
    // if a > b then a else b
    class function Ymax(const a, b: T2i): T2i; inline; static;
    // Returns the cross product
    class function Cross(const vp, vc, vn: T2i): Int64; overload; inline; static;
    // Returns the orientation vectors
    class function IsLeft(const v, v0, v1: T2i): Boolean; inline; static;
    // self + p
    function Plus(const p: T2i): T2i;
    // self - p
    function Minus(const p: T2i): T2i;
    // self * s
    function ScaledBy(s: Integer): T2i;
    // Returns the dot product
    function Dot(const p: T2i): Int64;
    // Returns the cross product
    function Cross(const p: T2i): Int64; overload;
    // self = p
    function Equals(const p: T2i): Boolean;
  end;

{$EndRegion}

implementation

{$Region 'T2i'}

class function T2i.AngleInside(const t, a, b: T2i): Boolean;
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

class function T2i.Gt(const a, b: T2i): Boolean;
begin
  Result := (a.y > b.y) or (a.y = b.y) and (a.x > b.x);
end;

class function T2i.Ls(const a, b: T2i): Boolean;
begin
  Result := (a.y < b.y) or (a.y = b.y) and (a.x < b.x);
end;

class function T2i.Ge(const a, b: T2i): Boolean;
begin
  Result := (a.y > b.y) or (a.y = b.y) and (a.x >= b.x);
end;

class function T2i.Le(const a, b: T2i): Boolean;
begin
  Result := (a.y < b.y) or (a.y = b.y) and (a.x <= b.x);
end;

class function T2i.Ymin(const a, b: T2i): T2i;
begin
  if Ls(a, b) then
    Result := a
  else
    Result := b;
end;

class function T2i.Ymax(const a, b: T2i): T2i;
begin
  if Gt(a, b) then
    Result := a
  else
    Result := b;
end;

class function T2i.Cross(const vp, vc, vn: T2i): Int64;
begin
   Result := vp.Minus(vc).Cross(vn.Minus(vc));
end;

class function T2i.IsLeft(const v, v0, v1: T2i): Boolean;
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

function T2i.Plus(const p: T2i): T2i;
begin
  Result.x := x + p.x;
  Result.y := y + p.y;
end;

function T2i.Minus(const p: T2i): T2i;
begin
  Result.x := x - p.x;
  Result.y := y - p.y;
end;

function T2i.ScaledBy(s: Integer): T2i;
begin
  Result.x := x * s;
  Result.y := y * s;
end;

function T2i.Dot(const p: T2i): Int64;
begin
  Result := x * p.x + y * p.y;
end;

function T2i.Cross(const p: T2i): Int64;
begin
  Result := Int64(Self.x) * Int64(p.y) - Int64(Self.y) * Int64(p.x);
end;

function T2i.Equals(const p: T2i): Boolean;
begin
  Result := (Self.x = p.x) and (Self.y = p.y);
end;

{$EndRegion}

end.

