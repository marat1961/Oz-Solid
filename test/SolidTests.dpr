program SolidTests;

{$IFDEF CONSOLE_TESTRUNNER}
{$APPTYPE CONSOLE}
{$ENDIF}

uses
  FastMM4,
  DUnitTestRunner,
  TestUtils in 'TestUtils.pas',
  Oz.SGL.Collections in '..\..\Oz-SGL\src\Oz.SGL.Collections.pas',
  Oz.SGL.Heap in '..\..\Oz-SGL\src\Oz.SGL.Heap.pas',
  Oz.Solid.Types in '..\src\Oz.Solid.Types.pas',
  Oz.SGL.HandleManager in '..\..\Oz-SGL\src\Oz.SGL.HandleManager.pas',
  Oz.Solid.Boolean in '..\src\Oz.Solid.Boolean.pas',
  Oz.Solid.VectorInt in '..\src\Oz.Solid.VectorInt.pas',
  Oz.Solid.EarTri in '..\src\Oz.Solid.EarTri.pas',
  Oz.Solid.Svg in '..\src\Oz.Solid.Svg.pas',
  Oz.Solid.DelaunayTri in '..\src\Oz.Solid.DelaunayTri.pas';

{$R *.RES}

begin
  DUnitTestRunner.RunRegisteredTests;
end.

