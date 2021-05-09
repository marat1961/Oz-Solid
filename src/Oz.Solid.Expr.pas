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

unit Oz.Solid.Expr;

interface

{$Region 'Uses'}

uses
  System.SysUtils, System.Math, System.Character,
  Oz.SGL.Heap, Oz.SGL.Collections, Oz.Solid.Utils, Oz.Solid.Types;

{$EndRegion}

{$T+}

type
  EExprError = class(Exception)
  public
    constructor Create(err: Integer); overload;
  const
    UnexpectedOperation = 1;
    UnexpectedOperator = 2;
  end;

{$Region 'TsdParam'}

  hParam = record
    v: Cardinal;
  end;

  PsdParam = ^TsdParam;
  TsdParam = record
    tag: Integer;
    h: hParam;
    val: Double;
    known, free: Boolean;
    procedure Clear; inline;
  end;

  PsdParams = ^TsdParams;
  TsdParams = TsdIdList<TsdParam>;

{$EndRegion}

{$Region 'TExpr'}

  PExpr = ^TExpr;
  TExpr = record
  type
    TOp = (PARAM, PARAM_PTR, CONSTANT, VARIABLE,
      PLUS, MINUS, TIMES, DIVIDE, NEGATE, POWER,
      SQRT, SQUARE, SIN, COS, ASIN, ACOS, LN);
  const
    NO_PARAMS: hParam = (v: 0);
    MULTIPLE_PARAMS: hParam = (v: 1);
  strict private class var
    ctx: TsdContext;
  private
    function AnyOp(newOp: TOp; b: PExpr): PExpr; inline;
  public
    constructor Expr(val: Double);
    class function AllocExpr: PExpr; static; inline;
    class function From(p: hParam): PExpr; overload; static;
    class function From(v: Double): PExpr; overload; static;
    class function From(const inp: string; popUpError: Boolean): PExpr; overload; static;
    class function Parse(const inp: string; var error: string): PExpr; static;

    function Plus(b: PExpr): PExpr; inline;
    function Minus(b: PExpr): PExpr; inline;
    function Times(b: PExpr): PExpr; inline;
    function Divide(b: PExpr): PExpr; inline;
    function Power(b: PExpr): PExpr; inline;

    function Negate: PExpr; inline;
    function Sqrt: PExpr; inline;
    function Square: PExpr; inline;
    function Sin: PExpr; inline;
    function Cos: PExpr; inline;
    function ASin: PExpr; inline;
    function ACos: PExpr; inline;
    function Ln: PExpr; inline;

    function PartialWrt(p: hParam): PExpr;
    function Eval: Double;
    function ParamsUsed: uint64;
    function DependsOn(p: hParam): Boolean;
    function Tol(a, b: Double): Boolean;
    function FoldConstants: PExpr;
    procedure Substitute(oldh, newh: hParam);
    function ReferencedParams(pl: PsdParams): hParam;
    function ToString: string;
    function Children: Integer;
    function Nodes: Integer;
    function DeepCopy: PExpr;
    function DeepCopyWithParamsAsPointers(firstTry, thenTry: PsdParams): PExpr;
  public
    op: TOp;
    a: PExpr;
    case Integer of
      0: (v: Double);
      1: (parh: hParam);
      2: (parp: PsdParam);
      3: (b: PExpr);
  end;

{$EndRegion}

{$Region 'TExprVector'}

  PExprVector = ^TExprVector;
  TExprVector = record
    x, y, z: PExpr;
    constructor From(x, y, z: PExpr); overload;
    constructor From(const vn: TsdVector); overload;
    constructor From(x, y, z: hParam); overload;
    constructor From(x, y, z: Double); overload;
    function Plus(const b: TExprVector): TExprVector;
    function Minus(const b: TExprVector): TExprVector;
    function Dot(const b: TExprVector): PExpr;
    function Cross(const b: TExprVector): TExprVector;
    function ScaledBy(const s: PExpr): TExprVector;
    function WithMagnitude(const s: PExpr): TExprVector;
    function Magnitude: PExpr;
    function Eval: TsdVector;
  end;

{$EndRegion}

{$Region 'TExprQuaternion'}

  PExprQuaternion = ^TExprQuaternion;
  TExprQuaternion = record
    w, vx, vy, vz: PExpr;
    constructor From(w, vx, vy, vz: PExpr); overload;
    constructor From(const qn: TQuaternion); overload;
    constructor From(w, vx, vy, vz: hParam); overload;
    function RotationU: TExprVector;
    function RotationV: TExprVector;
    function RotationN: TExprVector;
    function Rotate(const p: TExprVector): TExprVector;
    function Times(const b: TExprQuaternion): TExprQuaternion;
    function Magnitude: PExpr;
  end;

{$EndRegion}

{$Region 'TExprParser'}

  TExprParser = record
  type
    TErrNo = (
      NoErrors,
      UnexpectedCharacter,
      BadNumber,
      ExpectedOperator,
      ExpectedOperand,
      IsNotIdent,
      ExpectedRParen);
  const
    ErrMsg: array [TErrNo] of string = (
      '',
      'Unexpected character',
      'Bad number',
      'Expected an operator',
      'Expected an operand',
      'is not a valid variable, function or constant',
      'Expected ")"');
  private type
    TSymbolType = (ERROR, PAREN_LEFT, PAREN_RIGHT, BINARY_OP, UNARY_OP, OPERAND, EOS);
    TSymbol = record
      typ: TSymbolType;
      err: TErrNo;
      expr: PExpr;
      constructor From(typ: TSymbolType; expr: PExpr = nil); overload;
      constructor From(typ: TSymbolType; op: TExpr.TOp); overload;
      constructor From(err: TErrNo); overload;
      function IsError: Boolean;
    end;
  private
    it: PChar;
    ch: char;
    stack: TsgStack<TSymbol>;
    sym: TSymbol;
    id: string;
    constructor From(const inp: string);
    procedure Clear;
    procedure NextChar;
    function ReadWord: string;
    procedure SkipSpace;
    function LexNumber: TSymbol;
    function ToDouble(var V: Double): Boolean;
    function PopOperator: TSymbol;
    function PopOperand: TSymbol;
    function Precedence(sym: TSymbol): Integer;
    function Lex: TSymbol;
    function Reduce: Boolean;
    function GetErrorMessage(err: TErrNo): string;
    function Parse(reduceUntil: Integer = 0): Boolean; overload;
  public
    class function Parse(const inp: string; var error: string): PExpr; overload; static;
  end;

{$EndRegion}

implementation

uses
  Oz.Solid.Context;

constructor EExprError.Create(err: Integer);
var
  msg: string;
begin
  case err of
    UnexpectedOperation: msg := 'Unexpected operation';
    UnexpectedOperator: msg := 'Unexpected operator';
    else msg := 'Error: ' + IntToStr(err);
  end;
  Create(msg);
end;

{$Region 'TsdParam'}

procedure TsdParam.Clear;
begin
  Self := Default(TsdParam);
end;

{$EndRegion}

{$Region 'TExpr'}

constructor TExpr.Expr(val: Double);
begin
  op := TOp.CONSTANT;
  a := nil;
  v := val;
end;

class function TExpr.AllocExpr: PExpr;
begin
  Result := PExpr(TExpr.ctx.AllocExpr);
end;

class function TExpr.From(p: hParam): PExpr;
begin
  Result := AllocExpr;
  Result.op := TOp.PARAM;
  Result.parh := p;
end;

class function TExpr.From(v: Double): PExpr;
const
  zero: TExpr = (op: TExpr.TOp.CONSTANT; v: 0.0);
  one: TExpr = (op: TExpr.TOp.CONSTANT; v: 1.0);
  mone: TExpr = (op: TExpr.TOp.CONSTANT; v: -1.0);
  half: TExpr = (op: TExpr.TOp.CONSTANT; v: 0.5);
  mhalf: TExpr = (op: TExpr.TOp.CONSTANT; v: -0.5);
begin
  if v = 0.0 then exit(@zero);
  if v = 1.0 then exit(@one);
  if v = -1.0 then exit(@mone);
  if v = 0.5 then exit(@half);
  if v = -0.5 then exit(@mhalf);
  Result := AllocExpr;
  Result.op := TOp.CONSTANT;
  Result.v := v;
end;

class function TExpr.From(const inp: string; popUpError: Boolean): PExpr;
var
  error: string;
  e: PExpr;
begin
  e := TExprParser.Parse(inp, error);
  if e = nil then
  begin
    if popUpError then
      raise EExprError.CreateFmt(
        'Not a valid number or expression: "%s".%s.', [inp, error]);
  end;
  Result := e;
end;

class function TExpr.Parse(const inp: string; var error: string): PExpr;
begin
  Result := TExprParser.Parse(inp, error);
end;

function TExpr.AnyOp(newOp: TOp; b: PExpr): PExpr;
begin
  Result := AllocExpr;
  Result.op := newOp;
  Result.a := @Self;
  Result.b := b;
end;

function TExpr.Plus(b: PExpr): PExpr;
begin
  Result := AnyOp(TOp.PLUS, b);
end;

function TExpr.Minus(b: PExpr): PExpr;
begin
  Result := AnyOp(TOp.MINUS, b);
end;

function TExpr.Times(b: PExpr): PExpr;
begin
  Result := AnyOp(TOp.TIMES, b);
end;

function TExpr.Divide(b: PExpr): PExpr;
begin
  Result := AnyOp(TOp.DIVIDE, b);
end;

function TExpr.Power(b: PExpr): PExpr;
begin
  Result := AnyOp(TOp.POWER, b);
end;

function TExpr.Negate: PExpr;
begin
  Result := AnyOp(TOp.NEGATE, nil);
end;

function TExpr.Sqrt: PExpr;
begin
  Result := AnyOp(TOp.SQRT, nil);
end;

function TExpr.Square: PExpr;
begin
  Result := AnyOp(TOp.SQUARE, nil);
end;

function TExpr.Sin: PExpr;
begin
  Result := AnyOp(TOp.SIN, nil);
end;

function TExpr.Cos: PExpr;
begin
  Result := AnyOp(TOp.COS, nil);
end;

function TExpr.ASin: PExpr;
begin
  Result := AnyOp(TOp.ASIN, nil);
end;

function TExpr.ACos: PExpr;
begin
  Result := AnyOp(TOp.ACOS, nil);
end;

function TExpr.Ln: PExpr;
begin
  Result := AnyOp(TOp.LN, nil);
end;

function TExpr.PartialWrt(p: hParam): PExpr;
var da, db: PExpr;
begin
  case op of
    TOp.PARAM_PTR:
      Result := From(Ord(p.v = parp.h.v));
    TOp.PARAM:
      Result := From(Ord(p.v = parh.v));
    TOp.CONSTANT:
      Result := From(0.0);
    TOp.VARIABLE:
      raise EExprError.Create('Not supported yet');
    TOp.PLUS:
      Result := a.PartialWrt(p).Plus(b.PartialWrt(p));
    TOp.MINUS:
      Result := a.PartialWrt(p).Minus(b.PartialWrt(p));
    TOp.TIMES:
      begin
        da := a.PartialWrt(p);
        db := b.PartialWrt(p);
        Result := a.Times(db).Plus(b.Times(da));
      end;
    TOp.DIVIDE:
      begin
        da := a.PartialWrt(p);
        db := b.PartialWrt(p);
        Result := da.Times(b).Minus(a.Times(db)).Divide(b.Square);
     end;
    TOp.POWER:
     Result := a.Power(b).Times(a.Ln);
    TOp.SQRT:
      Result := From(0.5).Divide(a.Sqrt).Times(a.PartialWrt(p));
    TOp.SQUARE:
      Result := From(2.0).Times(a).Times(a.PartialWrt(p));
    TOp.NEGATE:
      Result := a.PartialWrt(p).Negate;
    TOp.SIN:
      Result := a.Cos.Times(a.PartialWrt(p));
    TOp.COS:
      Result := a.Sin.Times(a.PartialWrt(p)).Negate;
    TOp.ASIN:
      Result := From(1).Divide(From(1).Minus(a.Square).Sqrt)
        .Times(a.PartialWrt(p));
    TOp.ACOS:
      Result := From(-1).Divide(From(1).Minus(a.Square).Sqrt)
        .Times(a.PartialWrt(p));
    TOp.LN:
      Result := From(1).Divide(a);
    else
      raise EExprError.Create(EExprError.UnexpectedOperation);
  end;
end;

function TExpr.Eval: Double;
begin
  case op of
    TOp.PARAM: Result := ctx.GetParam(parh).val;
    TOp.PARAM_PTR: Result := parp.val;
    TOp.CONSTANT: Result := v;
    TOp.VARIABLE: raise EExprError.Create('Not supported yet');
    TOp.PLUS: Result := a.Eval + b.Eval;
    TOp.MINUS: Result := a.Eval - b.Eval;
    TOp.TIMES: Result := a.Eval * b.Eval;
    TOp.DIVIDE: Result := a.Eval / b.Eval;
    TOp.POWER: Result := System.Math.Power(a.Eval, b.Eval);
    TOp.NEGATE: Result := -a.Eval;
    TOp.SQRT: Result := System.Sqrt(a.Eval);
    TOp.SQUARE: Result := System.Sqr(a.Eval);
    TOp.SIN: Result := System.Sin(a.Eval);
    TOp.COS: Result := System.Cos(a.Eval);
    TOp.ACOS: Result := System.Math.ArcCos(a.Eval);
    TOp.ASIN: Result := System.Math.ArcSin(a.Eval);
    TOp.LN: Result := System.Ln(a.Eval);
    else
      raise EExprError.Create(EExprError.UnexpectedOperation);
  end;
end;

function TExpr.ParamsUsed: uint64;
var
  r: uint64;
  c: Integer;
begin
  r := 0;
  case op of
    TOp.PARAM: r := r or (uint64(1) shl (parh.v mod 61));
    TOp.PARAM_PTR: r := r or (uint64(1) shl (parp.h.v mod 61));
  end;
  c := Children;
  if c >= 1 then r := r or a.ParamsUsed;
  if c >= 2 then r := r or b.ParamsUsed;
  Result := r;
end;

function TExpr.DependsOn(p: hParam): Boolean;
var c: Integer;
begin
  case op of
    TOp.PARAM: exit(parh.v = p.v);
    TOp.PARAM_PTR: exit(parp.h.v = p.v);
  end;
  c := Children;
  case c of
    1: Result := a.DependsOn(p);
    2: Result := a.DependsOn(p) or b.DependsOn(p);
    else Result := False;
  end;
end;

function TExpr.Tol(a, b: Double): Boolean;
begin
  Result := Abs(a - b) < 0.001;
end;

function TExpr.FoldConstants: PExpr;
var
  n: PExpr;
  c: Integer;
  nv: Double;
begin
  n := AllocExpr;
  n^ := Self;
  c := Children;
  if c >= 1 then n.a := a.FoldConstants;
  if c >= 2 then n.b := b.FoldConstants;
  case op of
    TOp.MINUS, TOp.TIMES, TOp.DIVIDE, TOp.PLUS:
      begin
        if (n.a.op = TOp.CONSTANT) and (n.b.op = TOp.CONSTANT) then
        begin
          nv := n.Eval;
          n.op := TOp.CONSTANT;
          n.v := nv;
        end
        else if (op = TOp.PLUS) and (n.b.op = TOp.CONSTANT) and Tol(n.b.v, 0) then
          n^ := n.a^
        else if (op = TOp.PLUS) and (n.a.op = TOp.CONSTANT) and Tol(n.a.v, 0) then
          n^ := n.b^
        else if (op = TOp.TIMES) and (n.b.op = TOp.CONSTANT) and Tol(n.b.v, 1) then
          n^ := n.a^
        else if (op = TOp.TIMES) and (n.a.op = TOp.CONSTANT) and Tol(n.a.v, 1) then
          n^ := n.b^
        else if (op = TOp.TIMES) and (n.b.op = TOp.CONSTANT) and Tol(n.b.v, 0) then
        begin
          n.op := TOp.CONSTANT;
          n.v := 0;
        end
        else if (op = TOp.TIMES) and (n.a.op = TOp.CONSTANT) and Tol(n.a.v, 0) then
        begin
          n.op := TOp.CONSTANT;
          n.v := 0;
        end;
      end;
    TOp.SQRT, TOp.SQUARE, TOp.NEGATE, TOp.SIN, TOp.COS, TOp.ASIN, TOp.ACOS:
      if n.a.op = TOp.CONSTANT then
      begin
        nv := n.Eval;
        n.op := TOp.CONSTANT;
        n.v := nv;
      end;
  end;
  Result := n;
end;

procedure TExpr.Substitute(oldh, newh: hParam);
var c: Integer;
begin
  Check(op <> TOp.PARAM_PTR, 'Expected an expression that refer to params via handles');
  if (op = TOp.PARAM) and (parh.v = oldh.v) then
    parh := newh;
  c := Children;
  if c >= 1 then a.Substitute(oldh, newh);
  if c >= 2 then b.Substitute(oldh, newh);
end;

function TExpr.ReferencedParams(pl: PsdParams): hParam;
var
  c: Integer;
  pa, pb: hParam;
begin
  if op = TOp.PARAM then
    if pl.FindByIdNoOops(parh.v) <> nil then
      exit(parh)
    else
      exit(NO_PARAMS);
  Check(op <> TOp.PARAM_PTR, 'Expected an expression that refer to params via handles');
  c := Children;
  case c of
    0: exit(NO_PARAMS);
    1: exit(a.ReferencedParams(pl));
    2:
      begin
        pa := a.ReferencedParams(pl);
        pb := b.ReferencedParams(pl);
        if pa.v = NO_PARAMS.v then exit(pb);
        if pb.v = NO_PARAMS.v then exit(pa);
        if pa.v = pb.v then exit(pa); // either, doesn't matter
        exit(MULTIPLE_PARAMS);
      end
    else raise EExprError.Create('Unexpected children count');
  end;
end;

function TExpr.ToString: string;
  procedure BinOp(c: char);
  begin
    Result := '(' + a.ToString + ' ' + c + ' ' + b.ToString + ')';
  end;
begin
  case op of
    TOp.PARAM: Result := Format('param(%08x)', [parh.v]);
    TOp.PARAM_PTR: Result := Format('param(p%08x)', [parp.h.v]);
    TOp.CONSTANT: Result := Format('%.3f', [v]);
    TOp.VARIABLE: Result := '(var)';
    TOp.PLUS: BinOp('+');
    TOp.MINUS: BinOp('-');
    TOp.TIMES: BinOp('*');
    TOp.DIVIDE: BinOp('/');
    TOp.POWER: BinOp('^');
    TOp.NEGATE: Result := '(- ' + a.ToString + ')';
    TOp.SQRT: Result := '(sqrt ' + a.ToString + ')';
    TOp.SQUARE: Result := '(square ' + a.ToString + ')';
    TOp.SIN: Result := '(sin ' + a.ToString + ')';
    TOp.COS: Result := '(cos ' + a.ToString + ')';
    TOp.ASIN: Result := '(asin ' + a.ToString + ')';
    TOp.ACOS: Result := '(acos ' + a.ToString + ')';
    TOp.LN: Result := '(ln ' + a.ToString + ')';
    else
      raise EExprError.Create(EExprError.UnexpectedOperation);
  end;
end;

function TExpr.Children: Integer;
begin
  case op of
    TOp.PARAM, TOp.PARAM_PTR, TOp.CONSTANT, TOp.VARIABLE:
      Result := 0;
    TOp.PLUS, TOp.MINUS, TOp.TIMES, TOp.DIVIDE, TOp.POWER:
      Result := 2;
    TOp.NEGATE, TOp.SQRT, TOp.SQUARE, TOp.SIN, TOp.COS, TOp.ASIN, TOp.ACOS, TOp.LN:
      Result := 1;
    else
      raise EExprError.Create(EExprError.UnexpectedOperation);
  end
end;

function TExpr.Nodes: Integer;
begin
  case Children of
    0: Result := 1;
    1: Result := 1 + a.Nodes;
    2: Result := 1 + a.Nodes + b.Nodes;
    else raise EExprError.Create('Unexpected children count');
  end;
end;

function TExpr.DeepCopy: PExpr;
var
  n: PExpr;
  c: Integer;
begin
  n := AllocExpr;
  n^ := Self;
  c := n.Children;
  if c > 0 then n.a := a.DeepCopy;
  if c > 1 then n.b := b.DeepCopy;
  Result := n;
end;

function TExpr.DeepCopyWithParamsAsPointers(firstTry, thenTry: PsdParams): PExpr;
var
  n: PExpr;
  c: Integer;
  p: PsdParam;
begin
  n := AllocExpr;
  if op = TOp.PARAM then
  begin
    p := firstTry.FindByIdNoOops(parh.v);
    if p = nil then p := thenTry.FindById(parh.v);
    if p.known then
    begin
      n.op := TOp.CONSTANT;
      n.v := p.val;
    end
    else
    begin
      n.op := TOp.PARAM_PTR;
      n.parp := p;
    end;
    exit(n);
  end;
  n^ := Self;
  c := n.Children;
  if c > 0 then n.a := a.DeepCopyWithParamsAsPointers(firstTry, thenTry);
  if c > 1 then n.b := b.DeepCopyWithParamsAsPointers(firstTry, thenTry);
  Result := n;
end;

{$EndRegion}

{$Region 'TExprVector'}

constructor TExprVector.From(x, y, z: PExpr);
begin
  Self.x := x;
  Self.y := y;
  Self.z := z;
end;

constructor TExprVector.From(const vn: TsdVector);
begin
  Self.x := TExpr.From(vn.x);
  Self.y := TExpr.From(vn.y);
  Self.z := TExpr.From(vn.z);
end;

constructor TExprVector.From(x, y, z: hParam);
begin
  Self.x := TExpr.From(x);
  Self.y := TExpr.From(y);
  Self.z := TExpr.From(z);
end;

constructor TExprVector.From(x, y, z: Double);
begin
  Self.x := TExpr.From(x);
  Self.y := TExpr.From(y);
  Self.z := TExpr.From(z);
end;

function TExprVector.Plus(const b: TExprVector): TExprVector;
begin
  Result.x := x.Plus(b.x);
  Result.y := y.Plus(b.y);
  Result.z := z.Plus(b.z);
end;

function TExprVector.Minus(const b: TExprVector): TExprVector;
begin
  Result.x := x.Minus(b.x);
  Result.y := y.Minus(b.y);
  Result.z := z.Minus(b.z);
end;

function TExprVector.Dot(const b: TExprVector): PExpr;
begin
  Result := x.Times(b.x);
  Result := Result.Plus(y.Times(b.y));
  Result := Result.Plus(z.Times(b.z));
end;

function TExprVector.Cross(const b: TExprVector): TExprVector;
begin
  Result.x := y.Times(b.z).Minus(z.Times(b.y));
  Result.y := z.Times(b.x).Minus(x.Times(b.z));
  Result.z := x.Times(b.y).Minus(y.Times(b.x));
end;

function TExprVector.ScaledBy(const s: PExpr): TExprVector;
begin
  Result.x := x.Times(s);
  Result.y := y.Times(s);
  Result.z := z.Times(s);
end;

function TExprVector.WithMagnitude(const s: PExpr): TExprVector;
var m: PExpr;
begin
  m := Magnitude;
  Result := ScaledBy(s.Divide(m));
end;

function TExprVector.Magnitude: PExpr;
begin
  Result := x.Square;
  Result := Result.Plus(y.Square);
  Result := Result.Plus(z.Square);
  Result := Result.Sqrt;
end;

function TExprVector.Eval: TsdVector;
begin
  Result.x := x.Eval;
  Result.y := y.Eval;
  Result.z := z.Eval;
end;

{$EndRegion}

{$Region 'TExprQuaternion'}

constructor TExprQuaternion.From(w, vx, vy, vz: PExpr);
begin
  Self.w := w;
  Self.vx := vx;
  Self.vy := vy;
  Self.vz := vz;
end;

constructor TExprQuaternion.From(const qn: TQuaternion);
begin
  Self.w := TExpr.From(qn.w);
  Self.vx := TExpr.From(qn.v.x);
  Self.vy := TExpr.From(qn.v.y);
  Self.vz := TExpr.From(qn.v.z);
end;

constructor TExprQuaternion.From(w, vx, vy, vz: hParam);
var q: TExprQuaternion;
begin
  q.w := TExpr.From(w);
  q.vx := TExpr.From(vx);
  q.vy := TExpr.From(vy);
  q.vz := TExpr.From(vz);
  Self := q;
end;

function TExprQuaternion.RotationU: TExprVector;
var
  u: TExprVector;
  two: PExpr;
begin
  two := TExpr.From(2);
  u.x := w.Square;
  u.x := u.x.Plus(vx.Square);
  u.x := u.x.Minus(vy.Square);
  u.x := u.x.Minus(vz.Square);
  u.y := two.Times(w.Times(vz));
  u.y := (u.y).Plus(two.Times(vx.Times(vy)));
  u.z := two.Times(vx.Times(vz));
  u.z := u.z.Minus(two.Times(w.Times(vy)));
  Result := u;
end;

function TExprQuaternion.RotationV: TExprVector;
var
  v: TExprVector;
  two: PExpr;
begin
  two := TExpr.From(2);
  v.x := two.Times(vx.Times(vy));
  v.x := v.x.Minus(two.Times(w.Times(vz)));
  v.y := w.Square;
  v.y := v.y.Minus(vx.Square);
  v.y := v.y.Plus(vy.Square);
  v.y := v.y.Minus(vz.Square);
  v.z := two.Times(w.Times(vx));
  v.z := v.z.Plus(two.Times(vy.Times(vz)));
  Result := v;
end;

function TExprQuaternion.RotationN: TExprVector;
var
  n: TExprVector;
  two: PExpr;
begin
  two := TExpr.From(2);
  n.x := two.Times(w.Times(vy));
  n.x := n.x.Plus(two.Times(vx.Times(vz)));
  n.y := two.Times(vy.Times(vz));
  n.y := n.y.Minus(two.Times( w.Times(vx)));
  n.z := w.Square;
  n.z := n.z.Minus(vx.Square);
  n.z := n.z.Minus(vy.Square);
  n.z := n.z.Plus (vz.Square);
  Result := n;
end;

function TExprQuaternion.Rotate(const p: TExprVector): TExprVector;
begin
  Result := (RotationU.ScaledBy(p.x)).Plus(
             RotationV.ScaledBy(p.y)).Plus(
             RotationN.ScaledBy(p.z));
end;

function TExprQuaternion.Times(const b: TExprQuaternion): TExprQuaternion;
var
  sa, sb: PExpr;
  r: TExprQuaternion;
  va, vb, vr: TExprVector;
begin
  sa := w;
  sb := b.w;
  va := TExprVector.From(vx, vy, vz);
  vb := TExprVector.From(b.vx, b.vy, b.vz);
  r.w := sa.Times(sb).Minus(va.Dot(vb));
  vr := vb.ScaledBy(sa).Plus(va.ScaledBy(sb).Plus(va.Cross(vb)));
  r.vx := vr.x;
  r.vy := vr.y;
  r.vz := vr.z;
  Result := r;
end;

function TExprQuaternion.Magnitude: PExpr;
begin
  Result := ((w.Square).Plus(
             (vx.Square).Plus(
             (vy.Square).Plus(
             (vz.Square))))).Sqrt;
end;

{$EndRegion}

{$Region 'TExprParser'}

constructor TExprParser.From(const inp: string);
var
  n: Integer;
begin
  n := inp.Length - 1;
  Check(n >= 0, 'TExprParser: empty expr');
  it := PChar(inp);
  stack := TsgStack<TSymbol>.From(200);
  NextChar;
end;

procedure TExprParser.Clear;
begin
  stack.Clear;
  id := '';
end;

constructor TExprParser.TSymbol.From(typ: TSymbolType; expr: PExpr);
begin
  Self.typ := typ;
  Self.err := TErrNo.NoErrors;
  Self.expr := expr;
end;

constructor TExprParser.TSymbol.From(typ: TSymbolType; op: TExpr.TOp);
begin
  Self.typ := typ;
  Self.err := TErrNo.NoErrors;
  Self.expr := TExpr.AllocExpr;
  Self.expr.op := op;
end;

constructor TExprParser.TSymbol.From(err: TErrNo);
begin
  Self.typ := TSymbolType.ERROR;
  Self.err := err;
  Self.expr := nil;
end;

function TExprParser.TSymbol.IsError: Boolean;
begin
  Result := typ = TSymbolType.ERROR;
end;

procedure TExprParser.NextChar;
begin
  ch := PWideChar(it)^;
  if ch <> #0 then
    Inc(PWideChar(it));
end;

function TExprParser.ReadWord: string;
begin
  while ch <> #0 do
  begin
     if not ch.IsLetterOrDigit then break;
     Result := Result + ch;
     NextChar;
  end;
end;

procedure TExprParser.SkipSpace;
begin
  while ch <> #0 do
  begin
     if not ch.IsSeparator then break;
     NextChar;
  end;
end;

function TExprParser.PopOperator: TSymbol;
begin
  if stack.Empty or not (stack.Peek.typ in [TSymbolType.UNARY_OP, TSymbolType.BINARY_OP]) then
    Result := TSymbol.From(TErrNo.ExpectedOperator)
  else
    Result := stack.Pop;
end;

function TExprParser.PopOperand: TSymbol;
begin
  if stack.Empty or (stack.Peek.typ <> TSymbolType.OPERAND) then
    Result := TSymbol.From(TErrNo.ExpectedOperand)
  else
    Result := stack.Pop;
end;

function TExprParser.Precedence(sym: TSymbol): Integer;
begin
  Check(sym.typ in [TSymbolType.BINARY_OP,
                    TSymbolType.UNARY_OP,
                    TSymbolType.OPERAND], 'Unexpected token type');
  if sym.typ = TSymbolType.UNARY_OP then
    Result := 40
  else if sym.expr.op = TExpr.TOp.POWER then
    Result := 30
  else if sym.expr.op in [TExpr.TOp.TIMES, TExpr.TOp.DIVIDE] then
    Result := 20
  else if sym.expr.op in [TExpr.TOp.PLUS, TExpr.TOp.MINUS] then
    Result := 10
  else if sym.typ = TSymbolType.OPERAND then
    Result := 0
  else
    raise EExprError.Create(EExprError.UnexpectedOperator);
end;

function TExprParser.LexNumber: TSymbol;
var v: double;
begin
  if not ToDouble(v) then
    Result := TSymbol.From(TErrNo.BadNumber)
  else
  begin
    Result := TSymbol.From(TSymbolType.OPERAND, TExpr.TOp.CONSTANT);
    Result.expr.v := v;
  end;
end;

function TExprParser.ToDouble(var V: Double): Boolean;
const
  MaxExponent = 1024;
var
  Exp: Integer;
  D: Double;

  function ReadSign: SmallInt;
  begin
    Result := 1;
    if ch = '+' then
      NextChar
    else if ch = '-' then
    begin
      NextChar;
      Result := -1;
    end;
  end;

  function ReadNumber(var N: Double): Integer;
  begin
    Result := 0;
    while ch.IsDigit or (ch = '_') do
    begin
      if ch <> '_' then
      begin
        N := N * 10;
        N := N + Ord(ch) - Ord('0');
      end;
      Inc(Result);
      NextChar;
    end;
  end;

  function ReadExponent: SmallInt;
  var Sgn: SmallInt;
  begin
    Sgn := ReadSign;
    Result := 0;
    while ch.IsDigit do
    begin
      Result := Result * 10;
      Result := Result + Ord(ch) - Ord('0');
      NextChar;
    end;
    if Result > MaxExponent then
      Result := MaxExponent;
    Result := Result * Sgn;
  end;

begin
  D := 0;
  ReadNumber(D);
  if ch <> '.' then
    Exp := 0
  else
  begin
    NextChar;
    Exp := -ReadNumber(D);
  end;
  if Char(Word(ch) and $FFDF) = 'E' then
  begin
    NextChar;
    Inc(Exp, ReadExponent);
  end;
  if ch.IsLetter or (ch = '.') or (ch = '_') then exit(False);
  try
    D := Power10(D, Exp);
    V := D;
    Result := True;
  except
    Result := False;
  end;
end;

function TExprParser.Lex: TSymbol;
var sym: TSymbol;
begin
  SkipSpace;
  if ch = #0 then
    exit(TSymbol.From(TSymbolType.EOS));
  if ch.IsUpper then
  begin
    id := ReadWord;
    sym := TSymbol.From(TSymbolType.OPERAND, TExpr.TOp.VARIABLE);
  end
  else if ch.IsLetter then
  begin
    id := ReadWord;
    if id = 'sqrt' then
      sym := TSymbol.From(TSymbolType.UNARY_OP, TExpr.TOp.SQRT)
    else if id = 'square' then
      sym := TSymbol.From(TSymbolType.UNARY_OP, TExpr.TOp.SQUARE)
    else if id = 'sin' then
      sym := TSymbol.From(TSymbolType.UNARY_OP, TExpr.TOp.SIN)
    else if id = 'cos' then
      sym := TSymbol.From(TSymbolType.UNARY_OP, TExpr.TOp.COS)
    else if id = 'asin' then
      sym := TSymbol.From(TSymbolType.UNARY_OP, TExpr.TOp.ASIN)
    else if id = 'acos' then
      sym := TSymbol.From(TSymbolType.UNARY_OP, TExpr.TOp.ACOS)
    else if id = 'ln' then
      sym := TSymbol.From(TSymbolType.UNARY_OP, TExpr.TOp.LN)
    else if id = 'pi' then
    begin
      sym := TSymbol.From(TSymbolType.OPERAND, TExpr.TOp.CONSTANT);
      sym.Expr.v := PI;
    end
    else
      sym := TSymbol.From(TErrNo.IsNotIdent);
  end
  else if ch.IsDigit or (ch = '.') then
    exit(LexNumber)
  else begin
    if ch = '+' then
      sym := TSymbol.From(TSymbolType.BINARY_OP, TExpr.TOp.PLUS)
    else if ch = '-' then
      sym := TSymbol.From(TSymbolType.BINARY_OP, TExpr.TOp.MINUS)
    else if ch = '*' then
      sym := TSymbol.From(TSymbolType.BINARY_OP, TExpr.TOp.TIMES)
    else if ch = '/' then
      sym := TSymbol.From(TSymbolType.BINARY_OP, TExpr.TOp.DIVIDE)
    else if ch = '^' then
      sym := TSymbol.From(TSymbolType.BINARY_OP, TExpr.TOp.POWER)
    else if ch = '(' then
      sym := TSymbol.From(TSymbolType.PAREN_LEFT)
    else if ch = ')' then
      sym := TSymbol.From(TSymbolType.PAREN_RIGHT)
    else
    begin
      sym := TSymbol.From(TErrNo.UnexpectedCharacter);
      id := ch;
    end;
    NextChar;
  end;
  Result := sym;
end;

function TExprParser.Reduce: Boolean;
var
  a, b, op, r: TSymbol;
  e: PExpr;
begin
  a := PopOperand;
  if a.IsError then
  begin
    sym := a;
    exit(False);
  end;
  op := PopOperator;
  if op.IsError then
  begin
    sym := op;
    exit(False);
  end;
  r := TSymbol.From(TSymbolType.OPERAND);
  case op.typ of
    TSymbolType.BINARY_OP:
    begin
      b := PopOperand;
      if b.IsError then
      begin
        sym := b;
        exit(False);
      end;
      r.expr := b.expr.AnyOp(op.expr.op, a.expr);
    end;
    TSymbolType.UNARY_OP:
    begin
      e := a.expr;
      case op.expr.op of
        TExpr.TOp.NEGATE: e := e.Negate;
        TExpr.TOp.SQRT: e := e.Sqrt;
        TExpr.TOp.LN: e := e.Ln;
        TExpr.TOp.SQUARE: e := e.Times(e);
        TExpr.TOp.SIN: e := e.Times(TExpr.From(PI / 180)).Sin;
        TExpr.TOp.COS: e := e.Times(TExpr.From(PI / 180)).Cos;
        TExpr.TOp.ASIN: e := e.ASin.Times(TExpr.From(180 / PI));
        TExpr.TOp.ACOS: e := e.ACos.Times(TExpr.From(180 / PI));
        else
          raise EExprError.Create('Unexpected unary operator');
      end;
      r.expr := e;
    end;
    else
      raise EExprError.Create(EExprError.UnexpectedOperator);
  end;
  stack.Push(r);
  Result := True;
end;

function TExprParser.Parse(reduceUntil: Integer = 0): Boolean;
begin
  while True do
  begin
    sym := Lex;
    case sym.typ of
      TSymbolType.ERROR:
        exit(False);
      TSymbolType.PAREN_RIGHT, TSymbolType.EOS:
        begin
          while stack.Count > 1 + reduceUntil do
            if not Reduce then
              exit(False);
          if sym.typ = TSymbolType.PAREN_RIGHT then
              stack.Push(sym);
          exit(True);
        end;
      TSymbolType.PAREN_LEFT:
        begin
          // sub-expression
          if not Parse({reduceUntil=}stack.Count) then exit(False);
          if stack.Empty or (stack.Peek.typ <> TSymbolType.PAREN_RIGHT) then
          begin
            sym := TSymbol.From(TErrNo.ExpectedRParen);
            exit(False);
          end;
          stack.Pop;
        end;
      TSymbolType.BINARY_OP:
        begin
          if (stack.Count > reduceUntil) and
             (stack.Peek.typ <> TSymbolType.OPERAND) or
             (stack.Count = reduceUntil) then
          begin
            if sym.expr.op = TExpr.TOp.MINUS then
            begin
              sym.typ := TSymbolType.UNARY_OP;
              sym.expr.op := TExpr.TOp.NEGATE;
              stack.Push(sym);
              continue;
            end;
          end;
          while (stack.Count > 1 + reduceUntil) and
                (Precedence(sym) <= Precedence(stack.Items[stack.Count - 2])) do
            if not Reduce then exit(False);
          stack.Push(sym);
        end;
      TSymbolType.UNARY_OP, TSymbolType.OPERAND:
        stack.Push(sym);
    end;
  end;
  Result := True;
end;

class function TExprParser.Parse(const inp: string; var error: string): PExpr;
var
  parser: TExprParser;
  r: TSymbol;
begin
  parser := TExprParser.From(inp);
  try
    if not parser.Parse then
      r := parser.sym
    else
    begin
      r := parser.PopOperand;
      if not r.IsError then exit(r.expr);
    end;
    error := parser.GetErrorMessage(r.err);
    Result := nil;
  finally
    parser.Clear;
  end;
end;

function TExprParser.GetErrorMessage(err: TErrNo): string;
begin
  Result := ErrMsg[err];
  if err = TErrNo.UnexpectedCharacter then
    Result := Result + ' "' + id + '"'
  else if err = TErrNo.IsNotIdent then
    Result := '"' + id + '" ' + Result;
end;

{$EndRegion}

end.
