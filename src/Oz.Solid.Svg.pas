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
unit Oz.Solid.Svg;

interface

{$Region 'Uses'}

uses
  System.Classes, System.SysUtils, System.Math, System.Contnrs,
  Oz.Solid.VectorInt, Oz.Solid.Types;

{$EndRegion}

{$T+}

{$Region 'TsvgShape: Shapes and text context elements'}

type
  TsvgShape = class
  private
    FFill: string;
    FStroke: string;
    FStrokeWidth: Double;
    sb: TStringBuilder;
  public
    // presentation attribute that defines the color
    function Fill(const color: string): TsvgShape;
    // presentation attribute defining the color used to paint the outline of the shape
    function Stroke(const color: string): TsvgShape;
    // presentation attribute defining the width of the stroke to be applied to the shape
    function StrokeWidth(const Width: Double): TsvgShape;
    // generate svg element
    procedure Gen; virtual;
  end;

{$EndRegion}

{$Region 'TsvgRect: Rect element'}

  TsvgRect = class(TsvgShape)
  private
    Fx, Fy, Fwidth, Fheight: Double;
    Frx: Double;
    Fry: Double;
  public
    constructor Create(x, y, width, height: Double);
    // The x radius of the corners of the rectangle
    function Rx(const radius: Double): TsvgRect;
    // The y radius of the corners of the rectangle
    function Ry(const radius: Double): TsvgRect;
    // generate svg element
    procedure Gen; override;
  end;

{$EndRegion}

{$Region 'TsvgPoly'}

  TsvgPoly = class(TsvgShape)
  private
    FPolygon: Boolean;
    FPoints: TArray<T2dPoint>;
  public
    constructor Create(Polygon: Boolean);
    function Point(const pt: T2dPoint): TsvgPoly; overload;
    function Point(const x, y: Double): TsvgPoly; overload;
    function Point(const pt: T2i): TsvgPoly; overload;
    function Points(const points: T2dPoints): TsvgPoly;
    // generate svg element
    procedure Gen; override;
  end;

{$EndRegion}

{$Region 'TsvgPolyline'}

  TsvgPolyline = class(TsvgPoly)
  public
    constructor Create;
  end;

{$EndRegion}

{$Region 'TsvgPolygon'}

  TsvgPolygon = class(TsvgPoly)
  public
    constructor Create;
  end;

{$EndRegion}

{$Region 'TsvgCircle'}

  TsvgCircle = class(TsvgShape)
  private
    Fcx: Double;
    Fcy: Double;
    Fr: Double;
  public
    constructor Create(cx, cy, r: Double);
    // generate svg element
    procedure Gen; override;
  end;

{$EndRegion}

{$Region 'TsvgEllipse'}

  TsvgEllipse = class(TsvgShape)
  private
    Fcx: Double;
    Fcy: Double;
    Frx: Double;
    Fry: Double;
  public
    constructor Create(cx, cy, rx, ry: Double);
    // generate svg element
    procedure Gen; override;
  end;

{$EndRegion}

{$Region 'TsvgLine'}

  TsvgLine = class(TsvgShape)
  private
    Fx1: Double;
    Fy1: Double;
    Fx2: Double;
    Fy2: Double;
  public
    constructor Create(x1, y1, x2, y2: Double);
    // generate svg element
    procedure Gen; override;
  end;

{$EndRegion}

{$Region 'TsvgText'}

  TsvgText = class(TsvgShape)
  private
    Fx: Double;
    Fy: Double;
    Ftext: string;
    Fcls: string;
  public
    constructor Create(x, y: Double; const text: string);
    function Cls(const value: string): TsvgText;
    // generate svg element
    procedure Gen; override;
  end;

{$EndRegion}

{$Region 'TsvgPath'}

  TsvgPath = class(TsvgShape)
  type
    TPathOp = record
      op: Char;
      points: T2dPoints
    end;
  private
    FOps: TArray<TPathOp>;
  public
    constructor Create;
    // op
    //   MoveTo: M, m
    //   LineTo: L, l, H, h, V, v
    //   Cubic Bezier Curve: C, c, S, s
    //   Quadratic Bezier Curve: Q, q, T, t
    //   Elliptical Arc Curve: A, a
    //   ClosePath: Z, z
    function D(op: Char; const points: T2dPoints): TsvgPath;
    // generate svg element
    procedure Gen; override;
  end;

{$EndRegion}

{$Region 'TViewBox'}

  TViewBox = record
    min_x: Double;
    min_y: Double;
    width: Double;
    height: Double;
  end;

{$EndRegion}

{$Region 'TsvgBuilder'}

  TsvgBuilder = class
  private
    FWidth: Double;
    FHeight: Double;
    FViewBox: TViewBox;
    FShapes: TObjectList;
  public
    constructor Create(width, height: Double);
    destructor Destroy; override;
    // The viewBox attribute defines the position and dimension,
    // in user space, of an SVG viewport.
    function ViewBox(min_x, min_y, width, height: Double): TsvgBuilder;
    // The <rect> element draws a rectangle on the screen.
    function Rect(x, y, width, height: Double): TsvgRect;
    // The <circle> element draws a circle on the screen.
    function Circle(cx, cy, r: Double): TsvgCircle;
    // An <ellipse> is a more general form of the <circle> element.
    function Ellipse(cx, cy, rx, ry: Double): TsvgEllipse;
    // The <line> element is an SVG basic shape used
    // to create a line connecting two points.
    function Line(x1, y1, x2, y2: Double): TsvgLine;
    // A <polyline> is a group of connected straight lines.
    function Polyline: TsvgPolyline;
    // The <polygon> element defines a closed shape consisting of a set
    // of connected straight line segments.
    // The last point is connected to the first point.
    function Polygon: TsvgPolygon;
    // The SVG <text> element draws a graphics element consisting of text.
    function Text(x, y: Double; const text: string): TsvgText;
    // The <path> SVG element is the generic element to define a shape.
    // All the basic shapes can be created with a path element.
    function Path: TsvgPath;
    // generate svg element
    function ToString: string; override;
  end;

{$EndRegion}

{$Region 'TsvgBuilder'}

  TSbHelper = class helper for TStringBuilder
  const
    DF = '%.8f';
  public
    procedure StrAttr(const name, value: string);
    procedure NumAttr(const name: string; value: Double; def: Double = 0.0);
    procedure Text(const value: string);
    procedure Point(const Pt: T2dPoint);
  end;

{$EndRegion}

{$Region 'Sbrouitines'}

function FormatDouble(Value: Double; const FormatString: string): string;
function StrToXml(const s: string): string;

{$EndRegion}

implementation

{$Region 'Sbrouitines'}

function FormatDouble(Value: Double; const FormatString: string): string;
var P: PChar;
begin
  Result := Format(FormatString, [Value]);
  P := PChar(Result);
  if P^ = '-' then Inc(P);
  while (P^ >= '0') and (P^ <= '9') do Inc(P);
  if (P^ = '.') or (P^ = ',') then
  begin
    Inc(P);
    while (P^ >= '0') and (P^ <= '9') do Inc(P);
    repeat
      Dec(P);
    until P^ <> '0';
    if (P^ = '.') or (P^ = ',') then Dec(P);
    SetLength(Result, P - PChar(Result) + 1);
  end;
end;

function StrToXml(const s: string): string;
var
  MaxLen, i, Idx: integer;
begin
  MaxLen := 0;
  for i := 1 to Length(s) do begin
    case s[i] of
      '<': Inc(MaxLen, 4);
      '&': Inc(MaxLen, 5);
      '>': Inc(MaxLen, 4);
      '"': Inc(MaxLen, 6);
      '''': Inc(MaxLen, 6);
    else
      Inc(MaxLen);
    end;
  end;

  SetLength(Result, MaxLen);

  Idx := 1;
  for i := 1 to Length(s) do begin
    case s[i] of
      '<': begin Move('&lt;', Result[Idx], 4); Inc(Idx, 4); end;
      '&': begin Move('&amp;', Result[Idx], 5); Inc(Idx, 5); end;
      '>': begin Move('&gt;', Result[Idx], 4); Inc(Idx, 4); end;
      '"': begin Move('&quot;', Result[Idx], 6); Inc(Idx, 6); end;
      '''': begin Move('&apos;', Result[Idx], 6); Inc(Idx, 6); end;
    else
      begin
        Result[Idx] := s[i];
        Inc(Idx);
      end;
    end;
  end;
end;

{$EndRegion}

{$Region 'TSbHelper'}

procedure TSbHelper.NumAttr(const name: string; value, def: Double);
begin
  if SameValue(value, def) then exit;
  AppendFormat(' %s=''%s''', [name, FormatDouble(value, DF)]);
end;

procedure TSbHelper.StrAttr(const name, value: string);
begin
  if value = '' then exit;
  AppendFormat(' %s=''%s''', [name, StrToXml(value)]);
end;

procedure TSbHelper.Text(const value: string);
begin
  Append(StrToXml(value));
end;

procedure TSbHelper.Point(const Pt: T2dPoint);
begin
  AppendFormat(' %s %s', [FormatDouble(Pt.x, DF), FormatDouble(pt.y, DF)]);
end;

{$EndRegion}

{$Region 'TsvgShape'}

function TsvgShape.Fill(const color: string): TsvgShape;
begin
  FFill := color;
  Result := Self;
end;

function TsvgShape.Stroke(const color: string): TsvgShape;
begin
  FStroke := color;
  Result := Self;
end;

function TsvgShape.StrokeWidth(const Width: Double): TsvgShape;
begin
  FStrokeWidth := Width;
  Result := Self;
end;

procedure TsvgShape.Gen;
begin
  sb.StrAttr('fill', FFill);
  sb.StrAttr('stroke', FStroke);
  sb.NumAttr('stroke-width', FStrokeWidth, 1);
end;

{$EndRegion}

{$Region 'TsvgRect'}

constructor TsvgRect.Create(x, y, width, height: Double);
begin
  inherited Create;
  Fx := x;
  Fy := y;
  Fwidth := width;
  Fheight := height;
end;

function TsvgRect.Rx(const radius: Double): TsvgRect;
begin
  FRx := radius;
  Result := Self;
end;

function TsvgRect.Ry(const radius: Double): TsvgRect;
begin
  FRy := radius;
  Result := Self;
end;

procedure TsvgRect.Gen;
begin
  sb.Append('<rect');
  sb.NumAttr('x', Fx);
  sb.NumAttr('y', Fy);
  sb.NumAttr('width', Fwidth);
  sb.NumAttr('height', Fheight);
  inherited Gen;
  sb.AppendLine('/>');
end;

{$EndRegion}

{$Region 'TsvgPoly'}

constructor TsvgPoly.Create(Polygon: Boolean);
begin
  FPolygon := Polygon;
  FPoints := [];
end;

function TsvgPoly.Point(const pt: T2dPoint): TsvgPoly;
begin
  FPoints := FPoints + [pt];
  Result := Self;
end;

function TsvgPoly.Point(const x, y: Double): TsvgPoly;
begin
  FPoints := FPoints + [T2dPoint.From(x, y)];
  Result := Self;
end;

function TsvgPoly.Point(const pt: T2i): TsvgPoly;
begin
  FPoints := FPoints + [T2dPoint.From(pt.x, pt.y)];
  Result := Self;
end;

function TsvgPoly.Points(const points: T2dPoints): TsvgPoly;
var
  i: Integer;
begin
  for i := 0 to High(points) do
    Point(points[i]);
  Result := Self;
end;

procedure TsvgPoly.Gen;
var
  i: Integer;
begin
  if FPolygon then
    sb.Append('<polygon')
  else
    sb.Append('<polyline');
  for i := 0 to High(FPoints) do
    sb.Point(FPoints[i]);
  inherited Gen;
  sb.AppendLine('/>');
end;

{$EndRegion}

{$Region 'TsvgPolyline'}

constructor TsvgPolyline.Create;
begin
  inherited Create(False);
end;

{$EndRegion}

{$Region 'TsvgPolygon'}

constructor TsvgPolygon.Create;
begin
  inherited Create(True);
end;

{$EndRegion}

{$Region 'TsvgCircle'}

constructor TsvgCircle.Create(cx, cy, r: Double);
begin
  inherited Create;
  Fcx := cx;
  Fcy := cy;
  Fr := r;
end;

procedure TsvgCircle.Gen;
begin
  sb.Append('<circle');
  sb.NumAttr('cx', Fcx);
  sb.NumAttr('cy', Fcy);
  sb.NumAttr('r', Fr);
  inherited Gen;
  sb.AppendLine('/>');
end;

{$EndRegion}

{$Region 'TsvgEllipse'}

constructor TsvgEllipse.Create(cx, cy, rx, ry: Double);
begin
  inherited Create;
  Fcx := cx;
  Fcy := cy;
  Frx := rx;
  Fry := ry;
end;

procedure TsvgEllipse.Gen;
begin
  sb.Append('<ellipse');
  sb.NumAttr('cx', Fcx);
  sb.NumAttr('cy', Fcy);
  sb.NumAttr('rx', Frx);
  sb.NumAttr('ry', Fry);
  inherited Gen;
  sb.AppendLine('/>');
end;

{$EndRegion}

{$Region 'TsvgLine'}

constructor TsvgLine.Create(x1, y1, x2, y2: Double);
begin
  inherited Create;
  Fx1 := x1;
  Fy1 := y1;
  Fx2 := x2;
  Fy2 := y2;
end;

procedure TsvgLine.Gen;
begin
  sb.Append('<line');
  sb.NumAttr('x1', Fx1);
  sb.NumAttr('y1', Fy1);
  sb.NumAttr('x2', Fx2);
  sb.NumAttr('y2', Fy2);
  inherited Gen;
  sb.AppendLine('/>');
end;

{$EndRegion}

{$Region 'TsvgText'}

constructor TsvgText.Create(x, y: Double; const text: string);
begin
  inherited Create;
  Fx := x;
  Fy := y;
  Ftext := text;
end;

function TsvgText.Cls(const value: string): TsvgText;
begin
  Fcls := value;
  Result := Self;
end;

procedure TsvgText.Gen;
begin
  sb.Append('<text');
  sb.NumAttr('x', Fx);
  sb.NumAttr('y', Fy);
  inherited Gen;
  sb.Append('>');
  sb.Append(Ftext);
  sb.AppendLine('</text>');
end;

{$EndRegion}

{$Region 'TsvgPath'}

constructor TsvgPath.Create;
begin
  inherited;
  FOps := [];
end;

function TsvgPath.D(op: Char; const points: T2dPoints): TsvgPath;
var
  item: TPathOp;
begin
  item.op := op;
  item.points := points;
  FOps := FOps + [item];
  Result := Self;
end;

procedure TsvgPath.Gen;
begin

end;

{$EndRegion}

{$Region 'TsvgBuilder'}

constructor TsvgBuilder.Create(width, height: Double);
begin
  inherited Create;
  FWidth := width;
  FHeight := height;
  FShapes := TObjectList.Create;
end;

destructor TsvgBuilder.Destroy;
begin
  FShapes.Free;
  inherited;
end;

function TsvgBuilder.ViewBox(min_x, min_y, width, height: Double): TsvgBuilder;
begin
  FViewBox.min_x := min_x;
  FViewBox.min_y := min_y;
  FViewBox.width := width;
  FViewBox.height := height;
  Result := Self;
end;

function TsvgBuilder.Rect(x, y, width, height: Double): TsvgRect;
begin
  Result := TsvgRect.Create(x, y, width, height);
end;

function TsvgBuilder.Circle(cx, cy, r: Double): TsvgCircle;
begin
  Result := TsvgCircle.Create(cx, cy, r);
end;

function TsvgBuilder.Ellipse(cx, cy, rx, ry: Double): TsvgEllipse;
begin
  Result := TsvgEllipse.Create(cx, cy, rx, ry);
end;

function TsvgBuilder.Line(x1, y1, x2, y2: Double): TsvgLine;
begin
  Result := TsvgLine.Create(x1, y1, x2, y2);
end;

function TsvgBuilder.Polyline: TsvgPolyline;
begin
  Result := TsvgPolyline.Create;
end;

function TsvgBuilder.Polygon: TsvgPolygon;
begin
  Result := TsvgPolygon.Create;
end;

function TsvgBuilder.Path: TsvgPath;
begin
  Result := TsvgPath.Create;
end;

function TsvgBuilder.Text(x, y: Double; const text: string): TsvgText;
begin
  Result := TsvgText.Create(x, y, text);
end;

function TsvgBuilder.ToString: string;
var
  sb: TStringBuilder;
begin
  sb := TStringBuilder.Create;
  try

    Result := sb.ToString;
  finally
    sb.Free;
  end;
end;

{$EndRegion}

end.

