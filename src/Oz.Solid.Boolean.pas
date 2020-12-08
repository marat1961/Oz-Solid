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
  System.Math.Vectors, Oz.SGL.Heap, Oz.SGL.Collections, Oz.Solid.Types;

{$EndRegion}

{$T+}

const
  // ranges for the integer coordinates
  INT20_MAX = 524287;
  INT20_MIN = -524288;

{$Region 'Pointers'}

type
  P2Polygon = ^T2Polygon;
  P2Contour = ^T2Contour;

{$EndRegion}

{$Region 'T2i'}

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
    class function Cross(const vp, vc, vn: T2i): Int64; overload; inline; static;
    class function IsLeft(const v, v0, v1: T2i): Boolean; inline; static;

    function Plus(const p: T2i): T2i;
    function Minus(const p: T2i): T2i;
    function ScaledBy(s: Integer): T2i;
    function Dot(const p: T2i): Int64;
    function Cross(const p: T2i): Int64; overload;
    function Equals(const p: T2i): Boolean;
  end;

{$EndRegion}

{$Region 'T2Vertex'}

  // Vertex coordinates
  TVertexPoint = record
  case Integer of
    0: (p2d: T2dPoint);
    1: (p2i: T2i);
  end;

  P2Vertex = ^T2Vertex;

  PVertexLink = ^TVertexLink;
  TVertexLink = record
  type
    TLinkFlag = (fIn, fValid, fFirst);
    TLinkFlags = set of TLinkFlag;
  var
    n, p: PVertexLink; // neighbours
    vn: P2Vertex;      // parent vnode
    dx: Integer;       // dx and dy determine descriptor angle
    dy: Integer;
    m_flags: TLinkFlags;
    shared: P2Vertex;  // shared edge
  public
    procedure SetIn(value: Boolean);
    function IsIn: Boolean;
    procedure SetValid(value: Boolean);
    function IsValid: Boolean;
    procedure SetFirst(value: Boolean);
    function IsFirst: Boolean;
    function nxt: PVertexLink;
    class function Compare(const a, b: PVertexLink): Integer; static;
  end;

  TemporaryFields = record
  case Integer of
    0: (lnk: record i, o: PVertexLink end;);
    1: (i: Integer);
    2: (v: Pointer);
    3: (vn: P2Vertex);
  end;

  T2Vertex = record
  const
    RESERVED = $00FF;
    E_MASK   = $0007; // edge label mask
    E_MARK   = $0008; // vertex is already included into result
    E_FST    = $0010; // vertex belongs to 1st PAREA
  var
    next, prev: P2Vertex;
    Flags: Cardinal;
    v: TVertexPoint;
    t: TemporaryFields;
  public
    class function New(const pt: T2i): P2Vertex; static;
    procedure Incl(after: P2Vertex);
    procedure Excl;
    function SetBits(mask, s: Cardinal): Cardinal;
  end;

{$EndRegion}

{$Region 'T2Contour'}

  T2Contour = record
  const
    RESERVED = $00FF;
    ORIENT   = $0100;
    DIR      = $0100;
    INV      = $0000;
  type
    ELABEL = (
      E_INSIDE,
      E_OUTSIDE,
      E_SHARED1,
      E_SHARED2,
      E_SHARED3,
      E_UNKNOWN);
    PLABEL = (
      P_OUTSIDE,
      P_INSIDE,
      P_UNKNOWN,
      P_ISECTED);
  var
    next: P2Contour;  // next contour
    head: P2Vertex;   // first vertex
    Count: Cardinal;  // number of vertices
    Flags: Cardinal;
    vMin: TVertexPoint;
    vMax: TVertexPoint;
  private
    function SetBits(mask, s: Cardinal): Cardinal;
  public
    class function New(const g: T2i): P2Contour; static;
    class procedure Del(var pline: P2Contour); static;
    function IsOuter: Boolean;
    function Copy(makeLinks: Boolean = False): P2Contour;
    class procedure Incl(var pline: P2Contour; const g: T2i); static;
    // calculate orientation and bounding box
    // removes points lying on the same line
    // returns if contour is valid, i.e. Count >= 3 and Area <> 0
    function Prepare: Boolean;
    // invert contour
    procedure Invert;
    // put pline either into area or holes depending on its orientation
    class procedure Put(pline: P2Contour; var area: P2Polygon; var holes: P2Contour); static;
  end;

{$EndRegion}

{$Region 'T2Triangle'}

  P2Triangle = ^T2Triangle;
  T2Triangle = record
    v0: P2Vertex;
    v1: P2Vertex;
    v2: P2Vertex;
  end;

{$EndRegion}

{$Region 'T2Polygon: Polygon area'}

  TErrorNumber = (ecOk, ecNotEnoughMemory, ecIO, ecInvalidParameter, ecBool);

  T2Polygon = record
  type
    TBoolOp = (opUnion, opIntersection, opDifference, opXor);
  var
    f, b: P2Polygon;
    cntr: P2Contour;
    tria: P2Triangle;
    tnum: Cardinal;
  public
    class function New: P2Polygon; static;
    class procedure Del(var p: P2Polygon); static;
    function Copy: P2Polygon;
    procedure Excl;
    class function Bool(const _a, _b: P2Polygon; var r: P2Polygon;
      Op: TBoolOp): TErrorNumber; static;
    // PolyBoolean0 operates destructively on a and b
    class function Bool0(const a, b: P2Polygon; var r: P2Polygon;
      Op: TBoolOp): TErrorNumber; static;
    class function Triangulate(area: P2Polygon): Integer; static;
    class procedure InclParea(var list: P2Polygon; a: P2Polygon); static;
    class procedure InclPline(var list: P2Polygon; pline: P2Contour); static;
    class procedure InsertHoles(var list: P2Polygon; var holes: P2Contour); static;
    // check if coordinates are within 20 bit grid
    function CheckDomain: Boolean;
  end;

procedure Err(e: TErrorNumber);
function GridInPline(const p: P2i; const outer: P2Contour): Boolean;
function GridInParea(const p: P2i; const outer: P2Polygon): Boolean;
function PlineInPline(const c: P2Contour; const outer: P2Contour): Boolean;
function PlineInParea(const c: P2Contour; const outer: P2Polygon): Boolean;

{$EndRegion}

implementation

{$Region 'T2Segment'}

type
  PVertexLinkHeap = ^TVertexLinkHeap;
  TVertexLinkHeap = record
    region: TSegmentedRegion;
    constructor From(BlockSize: Cardinal);
    function Get(Clear: Boolean): PVertexLink;
  end;

{$EndRegion}

{$Region 'T2Segment'}

  P2Segment = ^T2Segment;
  T2Segment = record
    l: P2Vertex;       // left point
    r: P2Vertex;       // right point
    n, p: P2Segment;   // next, prev in main active list
    m_bRight: Boolean; // l.next = r
  end;

{$EndRegion}

{$Region 'TBoolContext'}

  TBoolContext = record
  type
    INS_PROC = procedure(var list: PVertexLink; vn: P2Vertex;
      parm: PVertexLinkHeap);
  public
    constructor From(InsertProc: INS_PROC; InsertParm: Pointer);
    procedure Sweep(aSegms: P2Segment; nSegms: Cardinal);
  end;

constructor TBoolContext.From(InsertProc: INS_PROC; InsertParm: Pointer);
begin

end;

procedure TBoolContext.Sweep(aSegms: P2Segment; nSegms: Cardinal);
begin

end;

{$EndRegion}

{$Region 'Subroutines'}

procedure Err(e: TErrorNumber);
var
  s: string;
begin
  case e of
    ecOk: exit;
    ecNotEnoughMemory: s := 'Not enough memory';
    ecIO: s := 'File I/O error';
    ecInvalidParameter: s := 'Inavlid parameter';
    ecBool: s := 'Boolean error';
  end;
  raise ESolidError.Create(s);
end;

procedure AdjustBox(pline: P2Contour; const pt: T2i);
begin
  if pline.vMin.p2d.x > pt.x then
    pline.vMin.p2d.x := pt.x;
  if pline.vMin.p2d.y > pt.y then
    pline.vMin.p2d.y := pt.y;
  if pline.vMax.p2d.x < pt.x then
    pline.vMax.p2d.x := pt.x;
  if pline.vMax.p2d.y < pt.y then
    pline.vMax.p2d.y := pt.y;
end;

function GridInBox(const p: T2i; const c: P2Contour): Boolean;
begin
  Result := (p.x > c.vMin.p2i.x) and (p.y > c.vMin.p2i.y) and
            (p.x < c.vMax.p2i.x) and (p.y < c.vMax.p2i.y);
end;

function BoxInBox(const c1, c2: P2Contour): Boolean;
begin
  Result := (c1.vMin.p2i.x >= c2.vMin.p2i.x) and
            (c1.vMin.p2i.y >= c2.vMin.p2i.y) and
            (c1.vMax.p2i.x <= c2.vMax.p2i.x) and
            (c1.vMax.p2i.y <= c2.vMax.p2i.y);
end;

function GridInPline(const p: P2i; const outer: P2Contour): Boolean;
var
  vn: P2Vertex;
  inside: Boolean;
  vc, vp: T2i;
begin
  if outer = nil then exit(False);
  if not GridInBox(p^, outer) then exit(False);
  vn := outer.head;
  inside := false;
  repeat
    vc := vn.v.p2i;
    vp := vn.prev.v.p2i;
    if (vc.y <= p.y) and (p.y < vp.y) and
       (Int64((vp.y - vc.y) * (p.x - vc.x)) < Int64((p.y - vc.y) * (vp.x - vc.x))) then
      inside := not inside
    else if (vp.y <= p.y) and (p.y < vc.y) and
       (Int64((vp.y - vc.y) * (p.x - vc.x)) > Int64((p.y - vc.y) * (vp.x - vc.x))) then
      inside := not inside;
    vn := vn.next;
  until vn = outer.head;
  Result := inside;
end;

function GridInParea(const p: P2i; const outer: P2Polygon): Boolean;
label
  Proceed;
var
  pa: P2Polygon;
  curc: P2Contour;
begin
  pa := outer;
  if pa = nil then exit(False);
  assert((p <> nil) and (pa <> nil));
  repeat
    curc := pa.cntr;
    if GridInPline(p, curc) then
    begin
      curc := curc.next;
      while curc <> nil do
      begin
        if GridInPline(p, curc) then
          goto Proceed;
        curc := curc.next;
      end;
      exit(True);
    end;
    Proceed: ;
    pa := pa.f;
  until pa = outer;
  Result := False;
end;

function PlineInPline(const c: P2Contour; const outer: P2Contour): Boolean;
begin
  assert(c <> nil);
  Result := (outer <> nil) and BoxInBox(c, outer) and
    GridInPline(@c.head.v.p2i, outer);
end;

function PlineInParea(const c: P2Contour; const outer: P2Polygon): Boolean;
label
  Proceed;
var
  pa: P2Polygon;
  curc: P2Contour;
begin
  pa := outer;
  if pa = nil then exit(False);
  assert((c <> nil) and (pa <> nil));
  repeat
    curc := pa.cntr;
    if PlineInPline(c, curc) then
    begin
      curc := curc.next;
      while curc <> nil do
      begin
        if PlineInPline(c, curc) then
          goto Proceed;
        curc := curc.next;
      end;
      exit(True);
    end;
    Proceed: ;
    pa := pa.f;
  until pa = outer;
  Result := False;
end;

{$EndRegion}

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

{$Region 'TVertexLink'}

procedure TVertexLink.SetIn(value: Boolean);
begin
  if value then
    Include(m_flags, fIn)
  else
    Exclude(m_flags, fIn);
end;

function TVertexLink.IsIn: Boolean;
begin
  Result := fIn in m_flags;
end;

procedure TVertexLink.SetValid(value: Boolean);
begin
  if value then
    Include(m_flags, fValid)
  else
    Exclude(m_flags, fValid);
end;

function TVertexLink.IsValid: Boolean;
begin
  Result := fValid in m_flags;
end;

procedure TVertexLink.SetFirst(value: Boolean);
begin
  if value then
    Include(m_flags, fFirst)
  else
    Exclude(m_flags, fFirst);
end;

function TVertexLink.IsFirst: Boolean;
begin
  Result := fFirst in m_flags;
end;

function TVertexLink.nxt: PVertexLink;
begin
  Result := n;
end;

function GetQuadrant(dx, dy: Integer): Integer;
begin
  assert((dx <> 0) or (dy <> 0));
  if (dx > 0) and (dy >= 0) then exit(0);
  if (dx <= 0) and (dy >  0) then exit(1);
  if (dx < 0) and (dy <= 0) then exit(2);
  assert((dx >= 0) and (dy < 0));
  Result := 3;
end;

class function TVertexLink.Compare(const a, b: PVertexLink): Integer;
var
  aq, bq: Integer;
  nSign: Int64;
begin
  aq := GetQuadrant(a.dx, a.dy);
  bq := GetQuadrant(b.dx, b.dy);
  if aq <> bq then
    exit(aq - bq);
  nSign := Int64(a.dy * b.dx) - Int64(a.dx * b.dy);
  if nSign < 0 then
    exit(-1);
  if nSign > 0 then
    exit(1);
  Result := Ord(a.IsFirst) - Ord(b.IsFirst);
end;

{$EndRegion}

{$Region 'T2Vertex'}

class function T2Vertex.New(const pt: T2i): P2Vertex;
var
  r: P2Vertex;
begin
  GetMem(r, sizeof(T2Vertex));
  if r = nil then Err(ecNotEnoughMemory);
  r.v.p2i := pt;
  r.prev := r;
  r.next := r;
  Result := r;
end;

procedure T2Vertex.Incl(after: P2Vertex);
begin
  next := after.next;
  next.prev := @Self;
  prev := after;
end;

procedure T2Vertex.Excl;
begin
  prev.next := next;
  next.prev := prev;
end;

function T2Vertex.SetBits(mask, s: Cardinal): Cardinal;
begin
  Result := (Flags and not mask) or (s and mask);
end;

{$EndRegion}

{$Region 'T2Contour'}

class function T2Contour.New(const g: T2i): P2Contour;
var
  r: P2Contour;
begin
  GetMem(r, sizeof(T2Contour));
  if r = nil then Err(ecNotEnoughMemory);
  try
    r.head := T2Vertex.New(g);
  except
    FreeMem(r);
    raise;
  end;
  r.vMax.p2i := g;
  r.vMin.p2i := g;
  r.Count := 1;
  Result := r;
end;

function T2Contour.IsOuter: Boolean;
begin
  Result := (Flags and ORIENT) = DIR;
end;

class procedure T2Contour.Del(var pline: P2Contour);
var
  vn: P2Vertex;
begin
  if pline = nil then exit;
  vn := pline.head.next;
  while vn <> pline.head do
  begin
    vn.Excl();
    FreeMem(vn);
    vn := pline.head.next;
  end;
  FreeMem(vn);
  FreeMem(pline);
  pline := nil;
end;

function T2Contour.Copy(makeLinks: Boolean): P2Contour;
var
  dst: P2Contour;
  vn, p: P2Vertex;
begin
  dst := nil;
  vn := head;
  try
    repeat
      Incl(dst, vn.v.p2i);
      if makeLinks then
      begin
        p := dst.head.prev;
        vn.t.vn := p;
        p.t.vn := vn;
      end;
      vn := vn.next;
    until vn = head;
  except
    Del(&dst);
    raise;
  end;
    dst.Count := Count;
    dst.Flags := Flags;
    dst.vMin.p2i := vMin.p2i;
    dst.vMax.p2i := vMax.p2i;
  Result := dst;
end;

procedure InclPlineVnode(c: P2Contour; vn: P2Vertex);
begin
  Assert((vn <> nil) and (c <> nil));
  vn.Incl(c.head.prev);
  Inc(c.Count);
  AdjustBox(c, vn.v.p2i);
end;

class procedure T2Contour.Incl(var pline: P2Contour; const g: T2i);
begin
  if pline = nil then
    pline := T2Contour.New(g)
  else
    InclPlineVnode(pline, T2Vertex.New(g));
end;

function PointOnLine(const a, b, c: T2i): Boolean;
begin
  Result :=
    Int64((b.x - a.x) * (c.y - b.y)) =
    Int64((b.y - a.y) * (c.x - b.x));
end;

function T2Contour.Prepare: Boolean;
var
  p, c, n: P2Vertex;
  test, tests: Integer;
  nArea: Int64;
begin
  vMin.p2i.x := head.v.p2i.x;
  vMax.p2i.x := head.v.p2i.x;
  vMin.p2i.y := head.v.p2i.y;
  vMax.p2i.y := head.v.p2i.y;
  // remove coincident vertices and those lying on the same line
  p := head;
  c := p.next;
  tests := Count;
  test := 0;
  while test < tests do
  begin
    n := c.next;
    if PointOnLine(p.v.p2i, c.v.p2i, n.v.p2i) then
    begin
      Inc(tests);
      if n = head then
        Inc(tests);
      Dec(Count);
      if Count < 3 then
        exit(False);
      if c = head then
        head := p;
      c.Excl;
      FreeMem(c);
      c := p;
      p := p.prev;
    end
    else
    begin
      p := c;
      c := n;
    end;
    Inc(test);
  end;
  c := head;
  p := c.prev;
  nArea := 0;
  repeat
    nArea := nArea + Int64((p.v.p2i.x - c.v.p2i.x) * (p.v.p2i.y + c.v.p2i.y));
    AdjustBox(@Self, c.v.p2i);
    p := c;
    c := c.next;
  until c = head;
  if nArea = 0 then
    exit(False);
  if nArea < 0 then
    Flags := SetBits(ORIENT, INV)
  else
    Flags := SetBits(ORIENT, DIR);
  Result := True;
end;

procedure T2Contour.Invert;
var
  vn, next: P2Vertex;
begin
  vn := head;
  repeat
    next := vn.next;
    vn.next := vn.prev;
    vn.prev := next;
    vn := next;
  until vn = head;
  Flags := Flags xor ORIENT;
end;

class procedure T2Contour.Put(pline: P2Contour; var area: P2Polygon;
  var holes: P2Contour);
begin
  assert(pline.next = nil);
  if pline.IsOuter then
    T2Polygon.InclPline(area, pline)
  else
  begin
    pline.next := holes;
    holes := pline;
  end;
end;

function T2Contour.SetBits(mask, s: Cardinal): Cardinal;
begin
  Result := (Flags and not mask) or (s and mask);
end;

{$EndRegion}

{$Region 'T2Polygon'}

class function T2Polygon.New: P2Polygon;
var
  r: P2Polygon;
begin
  GetMem(r, sizeof(T2Polygon));
  if r = nil then Err(ecNotEnoughMemory);
  r.f := r;
  r.b := r;
  Result := r;
end;

procedure ClearArea(a: P2Polygon);
var
  p: P2Contour;
begin
  assert(a <> nil);
  p := a.cntr;
  while p <> nil do
  begin
    a.cntr := p.next;
    T2Contour.Del(p);
    p := a.cntr;
  end;
  FreeMem(a.tria);
  a.tria := nil;
  a.tnum := 0;
end;

class procedure T2Polygon.Del(var p: P2Polygon);
var
  q: P2Polygon;
begin
  if p = nil then exit;
  q := p.f;
  while q <> p do
  begin
    q.b.f := q.b;
    q.f.b := q.b;
    ClearArea(q);
    FreeMem(q);
    q := p.f;
  end;
  ClearArea(q);
  FreeMem(q);
  p := nil;
end;

function PareaCopy0(const area: P2Polygon): P2Polygon;
var
  dst: P2Polygon;
  i: Cardinal;
  td, ts: P2Triangle;
  pline: P2Contour;
begin
  dst := nil;
  try
    pline := area.cntr;
    while pline <> nil do
    begin
      T2Polygon.InclPline(dst, pline.Copy(True));
      pline := pline.next;
    end;
    if area.tria = nil then
      exit(dst);
    GetMem(dst.tria, area.tnum * sizeof(T2Triangle));
    if dst.tria = nil then
      err(ecNotEnoughMemory);
  except
    T2Polygon.Del(dst);
    raise;
  end;
  dst.tnum := area.tnum;
  td := dst.tria;
  ts := area.tria;
  for i := 0 to area.tnum - 1 do
  begin
    td.v0 := ts.v0.t.vn;
    td.v1 := ts.v1.t.vn;
    td.v2 := ts.v2.t.vn;
    td := P2Triangle(PByte(td) + sizeof(T2Triangle));
    ts := P2Triangle(PByte(ts) + sizeof(T2Triangle));
  end;
  Result := dst;
end;

function T2Polygon.Copy: P2Polygon;
var
  dst, src, di: P2Polygon;
begin
  dst := nil;
  src := @Self;
  try
    repeat
      di := PareaCopy0(src);
      InclParea(dst, di);
      src := src.f;
    until src = @Self;
  except
    Del(dst);
    raise;
  end;
  Result := dst;
end;

procedure T2Polygon.Excl;
begin
  b.f := f;
  f.b := b;
end;

class function T2Polygon.Bool(const _a, _b: P2Polygon; var r: P2Polygon;
  Op: TBoolOp): TErrorNumber;
var
  a, b: P2Polygon;
begin
  r := nil;
  if (_a = nil) and (_b = nil) then exit(ecOk);
  if _b = nil then
  begin
    Result := ecOk;
    if (_a <> nil) and (Op in [opUnion, opDifference, opXor]) then
    begin
      try
        r^ := _a.Copy^;
      except
        Result := ecBool;
      end;
    end;
    exit;
  end
  else if _a = nil then
  begin
    Result := ecOk;
    if Op in [opXor, opUnion] then
    begin
      try
        r := _b.Copy();
      except
        Result := ecBool;
      end;
    end;
    exit;
  end;

  a := nil;
  b := nil;
  if _a <> nil then
  begin
    a := _a.Copy;
    if a = nil then exit(ecNotEnoughMemory);
  end;
  if _b <> nil then
  begin
    b := _b.Copy();
    if b = nil then
    begin
      T2Polygon.Del(a);
      exit(ecNotEnoughMemory);
    end;
  end;
  Result := Bool0(a, b, r, Op);
  T2Polygon.Del(a);
  T2Polygon.Del(b);
end;

function IsFirst(const vn: T2Vertex): Boolean;
begin
  Result := (vn.Flags and T2Vertex.E_FST) <> 0;
end;

function IsMarked(const vn: T2Vertex): Boolean;
begin
  Result := (vn.Flags and T2Vertex.E_MARK) <> 0;
end;

procedure SetMarked(vn: P2Vertex);
begin
  vn.Flags := vn.Flags or T2Vertex.E_MARK;
end;

procedure SetFirst(vn: P2Vertex; first: Boolean);
begin
  if first then
    vn.Flags := vn.Flags or T2Vertex.E_MARK
  else
    vn.Flags := vn.Flags and not T2Vertex.E_MARK;
end;

procedure InitArea(area: P2Polygon; first: Boolean);
var
  pa: P2Polygon;
  pline: P2Contour;
  vn: P2Vertex;
begin
  pa := area;
  repeat
    pline := pa.cntr;
    while pline <> nil do
    begin
      pline.Flags := pline.SetBits(T2Contour.RESERVED, Ord(P_UNKNOWN));
      vn := pline.head;
      repeat
        vn.Flags := vn.SetBits(T2Vertex.RESERVED, Ord(E_UNKNOWN));
        SetFirst(vn, first);
        vn.t.lnk.i := nil;
        vn.t.lnk.o := nil;
        vn := vn.next
      until vn = pline.head;
      pline := pline.next;
    end;
    pa := pa.f;
  until pa = area;
end;

function VertCnt(const area: P2Polygon): Cardinal;
var
  pa: P2Polygon;
  pline: P2Contour;
  vn: P2Vertex;
begin
  if area = nil then exit(0);
  Result := 0;
  pa := area;
  repeat
    pline := pa.cntr;
    while pline = nil do
    begin
      vn := pline.head;
      repeat
        Inc(Result);
        vn := vn.next;
      until vn = pline.head;
      pline := pline.next;
    end;
    pa := pa.f;
  until pa = area;
end;

function Left(const a, b: T2i): Boolean;
begin
  Result := (a.x < b.x) or (a.x = b.x) and (a.y < b.y);
end;

procedure Area2Segms(area: P2Polygon; var pSegm: P2Segment);
var
  pa: P2Polygon;
  pline: P2Contour;
  vn: P2Vertex;
  s: P2Segment;
begin
  if area = nil then exit;
  pa := area;
  repeat
    pline := pa.cntr;
    while pline <> nil do
    begin
      vn := pline.head;
      repeat
        s := pSegm;
        Inc(pSegm, sizeof(T2Segment));

        s.m_bRight := Left(vn.v.p2i, vn.next.v.p2i);
        if s.m_bRight then
        begin
          s.l := vn;
          s.r := vn.next;
        end
        else
        begin
          s.r := vn;
          s.l := vn.next;
        end;
        vn := vn.next;
      until vn = pline.head;
      pline := pline.next;
    end;
    pa := pa.f;
  until pa = area;
end;

procedure InsertNode(var list: PVertexLink; vn: P2Vertex; parm: PVertexLinkHeap);
var
  i, o: PVertexLink;
  pHeap: PVertexLinkHeap;
begin
  if vn.t.lnk.i <> nil then // already tied
  begin
    assert(vn.t.lnk.o <> nil);
    exit;
  end;
  // tie into ring all segments which point (X,Y) was inserted into

  pHeap := PVertexLinkHeap(parm);
  i := pHeap.Get(true);
  o := pHeap.Get(true);
  i.SetIn(true);
  i.SetValid(false);
  o.SetIn(false);
  o.SetValid(false);
  i.vn := vn;
  o.vn := vn;

  if list = nil then
  begin
    list := o;
    o.n := o;
    o.p := o;
  end
  else
  begin
    o.p := list.p;
    o.p.n := o;
    o.n := list;
    list.p := o;
  end;
  i.p := o.p;
  o.p.n := i;
  i.n := o;
  o.p := i;
  vn.t.lnk.i := i;
  vn.t.lnk.o := o;
end;

procedure DoBoolean(a, b, r: P2Polygon; Op: T2Polygon.TBoolOp);
begin
end;

procedure RecalcCount(area: P2Polygon);
begin
end;

class function T2Polygon.Bool0(const a, b: P2Polygon; var r: P2Polygon;
  Op: TBoolOp): TErrorNumber;
var
  aSegms, pSegm: P2Segment;
  nSegms: Cardinal;
  pb: TVertexLinkHeap;
  bc: TBoolContext;
begin
  r := nil;
  assert(a.CheckDomain);
  assert(b.CheckDomain);
  aSegms := nil;
  Result := ecOk;
  try
    InitArea(a, true);
    InitArea(b, false);
    begin
      nSegms := VertCnt(a) + VertCnt(b);
      GetMem(aSegms, nSegms * sizeof(T2Segment));
      if aSegms = nil then err(ecNotEnoughMemory);
      pSegm := aSegms;
      Area2Segms(a, pSegm);
      Area2Segms(b, pSegm);

      assert(PByte(pSegm) = PByte(aSegms) + nSegms * sizeof(T2Segment));

      bc := TBoolContext.From(InsertNode, @pb);
      bc.Sweep(aSegms, nSegms);
    end;
    DoBoolean(a, b, r, Op);
    RecalcCount(a);
    RecalcCount(b);
  except
    Result := ecBool;
  end;
  FreeMem(aSegms);
end;

class function T2Polygon.Triangulate(area: P2Polygon): Integer;
begin
end;

class procedure T2Polygon.InclParea(var list: P2Polygon; a: P2Polygon);
begin
end;

class procedure T2Polygon.InclPline(var list: P2Polygon; pline: P2Contour);
begin
end;

class procedure T2Polygon.InsertHoles(var list: P2Polygon; var holes: P2Contour);
begin
end;

function Chk(x: INT32): Boolean;
begin
  Result := (INT20_MIN > x) or (x > INT20_MAX);
end;

function T2Polygon.CheckDomain: Boolean;
var
  pa: P2Polygon;
  pline: P2Contour;
begin
  pa := @Self;
  repeat
    pline := pa.cntr;
    while pline <> nil do
    begin
      if Chk(pline.vMin.p2i.x) or Chk(pline.vMin.p2i.y) or
        Chk(pline.vMax.p2i.x) or Chk(pline.vMax.p2i.y) then
        exit(False);
      pline := pline.next;
    end;
    pa := pa.f;
  until pa = @Self;
  Result := True;
end;

{$EndRegion}

{$Region 'TVertexLinkHeap'}

constructor TVertexLinkHeap.From(BlockSize: Cardinal);
var
  meta: PsgItemMeta;
begin
  meta := SysCtx.CreateMeta<TVertexLink>;
  region.Init(meta, BlockSize);
end;

function TVertexLinkHeap.Get(Clear: Boolean): PVertexLink;
begin
  Result := region.AddItem;
end;

{$EndRegion}

end.

