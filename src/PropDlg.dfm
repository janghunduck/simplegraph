object PropDialog: TPropDialog
  Left = 1357
  Top = 138
  Width = 390
  Height = 859
  Caption = 'Properties ...'
  Color = clBtnFace
  DockSite = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object PageControl: TPageControl
    Left = 0
    Top = 0
    Width = 382
    Height = 832
    ActivePage = TabSheet1
    Align = alClient
    TabOrder = 0
    object TabSheet1: TTabSheet
      Caption = 'Designer'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      object DesignerPanel1: TPanel
        Left = 0
        Top = 313
        Width = 374
        Height = 136
        Align = alTop
        TabOrder = 0
        object LbStaticText2: TLbStaticText
          Left = 1
          Top = 1
          Width = 372
          Height = 23
          Align = alTop
          Caption = 'o. Size All Object'
          Color = clGray
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindow
          Font.Height = -11
          Font.Name = 'MS Sans Serif'
          Font.Style = [fsBold]
          HotTrackFont.Charset = DEFAULT_CHARSET
          HotTrackFont.Color = clWindowText
          HotTrackFont.Height = -11
          HotTrackFont.Name = 'MS Sans Serif'
          HotTrackFont.Style = []
          ParentColor = False
          ParentFont = False
        end
        object Horzsize: TRadioGroup
          Left = 12
          Top = 34
          Width = 149
          Height = 87
          Caption = ' Horizontal '
          ItemIndex = 0
          Items.Strings = (
            'No Change'
            'Shrink to smallest'
            'Grow to largest')
          TabOrder = 1
          OnClick = HorzsizeClick
        end
        object Vertsize: TRadioGroup
          Left = 177
          Top = 34
          Width = 152
          Height = 87
          Caption = ' Vertical '
          ItemIndex = 0
          Items.Strings = (
            'No Change'
            'Shrink to smallest'
            'Grow to largest')
          TabOrder = 2
        end
      end
      object Panel1: TPanel
        Left = 0
        Top = 0
        Width = 374
        Height = 145
        Align = alTop
        TabOrder = 1
        object GroupBox2: TGroupBox
          Left = 9
          Top = 31
          Width = 153
          Height = 106
          Caption = ' Grid '
          TabOrder = 0
          object Label9: TLabel
            Left = 16
            Top = 72
            Width = 45
            Height = 13
            Caption = 'Grid Size:'
          end
          object ShowGrid: TCheckBox
            Left = 16
            Top = 37
            Width = 121
            Height = 17
            Caption = 'Show Grid'
            TabOrder = 1
            OnClick = ShowGridClick
          end
          object SnapToGrid: TCheckBox
            Left = 16
            Top = 17
            Width = 121
            Height = 17
            Caption = 'Snap To Grid'
            TabOrder = 0
            OnClick = SnapToGridClick
          end
          object Edit2: TEdit
            Left = 66
            Top = 68
            Width = 37
            Height = 21
            ImeName = 'Microsoft Office IME 2007'
            TabOrder = 2
            Text = '8'
          end
          object GridSize: TUpDown
            Left = 103
            Top = 68
            Width = 15
            Height = 21
            Associate = Edit2
            Position = 8
            TabOrder = 3
            OnClick = GridSizeClick
          end
        end
        object GroupBox3: TGroupBox
          Left = 177
          Top = 31
          Width = 153
          Height = 106
          Caption = ' Colors '
          TabOrder = 1
          object Label10: TLabel
            Left = 16
            Top = 20
            Width = 61
            Height = 13
            Caption = 'Background:'
            FocusControl = DesignerBackgroundColor
          end
          object Label11: TLabel
            Left = 16
            Top = 41
            Width = 41
            Height = 13
            Caption = 'Markers:'
            FocusControl = Panel3
          end
          object Label12: TLabel
            Left = 16
            Top = 63
            Width = 22
            Height = 13
            Caption = 'Grid:'
            FocusControl = DesignerGridColor
          end
          object DesignerBackgroundColor: TPanel
            Left = 88
            Top = 16
            Width = 49
            Height = 20
            ParentColor = True
            TabOrder = 0
            OnClick = DesignerBackgroundColorClick
            object BackgroundColor: TShape
              Left = 1
              Top = 1
              Width = 47
              Height = 18
              Align = alClient
              Enabled = False
            end
          end
          object Panel3: TPanel
            Left = 88
            Top = 37
            Width = 49
            Height = 20
            ParentColor = True
            TabOrder = 1
            OnClick = Panel3Click
            object MarkerColor: TShape
              Left = 1
              Top = 1
              Width = 47
              Height = 18
              Align = alClient
              Enabled = False
            end
          end
          object DesignerGridColor: TPanel
            Left = 88
            Top = 58
            Width = 49
            Height = 20
            ParentColor = True
            TabOrder = 2
            OnClick = DesignerGridColorClick
            object GridColor: TShape
              Left = 1
              Top = 1
              Width = 47
              Height = 18
              Align = alClient
              Enabled = False
            end
          end
        end
        object LbStaticText1: TLbStaticText
          Left = 1
          Top = 1
          Width = 372
          Height = 23
          Align = alTop
          Caption = 'o. Designer Viewport'
          Color = clGray
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindow
          Font.Height = -11
          Font.Name = 'MS Sans Serif'
          Font.Style = [fsBold]
          HotTrackFont.Charset = DEFAULT_CHARSET
          HotTrackFont.Color = clWindowText
          HotTrackFont.Height = -11
          HotTrackFont.Name = 'MS Sans Serif'
          HotTrackFont.Style = []
          ParentColor = False
          ParentFont = False
        end
      end
      object Panel5: TPanel
        Left = 0
        Top = 145
        Width = 374
        Height = 168
        Align = alTop
        TabOrder = 2
        object LbStaticText3: TLbStaticText
          Left = 1
          Top = 1
          Width = 372
          Height = 23
          Align = alTop
          Caption = 'o. Align All Object'
          Color = clGray
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindow
          Font.Height = -11
          Font.Name = 'MS Sans Serif'
          Font.Style = [fsBold]
          HotTrackFont.Charset = DEFAULT_CHARSET
          HotTrackFont.Color = clWindowText
          HotTrackFont.Height = -11
          HotTrackFont.Name = 'MS Sans Serif'
          HotTrackFont.Style = []
          ParentColor = False
          ParentFont = False
        end
        object HorzAlign: TRadioGroup
          Left = 10
          Top = 31
          Width = 151
          Height = 122
          Caption = ' Horizontal '
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'MS Sans Serif'
          Font.Style = []
          ItemIndex = 0
          Items.Strings = (
            'No change'
            'Left sides'
            'Centers'
            'Right sides'
            'Space equally')
          ParentFont = False
          TabOrder = 1
          OnClick = HorzAlignClick
        end
        object VertAlign: TRadioGroup
          Left = 177
          Top = 31
          Width = 152
          Height = 122
          Caption = ' Vertical '
          ItemIndex = 0
          Items.Strings = (
            'No change'
            'Tops'
            'Centers'
            'Bottoms'
            'Space equally')
          TabOrder = 2
          OnClick = VertAlignClick
        end
      end
    end
    object TabSheet2: TTabSheet
      Caption = 'Polygon'
      ImageIndex = 1
      object Panel7: TPanel
        Left = 0
        Top = 0
        Width = 374
        Height = 497
        Align = alTop
        TabOrder = 0
        object Label1: TLabel
          Left = 12
          Top = 30
          Width = 39
          Height = 13
          Caption = 'Caption:'
        end
        object Label4: TLabel
          Left = 12
          Top = 102
          Width = 39
          Height = 13
          Caption = 'Options:'
          FocusControl = AllOptions
        end
        object LbStaticText5: TLbStaticText
          Left = 1
          Top = 1
          Width = 372
          Height = 23
          Align = alTop
          Caption = 'o. Polygon Object'
          Color = clGray
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindow
          Font.Height = -11
          Font.Name = 'MS Sans Serif'
          Font.Style = [fsBold]
          HotTrackFont.Charset = DEFAULT_CHARSET
          HotTrackFont.Color = clWindowText
          HotTrackFont.Height = -11
          HotTrackFont.Name = 'MS Sans Serif'
          HotTrackFont.Style = []
          ParentColor = False
          ParentFont = False
        end
        object NodeShape: TRadioGroup
          Left = 178
          Top = 167
          Width = 153
          Height = 154
          Caption = ' Shape '
          TabOrder = 1
        end
        object Colors: TGroupBox
          Left = 10
          Top = 371
          Width = 153
          Height = 78
          Caption = ' Colors '
          TabOrder = 2
          object Label2: TLabel
            Left = 16
            Top = 24
            Width = 27
            Height = 13
            Caption = 'Body:'
            FocusControl = NodeBodyColor
          end
          object Label3: TLabel
            Left = 16
            Top = 49
            Width = 34
            Height = 13
            Caption = 'Border:'
            FocusControl = NodeBorderColor
          end
          object NodeBodyColor: TPanel
            Left = 88
            Top = 19
            Width = 49
            Height = 22
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clWindowText
            Font.Height = -11
            Font.Name = 'MS Sans Serif'
            Font.Style = []
            ParentColor = True
            ParentFont = False
            TabOrder = 0
            object BodyColor: TShape
              Left = 1
              Top = 1
              Width = 47
              Height = 20
              Align = alClient
              Enabled = False
            end
          end
          object NodeBorderColor: TPanel
            Left = 88
            Top = 44
            Width = 49
            Height = 22
            ParentColor = True
            TabOrder = 1
            object BorderColor: TShape
              Left = 1
              Top = 1
              Width = 47
              Height = 20
              Align = alClient
              Enabled = False
            end
          end
        end
        object btnChangeFont: TButton
          Left = 188
          Top = 424
          Width = 129
          Height = 25
          Caption = 'Change Font...'
          TabOrder = 3
        end
        object NodeText: TMemo
          Left = 12
          Top = 44
          Width = 318
          Height = 53
          ImeName = 'Microsoft Office IME 2007'
          ScrollBars = ssBoth
          TabOrder = 4
        end
        object GroupBox1: TGroupBox
          Left = 12
          Top = 167
          Width = 151
          Height = 106
          Caption = ' Caption Placement '
          TabOrder = 5
          object Label5: TLabel
            Left = 16
            Top = 27
            Width = 30
            Height = 13
            Caption = 'Horiz.:'
          end
          object Label6: TLabel
            Left = 16
            Top = 50
            Width = 25
            Height = 13
            Caption = 'Vert.:'
          end
          object Label7: TLabel
            Left = 16
            Top = 74
            Width = 35
            Height = 13
            Caption = 'Margin:'
          end
          object cbAlignment: TComboBox
            Left = 64
            Top = 24
            Width = 74
            Height = 21
            Style = csDropDownList
            ImeName = 'Microsoft Office IME 2007'
            ItemHeight = 13
            TabOrder = 0
            Items.Strings = (
              'Left'
              'Center'
              'Right')
          end
          object cbLayout: TComboBox
            Left = 64
            Top = 47
            Width = 74
            Height = 21
            Style = csDropDownList
            ImeName = 'Microsoft Office IME 2007'
            ItemHeight = 13
            TabOrder = 1
            Items.Strings = (
              'Top'
              'Center'
              'Bottom')
          end
          object edtMargin: TEdit
            Left = 64
            Top = 70
            Width = 57
            Height = 21
            ImeName = 'Microsoft Office IME 2007'
            TabOrder = 2
            Text = '0'
          end
          object UpDownMargin: TUpDown
            Left = 121
            Top = 70
            Width = 15
            Height = 21
            Associate = edtMargin
            TabOrder = 3
          end
        end
        object AllOptions: TCheckListBox
          Left = 12
          Top = 116
          Width = 318
          Height = 43
          Columns = 2
          ImeName = 'Microsoft Office IME 2007'
          ItemHeight = 13
          Items.Strings = (
            'Linkable'
            'Selectable'
            'Show Caption'
            'Movable'
            'Resizable'
            'Show Background')
          TabOrder = 6
        end
        object Styles: TGroupBox
          Left = 11
          Top = 281
          Width = 153
          Height = 80
          Caption = ' Style '
          TabOrder = 7
          object Label8: TLabel
            Left = 16
            Top = 24
            Width = 15
            Height = 13
            Caption = 'Fill:'
            FocusControl = FillStyle
          end
          object Label13: TLabel
            Left = 16
            Top = 47
            Width = 34
            Height = 13
            Caption = 'Border:'
            FocusControl = BorderStyle
          end
          object FillStyle: TComboBox
            Left = 64
            Top = 20
            Width = 73
            Height = 21
            Style = csDropDownList
            ImeName = 'Microsoft Office IME 2007'
            ItemHeight = 13
            ItemIndex = 0
            TabOrder = 0
            Text = 'Solid'
            Items.Strings = (
              'Solid'
              'Clear'
              'Horizontal'
              'Vertical'
              'Diagonal Forwad'
              'Diagonal Backward'
              'Cross'
              'Cross Diagonal')
          end
          object BorderStyle: TComboBox
            Left = 64
            Top = 45
            Width = 73
            Height = 21
            Style = csDropDownList
            ImeName = 'Microsoft Office IME 2007'
            ItemHeight = 13
            ItemIndex = 0
            TabOrder = 1
            Text = 'Solid'
            Items.Strings = (
              'Solid'
              'Dash'
              'Dot'
              'Dash Dot'
              'Dash Dot Dot'
              'Clear'
              'Inside Frame')
          end
        end
        object GroupBox4: TGroupBox
          Left = 179
          Top = 331
          Width = 153
          Height = 89
          Caption = ' Background '
          TabOrder = 8
          object btnChangBkgnd: TButton
            Left = 16
            Top = 24
            Width = 57
            Height = 25
            Caption = 'Change...'
            TabOrder = 0
          end
          object btnClearBackground: TButton
            Left = 80
            Top = 24
            Width = 57
            Height = 25
            Caption = 'Clear'
            TabOrder = 1
          end
          object btnBackgroundMargins: TButton
            Left = 36
            Top = 54
            Width = 81
            Height = 25
            Caption = 'Margins...'
            TabOrder = 2
          end
        end
      end
    end
    object TabSheet3: TTabSheet
      Caption = 'Line'
      ImageIndex = 2
      object Panel6: TPanel
        Left = 0
        Top = 0
        Width = 374
        Height = 417
        Align = alTop
        TabOrder = 0
        object Label14: TLabel
          Left = 11
          Top = 27
          Width = 39
          Height = 13
          Caption = 'Caption:'
          FocusControl = LinkLabel
        end
        object Label15: TLabel
          Left = 11
          Top = 330
          Width = 39
          Height = 13
          Caption = 'Options:'
          FocusControl = CheckListBox1
        end
        object LbStaticText4: TLbStaticText
          Left = 1
          Top = 1
          Width = 372
          Height = 23
          Align = alTop
          Caption = 'o. Line Object'
          Color = clGray
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindow
          Font.Height = -11
          Font.Name = 'MS Sans Serif'
          Font.Style = [fsBold]
          HotTrackFont.Charset = DEFAULT_CHARSET
          HotTrackFont.Color = clWindowText
          HotTrackFont.Height = -11
          HotTrackFont.Name = 'MS Sans Serif'
          HotTrackFont.Style = []
          ParentColor = False
          ParentFont = False
        end
        object LinkLabel: TEdit
          Left = 11
          Top = 43
          Width = 316
          Height = 21
          ImeName = 'Microsoft Office IME 2007'
          TabOrder = 1
        end
        object Style: TGroupBox
          Left = 11
          Top = 163
          Width = 153
          Height = 88
          Caption = ' Line Style '
          TabOrder = 2
          object Shape4: TShape
            Left = 70
            Top = 32
            Width = 67
            Height = 1
            Brush.Style = bsClear
          end
          object Shape5: TShape
            Left = 68
            Top = 51
            Width = 69
            Height = 1
            Brush.Style = bsClear
            Pen.Style = psDash
          end
          object Shape6: TShape
            Left = 69
            Top = 70
            Width = 68
            Height = 1
            Brush.Style = bsClear
            Pen.Style = psDot
          end
          object StyleSolid: TRadioButton
            Left = 16
            Top = 24
            Width = 49
            Height = 17
            Caption = 'Solid'
            TabOrder = 0
          end
          object StyleDash: TRadioButton
            Left = 16
            Top = 43
            Width = 49
            Height = 17
            Caption = 'Dash'
            TabOrder = 1
          end
          object StyleDot: TRadioButton
            Left = 16
            Top = 62
            Width = 49
            Height = 17
            Caption = 'Dot'
            TabOrder = 2
          end
        end
        object GroupBox5: TGroupBox
          Left = 175
          Top = 163
          Width = 153
          Height = 88
          Caption = ' Colors '
          TabOrder = 3
          object Label16: TLabel
            Left = 16
            Top = 24
            Width = 23
            Height = 13
            Caption = 'Line:'
            FocusControl = LinkLineColor
          end
          object Label17: TLabel
            Left = 16
            Top = 55
            Width = 54
            Height = 13
            Caption = 'Begin/End:'
            FocusControl = LinkStyleColor
          end
          object LinkLineColor: TPanel
            Left = 88
            Top = 19
            Width = 49
            Height = 22
            ParentColor = True
            TabOrder = 0
            object LineColor: TShape
              Left = 1
              Top = 1
              Width = 47
              Height = 20
              Align = alClient
              Enabled = False
            end
          end
          object LinkStyleColor: TPanel
            Left = 88
            Top = 50
            Width = 49
            Height = 22
            ParentColor = True
            TabOrder = 1
            object StyleColor: TShape
              Left = 1
              Top = 1
              Width = 47
              Height = 20
              Align = alClient
              Enabled = False
            end
          end
        end
        object Button1: TButton
          Left = 23
          Top = 85
          Width = 129
          Height = 22
          Caption = 'Change Font...'
          TabOrder = 4
        end
        object CheckListBox1: TCheckListBox
          Left = 11
          Top = 345
          Width = 317
          Height = 57
          Columns = 2
          ImeName = 'Microsoft Office IME 2007'
          ItemHeight = 13
          Items.Strings = (
            'Linkable'
            'Selectable'
            'Show Caption'
            'Fixed - Start Point'
            'Fixed - End Point'
            'Fixed - Break Points'
            'Fixed Anchor - Start Point'
            'Fixed Anchor - End Point')
          TabOrder = 5
        end
        object LabelPlacement: TGroupBox
          Left = 175
          Top = 76
          Width = 153
          Height = 85
          Caption = ' Caption Placement '
          TabOrder = 6
          object Label18: TLabel
            Left = 16
            Top = 30
            Width = 40
            Height = 13
            Caption = 'Position:'
            FocusControl = Edit4
          end
          object Label19: TLabel
            Left = 16
            Top = 56
            Width = 42
            Height = 13
            Caption = 'Spacing:'
            FocusControl = Edit5
          end
          object Edit4: TEdit
            Left = 64
            Top = 27
            Width = 60
            Height = 21
            ImeName = 'Microsoft Office IME 2007'
            TabOrder = 0
            Text = '-1'
          end
          object LabelPosition: TUpDown
            Left = 124
            Top = 27
            Width = 15
            Height = 21
            Associate = Edit4
            Min = -1
            Position = -1
            TabOrder = 1
          end
          object Edit5: TEdit
            Left = 64
            Top = 53
            Width = 60
            Height = 21
            ImeName = 'Microsoft Office IME 2007'
            TabOrder = 2
            Text = '0'
          end
          object LabelSpacing: TUpDown
            Left = 124
            Top = 53
            Width = 15
            Height = 21
            Associate = Edit5
            Min = -100
            TabOrder = 3
          end
        end
        object Size: TGroupBox
          Left = 11
          Top = 110
          Width = 153
          Height = 50
          Caption = ' Line Size '
          TabOrder = 7
          object Edit1: TEdit
            Left = 12
            Top = 18
            Width = 112
            Height = 21
            ImeName = 'Microsoft Office IME 2007'
            TabOrder = 0
            Text = '1'
          end
          object PenWidth: TUpDown
            Left = 124
            Top = 18
            Width = 15
            Height = 21
            Associate = Edit1
            Min = 1
            Max = 10
            Position = 1
            TabOrder = 1
          end
        end
        object LineBegin: TGroupBox
          Left = 11
          Top = 253
          Width = 153
          Height = 86
          Caption = ' Begin '
          TabOrder = 8
          object Label20: TLabel
            Left = 16
            Top = 24
            Width = 26
            Height = 13
            Caption = 'Style:'
            FocusControl = LineBeginStyle
          end
          object Label21: TLabel
            Left = 16
            Top = 54
            Width = 23
            Height = 13
            Caption = 'Size:'
          end
          object LineBeginStyle: TComboBox
            Left = 53
            Top = 21
            Width = 85
            Height = 21
            Style = csDropDownList
            ImeName = 'Microsoft Office IME 2007'
            ItemHeight = 13
            ItemIndex = 0
            TabOrder = 0
            Text = 'None'
            Items.Strings = (
              'None'
              'Arrow'
              'Simple Arrow'
              'Circle'
              'Diamond')
          end
          object Edit3: TEdit
            Left = 53
            Top = 51
            Width = 68
            Height = 21
            ImeName = 'Microsoft Office IME 2007'
            TabOrder = 1
            Text = '1'
          end
          object LineBeginSize: TUpDown
            Left = 121
            Top = 51
            Width = 15
            Height = 21
            Associate = Edit3
            Min = 1
            Max = 10
            Position = 1
            TabOrder = 2
          end
        end
        object LineEnd: TGroupBox
          Left = 175
          Top = 253
          Width = 153
          Height = 86
          Caption = ' End '
          TabOrder = 9
          object Label22: TLabel
            Left = 16
            Top = 24
            Width = 26
            Height = 13
            Caption = 'Style:'
            FocusControl = LineEndStyle
          end
          object Label23: TLabel
            Left = 16
            Top = 54
            Width = 23
            Height = 13
            Caption = 'Size:'
          end
          object LineEndStyle: TComboBox
            Left = 53
            Top = 21
            Width = 85
            Height = 21
            Style = csDropDownList
            ImeName = 'Microsoft Office IME 2007'
            ItemHeight = 13
            ItemIndex = 0
            TabOrder = 0
            Text = 'None'
            Items.Strings = (
              'None'
              'Arrow'
              'Simple Arrow'
              'Circle'
              'Diamond')
          end
          object Edit6: TEdit
            Left = 53
            Top = 51
            Width = 68
            Height = 21
            ImeName = 'Microsoft Office IME 2007'
            TabOrder = 1
            Text = '1'
          end
          object LineEndSize: TUpDown
            Left = 121
            Top = 51
            Width = 15
            Height = 21
            Associate = Edit6
            Min = 1
            Max = 10
            Position = 1
            TabOrder = 2
          end
        end
      end
    end
  end
  object FontDialog: TFontDialog
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    Left = 268
    Top = 476
  end
  object ColorDialog: TColorDialog
    Left = 300
    Top = 476
  end
  object OpenPictureDialog: TOpenPictureDialog
    Title = 'Select Background'
    Left = 330
    Top = 476
  end
end
