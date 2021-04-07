program SolidTests;

{$IFDEF CONSOLE_TESTRUNNER}
{$APPTYPE CONSOLE}
{$ENDIF}

uses
  FastMM4,
  DUnitTestRunner,
  TestUtils in 'TestUtils.pas',
  Oz.Solid.Types in '..\src\Oz.Solid.Types.pas',
  Oz.Solid.Intersect in '..\src\Oz.Solid.Intersect.pas',
  Oz.Solid.Boolean in '..\src\Oz.Solid.Boolean.pas',
  Oz.Solid.VectorInt in '..\src\Oz.Solid.VectorInt.pas',
  Oz.Solid.EarTri in '..\src\Oz.Solid.EarTri.pas',
  Oz.Solid.Svg in '..\src\Oz.Solid.Svg.pas',
  Oz.Solid.Bezier in '..\src\Oz.Solid.Bezier.pas',
  Oz.Solid.DelaunayTri in '..\src\Oz.Solid.DelaunayTri.pas',
  Oz.Solid.Polygon in '..\src\Oz.Solid.Polygon.pas',
  Oz.Solid.KdTree in '..\src\Oz.Solid.KdTree.pas',
  Oz.SGL.Collections in '..\..\Oz-SGL\src\Oz.SGL.Collections.pas',
  Oz.SGL.HandleManager in '..\..\Oz-SGL\src\Oz.SGL.HandleManager.pas',
  Oz.SGL.Hash in '..\..\Oz-SGL\src\Oz.SGL.Hash.pas',
  Oz.SGL.Heap in '..\..\Oz-SGL\src\Oz.SGL.Heap.pas',
  Oz.Solid.Utils in '..\src\Oz.Solid.Utils.pas',
  Oz.Solid.Expr in '..\src\Oz.Solid.Expr.pas',
  Oz.Solid.Context in '..\src\Oz.Solid.Context.pas',
  Oz.Solid.Matrix in '..\src\Oz.Solid.Matrix.pas';

{$R *.RES}

begin
  DUnitTestRunner.RunRegisteredTests;
end.

