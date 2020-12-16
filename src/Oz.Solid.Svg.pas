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
  System.Classes, System.SysUtils, System.Contnrs,
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
  public
    // presentation attribute that defines the color
    function Fill(const color: string): TsvgShape;
    // presentation attribute defining the color used to paint the outline of the shape
    function Stroke(const color: string): TsvgShape;
    // presentation attribute defining the width of the stroke to be applied to the shape
    function StrokeWidth(const Width: Double): TsvgShape;
  end;

{$EndRegion}

{$Region 'TsvgRect: Rect element'}

  TsvgRect = class(TsvgShape)
  private
    FRx: Double;
    FRy: Double;
  public
    // The x radius of the corners of the rectangle
    function Rx(const radius: Double): TsvgRect;
    // The y radius of the corners of the rectangle
    function Ry(const radius: Double): TsvgRect;
  end;

{$EndRegion}

{$Region 'TsvgPoly'}

  TsvgPoly = class(TsvgShape)
  private
    FPoints: TArray<T2dPoint>;
  public
    function Point(const pt: T2dPoint): TsvgPoly; overload;
    function Point(const x, y: Double): TsvgPoly; overload;
    function Point(const pt: T2i): TsvgPoly; overload;
    function Points(const points: T2dPoints): TsvgPoly;
  end;

{$EndRegion}

{$Region 'Elements'}

  TsvgCircle = class(TsvgShape);

  TsvgEllipse = class(TsvgShape);

  TsvgLine = class(TsvgShape);

  TsvgPolyline = class(TsvgPoly);

  TsvgPolygon = class(TsvgPoly);

{$EndRegion}

{$Region 'TsvgPoly'}

  TsvgPath = class(TsvgShape)
  type
    TPathOp = record
      op: Char;
      points: T2dPoints
    end;
  private
    FOps: TArray<TPathOp>;
  public
    // op
    //   MoveTo: M, m
    //   LineTo: L, l, H, h, V, v
    //   Cubic Bezier Curve: C, c, S, s
    //   Quadratic Bezier Curve: Q, q, T, t
    //   Elliptical Arc Curve: A, a
    //   ClosePath: Z, z
    function D(op: Char; const points: T2dPoints): TsvgPath;
  end;

{$EndRegion}

{$Region 'TsvgPoly'}

  TsvgText = class(TsvgShape)
    function Cls(const value: string): TsvgText;
  end;

{$EndRegion}

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
    destructor Destroy; overload;
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
    // The <path> SVG element is the generic element to define a shape.
    // All the basic shapes can be created with a path element.
    function Path: TsvgPath;
    // The SVG <text> element draws a graphics element consisting of text.
    function Text(x, y: Double; const text, cls: string): TsvgText;
    function ToString: string;
  end;

{$EndRegion}

implementation

{$Region 'TsvgShape'}

function TsvgShape.Fill(const color: string): TsvgShape;
begin
  FFill := color;
end;

function TsvgShape.Stroke(const color: string): TsvgShape;
begin
  FStroke := color;
end;

function TsvgShape.StrokeWidth(const Width: Double): TsvgShape;
begin
  FStrokeWidth := Width;
end;

{$EndRegion}

{$Region 'TsvgRect'}

function TsvgRect.Rx(const radius: Double): TsvgRect;
begin
  FRx := radius;
end;

function TsvgRect.Ry(const radius: Double): TsvgRect;
begin
  FRy := radius;
end;

{$EndRegion}

{$Region 'TsvgPoly'}

function TsvgPoly.Point(const pt: T2dPoint): TsvgPoly;
begin
  FPoints := FPoints + [pt];
end;

function TsvgPoly.Point(const x, y: Double): TsvgPoly;
begin
  FPoints := FPoints + [T2dPoint.From(x, y)];
end;

function TsvgPoly.Point(const pt: T2i): TsvgPoly;
begin
  FPoints := FPoints + [T2dPoint.From(pt.x, pt.y)];
end;

function TsvgPoly.Points(const points: T2dPoints): TsvgPoly;
var
  i: Integer;
begin
  for i := 0 to High(points) do
    Point(points[i]);
end;

{$EndRegion}

{$Region 'TsvgPoly'}

function TsvgPath.D(op: Char; const points: T2dPoints): TsvgPath;
var
  item: TPathOp;
begin
  item.op := op;
  item.points := points;
  FOps := FOps + [item];
end;

{$EndRegion}

{$Region 'TsvgText'}

function TsvgText.Cls(const value: string): TsvgText;
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
end;

function TsvgBuilder.Rect(x, y, width, height: Double): TsvgRect;
begin

end;

function TsvgBuilder.Circle(cx, cy, r: Double): TsvgCircle;
begin

end;

function TsvgBuilder.Ellipse(cx, cy, rx, ry: Double): TsvgEllipse;
begin

end;

function TsvgBuilder.Line(x1, y1, x2, y2: Double): TsvgLine;
begin

end;

function TsvgBuilder.Polyline: TsvgPolyline;
begin

end;

function TsvgBuilder.Polygon: TsvgPolygon;
begin

end;

function TsvgBuilder.Path: TsvgPath;
begin

end;

function TsvgBuilder.Text(x, y: Double; const text, cls: string): TsvgText;
begin

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

