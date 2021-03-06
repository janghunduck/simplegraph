unit Dock;

interface

uses Classes, SysUtils, Forms, ExtCtrls, Controls, Windows, Dialogs,
     Graphics;

type
  TCingDockTree = class(TDockTree)
  protected
    property DockSite;
  public
    GrabberSize: Integer;
    procedure AdjustDockRect(Control: TControl; var ARect: TRect); override;
    procedure PaintDockFrame(Canvas: TCanvas; Control: TControl; const ARect: TRect); override;
    procedure PaintSite(DC: HDC); override;
    constructor Create(DockSite: TWinControl);
  end;

  TCingDockPanel = class(TPanel)
  private
  protected
  public
    DockingManager: TCingDockTree;
    constructor Create(Owner: TWinControl);
    procedure SetGrabberSize(size: Integer);
  published
  end;

  TDockManager = class(TWinControl)
  private
    fOwner : TForm;           { main form }
    fDockDlg : TForm;         { dock client form }
    fPanel : TCingDockPanel;  { dock site }
    fSplitter: TSplitter;
    fIsDock: boolean;
    procedure SetDockDlg(dlg: TForm);
    function GetDockDlg: TForm;
    procedure DockDrop(Sender: TObject; Source: TDragDockObject;X, Y: Integer);
    procedure DockOver(Sender: TObject; Source: TDragDockObject;X, Y: Integer; State: TDragState; var Accept: Boolean);
    procedure UnDock(Sender: TObject; Client: TControl;NewTarget: TWinControl; var Allow: Boolean);
    procedure GetSiteInfo(Sender: TObject; DockClient: TControl;var InfluenceRect: TRect; MousePos: TPoint; var CanDock: Boolean);
  public
    constructor create(owner: TForm);
    procedure Hide;
    procedure Show;
    property Owner: TForm read fOwner;
    property DockDlg: TForm read GetDockDlg write SetDockDlg;
    property IsDock:boolean read fIsDock;
  end;

implementation


constructor TDockManager.create(owner: TForm);
begin
  fOwner := owner;
  fPanel := TCingDockPanel.create(fOwner);
  fPanel.Parent := fOwner;
  fPanel.Align  := alRight;
  fPanel.width  := 400;
  fPanel.SetGrabberSize(18);       { important : drag title bar chanage }
  //fPanel.BevelOuter := bvNone;
  fPanel.Docksite := true;

  fSplitter := TSplitter.create(nil);
  fSplitter.Parent := fOwner;
  fSplitter.Align := alRight;

  fPanel.OnDockDrop := DockDrop;
  fPanel.OnDockOver := DockOver;

  //fPanel.OnDockEnd
  fPanel.OnUnDock      := UnDock;
  fPanel.OnGetSiteInfo := GetSiteInfo;

  inherited create(nil);
end;

procedure TDockManager.SetDockDlg(dlg: TForm);
begin
  if dlg <> nil then
  begin
    fDockDlg := dlg;
    dlg.DragKind := dkDock;
    dlg.DragMode := dmAutomatic;
    dlg.ManualDock(fPanel);
    fIsDock := True;
    Show;
  end;
end;

function TDockManager.GetDockDlg: TForm;
begin
  result := fDockDlg;
end;

procedure TDockManager.Hide;
begin
  //if not fDockDlg.Visible then fDockDlg.Hide;
  fPanel.Visible := false;
  fSplitter.Visible := false;
end;

procedure TDockManager.Show;
begin
  if fIsDock then
  begin
    //if fDockDlg.Visible then fDockDlg.Show;
    //SetDockDlg(fDockDlg);
    fPanel.Visible := true;
    fSplitter.Visible := true;
    //draw and paint
  end else
  begin
    fPanel.visible := false;
    fSplitter.visible := false;
  end;
end;

procedure TDockManager.DockDrop(Sender: TObject; Source: TDragDockObject;X, Y: Integer);
begin
  fPanel.width := 400;
  fIsDock := True;
  //show;
end;

procedure TDockManager.DockOver(Sender: TObject; Source: TDragDockObject;X, Y: Integer; State: TDragState; var Accept: Boolean);
begin

end;

procedure TDockManager.UnDock(Sender: TObject; Client: TControl;NewTarget: TWinControl; var Allow: Boolean);
begin
  fPanel.width := 1;
  fIsDock := false;
  //Hide;
end;

procedure TDockManager.GetSiteInfo(Sender: TObject; DockClient: TControl;var InfluenceRect: TRect; MousePos: TPoint; var CanDock: Boolean);
begin

end;

{ TCingDockTree }

constructor TCingDockTree.Create(DockSite: TWinControl);
begin
  inherited Create(DockSite);
  GrabberSize := 10;
end;

procedure TCingDockTree.AdjustDockRect(Control: TControl; var ARect: TRect);
begin
  if DockSite.Align in [alTop, alBottom] then
    Inc(ARect.Left, GrabberSize)
  else
    Inc(ARect.Top, GrabberSize);
end;

procedure TCingDockTree.PaintDockFrame(Canvas: TCanvas; Control: TControl; const ARect: TRect);

  procedure DrawCloseButton(Left, Top: Integer);
  var
    R: TRect;
  begin
    R := Rect(Left + 2, Top + 2, Left + GrabberSize - 4, Top + GrabberSize - 4);
    //R := Rect(Left, Top, Left + GrabberSize - 2, Top + GrabberSize - 2);
    with Canvas do begin
      Rectangle(R);
      MoveTo(Left + 4, Top + 4);
      LineTo(Left + GrabberSize - 6, Top + GrabberSize - 6);
      MoveTo(Left + GrabberSize - 7, Top + 4);
      LineTo(Left + 3, Top + GrabberSize - 6);
    end;
  end;

var
  R: TRect;
  Title: String;
begin
  R := ARect;
  R.Bottom := R.Top + GrabberSize;
  with Canvas do begin
    if (Control.Tag = 0) then begin
      Brush.Color := clBtnFace;
      Pen.Color := clBtnShadow;
      Font.Color := clBtnText;
    end else begin
      Brush.Color := clActiveCaption;
      Pen.Color := clActiveCaption;
      Font.Color := clCaptionText;
    end;
    FillRect(R);
    Rectangle(R.Left, R.Top, R.Right, R.Bottom);
    if (Control is TPanel) then begin
      Font.Name := (Control as TPanel).Font.Name;
      Title := '   ' + (Control as TPanel).Caption;
    end else begin
      Title := '   Properties ...';// + Control.ClassName;
    end;
  end;
  with ARect do begin
    Canvas.TextOut(Left + 10, Top + 2, Title);
    if Control.Tag <> 0 then Canvas.Pen.Color := clCaptionText;
    if DockSite.Align in [alTop, alBottom, alRight] then
      DrawCloseButton(Left + 1, Top + 1)
    else
      DrawCloseButton(Right - GrabberSize + 1, Top + 1);
  end;
//
end;

procedure TCingDockTree.PaintSite(DC: HDC);
var
  Canvas: TControlCanvas;
  Control: TControl;
  I: Integer;
  R: TRect;
begin
  Canvas := TControlCanvas.Create;
  try
    Canvas.Control := DockSite;
    Canvas.Lock;
    try
      Canvas.Handle := DC;
      try
        for I := 0 to DockSite.ControlCount - 1 do
        begin
          Control := DockSite.Controls[I];
          if Control.Visible and (Control.HostDockSite = DockSite) then begin
            R := Control.BoundsRect;
            AdjustDockRect(Control, R);
            Dec(R.Left, 2 * (R.Left - Control.Left));
            Dec(R.Top, 2 * (R.Top - Control.Top));
            Dec(R.Right, 2 * (Control.Width - (R.Right - R.Left)));
            Dec(R.Bottom, 2 * (Control.Height - (R.Bottom - R.Top)));
            PaintDockFrame(Canvas, Control, R);
          end;
        end;
      finally
        Canvas.Handle := 0;
      end;
    finally
      Canvas.Unlock;
    end;
  finally
    Canvas.Free;
  end;
end;

{ TCingDockPanel }

constructor TCingDockPanel.Create(Owner: TWinControl);
begin
  inherited Create(Owner);
  DockingManager := nil;
end;

procedure TCingDockPanel.SetGrabberSize(size: Integer);
begin
  self.UseDockManager:=false;
  if(DockingManager<>nil) then DockingManager.Free;


  DockingManager := TCingDockTree.Create(self);
  DockingManager.GrabberSize := size;
  self.DockManager := DockingManager;
  //TXPDockTree.Create(self);
  self.UseDockManager:= true;

end;


end.
