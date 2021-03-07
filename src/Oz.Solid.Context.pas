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

unit Oz.Solid.Context;

interface

{$Region 'Uses'}

uses
  Oz.Solid.Types,
  Oz.Solid.Expr,
  Oz.Solid.Utils;

{$EndRegion}

{$T+}
{$SCOPEDENUMS ON}

{$Region 'TsdContextHelper'}

type
  TsdContextHelper = class helper for TsdContext
    function GetParam(h: hParam): PsdParam; inline;
  end;

{$EndRegion}

implementation

{$Region 'TsdContextHelper'}

function TsdContextHelper.GetParam(h: hParam): PsdParam;
begin
end;

{$EndRegion}

end.

