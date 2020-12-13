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
  Oz.SGL.Heap,
  Oz.SGL.Collections,
  Oz.Solid.VectorInt,
  Oz.Solid.Types;

{$EndRegion}

{$T+}

{$Region 'Pointers'}

type
  P2Polygon = ^T2Polygon;
  P2Contour = ^T2Contour;

{$EndRegion}

{$Region 'T2Vertex'}

  // Vertex coordinates
  TVertexPoint = record
  case Integer of
    0: (p2d: T2dPoint);
    1: (p2i: T2i);
  end;

  P2Vertex = ^T2Vertex;

  PPVertexLink = ^PVertexLink;
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
    class function Compare(const a, b: PVertexLink): Integer; static;
    property nxt: PVertexLink read n write n;
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
    E_FST    = $0010; // vertex belongs to 1st T2Polygon
  type
    ELABEL = (
      E_INSIDE,
      E_OUTSIDE,
      E_SHARED1,
      E_SHARED2,
      E_SHARED3,
      E_UNKNOWN);
  var
    next, prev: P2Vertex;
    Flags: Cardinal;
    v: TVertexPoint;
    t: TemporaryFields;
  private
    procedure SetVnodeLabel(value: ELABEL);
    function GetVnodeLabel: ELABEL;
    function IsFirst: Boolean;
    function IsMarked: Boolean;
    procedure SetMarked;
    procedure SetFirst(value: Boolean);
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
    P_MASK   = $0003; // pline label mask
  type
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
    procedure SetPlineLabel(value: PLABEL);
    function GetPlineLabel: PLABEL;
  public
    class function New(const g: T2i): P2Contour; static;
    class procedure Del(var pline: P2Contour); static;
    function IsOuter: Boolean;
    function Copy(makeLinks: Boolean = False): P2Contour;
    class procedure Incl(var pline: P2Contour; const g: T2i); static;
    // Calculate orientation and bounding box
    // removes points lying on the same line
    // returns if contour is valid, i.e. Count >= 3 and Area <> 0
    function Prepare: Boolean;
    // Invert contour
    procedure Invert;
    // Put pline either into area or holes depending on its orientation
    class procedure Put(pline: P2Contour;
      var area: P2Polygon; var holes: P2Contour); static;
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

  TErrorNumber = (ecOk, ecNotEnoughMemory, ecIO, ecInvalidParameter,
    ecBool, ecTriangulate);

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
    class function Triangulate(area: P2Polygon): TErrorNumber; static;
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

{$Region 'TVertexLinkHeap'}

type
  PVertexLinkHeap = ^TVertexLinkHeap;
  TVertexLinkHeap = TObjectHeap<TVertexLink>;

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
  inside := False;
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

{$Region 'Collect'}
type

  DIRECTION = (FORW, BACKW);

  TEdgeRule = function(const vn: P2Vertex; dir: DIRECTION): Boolean;
  TCntrRule = function(const c: P2Contour; dir: DIRECTION): Boolean;

function EdgeRuleUn(const vn: P2Vertex; dir: DIRECTION): Boolean;
var
  nLabel: T2Vertex.ELABEL;
begin
  nLabel := vn.GetVnodeLabel;
  if nLabel in [E_OUTSIDE, E_SHARED1] then
  begin
    dir := FORW;
    exit(True);
  end;
  Result := False;
end;

function EdgeRuleIs(const vn: P2Vertex; dir: DIRECTION): Boolean;
var
  nLabel: T2Vertex.ELABEL;
begin
  nLabel := vn.GetVnodeLabel;
  if nLabel in [E_INSIDE, E_SHARED1] then
  begin
    dir := FORW;
    exit(True);
  end;
  Result := False;
end;

function EdgeRuleSb(const vn: P2Vertex; dir: DIRECTION): Boolean;
var
  nLabel: T2Vertex.ELABEL;
begin
  nLabel := vn.GetVnodeLabel;
  if vn.IsFirst then
  begin
    if nLabel in [E_OUTSIDE, E_SHARED2] then
    begin
      dir := FORW;
      exit(True);
    end;
  end
  else
  begin
    if nLabel in [E_INSIDE, E_SHARED2] then
    begin
      dir := BACKW;
      exit(True);
    end;
  end;
  Result := False;
end;

function EdgeRuleXr(const vn: P2Vertex; dir: DIRECTION): Boolean;
var
  nLabel: T2Vertex.ELABEL;
begin
  nLabel := vn.GetVnodeLabel;
  if nLabel = E_OUTSIDE then
  begin
    dir := FORW;
    exit(True);
  end
  else if nLabel = E_INSIDE then
  begin
    dir := BACKW;
    exit(True);
  end;
  Result := False;
end;

function CntrRuleUn(const pline: P2Contour; dir: DIRECTION): Boolean;
var
  nLabel: T2Contour.PLABEL;
begin
  nLabel := pline.GetPlineLabel;
  if nLabel = P_OUTSIDE then
  begin
    dir := FORW;
    exit(True);
  end;
  Result := False;
end;

function CntrRuleIs(const pline: P2Contour; dir: DIRECTION): Boolean;
var
  nLabel: T2Contour.PLABEL;
begin
  nLabel := pline.GetPlineLabel;
  if nLabel = P_INSIDE then
  begin
    dir := FORW;
    exit(True);
  end;
  Result := False;
end;

function CntrRuleSb(const pline: P2Contour; dir: DIRECTION): Boolean;
var
  nLabel: T2Contour.PLABEL;
begin
  nLabel := pline.GetPlineLabel;
  if pline.head.IsFirst then
  begin
    if nLabel = P_OUTSIDE then
    begin
      dir := FORW;
      exit(True);
    end;
  end
  else
  begin
    if nLabel = P_INSIDE then
    begin
      dir := BACKW;
      exit(True);
    end;
  end;
  Result := False;
end;

function CntrRuleXr(const pline: P2Contour; dir: DIRECTION): Boolean;
var
  nLabel: T2Contour.PLABEL;
begin
  nLabel := pline.GetPlineLabel;
  if nLabel = P_OUTSIDE then
  begin
    dir := FORW;
    exit(True);
  end
  else if nLabel = P_INSIDE then
  begin
    dir := BACKW;
    exit(True);
  end;
  Result := False;
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

procedure T2Vertex.SetVnodeLabel(value: ELABEL);
begin
  Flags := (Flags and not E_MASK) or (Ord(value) and E_MASK);
end;

function T2Vertex.GetVnodeLabel: ELABEL;
begin
  Result := ELABEL(Flags and E_MASK);
end;

function T2Vertex.IsFirst: Boolean;
begin
  Result := (Flags and E_FST) <> 0;
end;

function T2Vertex.IsMarked: Boolean;
begin
  Result := (Flags and E_MARK) <> 0;
end;

procedure T2Vertex.SetFirst(value: Boolean);
begin
  if value then
    Flags := Flags or E_FST
  else
    Flags := Flags and not E_FST
end;

procedure T2Vertex.SetMarked;
begin
  Flags := Flags or E_MARK;
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

procedure T2Contour.SetPlineLabel(value: PLABEL);
begin
  Flags := (Flags and not P_MASK) or (Ord(value) and P_MASK);
end;

function T2Contour.GetPlineLabel: PLABEL;
begin
  Result := PLABEL(Flags and P_MASK);
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
  a := nil; b := nil;
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

function IsFirst(const vn: P2Vertex): Boolean;
begin
  Result := (vn.Flags and T2Vertex.E_FST) <> 0;
end;

function IsMarked(const vn: P2Vertex): Boolean;
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
  i := pHeap.Get(True);
  o := pHeap.Get(True);
  i.SetIn(True);
  i.SetValid(False);
  o.SetIn(False);
  o.SetValid(False);
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

function MergeSort(var head: PVertexLink): PVertexLink;
var
  p, q, r, s, t: PVertexLink;
  elm: array [0..3] of PVertexLink;
  n: Cardinal;
  nP, nQ: Integer;
begin
  p := Head;
  if p = nil then
    exit(nil);
  if p.nxt = nil then
    exit(p);

  elm[0].nxt := p; q := p.nxt;
  elm[1].nxt := q; r := q.nxt;

  while r <> nil do
  begin
    p := p.nxt; r := r.nxt;
    if r = nil then break;
    q := r; q.nxt := r; r := r.nxt;
  end;
  p.nxt := nil; q.nxt := nil;

  n := 1;

  while True do
  begin
    begin
      p := elm[0].nxt;
      q := elm[1].nxt;
      if q = nil then break;
      r := elm[2];
      s := elm[3];

      nP := n;
      nQ := n;
      while True do
      begin
        begin
          t := r;
          while True do
          begin
            if (nP > 0) and (nQ < 1) or (TVertexLink.Compare(p, q) <= 0) then
            begin
              t := p; t.nxt := p; p := p.nxt;
              if p = nil then nP := -1 else Dec(nP);
            end
            else
            begin
              if nQ < 1 then break;
              t := q; t.nxt := q; q := q.nxt;
              if q = nil then nQ := -1 else Dec(nQ);
            end;
          end;
          r := t;
        end;
        if nP < 0 then
        begin
          if nQ >= 0 then
            nQ := n
          else
            break;
        end
        else
        begin
          nP := n;
          if nQ >= 0 then
            nQ := n;
        end;
        begin
          t := s;
          while True do
          begin
            if (nP > 0) and (nQ < 1) or (TVertexLink.Compare(p, q) <= 0) then
            begin
              t := p; t.nxt := p; p := p.nxt;
              if p = nil then nP := -1 else Dec(nP);
            end
            else
            begin
              if nQ < 1 then break;
              t := q; t.nxt := q; q := q.nxt;
              if q = nil then nQ := -1 else Dec(nQ);
            end;
          end;
          s := t;
        end;
        if nP < 0 then
        begin
          if nQ >= 0 then
            nQ := n
          else
            break;
        end
        else
        begin
          nP := n;
          if nQ >= 0 then
            nQ := n;
        end;
      end;
      r.nxt := nil; s.nxt := nil; n := n * 2;
    end;
    begin
      p := elm[2].nxt;
      q := elm[3].nxt;
      if q = nil then
        break;
      r := elm[0];
      s := elm[1];
      nP := n;
      nQ := n;
      while True do
      begin
        begin
          t := r;
          while True do
          begin
            if (nP > 0) and (nQ < 1) or (TVertexLink.Compare(p, q) <= 0) then
            begin
              t := p; t.nxt := p; p := p.nxt;
              if p = nil then nP := -1 else Dec(nP);
            end
            else
            begin
              if nQ < 1 then
                break;
              t := q; t.nxt := q; q := q.nxt;
              if q = nil then nQ := -1 else Dec(nQ);
            end;
          end;
          r := t;
        end;
        if nP < 0 then
        begin
          if nQ >= 0 then
            nQ := n
          else
            break;
        end
        else
        begin
          nP := n;
          if nQ >= 0 then
            nQ := n;
        end;
        begin
          t := s;
          while True do
          begin
            if (nP > 0) and (nQ < 1) or (TVertexLink.Compare(p, q) <= 0) then
            begin
              t := p; t.nxt := p; p := p.nxt;
              if p = nil then nP := -1 else Dec(nP);
            end
            else
            begin
              if nQ < 1 then
                break;
              t := q; t.nxt := q; q := q.nxt;
              if q = nil then nQ := -1 else Dec(nQ);
            end;
          end;
          s := t;
        end;
        if nP < 0 then
        begin
          if nQ >= 0 then
            nQ := n
          else
            break;
        end
        else
        begin
          nP := n;
          if nQ >= 0 then
            nQ := n;
        end;
      end;
      r.nxt := nil; s.nxt := nil;
      n := n * 2;
    end;
  end;
  Head := p;
  Result := r;
end;

function HasShared3(const a: PVertexLink): Boolean;
var
  b: PVertexLink;
begin
  if (a = nil) or (a.n = nil) then
    exit(False);
  b := a.n;
  Result := (a.dx = b.dx) and (a.dy = b.dy) and (a.IsFirst = b.IsFirst);
end;

procedure MarkAsDone(const a: PVertexLink);
begin
  if a.IsIn then
  begin
    a.vn.prev.SetVnodeLabel(E_SHARED3);
    a.vn.t.lnk.i := nil;
  end
  else
  begin
    a.vn.SetVnodeLabel(E_SHARED3);
    a.vn.t.lnk.o := nil;
  end;
end;

procedure LnkUntie(const l: PVertexLink);
begin
  if l.IsIn then
    l.vn.t.lnk.i := nil
  else
    l.vn.t.lnk.o := nil;
end;

procedure SortDesc(area: P2Polygon);
var
  pa: P2Polygon;
  pline: P2Contour;
  vn, vnext: P2Vertex;
  head, l, c, s, q: PVertexLink;
  pp: PPVertexLink;
begin
  pa := area;
  repeat
    pline := pa.cntr;
    while pline <> nil do
    begin
      vn := pline.head;
      repeat
        if (vn.t.lnk.i = nil) and (vn.t.lnk.o = nil) then
          continue;

        if vn.t.lnk.i = nil then
          head := vn.t.lnk.o
        else if vn.t.lnk.o = nil then
          head := vn.t.lnk.i
        else if (vn.t.lnk.o.n = vn.t.lnk.i) and (vn.t.lnk.o.p = vn.t.lnk.i) then
        begin
          // resolve trivial intersections at endpoints
          vn.t.lnk.o := nil;
          vn.t.lnk.i := nil;
          continue;
        end
        else
          head := vn.t.lnk.i;

        if head.IsValid then
        begin
          pline.SetPlineLabel(P_ISECTED);
          continue;
        end;
        l := head;
        repeat
          if l.IsIn then
            vnext := l.vn.prev
          else
            vnext := l.vn.next;
          l.dx := vnext.v.p2i.x - vn.v.p2i.x;
          l.dy := vnext.v.p2i.y - vn.v.p2i.y;
          l.SetFirst(IsFirst(l.vn));
          l := l.n;
        until l = head;

        l.p.n := nil;
        MergeSort(l);

        // now, untie self shared edges
        begin
          pp := @l;
          c := pp^;
          while c <> nil do
          begin
            if not HasShared3(c) then
              pp := @c.n
            else
            begin
              pline.SetPlineLabel(P_ISECTED);
              MarkAsDone(c);
              MarkAsDone(c.n);
              pp := @c.n.n;
            end;
            c := pp^;
          end;
        end;

        if l = nil then
          continue;
        assert(l.n <> nil);
        if l.n.n = nil then
        begin
          // only trivial intersection remained
          LnkUntie(l);
          LnkUntie(l.n);
          continue;
        end;
        // now we have only True intersections make valid doubly linked list

        pline.SetPlineLabel(P_ISECTED);
        s := l;
        q := s.n;
        while q <> nil do
        begin
          s.SetValid(True);
          q.p := s;
          s := s.n;
          q := s.n;
        end;
        l.p := s;
        s.n := l;
        vn := vn.next;
      until vn = pline.head;
      pline := pline.next;
    end;
    pa := pa.f;
  until pa = area;
end;

function DoShared(lnk, chk: PVertexLink): Boolean;
var
  nLabel: T2Vertex.ELABEL;
  vn0, vn1: P2Vertex;
begin
  if (lnk.dx <> chk.dx) or (lnk.dy <> chk.dy) then
    exit(False);

  // we have a pair of shared edges
  if chk.IsIn = lnk.IsIn then
  begin
    nLabel := E_SHARED1;
    if chk.IsIn then
    begin
      vn0 := chk.vn.prev;
      vn1 := lnk.vn.prev;
    end
    else
    begin
      vn0 := chk.vn;
      vn1 := lnk.vn;
    end;
  end
  else
  begin
    nLabel := E_SHARED2;
    if chk.IsIn then
    begin
      vn0 := chk.vn.prev;
      vn1 := lnk.vn;
    end
    else
    begin
      vn0 := chk.vn;
      vn1 := lnk.vn.prev;
    end;
  end;
  vn0.SetVnodeLabel(nLabel);
  vn1.SetVnodeLabel(nLabel);
  vn0.t.lnk.o.shared := vn1;
  vn1.t.lnk.o.shared := vn0;
  Result := True;
end;

function DoLabel(vn: P2Vertex; lnk: PVertexLink): Boolean;
var
  n, vl, p: PVertexLink;
  bInside: Boolean;
begin
  n := nil;
  vl := lnk.n;
  while vl <> lnk do
  begin
    if vl.IsFirst <> lnk.IsFirst then
    begin
      n := vl;
      break;
    end;
    vl := vl.n;
  end;
  if n = nil then
    exit(False);
  p := nil;
  vl := lnk.p;
  while vl <> lnk do
  begin
    if vl.IsFirst <> lnk.IsFirst then
    begin
      p := vl;
      break;
    end;
    vl := vl.p;
  end;
  assert((p <> nil) and (n <> p));
  if DoShared(lnk, n) or DoShared(lnk, p) then
    exit(True);

  // check if lnk lies inside (p, n)
  bInside := n.IsIn and not p.IsIn;
  if bInside then
    vn.SetVnodeLabel(E_INSIDE)
  else
    vn.SetVnodeLabel(E_OUTSIDE);;
  Result := True;
end;

procedure LabelIsected(pline: P2Contour; other: P2Polygon);
var
  vn: P2Vertex;
  nLabel, nPrev: T2Vertex.ELABEL;
  lnk: PVertexLink;
begin
  vn := pline.head;
  repeat
    nLabel := vn.GetVnodeLabel;
    if nLabel <> E_UNKNOWN then continue;

    lnk := nil;
    if vn.t.lnk.o <> nil then
      lnk := vn.t.lnk.o
    else if vn.next.t.lnk.i <> nil then
      lnk := vn.next.t.lnk.i;
    if (lnk <> nil) and DoLabel(vn, lnk) then continue;

    nPrev := vn.prev.GetVnodeLabel;
    if (nPrev <> E_UNKNOWN) and (nPrev <> E_SHARED3) then
      vn.SetVnodeLabel(nPrev)
    else if GridInParea(@vn.v.p2i, other) then
      vn.SetVnodeLabel(E_INSIDE)
    else
      vn.SetVnodeLabel(E_OUTSIDE);
    vn := vn.next;
  until vn = pline.head;
end;

procedure LabelPline(pline: P2Contour; other: P2Polygon);
begin
  if pline.GetPlineLabel = P_ISECTED then
    LabelIsected(pline, other)
  else if PlineInParea(pline, other) then
    pline.Flags := pline.SetBits(T2Contour.P_MASK, Ord(P_INSIDE))
  else
    pline.Flags := pline.SetBits(T2Contour.P_MASK, Ord(P_OUTSIDE));
end;

procedure LabelParea(area, other: P2Polygon);
var
  pa: P2Polygon;
  pline: P2Contour;
begin
  pa := area;
  repeat
    pline := pa.cntr;
    while pline <> nil do
    begin
      LabelPline(pline, other);
      pline := pline.next;
    end;
    pa := pa.f;
  until pa = area;
end;

function Jump(cur: P2Vertex; var cdir: DIRECTION; eRule: TEdgeRule): P2Vertex;
var
  start, n: PVertexLink;
begin
  if cdir = FORW  then
    start := cur.t.lnk.i
  else
    start := cur.t.lnk.o;
  if start <> nil then
  begin
    n := start.p;
    while n <> start do
    begin
      if (start.dx = n.dx) and (start.dy = n.dy) then continue;
      if n.IsIn and eRule(n.vn.prev, cdir) or not n.IsIn and eRule(n.vn, cdir) then
        exit(n.vn);
      n := n.p;
    end;
  end;
  Result := cur;
end;

procedure CollectVnode(start: P2Vertex; var result: P2Contour;
  edgeRule: TEdgeRule; initdir: DIRECTION);
var
  V, E: P2Vertex;
  dir: DIRECTION;
begin
  V := start;
  if initdir = FORW then
    E := start
  else
    E := start.prev;
    dir := initdir;
    repeat
      T2Contour.Incl(result, V.v.p2i);
      SetMarked(E);
      // for SHARED edge mark its neighbour
      if (E.GetVnodeLabel = E_SHARED1) or (E.GetVnodeLabel = E_SHARED2) then
        SetMarked(E.t.lnk.o.shared);
      // go forward, try to jump
      if dir = FORW then
      begin
        V := Jump(V.next, dir, edgeRule);
        E := V;
      end
      else
      begin
        V := Jump(V.prev, dir, edgeRule);
        E := V.prev;
      end;
      assert(E.GetVnodeLabel <> E_SHARED3);
    until IsMarked(E);
end;

procedure CollectPline(pline: P2Contour; var r: P2Polygon; var holes: P2Contour;
  Op: T2Polygon.TBoolOp);
const
  edgeRule: array [T2Polygon.TBoolOp] of TEdgeRule = (
    EdgeRuleUn,  // PBO_UNITE,
    EdgeRuleIs,  // PBO_ISECT,
    EdgeRuleSb,  // PBO_SUB,
    EdgeRuleXr); // PBO_XOR
  cntrRule: array [T2Polygon.TBoolOp] of TCntrRule = (
    CntrRuleUn,  // PBO_UNITE,
    CntrRuleIs,  // PBO_ISECT,
    CntrRuleSb,  // PBO_SUB,
    CntrRuleXr); // PBO_XOR
var
  nLabel: T2Contour.PLABEL;
  vn: P2Vertex;
  dir: DIRECTION;
  p, copy: P2Contour;
begin
  nLabel := pline.GetPlineLabel;
  if nLabel = P_ISECTED then
  begin
    vn := pline.head;
    repeat
      if not IsMarked(vn) and edgeRule[Op](vn, dir) then
      begin
        p := nil;
        if dir = FORW then
          CollectVnode(vn, p, edgeRule[Op], dir)
        else
          CollectVnode(vn.next, p, edgeRule[Op], dir);
        if p.Prepare then
          T2Contour.Put(p, r, holes)
        else
          T2Contour.Del(p);
      end;
      vn := vn.next;
    until vn = pline.head;
  end
  else
  begin
    if cntrRule[Op](pline, dir) then
    begin
      copy := pline.Copy;
      if not copy.Prepare then
        T2Contour.Del(copy)
      else
      begin
        if dir = BACKW then
          copy.Invert;
        T2Contour.Put(copy, r, holes);
      end;
    end;
  end;
end;

procedure CollectParea(area: P2Polygon; var r: P2Polygon; var holes: P2Contour;
  Op: T2Polygon.TBoolOp);
var
  pa: P2Polygon;
  pline: P2Contour;
begin
  pa := area;
  repeat
    pline := pa.cntr;
    while pline <> nil do
    begin
      CollectPline(pline, r, holes, Op);
      pline := pline.next;
    end;
    pa := pa.f;
  until pa = area;
end;

procedure DoBoolean(a, b, r: P2Polygon; Op: T2Polygon.TBoolOp);
var
  holes: P2Contour;
begin
  SortDesc(a);
  SortDesc(b);
  LabelParea(a, b);
  LabelParea(b, a);
  holes := nil;
  CollectParea(a, r, holes, Op);
  CollectParea(b, r, holes, Op);
  try
    T2Polygon.InsertHoles(r, holes);
  except
    T2Contour.Del(holes);
    T2Polygon.Del(r);
    raise;
  end;
end;

procedure RecalcCount(area: P2Polygon);
var
  pa: P2Polygon;
  pline: P2Contour;
  vn: P2Vertex;
  nCount: Cardinal;
begin
  pa := area;
  repeat
    pline := pa.cntr;
    while pline <> nil do
    begin
      vn := pline.head;
      nCount := 0;
      repeat
        Inc(nCount);
        vn := vn.next;
      until vn = pline.head;
      pline.Count := nCount;
      pline := pline.next;
    end;
    pa := pa.f;
  until pa = area;
end;

class function T2Polygon.Bool0(const a, b: P2Polygon; var r: P2Polygon;
  Op: TBoolOp): TErrorNumber;
var
  aSegms, pSegm: P2Segment;
  nSegms: Cardinal;
  pb: TObjectHeap<TVertexLink>;
  bc: TBoolContext;
begin
  r := nil;
  assert(a.CheckDomain);
  assert(b.CheckDomain);
  aSegms := nil;
  Result := ecOk;
  try
    InitArea(a, True);
    InitArea(b, False);
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

class function T2Polygon.Triangulate(area: P2Polygon): TErrorNumber;
var
//  g: Tb;
  pa: P2Polygon;
begin
  Result := ecOk;
  if area = nil then exit;
  try
    pa := area;
    repeat
//      g.Triangulate(pa);
      pa := pa.f;
    until pa = area;
  except
    Result := ecTriangulate;
  end;
end;

class procedure T2Polygon.InclParea(var list: P2Polygon; a: P2Polygon);
begin
  if a <> nil then
  begin
    if list = nil then
      list := a
    else
    begin
      a.b := list.b;
      a.b.f := a;
      a.f := list;
      list.b := a;
    end;
  end;
end;

procedure InclPareaPline(p: P2Polygon; c: P2Contour);
begin
  assert(c.next = nil);
  if c.IsOuter then
  begin
    assert(p.cntr = nil);
    p.cntr := c;
  end
  else
  begin
    assert(p.cntr <> nil);
    c.next := p.cntr.next;
    p.cntr.next := c;
  end;
end;

class procedure T2Polygon.InclPline(var list: P2Polygon; pline: P2Contour);
var
  t, pa: P2Polygon;
begin
  assert((pline <> nil) and (pline.next = nil));
  if pline.IsOuter then
  begin
    t := New();
    InclParea(list, t);
  end
  else
  begin
    assert(list <> nil);
    // find the smallest container for the hole
    t := nil;
    pa := list;
    repeat
      if PlineInPline(pline, pa.cntr) and (t = nil) or
         PlineInPline(pa.cntr, t.cntr) then
        t := pa;
      pa := pa.f;
    until pa = list;
    // couldn't find a container for the hole
    if t = nil then err(ecInvalidParameter);
  end;
  InclPareaPline(t, pline);
end;

class procedure T2Polygon.InsertHoles(var list: P2Polygon; var holes: P2Contour);
var
  next: P2Contour;
begin
  if holes = nil then exit;
  if list = nil then err(ecInvalidParameter);
  while holes <> nil do
  begin
    next := holes.next;
    holes.next := nil;
    InclPline(list, holes);
    holes := next;
  end;
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

end.

