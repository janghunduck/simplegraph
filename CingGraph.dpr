library CingGraph;

{ Important note about DLL memory management: ShareMem must be the
  first unit in your library's USES clause AND your project's (select
  Project-View Source) USES clause if your DLL exports any procedures or
  functions that pass strings as parameters or function results. This
  applies to all strings passed to and from your DLL--even those that
  are nested in records and classes. ShareMem is the interface unit to
  the BORLNDMM.DLL shared memory manager, which must be deployed along
  with your DLL. To avoid using BORLNDMM.DLL, pass string information
  using PChar or ShortString parameters. }

uses
  SysUtils,
  Classes,
  Controls,
  ExtCtrls,
  Forms,
  Dialogs,
  Windows,
  Main in 'src\Main.pas' {MainForm},
  AboutDelphiArea in 'src\AboutDelphiArea.pas' {About},
  AlignDlg in 'src\AlignDlg.pas' {AlignDialog},
  DesignProp in 'src\DesignProp.pas' {DesignerProperties},
  LinkProp in 'src\LinkProp.pas' {LinkProperties},

  MarginsProp in 'src\MarginsProp.pas' {MarginDialog},
  NodeProp in 'src\NodeProp.pas' {NodeProperties},
  ObjectProp in 'src\ObjectProp.pas' {ObjectProperties},
  SizeDlg in 'src\SizeDlg.pas' {SizeDialog},
  UsageHelp in 'src\UsageHelp.pas' {HelpOnActions},
  Equations in 'src\Equations.pas',
  SimpleGraph in 'src\SimpleGraph.pas',
  UsefulUtils in 'src\UsefulUtils.pas';

{$I D:\Keditor\Keditor_src\CoreSource\KeCore\Plugins.inc}
{$R *.res}

const
  MENU_CAPTION = 'Cing Graph 0.1';
  

var
  MainWindowHandle: THandle;


function DefMenuCaption(Caption:PChar; CaptionLen:Integer):Integer; stdcall;
var
  S : String;
begin
  S := MENU_CAPTION;
  Result := length(S);
  StrLCopy(Caption, PChar(S), Result);
end;

function DefPluginWindow(Handle: THandle):THandle; stdcall;
var Form : TMainForm;
begin

  try
  Form := TMainForm.Create(nil);
  Form.BorderStyle := bsNone;
  
  Windows.SetParent(Form.Handle, Handle);
  MainWindowHandle := Form.Handle;
  Application.InsertComponent(Form);
  Form.Show;
  Result := Form.Handle;
  except on E:Exception do
    ShowMessage('DefPluginWindow Error:' + E.Message);
  end;

end;


function ControlFromHandle(AWindow: THandle): TMainForm;
var i: Integer;
begin
  with Application do
    for i := 0 to ComponentCount - 1 do
      if Components[i] is TMainForm then
        begin
          Result := TMainForm(Components[i]);
          Exit;
        end;
  Result := nil;
end;

procedure DefPluginDestroyWin(WinHandle: THandle); stdcall;
var Form: TMainForm;
begin
  try
    Form := ControlFromHandle(WinHandle);
    if Form <> nil then Form.Free;
  except on E: Exception do
    ShowMessage('CingFinder Dll Form Free Error: ' + E.Message);
  end;

end;

procedure DefRecive(Data: TRevData); stdcall;
begin

end;


function DefMainMenu: PChar; stdcall;
var
  s: string;
begin
  //s:= '[';
  //s:= s + '{root2,{child1, child2, {child3,{a1,a2,a3}}}},';
  //s:= s + '{root3,{{child1,{m1,m2,m3}}, child2, {child3,{a1,a2,a3}}}';
  //s:= s + ']';

  s := '[{About,{About}}]';
  Result := PChar(s);
end;

procedure DefOnPluginMenuEvent(Handle: THandle; Name:PChar); stdcall;
var
  sAbout : string;
begin
  if Name = '&About' then
  begin
    sAbout := 'Cing Graph Plugin v 0.1' + #10#13;
    sAbout := sAbout + 'Thank!';
    ShowMessage(sAbout);
  end;

end;


exports

DefMenuCaption,
DefPluginWindow,
DefPluginDestroyWin,
DefRecive, // not use
DefMainMenu,
DefOnPluginMenuEvent;

end.
