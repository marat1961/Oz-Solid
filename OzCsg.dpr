program Csg;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  FastMM4,
  System.SysUtils;

begin
  try
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
