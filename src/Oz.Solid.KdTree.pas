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

unit Oz.Solid.KdTree;

interface

{$T+}

const
  DIMENSIONS = 3;
  BUCKET_SIZE = 10;

type
  TkdPoint = array [0 .. DIMENSIONS - 1] of Double;

  PkdNode = ^TkdNode;
  TkdNode = record
    case leaf: boolean of
      True:
        (bucketStart, bucketStop: Integer;
        );
      False:
        (dim: Integer;
          value: Double;
          left, right: PkdNode;
        )
  end;

  TkdPoints = TArray<TkdPoint>;

procedure Test;

implementation

var
  nodes: TkdPoints;
  head: PkdNode;
  points: TkdPoints;

procedure Init(var count: Integer; var points: TkdPoints);
var
  j, i: Integer;
begin
  SetLength(points, count);
  for i := 0 to count - 1 do
  begin
    for j := 0 to DIMENSIONS - 1 do
      Read(input, points[i, j]);
  end;
end;

function FindBestDim(lo, hi: Integer): Integer;
var
  j, i, bestDim: Integer;
  lowVals, highVals: array [0 .. DIMENSIONS - 1] of Double;
begin
  for i := 0 to hi - lo do
  begin
    for j := 0 to DIMENSIONS - 1 do
    begin
      if i = 0 then
      begin
        highVals[j] := nodes[i, j];
        lowVals[j] := nodes[i, j];
      end
      else if nodes[i, j] < lowVals[j] then
        lowVals[j] := nodes[i, j]
      else if nodes[i, j] > highVals[j] then
        highVals[j] := nodes[i, j];
    end;
  end;
  bestDim := 0;
  for j := 0 to DIMENSIONS - 1 do
  begin
    if abs(highVals[j] - lowVals[j]) >
      abs(highVals[bestDim] - lowVals[bestDim]) then
      bestDim := j
  end;
  FindBestDim := bestDim;
end;

function FindMedian(dim, lo, hi, k: Integer): Integer;
var
  pivot, i, j, smallCtr, largeCtr, equalCtr: Integer;
  pivotVal: Double;
  small, large, equal: TkdPoints;
begin
  SetLength(small, hi - lo + 1);
  SetLength(large, hi - lo + 1);
  SetLength(equal, hi - lo + 1);
  pivot := random(hi - lo) + lo;
  smallCtr := 0;
  largeCtr := 0;
  equalCtr := 0;
  pivotVal := nodes[pivot, dim];
  for i := lo to hi do
  begin
    if nodes[i, dim] < pivotVal then
    begin
      small[smallCtr] := nodes[i];
      smallCtr := smallCtr + 1
    end
    else if nodes[i, dim] > pivotVal then
    begin
      large[largeCtr] := nodes[i];
      largeCtr := largeCtr + 1
    end
    else
    begin
      equal[equalCtr] := nodes[i];
      equalCtr := equalCtr + 1
    end
  end;

  for i := 0 to smallCtr - 1 do
    for j := 0 to DIMENSIONS - 1 do
      nodes[i + lo, j] := small[i, j];
  for i := 0 to equalCtr - 1 do
    for j := 0 to DIMENSIONS - 1 do
      nodes[i + lo + smallCtr, j] := equal[i, j];
  for i := 0 to largeCtr - 1 do
    for j := 0 to DIMENSIONS - 1 do
      nodes[i + lo + smallCtr + equalCtr, j] := large[i, j];
  SetLength(small, 0);
  SetLength(equal, 0);
  SetLength(large, 0);

  if (smallCtr + equalCtr = k) or
    ((equalCtr > smallCtr) and (equalCtr > largeCtr)) then
    FindMedian := smallCtr + equalCtr + lo - 1
  else if smallCtr + equalCtr < k then
    FindMedian := FindMedian(dim, lo + smallCtr + equalCtr, hi, k - smallCtr - equalCtr)
  else
    FindMedian := FindMedian(dim, lo, hi - largeCtr, k);
end;

function MakeNodes(lo, hi: Integer): PkdNode;
var
  bestDim, k, medianIndex: Integer;
  median: Double;
  tmpNode: PkdNode;
begin
  New(tmpNode);
  with tmpNode^ do
  begin
    leaf := hi - lo < BUCKET_SIZE;
    case leaf of
      True:
        begin
          bucketStart := lo;
          bucketStop := hi;
        end;
      False:
        begin
          bestDim := FindBestDim(lo, hi);
          k := (hi + 2 - lo) div 2;
          medianIndex := FindMedian(bestDim, lo, hi, k);
          median := nodes[medianIndex, bestDim];
          dim := bestDim;
          value := median;
          left := MakeNodes(lo, medianIndex);
          right := MakeNodes(medianIndex + 1, hi);
        end;
    end;
    MakeNodes := tmpNode;
  end;
end;

procedure BuildKDTree;
var
  nodeCount: Integer;
begin
  Write(output, 'What is the node count? ');
  Read(input, nodeCount);
  while nodeCount < 1 do
  begin
    Write(output, 'Please give a node count > 0:  ');
    Read(input, nodeCount);
  end;
  Init(nodeCount, nodes);
  randomize;
  head := MakeNodes(0, nodeCount - 1);
end;

procedure PrintBucket(var node: PkdNode);
var
  i, j: Integer;
begin
  Writeln(output, 'Bucket: ');
  for i := node.bucketStart to node.bucketStop do
  begin
    for j := 0 to DIMENSIONS - 1 do
      Write(output, nodes[i, j]:5:1, ' ');
    Writeln(output);
  end;
end;

procedure PrintPoint(var pt: TkdPoint);
var
  j: Integer;
begin
  Writeln(output);
  Writeln(output, 'Probe: ');
  for j := 0 to DIMENSIONS - 1 do
    Write(output, pt[j]:5:1, ' ');
  Writeln(output);
end;

procedure FindBucket(var pt: TkdPoint);
var
  node: PkdNode;
begin
  node := head;
  while not node.leaf do
  begin
    if pt[node.dim] > node.value then
      node := node.right
    else
      node := node.left;
  end;
  PrintPoint(pt);
  PrintBucket(node);
end;

procedure ProbeKDTree;
var
  n, i: Integer;
begin
  Write(output, 'What is the probe count? ');

  Read(input, n);
  while n < 1 do
  begin
    Write(output, 'Please give a probe count > 0: ');
    Read(input, n);
  end;
  Init(n, points);
  for i := 0 to n - 1 do
    FindBucket(points[i]);
end;

function FreeTree(node: PkdNode): PkdNode;
begin
  if not(node.leaf) then
  begin
    case node.left^.leaf of
      True:
        Dispose(node.left);
      False:
        node.left := FreeTree(node.left);
    end;
    case node.right^.leaf of
      True:
        Dispose(node.right);
      False:
        node.right := FreeTree(node.right);
    end;
  end;
  Dispose(node);
  FreeTree := node;
end;

procedure Test;
begin
  BuildKDTree;
  ProbeKDTree;
  SetLength(nodes, 0);
  SetLength(points, 0);
  head := FreeTree(head);
end;

end.

