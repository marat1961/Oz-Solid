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

{$Region 'TsvgBuilder'}

type

  // Shapes and text context elements
  TsvgShape = class
    // presentation attribute that defines the color
    function Fill(const color: string): TsvgShape;
    // presentation attribute defining the color used to paint the outline of the shape
    function Stroke(const color: string): TsvgShape;
    // presentation attribute defining the width of the stroke to be applied to the shape
    function StrokeWidth(const Width: Double): TsvgShape;
  end;

  // The <rect> element draws a rectangle on the screen.
  TsvgRect = class(TsvgShape)
    // The x radius of the corners of the rectangle
    function Rx(const radius: Double): TsvgRect;
    // The y radius of the corners of the rectangle
    function Ry(const radius: Double): TsvgRect;
  end;

  // The <circle> element draws a circle on the screen.
  TsvgCircle = class(TsvgShape);

  // An <ellipse> is a more general form of the <circle> element.
  TsvgEllipse = class(TsvgShape);

  // The <line> element is an SVG basic shape used
  // to create a line connecting two points.
  TsvgLine = class(TsvgShape);

  TsvgPoly = class(TsvgShape)
    function Point(const x, y: Double): TsvgPoly; overload;
    function Point(const pt: T2dPoint): TsvgPoly; overload;
    function Point(const pt: T2i): TsvgPoly; overload;
    function Points(const points: T2dPoints): TsvgPoly;
  end;

  // A <polyline> is a group of connected straight lines.
  TsvgPolyline = class(TsvgPoly);

  // The <polygon> element defines a closed shape consisting of a set
  // of connected straight line segments.
  // The last point is connected to the first point.
  TsvgPolygon = class(TsvgPoly);

  // The <path> SVG element is the generic element to define a shape.
  // All the basic shapes can be created with a path element.
  TsvgPath = class(TsvgShape)
    // op
    //   MoveTo: M, m
    //   LineTo: L, l, H, h, V, v
    //   Cubic Bezier Curve: C, c, S, s
    //   Quadratic Bezier Curve: Q, q, T, t
    //   Elliptical Arc Curve: A, a
    //   ClosePath: Z, z
    function D(op: Char; const points: T2dPoints): TsvgPath;
  end;

  TsvgText = class(TsvgShape)
    function Cls(const value: string): TsvgText;
  end;

  TViewBox = record
    min_x: Double;
    min_y: Double;
    width: Double;
    height: Double;
  end;

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
    function Rect(x, y, width, height: Double): TsvgRect;
    function Circle(cx, cy, r: Double): TsvgCircle;
    function Ellipse(cx, cy, rx, ry: Double): TsvgEllipse;
    function Line(x1, y1, x2, y2: Double): TsvgLine;
    function Polyline: TsvgPolyline;
    function Polygon: TsvgPolygon;
    function Path: TsvgPath;
    // The SVG <text> element draws a graphics element consisting of text.
    function Text(x, y: Double; const text, cls: string): TsvgText;
    function ToString: string;
  end;

{$EndRegion}

implementation

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

