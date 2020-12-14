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
  System.Classes, System.SysUtils, Oz.Solid.VectorInt;

{$EndRegion}

{$T+}

{$Region 'TsdSvg'}

type

  TsdSvg = class
  type
    TsvgRoot = class
    end;
    TRect = class
    end;
    TLine = class
    end;
    TPolyline = class
    end;
    TPolygon = class
    end;
    TPath = class
    end;
  private
    FWidth: Double;
    FHeight: Double;
  public
    function Init(Width, Height: Double): TsvgRoot;
    // <rect x="10" y="10" width="30" height="30"
    //  stroke="black" fill="transparent" stroke-width="5"/>
    function Rect(x, y, Width, Height: Double): TRect;
    // <line x1="10" x2="50" y1="110" y2="150"
    //  stroke="orange" fill="transparent" stroke-width="5"/>
    function Line(x1, y1, x2, y2: Double): TLine;
    // <polyline points="60 110 65 120 70 115 75 130 80 125 85 140 90 135 95 150 100 145"
    //  stroke="orange" fill="transparent" stroke-width="5"/>
    function Polyline: TPolyline;
    // polygon points="50 160 55 180 70 180 60 190 65 205 50 195 35 205 40 190 30 180 45 180"
    //  stroke="green" fill="transparent" stroke-width="5"/>
    function Polygon: TPolygon;
    // <path d="M20,230 Q40,205 50,230 T90,230" fill="none" stroke="blue" stroke-width="5"/>
    function Path: TPath;
    function ToString: string;
  end;

{$EndRegion}

implementation

{ TsdSvg }

function TsdSvg.Init(Width, Height: Double): TsvgRoot;
begin

end;

function TsdSvg.Line(x1, y1, x2, y2: Double): TLine;
begin

end;

function TsdSvg.Path: TPath;
begin

end;

function TsdSvg.Polygon: TPolygon;
begin

end;

function TsdSvg.Polyline: TPolyline;
begin

end;

function TsdSvg.Rect(x, y, Width, Height: Double): TRect;
begin

end;

function TsdSvg.ToString: string;
begin

end;

end.

