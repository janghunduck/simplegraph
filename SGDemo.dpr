program SGDemo;

uses
  Forms,
  Main in 'src\Main.pas' {MainForm},
  DesignProp in 'src\DesignProp.pas' {DesignerProperties},
  ObjectProp in 'src\ObjectProp.pas' {ObjectProperties},
  LinkProp in 'src\LinkProp.pas' {LinkProperties},
  NodeProp in 'src\NodeProp.pas' {NodeProperties},
  AboutDelphiArea in 'src\AboutDelphiArea.pas' {About},
  UsageHelp in 'src\UsageHelp.pas' {HelpOnActions},
  MarginsProp in 'src\MarginsProp.pas' {MarginDialog},
  AlignDlg in 'src\AlignDlg.pas' {AlignDialog},
  SizeDlg in 'src\SizeDlg.pas' {SizeDialog},
  Equations in 'src\Equations.pas',
  SimpleGraph in 'src\SimpleGraph.pas',
  UsefulUtils in 'src\UsefulUtils.pas',
  PropDlg in 'src\PropDlg.pas' {PropDialog},
  Dock in 'src\Dock.pas',
  Spline in 'src\Spline.pas',
  sgutil in 'src\sgutil.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Simple Graph Demo';
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
