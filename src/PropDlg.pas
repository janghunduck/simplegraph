unit PropDlg;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, ExtCtrls, LbStaticText, CheckLst, ExtDlgs,
  SimpleGraph;

type
  TPropDialog = class(TForm)
    FontDialog: TFontDialog;
    ColorDialog: TColorDialog;
    OpenPictureDialog: TOpenPictureDialog;
    PageControl: TPageControl;
    TabSheet1: TTabSheet;
    DesignerPanel1: TPanel;
    LbStaticText2: TLbStaticText;
    Horzsize: TRadioGroup;
    Vertsize: TRadioGroup;
    Panel1: TPanel;
    GroupBox2: TGroupBox;
    Label9: TLabel;
    ShowGrid: TCheckBox;
    SnapToGrid: TCheckBox;
    Edit2: TEdit;
    GridSize: TUpDown;
    GroupBox3: TGroupBox;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    DesignerBackgroundColor: TPanel;
    BackgroundColor: TShape;
    Panel3: TPanel;
    MarkerColor: TShape;
    DesignerGridColor: TPanel;
    GridColor: TShape;
    LbStaticText1: TLbStaticText;
    Panel5: TPanel;
    LbStaticText3: TLbStaticText;
    HorzAlign: TRadioGroup;
    VertAlign: TRadioGroup;
    TabSheet2: TTabSheet;
    Panel7: TPanel;
    Label1: TLabel;
    Label4: TLabel;
    LbStaticText5: TLbStaticText;
    NodeShape: TRadioGroup;
    Colors: TGroupBox;
    Label2: TLabel;
    Label3: TLabel;
    NodeBodyColor: TPanel;
    BodyColor: TShape;
    NodeBorderColor: TPanel;
    BorderColor: TShape;
    btnChangeFont: TButton;
    NodeText: TMemo;
    GroupBox1: TGroupBox;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    cbAlignment: TComboBox;
    cbLayout: TComboBox;
    edtMargin: TEdit;
    UpDownMargin: TUpDown;
    AllOptions: TCheckListBox;
    Styles: TGroupBox;
    Label8: TLabel;
    Label13: TLabel;
    FillStyle: TComboBox;
    BorderStyle: TComboBox;
    GroupBox4: TGroupBox;
    btnChangBkgnd: TButton;
    btnClearBackground: TButton;
    btnBackgroundMargins: TButton;
    TabSheet3: TTabSheet;
    Panel6: TPanel;
    Label14: TLabel;
    Label15: TLabel;
    LbStaticText4: TLbStaticText;
    LinkLabel: TEdit;
    Style: TGroupBox;
    Shape4: TShape;
    Shape5: TShape;
    Shape6: TShape;
    StyleSolid: TRadioButton;
    StyleDash: TRadioButton;
    StyleDot: TRadioButton;
    GroupBox5: TGroupBox;
    Label16: TLabel;
    Label17: TLabel;
    LinkLineColor: TPanel;
    LineColor: TShape;
    LinkStyleColor: TPanel;
    StyleColor: TShape;
    Button1: TButton;
    CheckListBox1: TCheckListBox;
    LabelPlacement: TGroupBox;
    Label18: TLabel;
    Label19: TLabel;
    Edit4: TEdit;
    LabelPosition: TUpDown;
    Edit5: TEdit;
    LabelSpacing: TUpDown;
    Size: TGroupBox;
    Edit1: TEdit;
    PenWidth: TUpDown;
    LineBegin: TGroupBox;
    Label20: TLabel;
    Label21: TLabel;
    LineBeginStyle: TComboBox;
    Edit3: TEdit;
    LineBeginSize: TUpDown;
    LineEnd: TGroupBox;
    Label22: TLabel;
    Label23: TLabel;
    LineEndStyle: TComboBox;
    Edit6: TEdit;
    LineEndSize: TUpDown;
    procedure ShowGridClick(Sender: TObject);
    procedure SnapToGridClick(Sender: TObject);
    procedure DesignerBackgroundColorClick(Sender: TObject);
    procedure GridSizeClick(Sender: TObject; Button: TUDBtnType);
    procedure Panel3Click(Sender: TObject);
    procedure DesignerGridColorClick(Sender: TObject);
    procedure HorzAlignClick(Sender: TObject);
    procedure VertAlignClick(Sender: TObject);
    procedure HorzsizeClick(Sender: TObject);
  private
    Graph: TSimpleGraph;
  public
    constructor create(AOwner: TComponent); override;
    function DesignerExecute(SimpleGraph: TSimpleGraph): Boolean;
  end;

var
  PropDialog: TPropDialog;

implementation

{$R *.dfm}

{ TPropDialog }

constructor TPropDialog.create(AOwner: TComponent);
begin
  inherited Create(AOwner);
end;

{ 현재 정보 로딩 }
function TPropDialog.DesignerExecute(SimpleGraph: TSimpleGraph): Boolean;
begin

  Result := False;
  Graph :=  SimpleGraph;

  { Designer Viewport }
  GridSize.Min := Low(TGridSize);
  GridSize.Max := High(TGridSize);
  SnapToGrid.Checked := SimpleGraph.SnapToGrid;
  ShowGrid.Checked := SimpleGraph.ShowGrid;
  GridSize.Position := SimpleGraph.GridSize;
  BackgroundColor.Brush.Color := SimpleGraph.Color;
  MarkerColor.Brush.Color := SimpleGraph.MarkerColor;
  GridColor.Brush.Color := SimpleGraph.GridColor;

  { Aligment }
  { Size }
  
end;

procedure TPropDialog.ShowGridClick(Sender: TObject);
begin
  Graph.ShowGrid := showgrid.Checked;
end;

procedure TPropDialog.SnapToGridClick(Sender: TObject);
begin
  Graph.SnapToGrid := SnapToGrid.Checked;
end;

procedure TPropDialog.GridSizeClick(Sender: TObject; Button: TUDBtnType);
begin
  Graph.GridSize := GridSize.Position;
end;

procedure TPropDialog.DesignerBackgroundColorClick(Sender: TObject);
begin
  ColorDialog.Color := BackgroundColor.Brush.Color;
  if ColorDialog.Execute then
  begin
    BackgroundColor.Brush.Color := ColorDialog.Color;
    Graph.Color := BackgroundColor.Brush.Color;
  end;
end;

procedure TPropDialog.Panel3Click(Sender: TObject);
begin
  ColorDialog.Color := MarkerColor.Brush.Color;
  if ColorDialog.Execute then
  begin
    MarkerColor.Brush.Color := ColorDialog.Color;
    Graph.MarkerColor := MarkerColor.Brush.Color;
  end;
end;

procedure TPropDialog.DesignerGridColorClick(Sender: TObject);
begin
  ColorDialog.Color := GridColor.Brush.Color;
  if ColorDialog.Execute then
  begin
    GridColor.Brush.Color := ColorDialog.Color;
    Graph.GridColor := GridColor.Brush.Color;
  end;
end;

procedure TPropDialog.HorzAlignClick(Sender: TObject);
var
  H: THAlignOption;
  V: TVAlignOption;
begin
  H := THAlignOption(HorzAlign.ItemIndex);
  V := TVAlignOption(VertAlign.ItemIndex);
  Graph.AlignSelection(H, V);
end;

procedure TPropDialog.VertAlignClick(Sender: TObject);
begin
  HorzAlignClick(Sender);
end;

procedure TPropDialog.HorzsizeClick(Sender: TObject);
var
  H: TResizeOption;
  V: TResizeOption;
begin
  H := TResizeOption(Horzsize.ItemIndex);
  V := TResizeOption(Vertsize.ItemIndex);
  Graph.ResizeSelection(H, V);
end;

end.
