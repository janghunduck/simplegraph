{------------------------------------------------------------------------------}
{                                                                              }
{  TSimpleGraph v2.91                                                        }
{  by Kambiz R. Khojasteh                                                      }
{                                                                              }
{  kambiz@delphiarea.com                                                       }
{  http://www.delphiarea.com                                                   }
{                                                                              }
{------------------------------------------------------------------------------}

{$I DELPHIAREA.INC}

unit SimpleGraph;

interface

uses
  Windows, Messages, Classes, Graphics, Controls, StdCtrls, Forms, Menus,
  ExtCtrls, Contnrs, UsefulUtils, Dialogs;

const
  // Custom Cursors
  crHandFlat  = 51;
  crHandGrab  = 52;
  crHandPnt   = 53;
  crXHair1    = 54;
  crXHair2    = 55;
  crXHair3    = 56;
  crXHairLink = 57;

const
  // Default Graph Hit Test Flags
  GHT_NOWHERE       = $00000000;
  GHT_TRANSPARENT   = $00000001;
  GHT_LEFT          = $00000002;
  GHT_TOP           = $00000004;
  GHT_RIGHT         = $00000008;
  GHT_BOTTOM        = $00000010;
  GHT_TOPLEFT       = $00000020;
  GHT_TOPRIGHT      = $00000040;
  GHT_BOTTOMLEFT    = $00000080;
  GHT_BOTTOMRIGHT   = $00000100;
  GHT_CLIENT        = $00000200;
  GHT_CAPTION       = $00000400;
  GHT_POINT         = $00000800;  // High word contains the point's index
  GHT_LINE          = $00001000;  // High word contains the line's index

const
  GHT_BODY_MASK     = GHT_CLIENT or GHT_CAPTION;
  GHT_SIDES_MASK    = GHT_LEFT or GHT_TOP or GHT_RIGHT or GHT_BOTTOM or
                      GHT_TOPLEFT or GHT_TOPRIGHT or GHT_BOTTOMLEFT or
                      GHT_BOTTOMRIGHT;

type

  TPoints = array of TPoint;

  PFloatPoint = ^TFloatPoint;
  TFloat = Single;
  TFloatPoint = record
    X, Y: TFloat;
  end;
  TFloatPoints = array of TFloatPoint;


  TSimpleGraph = class;
  TGraphObject = class;
  TGraphLink = class;
  TGraphNode = class;


  EGraphStreamError      = class(EStreamError);
  EGraphInvalidOperation = class(EInvalidOperation);
  EPointListError        = class(EListError);

  { eq }
  TKindBracket=(kbRound, kbSquare, kbFigure, kbCorner, kbModule, kbDModule);
  TKindArrow = set of (kaRight, kaLeft, kaDouble);
  TAlignEA = (aeTop, aeBottom);
  TGroupOptions = set of (goLimitTop, goLimitBottom, goIndexTop, goIndexBottom);
  TKindMatrix = (kmHoriz, kmVert, kmSquare);

  TExpression = record
    ClassName: string;
    ExprData: string;
  end;
  TExprArray = array of TExpression;
  
  { TGraphScrollBar -- for internal use only }

  TGraphScrollBar = class(TPersistent)
  private
    fOwner: TSimpleGraph;
    fIncrement: TScrollBarInc;
    fPageIncrement: TScrollBarInc;
    fPosition: Integer;
    fRange: Integer;
    fCalcRange: Integer;
    fKind: TScrollBarKind;
    fMargin: Word;
    fVisible: Boolean;
    fTracking: Boolean;
    fSmooth: Boolean;
    fDelay: Integer;
    fButtonSize: Integer;
    fColor: TColor;
    fParentColor: Boolean;
    fSize: Integer;
    fStyle: TScrollBarStyle;
    fThumbSize: Integer;
    fPageDiv: Integer;
    fLineDiv: Integer;
    fUpdateNeeded: Boolean;
    procedure DoSetRange(Value: Integer);
    function GetScrollPos: Integer;
    procedure SetButtonSize(Value: Integer);
    procedure SetColor(Value: TColor);
    procedure SetParentColor(Value: Boolean);
    procedure SetPosition(Value: Integer);
    procedure SetSize(Value: Integer);
    procedure SetStyle(Value: TScrollBarStyle);
    procedure SetThumbSize(Value: Integer);
    procedure SetVisible(Value: Boolean);
    function IsIncrementStored: Boolean;
  protected
    constructor Create(AOwner: TSimpleGraph; AKind: TScrollBarKind);
    function ControlSize(ControlSB, AssumeSB: Boolean): Integer;
    procedure CalcAutoRange;
    procedure Update(ControlSB, AssumeSB: Boolean);
    function NeedsScrollBarVisible: Boolean;
    procedure ScrollMessage(var Msg: TWMScroll);
  public
    procedure Assign(Source: TPersistent); override;
    procedure ChangeBiDiPosition;
    property Kind: TScrollBarKind read fKind;
    function IsScrollBarVisible: Boolean;
    property ScrollPos: Integer read GetScrollPos;
    property Range: Integer read fRange;
    property Owner: TSimpleGraph read fOwner;
  published
    property ButtonSize: Integer read fButtonSize write SetButtonSize default 0;
    property Color: TColor read fColor write SetColor default clBtnHighlight;
    property Increment: TScrollBarInc read fIncrement write fIncrement stored IsIncrementStored default 8;
    property Margin: Word read fMargin write fMargin default 0;
    property ParentColor: Boolean read fParentColor write SetParentColor default True;
    property Position: Integer read fPosition write SetPosition default 0;
    property Smooth: Boolean read fSmooth write fSmooth default False;
    property Size: Integer read fSize write SetSize default 0;
    property Style: TScrollBarStyle read fStyle write SetStyle default ssRegular;
    property ThumbSize: Integer read fThumbSize write SetThumbSize default 0;
    property Tracking: Boolean read fTracking write fTracking default False;
    property Visible: Boolean read fVisible write SetVisible default True;
  end;

  { TGraphStreamableObject -- for internal use only }

  TGraphStreamableObject = class(TComponent)
  private
    fID: DWORD;
    fG: TGraphObject;
    fDummy: Integer;
  published
    property ID: DWORD read fID write fID;
    property G: TGraphObject read fG write fG stored True;
    property Left: Integer read fDummy write fDummy stored False;
    property Top: Integer read fDummy write fDummy stored False;
    property Tag stored False;
    property Name stored False;
  end;

  { TMemoryHandleStream }

  TMemoryHandleStream = class(TMemoryStream)
  private
    fHandle: THandle;
    fReleaseHandle: Boolean;
  protected
    function Realloc(var NewCapacity: Longint): Pointer; override;
  public
    constructor Create(MemHandle: THandle); virtual;
    destructor Destroy; override;
    property Handle: THandle read fHandle;
    property ReleaseHandle: Boolean read fReleaseHandle write fReleaseHandle;
  end;

  { TCanvasRecall }

  TCanvasRecall = class(TObject)
  private
    fPen: TPen;
    fFont: TFont;
    fBrush: TBrush;
    fCopyMode: TCopyMode;
    fTextFlags: Integer;
    fReference: TCanvas;
    procedure SetReference(Value: TCanvas);
  public
    constructor Create(AReference: TCanvas);
    destructor Destroy; override;
    procedure Store;
    procedure Retrieve;
    property Reference: TCanvas read fReference write SetReference;
  end;

  { TCompatibleCanvas }

  TCompatibleCanvas = class(TCanvas)
  public
    constructor Create;
    destructor Destroy; override;
  end;

  { TGraphObjectList }

  TGraphObjectListAction = (glAdded, glRemoved, glReordered);

  TGraphObjectListEvent = procedure(Sender: TObject; GraphObject: TGraphObject;
    Action: TGraphObjectListAction) of object;

  TListEnumState = record
    Current: Integer;
    Dir: Integer;
  end;

  TGraphObjectList = class(TPersistent)
  private
    fItems: array of TGraphObject;
    fCount: Integer;
    fCapacity: Integer;
    fOnChange: TGraphObjectListEvent;
    Enum: TListEnumState;
    EnumStack: array of TListEnumState;
    EnumStackPos: Integer;
    procedure SetCapacity(Value: Integer);
    function GetItems(Index: Integer): TGraphObject;
  protected
    procedure Grow;
    function Replace(OldItem, NewItem: TGraphObject): Integer;
    procedure AdjustDeleted(Index: Integer; var EnumState: TListEnumState);
    procedure NotifyAction(Item: TGraphObject; Action: TGraphObjectListAction); virtual;
  public
    destructor Destroy; override;
    procedure Clear;
    procedure Assign(Source: TPersistent); override;
    function Add(Item: TGraphObject): Integer;
    procedure Insert(Index: Integer; Item: TGraphObject);
    procedure Delete(Index: Integer);
    function Remove(Item: TGraphObject): Integer;
    procedure Move(CurIndex, NewIndex: Integer);
    function IndexOf(Item: TGraphObject): Integer;
    function First: TGraphObject;
    function Prior: TGraphObject;
    function Next: TGraphObject;
    function Last: TGraphObject;
    function Push: Boolean;
    function Pop: Boolean;
    property Count: Integer read fCount;
    property Capacity: Integer read fCapacity write SetCapacity;
    property Items[Index: Integer]: TGraphObject read GetItems; default;
    property OnChange: TGraphObjectListEvent read fOnChange write fOnChange;
  end;

  { TGraphObject }

  TGraphObjectState = (osCreating, osDestroying, osLoading, osReading, osWriting,
    osUpdating, osDragging, osDragDisabled, osConverting);
  TGraphObjectStates = set of TGraphObjectState;

  TGraphChangeFlag = (gcView, gcData, gcText, gcPlacement, gcDependency);
  TGraphChangeFlags = set of TGraphChangeFlag;

  TGraphDependencyChangeFlag = (gdcChanged, gdcRemoved);

  TGraphObjectOption = (goLinkable, goSelectable, goShowCaption);
  TGraphObjectOptions = set of TGraphObjectOption;

  TObjectSide = (osLeft, osTop, osRight, osBottom);
  TObjectSides = set of TObjectSide;

  TGraphObjectClass = class of TGraphObject;

  TGraphObject = class(TPersistent)
  private
    fID: DWORD;
    fOwner: TSimpleGraph;
    fBrush: TBrush;
    fPen: TPen;
    fText: String;
    fHint: String;
    fFont: TFont;
    fParentFont: Boolean;
    fOptions: TGraphObjectOptions;
    fVisible: Boolean;
    fSelected: Boolean;
    fStates: TGraphObjectStates;
    fDependentList: TGraphObjectList;
    fLinkInputList: TGraphObjectList;
    fLinkOutputList: TGraphObjectList;
    fTextToShow: String;
    fTag: Integer;
    fData: Pointer;
    fHasCustomData: Boolean;
    fVisualRect: TRect;
    fVisualRectFlags: TGraphChangeFlags;
    UpdateCount: Integer;
    PendingChanges: TGraphChangeFlags;
    DragDisableCount: Integer;

    procedure SetBrush(Value: TBrush);
    procedure SetPen(Value: TPen);
    procedure SetText(const Value: String);
    procedure SetHint(const Value: String);
    procedure SetFont(Value: TFont);
    procedure SetParentFont(Value: Boolean);
    procedure SetVisible(Value: Boolean);
    procedure SetSelected(Value: Boolean);
    function GetZOrder: Integer;
    procedure SetZOrder(Value: Integer);
    procedure SetOptions(Value: TGraphObjectOptions);
    procedure SetHasCustomData(Value: Boolean);
    function GetShowing: Boolean;
    function GetDragging: Boolean;
    function GetDependents(Index: Integer): TGraphObject;
    function GetDependentCount: Integer;
    function GetLinkInputs(Index: Integer): TGraphLink;
    function GetLinkInputCount: Integer;
    function GetLinkOutputs(Index: Integer): TGraphLink;
    function GetLinkOutputCount: Integer;
    function IsFontStored: Boolean;
    procedure StyleChanged(Sender: TObject);
    procedure ListChanged(Sender: TObject; GraphObject: TGraphObject; Action: TGraphObjectListAction);
    procedure ReadCustomData(Stream: TStream);
    procedure WriteCustomData(Stream: TStream);


  protected
    constructor CreateAsReplacement(AGraphObject: TGraphObject); virtual;
    constructor CreateFromStream(AOwner: TSimpleGraph; AStream: TStream); virtual;
    function GetOwner: TPersistent; override;
    procedure DefineProperties(Filer: TFiler); override;
    procedure Initialize; virtual;
    procedure Loaded; virtual;
    procedure ReplaceID(OldID, NewID: DWORD); virtual;
    procedure ReplaceObject(OldObject, NewObject: TGraphObject); virtual;
    procedure NotifyDependents(Flag: TGraphDependencyChangeFlag); virtual;
    procedure LookupDependencies; virtual;
    procedure UpdateDependencies; virtual;
    procedure UpdateDependencyTo(GraphObject: TGraphObject; Flag: TGraphDependencyChangeFlag); virtual;
    function UpdateTextPlacement(Recalc: Boolean; dX, dY: Integer): Boolean; virtual;
    procedure Changed(Flags: TGraphChangeFlags); virtual;
    procedure BoundsChanged(dX, dY, dCX, dCY: Integer); virtual;
    procedure DependentChanged(GraphObject: TGraphObject; Action: TGraphObjectListAction); virtual;
    procedure LinkInputChanged(GraphObject: TGraphObject; Action: TGraphObjectListAction); virtual;
    procedure LinkOutputChanged(GraphObject: TGraphObject; Action: TGraphObjectListAction); virtual;
    procedure ParentFontChanged; virtual;
    function IsUpdateLocked: Boolean; virtual;
    function NeighborhoodRadius: Integer; virtual;
    function FixHookAnchor: TPoint; virtual; abstract;
    function RelativeHookAnchor(RefPt: TPoint): TPoint; virtual; abstract;
    procedure DrawControlPoint(Canvas: TCanvas; const Pt: TPoint; Enabled: Boolean); virtual;
    procedure DrawControlPoints(Canvas: TCanvas); virtual; abstract;
    procedure DrawHighlight(Canvas: TCanvas); virtual; abstract;
    procedure DrawText(Canvas: TCanvas); virtual; abstract;
    procedure DrawBody(Canvas: TCanvas); virtual; abstract;
    procedure Draw(Canvas: TCanvas); virtual;
    procedure DrawState(Canvas: TCanvas); virtual;
    function IsVisibleOn(Canvas: TCanvas): Boolean; virtual;
    procedure QueryVisualRect(out Rect: TRect); virtual; abstract;
    function QueryHitTest(const Pt: TPoint): DWORD; virtual;
    function QueryCursor(HT: DWORD): TCursor; virtual;
    function QueryMobility(HT: DWORD): TObjectSides; virtual;
    function OffsetHitTest(HT: DWORD; dX, dY: Integer): Boolean; virtual;
    procedure SnapHitTestOffset(HT: DWORD; var dX, dY: Integer); virtual;
    function BeginFollowDrag(HT: DWORD): Boolean; virtual;
    function EndFollowDrag: Boolean; virtual;
    procedure DisableDrag; virtual;
    procedure EnableDrag; virtual;
    procedure MoveBy(dX, dY: Integer); virtual; abstract;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; const Pt: TPoint); virtual;
    procedure MouseMove(Shift: TShiftState; const Pt: TPoint); virtual;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; const Pt: TPoint); virtual;
    function KeyPress(var Key: Word; Shift: TShiftState): Boolean; virtual;
    procedure SetBoundsRect(const Rect: TRect); virtual; abstract;
    function GetBoundsRect: TRect; virtual; abstract;
    function GetSelectedVisualRect: TRect; virtual;

  protected
    property TextToShow: String read fTextToShow write fTextToShow;
    property DependentList: TGraphObjectList read fDependentList;
    property LinkInputList: TGraphObjectList read fLinkInputList;
    property LinkOutputList: TGraphObjectList read fLinkOutputList;
    property VisualRectFlags: TGraphChangeFlags read fVisualRectFlags write fVisualRectFlags;
  public
    constructor Create(AOwner: TSimpleGraph); virtual;
    destructor Destroy; override;
    procedure AfterConstruction; override;
    procedure BeforeDestruction; override;
    procedure Assign(Source: TPersistent); override;
    procedure AssignTo(Dest: TPersistent); override;
    function ConvertTo(AnotherClass: TGraphObjectClass): TGraphObject; virtual;
    procedure LoadFromStream(Stream: TStream); virtual;
    procedure SaveToStream(Stream: TStream); virtual;
    procedure BeginUpdate; virtual;
    procedure EndUpdate; virtual;
    procedure Invalidate; virtual;
    procedure BringToFront; virtual;
    procedure SendToBack; virtual;
    class function IsLink: Boolean; virtual;
    class function IsNode: Boolean; virtual;
    function IsLocked: Boolean; virtual;
    function Delete: Boolean; virtual;
    function CanDelete: Boolean; virtual;
    function HitTest(const Pt: TPoint): DWORD; virtual;
    function ContainsPoint(X, Y: Integer): Boolean; virtual;
    function ContainsRect(const Rect: TRect): Boolean; virtual;
    function BeginDrag(const Pt: TPoint; HT: DWORD = $FFFFFFFF): Boolean; virtual;
    function DragTo(const Pt: TPoint; SnapToGrid: Boolean): Boolean; virtual;
    function DragBy(dX, dY: Integer; SnapToGrid: Boolean): Boolean; virtual;
    function EndDrag(Accept: Boolean): Boolean; virtual;
    property States: TGraphObjectStates read fStates;
    property Dragging: Boolean read GetDragging;
    property Showing: Boolean read GetShowing;
    property Owner: TSimpleGraph read fOwner;
    property ZOrder: Integer read GetZOrder write SetZOrder;
    property Selected: Boolean read fSelected write SetSelected;
    property BoundsRect: TRect read GetBoundsRect write SetBoundsRect;
    property VisualRect: TRect read fVisualRect;
    property SelectedVisualRect: TRect read GetSelectedVisualRect;
    property Dependents[Index: Integer]: TGraphObject read GetDependents;
    property DependentCount: Integer read GetDependentCount;
    property LinkInputs[Index: Integer]: TGraphLink read GetLinkInputs;
    property LinkInputCount: Integer read GetLinkInputCount;
    property LinkOutputs[Index: Integer]: TGraphLink read GetLinkOutputs;
    property LinkOutputCount: Integer read GetLinkOutputCount;
    property Data: Pointer read fData write fData;
    property ID: DWORD read fID;
  published
    property Text: String read fText write SetText;
    property Hint: String read fHint write SetHint;
    property Brush: TBrush read fBrush write SetBrush;
    property Pen: TPen read fPen write SetPen;
    property Font: TFont read fFont write SetFont stored IsFontStored;
    property ParentFont: Boolean read fParentFont write SetParentFont default True;
    property Options: TGraphObjectOptions read fOptions write SetOptions
      default [goLinkable, goSelectable, goShowCaption];
    property Visible: Boolean read fVisible write SetVisible default True;
    property Tag: Integer read fTag write fTag default 0;
    property HasCustomData: Boolean read fHasCustomData write SetHasCustomData default False;
  end;

  { TGraphLink }

  TGraphLinkOption = (gloFixedStartPoint, gloFixedEndPoint, gloFixedBreakPoints,
    gloFixedAnchorStartPoint, gloFixedAnchorEndPoint);
  TGraphLinkOptions = set of TGraphLinkOption;

  TLinkBeginEndStyle = (lsNone, lsArrow, lsArrowSimple, lsCircle, lsDiamond);

  TLinkNormalizeOptions = set of (lnoDeleteSamePoint, lnoDeleteSameAngle);

  TLinkChangeMode = (lcmNone, lcmInsertPoint, lcmRemovePoint, lcmMovePoint, lcmMovePolyline);

  TGraphLink = class(TGraphObject)
  private
    fPoints: TPoints;
    fPointCount: Integer;
    fSource: TGraphObject;
    fTarget: TGraphObject;
    fTextPosition: Integer;
    fTextSpacing: Integer;
    fBeginStyle: TLinkBeginEndStyle;
    fBeginSize: Byte;
    fEndStyle: TLinkBeginEndStyle;
    fEndSize: Byte;
    fLinkOptions: TGraphLinkOptions;
    fTextRegion: HRGN;
    fTextAngle: Double;
    fTextCenter: TPoint;
    fTextLine: Integer;
    fChangeMode: TLinkChangeMode;
    fAcceptingHook: Boolean;
    fHookingObject: TGraphObject;
    fMovingPoint: Integer;
    SourceID: DWORD;
    TargetID: DWORD;
    UpdatingEndPoints: Boolean;
    CheckingLink: Boolean;
    procedure SetSource(Value: TGraphObject);
    procedure SetTarget(Value: TGraphObject);
    procedure SetLinkOptions(Value: TGraphLinkOptions);
    procedure SetTextPosition(Value: Integer);
    procedure SetTextSpacing(Value: Integer);
    procedure SetBeginStyle(Value: TLinkBeginEndStyle);
    procedure SetBeginSize(Value: Byte);
    procedure SetEndStyle(Value: TLinkBeginEndStyle);
    procedure SetEndSize(Value: Byte);
    function GetPoints(Index: Integer): TPoint;
    procedure SetPoints(Index: Integer; const Value: TPoint);
    procedure SetPolyline(const Value: TPoints);
    procedure ReadSource(Reader: TReader);
    procedure WriteSource(Writer: TWriter);
    procedure ReadTarget(Reader: TReader);
    procedure WriteTarget(Writer: TWriter);
    procedure ReadPoints(Stream: TStream);
    procedure WritePoints(Stream: TStream);
  private
    procedure ReadFromNode(Reader: TReader);  // Obsolete - for backward compatibility
    procedure ReadToNode(Reader: TReader);    // Obsolete - for backward compatibility
    procedure ReadKind(Reader: TReader);      // Obsolete - for backward compatibility
    procedure ReadArrowSize(Reader: TReader); // Obsolete - for backward compatibility
  protected
    procedure DefineProperties(Filer: TFiler); override;
    procedure Loaded; override;
    function FixHookAnchor: TPoint; override;
    function RelativeHookAnchor(RefPt: TPoint): TPoint; override;
    procedure ReplaceID(OldID, NewID: DWORD); override;
    procedure ReplaceObject(OldObject, NewObject: TGraphObject); override;
    procedure NotifyDependents(Flag: TGraphDependencyChangeFlag); override;
    procedure UpdateDependencyTo(GraphObject: TGraphObject; Flag: TGraphDependencyChangeFlag); override;
    procedure UpdateDependencies; override;
    procedure LookupDependencies; override;
    function UpdateTextPlacement(Recalc: Boolean; dX, dY: Integer): Boolean; override;
    function CreateTextRegion: HRGN; virtual;
    function IndexOfLongestLine: Integer; virtual;
    function IndexOfNearestLine(const Pt: TPoint; Neighborhood: Integer): Integer; virtual;
    procedure QueryVisualRect(out Rect: TRect); override;
    function QueryHitTest(const Pt: TPoint): DWORD; override;
    function QueryCursor(HT: DWORD): TCursor; override;
    function QueryMobility(HT: DWORD): TObjectSides; override;
    function OffsetHitTest(HT: DWORD; dX, dY: Integer): Boolean; override;
    procedure SnapHitTestOffset(HT: DWORD; var dX, dY: Integer); override;
    function BeginFollowDrag(HT: DWORD): Boolean; override;
    procedure MoveBy(dX, dY: Integer); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; const Pt: TPoint); override;
    procedure MouseMove(Shift: TShiftState; const Pt: TPoint); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; const Pt: TPoint); override;
    procedure UpdateChangeMode(HT: DWORD; Shift: TShiftState); virtual;
    function PointStyleOffset(Style: TLinkBeginEndStyle; Size: Integer): Integer; virtual;
    function PointStyleRect(const Pt: TPoint; const Angle: Double;
      Style: TLinkBeginEndStyle; Size: Integer): TRect; virtual;
    function DrawPointStyle(Canvas: TCanvas; const Pt: TPoint; const Angle: Double;
      Style: TLinkBeginEndStyle; Size: Integer): TPoint; virtual;
    procedure DrawControlPoints(Canvas: TCanvas); override;
    procedure DrawHighlight(Canvas: TCanvas); override;
    procedure DrawText(Canvas: TCanvas); override;
    procedure DrawBody(Canvas: TCanvas); override;
    procedure SetBoundsRect(const Rect: TRect); override;
    function GetBoundsRect: TRect; override;
  protected
    property TextRegion: HRGN read fTextRegion;
    property TextAngle: Double read fTextAngle;
    property TextCenter: TPoint read fTextCenter;
    property TextLine: Integer read fTextLine;
    property ChangeMode: TLinkChangeMode read fChangeMode write fChangeMode;
    property AcceptingHook: Boolean read fAcceptingHook;
    property HookingObject: TGraphObject read fHookingObject;
    property MovingPoint: Integer read fMovingPoint;
  public
    constructor Create(AOwner: TSimpleGraph); override;
    constructor CreateNew(AOwner: TSimpleGraph; ASource: TGraphObject;const Pts: array of TPoint; ATarget: TGraphObject); virtual;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    function ContainsRect(const Rect: TRect): Boolean; override;
    function CanMove: Boolean; virtual;
    function AddPoint(const Pt: TPoint): Integer; virtual;
    procedure InsertPoint(Index: Integer; const Pt: TPoint); virtual;
    procedure RemovePoint(Index: Integer); virtual;
    function IndexOfPoint(const Pt: TPoint; Neighborhood: Integer = 0): Integer; virtual;
    function AddBreakPoint(const Pt: TPoint): Integer; virtual;
    function NormalizeBreakPoints(Options: TLinkNormalizeOptions): Boolean; virtual;
    function IsFixedPoint(Index: Integer; HookedPointsAsFixed: Boolean): Boolean; virtual;
    function IsHookedPoint(Index: Integer): Boolean; virtual;
    function HookedObjectOf(Index: Integer): TGraphObject; virtual;
    function HookedIndexOf(GraphObject: TGraphObject): Integer; virtual;
    function HookedPointCount: Integer; virtual;
    function CanHook(Index: Integer; GraphObject: TGraphObject): Boolean; virtual;
    function Hook(Index: Integer; GraphObject: TGraphObject): Boolean; virtual;
    function Unhook(GraphObject: TGraphObject): Integer; overload; virtual;
    function Unhook(Index: Integer): Boolean; overload; virtual;
    function CanLink(ASource, ATarget: TGraphObject): Boolean; virtual;
    function Link(ASource, ATarget: TGraphObject): Boolean; virtual;
    function Rotate(const Angle: Double; const Origin: TPoint): Boolean; virtual;
    function Scale(const Factor: Double): Boolean; virtual;
    procedure Reverse; virtual;
    class function IsLink: Boolean; override;
    property Source: TGraphObject read fSource write SetSource;
    property Target: TGraphObject read fTarget write SetTarget;
    property Points[Index: Integer]: TPoint read GetPoints write SetPoints;
    property PointCount: Integer read fPointCount;
    property Polyline: TPoints read fPoints write SetPolyline;
  published
    property BeginStyle: TLinkBeginEndStyle read fBeginStyle write SetBeginStyle default lsNone;
    property BeginSize: Byte read fBeginSize write SetBeginSize default 6;
    property EndStyle: TLinkBeginEndStyle read fEndStyle write SetEndStyle default lsArrow;
    property EndSize: Byte read fEndSize write SetEndSize default 6;
    property LinkOptions: TGraphLinkOptions read fLinkOptions write SetLinkOptions default [];
    property TextPosition: Integer read fTextPosition write SetTextPosition default -1;
    property TextSpacing: Integer read fTextSpacing write SetTextSpacing default 0;
  end;

  { EVSSimpleGraph Project }
  TEVSBezierLink  = class(TGraphLink)
  private
    FPolyline :TPoints;
    FCreateByMouse :Boolean;
    
    function GetBezierPolyline(CPs: array of TPoint): TPoints;
  protected
    function IndexOfNearestLine (const Pt: TPoint; Neighborhood: integer): integer;             override;
    function RelativeHookAnchor (RefPt: TPoint): TPoint;                                        override;
    procedure MouseUp           (aButton: TMouseButton; aShift: TShiftState; const aPt: TPoint);override;
    procedure MouseDown         (aButton: TMouseButton; aShift: TShiftState; const aPt: TPoint);override;
    procedure Changed           (aFlags: TGraphChangeFlags);                                 override;
    procedure DrawBody          (aCanvas:TCanvas);                                              override;
    function QueryHitTest       (const aPt: TPoint): DWORD;                                     override;
    procedure DrawHighlight     (aCanvas: TCanvas);                                             override;
    procedure UpdateChangeMode  (aHT: DWORD; aShift: TShiftState);                              override;
  end;


  TSplineLink = class(TGraphLink)
  private
    FCreateByMouse :Boolean;
    fCatPoints: TPoints;     { catmullrom point array }
    fCatCount: integer;      { ÃÑ catmullrom ÀÇ Á¡ÀÇ ¼ö }
    fdupcatcount:integer;
    fdupcatpoints: tpoints;  { fcatpoints ¿¡¼­ Áßº¹À» Á¦°ÅÇÑ point µé, °¢ ±¸°£¸¶´Ù sementcount-1 ¸¸Å­ Á¦°ÅµÈ´Ù. }

    fSegmentCount : integer; { ±¸°£»çÀÌÀÇ Á¡µéÀÇ ¼ö  }

    fStartPoint, fEndPoint: TPoint;

    function FPtToPt(const FP: TFloatPoint): TPoint;
    function IntPtToSinglePt(const P: TPoint): TFloatPoint;
    function PointsEqual ( pt1, PT2:TPoint):Boolean;
    function CatMullRom(a, b, c, d, t: TFloat): TFloat;
    function GetPointOnCurve(const p1, p2, p3, p4: TFloatPoint; t: TFloat): TFloatPoint;  // not
    function GetCatmullromLine(CPs: array of TPoint): TPoints;   // not
    function interpolateCurve(const points: TFloatPoints; segment: integer; var outpoints: TFloatPoints; amountOfPoints: integer; IsaddLastPoint: boolean): single;
    function distancePttoPt(P1, P2: TPoint): double;   // not
    function distancePttoPt_A(P1,P2: TPoint): double;  // not

  protected

    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; const Pt: TPoint);override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; const Pt: TPoint);override;
    procedure MouseMove(Shift: TShiftState; const Pt: TPoint); override;
    procedure Changed(Flags: TGraphChangeFlags);override;
    procedure UpdateChangeMode(hit: DWORD; Shift: TShiftState);override;
    procedure DrawBody(Canvas:TCanvas);override;
    function QueryHitTest(const Pt: TPoint): DWORD;override;
    procedure DrawHighlight(Canvas: TCanvas) ;override;
    function IndexOfNearestLine(const Pt : TPoint;Neighborhood : integer) : integer;override;
    function RelativeHookAnchor(RefPt : TPoint) : TPoint;override;
    //procedure DrawState(Canvas: TCanvas);override;
    procedure QueryVisualRect(out Rect: TRect); override;
  public
    constructor Create(AOwner: TSimpleGraph); override;
    constructor CreateNew(AOwner: TSimpleGraph; ASource: TGraphObject;const Pts: array of TPoint; ATarget: TGraphObject); virtual;
    destructor Destroy; override;

  end;

  TBSplineLink = class(TGraphLink)
  private
    FCreateByMouse: Boolean;
    StartPt, EndPt : TPoint;
  protected
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; const Pt: TPoint);override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; const Pt: TPoint);override;
    procedure MouseMove(Shift: TShiftState; const Pt: TPoint); override;
    procedure Changed(Flags: TGraphChangeFlags);override;
  public
    constructor Create(AOwner: TSimpleGraph); override;
  end;

  { TGraphNode }

  TGraphNodeOption = (gnoMovable, gnoResizable, gnoShowBackground);
  TGraphNodeOptions = set of TGraphNodeOption;

  TGraphNode = class(TGraphObject)
  private
    fLeft: Integer;
    fTop: Integer;
    fWidth: Integer;
    fHeight: Integer;
    fAlignment: TAlignment;
    fLayout: TTextLayout;
    fMargin: Integer;
    fBackground: TPicture;
    fBackgroundMargins: TRect;
    fNodeOptions: TGraphNodeOptions;
    fRegion: HRGN;
    fTextRect: TRect;
    procedure SetLeft(Value: Integer);
    procedure SetTop(Value: Integer);
    procedure SetWidth(Value: Integer);
    procedure SetHeight(Value: Integer);
    procedure SetAlignment(Value: TAlignment);
    procedure SetLayout(Value: TTextLayout);
    procedure SetMargin(Value: Integer);
    procedure SetNodeOptions(Value: TGraphNodeOptions);
    procedure SetBackground(Value: TPicture);
    procedure SetBackgroundMargins(const Value: TRect);
    procedure BackgroundChanged(Sender: TObject);
    procedure ReadBackgroundMargins(Reader: TReader);
    procedure WriteBackgroundMargins(Writer: TWriter);
  protected
    procedure DefineProperties(Filer: TFiler); override;
    procedure Initialize; override;
    function FixHookAnchor: TPoint; override;
    function RelativeHookAnchor(RefPt: TPoint): TPoint; override;
    function LinkIntersect(const LinkPt: TPoint; const LinkAngle: Double): TPoints; virtual; abstract;
    procedure BoundsChanged(dX, dY, dCX, dCY: Integer); override;
    function UpdateTextPlacement(Recalc: Boolean; dX, dY: Integer): Boolean; override;
    procedure QueryMaxTextRect(out Rect: TRect); virtual;
    procedure QueryTextRect(out Rect: TRect); virtual;
    function CreateRegion: HRGN; virtual; abstract;
    function CreateClipRgn(Canvas: TCanvas): HRGN; virtual;
    procedure QueryVisualRect(out Rect: TRect); override;
    function QueryHitTest(const Pt: TPoint): DWORD; override;
    function QueryCursor(HT: DWORD): TCursor; override;
    function QueryMobility(HT: DWORD): TObjectSides; override;
    function OffsetHitTest(HT: DWORD; dX, dY: Integer): Boolean; override;
    procedure SnapHitTestOffset(HT: DWORD; var dX, dY: Integer); override;
    function BeginFollowDrag(HT: DWORD): Boolean; override;
    procedure MoveBy(dX, dY: Integer); override;
    procedure DrawControlPoints(Canvas: TCanvas); override;
    procedure DrawHighlight(Canvas: TCanvas); override;
    procedure DrawText(Canvas: TCanvas); override;
    procedure DrawBackground(Canvas: TCanvas); virtual;
    procedure DrawBorder(Canvas: TCanvas); virtual; abstract;
    procedure DrawBody(Canvas: TCanvas); override;
    procedure SetBoundsRect(const Rect: TRect); override;
    function GetBoundsRect: TRect; override;
    function GetCenter: TPoint; virtual;
  protected
    property Region: HRGN read fRegion;
    property TextRect: TRect read fTextRect;
  public
    constructor Create(AOwner: TSimpleGraph); override;
    constructor CreateNew(AOwner: TSimpleGraph; const Bounds: TRect); virtual;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    function ContainsRect(const Rect: TRect): Boolean; override;
    procedure CanMoveResize(var NewLeft, NewTop, NewWidth, NewHeight: Integer;
      out CanMove, CanResize: Boolean); virtual;
    procedure SetBounds(aLeft, aTop, aWidth, aHeight: Integer); virtual;
    property Center: TPoint read GetCenter;
    property BackgroundMargins: TRect read fBackgroundMargins write SetBackgroundMargins;
  published
    property Left: Integer read fLeft write SetLeft;
    property Top: Integer read fTop write SetTop;
    property Width: Integer read fWidth write SetWidth;
    property Height: Integer read fHeight write SetHeight;
    property Alignment: TAlignment read fAlignment write SetAlignment default taCenter;
    property Layout: TTextLayout read fLayout write SetLayout default tlCenter;
    property Margin: Integer read fMargin write SetMargin default 8;
    property Background: TPicture read fBackground write SetBackground;
    property NodeOptions: TGraphNodeOptions read fNodeOptions write SetNodeOptions
      default [gnoMovable, gnoResizable, gnoShowBackground];
  end;

  { TPolygonalNode }

  TPolygonalNode = class(TGraphNode)
  private
    fVertices: TPoints;
  protected
    procedure Initialize; override;
    procedure BoundsChanged(dX, dY, dCX, dCY: Integer); override;
    function GetCenter: TPoint; override;
    function CreateRegion: HRGN; override;
    procedure DrawBorder(Canvas: TCanvas); override;
    function LinkIntersect(const LinkPt: TPoint; const LinkAngle: Double): TPoints; override;
    procedure DefineVertices(const ARect: TRect; var Points: TPoints); virtual; abstract;
  public
    destructor Destroy; override;
    property Vertices: TPoints read fVertices;
  end;

  { TRoundRectangularNode }

  TRoundRectangularNode = class(TGraphNode)
  protected
    function CreateRegion: HRGN; override;
    procedure DrawBorder(Canvas: TCanvas); override;
    function LinkIntersect(const LinkPt: TPoint; const LinkAngle: Double): TPoints; override;
  end;

  { TEllipticNode }

  TEllipticNode = class(TGraphNode)
  protected
    function CreateRegion: HRGN; override;
    procedure DrawBorder(Canvas: TCanvas); override;
    function LinkIntersect(const LinkPt: TPoint; const LinkAngle: Double): TPoints; override;
  end;

  { TTriangularNode }

  TTriangularNode = class(TPolygonalNode)
  protected
    procedure QueryMaxTextRect(out Rect: TRect); override;
    procedure DefineVertices(const ARect: TRect; var Points: TPoints); override;
  end;

  { TRectangularNode }

  TRectangularNode = class(TPolygonalNode)
  protected
    procedure DefineVertices(const ARect: TRect; var Points: TPoints); override;
  end;

  { TRhomboidalNode }

  TRhomboidalNode = class(TPolygonalNode)
  protected
    procedure QueryMaxTextRect(out Rect: TRect); override;
    procedure DefineVertices(const ARect: TRect; var Points: TPoints); override;
  end;

  { TPentagonalNode }

  TPentagonalNode = class(TPolygonalNode)
  protected
    procedure QueryMaxTextRect(out Rect: TRect); override;
    procedure DefineVertices(const ARect: TRect; var Points: TPoints); override;
  end;

  { THexagonalNode }

  THexagonalNode = class(TPolygonalNode)
  protected
    procedure QueryMaxTextRect(out Rect: TRect); override;
    procedure DefineVertices(const ARect: TRect; var Points: TPoints); override;
  end;

  { TGraphConstraints }

  TGraphConstraints = class(TPersistent)
  private
    fOwner: TSimpleGraph;
    fBoundsRect: TRect;
    fSourceRect: TRect;
    fOnChange: TNotifyEvent;
    procedure SetBoundsRect(const Rect: TRect);
    function GetField(Index: Integer): Integer;
    procedure SetField(Index: Integer; Value: Integer);
  protected
    function GetOwner: TPersistent; override;
    procedure DoChange; virtual;
  public
    constructor Create(AOwner: TSimpleGraph);
    procedure Assign(Source: TPersistent); override;
    procedure SetBounds(aLeft, aTop, aWidth, aHeight: Integer);
    function WithinBounds(const Pts: array of TPoint): Boolean;
    function ConfinePt(var Pt: TPoint): Boolean;
    function ConfineRect(var Rect: TRect): Boolean;
    function ConfineOffset(var dX, dY: Integer; Mobility: TObjectSides): Boolean;
    property Owner: TSimpleGraph read fOwner;
    property BoundsRect: TRect read fBoundsRect write SetBoundsRect;
    property SourceRect: TRect read fSourceRect write fSourceRect;
    property OnChange: TNotifyEvent read fOnChange write fOnChange;
  published
    property MinLeft: Integer index 0 read GetField write SetField default 0;
    property MinTop: Integer index 1 read GetField write SetField default 0;
    property MaxRight: Integer index 2 read GetField write SetField default $0000FFFF;
    property MaxBottom: Integer index 3 read GetField write SetField default $0000FFFF;
  end;

  { TSimpleGraph }

  TGraphNodeClass = class of TGraphNode;
  TGraphLinkClass = class of TGraphLink;

  TGridSize = 4..128;
  TMarkerSize = 3..9;
  TZoom = 5..36863;

  TGraphBoundsKind = (bkGraph, bkSelected, bkDragging);

  TGraphCommandMode = (cmViewOnly, cmPan, cmEdit, cmInsertNode, cmInsertLink);

  TGraphDrawOrder = (doDefault, doNodesOnTop, doLinksOnTop);

  TGraphClipboardFormat = (cfNative, cfMetafile, cfBitmap);
  TGraphClipboardFormats = set of TGraphClipboardFormat;

  TGraphZoomOrigin = (zoTopLeft, zoCenter, zoCursor, zoCursorCenter);

  THAlignOption = (haNoChange, haLeft, haCenter, haRight, haSpaceEqually);
  TVAlignOption = (vaNoChange, vaTop, vaCenter, vaBottom, vaSpaceEqually);

  TResizeOption = (roNoChange, roSmallest, roLargest);

  TGraphNotifyEvent = procedure(Graph: TSimpleGraph; GraphObject: TGraphObject) of object;
  TGraphContextPopupEvent = procedure(Graph: TSimpleGraph; GraphObject: TGraphObject;
    const MousePos: TPoint; var Handled: Boolean) of object;
  TGraphDrawEvent = procedure(Graph: TSimpleGraph; Canvas: TCanvas) of object;
  TGraphObjectDrawEvent = procedure(Graph: TSimpleGraph; GraphObject: TGraphObject;
    Canvas: TCanvas) of object;
  TGraphInfoTipEvent = procedure(Graph: TSimpleGraph; GraphObject: TGraphObject;
    var InfoTip: String) of object;
  TGraphHookEvent = procedure(Graph: TSimpleGraph; GraphObject: TGraphObject;
    Link: TGraphLink; Index: Integer) of object;
  TGraphCanHookEvent = procedure(Graph: TSimpleGraph; GraphObject: TGraphObject;
    Link: TGraphLink; Index: Integer; var CanHook: Boolean) of object;
  TGraphCanLinkEvent = procedure(Graph: TSimpleGraph; Link: TGraphLink;
    Source, Target: TGraphObject; var CanLink: Boolean) of object;
  TCanMoveResizeNodeEvent = procedure(Graph: TSimpleGraph; Node: TGraphNode;
    var NewLeft, NewTop, NewWidth, NewHeight: Integer;
    var CanMove, CanResize: Boolean) of object;
  TGraphNodeResizeEvent = procedure(Graph: TSimpleGraph; Node: TGraphNode) of object;
  TGraphCanRemoveEvent = procedure(Graph: TSimpleGraph; GraphObject: TGraphObject;
    var CanRemove: Boolean) of object;
  TGraphBeginDragEvent = procedure(Graph: TSimpleGraph; GraphObject: TGraphObject;
    HT: DWORD) of object;
  TGraphEndDragEvent = procedure(Graph: TSimpleGraph; GraphObject: TGraphObject;
    HT: DWORD; Cancelled: Boolean) of object;
  TGraphStreamEvent = procedure(Graph: TSimpleGraph; GraphObject: TGraphObject;
    Stream: TStream) of object;

  TGraphForEachMethod = function(GraphObject: TGraphObject;
    UserData: Integer): Boolean of object;

  {$IFNDEF COMPILER5_UP}
  TContextPopupEvent = procedure(Sender: TObject; MousePos: TPoint;
    var Handled: Boolean) of object;
  {$ENDIF}

  {$IFNDEF COMPILER7_UP}
  TWMPrint = packed record
    Msg: Cardinal;
    DC: HDC;
    Flags: Cardinal;
    Result: Integer;
  end;
  {$ENDIF}


  TEditArea = class;
  TEditAreaList = class;
  TEquationList = class;
  TEquatStore = class;
  TEquation = class;

  TQDSGraphic = class(TCustomControl)
  private
    FBkColor: TColor;
    procedure SetBkColor(AValue: TColor); virtual;
  protected
    function GetExprData(const ExprData: String): TExprArray;
    procedure RefreshDimensions; virtual; abstract;
    property BkColor: TColor read FBkColor write SetBkColor;
    property Canvas;
    property Font;
  public
    constructor Create(AOwner: TComponent); override;
  end;


  TEACursor = class(TQDSGraphic)
  private
    FComVisible: Boolean;
    Timer: TTimer;
    function GetParent: TEditArea;
    procedure PutParent(AValue: TEditArea);
    procedure RefreshVisible;
    procedure SetComVisible(Value: Boolean);
  protected
    procedure Paint; override;
    procedure RefreshDimensions; override;
    procedure Time(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property ComVisible: Boolean read FComVisible write SetComVisible;
    property Parent: TEditArea read GetParent write PutParent;
  end;

  TEditArea = class(TQDSGraphic)
  private
    FActive: Boolean;
    FCursor: TEACursor;
    FEquationIndex: Integer;
    FEquationList: TEquationList;
    Index: Integer;
    //MainArea: TQDSEquation;
    MainArea: TSimpleGraph;
    function GetData: string;
    function GetIsEmpty: Boolean;
    function GetParent: TEquatStore;
    procedure OnActive;
    procedure OnDeactive;
    procedure PutParent(AValue: TEquatStore);
    procedure RefreshCursor;
    procedure RefreshEquations;
    procedure RefreshRecurse;
    procedure SetActive(AValue: Boolean);
    procedure SetBkColor(AValue: TColor); override;
    procedure SetData(const AValue: string);
    procedure SetEquationIndex(AValue: Integer);
    procedure SetEquationList(AValue: TEquationList);
    procedure WMLButtonDown(var Message: TWMLButtonDown); message WM_LBUTTONDOWN;
  protected

    function CalcWidth(AIndex: Integer): Integer;
    procedure RefreshDimensions; override;
  public
    function CalcHeight: Integer;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure AddEqBrackets(kb: TKindBracket);
    procedure AddEqExtSymbol(SymbolCode: Integer);
    procedure AddEqIndex(go: TGroupOptions);
    procedure AddEqIntegral(go: TGroupOptions; Size: Integer; Ring: Boolean);
    procedure AddEqSimple(Ch: Char);
    procedure AddEqVector(ka: TKindArrow; ae: TAlignEA); 
    procedure AddEqSumma(go: TGroupOptions);
    procedure AddEqMultiply(go: TGroupOptions);
    procedure AddEqJoin(go: TGroupOptions);
    procedure AddEqIntersection(go: TGroupOptions);
    procedure AddEqCoMult(go: TGroupOptions);
    procedure AddEqArrow(ka: TKindArrow; ae: TAlignEA);
    procedure AddEqSquare;
    procedure AddEqDivision;
    procedure AddEqMatrix(km: TKindMatrix; CountEA: Integer);
    procedure DelEquation(AEquationIndex: Integer);
    procedure Paint; override;
    property Active: Boolean read FActive write SetActive;
    property Cursor: TEACursor read FCursor write FCursor;
    property Data: string read GetData write SetData;
    property EquationIndex: Integer read FEquationIndex write SetEquationIndex;
    property EquationList: TEquationList read FEquationList write
        SetEquationList;
    property IsEmpty: Boolean read GetIsEmpty;
    property Parent: TEquatStore read GetParent write PutParent;
  end;

  TEditAreaList = class(TObjectList)
  private
    function GetItem(Index: Integer): TEditArea;
    procedure SetItem(Index: Integer; AValue: TEditArea);
  public
    property Items[Index: Integer]: TEditArea read GetItem write SetItem;
  end;

  TEquationList = class(TStringList)
  private
    function GetItem(Index: Integer): TEquation;
    procedure PutItem(Index: Integer; AValue: TEquation);
  public
    property Items[Index: Integer]: TEquation read GetItem write PutItem;
  end;

  TEquatStore = class(TQDSGraphic)
  private
    FEditAreaIndex: Integer;
    FEditAreaList: TEditAreaList;
    FLevel: Integer;
    FUpdateCount: Integer;
    Kp: Double;
    procedure SetEditAreaIndex(AValue: Integer);
    procedure SetEditAreaList(AValue: TEditAreaList);
    procedure SetUpdateState(Updating: Boolean); virtual; abstract;
  protected
    procedure EditAreaDown; dynamic;
    procedure EditAreaUp; dynamic;
    procedure RefreshEditArea(AEditAreaIndex: Integer = 0); dynamic;
    property EditAreaIndex: Integer read FEditAreaIndex write SetEditAreaIndex;
    property Level: Integer read FLevel write FLevel;
    property UpdateCount: Integer read FUpdateCount;
  public
    procedure BeginUpdate;
    procedure DeleteEditArea; dynamic;
    procedure EndUpdate;
    procedure InsertEditArea; dynamic;
    property EditAreaList: TEditAreaList read FEditAreaList write
        SetEditAreaList;
  end;

  TEquation = class(TEquatStore)
  private
    Index: Integer;
    function GetData: string; virtual;
    function GetMidLine: Integer; virtual;
    function GetParent: TEditArea;
    procedure PutParent(AValue: TEditArea);
    procedure SetData(const AValue: string); virtual;
    procedure SetUpdateState(Updating: Boolean); override;
    procedure WMLButtonDown(var Message: TWMLButtonDown); message
        WM_LBUTTONDOWN;
    property Data: string read GetData write SetData;
  protected
    function CalcHeight: Integer; dynamic;
    function CalcWidth: Integer; dynamic;
    procedure SetCanvasFont;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Paint; override;
    property MidLine: Integer read GetMidLine;
    property Parent: TEditArea read GetParent write PutParent;
  end;


  TEqParent = class(TEquation)
  private
    function GetData: string; override;
    procedure SetBkColor(AValue: TColor); override;
    procedure SetData(const AValue: string); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure InsertEditArea; override;
  end;

  TEqBrackets = class(TEqParent)
  private
    FLSymbol: WideChar;
    FRSymbol: WideChar;
    FKindBracket: TKindBracket;
    procedure SetKindBracket(AValue: TKindBracket);
    procedure SetLSymbol(Value: WideChar);
    procedure SetRSymbol(Value: WideChar);
  protected
    function CalcSymbolWidth: Integer;
    function CalcSymbolHeight: Integer;
    function CalcHeight: Integer; override;
    function CalcWidth: Integer; override;
    function GetCommonHeight: Integer;
    procedure RefreshDimensions; override;
    procedure RefreshEditArea(AEditAreaIndex: Integer = 0); override;
    property KindBracket: TKindBracket read FKindBracket write SetKindBracket;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Paint; override;
    property LSymbol: WideChar read FLSymbol write SetLSymbol;
    property RSymbol: WideChar read FRSymbol write SetRSymbol;
  end;

  TEqExtSymbol = class(TEquation)
  private
    function GetData: string; override;
  protected
    Symbol: WideChar;
    function CalcHeight: Integer; override;
    function CalcWidth: Integer; override;
    procedure RefreshDimensions; override;
  public
    procedure Paint; override;
  end;
  
  TEqIndex = class(TEqParent)
  private
    FIndexTop, FIndexBottom: TEditArea;
    FGroupOptions: TGroupOptions;
    function GetData: String; override;
    procedure SetData(const AValue: String); override;
    procedure SetGroupOptions(const Value: TGroupOptions);
  protected
    function CalcHeight: Integer; override;
    function CalcWidth: Integer; override;
    procedure RefreshDimensions; override;
    procedure RefreshEA(AEditArea: TEditArea);
    procedure RefreshEditArea(AEditAreaIndex: Integer = 0); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Paint; override;
    property GroupOptions: TGroupOptions read FGroupOptions write SetGroupOptions;
  end;

  TEqGroupOp = class(TEqParent)
  private
    FRing: Boolean;
    FSize: Integer;
    FSymbol: WideChar;
    FGroupOptions: TGroupOptions;
    FLimitTop, FLimitBottom, FIndexTop, FIndexBottom: TEditArea;
    function GetCommonHeight: Integer;
    function GetCommonWidth: Integer;
    function GetData: string; override;
    procedure SetData(const AValue: string); override;
    function GetMidLine: Integer; override;
    function GetSymbolHeight: Integer;
    function GetSymbolWidth: Integer;
    function GetTopMargin: Integer;
    procedure SetGroupOptions(Value: TGroupOptions);
    procedure SetRing(ARing: Boolean);
    procedure SetSize(ASize: Integer);
    procedure SetSymbol(Value: WideChar);
  protected
    function CalcHeight: Integer; override;
    function CalcSymbolHeight: Integer;
    function CalcSymbolWidth: Integer;
    function CalcWidth: Integer; override;
    procedure RefreshDimensions; override;
    procedure RefreshEA(AEditArea: TEditArea; AKp: Double);
    procedure RefreshEditArea(AEditAreaIndex: Integer = 0); override;
  public
    constructor Create(AOwner: TComponent); override;
    property GroupOptions: TGroupOptions read FGroupOptions write SetGroupOptions;
    procedure Paint; override;
    property Ring: Boolean read FRing write SetRing;
    property Size: Integer read FSize write SetSize;
    property Symbol: WideChar read FSymbol write SetSymbol;
    property SymbolHeight: Integer read GetSymbolHeight;
    property SymbolWidth: Integer read GetSymbolWidth;
    property TopMargin: Integer read GetTopMargin;
  end;

  TEqIntegral = class(TEqGroupOp)
  public
    constructor Create(AOwner: TComponent); override;
  end;

  TEqVector = class(TEqParent)
  private
    ArrowHeight, LineHeight: Integer;
    FAlignEA: TAlignEA;
    FKindArrow: TKindArrow;

    function GetMidLine: Integer; override;
    procedure SetKindArrow(Value: TKindArrow);
    procedure SetAlignEA(const Value: TAlignEA);
  protected
    function CalcHeight: Integer; override;
    function CalcWidth: Integer; override;
    procedure RefreshDimensions; override;
    procedure RefreshEditArea(AEditAreaIndex: Integer = 0); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Paint; override;
    property AlignEA: TAlignEA read FAlignEA write SetAlignEA;
    property KindArrow: TKindArrow read FKindArrow write SetKindArrow;
  end;


  TEqSimple = class(TEquation)
  private
    function GetData: string; override;
  protected
    Ch: Char;
    function CalcHeight: Integer; override;
    function CalcWidth: Integer; override;
    procedure RefreshDimensions; override;
  public
    procedure Paint; override;
  end;

  TEqSumma = class(TEqGroupOp)
  public
    constructor Create(AOwner: TComponent); override;
  end;

  TEqMultiply = class(TEqGroupOp)
  public
    constructor Create(AOwner: TComponent); override;
  end;

  TEqIntersection = class(TEqGroupOp)
  public
    constructor Create(AOwner: TComponent); override;
  end;

  TEqJoin = class(TEqGroupOp)
  public
    constructor Create(AOwner: TComponent); override;
  end;

  TEqCoMult = class(TEqGroupOp)
  public
    constructor Create(AOwner: TComponent); override;
  end;

  TEqArrow = class(TEqParent)
  private
    ArrowHeight, LineHeight: Integer;
    FAlignEA: TAlignEA;
    FKindArrow: TKindArrow;

    function GetMidLine: Integer; override;
    procedure SetKindArrow(Value: TKindArrow);
    procedure SetAlignEA(const Value: TAlignEA);
  protected
    function CalcHeight: Integer; override;
    function CalcWidth: Integer; override;
    procedure RefreshDimensions; override;
    procedure RefreshEditArea(AEditAreaIndex: Integer = 0); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Paint; override;
    property AlignEA: TAlignEA read FAlignEA write SetAlignEA;
    property KindArrow: TKindArrow read FKindArrow write SetKindArrow;
  end;

  TEqSquare = class(TEqParent)
  private
    LineHeight: Integer;
    GalkaLeft: Integer;
    function GetMidLine: Integer; override;
  protected
    function CalcHeight: Integer; override;
    function CalcWidth: Integer; override;
    procedure RefreshDimensions; override;
    procedure RefreshEditArea(AEditAreaIndex: Integer = 0); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Paint; override;
  end;


  TEqDivision = class(TEqParent)
  private
    ArrowHeight, LineHeight: Integer;
    function GetData: String; override;
    procedure SetData(const AValue: String); override;
    function GetMidLine: Integer; override;
  protected
    function CalcHeight: Integer; override;
    function CalcWidth: Integer; override;
    procedure RefreshDimensions; override;
    procedure RefreshEA(AEditArea: TEditArea);
    procedure RefreshEditArea(AEditAreaIndex: Integer = 0); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Paint; override;
  end;

  TEqMatrix = class(TEqParent)
  private
    FCountEA: Integer;
    FKindMatrix: TKindMatrix;
    procedure SetData(const AValue: String); override;
    function GetData: String; override;
    function GetDX: Integer;
    function GetDY: Integer;
    function GetColWidth(ACol: Integer): Integer;
    function GetRowHeight(ARow: Integer): Integer;
    function GetMidLine: Integer; override;
    procedure SetKindMatrix(const Value: TKindMatrix);
    procedure SetCountEA(const Value: Integer);
  protected
    function CalcHeight: Integer; override;
    function CalcWidth: Integer; override;
    procedure RefreshDimensions; override;
    procedure RefreshEA(AEditArea: TEditArea);
    procedure RefreshEditArea(AEditAreaIndex: Integer = 0); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Paint; override;
    property CountEA: Integer read FCountEA write SetCountEA;
    property KindMatrix: TKindMatrix read FKindMatrix write SetKindMatrix;
  end;






  
  TSimpleGraph = class(TEquatStore)
  private
    fGridSize: TGridSize;
    fGridColor: TColor;
    fShowGrid: Boolean;
    fSnapToGrid: Boolean;
    fShowHiddenObjects: Boolean;
    fHideSelection: Boolean;
    fLockNodes: Boolean;
    fLockLinks: Boolean;
    fMarkerColor: TColor;
    fMarkerSize: TMarkerSize;
    fZoom: TZoom;
    fObjects: TGraphObjectList;
    fSelectedObjects: TGraphObjectList;
    fDraggingObjects: TGraphObjectList;
    fDefaultKeyMap: Boolean;
    fObjectPopupMenu: TPopupMenu;
    fDefaultNodeClass: TGraphNodeClass;
    fDefaultLinkClass: TGraphLinkClass;
    fModified: Boolean;
    fCommandMode: TGraphCommandMode;
    fHorzScrollBar: TGraphScrollBar;
    fVertScrollBar: TGraphScrollBar;
    fGraphConstraints: TGraphConstraints;
    fMinNodeSize: Word;
    fDrawOrder: TGraphDrawOrder;
    fFixedScrollBars: Boolean;
    fValidMarkedArea: Boolean;
    fMarkedArea: TRect;
    fTransparent: Boolean;
    fDragSource: TGraphObject;
    fDragHitTest: DWORD;
    fDragSourcePt: TPoint;
    fDragTargetPt: TPoint;
    fDragModified: Boolean;
    fCanvasRecall: TCanvasRecall;
    fClipboardFormats: TGraphClipboardFormats;

    fObjectAtCursor: TGraphObject;
    fOnObjectInitInstance: TGraphNotifyEvent;
    fOnObjectInsert: TGraphNotifyEvent;
    fOnObjectRemove: TGraphNotifyEvent;
    fOnObjectChange: TGraphNotifyEvent;
    fOnObjectSelect: TGraphNotifyEvent;
    fOnObjectClick: TGraphNotifyEvent;
    fOnObjectDblClick: TGraphNotifyEvent;
    fOnObjectContextPopup: TGraphContextPopupEvent;
    fOnObjectBeforeDraw: TGraphObjectDrawEvent;
    fOnObjectAfterDraw: TGraphObjectDrawEvent;
    fOnObjectBeginDrag: TGraphBeginDragEvent;
    fOnObjectEndDrag: TGraphEndDragEvent;
    fOnObjectMouseEnter: TGraphNotifyEvent;
    fOnObjectMouseLeave: TGraphNotifyEvent;
    fOnObjectRead: TGraphStreamEvent;
    fOnObjectWrite: TGraphStreamEvent;
    fOnObjectHook: TGraphHookEvent;
    fOnObjectUnhook: TGraphHookEvent;
    fOnCanHookLink: TGraphCanHookEvent;
    fOnCanRemoveObject: TGraphCanRemoveEvent;
    fOnCanLinkObjects: TGraphCanLinkEvent;
    fOnCanMoveResizeNode: TCanMoveResizeNodeEvent;
    fOnNodeMoveResize: TGraphNodeResizeEvent;
    fOnGraphChange: TNotifyEvent;
    fOnBeforeDraw: TGraphDrawEvent;
    fOnAfterDraw: TGraphDrawEvent;
    fOnCommandModeChange: TNotifyEvent;
    {$IFNDEF COMPILER5_UP}
    fOnContextPopup: TContextPopupEvent;
    {$ENDIF}
    fOnInfoTip: TGraphInfoTipEvent;
    fOnZoomChange: TNotifyEvent;
    UpdatingScrollBars: Boolean;
    UpdateCount: Integer;
    SaveModified: Integer;
    SaveRangeChange: Boolean;
    SaveInvalidateRect: TRect;
    SaveBoundsChange: set of TGraphBoundsKind;
    SaveBounds: array[TGraphBoundsKind] of TRect;
    SuspendQueryEvents: Integer;
    UndoStorage: TMemoryStream;


    memo1: TMemo;
    FDoubleBuffer : boolean;
    
    {eq}
    FActiveEditArea: TEditArea;
    FOnChange: TNotifyEvent;

    procedure SetGridSize(Value: TGridSize);
    procedure SetGridColor(Value: TColor);
    procedure SetShowGrid(Value: Boolean);
    procedure SetTransparent(Value: Boolean);
    procedure SetShowHiddenObjects(Value: Boolean);
    procedure SetHideSelection(Value: Boolean);
    procedure SetLockNodes(Value: Boolean);
    procedure SetLockLinks(Value: Boolean);
    procedure SetMarkerColor(Value: TColor);
    procedure SetMarkerSize(Value: TMarkerSize);
    procedure SetZoom(Value: TZoom);
    procedure SetDrawOrder(Value: TGraphDrawOrder);
    procedure SetFixedScrollBars(Value: Boolean);
    procedure SetCommandMode(Value: TGraphCommandMode);
    procedure SetHorzScrollBar(Value: TGraphScrollBar);
    procedure SetVertScrollBar(Value: TGraphScrollBar);
    procedure SetGraphConstraints(Value: TGraphConstraints);
    function GetBoundingRect(Kind: TGraphBoundsKind): TRect;
    function GetVisibleBounds: TRect;
    function GetCursorPos: TPoint;
    procedure SetCursorPos(const Pt: TPoint);
    procedure SetMarkedArea(const Value: TRect);
    {$IFNDEF COMPILER5_UP}
    procedure WMContextMenu(var Msg: TMessage); message WM_CONTEXTMENU;
    {$ENDIF}
    procedure WMPaint(var Msg: TWMPaint); message WM_PAINT;
    procedure WMPrint(var Msg: TWMPrint); message WM_PRINT;
    procedure WMEraseBkgnd(var Msg: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure WMWindowPosChanging(var Msg: TWMWindowPosChanging); message WM_WINDOWPOSCHANGING;
    procedure WMSize(var Msg: TWMSize); message WM_SIZE;
    procedure WMHScroll(var Msg: TWMHScroll); message WM_HSCROLL;
    procedure WMVScroll(var Msg: TWMVScroll); message WM_VSCROLL;
    procedure CNKeyDown(var Msg: TWMKeyDown); message CN_KEYDOWN;
    procedure CNKeyUp(var Msg: TWMKeyUp); message CN_KEYUP;
    procedure CMFontChanged(var Msg: TMessage); message CM_FONTCHANGED;
    procedure CMBiDiModeChanged(var Msg: TMessage); message CM_BIDIMODECHANGED;
    procedure CMMouseLeave(var Msg: TMessage); message CM_MOUSELEAVE;
    procedure CMHintShow(var Msg: TCMHintShow); message CM_HINTSHOW;
    procedure ObjectListChanged(Sender: TObject; GraphObject: TGraphObject;Action: TGraphObjectListAction);
    procedure SelectedListChanged(Sender: TObject; GraphObject: TGraphObject;
      Action: TGraphObjectListAction);
    procedure DraggingListChanged(Sender: TObject; GraphObject: TGraphObject;
      Action: TGraphObjectListAction);
    procedure ObjectChanged(GraphObject: TGraphObject; Flags: TGraphChangeFlags);
    function ReadGraphObject(Stream: TStream): TGraphObject;
    procedure WriteGraphObject(Stream: TStream; GraphObject: TGraphObject);

    {eq
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
    procedure WMLButtonDown(var Message: TWMLButtonDown); message WM_LBUTTONDOWN;
    }
    procedure SetBkColor(AValue: TColor); override;
    procedure SetUpdateState(Updating: Boolean); override;
    function GetData: String;
    procedure SetData(const Value: String);

  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure CreateWnd; override;
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure DoContextPopup(MousePos: TPoint; var Handled: Boolean); {$IFDEF COMPILER5_UP} override; {$ENDIF}
    procedure Click; override;
    procedure DblClick; override;
    procedure DoEnter; override;
    procedure DoExit; override;
    procedure DoZoomChange; virtual;
    procedure DoGraphChange; virtual;
    procedure DoCommandModeChange; virtual;
    procedure DoBeforeDraw(ACanvas: TCanvas); virtual;
    procedure DoAfterDraw(ACanvas: TCanvas); virtual;
    procedure DoObjectClick(GraphObject: TGraphObject); virtual;
    procedure DoObjectDblClick(GraphObject: TGraphObject); virtual;
    procedure DoObjectInitInstance(GraphObject: TGraphObject); virtual;
    procedure DoObjectInsert(GraphObject: TGraphObject); virtual;
    procedure DoObjectRemove(GraphObject: TGraphObject); virtual;
    procedure DoObjectSelect(GraphObject: TGraphObject); virtual;
    procedure DoObjectChange(GraphObject: TGraphObject); virtual;
    procedure DoObjectMouseEnter(GraphObject: TGraphObject); virtual;
    procedure DoObjectMouseLeave(GraphObject: TGraphObject); virtual;
    procedure DoObjectBeforeDraw(ACanvas: TCanvas; GraphObject: TGraphObject); virtual;
    procedure DoObjectAfterDraw(ACanvas: TCanvas; GraphObject: TGraphObject); virtual;
    procedure DoObjectContextPopup(GraphObject: TGraphObject; const MousePos: TPoint;
      var Handled: Boolean); virtual;
    procedure DoObjectBeginDrag(GraphObject: TGraphObject; HT: DWORD); virtual;
    procedure DoObjectEndDrag(GraphObject: TGraphObject; HT: DWORD; Cancelled: Boolean); virtual;
    procedure DoObjectRead(GraphObject: TGraphObject; Stream: TStream); virtual;
    procedure DoObjectWrite(GraphObject: TGraphObject; Stream: TStream); virtual;
    procedure DoObjectUnhook(GraphObject: TGraphObject; Link: TGraphLink; Index: Integer); virtual;
    procedure DoObjectHook(GraphObject: TGraphObject; Link: TGraphLink; Index: Integer); virtual;
    procedure DoCanHookLink(GraphObject: TGraphObject; Link: TGraphLink;
      Index: Integer; var CanHook: Boolean); virtual;
    procedure DoCanLinkObjects(Link: TGraphLink; Source, Target: TGraphObject;
      var CanLink: Boolean); virtual;
    procedure DoCanMoveResizeNode(Node: TGraphNode; var aLeft, aTop, aWidth, aHeight: Integer;
      var CanMove, CanResize: Boolean); virtual;
    procedure DoCanRemoveObject(GraphObject: TGraphObject; var CanRemove: Boolean); virtual;
    procedure DoNodeMoveResize(Node: TGraphNode); virtual;
    procedure ReadObjects(Stream: TStream); virtual;
    procedure WriteObjects(Stream: TStream; ObjectList: TGraphObjectList); virtual;
    procedure RestoreObjects(Stream: TStream); virtual;
    procedure BackupObjects(Stream: TStream; ObjectList: TGraphObjectList); virtual;
    procedure DrawGrid(Canvas: TCanvas); virtual;
    procedure DrawObjects(Canvas: TCanvas; ObjectList: TGraphObjectList); virtual;
    procedure DrawEditStates(Canvas: TCanvas); virtual;
    function CreateUniqueID(GraphObject: TGraphObject): DWORD; virtual;
    function GetAsMetafile(RefDC: HDC; ObjectList: TGraphObjectList): TMetafile; virtual;
    function GetAsBitmap(ObjectList: TGraphObjectList): TBitmap; virtual;
    function GetObjectsBounds(ObjectList: TGraphObjectList): TRect; virtual;
    procedure AdjustDC(DC: HDC; Org: PPoint = nil); virtual;
    procedure GPToCP(var Points; Count: Integer);
    procedure CPToGP(var Points; Count: Integer);
    procedure UpdateScrollBars; virtual;
    procedure CalcAutoRange; virtual;
    function BeginDragObject(GraphObject: TGraphObject;
      const Pt: TPoint; HT: DWORD): Boolean; virtual;
    procedure PerformDragBy(dX, dY: Integer); virtual;
    procedure EndDragObject(Accept: Boolean); virtual;
    procedure PerformInvalidate(pRect: PRect);
    procedure CheckObjectAtCursor(const Pt: TPoint); virtual;
    procedure RenewObjectAtCursor(NewObjectAtCursor: TGraphObject); virtual;
    function InsertObjectByMouse(var Pt: TPoint; GraphObjectClass: TGraphObjectClass;
      GridSnap: Boolean): TGraphObject;
    function DefaultKeyHandler(var Key: Word; Shift: TShiftState): Boolean; virtual;

    { eq }
    function CalcWidth: Integer;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    function CalcHeight(AIndex: Integer): Integer;
    procedure FontChanged(Sender: TObject); dynamic;
    procedure RefreshEditArea(AEditAreaIndex: Integer = 0); override;
    procedure Change; virtual;
    procedure RefreshDimensions; override;
    procedure EditAreaDown; override;
    procedure EditAreaUp; override;
  protected
    property CanvasRecall: TCanvasRecall read fCanvasRecall;
    property DragSourcePt: TPoint read fDragSourcePt write fDragSourcePt;
    property DragTargetPt: TPoint read fDragTargetPt write fDragTargetPt;
    property DragHitTest: DWORD read fDragHitTest write fDragHitTest;
    property DragModified: Boolean read fDragModified;
    property ValidMarkedArea: Boolean read fValidMarkedArea;
    property MarkedArea: TRect read fMarkedArea write SetMarkedArea;
  public
    class procedure Register(ANodeClass: TGraphNodeClass); overload;
    class procedure Unregister(ANodeClass: TGraphNodeClass); overload;
    class function NodeClassCount: Integer;
    class function NodeClasses(Index: Integer): TGraphNodeClass;
    class procedure Register(ALinkClass: TGraphLinkClass); overload;
    class procedure Unregister(ALinkClass: TGraphLinkClass); overload;
    class function LinkClassCount: Integer;
    class function LinkClasses(Index: Integer): TGraphLinkClass;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure BeginUpdate;
    procedure EndUpdate;
    procedure Invalidate; override;
    procedure InvalidateRect(const Rect: TRect);
    procedure Draw(Canvas: TCanvas);
    procedure Print(Canvas: TCanvas; const Rect: TRect);
    procedure ToggleSelection(const Rect: TRect; KeepOld: Boolean;
      GraphObjectClass: TGraphObjectClass = nil);
    function FindObjectAt(X, Y: Integer;
      LookAfter: TGraphObject = nil): TGraphObject;
    function FindObjectByID(ID: DWORD): TGraphObject;
    function InsertNode(const Bounds: TRect;
      ANodeClass: TGraphNodeClass = nil): TGraphNode;
    function InsertLink(Source, Target: TGraphObject;
      ALinkClass: TGraphLinkClass = nil): TGraphLink; overload;
    function InsertLink(Source: TGraphObject; const Pts: array of TPoint;
      ALinkClass: TGraphLinkClass = nil): TGraphLink; overload;
    function InsertLink(const Pts: array of TPoint; Target: TGraphObject;
      ALinkClass: TGraphLinkClass = nil): TGraphLink; overload;
    function InsertLink(const Pts: array of TPoint;
      ALinkClass: TGraphLinkClass = nil): TGraphLink; overload;
    procedure ScrollInView(GraphObject: TGraphObject); overload;
    procedure ScrollInView(const Rect: TRect); overload;
    procedure ScrollInView(const Pt: TPoint); overload;
    procedure ScrollCenter(GraphObject: TGraphObject); overload;
    procedure ScrollCenter(const Rect: TRect); overload;
    procedure ScrollCenter(const Pt: TPoint); overload;
    procedure ScrollBy(DeltaX, DeltaY: Integer);
    function ZoomRect(const Rect: TRect): Boolean;
    function ZoomObject(GraphObject: TGraphObject): Boolean;
    function ZoomSelection: Boolean;
    function ZoomGraph: Boolean;
    function ChangeZoom(NewZoom: Integer; Origin: TGraphZoomOrigin): Boolean;
    function ChangeZoomBy(Delta: Integer; Origin: TGraphZoomOrigin): Boolean;
    function AlignSelection(Horz: THAlignOption; Vert: TVAlignOption): Boolean;
    function ResizeSelection(Horz: TResizeOption; Vert: TResizeOption): Boolean;
    function ForEachObject(Callback: TGraphForEachMethod; UserData: Integer;
      Selection: Boolean = False): Integer;
    function FindNextObject(StartIndex: Integer; Inclusive, Backward,
      Wrap: Boolean; GraphObjectClass: TGraphObjectClass = nil): TGraphObject;
    function SelectNextObject(Backward: Boolean;
      GraphObjectClass: TGraphObjectClass = nil): Boolean;
    function ObjectsCount(GraphObjectClass: TGraphObjectClass = nil): Integer;
    function SelectedObjectsCount(GraphObjectClass: TGraphObjectClass = nil): Integer;
    procedure ClearSelection;
    procedure Clear;
    procedure SaveAsMetafile(const Filename: String);
    procedure SaveAsBitmap(const Filename: String);
    procedure CopyToGraphic(Graphic: TGraphic);
    procedure LoadFromStream(Stream: TStream);
    procedure SaveToStream(Stream: TStream);
    procedure LoadFromFile(const Filename: String);
    procedure SaveToFile(const Filename: String);
    procedure MergeFromStream(Stream: TStream; OffsetX, OffsetY: Integer);
    procedure MergeFromFile(const Filename: String; OffsetX, OffsetY: Integer);
    procedure CopyToClipboard(Selection: Boolean = True);
    function PasteFromClipboard: Boolean;
    procedure SnapOffset(const Pt: TPoint; var dX, dY: Integer);
    function SnapPoint(const Pt: TPoint): TPoint;
    function ClientToGraph(X, Y: Integer): TPoint;
    function GraphToClient(X, Y: Integer): TPoint;
    function ScreenToGraph(X, Y: Integer): TPoint;
    function GraphToScreen(X, Y: Integer): TPoint;
    property DragSource: TGraphObject read fDragSource;
    property ObjectAtCursor: TGraphObject read fObjectAtCursor;
    property CursorPos: TPoint read GetCursorPos write SetCursorPos;
    property VisibleBounds: TRect read GetVisibleBounds;
    property GraphBounds: TRect index bkGraph read GetBoundingRect;
    property SelectionBounds: TRect index bkSelected read GetBoundingRect;
    property DraggingBounds: TRect index bkDragging read GetBoundingRect;
    property Objects: TGraphObjectList read fObjects;
    property SelectedObjects: TGraphObjectList read fSelectedObjects;
    property DraggingObjects: TGraphObjectList read fDraggingObjects;
    property Modified: Boolean read fModified write fModified;
    property CommandMode: TGraphCommandMode read fCommandMode write SetCommandMode;
    property DefaultNodeClass: TGraphNodeClass read fDefaultNodeClass write fDefaultNodeClass;
    property DefaultLinkClass: TGraphLinkClass read fDefaultLinkClass write fDefaultLinkClass;
    {eq
    procedure DeleteEditArea; override;
    //procedure Paint; override;
    property Canvas;
    }
    procedure AddEditArea; overload;
    procedure AddEditArea(Area: TEditArea); overload;
    procedure InsertEditArea; override;
    property ActiveEditArea: TEditArea read FActiveEditArea write FActiveEditArea;

    property DoubleBuffer: boolean read FDoubleBuffer write FDoubleBuffer;
  published
    property Canvas;  {2020, added}
    property Align;
    property Anchors;
    property BiDiMode;
    property ClipboardFormats: TGraphClipboardFormats read fClipboardFormats write fClipboardFormats default [cfNative];
    property Color;
    property Constraints;
    property DefaultKeyMap: Boolean read fDefaultKeyMap write fDefaultKeyMap default True;
    property DragCursor;
    property DragKind;
    property DragMode;
    property DrawOrder: TGraphDrawOrder read fDrawOrder write SetDrawOrder default doDefault;
    property Enabled;
    property FixedScrollBars: Boolean read fFixedScrollBars write SetFixedScrollBars default False;
    property Font;
    property GraphConstraints: TGraphConstraints read fGraphConstraints write SetGraphConstraints;
    property GridColor: TColor read fGridColor write SetGridColor default clGray;
    property GridSize: TGridSize read fGridSize write SetGridSize default 8;
    property Height;
    property HideSelection: Boolean read fHideSelection write SetHideSelection default False;
    property HorzScrollBar: TGraphScrollBar read fHorzScrollBar write SetHorzScrollBar;
    property LockLinks: Boolean read fLockLinks write SetLockLinks default False;
    property LockNodes: Boolean read fLockNodes write SetLockNodes default False;
    property MarkerColor: TColor read fMarkerColor write SetMarkerColor default clBlack;
    property MarkerSize: TMarkerSize read fMarkerSize write SetMarkerSize default 3;
    property MinNodeSize: Word read fMinNodeSize write fMinNodeSize default 16;
    property ObjectPopupMenu: TPopupMenu read fObjectPopupMenu write fObjectPopupMenu;
    property ParentBiDiMode;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowGrid: Boolean read fShowGrid write SetShowGrid default True;
    property ShowHiddenObjects: Boolean read fShowHiddenObjects write SetShowHiddenObjects default False;
    property ShowHint;
    property SnapToGrid: Boolean read fSnapToGrid write fSnapToGrid default True;
    property TabOrder;
    property TabStop;
    property Transparent: Boolean read fTransparent write SetTransparent default False;
    property VertScrollBar: TGraphScrollBar read fVertScrollBar write SetVertScrollBar;
    property Visible;
    property Width;
    property Zoom: TZoom read fZoom write SetZoom default 100;
    property OnCanResize;
    property OnClick;
    property OnConstrainedResize;
    {$IFNDEF COMPILER5_UP}
    property OnContextPopup: TContextPopupEvent read fOnContextPopup write fOnContextPopup;
    {$ELSE}
    property OnContextPopup;
    {$ENDIF}
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnDockDrop;
    property OnDockOver;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnGetSiteInfo;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseWheelDown;
    property OnMouseWheelUp;
    property OnResize;
    property OnStartDock;
    property OnStartDrag;
    property OnUnDock;
    property OnObjectInitInstance: TGraphNotifyEvent read fOnObjectInitInstance write fOnObjectInitInstance;
    property OnObjectInsert: TGraphNotifyEvent read fOnObjectInsert write fOnObjectInsert;
    property OnObjectRemove: TGraphNotifyEvent read fOnObjectRemove write fOnObjectRemove;
    property OnObjectChange: TGraphNotifyEvent read fOnObjectChange write fOnObjectChange;
    property OnObjectSelect: TGraphNotifyEvent read fOnObjectSelect write fOnObjectSelect;
    property OnObjectClick: TGraphNotifyEvent read fOnObjectClick write fOnObjectClick;
    property OnObjectDblClick: TGraphNotifyEvent read fOnObjectDblClick write fOnObjectDblClick;
    property OnObjectContextPopup: TGraphContextPopupEvent read fOnObjectContextPopup write fOnObjectContextPopup;
    property OnObjectBeforeDraw: TGraphObjectDrawEvent read fOnObjectBeforeDraw write fOnObjectBeforeDraw;
    property OnObjectAfterDraw: TGraphObjectDrawEvent read fOnObjectAfterDraw write fOnObjectAfterDraw;
    property OnObjectBeginDrag: TGraphBeginDragEvent read fOnObjectBeginDrag write fOnObjectBeginDrag;
    property OnObjectEndDrag: TGraphEndDragEvent read fOnObjectEndDrag write fOnObjectEndDrag;
    property OnObjectMouseEnter: TGraphNotifyEvent read fOnObjectMouseEnter write fOnObjectMouseEnter;
    property OnObjectMouseLeave: TGraphNotifyEvent read fOnObjectMouseLeave write fOnObjectMouseLeave;
    property OnObjectRead: TGraphStreamEvent read fOnObjectRead write fOnObjectRead;
    property OnObjectWrite: TGraphStreamEvent read fOnObjectWrite write fOnObjectWrite;
    property OnObjectHook: TGraphHookEvent read fOnObjectHook write fOnObjectHook;
    property OnObjectUnhook: TGraphHookEvent read fOnObjectUnhook write fOnObjectUnhook;
    property OnCanHookLink: TGraphCanHookEvent read fOnCanHookLink write fOnCanHookLink;
    property OnCanLinkObjects: TGraphCanLinkEvent read fOnCanLinkObjects write fOnCanLinkObjects;
    property OnCanMoveResizeNode: TCanMoveResizeNodeEvent read fOnCanMoveResizeNode write fOnCanMoveResizeNode;
    property OnCanRemoveObject: TGraphCanRemoveEvent read fOnCanRemoveObject write fOnCanRemoveObject;
    property OnNodeMoveResize: TGraphNodeResizeEvent read fOnNodeMoveResize write fOnNodeMoveResize;
    property OnGraphChange: TNotifyEvent read fOnGraphChange write fOnGraphChange;
    property OnCommandModeChange: TNotifyEvent read fOnCommandModeChange write fOnCommandModeChange;
    property OnBeforeDraw: TGraphDrawEvent read fOnBeforeDraw write fOnBeforeDraw;
    property OnAfterDraw: TGraphDrawEvent read fOnAfterDraw write fOnAfterDraw;
    property OnInfoTip: TGraphInfoTipEvent read fOnInfoTip write fOnInfoTip;
    property OnZoomChange: TNotifyEvent read fOnZoomChange write fOnZoomChange;
    {eq
    //property Align;
    //property Anchors;
    property BkColor;
    property Data: String read GetData write SetData;
    //property Enabled;
    //property Font;
    property Version: String read FVersion;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    }
    property Data: String read GetData write SetData;
  end;


function WrapText(Canvas: TCanvas; const Text: String; MaxWidth: Integer): String;
function MinimizeText(Canvas: TCanvas; const Text: String; const Rect: TRect): String;

function IsBetween(Value: Integer; Bound1, Bound2: Integer): Boolean;

function TransformRgn(Rgn: HRGN; const XForm: TXForm): HRGN;

function NormalizeAngle(const Angle: Double): Double;

function EqualPoint(const Pt1, Pt2: TPoint): Boolean;
procedure TransformPoints(var Points: array of TPoint; const XForm: TXForm);
procedure RotatePoints(var Points: array of TPoint; const Angle: Double; const OrgPt: TPoint);
procedure ScalePoints(var Points: array of TPoint; const Factor: Double; const RefPt: TPoint);
procedure ShiftPoints(var Points: array of TPoint; dX, dY: Integer; const RefPt: TPoint);
procedure OffsetPoints(var Points: array of TPoint; dX, dY: Integer);
function CenterOfPoints(const Points: array of TPoint): TPoint;
function BoundsRectOfPoints(const Points: array of TPoint): TRect;
function NearestPoint(const Points: array of TPoint; const RefPt: TPoint; out NearestPt: TPoint): Integer;

function MakeSquare(const Center: TPoint; Radius: Integer): TRect;
function MakeRect(const Corner1, Corner2: TPoint): TRect;

function CenterOfRect(const Rect: TRect): TPoint;
procedure UnionRect(var DstRect: TRect; const SrcRect: TRect);
procedure IntersectRect(var DstRect: TRect; const SrcRect: TRect);
function OverlappedRect(const Rect1, Rect2: TRect): Boolean;

function LineLength(const LinePt1, LinePt2: TPoint): Double;
function LineSlopeAngle(const LinePt1, LinePt2: TPoint): Double;
function DistanceToLine(const LinePt1, LinePt2: TPoint; const QueryPt: TPoint): Double;
function NearestPointOnLine(const LinePt1, LinePt2: TPoint; const RefPt: TPoint): TPoint;
function NextPointOfLine(const LineAngle: Double; const ThisPt: TPoint;
  const DistanceFromThisPt: Double): TPoint;

function IntersectLines(const Line1Pt: TPoint; const Line1Angle: Double;
  const Line2Pt: TPoint; const Line2Angle: Double;
  out Intersect: TPoint): Boolean;

function IntersectLineRect(const LinePt: TPoint; const LineAngle: Double;
  const Rect: TRect): TPoints;
function IntersectLineEllipse(const LinePt: TPoint; const LineAngle: Double;
  const Bounds: TRect): TPoints;
function IntersectLineRoundRect(const LinePt: TPoint; const LineAngle: Double;
  const Bounds: TRect; CW, CH: Integer): TPoints;
function IntersectLinePolygon(const LinePt: TPoint; const LineAngle: Double;
  const Vertices: array of TPoint): TPoints;
function IntersectLinePolyline(const LinePt: TPoint; const LineAngle: Double;
  const Vertices: array of TPoint): TPoints;

{ add 2020 }  
function makepoint(x,y:integer):TPoint;
function copynewpoints(const points: TPoints):TPoints;
procedure duplicateremovepoint(var arr:tpoints; var count:integer);
function RectToString(r: TRect): string;
function PointTostring(p: TPoint): string;

var
  CF_SIMPLEGRAPH: Integer = 0;

procedure Register;

implementation

{$R *.RES}

uses
  {$IFDEF COMPILER6_UP} Types, {$ENDIF}
  {$IFDEF COMPILER_XE3_UP} UITypes, {$ENDIF}
  Math, SysUtils, CommCtrl, Clipbrd;

resourcestring
  SListIndexError     = 'Index out of range (%d)';
  SListEnumerateError = 'List enumeration is not initialized';
  SStreamContentError = 'Invalid stream content';
  SLinkCreateError    = 'Cannot create link with the specified parameters'; 

const
  StreamSignature: DWORD =
    (Ord('S') shl 24) or (Ord('G') shl 16) or (Ord('.') shl 8) or Ord('0');

const
  TextAlignFlags: array[TAlignment] of Integer = (DT_LEFT, DT_RIGHT, DT_CENTER);
  TextLayoutFlags: array[TTextLayout] of Integer = (DT_TOP, DT_VCENTER, DT_BOTTOM);

const
  Pi: Double = System.Pi;
  MaxDouble: Double = +1.7E+308;

const
  EmptyRect: TRect = (Left: +MaxInt; Top: +MaxInt; Right: -MaxInt; Bottom: -MaxInt);

var
  RegisteredNodeClasses: TList;
  RegisteredLinkClasses: TList;

{ Helper Functions }

type TParentControl = class(TWinControl);

{ This procedure is adapted from RxLibrary VCLUtils. }
procedure CopyParentImage(Control: TControl; DC: HDC; X, Y: Integer);
var
  I, SaveIndex: Integer;
  SelfR, CtlR: TRect;
  NextControl: TControl;
begin
  if (Control = nil) or (Control.Parent = nil) then Exit;
  with Control.Parent do
    ControlState := ControlState + [csPaintCopy];
  try
    SelfR := Control.BoundsRect;
    Inc(X, SelfR.Left);
    Inc(Y, SelfR.Top);
    SaveIndex := SaveDC(DC);
    try
      SetViewportOrgEx(DC, -X, -Y, nil);
      with TParentControl(Control.Parent) do
      begin
        with ClientRect do
          IntersectClipRect(DC, Left, Top, Right, Bottom);
        {$IFDEF COMPILER9_UP}
        Perform(WM_PRINT, DC, PRF_CHECKVISIBLE or WM_ERASEBKGND or PRF_CHILDREN);
        {$ELSE}
        Perform(WM_ERASEBKGND, DC, 0);
        PaintWindow(DC);
        {$ENDIF}
      end;
    finally
      RestoreDC(DC, SaveIndex);
    end;
    for I := 0 to Control.Parent.ControlCount - 1 do
    begin
      NextControl := Control.Parent.Controls[I];
      if NextControl = Control then
        Break
      else if (NextControl <> nil) and (NextControl is TGraphicControl) then
      begin
        with TGraphicControl(NextControl) do
        begin
          CtlR := BoundsRect;
          if Visible and OverlappedRect(SelfR, CtlR) then
          begin
            ControlState := ControlState + [csPaintCopy];
            SaveIndex := SaveDC(DC);
            try
              SetViewportOrgEx(DC, Left - X, Top - Y, nil);
              IntersectClipRect(DC, 0, 0, Width, Height);
              Perform(WM_ERASEBKGND, DC, 0);
              Perform(WM_PAINT, DC, 0);
            finally
              RestoreDC(DC, SaveIndex);
              ControlState := ControlState - [csPaintCopy];
            end;
          end;
        end;
      end;
    end;
  finally
    with Control.Parent do
      ControlState := ControlState - [csPaintCopy];
  end;
end;

function WrapText(Canvas: TCanvas; const Text: String; MaxWidth: Integer): String;
var
  DC: HDC;
  TextExtent: TSize;
  S, P, E: PChar;
  Line: String;
  IsFirstLine: Boolean;
begin
  Result := '';
  DC := Canvas.Handle;
  IsFirstLine := True;
  P := PChar(Text);
  while P^ = ' ' do
    Inc(P);
  while P^ <> #0 do
  begin
    S := P;
    E := nil;
    while (P^ <> #0) and (P^ <> #13) and (P^ <> #10) do
    begin
      GetTextExtentPoint32(DC, S, P - S + 1, TextExtent);
      if (TextExtent.CX > MaxWidth) and (E <> nil) then
      begin
        if (P^ <> ' ') and (P^ <> ^I) then
        begin
          while (E >= S) do
            case E^ of
              '.', ',', ';', '?', '!', '-', ':',
              ')', ']', '}', '>', '/', '\', ' ':
                break;
            else
              Dec(E);
            end;
          if E < S then
            E := P - 1;
        end;
        Break;
      end;
      E := P;
      Inc(P);
    end;
    if E <> nil then
    begin
      while (E >= S) and (E^ = ' ') do
        Dec(E);
    end;
    if E <> nil then
      SetString(Line, S, E - S + 1)
    else
      SetLength(Line, 0);
    if (P^ = #13) or (P^ = #10) then
    begin
      Inc(P);
      if (P^ <> (P - 1)^) and ((P^ = #13) or (P^ = #10)) then
        Inc(P);
      if P^ = #0 then
        Line := Line + #13#10;
    end
    else if P^ <> ' ' then
      P := E + 1;
    while P^ = ' ' do
      Inc(P);
    if IsFirstLine then
    begin
      Result := Line;
      IsFirstLine := False;
    end
    else
      Result := Result + #13#10 + Line;
  end;
end;

function MinimizeText(Canvas: TCanvas; const Text: String; const Rect: TRect): String;
const
  EllipsisSingle: String = '…';
  EllipsisTriple: String = '...';
var
  DC: HDC;
  S, E: PChar;
  TextExtent: TSize;
  TextHeight: Integer;
  LastLine: String;
  Ellipsis: PString;
  MaxWidth, MaxHeight: Integer;
  GlyphIndex: WORD;
begin
  MaxWidth := Rect.Right - Rect.Left;
  MaxHeight := Rect.Bottom - Rect.Top;
  Result := WrapText(Canvas, Text, MaxWidth);
  DC := Canvas.Handle;
  TextHeight := 0;
  S := PChar(Result);
  while S^ <> #0 do
  begin
    E := S;
    while (E^ <> #0) and (E^ <> #13) and (E^ <> #10) do
      Inc(E);
    if E > S then
      GetTextExtentPoint32(DC, S, E - S, TextExtent)
    else
      GetTextExtentPoint32(DC, ' ', 1, TextExtent);
    Inc(TextHeight, TextExtent.CY);
    if TextHeight <= MaxHeight then
    begin
      S := E;
      if S^ <> #0 then
      begin
        Inc(S);
        if (S^ <> (S - 1)^) and ((S^ = #13) or (S^ = #10)) then
          Inc(S);
      end;
    end
    else
    begin
      repeat
        Dec(S);
      until (S < PChar(Result)) or ((S^ <> #13) and (S^ <> #10));
      SetLength(Result, S - PChar(Result) + 1);
      if S >= PChar(Result) then
      begin
        E := StrEnd(PChar(Result));
        S := E;
        repeat
          Dec(S)
        until (S < PChar(Result)) or ((S^ = #13) or (S^ = #10));
        SetString(LastLine, S + 1, E - S - 1);
        SetLength(Result, S - PChar(Result) + 1);
        GetGlyphIndices(DC, PChar(EllipsisSingle), 1, @GlyphIndex, GGI_MARK_NONEXISTING_GLYPHS);
        if GlyphIndex = $FFFF then
          Ellipsis := @EllipsisTriple
        else
          Ellipsis := @EllipsisSingle;
        LastLine := LastLine + Ellipsis^;
        GetTextExtentPoint32(DC, PChar(LastLine), Length(LastLine), TextExtent);
        while (TextExtent.CX > MaxWidth) and (Length(LastLine) > Length(Ellipsis^)) do
        begin
          Delete(LastLine, Length(LastLine) - Length(Ellipsis^), 1);
          GetTextExtentPoint32(DC, PChar(LastLine), Length(LastLine), TextExtent);
        end;
        Result := Result + LastLine;
      end;
      Break;
    end;
  end;
end;

function Sqr(const X: Double): Double;
begin
  Result := X * X;
end;

function IsBetween(Value: Integer; Bound1, Bound2: Integer): Boolean;
begin
  if Bound1 <= Bound2 then
    Result := (Value >= Bound1) and (Value <= Bound2)
  else
    Result := (Value >= Bound2) and (Value <= Bound1);
end;

function EqualPoint(const Pt1, Pt2: TPoint): Boolean;
begin
  Result := (Pt1.X = Pt2.X) and (Pt1.Y = Pt2.Y);
end;

procedure TransformPoints(var Points: array of TPoint; const XForm: TXForm);
var
  I: Integer;
begin
 for I := Low(Points) to High(Points) do
   with Points[I], XForm do
   begin
     X := Round(X * eM11 + Y * eM21 + eDx);
     Y := Round(X * eM12 + Y * eM22 + eDy);
   end;
end;

procedure RotatePoints(var Points: array of TPoint;
  const Angle: Double; const OrgPt: TPoint);
var
  Sin, Cos: Extended;
  Prime: TPoint;
  I: Integer;
begin
 SinCos(NormalizeAngle(Angle), Sin, Cos);
 for I := Low(Points) to High(Points) do
   with Points[I] do
   begin
     Prime.X := X - OrgPt.X;
     Prime.Y := Y - OrgPt.Y;
     X := Round(Prime.X * Cos - Prime.Y * Sin) + OrgPt.X;
     Y := Round(Prime.X * Sin + Prime.Y * Cos) + OrgPt.Y;
   end;
end;

procedure OffsetPoints(var Points: array of TPoint; dX, dY: Integer);
var
  I: Integer;
begin
  for I := Low(Points) to High(Points) do
    with Points[I] do
    begin
      Inc(X, dX);
      Inc(Y, dY);
    end;
end;

procedure ScalePoints(var Points: array of TPoint; const Factor: Double; const RefPt: TPoint);
var
  I: Integer;
  Angle: Double;
  Distance: Double;
begin
  for I := Low(Points) to High(Points) do
  begin
    Angle := LineSlopeAngle(Points[I], RefPt);
    Distance := LineLength(Points[I], RefPt);
    Points[I] := NextPointOfLine(Angle, RefPt, Distance * Factor);
  end;
end;

procedure ShiftPoints(var Points: array of TPoint; dX, dY: Integer; const RefPt: TPoint);
var
  I: Integer;
begin
  for I := Low(Points) to High(Points) do
    with Points[I] do
    begin
      if X < RefPt.X then
        Dec(X, dX)
      else if X > RefPt.X then
        Inc(X, dX);
      if Y < RefPt.Y then
        Dec(Y, dY)
      else if Y > RefPt.Y then
        Inc(Y, dY);
    end;
end;

function CenterOfPoints(const Points: array of TPoint): TPoint;
var
  I: Integer;
  Sum: TPoint;
begin
  Sum.X := 0;
  Sum.Y := 0;
  for I := Low(Points) to High(Points) do
    with Points[I] do
    begin
      Inc(Sum.X, X);
      Inc(Sum.Y, Y);
    end;
  Result.X := Sum.X div Length(Points);
  Result.Y := Sum.Y div Length(Points);
end;

function BoundsRectOfPoints(const Points: array of TPoint): TRect;
var
  I: Integer;
begin
  SetRect(Result, MaxInt, MaxInt, -MaxInt, -MaxInt);
  for I := Low(Points) to High(Points) do
    with Points[I], Result do
    begin
      if X < Left then Left := X;
      if Y < Top then Top := Y;
      if X > Right then Right := X;
      if Y > Bottom then Bottom := Y;
    end;
end;

function makepoint(x,y:integer):TPoint;
begin
    result.x := x;
    result.Y := y;
end;

procedure duplicateremovepoint(var arr:tpoints; var count:integer);
var
  i,j,k,tot,mov:integer;
begin
  tot := 0;
  for i := 0 to length(arr)-1 do
  begin
    if i >= length(arr)-tot-1 then
      continue;
    for j := i + 1 to length(arr)-1-tot do
    begin
      if j >= length(arr)-tot-1 then
        continue;
      mov := 0;
      while equalpoint(arr[i],arr[j]) do
      begin
        inc(mov);
        arr[j] := arr[j+mov];
      end;
      tot := tot + mov;
      if mov>0 then
        for k := j+1 to length(arr)-1-tot do
          arr[k] := arr[k+mov];
    end;
  end;
  count := length(arr)-tot-1;
  SetLength(arr,length(arr)-tot-1);
end;

function RectToString(r: TRect): string;
begin
  result := '(' + PointTostring(r.TopLeft) + ',' + PointTostring(r.BottomRight) + ')';
end;

function PointTostring(p: TPoint): string;
begin
  result := '(' + inttostr(p.X) + ',' + inttostr(p.Y) + ')';
end;

(*
procedure ForceUnique;
var
  i, j: integer;
begin
  for i := 2 to 5 do {the first element is unique by definition}
  begin
    j := 1;
    while (j < i) do
    begin
      if MyArray[j] = MyArray[i] then
      begin
        MyArray[i] := Random(MyRange);
        j := 1; {start over with a new number}
      end
      else
        j := j + 1;
    end;
  end;
end;
*)

function copynewpoints(const points: TPoints):TPoints;
var
  I:integer;
begin
  setlength(result, length(points));
  Move(points[0], result[0], SizeOf(Byte)*Length(points));
  //for I:=0 to high(points) do
  //  result[I] := points[I];
end;

function NearestPoint(const Points: array of TPoint; const RefPt: TPoint;
  out NearestPt: TPoint): Integer;
var
  I: Integer;
  Distance: Double;
  NearestDistance: Double;
begin
  Result := -1;
  NearestDistance := MaxDouble;
  for I := Low(Points) to High(Points) do
  begin
    Distance := LineLength(Points[I], RefPt);
    if Distance < NearestDistance then
    begin
      NearestDistance := Distance;
      Result := I;
    end;
  end;
  if Result >= 0 then
    NearestPt := Points[Result];
end;

function MakeSquare(const Center: TPoint; Radius: Integer): TRect;
begin
  Result.TopLeft := Center;
  Result.BottomRight := Center;
  InflateRect(Result, Radius, Radius);
end;

function MakeRect(const Corner1, Corner2: TPoint): TRect;
begin
  if Corner1.X > Corner2.X then
  begin
    Result.Left := Corner2.X;
    Result.Right := Corner1.X;
  end
  else
  begin
    Result.Left := Corner1.X;
    Result.Right := Corner2.X;
  end;
  if Corner1.Y > Corner2.Y then
  begin
    Result.Top := Corner2.Y;
    Result.Bottom := Corner1.Y;
  end
  else
  begin
    Result.Top := Corner1.Y;
    Result.Bottom := Corner2.Y;
  end
end;

function CenterOfRect(const Rect: TRect): TPoint;
begin
  Result.X := (Rect.Left + Rect.Right) div 2;
  Result.Y := (Rect.Top + Rect.Bottom) div 2;
end;

procedure UnionRect(var DstRect: TRect; const SrcRect: TRect);
begin
  if DstRect.Left > SrcRect.Left then
    DstRect.Left := SrcRect.Left;
  if DstRect.Top > SrcRect.Top then
    DstRect.Top := SrcRect.Top;
  if DstRect.Right < SrcRect.Right then
    DstRect.Right := SrcRect.Right;
  if DstRect.Bottom < SrcRect.Bottom then
    DstRect.Bottom := SrcRect.Bottom;
end;

procedure IntersectRect(var DstRect: TRect; const SrcRect: TRect);
begin
  if DstRect.Left < SrcRect.Left then
    DstRect.Left := SrcRect.Left;
  if DstRect.Top < SrcRect.Top then
    DstRect.Top := SrcRect.Top;
  if DstRect.Right > SrcRect.Right then
    DstRect.Right := SrcRect.Right;
  if DstRect.Bottom > SrcRect.Bottom then
    DstRect.Bottom := SrcRect.Bottom;
end;

function OverlappedRect(const Rect1, Rect2: TRect): Boolean;
begin
  Result := (Rect1.Right >= Rect2.Left) and (Rect2.Right >= Rect1.Left) and
            (Rect1.Bottom >= Rect2.Top) and (Rect2.Bottom >= Rect1.Top);
end;

function TransformRgn(Rgn: HRGN; const XForm: TXForm): HRGN;
var
  RgnData: PRgnData;
  RgnDataSize: DWORD;
begin
  Result := 0;
  RgnDataSize := GetRegionData(Rgn, 0, nil);
  if RgnDataSize > 0 then
  begin
    GetMem(RgnData, RgnDataSize);
    try
      GetRegionData(Rgn, RgnDataSize, RgnData);
      Result := ExtCreateRegion(@Xform, RgnDataSize, RgnData^);
    finally
      FreeMem(RgnData);
    end;
  end;
end;

function NormalizeAngle(const Angle: Double): Double;
begin
  Result := Angle;
  while Result > Pi do
    Result := Result - 2 * Pi;
  while Result < -Pi do
    Result := Result + 2 * Pi;
end;

function LineLength(const LinePt1, LinePt2: TPoint): Double;
begin
  Result := Sqrt(Sqr(LinePt2.X - LinePt1.X) + Sqr(LinePt2.Y - LinePt1.Y));
end;

function LineSlopeAngle(const LinePt1, LinePt2: TPoint): Double;
begin
  if LinePt1.X <> LinePt2.X then
    Result := ArcTan2(LinePt2.Y - LinePt1.Y, LinePt2.X - LinePt1.X)
  else if LinePt1.Y > LinePt2.Y then
    Result := -Pi / 2
  else if LinePt1.Y < LinePt2.Y then
    Result := +Pi / 2
  else
    Result := 0;
end;

function DistanceToLine(const LinePt1, LinePt2: TPoint; const QueryPt: TPoint): Double;
var
  Pt: TPoint;
begin
  Pt := NearestPointOnLine(LinePt1, LinePt2, QueryPt);
  Result := LineLength(QueryPt, Pt);
end;

function NextPointOfLine(const LineAngle: Double; const ThisPt: TPoint;
  const DistanceFromThisPt: Double): TPoint;
var
  X, Y, M: Double;
  Angle: Double;
begin
  Angle := NormalizeAngle(LineAngle);
  if Abs(Angle) <> Pi / 2 then
  begin
    M := Tan(LineAngle);
    if Abs(Angle) < Pi / 2 then
      X := ThisPt.X - DistanceFromThisPt / Sqrt(1 + Sqr(M))
    else
      X := ThisPt.X + DistanceFromThisPt / Sqrt(1 + Sqr(M));
    Y := ThisPt.Y + M * (X - ThisPt.X);
    Result.X := Round(X);
    Result.Y := Round(Y);
  end
  else
  begin
    Result.X := ThisPt.X;
    if Angle > 0 then
      Result.Y := ThisPt.Y - Round(DistanceFromThisPt)
    else
      Result.Y := ThisPt.Y + Round(DistanceFromThisPt);
  end;
end;

function NearestPointOnLine(const LinePt1, LinePt2: TPoint; const RefPt: TPoint): TPoint;
var
  LoPt, HiPt: TPoint;
  LoDis, HiDis: Double;
begin
  LoPt := LinePt1;
  HiPt := LinePt2;
  Result.X := (LoPt.X + HiPt.X) div 2;
  Result.Y := (LoPt.Y + HiPt.Y) div 2;
  while ((Result.X <> LoPt.X) or (Result.Y <> LoPt.Y)) and ((Result.X <> HiPt.X) or (Result.Y <> HiPt.Y)) do
  begin
    LoDis := Sqrt(Sqr(RefPt.X - (LoPt.X + Result.X) div 2) + Sqr(RefPt.Y - (LoPt.Y + Result.Y) div 2));
    HiDis := Sqrt(Sqr(RefPt.X - (HiPt.X + Result.X) div 2) + Sqr(RefPt.Y - (HiPt.Y + Result.Y) div 2));
    if LoDis < HiDis then
      HiPt := Result
    else
      LoPt := Result;
    Result.X := (LoPt.X + HiPt.X) div 2;
    Result.Y := (LoPt.Y + HiPt.Y) div 2;
  end;
end;

function IntersectLines(const Line1Pt: TPoint; const Line1Angle: Double;
  const Line2Pt: TPoint; const Line2Angle: Double; out Intersect: TPoint): Boolean;
var
  M1, M2: Double;
  C1, C2: Double;
begin
  Result := True;
  if (Abs(Line1Angle) = Pi / 2) and (Abs(Line2Angle) = Pi / 2) then
    // Lines have identical slope, so they are either parallel or identical
    Result := False
  else if Abs(Line1Angle) = Pi / 2 then
  begin
    M2 := Tan(Line2Angle);
    C2 := Line2Pt.Y - M2 * Line2Pt.X;
    Intersect.X := Line1Pt.X;
    Intersect.Y := Round(M2 * Intersect.X + C2);
  end
  else if Abs(Line2Angle) = Pi / 2 then
  begin
    M1 := Tan(Line1Angle);
    C1 := Line1Pt.Y - M1 * Line1Pt.X;
    Intersect.X := Line2Pt.X;
    Intersect.Y := Round(M1 * Intersect.X + C1);
  end
  else
  begin
    M1 := Tan(Line1Angle);
    M2 := Tan(Line2Angle);
    if M1 = M2 then
      // Lines have identical slope, so they are either parallel or identical
      Result := False
    else
    begin
      C1 := Line1Pt.Y - M1 * Line1Pt.X;
      C2 := Line2Pt.Y - M2 * Line2Pt.X;
      Intersect.X := Round((C1 - C2) / (M2 - M1));
      Intersect.Y := Round((M2 * C1 - M1 * C2) / (M2 - M1));
    end;
  end;
end;

function IntersectLineRect(const LinePt: TPoint; const LineAngle: Double;
  const Rect: TRect): TPoints;
var
  Corners: array[0..3] of TPoint;
begin
  Corners[0].X := Rect.Left;
  Corners[0].Y := Rect.Top;
  Corners[1].X := Rect.Right;
  Corners[1].Y := Rect.Top;
  Corners[2].X := Rect.Right;
  Corners[2].Y := Rect.Bottom;
  Corners[3].X := Rect.Left;
  Corners[3].Y := Rect.Bottom;
  Result := IntersectLinePolygon(LinePt, LineAngle, Corners);
end;

function IntersectLineEllipse(const LinePt: TPoint; const LineAngle: Double;
  const Bounds: TRect): TPoints;
var
  M, C: Double;
  A2, B2, a, b, d: Double;
  Xc, Yc, X, Y: Double;
begin
  SetLength(Result, 0);
  if IsRectEmpty(Bounds) then Exit;
  Xc := (Bounds.Left + Bounds.Right) / 2;
  Yc := (Bounds.Top + Bounds.Bottom) / 2;
  A2 := Sqr((Bounds.Right - Bounds.Left) / 2);
  B2 := Sqr((Bounds.Bottom - Bounds.Top) / 2);
  if Abs(LineAngle) = Pi / 2 then
  begin
    d := 1 - (Sqr(LinePt.X - Xc) / A2);
    if d >= 0 then
    begin
      if d = 0 then
      begin
        SetLength(Result, 1);
        Result[0].X := LinePt.X;
        Result[0].Y := Round(Yc);
      end
      else
      begin
        C := Sqrt(B2) * Sqrt(d);
        SetLength(Result, 2);
        Result[0].X := LinePt.X;
        Result[0].Y := Round(Yc - C);
        Result[1].X := LinePt.X;
        Result[1].Y := Round(Yc + C);
      end;
    end;
  end
  else
  begin
    M := Tan(LineAngle);
    C := LinePt.Y - M * LinePt.X;
    a := (B2 + A2 * Sqr(M));
    b := (A2 * M * (C - Yc)) - B2 * Xc;
    d := Sqr(b) - a * (B2 * Sqr(Xc) + A2 * Sqr(C - Yc) - A2 * B2);
    if (d >= 0) and (a <> 0) then
    begin
      if d = 0 then
      begin
        SetLength(Result, 1);
        X := -b / a;
        Y := M * X + C;
        Result[0].X := Round(X);
        Result[0].Y := Round(Y);
      end
      else
      begin
        SetLength(Result, 2);
        X := (-b - Sqrt(d)) / a;
        Y := M * X + C;
        Result[0].X := Round(X);
        Result[0].Y := Round(Y);
        X := (-b + Sqrt(d)) / a;
        Y := M * X + C;
        Result[1].X := Round(X);
        Result[1].Y := Round(Y);
      end;
    end;
  end;
end;

function IntersectLineRoundRect(const LinePt: TPoint; const LineAngle: Double;
  const Bounds: TRect; CW, CH: Integer): TPoints;
var
  I: Integer;
  CornerBounds: TRect;
  CornerIntersects: TPoints;
  W, H, Xc, Yc, dX, dY: Integer;
begin
  Result := IntersectLineRect(LinePt, LineAngle, Bounds);
  if Length(Result) > 0 then
  begin
    W := Bounds.Right - Bounds.Left;
    H := Bounds.Bottom - Bounds.Top;
    Xc := (Bounds.Left + Bounds.Right) div 2;
    Yc := (Bounds.Top + Bounds.Bottom) div 2;
    for I := 0 to Length(Result) - 1 do
    begin
      dX := Result[I].X - Xc;
      dY := Result[I].Y - Yc;
      if ((W div 2) - (Abs(dX)) < (CW div 2)) and (((H div 2) - Abs(dY)) < (CH div 2)) then
      begin
        SetRect(CornerBounds, Bounds.Left, Bounds.Top, Bounds.Left + CW, Bounds.Top + CH);
        if dX > 0 then OffsetRect(CornerBounds, W - CW, 0);
        if dY > 0 then OffsetRect(CornerBounds, 0, H - CH);
        CornerIntersects := IntersectLineEllipse(LinePt, LineAngle, CornerBounds);
        try
          if Length(CornerIntersects) = 2 then
            if dX < 0 then
              Result[I] := CornerIntersects[0]
            else
              Result[I] := CornerIntersects[1];
        finally
          SetLength(CornerIntersects, 0);
        end;
      end;
    end;
  end;
end;

function IntersectLinePolygon(const LinePt: TPoint; const LineAngle: Double;
  const Vertices: array of TPoint): TPoints;
var
  I: Integer;
  V1, V2: Integer;
  EdgeAngle: Double;
  Intersect: TPoint;
begin
  SetLength(Result, 0);
  for I := Low(Vertices) to High(Vertices) do
  begin
    V1 := I;
    V2 := Succ(I) mod Length(Vertices);
    EdgeAngle := LineSlopeAngle(Vertices[V1], Vertices[V2]);
    if IntersectLines(LinePt, LineAngle, Vertices[V1], EdgeAngle, Intersect) and
       IsBetween(Intersect.X, Vertices[V1].X, Vertices[V2].X) and
       IsBetween(Intersect.Y, Vertices[V1].Y, Vertices[V2].Y) then
    begin
      SetLength(Result, Length(Result) + 1);
      Result[Length(Result) - 1] := Intersect;
    end;
  end;
end;

function IntersectLinePolyline(const LinePt: TPoint; const LineAngle: Double;
  const Vertices: array of TPoint): TPoints;
var
  I: Integer;
  V1, V2: Integer;
  EdgeAngle: Double;
  Intersect: TPoint;
begin
  SetLength(Result, 0);
  for I := Low(Vertices) to Pred(High(Vertices)) do
  begin
    V1 := I;
    V2 := Succ(I);
    EdgeAngle := LineSlopeAngle(Vertices[V1], Vertices[V2]);
    if IntersectLines(LinePt, LineAngle, Vertices[V1], EdgeAngle, Intersect) and
       IsBetween(Intersect.X, Vertices[V1].X, Vertices[V2].X) and
       IsBetween(Intersect.Y, Vertices[V1].Y, Vertices[V2].Y) then
    begin
      SetLength(Result, Length(Result) + 1);
      Result[Length(Result) - 1] := Intersect;
    end;
  end;
end;

{ TGraphScrollBar }

constructor TGraphScrollBar.Create(AOwner: TSimpleGraph; AKind: TScrollBarKind);
begin
  inherited Create;
  fOwner := AOwner;
  fKind := AKind;
  fPageIncrement := 80;
  fIncrement := fPageIncrement div 10;
  fVisible := True;
  fDelay := 10;
  fLineDiv := 4;
  fPageDiv := 12;
  fColor := clBtnHighlight;
  fParentColor := True;
  fUpdateNeeded := True;
  fStyle := ssRegular;
end;

function TGraphScrollBar.IsIncrementStored: Boolean;
begin
  Result := not Smooth;
end;

procedure TGraphScrollBar.Assign(Source: TPersistent);
begin
  if Source is TGraphScrollBar then
  begin
    DoSetRange(TGraphScrollBar(Source).Range);
    Visible := TGraphScrollBar(Source).Visible;
    Position := TGraphScrollBar(Source).Position;
    ButtonSize := TGraphScrollBar(Source).ButtonSize;
    Color := TGraphScrollBar(Source).Color;
    ParentColor := TGraphScrollBar(Source).ParentColor;
    Increment := TGraphScrollBar(Source).Increment;
    Margin := TGraphScrollBar(Source).Margin;
    Smooth := TGraphScrollBar(Source).Smooth;
    Size := TGraphScrollBar(Source).Size;
    Style := TGraphScrollBar(Source).Style;
    ThumbSize := TGraphScrollBar(Source).ThumbSize;
    Tracking := TGraphScrollBar(Source).Tracking;
  end
  else
    inherited Assign(Source);
end;

procedure TGraphScrollBar.ChangeBiDiPosition;
begin
  if Kind = sbHorizontal then
    if IsScrollBarVisible then
      if not Owner.UseRightToLeftScrollBar then
        Position := 0
      else
        Position := Range;
end;

procedure TGraphScrollBar.CalcAutoRange;
var
  NewRange, AlignMargin: Integer;

  procedure ProcessHorz(Control: TControl);
  begin
    if Control.Visible then
      case Control.Align of
        alLeft, alNone:
          if (Control.Align = alLeft) or (Control.Anchors * [akLeft, akRight] = [akLeft]) then
            NewRange := Max(NewRange, Position + Control.Left + Control.Width);
        alRight: Inc(AlignMargin, Control.Width);
      end;
  end;

  procedure ProcessVert(Control: TControl);
  begin
    if Control.Visible then
      case Control.Align of
        alTop, alNone:
          if (Control.Align = alTop) or (Control.Anchors * [akTop, akBottom] = [akTop]) then
            NewRange := Max(NewRange, Position + Control.Top + Control.Height);
        alBottom: Inc(AlignMargin, Control.Height);
      end;
  end;

var
  I: Integer;
begin
  case Kind of
    sbHorizontal:
      if not Owner.FixedScrollBars then
      begin
        NewRange := 1;
        if Owner.ValidMarkedArea then
          with Owner.MarkedArea do
            if NewRange < Right then
              NewRange := Right;
        with Owner.GraphBounds do
          if NewRange < Right then
            NewRange := Right;
      end
      else
        NewRange := Owner.GraphConstraints.MaxRight;
    sbVertical:
      if not Owner.FixedScrollBars then
      begin
        NewRange := 1;
        if Owner.ValidMarkedArea then
          with Owner.MarkedArea do
            if NewRange < Bottom then
              NewRange := Bottom;
        with Owner.GraphBounds do
          if NewRange < Bottom then
            NewRange := Bottom;
      end
      else
        NewRange := Owner.GraphConstraints.MaxBottom;
  else
    Exit;
  end;
  AlignMargin := 0;
  for I := 0 to Owner.ControlCount - 1 do
    case Kind of
      sbHorizontal:
        ProcessHorz(Owner.Controls[I]);
      sbVertical:
        ProcessVert(Owner.Controls[I]);
    end;
  DoSetRange(NewRange + AlignMargin + Margin);
end;

function TGraphScrollBar.IsScrollBarVisible: Boolean;
var
  Style: Longint;
begin
  if Kind = sbVertical then
    Style := WS_VSCROLL
  else
    Style := WS_HSCROLL;
  Result := Visible and ((GetWindowLong(Owner.Handle, GWL_STYLE) and Style) <> 0);
end;

function TGraphScrollBar.ControlSize(ControlSB, AssumeSB: Boolean): Integer;
var
  BorderAdjust: Integer;

  function ScrollBarVisible(Code: Word): Boolean;
  var
    Style: Longint;
  begin
    Style := WS_HSCROLL;
    if Code = SB_VERT then Style := WS_VSCROLL;
    Result := GetWindowLong(Owner.Handle, GWL_STYLE) and Style <> 0;
  end;

  function Adjustment(Code, Metric: Word): Integer;
  begin
    Result := 0;
    if not ControlSB then
      if AssumeSB and not ScrollBarVisible(Code) then
        Result := -(GetSystemMetrics(Metric) - BorderAdjust)
      else if not AssumeSB and ScrollBarVisible(Code) then
        Result := GetSystemMetrics(Metric) - BorderAdjust;
  end;

begin
  BorderAdjust := Integer((GetWindowLong(Owner.Handle, GWL_STYLE) and
    (WS_BORDER or WS_THICKFRAME)) <> 0);
  if Kind = sbVertical then
    Result := Owner.ClientHeight + Adjustment(SB_HORZ, SM_CXHSCROLL)
  else
    Result := Owner.ClientWidth + Adjustment(SB_VERT, SM_CYVSCROLL);
end;

function TGraphScrollBar.GetScrollPos: Integer;
begin
  Result := 0;
  if Visible then Result := Position;
end;

function TGraphScrollBar.NeedsScrollBarVisible: Boolean;
begin
  Result := fRange > ControlSize(False, False);
end;

procedure TGraphScrollBar.ScrollMessage(var Msg: TWMScroll);
var
  Incr, FinalIncr, Count: Integer;
  CurrentTime, StartTime, ElapsedTime: Longint;

  function GetRealScrollPosition: Integer;
  var
    SI: TScrollInfo;
    Code: Integer;
  begin
    SI.cbSize := SizeOf(TScrollInfo);
    SI.fMask := SIF_TRACKPOS;
    Code := SB_HORZ;
    if fKind = sbVertical then Code := SB_VERT;
    Result := Msg.Pos;
    if FlatSB_GetScrollInfo(Owner.Handle, Code, SI) then
      Result := SI.nTrackPos;
  end;

begin
  with Msg do
  begin
    if fSmooth and (ScrollCode in [SB_LINEUP, SB_LINEDOWN, SB_PAGEUP, SB_PAGEDOWN]) then
    begin
      case ScrollCode of
        SB_LINEUP, SB_LINEDOWN:
          begin
            Incr := fIncrement div fLineDiv;
            FinalIncr := fIncrement mod fLineDiv;
            Count := fLineDiv;
          end;
        SB_PAGEUP, SB_PAGEDOWN:
          begin
            Incr := FPageIncrement;
            FinalIncr := Incr mod fPageDiv;
            Incr := Incr div fPageDiv;
            Count := fPageDiv;
          end;
      else
        Count := 0;
        Incr := 0;
        FinalIncr := 0;
      end;
      CurrentTime := 0;
      while Count > 0 do
      begin
        StartTime := GetTickCount;
        ElapsedTime := StartTime - CurrentTime;
        if ElapsedTime < fDelay then
          Sleep(fDelay - ElapsedTime);
        CurrentTime := StartTime;
        case ScrollCode of
          SB_LINEUP: SetPosition(fPosition - Incr);
          SB_LINEDOWN: SetPosition(fPosition + Incr);
          SB_PAGEUP: SetPosition(fPosition - Incr);
          SB_PAGEDOWN: SetPosition(fPosition + Incr);
        end;
        Owner.Update;
        Dec(Count);
      end;
      if FinalIncr > 0 then
      begin
        case ScrollCode of
          SB_LINEUP: SetPosition(fPosition - FinalIncr);
          SB_LINEDOWN: SetPosition(fPosition + FinalIncr);
          SB_PAGEUP: SetPosition(fPosition - FinalIncr);
          SB_PAGEDOWN: SetPosition(fPosition + FinalIncr);
        end;
      end;
    end
    else
      case ScrollCode of
        SB_LINEUP: SetPosition(fPosition - fIncrement);
        SB_LINEDOWN: SetPosition(fPosition + fIncrement);
        SB_PAGEUP: SetPosition(fPosition - ControlSize(True, False));
        SB_PAGEDOWN: SetPosition(fPosition + ControlSize(True, False));
        SB_THUMBPOSITION:
          if fCalcRange > 32767 then
            SetPosition(GetRealScrollPosition)
          else
            SetPosition(Pos);
        SB_THUMBTRACK:
          if Tracking then
            if fCalcRange > 32767 then
              SetPosition(GetRealScrollPosition)
            else
              SetPosition(Pos);
        SB_TOP: SetPosition(0);
        SB_BOTTOM: SetPosition(fCalcRange);
        SB_ENDSCROLL: begin end;
      end;
  end;
end;

procedure TGraphScrollBar.SetButtonSize(Value: Integer);
const
  SysConsts: array[TScrollBarKind] of Integer = (SM_CXHSCROLL, SM_CXVSCROLL);
var
  NewValue: Integer;
begin
  if Value <> ButtonSize then
  begin
    NewValue := Value;
    if NewValue = 0 then
      Value := GetSystemMetrics(SysConsts[Kind]);
    fButtonSize := Value;
    fUpdateNeeded := True;
    Owner.UpdateScrollBars;
    if NewValue = 0 then
      fButtonSize := 0;
  end;
end;

procedure TGraphScrollBar.SetColor(Value: TColor);
begin
  if Value <> Color then
  begin
    fColor := Value;
    fParentColor := False;
    fUpdateNeeded := True;
    Owner.UpdateScrollBars;
  end;
end;

procedure TGraphScrollBar.SetParentColor(Value: Boolean);
begin
  if ParentColor <> Value then
  begin
    fParentColor := Value;
    if Value then Color := clBtnHighlight;
  end;
end;

procedure TGraphScrollBar.SetPosition(Value: Integer);
var
  Code: Word;
  Form: TCustomForm;
  OldPos: Integer;
begin
  if csReading in Owner.ComponentState then
    fPosition := Value
  else
  begin
    if Value > fCalcRange then
      Value := fCalcRange
    else if Value < 0 then
      Value := 0;
    if Kind = sbHorizontal then
      Code := SB_HORZ
    else
      Code := SB_VERT;
    if Value <> FPosition then
    begin
      OldPos := FPosition;
      fPosition := Value;
      if Kind = sbHorizontal then
        Owner.ScrollBy(OldPos - Value, 0)
      else
        Owner.ScrollBy(0, OldPos - Value);
      if csDesigning in Owner.ComponentState then
      begin
        Form := GetParentForm(Owner);
        if Assigned(Form) and Assigned(Form.Designer) then Form.Designer.Modified;
      end;
    end;
    if FlatSB_GetScrollPos(Owner.Handle, Code) <> FPosition then
      FlatSB_SetScrollPos(Owner.Handle, Code, FPosition, True);
  end;
end;

procedure TGraphScrollBar.SetSize(Value: Integer);
const
  SysConsts: array[TScrollBarKind] of Integer = (SM_CYHSCROLL, SM_CYVSCROLL);
var
  NewValue: Integer;
begin
  if Value <> Size then
  begin
    NewValue := Value;
    if NewValue = 0 then
      Value := GetSystemMetrics(SysConsts[Kind]);
    fSize := Value;
    fUpdateNeeded := True;
    Owner.UpdateScrollBars;
    if NewValue = 0 then
      fSize := 0;
  end;
end;

procedure TGraphScrollBar.SetStyle(Value: TScrollBarStyle);
begin
  if Style <> Value then
  begin
    fStyle := Value;
    fUpdateNeeded := True;
    Owner.UpdateScrollBars;
  end;
end;

procedure TGraphScrollBar.SetThumbSize(Value: Integer);
begin
  if ThumbSize <> Value then
  begin
    fThumbSize := Value;
    fUpdateNeeded := True;
    Owner.UpdateScrollBars;
  end;
end;

procedure TGraphScrollBar.DoSetRange(Value: Integer);
var
  NewRange: Integer;
begin
  if Value <= 0 then
    NewRange := 0
  else
    NewRange := MulDiv(Value, Owner.Zoom, 100);
  if fRange <> NewRange then
  begin
    fRange := NewRange;
    Owner.UpdateScrollBars;
  end;
end;

procedure TGraphScrollBar.SetVisible(Value: Boolean);
begin
  if fVisible <> Value then
  begin
    fVisible := Value;
    Owner.UpdateScrollBars;
  end;
end;

procedure TGraphScrollBar.Update(ControlSB, AssumeSB: Boolean);
type
  TPropKind = (pkStyle, pkButtonSize, pkThumbSize, pkSize, pkBkColor);
const
  Kinds: array[TScrollBarKind] of Integer = (WSB_PROP_HSTYLE, WSB_PROP_VSTYLE);
  Styles: array[TScrollBarStyle] of Integer = (FSB_REGULAR_MODE,
    FSB_ENCARTA_MODE, FSB_FLAT_MODE);
  Props: array[TScrollBarKind, TPropKind] of Integer = (
    { Horizontal }
    (WSB_PROP_HSTYLE, WSB_PROP_CXHSCROLL, WSB_PROP_CXHTHUMB, WSB_PROP_CYHSCROLL,
     WSB_PROP_HBKGCOLOR),
    { Vertical }
    (WSB_PROP_VSTYLE, WSB_PROP_CYVSCROLL, WSB_PROP_CYVTHUMB, WSB_PROP_CXVSCROLL,
     WSB_PROP_VBKGCOLOR));
var
  Code: Word;
  ScrollInfo: TScrollInfo;

  procedure UpdateScrollProperties(Redraw: Boolean);
  begin
    FlatSB_SetScrollProp(Owner.Handle, Props[Kind, pkStyle], Styles[Style], Redraw);
    if ButtonSize > 0 then
      FlatSB_SetScrollProp(Owner.Handle, Props[Kind, pkButtonSize], ButtonSize, False);
    if ThumbSize > 0 then
      FlatSB_SetScrollProp(Owner.Handle, Props[Kind, pkThumbSize], ThumbSize, False);
    if Size > 0 then
      FlatSB_SetScrollProp(Owner.Handle, Props[Kind, pkSize], Size, False);
    FlatSB_SetScrollProp(Owner.Handle, Props[Kind, pkBkColor],
      ColorToRGB(Color), False);
  end;

begin
  fCalcRange := 0;
  if Kind = sbVertical then
    Code := SB_VERT
  else
    Code := SB_HORZ;
  if Visible then
  begin
    fCalcRange := Range - ControlSize(ControlSB, AssumeSB);
    if fCalcRange < 0 then fCalcRange := 0;
  end;
  ScrollInfo.cbSize := SizeOf(ScrollInfo);
  ScrollInfo.fMask := SIF_ALL;
  ScrollInfo.nMin := 0;
  if fCalcRange > 0 then
    ScrollInfo.nMax := Range
  else
    ScrollInfo.nMax := 0;
  ScrollInfo.nPage := ControlSize(ControlSB, AssumeSB) + 1;
  ScrollInfo.nPos := fPosition;
  ScrollInfo.nTrackPos := fPosition;
  UpdateScrollProperties(fUpdateNeeded);
  fUpdateNeeded := False;
  FlatSB_SetScrollInfo(Owner.Handle, Code, ScrollInfo, True);
  SetPosition(fPosition);
  fPageIncrement := (ControlSize(True, False) * 9) div 10;
  if Smooth then fIncrement := fPageIncrement div 10;
end;

{ TMemoryHandleStream }

constructor TMemoryHandleStream.Create(MemHandle: THandle);
begin
  fHandle := MemHandle;
  if fHandle <> 0 then Size := GlobalSize(fHandle);
end;

destructor TMemoryHandleStream.Destroy;
begin
  if not fReleaseHandle and (fHandle <> 0) then
  begin
    GlobalUnlock(fHandle);
    if Capacity > Size then
      GlobalReAlloc(fHandle, Size, GMEM_MOVEABLE);
    fHandle := 0;
  end;
  inherited Destroy;
end;

function TMemoryHandleStream.Realloc(var NewCapacity: Integer): Pointer;
const
  MemoryDelta = $2000; { Must be a power of 2 }
begin
  if (NewCapacity > 0) and (NewCapacity <> Size) then
    NewCapacity := (NewCapacity + (MemoryDelta - 1)) and not (MemoryDelta - 1);
  Result := Memory;
  if NewCapacity <> Capacity then
  begin
    if NewCapacity = 0 then
    begin
      if fHandle <> 0 then
      begin
        GlobalUnlock(fHandle);
        GlobalFree(fHandle);
        fHandle := 0;
      end;
      Result := nil;
    end
    else
    begin
      if fHandle = 0 then
        fHandle := GlobalAlloc(GMEM_MOVEABLE, NewCapacity)
      else
      begin
        GlobalUnlock(fHandle);
        fHandle := GlobalReAlloc(fHandle, NewCapacity, GMEM_MOVEABLE);
      end;
      Result := GlobalLock(fHandle);
    end;
  end;
end;

{ TCanvasRecall }

constructor TCanvasRecall.Create(AReference: TCanvas);
begin
  fReference := AReference;
  fFont := TFont.Create;
  fPen := TPen.Create;
  fBrush := TBrush.Create;
  Store;
end;

destructor TCanvasRecall.Destroy;
begin
  Retrieve;
  fBrush.Free;
  fPen.Free;
  fFont.Free;
  inherited Destroy;
end;

procedure TCanvasRecall.Store;
begin
  if Assigned(fReference) then
  begin
    fFont.Assign(fReference.Font);
    fPen.Assign(fReference.Pen);
    fBrush.Assign(fReference.Brush);
    fCopyMode := fReference.CopyMode;
    fTextFlags := fReference.TextFlags;
  end;
end;

procedure TCanvasRecall.Retrieve;
begin
  if Assigned(fReference) then
  begin
    fReference.Font.Assign(fFont);
    fReference.Pen.Assign(fPen);
    fReference.Brush.Assign(fBrush);
    fReference.CopyMode := fCopyMode;
    fReference.TextFlags := fTextFlags;
  end;
end;

procedure TCanvasRecall.SetReference(Value: TCanvas);
begin
  if fReference <> Value then
  begin
    Retrieve;
    fReference := Value;
    Store;
  end;
end;

{ TCompatibleCanvas. }

constructor TCompatibleCanvas.Create;
begin
  inherited Create;
  Handle := CreateCompatibleDC(0);
end;

destructor TCompatibleCanvas.Destroy;
var
  DC: HDC;
begin
  DC := Handle;
  Handle := 0;
  if DC <> 0 then
    DeleteObject(DC);
  inherited Destroy;
end;

{ TGraphObjectList }

destructor TGraphObjectList.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TGraphObjectList.SetCapacity(Value: Integer);
begin
  if fCapacity <> Value then
  begin
    fCapacity := Value;
    while fCapacity < fCount do
      Delete(fCount - 1);
    SetLength(fItems, fCapacity);
  end;
end;

function TGraphObjectList.GetItems(Index: Integer): TGraphObject;
begin
  if (Index < 0) or (Index >= fCount) then
    raise EListError.CreateFmt(SListIndexError, [Index]);
  Result := fItems[Index];
end;

procedure TGraphObjectList.Grow;
begin
  if fCount < 64 then
    SetCapacity(fCapacity + 16)
  else
    SetCapacity(fCapacity + 8);
end;

function TGraphObjectList.Replace(OldItem, NewItem: TGraphObject): Integer;
begin
  Result := IndexOf(OldItem);
  if Result >= 0 then
    fItems[Result] := NewItem;
end;

procedure TGraphObjectList.NotifyAction(Item: TGraphObject;
  Action: TGraphObjectListAction);
begin
  if Assigned(Item) and Assigned(OnChange) then
    OnChange(Self, Item, Action);
end;

procedure TGraphObjectList.AdjustDeleted(Index: Integer;
  var EnumState: TListEnumState);
begin
  if (EnumState.Dir <> 0) and ((Index < EnumState.Current) or
     ((EnumState.Dir = +1) and (Index = EnumState.Current)))
  then
    Dec(EnumState.Current);
end;

procedure TGraphObjectList.Clear;
begin
  SetCapacity(0);
  EnumStack := nil;
end;

procedure TGraphObjectList.Assign(Source: TPersistent);
var
  I: Integer;
begin
  if Source is TGraphObjectList then
  begin
    Clear;
    Capacity := TGraphObjectList(Source).Count;
    for I := 0 to TGraphObjectList(Source).Count - 1 do
      Add(TGraphObjectList(Source).Items[I]);
  end
  else
    inherited Assign(Source);
end;

function TGraphObjectList.IndexOf(Item: TGraphObject): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := Count - 1 downto 0 do
    if fItems[I] = Item then
    begin
      Result := I;
      Exit;
    end;
end;

function TGraphObjectList.Add(Item: TGraphObject): Integer;
begin
  if Count = Capacity then
    Grow;
  Result := fCount;
  fItems[Result] := Item;
  Inc(fCount);
  NotifyAction(Item, glAdded);
end;

procedure TGraphObjectList.Insert(Index: Integer; Item: TGraphObject);
begin
  if (Index < 0) or (Index > fCount) then
    raise EListError.CreateFmt(SListIndexError, [Index]);
  if Count = Capacity then
    Grow;
  if Index < fCount then
    System.Move(fItems[Index], fItems[Index + 1], (fCount - Index) * SizeOf(TGraphObject));
  fItems[Index] := Item;
  Inc(fCount);
  NotifyAction(Item, glAdded);
end;

procedure TGraphObjectList.Delete(Index: Integer);
var
  Item: TGraphObject;
  I: Integer;
begin
  if (Index < 0) or (Index >= fCount) then
    raise EListError.CreateFmt(SListIndexError, [Index]);
  Item := fItems[Index];
  Dec(fCount);
  if Index < fCount then
    System.Move(fItems[Index + 1], fItems[Index], (fCount - Index) * SizeOf(TGraphObject));
  AdjustDeleted(Index, Enum);
  for I := 0 to EnumStackPos - 1 do
    AdjustDeleted(Index, EnumStack[I]);
  NotifyAction(Item, glRemoved);
end;

function TGraphObjectList.Remove(Item: TGraphObject): Integer;
begin
  Result := IndexOf(Item);
  if Result >= 0 then
    Delete(Result);
end;

procedure TGraphObjectList.Move(CurIndex, NewIndex: Integer);
var
  Item: TGraphObject;
begin
  if CurIndex <> NewIndex then
  begin
    if (CurIndex < 0) or (CurIndex >= fCount) then
      raise EListError.CreateFmt(SListIndexError, [CurIndex]);
    if (NewIndex < 0) or (NewIndex >= fCount) then
      raise EListError.CreateFmt(SListIndexError, [NewIndex]);
    Item := fItems[CurIndex];
    fItems[CurIndex] := nil;
    Delete(CurIndex);
    Insert(NewIndex, nil);
    fItems[NewIndex] := Item;
    NotifyAction(Item, glReordered);
  end;
end;

function TGraphObjectList.First: TGraphObject;
begin
  if fCount > 0 then
  begin
    Enum.Dir := +1;
    Enum.Current := 0;
    Result := fItems[0]
  end
  else
  begin
    Enum.Dir := 0;
    Result := nil;
  end;
end;

function TGraphObjectList.Prior: TGraphObject;
begin
  Dec(Enum.Current);
  if (Enum.Current >= 0) and (Enum.Current < fCount) then
    Result := fItems[Enum.Current]
  else if Enum.Dir <> 0 then
  begin
    Enum.Dir := 0;
    Result := nil;
  end
  else
    raise EListError.Create(SListEnumerateError);
end;

function TGraphObjectList.Next: TGraphObject;
begin
  Inc(Enum.Current);
  if (Enum.Current >= 0) and (Enum.Current < fCount) then
    Result := fItems[Enum.Current]
  else if Enum.Dir <> 0 then
  begin
    Enum.Dir := 0;
    Result := nil;
  end
  else
    raise EListError.Create(SListEnumerateError);
end;

function TGraphObjectList.Last: TGraphObject;
begin
  if fCount > 0 then
  begin
    Enum.Dir := -1;
    Enum.Current := fCount - 1;
    Result := fItems[fCount - 1]
  end
  else
  begin
    Enum.Dir := 0;
    Result := nil;
  end;
end;

function TGraphObjectList.Push: Boolean;
begin
  Result := False;
  if Enum.Dir <> 0 then
  begin
    if EnumStackPos = Length(EnumStack) then
      SetLength(EnumStack, EnumStackPos + 1);
    EnumStack[EnumStackPos] := Enum;
    Inc(EnumStackPos);
    Result := True;
  end;
end;

function TGraphObjectList.Pop: Boolean;
begin
  Result := False;
  if EnumStackPos > 0 then
  begin
    Dec(EnumStackPos);
    Enum := EnumStack[EnumStackPos];
    Result := True;
  end;
end;

{ TGraphObject }

constructor TGraphObject.CreateAsReplacement(AGraphObject: TGraphObject);
var
  I: Integer;
  Stream: TMemoryStream;
begin
  Include(AGraphObject.fStates, osConverting);
  Include(fStates, osConverting);
  Create(AGraphObject.Owner);
  Stream := TMemoryStream.Create;
  try
    AGraphObject.SaveToStream(Stream);
    Stream.Seek(0, soFromBeginning);
    LoadFromStream(Stream);
  finally
    Stream.Free;
  end;
  Data := AGraphObject.Data;
  LinkInputList.Assign(AGraphObject.LinkInputList);
  LinkOutputList.Assign(AGraphObject.LinkOutputList);
  DependentList.Assign(AGraphObject.DependentList);
  Owner.Objects.Replace(AGraphObject, Self);
  Owner.SelectedObjects.Replace(AGraphObject, Self);
  for I := Owner.Objects.Count - 1 downto 0 do
    Owner.Objects[I].ReplaceObject(AGraphObject, Self);
end;

constructor TGraphObject.CreateFromStream(AOwner: TSimpleGraph; AStream: TStream);
begin
  Include(fStates, osLoading);
  Create(AOwner);
  LoadFromStream(AStream);
end;

constructor TGraphObject.Create(AOwner: TSimpleGraph);
begin
  Include(fStates, osCreating);
  fOwner := AOwner;
  fVisible := True;
  fParentFont := True;
  fFont := TFont.Create;
  fFont.Assign(Owner.Font);
  fFont.OnChange := StyleChanged;
  fBrush := TBrush.Create;
  fBrush.OnChange := StyleChanged;
  fPen := TPen.Create;
  fPen.OnChange := StyleChanged;
  fDependentList := TGraphObjectList.Create;
  fDependentList.OnChange := ListChanged;
  fLinkInputList := TGraphObjectList.Create;
  fLinkInputList.OnChange := ListChanged;
  fLinkOutputList := TGraphObjectList.Create;
  fLinkOutputList.OnChange := ListChanged;
  fOptions := [goLinkable, goSelectable, goShowCaption];
  fVisualRectFlags := [gcPlacement];
end;

destructor TGraphObject.Destroy;
begin
  fPen.Free;
  fBrush.Free;
  fFont.Free;
  fLinkInputList.Free;
  fLinkOutputList.Free;
  fDependentList.Free;
  inherited Destroy;
end;

procedure TGraphObject.AfterConstruction;
begin
  inherited AfterConstruction;
  if osConverting in States then
  begin
    Exclude(fStates, osConverting);
    Exclude(fStates, osCreating);
    Initialize;
    Changed([gcView, gcData, gcPlacement]);
  end
  else
  begin
    if not (osLoading in States) then
    begin
      fID := Owner.CreateUniqueID(Self);
      Owner.DoObjectInitInstance(Self);
    end;
    Exclude(fStates, osCreating);
    Initialize;
    Owner.Objects.Add(Self);
    //showmessage('TGraphObject.AfterConstruction: objects.add');
  end;
end;

procedure TGraphObject.BeforeDestruction;
begin
  if not (osDestroying in States) then
  begin
    Include(fStates, osDestroying);
    if not (osConverting in States) then
    begin
      Owner.Objects.Remove(Self);
      NotifyDependents(gdcRemoved);
    end;
  end;
  inherited BeforeDestruction;
end;

function TGraphObject.GetOwner: TPersistent;
begin
  Result := Owner;
end;

procedure TGraphObject.Initialize;
begin
  if not (osLoading in States) then
    LookupDependencies;
  UpdateTextPlacement(True, 0, 0);
  QueryVisualRect(fVisualRect);
  NotifyDependents(gdcChanged);
end;

procedure TGraphObject.Loaded;
begin
  Exclude(fStates, osLoading);
  LookupDependencies;
end;

procedure TGraphObject.ReplaceID(OldID, NewID: DWORD);
begin
  if ID = OldID then fID := NewID;
end;

procedure TGraphObject.ReplaceObject(OldObject, NewObject: TGraphObject);
begin
  repeat until DependentList.Replace(OldObject, NewObject) < 0;
  repeat until LinkInputList.Replace(OldObject, NewObject) < 0;
  repeat until LinkOutputList.Replace(OldObject, NewObject) < 0;
end;

procedure TGraphObject.UpdateDependencyTo(GraphObject: TGraphObject;
  Flag: TGraphDependencyChangeFlag);
begin
end;

procedure TGraphObject.LookupDependencies;
begin
end;

procedure TGraphObject.UpdateDependencies;
begin
end;

procedure TGraphObject.NotifyDependents(Flag: TGraphDependencyChangeFlag);
var
  DependentObject: TGraphObject;
begin
  DependentObject := DependentList.First;
  while Assigned(DependentObject) do
  begin
    DependentList.Push;
    try
      DependentObject.UpdateDependencyTo(Self, Flag);
    finally
      DependentList.Pop;
    end;
    DependentObject := DependentList.Next;
  end;
end;

function TGraphObject.UpdateTextPlacement(Recalc: Boolean; dX, dY: Integer): Boolean;
begin
  Result := False;
end;

procedure TGraphObject.Changed(Flags: TGraphChangeFlags);
var
  NewVisualRect: TRect;
begin
  if not IsUpdateLocked then
  begin
    if gcDependency in Flags then
      UpdateDependencies;
    if (gcText in Flags) and ((Text <> '') or (TextToShow <> '')) then
      UpdateTextPlacement(True, 0, 0);
    if gcPlacement in Flags then
      NotifyDependents(gdcChanged);
    if (gcView in Flags) and ((Flags * VisualRectFlags) <> []) then
    begin
      QueryVisualRect(NewVisualRect);
      if not EqualRect(NewVisualRect, VisualRect) then
      begin
        Include(Flags, gcPlacement);
        if gcView in Flags then
          Invalidate;
        fVisualRect := NewVisualRect;
      end;
    end;
    if (gcData in Flags) or (gcPlacement in Flags) then
      Owner.DoObjectChange(Self);
    Owner.ObjectChanged(Self, Flags);
  end
  else
    PendingChanges := PendingChanges + Flags;
end;

procedure TGraphObject.BoundsChanged(dX, dY, dCX, dCY: Integer);
var
  Shifted: Boolean;
  SavedVisualRectFlags: TGraphChangeFlags;
begin
  Shifted := (dCX = 0) and (dCY = 0);
  if Text <> '' then
    UpdateTextPlacement(not Shifted, dX, dY);
  SavedVisualRectFlags := VisualRectFlags;
  try
    if Shifted then
    begin
      Invalidate;
      OffsetRect(fVisualRect, dX, dY);
      VisualRectFlags := VisualRectFlags - [gcData, gcPlacement];
    end;
    Changed([gcView, gcData, gcPlacement]);
  finally
    VisualRectFlags := SavedVisualRectFlags;
  end;
end;

procedure TGraphObject.DependentChanged(GraphObject: TGraphObject;
  Action: TGraphObjectListAction);
begin
end;

procedure TGraphObject.LinkInputChanged(GraphObject: TGraphObject;
  Action: TGraphObjectListAction);
begin
  case Action of
    glAdded: DependentList.Add(GraphObject);
    glRemoved: DependentList.Remove(GraphObject);
  end;
end;

procedure TGraphObject.LinkOutputChanged(GraphObject: TGraphObject;
  Action: TGraphObjectListAction);
begin
  case Action of
    glAdded: DependentList.Add(GraphObject);
    glRemoved: DependentList.Remove(GraphObject);
  end;
end;

procedure TGraphObject.ParentFontChanged;
begin
  if ParentFont then
  begin
    Font.OnChange := nil;
    try
      Font.Assign(Owner.Font);
    finally
      Font.OnChange := StyleChanged;
    end;
    Changed([gcView, gcText]);
  end;
end;

function TGraphObject.QueryCursor(HT: DWORD): TCursor;
begin
  Result := Owner.Cursor;
end;

function TGraphObject.QueryMobility(HT: DWORD): TObjectSides; 
begin
  Result := [];
end;

function TGraphObject.QueryHitTest(const Pt: TPoint): DWORD;
begin
  Result := GHT_NOWHERE;
end;

function TGraphObject.OffsetHitTest(HT: DWORD; dX, dY: Integer): Boolean;
begin
  Result := False;
end;

procedure TGraphObject.SnapHitTestOffset(HT: DWORD; var dX, dY: Integer);
begin
end;

procedure TGraphObject.MouseDown(Button: TMouseButton; Shift: TShiftState; const Pt: TPoint);
var
  HT: DWORD;
begin
  if Dragging then
    EndDrag(True);
  if Selected and (ssShift in Shift) then
    Selected := False
  else if not Selected and (goSelectable in Options) then
  begin
    if not (ssShift in Shift) then
      Owner.SelectedObjects.Clear;
    Selected := True;
  end;
  HT := HitTest(Pt);
  if (Button = mbLeft) and not (ssDouble in Shift) and Selected and not IsLocked then
    BeginDrag(Pt, HT);
  Screen.Cursor := QueryCursor(HT);
end;

procedure TGraphObject.MouseMove(Shift: TShiftState; const Pt: TPoint);
begin
  if Dragging then
    DragTo(Pt, Owner.SnapToGrid xor (ssCtrl in Shift))
  else
    Screen.Cursor := QueryCursor(HitTest(Pt));
end;

procedure TGraphObject.MouseUp(Button: TMouseButton; Shift: TShiftState; const Pt: TPoint);
begin
  if Dragging then
  begin
    EndDrag(True);
    Screen.Cursor := QueryCursor(HitTest(Pt));
  end;
end;

function TGraphObject.KeyPress(var Key: Word; Shift: TShiftState): Boolean;
var
  dX, dY: Integer;
  Mobility: TObjectSides;
  HT: DWORD;
begin
  Result := False;
  dX := 0;
  dY := 0;
  case Key of
    VK_ESCAPE:
    begin
      if Dragging then
      begin
        Result := True;
        EndDrag(False);
      end;
    end;
    VK_LEFT:
      if (Shift - [ssCtrl]) <= [ssShift] then dX := -1;
    VK_RIGHT:
      if (Shift - [ssCtrl]) <= [ssShift] then dX := +1;
    VK_UP:
      if (Shift - [ssCtrl]) <= [ssShift] then dY := -1;
    VK_DOWN:
      if (Shift - [ssCtrl]) <= [ssShift] then dY := +1;
  end;
  if (dX <> 0) or (dY <> 0) then
  begin
    if Owner.SnapToGrid xor (ssCtrl in Shift) then
    begin
      dX := dX * Owner.GridSize;
      dY := dY * Owner.GridSize;
    end;
    if ssShift in Shift then
    begin
      Mobility := [osRight, osBottom];
      HT := GHT_BOTTOMRIGHT;
    end
    else
    begin
      Mobility := [osLeft, osTop, osRight, osBottom];
      HT := GHT_CLIENT;
    end;
    if Owner.GraphConstraints.ConfineOffset(dX, dY, Mobility) then
      OffsetHitTest(HT, dX, dY);
    Result := True;
  end;
end;

function TGraphObject.BeginDrag(const Pt: TPoint; HT: DWORD): Boolean;
begin
  Result := False;
  if not (osDragDisabled in States) and
    (not Assigned(Owner.DragSource) or (Owner.DragSource = Self)) then
  begin
    if HT = $FFFFFFFF then
      HT := HitTest(Pt);
    if Owner.BeginDragObject(Self, Pt, HT) then
    begin
      Include(fStates, osDragging);
      Changed([gcView]);
      Result := True;
    end;
  end;
end;

function TGraphObject.DragTo(const Pt: TPoint; SnapToGrid: Boolean): Boolean;
begin
  with Owner.DragTargetPt do
    Result := DragBy(Pt.X - X, Pt.Y - Y, SnapToGrid);
end;

function TGraphObject.DragBy(dX, dY: Integer; SnapToGrid: Boolean): Boolean;
begin
  Result := False;
  Owner.memo1.Lines.Add('TGraphObject.DragBy (' + inttostr(dx) + ',' + inttostr(dy) + ')');
  if Owner.DragSource = Self then
  begin
    if (dX <> 0) or (dY <> 0) then
    begin
      if SnapToGrid then
        SnapHitTestOffset(Owner.DragHitTest, dX, dY);
      Owner.PerformDragBy(dX, dY);
    end;
    Result := True;
  end;
end;

function TGraphObject.EndDrag(Accept: Boolean): Boolean;
begin
  Result := False;
  if Owner.DragSource = Self then
  begin
    Exclude(fStates, osDragging);
    Changed([gcView]);
    Owner.EndDragObject(Accept);
    Result := True;
  end;
end;

function TGraphObject.BeginFollowDrag(HT: DWORD): Boolean;
begin
  Result := False;
  if not (osDragDisabled in States) or IsLocked then
  begin
    Include(fStates, osDragging);
    Changed([gcView]);
    Result := True;
  end;
end;

function TGraphObject.EndFollowDrag: Boolean;
begin
  Result := False;
  if Dragging then
  begin
    Exclude(fStates, osDragging);
    Changed([gcView]);
    Result := True;
  end;
end;

procedure TGraphObject.DisableDrag;
begin
  if DragDisableCount = 0 then
    Include(fStates, osDragDisabled);
  Inc(DragDisableCount);
end;

procedure TGraphObject.EnableDrag;
begin
  Dec(DragDisableCount);
  if DragDisableCount = 0 then
    Exclude(fStates, osDragDisabled);
end;

function TGraphObject.IsFontStored: Boolean;
begin
  Result := not ParentFont;
end;

procedure TGraphObject.SetFont(Value: TFont);
begin
  Font.Assign(Value);
end;

procedure TGraphObject.SetParentFont(Value: Boolean);
begin
  if ParentFont <> Value then
  begin
    fParentFont := Value;
    if ParentFont then
    begin
      Font.OnChange := nil;
      try
        Font.Assign(Owner.Font);
      finally
        Font.OnChange := StyleChanged;
      end;
      Changed([gcView, gcData, gcText]);
    end
    else
      Changed([gcData]);
  end;
end;

procedure TGraphObject.SetOptions(Value: TGraphObjectOptions);
begin
  if Options <> Value then
  begin
    fOptions := Value;
    Changed([gcView, gcData]);
  end;
end;

procedure TGraphObject.SetHasCustomData(Value: Boolean);
begin
  if HasCustomData <> Value then
  begin
    fHasCustomData := Value;
    Changed([gcData]);
  end;
end;

procedure TGraphObject.SetBrush(Value: TBrush);
begin
  Brush.Assign(Value);
end;

procedure TGraphObject.SetPen(Value: TPen);
begin
  Pen.Assign(Value);
end;

procedure TGraphObject.SetText(const Value: String);
begin
  if Text <> Value then
  begin
    fText := Value;
    Changed([gcView, gcData, gcText]);
  end;
end;

procedure TGraphObject.SetHint(const Value: String);
begin
  if Hint <> Value then
  begin
    fHint := Value;
    Changed([gcData]);
  end;
end;

function TGraphObject.GetZOrder: Integer;
begin
  Result := Owner.Objects.IndexOf(Self);
end;

procedure TGraphObject.SetZOrder(Value: Integer);
begin
  if (Value < 0) or (Value >= Owner.Objects.Count) then
    Value := Owner.Objects.Count - 1;
  Owner.Objects.Move(ZOrder, Value);
end;

procedure TGraphObject.SetSelected(Value: Boolean);
begin
  if not (goSelectable in Options) then
    Value := False;
  if Selected <> Value then
  begin
    fSelected := Value;
    if Selected then
      Owner.SelectedObjects.Add(Self)
    else
      Owner.SelectedObjects.Remove(Self);
    Changed([gcView]);
  end;
end;

procedure TGraphObject.SetVisible(Value: Boolean);
begin
  if Visible <> Value then
  begin
    fVisible := Value;
    Changed([gcView, gcData]);
  end;
end;

procedure TGraphObject.StyleChanged(Sender: TObject);
begin
  if Sender = Font then
  begin
    fParentFont := False;
    Changed([gcView, gcData, gcText]);
  end
  else if Sender = Pen then
    Changed([gcView, gcData, gcText, gcPlacement])
  else
    Changed([gcView, gcData]);
end;

procedure TGraphObject.ListChanged(Sender: TObject;
  GraphObject: TGraphObject; Action: TGraphObjectListAction);
begin
  if Sender = DependentList then
    DependentChanged(GraphObject, Action)
  else if Sender = LinkInputList then
    LinkInputChanged(GraphObject, Action)
  else if Sender = LinkOutputList then
    LinkOutputChanged(GraphObject, Action);
end;

function TGraphObject.GetSelectedVisualRect: TRect;
var
  D: Integer;
begin
  Result := VisualRect;
  D := Owner.MarkerSize - Pen.Width div 2;
  if D > 0 then InflateRect(Result, D, D);
end;

function TGraphObject.GetShowing: Boolean;
begin
  Result := (Visible or Owner.ShowHiddenObjects) and not (osDestroying in States);
end;

function TGraphObject.GetDragging: Boolean;
begin
  Result := osDragging in States;
end;

function TGraphObject.GetDependents(Index: Integer): TGraphObject;
begin
  Result := DependentList[Index];
end;

function TGraphObject.GetDependentCount: Integer;
begin
  Result := DependentList.Count;
end;

function TGraphObject.GetLinkInputs(Index: Integer): TGraphLink;
begin
  Result := TGraphLink(LinkInputList[Index]);
end;

function TGraphObject.GetLinkInputCount: Integer;
begin
  Result := LinkInputList.Count;
end;

function TGraphObject.GetLinkOutputs(Index: Integer): TGraphLink;
begin
  Result := TGraphLink(LinkOutputList[Index]);
end;

function TGraphObject.GetLinkOutputCount: Integer;
begin
  Result := LinkOutputList.Count;
end;

class function TGraphObject.IsLink: Boolean;
begin
  Result := False;
end;

class function TGraphObject.IsNode: Boolean;
begin
  Result := not IsLink;
end;

function TGraphObject.IsLocked: Boolean;
begin
  if IsLink then
    Result := Owner.LockLinks
  else if IsNode then
    Result := Owner.LockNodes
  else
    Result := False;
end;

function TGraphObject.IsVisibleOn(Canvas: TCanvas): Boolean;
begin
  if Showing then
    if not (Canvas is TMetafileCanvas) then  // Windows.RectVisible bug!!!
      Result := RectVisible(Canvas.Handle, SelectedVisualRect)
    else
      Result := True
  else
    Result := False;
end;

function TGraphObject.IsUpdateLocked: Boolean;
begin
  Result := (States * [osCreating, osDestroying, osReading, osUpdating]) <> [];
end;

function TGraphObject.NeighborhoodRadius: Integer;
begin
  Result := Pen.Width div 2;
  if Result < Owner.MarkerSize then
    Result := Owner.MarkerSize;
end;

procedure TGraphObject.BringToFront;
begin
  ZOrder := MaxInt;
end;

procedure TGraphObject.SendToBack;
begin
  ZOrder := 0;
end;

function TGraphObject.Delete: Boolean;
begin
  Result := False;
  if (Self <> nil) and CanDelete then
  begin
    Destroy;
    Result := True;
  end;
end;

function TGraphObject.CanDelete: Boolean;
begin
  Result := True;
  Owner.DoCanRemoveObject(Self, Result);
end;

function TGraphObject.HitTest(const Pt: TPoint): DWORD;
begin
  Result := GHT_NOWHERE;
  if Showing and
     ((Selected and PtInRect(SelectedVisualRect, Pt)) or
      (not Selected and PtInRect(VisualRect, Pt))) then
  begin
    Result := QueryHitTest(Pt);
    if (Result <> GHT_NOWHERE) and not (goSelectable in Options) then
      Result := GHT_TRANSPARENT;
  end;
end;

function TGraphObject.ContainsPoint(X, Y: Integer): Boolean;
begin
  Result := (HitTest(Point(X, Y)) <> GHT_NOWHERE);
end;

function TGraphObject.ContainsRect(const Rect: TRect): Boolean;
begin
  if Showing then
    if Selected then
      Result := OverlappedRect(Rect, SelectedVisualRect)
    else
      Result := OverlappedRect(Rect, VisualRect)
  else
    Result := False;
end;

procedure TGraphObject.Assign(Source: TPersistent);
begin
  if Source is TGraphObject then
  begin
    BeginUpdate;
    try
      Text := TGraphObject(Source).Text;
      Hint := TGraphObject(Source).Hint;
      Brush := TGraphObject(Source).Brush;
      Pen := TGraphObject(Source).Pen;
      Font := TGraphObject(Source).Font;
      ParentFont := TGraphObject(Source).ParentFont;
      Visible := TGraphObject(Source).Visible;
      Options := TGraphObject(Source).Options;
    finally
      EndUpdate;
    end;
  end
  else
    inherited Assign(Source);
end;

procedure TGraphObject.AssignTo(Dest: TPersistent);
begin
  if Dest is TGraphObject then
    Dest.Assign(Self)
  else
    inherited AssignTo(Dest);
end;

procedure TGraphObject.DrawControlPoint(Canvas: TCanvas; const Pt: TPoint; Enabled: Boolean);
var
  R: TRect;
begin
  R := MakeSquare(Pt, Owner.MarkerSize);
  Canvas.Rectangle(R.Left, R.Top, R.Right, R.Bottom);
  if not Enabled then
  begin
    InflateRect(R, -2, -2);
    Canvas.Rectangle(R.Left, R.Top, R.Right, R.Bottom);
  end;
end;

procedure TGraphObject.Draw(Canvas: TCanvas);
begin
  if IsVisibleOn(Canvas) then
  begin
    Canvas.Brush := Brush;
    Canvas.Pen := Pen;
    Canvas.Font := Font;
    Owner.DoObjectBeforeDraw(Canvas, Self);
    DrawBody(Canvas);
    if goShowCaption in Options then
      DrawText(Canvas);
    Owner.DoObjectAfterDraw(Canvas, Self);
  end;
end;

procedure TGraphObject.DrawState(Canvas: TCanvas);
begin
  if IsVisibleOn(Canvas) then
  begin
    if Dragging then
    begin
      Canvas.Brush.Style := bsClear;
      Canvas.Pen.Mode := pmNot;
      Canvas.Pen.Style := psSolid;
      if Pen.Width >= 2 then
        Canvas.Pen.Width := (Pen.Width - 1) div 2
      else
        Canvas.Pen.Width := Pen.Width + 2;
      DrawHighlight(Canvas);
    end
    else if Selected then
    begin
      Canvas.Pen.Width := 1;
      Canvas.Pen.Mode := pmCopy;
      Canvas.Pen.Style := psInsideFrame;
      Canvas.Pen.Color := Owner.MarkerColor;
      Canvas.Brush.Style := bsSolid;
      Canvas.Brush.Color := Owner.Color;
      DrawControlPoints(Canvas);
    end;
  end;
end;

function TGraphObject.ConvertTo(AnotherClass: TGraphObjectClass): TGraphObject;
begin
  Result := Self;
  if Assigned(AnotherClass) and (ClassType <> AnotherClass) and
    ((IsLink and AnotherClass.IsLink) or (IsNode and AnotherClass.IsNode)) then
  begin
    Result := AnotherClass.CreateAsReplacement(Self);
    Self.Free;
  end;
end;

procedure TGraphObject.LoadFromStream(Stream: TStream);
var
  Streamable: TGraphStreamableObject;
begin
  BeginUpdate;
  try
    Include(fStates, osReading);
    try
      Streamable := TGraphStreamableObject.Create(nil);
      try
        Streamable.G := Self;
        Stream.ReadComponent(Streamable);
        Self.fID := Streamable.ID;
      finally
        Streamable.Free;
      end;
    finally
      Exclude(fStates, osReading);
    end;
    if not (osCreating in States) then
      Initialize;
  finally
    EndUpdate;
  end;
end;

procedure TGraphObject.SaveToStream(Stream: TStream);
var
  Streamable: TGraphStreamableObject;
begin
  Include(fStates, osWriting);
  try
    Streamable := TGraphStreamableObject.Create(nil);
    try
      Streamable.G := Self;
      Streamable.ID := Self.ID;
      Stream.WriteComponent(Streamable);
    finally
      Streamable.Free;
    end;
  finally
    Exclude(fStates, osWriting);
  end;
end;

procedure TGraphObject.BeginUpdate;
begin
  if UpdateCount = 0 then
  begin
    Include(fStates, osUpdating);
    PendingChanges := [];
  end;
  Inc(UpdateCount);
end;

procedure TGraphObject.EndUpdate;
begin
  Dec(UpdateCount);
  if UpdateCount = 0 then
  begin
    Exclude(fStates, osUpdating);
    if PendingChanges <> [] then
      Changed(PendingChanges);
  end;
end;

procedure TGraphObject.Invalidate;
begin
  Owner.InvalidateRect(SelectedVisualRect);
end;

procedure TGraphObject.DefineProperties(Filer: TFiler);
begin
  inherited DefineProperties(Filer);
  Filer.DefineBinaryProperty('CustomData', ReadCustomData, WriteCustomData, HasCustomData);
end;

procedure TGraphObject.ReadCustomData(Stream: TStream);
var
  TmpStream: TMemoryStream;
  CustomDataSize: Integer;
begin
  Stream.Read(CustomDataSize, SizeOf(CustomDataSize));
  if CustomDataSize > 0 then
  begin
    TmpStream := TMemoryStream.Create;
    try
      TmpStream.CopyFrom(Stream, CustomDataSize);
      TmpStream.Seek(0, soFromBeginning);
      Owner.DoObjectRead(Self, TmpStream);
    finally
      TmpStream.Free;
    end;
  end;
end;

procedure TGraphObject.WriteCustomData(Stream: TStream);
var
  TmpStream: TMemoryStream;
  CustomDataSize: Integer;
begin
  TmpStream := TMemoryStream.Create;
  try
    Owner.DoObjectWrite(Self, TmpStream);
    CustomDataSize := TmpStream.Size;
    Stream.Write(CustomDataSize, SizeOf(CustomDataSize));
    if CustomDataSize > 0 then
    begin
      TmpStream.Seek(0, soFromBeginning);
      Stream.CopyFrom(TmpStream, CustomDataSize);
    end;
  finally
    TmpStream.Free;
  end;
end;


{ TGraphLink }

constructor TGraphLink.Create(AOwner: TSimpleGraph);
begin
  inherited Create(AOwner);
  fTextPosition := -1;
  fTextSpacing := 0;
  fLinkOptions := [];
  fBeginStyle := lsNone;
  fBeginSize := 6;
  fEndStyle := lsArrow;
  fEndSize := 6;
  fMovingPoint := -1;
  VisualRectFlags := VisualRectFlags + [gcText];
end;

constructor TGraphLink.CreateNew(AOwner: TSimpleGraph; ASource: TGraphObject;
  const Pts: array of TPoint; ATarget: TGraphObject);
var
  I: Integer;
begin
  Create(AOwner);
  if Assigned(ASource) then
    AddPoint(ASource.FixHookAnchor);
    
  { init 2 point add, start, end point }
  for I := Low(Pts) to High(Pts) do
    AddPoint(Pts[I]);

  if Assigned(ATarget) then
    AddPoint(ATarget.FixHookAnchor);
  if Assigned(ASource) and Assigned(ATarget) then
    Link(ASource, ATarget)
  else if Assigned(ASource) then
    Hook(0, ASource)
  else if Assigned(ATarget) then
    Hook(PointCount - 1, ATarget);
  if (Source <> ASource) or (Target <> ATarget) then
    raise EGraphInvalidOperation.Create(SLinkCreateError);
end;

destructor TGraphLink.Destroy;
begin
  if TextRegion <> 0 then
    DeleteObject(TextRegion);
  SetLength(fPoints, 0);
  inherited Destroy;
end;

procedure TGraphLink.Assign(Source: TPersistent);
begin
  BeginUpdate;
  try
    inherited Assign(Source);
    if Source is TGraphLink then
    begin
      Polyline := TGraphLink(Source).Polyline;
      BeginStyle := TGraphLink(Source).BeginStyle;
      BeginSize := TGraphLink(Source).BeginSize;
      EndStyle := TGraphLink(Source).EndStyle;
      EndSize := TGraphLink(Source).EndSize;
      LinkOptions := TGraphLink(Source).LinkOptions;
      TextPosition := TGraphLink(Source).TextPosition;
      TextSpacing := TGraphLink(Source).TextSpacing;
      if Assigned(TGraphLink(Source).Source) and Assigned(TGraphLink(Source).Target) then
        Link(TGraphLink(Source).Source, TGraphLink(Source).Target)
      else
      begin
        Source := TGraphLink(Source).Source;
        Target := TGraphLink(Source).Target;
      end;
    end;
  finally
    EndUpdate;
  end;
end;

function TGraphLink.ContainsRect(const Rect: TRect): Boolean;

  function ContainsEdge(const Pt: TPoint; const Angle: Double): Boolean;
  var
    Intersects: TPoints;
    I: Integer;
  begin
    Result := False;
    Intersects := IntersectLinePolyline(Pt, Angle, Polyline);
    try
      for I := 0 to Length(Intersects) - 1 do
        if PtInRect(Rect, Intersects[I]) then
        begin
          Result := True;
          Break;
        end;
    finally
      SetLength(Intersects, 0);
    end;
  end;

var
  I: Integer;
begin
  if inherited ContainsRect(Rect) then
  begin
    if (TextRegion <> 0) and (goShowCaption in Options) and RectInRegion(TextRegion, Rect) then
      Result := True
    else
    begin
      for I := 0 to PointCount - 1 do
        if PtInRect(Rect, Points[I]) then
        begin
          Result := True;
          Exit;
        end;
      Result := ContainsEdge(Rect.TopLeft, 0) or
                ContainsEdge(Rect.TopLeft, Pi / 2) or
                ContainsEdge(Rect.BottomRight, 0) or
                ContainsEdge(Rect.BottomRight, Pi / 2)
    end;
  end
  else
    Result := False;
end;

function TGraphLink.PointStyleOffset(Style: TLinkBeginEndStyle; Size: Integer): Integer;
begin
  case Style of
    lsArrow, lsArrowSimple:
      Result := 2 * (Size + Pen.Width);
    lsCircle, lsDiamond:
      Result := (Size + Pen.Width + 1) div 2;
  else
    Result := 0;
  end;
end;

function TGraphLink.PointStyleRect(const Pt: TPoint; const Angle: Double;
  Style: TLinkBeginEndStyle; Size: Integer): TRect;
var
  Pts: array[1..3] of TPoint;
  M: Integer;
begin
  Size := PointStyleOffset(Style, Size);
  case Style of
    lsArrow:
    begin
      Pts[1] := Pt;
      Pts[2] := NextPointOfLine(Angle + Pi / 9, Pt, Size);
      Pts[3] := NextPointOfLine(Angle - Pi / 9, Pt, Size);
      Result := BoundsRectOfPoints(Pts);
    end;
    lsArrowSimple:
    begin
      Pts[1] := NextPointOfLine(Angle + Pi / 6, Pt, Size);
      Pts[2] := Pt;
      Pts[3] := NextPointOfLine(Angle - Pi / 6, Pt, Size);
      Result := BoundsRectOfPoints(Pts);
    end;
    lsCircle, lsDiamond:
    begin
      Result := MakeSquare(Pt, Size);
    end;
  else
    Result := MakeSquare(Pt, 1);
  end;
  if Pen.Style <> psInsideFrame then
  begin
    M := (Pen.Width div 2) + 1;
    InflateRect(Result, M, M);
  end;
end;

function TGraphLink.DrawPointStyle(Canvas: TCanvas; const Pt: TPoint; const Angle: Double;
  Style: TLinkBeginEndStyle; Size: Integer): TPoint;
var
  Pts: array[1..4] of TPoint;
begin
  Size := PointStyleOffset(Style, Size);
  case Style of
    lsArrow:
    begin
      Pts[1] := Pt;
      Pts[2] := NextPointOfLine(Angle + Pi / 9, Pt, Size);
      Pts[3] := NextPointOfLine(Angle, Pt, MulDiv(Size, 6, 10));
      Pts[4] := NextPointOfLine(Angle - Pi / 9, Pt, Size);
      Canvas.Polygon(Pts);
      Result := Pts[3];
    end;
    lsArrowSimple:
    begin
      Pts[1] := NextPointOfLine(Angle + Pi / 6, Pt, Size);
      Pts[2] := Pt;
      Pts[3] := NextPointOfLine(Angle - Pi / 6, Pt, Size);
      Canvas.Polyline(Slice(Pts, 3));
      Result := Pt;
    end;
    lsCircle:
    begin
      Canvas.Ellipse(Pt.X - Size, Pt.Y - Size, Pt.X + Size, Pt.Y + Size);
      Result := NextPointOfLine(Angle, Pt, Size);
    end;
    lsDiamond:
    begin
      Pts[1] := NextPointOfLine(Angle, Pt, Size);
      Pts[2] := NextPointOfLine(Angle + Pi / 2, Pt, Size);
      Pts[3] := NextPointOfLine(Angle, Pt, -Size);
      Pts[4] := NextPointOfLine(Angle - Pi / 2, Pt, Size);
      Canvas.Polygon(Pts);
      Result := Pts[1];
    end;
  else
    Result := Pt;
  end;
end;

procedure TGraphLink.DrawControlPoints(Canvas: TCanvas);
var
  I: Integer;
begin
  DrawControlPoint(Canvas, fPoints[0], not (Owner.LockLinks or (gloFixedStartPoint in LinkOptions)));
  for I := 1 to PointCount - 2 do
    DrawControlPoint(Canvas, fPoints[I], not (Owner.LockLinks or (gloFixedBreakPoints in LinkOptions)));
  DrawControlPoint(Canvas, fPoints[PointCount - 1], not (Owner.LockLinks or (gloFixedEndPoint in LinkOptions)));
end;

procedure TGraphLink.DrawHighlight(Canvas: TCanvas);
var
  PtRect: TRect;
  First, Last: Integer;
begin
  if PointCount > 1 then
  begin
    if (MovingPoint >= 0) and (MovingPoint < PointCount) then
    begin
      if MovingPoint > 0 then
        First := MovingPoint - 1
      else
        First := MovingPoint;
      if MovingPoint < PointCount - 1 then
        Last := MovingPoint + 1
      else
        Last := MovingPoint;
      Canvas.Polyline(Copy(Polyline, First, Last - First + 1));
    end
    else
      Canvas.Polyline(Polyline)
  end
  else if PointCount = 1 then
  begin
    PtRect := MakeSquare(Points[0], Canvas.Pen.Width);
    Canvas.Ellipse(PtRect.Left, PtRect.Top, PtRect.Right, PtRect.Bottom);
  end;
end;

procedure TGraphLink.DrawText(Canvas: TCanvas);
var
  DC: HDC;
  LogFont: TLogFont;
  FontHandle: THandle;
  TextFlags: Integer;
  BkMode, TextAlign: Integer;
begin
  if TextRegion <> 0 then
  begin
    GetObject(Canvas.Font.Handle, SizeOf(LogFont), @LogFont);
    if Abs(TextAngle) > Pi / 2 then
      LogFont.lfEscapement := Round(-1800 * (TextAngle - Pi) / Pi)
    else
      LogFont.lfEscapement := Round(-1800 * TextAngle / Pi);
    LogFont.lfOrientation := LogFont.lfEscapement;
    LogFont.lfQuality := PROOF_QUALITY;
    DC := Canvas.Handle;
    FontHandle := SelectObject(DC, CreateFontIndirect(LogFont));
    BkMode := SetBkMode(DC, TRANSPARENT);
    TextAlign := SetTextAlign(DC, TA_BOTTOM or TA_CENTER);
    if Owner.UseRightToLeftReading then
      TextFlags := ETO_RTLREADING
    else
      TextFlags := 0;
    ExtTextOut(DC, TextCenter.X, TextCenter.Y, TextFlags, nil,
      PChar(TextToShow), Length(TextToShow), nil);
    SetTextAlign(DC, TextAlign);
    SetBkMode(DC, BkMode);
    DeleteObject(SelectObject(DC, FontHandle));
  end;
end;

procedure TGraphLink.DrawBody(Canvas: TCanvas);
var
  OldPenStyle: TPenStyle;
  OldBrushStyle: TBrushStyle;
  ModifiedPolyline: TPoints;
  Angle: Double;
  PtRect: TRect;
begin
  
  ModifiedPolyline := nil;
  if PointCount = 1 then
  begin
    owner.memo1.Lines.Add('PointCount = 1');
    PtRect := MakeSquare(Points[0], Pen.Width div 2);
    while not IsRectEmpty(PtRect) do
    begin
      Canvas.Ellipse(PtRect.Left, PtRect.Top, PtRect.Right, PtRect.Bottom);
      InflateRect(PtRect, -1, -1);
    end;
  end
  else if PointCount >= 2 then
  begin
    if (BeginStyle <> lsNone) or (EndStyle <> lsNone) then
    begin
      OldPenStyle := Canvas.Pen.Style;
      Canvas.Pen.Style := psSolid;
      try
        if BeginStyle <> lsNone then
        begin
          if ModifiedPolyline = nil then
            ModifiedPolyline := Copy(Polyline, 0, PointCount);
          Angle := LineSlopeAngle(fPoints[1], fPoints[0]);
          ModifiedPolyline[0] := DrawPointStyle(Canvas, fPoints[0], Angle, BeginStyle, BeginSize);
        end;
        if EndStyle <> lsNone then
        begin
          if ModifiedPolyline = nil then
            ModifiedPolyline := Copy(Polyline, 0, PointCount);
          Angle := LineSlopeAngle(fPoints[PointCount - 2], fPoints[PointCount - 1]);
          ModifiedPolyline[PointCount - 1] := DrawPointStyle(Canvas, fPoints[PointCount - 1], Angle, EndStyle, EndSize);;
        end;
      finally
        Canvas.Pen.Style := OldPenStyle;
      end;
    end;

    { Draw Line }
    OldBrushStyle := Canvas.Brush.Style;
    try
      Canvas.Brush.Style := bsClear;
      if ModifiedPolyline <> nil then
        Canvas.Polyline(ModifiedPolyline)
      else
        Canvas.Polyline(Polyline);
    finally
      Canvas.Brush.Style := OldBrushStyle;
    end;
  end;
  ModifiedPolyline := nil;
end;

procedure TGraphLink.SetBoundsRect(const Rect: TRect);
begin
  // Nothing to do
  owner.memo1.Lines.Add('TGraphLink.SetBoundsRect');
end;

function TGraphLink.GetBoundsRect: TRect;
begin
  Result := BoundsRectOfPoints(Polyline);
end;

procedure TGraphLink.QueryVisualRect(out Rect: TRect);
var
  TextRect: TRect;
  Margin: Integer;
  Angle: Double;
begin
  Rect := BoundsRect;
  Margin := (Pen.Width div 2) + 1;
  InflateRect(Rect, Margin, Margin);

  if PointCount >= 2 then
  begin
    if BeginStyle <> lsNone then
    begin
      Angle := LineSlopeAngle(fPoints[1], fPoints[0]);
      UnionRect(Rect, PointStyleRect(fPoints[0], Angle, BeginStyle, BeginSize));
    end;
    if EndStyle <> lsNone then
    begin
      Angle := LineSlopeAngle(fPoints[PointCount - 2], fPoints[PointCount - 1]);
      UnionRect(Rect, PointStyleRect(fPoints[PointCount - 1], Angle, EndStyle, EndSize));
    end;
  end;

  if (TextRegion <> 0) and (goShowCaption in Options) then
  begin
    GetRgnBox(TextRegion, TextRect);
    UnionRect(Rect, TextRect)
  end;
end;

class function TGraphLink.IsLink: Boolean;
begin
  Result := True;
end;

function TGraphLink.FixHookAnchor: TPoint;
var
  MidPoint: Integer;
begin
  if PointCount > 0 then
  begin
    MidPoint := PointCount div 2;
    if Odd(PointCount) then
      Result := fPoints[MidPoint]
    else
      Result := CenterOfPoints([fPoints[MidPoint - 1], fPoints[MidPoint]]);
  end
  else
    Result := CenterOfRect(Owner.VisibleBounds);
end;

function TGraphLink.RelativeHookAnchor(RefPt: TPoint): TPoint;

  function ValidAnchor(Index: Integer): Boolean;
  var
    GraphObject: TGraphObject;
  begin
    GraphObject := HookedObjectOf(Index);
    Result := not Assigned(GraphObject) or GraphObject.IsLink;
  end;

var
  Pt: TPoint;
  Line: Integer;
  Index: Integer;
begin
  Line := IndexOfNearestLine(RefPt, MaxInt);
  if Line >= 0 then
  begin
    Pt := NearestPointOnLine(fPoints[Line], fPoints[Line + 1], RefPt);
    Index := IndexOfPoint(Pt, NeighborhoodRadius);
    if Index < 0 then
      Result := Pt
    else if ValidAnchor(Index) then
      Result := fPoints[Index]
    else
    begin
      if (Index = 0) and ValidAnchor(Index + 1) then
        Result := Points[Index + 1]
      else if (Index = PointCount - 1) and ValidAnchor(Index - 1) then
        Result := fPoints[Index - 1]
      else
        Result := FixHookAnchor
    end;
  end
  else if PointCount = 1 then
    Result := fPoints[0]
  else
    Result := RefPt;
end;

function TGraphLink.IndexOfLongestLine: Integer;
var
  I: Integer;
  LongestLength: Double;
  Length: Double;
begin
  Result := -1;
  LongestLength := -MaxInt;
  for I := 0 to PointCount - 2 do
  begin
    Length := LineLength(fPoints[I], fPoints[I + 1]);
    if Length > LongestLength then
    begin
      LongestLength := Length;
      Result := I;
    end;
  end;
end;

function TGraphLink.IndexOfNearestLine(const Pt: TPoint; Neighborhood: Integer): Integer;
var
  I: Integer;
  NearestDistance: Double;
  Distance: Double;
begin
  Result := -1;
  NearestDistance := MaxDouble;
  for I := 0 to PointCount - 2 do
  begin
    Distance := DistanceToLine(fPoints[I], fPoints[I + 1], Pt);
    if (Trunc(Distance) <= Neighborhood) and (Distance < NearestDistance) then
    begin
      NearestDistance := Distance;
      Result := I;
    end;
  end;
end;

function TGraphLink.QueryHitTest(const Pt: TPoint): DWORD;
var
  Neighborhood: Integer;
  I: Integer;
begin
  Neighborhood := NeighborhoodRadius;
  for I := PointCount - 1 downto 0 do
    if PtInRect(MakeSquare(fPoints[I], Neighborhood), Pt) then
    begin
      if Selected then
        Result := GHT_POINT or (I shl 16)
      else
        Result := GHT_CLIENT;
      Exit;
    end;
  for I := 0 to PointCount - 2 do
    if DistanceToLine(fPoints[I], fPoints[I + 1], Pt) <= Neighborhood then
    begin
      if Selected then
        Result := GHT_LINE or (I shl 16) or GHT_CLIENT
      else
        Result := GHT_CLIENT;
      Exit;
    end;
  if (TextRegion <> 0) and (goShowCaption in Options) and PtInRegion(TextRegion, Pt.X, Pt.Y) then
    Result := GHT_CAPTION or GHT_CLIENT
  else
    Result := inherited QueryHitTest(Pt);
end;

procedure TGraphLink.SnapHitTestOffset(HT: DWORD; var dX, dY: Integer);
begin
  if (HT and GHT_POINT) <> 0 then
    Owner.SnapOffset(fPoints[HiWord(HT)], dX, dY)
  else if (HT and GHT_BODY_MASK) <> 0 then
    Owner.SnapOffset(fPoints[0], dX, dY)
  else
    inherited SnapHitTestOffset(HT, dX, dY);
end;

function TGraphLink.QueryMobility(HT: DWORD): TObjectSides;
begin
  if (HT and (GHT_POINT or GHT_BODY_MASK)) <> 0 then
    Result := [osLeft, osTop, osRight, osBottom]
  else
    Result := inherited QueryMobility(HT);
end;

function TGraphLink.OffsetHitTest(HT: DWORD; dX, dY: Integer): Boolean;
var
  Index: Integer;
  MovedPoints: Integer;
  ShiftRef: TPoint;
begin
  Result := False;
  if (HT and GHT_POINT) <> 0 then
  begin
    Index := HiWord(HT);
    if not IsFixedPoint(Index, True) then
    begin
      with fPoints[Index] do
      begin
        Inc(X, dX);
        Inc(Y, dY);
      end;
      Changed([gcView, gcData, gcText, gcPlacement]);
      Result := True;
    end;
  end
  else if (HT and GHT_BODY_MASK) <> 0 then
  begin
    MovedPoints := 0;
    for Index := 0 to PointCount - 1 do
      if not IsFixedPoint(Index, True) then
      begin
        with fPoints[Index] do
        begin
          Inc(X, dX);
          Inc(Y, dY);
        end;
        Inc(MovedPoints);
      end;
    if MovedPoints > 0 then
    begin
      if (MovedPoints = PointCount) and not IsUpdateLocked then
        BoundsChanged(dX, dY, 0, 0)
      else
        Changed([gcView, gcData, gcText, gcPlacement]);
      Result := True;
    end;
  end
  else if (HT and GHT_SIDES_MASK) <> 0 then
  begin
    case HT of
      GHT_LEFT:
        with BoundsRect do
        begin
          ShiftRef.X := Right;
          ShiftRef.Y := (Top + Bottom) div 2;
          dX := -dX;
          dY := 0;
        end;
      GHT_TOP:
        with BoundsRect do
        begin
          ShiftRef.X := (Left + Right) div 2;
          ShiftRef.Y := Bottom;
          dX := 0;
          dY := -dY;
        end;
      GHT_RIGHT:
        with BoundsRect do
        begin
          ShiftRef.X := Left;
          ShiftRef.Y := (Top + Bottom) div 2;
          dY := 0;
        end;
      GHT_BOTTOM:
        with BoundsRect do
        begin
          ShiftRef.X := (Left + Right) div 2;
          ShiftRef.Y := Top;
          dX := 0;
        end;
      GHT_TOPLEFT:
        with BoundsRect do
        begin
          ShiftRef.X := Right;
          ShiftRef.Y := Bottom;
          dX := -dX;
          dY := -dY;
        end;
      GHT_TOPRIGHT:
        with BoundsRect do
        begin
          ShiftRef.X := Left;
          ShiftRef.Y := Bottom;
          dY := -dY;
        end;
      GHT_BOTTOMLEFT:
        with BoundsRect do
        begin
          ShiftRef.X := Right;
          ShiftRef.Y := Top;
          dX := -dX;
        end;
      GHT_BOTTOMRIGHT:
        with BoundsRect do
        begin
          ShiftRef.X := Left;
          ShiftRef.Y := Top;
        end;
    end;
    if CanMove then
    begin
      ShiftPoints(fPoints, dX, dY, ShiftRef);
      Changed([gcView, gcData, gcText, gcPlacement]);
      Result := True;
    end;
  end
  else
    inherited OffsetHitTest(HT, dX, dY);
end;

procedure TGraphLink.MoveBy(dX, dY: Integer);
var
  I: Integer;
begin
  owner.memo1.Lines.Add('MoveBy(dX, dY: Integer)');
  if (PointCount > 0) and ((dX <> 0) or (dY <> 0)) then
  begin
    for I := 0 to PointCount - 1 do
      with fPoints[I] do
      begin
        Inc(X, dX);
        Inc(Y, dY);
      end;
    if not IsUpdateLocked then
      BoundsChanged(dX, dY, 0, 0)
    else
      Changed([gcView, gcData, gcText, gcPlacement]);
  end;
end;

function TGraphLink.BeginFollowDrag(HT: DWORD): Boolean;
begin
  if (HT and GHT_BODY_MASK) <> 0 then
    Result := inherited BeginFollowDrag(HT)
  else
    Result := False;
end;

function TGraphLink.QueryCursor(HT: DWORD): TCursor;
begin
  case LoWord(HT) and not GHT_CLIENT of
    GHT_POINT:
      case ChangeMode of
        lcmRemovePoint:
          Result := crXHair3;
        lcmMovePoint:
          if AcceptingHook then
            Result := crXHairLink
          else
            Result := crXHair2;
      else
        Result := crHandPoint;
      end;
    GHT_LINE:
      case ChangeMode of
        lcmInsertPoint:
          Result := crXHair1;
        lcmMovePolyline:
          Result := crSizeAll;
      else
        Result := crHandPoint;
      end;
    GHT_CAPTION:
      if ChangeMode = lcmMovePolyline then
        Result := crSizeAll
      else
        Result := crHandPoint;
  else
    if HT = GHT_CLIENT then
      Result := crHandPoint
    else
      Result := inherited QueryCursor(HT);
  end;
end;

procedure TGraphLink.UpdateChangeMode(HT: DWORD; Shift: TShiftState);
var
  Index: Integer;
begin
  ChangeMode := lcmNone;
  Index := HiWord(HT);
  case LoWord(HT) and not GHT_CLIENT of
    GHT_POINT:
      if not IsFixedPoint(Index, False) then
      begin
        if ssAlt in Shift then
          ChangeMode := lcmRemovePoint
        else
          ChangeMode := lcmMovePoint;
      end;
    GHT_LINE:
      if not (gloFixedBreakPoints in LinkOptions) then
      begin
        if ssAlt in Shift then
          ChangeMode := lcmInsertPoint
        else if not IsFixedPoint(Index, True) and not IsFixedPoint(Index + 1, True) then
          ChangeMode := lcmMovePolyline;
      end;
    GHT_CAPTION:
      if not (gloFixedBreakPoints in LinkOptions) and (HookedPointCount < PointCount) then
        ChangeMode := lcmMovePolyline;
  end;
end;

procedure TGraphLink.MouseDown(Button: TMouseButton; Shift: TShiftState; const Pt: TPoint);
var
  HT: DWORD;
  Handled: Boolean;
  NewPt: TPoint;
  WasDragging: Boolean;
  DragDisabled: Boolean;
begin
  Handled := False;
  WasDragging := False;
  if Dragging then
  begin
    WasDragging := True;
    EndDrag(True);
  end;
  DragDisabled := False;

  if WasDragging and (ssRight in Shift) and (ChangeMode = lcmMovePoint) then
  begin
    if Owner.SnapToGrid xor (ssCtrl in Shift) then
      NewPt := Owner.SnapPoint(Pt)
    else
      NewPt := Pt;
    Owner.GraphConstraints.ConfinePt(NewPt);
    if MovingPoint = 0 then
    begin
      BeginDrag(Pt, MakeLong(GHT_POINT, MovingPoint));
      InsertPoint(MovingPoint + 1, NewPt)
    end
    else
    begin
      BeginDrag(Pt, MakeLong(GHT_POINT, MovingPoint + 1));
      InsertPoint(MovingPoint, NewPt);
      Inc(fMovingPoint);
    end;
    Handled := True;
  end
  else if (Button = mbLeft) and Selected and not IsLocked then  { General Click }
  begin
    HT := HitTest(Pt);
    UpdateChangeMode(HT, Shift);
    case ChangeMode of
      lcmMovePoint:
      begin
        fMovingPoint := HiWord(HT);
        fHookingObject := HookedObjectOf(MovingPoint);
        fAcceptingHook := Assigned(fHookingObject);
        Unhook(fMovingPoint);
      end;
      lcmRemovePoint:
      begin
        RemovePoint(HiWord(HT));
        if PointCount = 0 then
        begin
          Free; // We don't need TSimpleGraph.OnCanRemoveObject event
          Exit;
        end;
        Handled := True;
      end;
      lcmInsertPoint:
      begin
        fMovingPoint := AddBreakPoint(Pt);
        if MovingPoint >= 0 then
          ChangeMode := lcmMovePoint
        else
          Handled := True;
      end;
      lcmMovePolyline:
        fMovingPoint := -1;
    else
      DisableDrag;
      DragDisabled := True;
    end;
    if Handled then
    begin
      if Dragging then EndDrag(True);
      Screen.Cursor := QueryCursor(HT);
    end;
  end;
  if not Handled then
  begin
    inherited MouseDown(Button, Shift, Pt);
    if DragDisabled then
      EnableDrag;
  end;
end;

procedure TGraphLink.MouseMove(Shift: TShiftState; const Pt: TPoint);
begin
  if not Dragging and Selected and not IsLocked then
    UpdateChangeMode(HitTest(Pt), Shift)
  else if (ChangeMode = lcmMovePoint) and (MovingPoint in [0, PointCount - 1]) then
  begin
    fHookingObject := Owner.FindObjectAt(Pt.X, Pt.Y);
    if (not (ssAlt in Shift) and CanHook(MovingPoint, HookingObject)) xor AcceptingHook then
    begin
      fAcceptingHook := not fAcceptingHook;
      Screen.Cursor := QueryCursor(MakeLong(GHT_POINT, MovingPoint));
    end;
  end;
  inherited MouseMove(Shift, Pt);
end;

procedure TGraphLink.MouseUp(Button: TMouseButton; Shift: TShiftState; const Pt: TPoint);
begin
  if not Dragging or (Button <> mbRight) or (ChangeMode <> lcmMovePoint) then
  begin
    inherited MouseUp(Button, Shift, Pt);
    
    if (ChangeMode = lcmMovePoint) and AcceptingHook then
      Hook(MovingPoint, HookingObject);
    fMovingPoint := -1;
    fHookingObject := nil;
    fAcceptingHook := False;
    ChangeMode := lcmNone;
  end;
end;

function TGraphLink.CanHook(Index: Integer; GraphObject: TGraphObject): Boolean;
begin
  Result := False;
  if Assigned(GraphObject) and (GraphObject <> Self) and
    (not (GraphObject is TGraphLink) or
    (TGraphLink(GraphObject).HookedIndexOf(Self) < 0)) then
  begin
    if Index = 0 then
    begin
      if GraphObject = Source then
        Result := True
      else if CheckingLink or (GraphObject <> Target) then
      begin
        Result := goLinkable in GraphObject.Options;
        Owner.DoCanHookLink(GraphObject, Self, Index, Result);
        if Result and not CheckingLink and Assigned(Target) then
          Owner.DoCanLinkObjects(Self, GraphObject, Target, Result);
      end;
    end
    else if Index >= PointCount - 1 then
    begin
      if GraphObject = Target then
        Result := True
      else if CheckingLink or (GraphObject <> Source) then
      begin
        Result := goLinkable in GraphObject.Options;
        Owner.DoCanHookLink(GraphObject, Self, Index, Result);
        if Result and not CheckingLink and Assigned(Source) then
          Owner.DoCanLinkObjects(Self, Source, GraphObject, Result);
      end;
    end;
  end;
end;

function TGraphLink.Hook(Index: Integer; GraphObject: TGraphObject): Boolean;
begin
  Result := False;
  if Assigned(GraphObject) then
  begin
    if Index = 0 then
    begin
      if GraphObject = Source then
        Result := True
      else if CanHook(Index, GraphObject) then
      begin
        BeginUpdate;
        try
          Unhook(Source);
          if PointCount < 1 then
            InsertPoint(0, GraphObject.FixHookAnchor);
          fSource := GraphObject;
          SourceID := GraphObject.ID;
          GraphObject.LinkOutputList.Add(Self);
          Changed([gcView, gcData, gcDependency]);
        finally
          EndUpdate;
        end;
        Owner.DoObjectHook(GraphObject, Self, Index);
        Result := True;
      end;
    end
    else if Index >= PointCount - 1 then
    begin
      if GraphObject = Target then
        Result := True
      else if CanHook(Index, GraphObject) then
      begin
        BeginUpdate;
        try
          Unhook(Target);
          if PointCount < 2 then
            AddPoint(GraphObject.FixHookAnchor);
          fTarget := GraphObject;
          TargetID := GraphObject.ID;
          GraphObject.LinkInputList.Add(Self);
          Changed([gcView, gcData, gcDependency]);
        finally
          EndUpdate;
        end;
        Owner.DoObjectHook(GraphObject, Self, Index);
        Result := True;
      end;
    end;
  end;
end;

function TGraphLink.Unhook(GraphObject: TGraphObject): Integer;
begin
  Result := -1;
  if Assigned(GraphObject) then
  begin
    if fSource = GraphObject then
    begin
      fSource := nil;
      SourceID := 0;
      Result := 0;
      GraphObject.LinkOutputList.Remove(Self);
    end;
    if fTarget = GraphObject then
    begin
      fTarget := nil;
      TargetID := 0;
      Result := PointCount - 1;
      GraphObject.LinkInputList.Remove(Self);
    end;
  end;
  if Result >= 0 then
  begin
    Changed([gcData]);
    Owner.DoObjectUnhook(GraphObject, Self, Result);
  end;
end;

function TGraphLink.Unhook(Index: Integer): Boolean;
begin
  Result := False;
  if Index = 0 then
    Result := (Unhook(Source) >= 0)
  else if Index = PointCount - 1 then
    Result := (Unhook(Target) >= 0);
end;

function TGraphLink.CanLink(ASource, ATarget: TGraphObject): Boolean;
begin
  Result := False;
  CheckingLink := True;
  try
    if (ASource <> ATarget) and CanHook(0, ASource) and CanHook(PointCount - 1, ATarget) then
    begin
      Result := True;
      Owner.DoCanLinkObjects(Self, ASource, ATarget, Result);
    end;
  finally
    CheckingLink := False;
  end;
end;

function TGraphLink.Link(ASource, ATarget: TGraphObject): Boolean;
begin
  Result := False;
  if CanLink(ASource, ATarget) then
  begin
    BeginUpdate;
    try
      if ASource <> Source then
      begin
        Unhook(Source);
        if PointCount < 1 then
          InsertPoint(0, ASource.FixHookAnchor);
        fSource := ASource;
        SourceID := ASource.ID;
        ASource.LinkOutputList.Add(Self);
        Changed([gcView, gcData, gcDependency]);
        Owner.DoObjectHook(ASource, Self, 0);
      end;
      if ATarget <> Target then
      begin
        Unhook(Target);
        if PointCount < 2 then
          AddPoint(ATarget.FixHookAnchor);
        fTarget := ATarget;
        TargetID := ATarget.ID;
        ATarget.LinkInputList.Add(Self);
        Changed([gcView, gcData, gcDependency]);
        Owner.DoObjectHook(ATarget, Self, PointCount - 1);
      end;
    finally
      EndUpdate;
    end;
  end;
end;

procedure TGraphLink.UpdateDependencies;
var
  OldPt: TPoint;
  Recheck: Boolean;
  RecheckCount: Integer;
  StartPt, EndPt: TPoint;
begin
  if not UpdatingEndPoints and (PointCount >= 2) and (Assigned(Source) or Assigned(Target)) then
  begin
    UpdatingEndPoints := True;
    try
      Recheck := False;
      StartPt := Points[0];
      EndPt := Points[PointCount - 1];
      if Assigned(Source) then
      begin
        if gloFixedAnchorStartPoint in LinkOptions then
          fPoints[0] := Source.FixHookAnchor
        else if not Assigned(Target) or (PointCount > 2) then
          fPoints[0] := Source.RelativeHookAnchor(fPoints[1])
        else
        begin
          fPoints[0] := Source.RelativeHookAnchor(Target.FixHookAnchor);
          if Target is TGraphLink then Recheck := True;
        end;
      end;
      if Assigned(Target) then
      begin
        if gloFixedAnchorEndPoint in LinkOptions then
          fPoints[PointCount - 1] := Target.FixHookAnchor
        else if not Assigned(Source) or (PointCount > 2) then
          fPoints[PointCount - 1] := Target.RelativeHookAnchor(fPoints[PointCount - 2])
        else
        begin
          fPoints[PointCount - 1] := Target.RelativeHookAnchor(Source.FixHookAnchor);
          if Source is TGraphLink then Recheck := True;
        end;
      end;
      RecheckCount := 0;
      while Recheck and (RecheckCount < 5) do
      begin
        Recheck := False;
        OldPt := fPoints[0];
        fPoints[0] := Source.RelativeHookAnchor(fPoints[1]);
        Recheck := Recheck or not EqualPoint(OldPt, fPoints[0]);
        OldPt := fPoints[PointCount - 1];
        fPoints[PointCount - 1] := Target.RelativeHookAnchor(fPoints[PointCount - 2]);
        Recheck := Recheck or not EqualPoint(OldPt, fPoints[PointCount - 1]);
        Inc(RecheckCount);
      end;
      if not EqualPoint(StartPt, Points[0]) or not EqualPoint(EndPt, Points[PointCount - 1]) then
        Changed([gcView, gcText, gcPlacement]);
    finally
      UpdatingEndPoints := False;
    end;
  end;
end;

function TGraphLink.UpdateTextPlacement(Recalc: Boolean; dX, dY: Integer): Boolean;
begin
  Result := False;
  if Recalc then
  begin
    if fTextRegion <> 0 then
    begin
      DeleteObject(TextRegion);
      fTextRegion := 0;
    end;
    fTextRegion := CreateTextRegion;
    Result := True;
  end
  else if fTextRegion <> 0 then
  begin
    Inc(fTextCenter.X, dX);
    Inc(fTextCenter.Y, dY);
    OffsetRgn(fTextRegion, dX, dY);
    Result := True;
  end;
end;

function TGraphLink.CreateTextRegion: HRGN;
const
  DrawTextFlags = DT_NOPREFIX or DT_END_ELLIPSIS or DT_EDITCONTROL or
                  DT_MODIFYSTRING or DT_CALCRECT;
var
  RgnPts: array[1..4] of TPoint;
  StartMargin, EndMargin: Integer;
  LineWidth, Distance: Integer;
  TextRect: TRect;
  Canvas: TCanvas;
begin
  Result := 0;
  fTextToShow := '';
  if (Text <> '') and (PointCount >= 2) then
  begin
    fTextLine := TextPosition;
    if (fTextLine < 0) or (fTextLine >= PointCount - 1) then
    begin
      fTextLine := IndexOfLongestLine;
      if fTextLine < 0 then Exit;
    end;
    StartMargin := Pen.Width + 1;
    if fTextLine = 0 then
      Inc(StartMargin, PointStyleOffset(BeginStyle, BeginSize));
    EndMargin := Pen.Width + 1;
    if fTextLine = PointCount - 2 then
      Inc(EndMargin, PointStyleOffset(EndStyle, EndSize));
    fTextCenter := CenterOfPoints([fPoints[fTextLine], fPoints[fTextLine + 1]]);
    fTextAngle := LineSlopeAngle(fPoints[fTextLine], fPoints[fTextLine + 1]);
    LineWidth := Trunc(LineLength(fPoints[fTextLine], fPoints[fTextLine + 1]));
    Dec(LineWidth, StartMargin + EndMargin);
    if LineWidth > 0 then
    begin
      SetRect(TextRect, 0, 0, LineWidth, 0);
      SetString(fTextToShow, nil, Length(Text) + 8);
      StrCopy(PChar(fTextToShow), PChar(Text));
      Canvas := TCompatibleCanvas.Create;
      try
        Canvas.Font := Font;
        Windows.DrawText(Canvas.Handle, PChar(fTextToShow), Length(Text), TextRect,
          Owner.DrawTextBiDiModeFlags(DrawTextFlags));
      finally
        Canvas.Free;
      end;
      SetLength(fTextToShow, StrLen(PChar(fTextToShow)));
      Distance := TextSpacing + (Pen.Width + 1) div 2;
      if (TextAngle > Pi / 2) or (TextAngle < -Pi / 2) then
        Distance := TextRect.Top + Distance
      else
        Distance := TextRect.Top - Distance;
      fTextCenter := NextPointOfLine(TextAngle - Pi / 2, fTextCenter, Distance);
      fTextCenter := NextPointOfLine(TextAngle, fTextCenter, (EndMargin - StartMargin) div 2);
      OffsetRect(TextRect, fTextCenter.X - TextRect.Right div 2, fTextCenter.Y - TextRect.Bottom);
      RgnPts[1] := TextRect.TopLeft;
      RgnPts[2] := Point(TextRect.Right, TextRect.Top);
      RgnPts[3] := TextRect.BottomRight;
      RgnPts[4] := Point(TextRect.Left, TextRect.Bottom);
      if Abs(TextAngle) > Pi / 2 then
        RotatePoints(RgnPts, TextAngle - Pi, TextCenter)
      else
        RotatePoints(RgnPts, TextAngle, TextCenter);
      Result := CreatePolygonRgn(RgnPts, 4, ALTERNATE);
    end;
  end;
end;

function TGraphLink.HookedPointCount: Integer;
begin
  Result := 0;
  if Assigned(Source) then
    Inc(Result);
  if Assigned(Target) then
    Inc(Result);
end;

function TGraphLink.IsFixedPoint(Index: Integer; HookedPointsAsFixed: Boolean): Boolean;
begin
  if (Index > 0) and (Index < PointCount - 1) then
    Result := (gloFixedBreakPoints in LinkOptions)
  else if (Index = 0) and (gloFixedStartPoint in LinkOptions) then
    Result := True
  else if (Index = PointCount - 1) and (gloFixedEndPoint in LinkOptions) then
    Result := True
  else if HookedPointsAsFixed and IsHookedPoint(Index) then
    Result := True
  else
    Result := False;
end;

function TGraphLink.IsHookedPoint(Index: Integer): Boolean;
begin
  Result := Assigned(HookedObjectOf(Index));
end;

function TGraphLink.HookedObjectOf(Index: Integer): TGraphObject;
begin
  if Index = PointCount - 1 then
    Result := Target
  else if Index = 0 then
    Result := Source
  else
    Result := nil;
end;

function TGraphLink.HookedIndexOf(GraphObject: TGraphObject): Integer;
begin
  Result := -1;
  if Assigned(GraphObject) then
  begin
    if GraphObject = Source then
      Result := 0
    else if GraphObject = Target then
      Result := PointCount - 1;
  end;
end;

function TGraphLink.AddPoint(const Pt: TPoint): Integer;
begin
  Unhook(Target);
  if Length(fPoints) = fPointCount then
    SetLength(fPoints, fPointCount + 1);
  Result := fPointCount;
  fPoints[Result] := Pt;
  Inc(fPointCount);
  Changed([gcView, gcData, gcText, gcPlacement]);
end;

procedure TGraphLink.InsertPoint(Index: Integer; const Pt: TPoint);
var
  I: Integer;
begin
  if Index < 0 then
  begin
    Index := 0;
    Unhook(Index);
  end
  else if Index > fPointCount then
    Index := fPointCount;
  if Length(fPoints) = fPointCount then
    SetLength(fPoints, fPointCount + 1);
  for I := fPointCount - 1 downto Index do
    fPoints[I + 1] := fPoints[I];
  fPoints[Index] := Pt;
  Inc(fPointCount);
  Changed([gcView, gcData, gcText, gcPlacement]);
end;

procedure TGraphLink.RemovePoint(Index: Integer);
var
  I: Integer;
begin
  if (Index >= 0) and (Index < fPointCount) then
  begin
    Unhook(Index);
    for I := Index to fPointCount - 2 do
      fPoints[I] := fPoints[I + 1];
    Dec(fPointCount);
    SetLength(fPoints, fPointCount);
    Changed([gcView, gcData, gcText, gcPlacement]);
  end;
end;

function TGraphLink.IndexOfPoint(const Pt: TPoint; Neighborhood: Integer): Integer;
var
  I: Integer;
  NeighborhoodArea: TRect;
begin
  Result := -1;
  NeighborhoodArea := MakeSquare(Pt, Neighborhood);
  for I := 0 to fPointCount - 1 do
    if PtInRect(NeighborhoodArea, fPoints[I]) then
    begin
      Result := I;
      Break;
    end;
end;

function TGraphLink.AddBreakPoint(const Pt: TPoint): Integer;
begin
  Result := IndexOfNearestLine(Pt, Pen.Width div 2 + Owner.MarkerSize) + 1;
  if Result > 0 then InsertPoint(Result, Pt);
end;

function TGraphLink.NormalizeBreakPoints(Options: TLinkNormalizeOptions): Boolean;
var
  I: Integer;
  Neighborhood: Integer;
  LastAngle, Angle: Double;
begin
  Result := False;
  if (PointCount > 2) and (Options <> []) then
  begin
    BeginUpdate;
    try
      // Delete breakpoints on same point
      if lnoDeleteSamePoint in Options then
      begin
        Neighborhood := NeighborhoodRadius;
        I := 1;
        while I < PointCount do
        begin
          if LineLength(Points[I - 1], Points[I]) <= Neighborhood then
          begin
            if I = PointCount - 1 then
              RemovePoint(I - 1)
            else
              RemovePoint(I);
            Result := True;
          end
          else
            Inc(I);
        end;
      end;
      // Delete breakpoints on a straight line
      if lnoDeleteSameAngle in Options then
      begin
        LastAngle := LineSlopeAngle(Points[0], Points[1]);
        I := 2;
        while I < PointCount do
        begin
          Angle := LineSlopeAngle(Points[I - 1], Points[I]);
          if Abs(Angle - LastAngle) < 0.05 * Pi then
          begin
            if I = PointCount - 1 then
              RemovePoint(I - 1)
            else
              RemovePoint(I);
            Result := True;
          end
          else
            Inc(I);
          LastAngle := Angle;
        end;
      end;
    finally
      EndUpdate;
    end;
  end;
end;

function TGraphLink.CanMove: Boolean;
begin
  Result := not Assigned(Source) and not Assigned(Target) and
    not (gloFixedStartPoint in LinkOptions) and
    not (gloFixedBreakPoints in LinkOptions) and
    not (gloFixedEndPoint in LinkOptions);
end;

function TGraphLink.Rotate(const Angle: Double; const Origin: TPoint): Boolean;
var
  NewPolyline: TPoints;
begin
  Result := False;
  if CanMove and (PointCount > 1) then
  begin
    NewPolyline := Copy(Polyline, 0, PointCount);
    try
      RotatePoints(NewPolyline, Angle, Origin);
      if Owner.GraphConstraints.WithinBounds(NewPolyline) then
      begin
        Polyline := NewPolyline;
        Result := True;
      end;
    finally
      SetLength(NewPolyline, 0);
    end;
  end;
end;

function TGraphLink.Scale(const Factor: Double): Boolean;
var
  NewPolyline: TPoints;
begin
  Result := False;
  if CanMove and (PointCount > 1) then
  begin
    NewPolyline := Copy(Polyline, 0, PointCount);
    try
      ScalePoints(NewPolyline, Factor, CenterOfPoints(NewPolyline));
      if Owner.GraphConstraints.WithinBounds(NewPolyline) then
      begin
        Polyline := NewPolyline;
        Result := True;
      end;
    finally
      SetLength(NewPolyline, 0);
    end;
  end;
end;

procedure TGraphLink.Reverse;
var
  GraphObject: TGraphObject;
  GraphObjectID: Integer;
  Pt: TPoint;
  I: Integer;
begin
  GraphObject := fSource;
  GraphObjectID := SourceID;
  fSource := fTarget;
  SourceID := TargetID;
  fTarget := GraphObject;
  TargetID := GraphObjectID;
  if (fTextPosition >= 0) and (PointCount > 2) then
    fTextPosition := PointCount - 2 - fTextPosition;
  for I := 0 to (PointCount div 2) - 1 do
  begin
    Pt := fPoints[I];
    fPoints[I] := fPoints[PointCount - 1 - I];
    fPoints[PointCount - 1 - I] := Pt;
  end;
  Changed([gcView, gcData, gcPlacement]);
end;

procedure TGraphLink.SetSource(Value: TGraphObject);
begin
  if Source <> Value then
  begin
    BeginUpdate;
    try
      Unhook(0);
      Hook(0, Value);
    finally
      EndUpdate;
    end;
  end;
end;

procedure TGraphLink.SetTarget(Value: TGraphObject);
begin
  if Target <> Value then
  begin
    BeginUpdate;
    try
      Unhook(PointCount - 1);
      Hook(PointCount - 1, Value);
    finally
      EndUpdate;
    end;
  end;
end;

procedure TGraphLink.SetLinkOptions(Value: TGraphLinkOptions);
begin
  if LinkOptions <> Value then
  begin
    fLinkOptions := Value;
    Changed([gcView, gcData, gcPlacement]);
  end;
end;

procedure TGraphLink.SetTextPosition(Value: Integer);
begin
  if TextPosition <> Value then
  begin
    fTextPosition := Value;
    Changed([gcView, gcData, gcText]);
  end;
end;

procedure TGraphLink.SetTextSpacing(Value: Integer);
begin
  if TextSpacing <> Value then
  begin
    fTextSpacing := Value;
    Changed([gcView, gcData, gcText]);
  end;
end;

procedure TGraphLink.SetBeginStyle(Value: TLinkBeginEndStyle);
begin
  if BeginStyle <> Value then
  begin
    fBeginStyle := Value;
    Changed([gcView, gcData, gcText]);
  end;
end;

procedure TGraphLink.SetBeginSize(Value: Byte);
begin
  if BeginSize <> Value then
  begin
    fBeginSize := Value;
    Changed([gcView, gcData, gcText]);
  end;
end;

procedure TGraphLink.SetEndStyle(Value: TLinkBeginEndStyle);
begin
  if EndStyle <> Value then
  begin
    fEndStyle := Value;
    Changed([gcView, gcData, gcText]);
  end;
end;

procedure TGraphLink.SetEndSize(Value: Byte);
begin
  if EndSize <> Value then
  begin
    fEndSize := Value;
    Changed([gcView, gcData, gcText]);
  end;
end;

function TGraphLink.GetPoints(Index: Integer): TPoint;
begin
  if (Index < 0) or (Index >= PointCount) then
    raise EPointListError.CreateFmt('Invalid point index. (%d)', [Index]);
  Result := fPoints[Index];
end;

procedure TGraphLink.SetPoints(Index: Integer; const Value: TPoint);
begin
  if (Index < 0) or (Index >= PointCount) then
    raise EPointListError.CreateFmt('Invalid point index. (%d)', [Index]);
  if not EqualPoint(fPoints[Index], Value) then
  begin
    Unhook(Index);
    fPoints[Index] := Value;
    Changed([gcView, gcData, gcText, gcPlacement]);
  end;
end;

procedure TGraphLink.SetPolyline(const Value: TPoints);
begin
  if (PointCount <> Length(Value)) or ((PointCount > 0) and
      not CompareMem(@fPoints[0], @Value[0], PointCount * SizeOf(TPoint))) then
  begin
    fPointCount := Length(Value);
    fPoints := Copy(Value, 0, fPointCount);
    Unhook(Source);
    Unhook(Target);
    Changed([gcView, gcData, gcText, gcPlacement]);
  end;
end;

procedure TGraphLink.Loaded;
begin
  inherited Loaded;
  // Backward compatibility
  if (PointCount = 0) and Assigned(Source) and Assigned(Target) then
  begin
    Inc(fPointCount, 2);
    SetLength(fPoints, fPointCount);
    UpdateDependencies;
  end;
end;

procedure TGraphLink.ReplaceID(OldID, NewID: DWORD);
begin
  inherited ReplaceID(OldID, NewID);
  if (SourceID <> 0) and (SourceID = OldID) then
    SourceID := NewID;
  if (TargetID <> 0) and (TargetID = OldID) then
    TargetID := NewID;
end;

procedure TGraphLink.ReplaceObject(OldObject, NewObject: TGraphObject);
begin
  if Source = OldObject then
  begin
    fSource := NewObject;
    SourceID := NewObject.ID;
  end;
  if Target = OldObject then
  begin
    fTarget := NewObject;
    TargetID := NewObject.ID;
  end;
  inherited ReplaceObject(OldObject, NewObject);
end;

procedure TGraphLink.LookupDependencies;
var
  GraphObject: TGraphObject;
begin
  if (SourceID <> 0) and not Assigned(Source) then
  begin
    GraphObject := Owner.FindObjectByID(SourceID);
    if Assigned(GraphObject) then
    begin
      fSource := GraphObject;
      GraphObject.LinkOutputList.Add(Self);
    end;
  end;
  if (TargetID <> 0) and not Assigned(Target) then
  begin
    GraphObject := Owner.FindObjectByID(TargetID);
    if Assigned(GraphObject) then
    begin
      fTarget := GraphObject;
      GraphObject.LinkInputList.Add(Self);
    end;
  end;
  inherited LookupDependencies;
end;

procedure TGraphLink.NotifyDependents(Flag: TGraphDependencyChangeFlag);
begin
  if HookedPointCount > 0 then
    case Flag of
      gdcChanged:
        UpdateDependencies;
      gdcRemoved:
      begin
        Unhook(Source);
        Unhook(Target);
      end;
    end;
  inherited NotifyDependents(Flag);
end;

procedure TGraphLink.UpdateDependencyTo(GraphObject: TGraphObject;
  Flag: TGraphDependencyChangeFlag);
begin
  if HookedIndexOf(GraphObject) >= 0 then
    case Flag of
      gdcChanged:
        UpdateDependencies;
      gdcRemoved:
        Unhook(GraphObject);
    end;
  inherited UpdateDependencyTo(GraphObject, Flag);
end;

procedure TGraphLink.DefineProperties(Filer: TFiler);
begin
  inherited DefineProperties(Filer);
  Filer.DefineProperty('Source', ReadSource, WriteSource, Assigned(Source));
  Filer.DefineProperty('Target', ReadTarget, WriteTarget, Assigned(Target));
  Filer.DefineBinaryProperty('BreakPoints', ReadPoints, WritePoints, PointCount > 0);
  // For backward campatibility
  Filer.DefineProperty('FromNode', ReadFromNode, nil, False);
  Filer.DefineProperty('ToNode', ReadToNode, nil, False);
  Filer.DefineProperty('Kind', ReadKind, nil, False);
  Filer.DefineProperty('ArrowSize', ReadArrowSize, nil, False);
end;

procedure TGraphLink.ReadSource(Reader: TReader);
begin
  SourceID := Reader.ReadInteger;
end;

procedure TGraphLink.WriteSource(Writer: TWriter);
begin
  Writer.WriteInteger(SourceID);
end;

procedure TGraphLink.ReadTarget(Reader: TReader);
begin
  TargetID := Reader.ReadInteger;
end;

procedure TGraphLink.WriteTarget(Writer: TWriter);
begin
  Writer.WriteInteger(TargetID);
end;

procedure TGraphLink.ReadPoints(Stream: TStream);
begin
  Stream.Read(fPointCount, SizeOf(fPointCount));
  SetLength(fPoints, fPointCount);
  if fPointCount > 0 then
    Stream.Read(fPoints[0], fPointCount * SizeOf(fPoints[0]));
end;

procedure TGraphLink.WritePoints(Stream: TStream);
begin
  Stream.Write(fPointCount, SizeOf(fPointCount));
  if fPointCount > 0 then
    Stream.Write(fPoints[0], fPointCount * SizeOf(fPoints[0]));
end;

// Obsolete - for backward compatibility
procedure TGraphLink.ReadFromNode(Reader: TReader);
begin
  ReadSource(Reader);
end;

// Obsolete - for backward compatibility
procedure TGraphLink.ReadToNode(Reader: TReader);
begin
  ReadTarget(Reader);
end;

// Obsolete - for backward compatibility
procedure TGraphLink.ReadKind(Reader: TReader);
var
  Kind: String;
begin
  Kind := Reader.ReadIdent;
  if LowerCase(Kind) = 'lkundirected' then
    EndStyle := lsNone
  else if LowerCase(Kind) = 'lkbidirected' then
    BeginStyle := lsArrow;
end;

// Obsolete - for backward compatibility
procedure TGraphLink.ReadArrowSize(Reader: TReader);
var
  ArrowSize: Integer;
begin
  ArrowSize := Reader.ReadInteger;
  EndSize := ArrowSize + 2;
  EndSize := ArrowSize + 2;
end;

{ TGraphNode }

constructor TGraphNode.Create(AOwner: TSimpleGraph);
begin
  inherited Create(AOwner);
  fMargin := 8;
  fAlignment := taCenter;
  fLayout := tlCenter;
  fBackground := TPicture.Create;
  fBackground.OnChange := BackgroundChanged;
  fNodeOptions := [gnoMovable, gnoResizable, gnoShowBackground];
end;

constructor TGraphNode.CreateNew(AOwner: TSimpleGraph; const Bounds: TRect);
begin
  Create(AOwner);
  SetBoundsRect(Bounds);
end;

destructor TGraphNode.Destroy;
begin
  if Region <> 0 then
    DeleteObject(Region);
  fBackground.Free;
  inherited Destroy;
end;

procedure TGraphNode.Assign(Source: TPersistent);
begin
  BeginUpdate;
  try
    inherited Assign(Source);
    if Source is TGraphNode then
      with Source as TGraphNode do
      begin
        Self.Background := Background;
        Self.Alignment := Alignment;
        Self.Layout := Layout;
        Self.Margin := Margin;
        Self.NodeOptions := NodeOptions;
        Self.BackgroundMargins := BackgroundMargins;
        Self.SetBounds(Left, Top, Width, Height);
      end;
  finally
    EndUpdate;
  end;
end;

function TGraphNode.ContainsRect(const Rect: TRect): Boolean;
begin
  if Selected then
    Result := inherited ContainsRect(Rect)
  else
    Result := Showing and RectInRegion(Region, Rect);
end;

procedure TGraphNode.QueryVisualRect(out Rect: TRect);
var
  Margin: Integer;
begin
  Rect := BoundsRect;
  if Pen.Style <> psInsideFrame then
  begin
    Margin := Pen.Width div 2;
    InflateRect(Rect, Margin, Margin);
  end;
end;

function TGraphNode.QueryHitTest(const Pt: TPoint): DWORD;
var
  Neighborhood: Integer;
begin
  if Selected then
  begin
    Result := GHT_NOWHERE;
    Neighborhood := NeighborhoodRadius;
    if PtInRect(MakeSquare(Point(Left + Width, Top + Height), Neighborhood), Pt) then
      Result := GHT_BOTTOMRIGHT
    else if PtInRect(MakeSquare(Point(Left, Top + Height), Neighborhood), Pt) then
      Result := GHT_BOTTOMLEFT
    else if PtInRect(MakeSquare(Point(Left + Width, Top), Neighborhood), Pt) then
      Result := GHT_TOPRIGHT
    else if PtInRect(MakeSquare(Point(Left, Top), Neighborhood), Pt) then
      Result := GHT_TOPLEFT
    else if PtInRect(MakeSquare(Point(Left + Width div 2, Top + Height), Neighborhood), Pt) then
      Result := GHT_BOTTOM
    else if PtInRect(MakeSquare(Point(Left + Width, Top + Height div 2), Neighborhood), Pt) then
      Result := GHT_RIGHT
    else if PtInRect(MakeSquare(Point(Left, Top + Height div 2), Neighborhood), Pt) then
      Result := GHT_LEFT
    else if PtInRect(MakeSquare(Point(Left + Width div 2, Top), Neighborhood), Pt) then
      Result := GHT_TOP;
    if Result <> GHT_NOWHERE then Exit;
  end;
  Result := inherited QueryHitTest(Pt);
  if PtInRegion(Region, Pt.X, Pt.Y) then
    Result := Result or GHT_CLIENT;
  if (goShowCaption in Options) and PtInRect(TextRect, Pt) then
    Result := Result or GHT_CAPTION;
end;

procedure TGraphNode.SnapHitTestOffset(HT: DWORD; var dX, dY: Integer);
var
  Pt: TPoint;
begin
  if (HT and (GHT_BODY_MASK or GHT_SIDES_MASK)) <> 0 then
  begin
    Pt.X := Left;
    Pt.Y := Top;
    if (HT and (GHT_RIGHT or GHT_TOPRIGHT or GHT_BOTTOMRIGHT)) <> 0 then
      Inc(Pt.X, Width);
    if (HT and (GHT_BOTTOM or GHT_BOTTOMLEFT or GHT_BOTTOMRIGHT)) <> 0 then
      Inc(Pt.Y, Height);
    Owner.SnapOffset(Pt, dX, dY);
  end
  else
    inherited SnapHitTestOffset(HT, dX, dY);
end;

function TGraphNode.QueryMobility(HT: DWORD): TObjectSides;
const
  LeftSideHT   = GHT_BODY_MASK or GHT_LEFT or GHT_TOPLEFT or GHT_BOTTOMLEFT;
  TopSideHT    = GHT_BODY_MASK or GHT_TOP or GHT_TOPLEFT or GHT_TOPRIGHT;
  RightSideHT  = GHT_BODY_MASK or GHT_RIGHT or GHT_TOPRIGHT or GHT_BOTTOMRIGHT;
  BottomSideHT = GHT_BODY_MASK or GHT_BOTTOM or GHT_BOTTOMLEFT or GHT_BOTTOMRIGHT;
begin
  if (HT and (GHT_BODY_MASK or GHT_SIDES_MASK)) <> 0 then
  begin
    Result := [];
    if (HT and LeftSideHT) <> 0 then
      Include(Result, osLeft);
    if (HT and TopSideHT) <> 0 then
      Include(Result, osTop);
    if (HT and RightSideHT) <> 0 then
      Include(Result, osRight);
    if (HT and BottomSideHT) <> 0 then
      Include(Result, osBottom);
  end
  else
    Result := inherited QueryMobility(HT);
end;

function TGraphNode.OffsetHitTest(HT: DWORD; dX, dY: Integer): Boolean;
var
  OldWidth, OldHeight: Integer;
begin
  Result := False;
  case HT and (GHT_BODY_MASK or GHT_SIDES_MASK) of
    GHT_CLIENT, GHT_CAPTION, GHT_CLIENT or GHT_CAPTION:
      if gnoMovable in NodeOptions then
      begin
        SetBounds(Left + dX, Top + dY, Width, Height);
        Result := True;
      end;
    GHT_LEFT:
      if gnoResizable in NodeOptions then
      begin
        OldWidth := Width;
        SetBounds(Left, Top, Width - dX, Height);
        SetBounds(Left + (OldWidth - Width), Top, Width, Height);
        Result := True;
      end;
    GHT_RIGHT:
      if gnoResizable in NodeOptions then
      begin
        SetBounds(Left, Top, Width + dX, Height);
        Result := True;
      end;
    GHT_TOP:
      if gnoResizable in NodeOptions then
      begin
        OldHeight := Height;
        SetBounds(Left, Top, Width, Height - dY);
        SetBounds(Left, Top + (OldHeight - Height), Width, Height);
        Result := True;
      end;
    GHT_BOTTOM:
      if gnoResizable in NodeOptions then
      begin
        SetBounds(Left, Top, Width, Height + dY);
        Result := True;
      end;
    GHT_TOPLEFT:
      if gnoResizable in NodeOptions then
      begin
        OldWidth := Width;
        OldHeight := Height;
        SetBounds(Left, Top, Width - dX, Height - dY);
        SetBounds(Left + (OldWidth - Width), Top + (OldHeight - Height), Width, Height);
        Result := True;
      end;
    GHT_TOPRIGHT:
      if gnoResizable in NodeOptions then
      begin
        OldHeight := Height;
        SetBounds(Left, Top, Width + dX, Height - dY);
        SetBounds(Left, Top + (OldHeight - Height), Width, Height);
        Result := True;
      end;
    GHT_BOTTOMLEFT:
      if gnoResizable in NodeOptions then
      begin
        OldWidth := Width;
        SetBounds(Left, Top, Width - dX, Height + dY);
        SetBounds(Left + (OldWidth - Width), Top, Width, Height);
        Result := True;
      end;
    GHT_BOTTOMRIGHT:
      if gnoResizable in NodeOptions then
      begin
        SetBounds(Left, Top, Width + dX, Height + dY);
        Result := True;
      end;
  else
    inherited OffsetHitTest(HT, dX, dY);
  end;
end;

procedure TGraphNode.MoveBy(dX, dY: Integer);
begin
  SetBounds(Left + dX, Top + dY, Width, Height);
end;

function TGraphNode.QueryCursor(HT: DWORD): TCursor;
begin
  case HT of
    GHT_CLIENT, GHT_CAPTION, GHT_CLIENT or GHT_CAPTION:
      if (gnoMovable in NodeOptions) and not IsLocked then
        Result := crSizeAll
      else
        Result := crHandPoint;
    GHT_LEFT, GHT_RIGHT:
      if (gnoResizable in NodeOptions) and not IsLocked  then
        Result := crSizeWE
      else
        Result := crHandPoint;
    GHT_TOP, GHT_BOTTOM:
      if (gnoResizable in NodeOptions) and not IsLocked  then
        Result := crSizeNS
      else
        Result := crHandPoint;
    GHT_TOPLEFT, GHT_BOTTOMRIGHT:
      if (gnoResizable in NodeOptions) and not IsLocked  then
        Result := crSizeNWSE
      else
        Result := crHandPoint;
    GHT_TOPRIGHT, GHT_BOTTOMLEFT:
      if (gnoResizable in NodeOptions) and not IsLocked  then
        Result := crSizeNESW
      else
        Result := crHandPoint;
  else
    Result := inherited QueryCursor(HT);
  end;
end;

function TGraphNode.BeginFollowDrag(HT: DWORD): Boolean;
begin
  if (HT and (GHT_BODY_MASK or GHT_SIDES_MASK)) <> 0 then
    Result := inherited BeginFollowDrag(HT)
  else
    Result := False;
end;

function TGraphNode.CreateClipRgn(Canvas: TCanvas): HRGN;
var
  XForm: TXForm;
  DevExt: TSize;
  LogExt: TSize;
  Org: TPoint;
begin
  GetViewportExtEx(Canvas.Handle, DevExt);
  GetWindowExtEx(Canvas.Handle, LogExt);
  GetViewportOrgEx(Canvas.Handle, Org);
  with XForm do
  begin
    eM11 := DevExt.CX / LogExt.CX;
    eM12 := 0;
    eM21 := 0;
    eM22 := DevExt.CY / LogExt.CY;
    eDx := Org.X;
    eDy := Org.Y;
  end;
  Result := TransformRgn(Region, XForm);
end;

procedure TGraphNode.QueryMaxTextRect(out Rect: TRect);
var
  TextMargin: Integer;
begin
  Rect := BoundsRect;
  if Pen.Style = psInsideFrame then
    TextMargin := Margin + Pen.Width
  else
    TextMargin := Margin + Pen.Width div 2;
  InflateRect(Rect, -TextMargin, -TextMargin);
end;

procedure TGraphNode.QueryTextRect(out Rect: TRect);
const
  DrawTextFlags = DT_NOPREFIX or DT_EDITCONTROL or DT_CALCRECT;
var
  Offset: TPoint;
  MaxTextRect: TRect;
  Canvas: TCanvas;
begin
  TextToShow := '';
  if (Text <> '') then
  begin
    QueryMaxTextRect(MaxTextRect);
    OffsetRect(MaxTextRect, -Left, -Top);
    Canvas := TCompatibleCanvas.Create;
    try
      Canvas.Font := Font;
      TextToShow := MinimizeText(Canvas, Text, MaxTextRect);
      Rect := MaxTextRect;
      Windows.DrawText(Canvas.Handle, PChar(TextToShow), Length(TextToShow),
        Rect, Owner.DrawTextBiDiModeFlags(DrawTextFlags));
    finally
      Canvas.Free;
    end;
    if Rect.Right > MaxTextRect.Right then
      Rect.Right := MaxTextRect.Right;
    if Rect.Bottom > MaxTextRect.Bottom then
      Rect.Bottom := MaxTextRect.Bottom;
    case Alignment of
      taLeftJustify:
        Offset.X := 0;
      taRightJustify:
        Offset.X := MaxTextRect.Right - Rect.Right;
    else
      Offset.X := (MaxTextRect.Right - Rect.Right) div 2;
    end;
    case Layout of
      tlTop:
        Offset.Y := 0;
      tlBottom:
        Offset.Y := MaxTextRect.Bottom - Rect.Bottom;
    else
      Offset.Y := (MaxTextRect.Bottom - Rect.Bottom) div 2;
    end;
    OffsetRect(Rect, Left + Offset.X, Top + Offset.Y);
  end
  else
    FillChar(Rect, SizeOf(Rect), 0);
end;

procedure TGraphNode.DrawText(Canvas: TCanvas);
var
  DC: HDC;
  Rect: TRect;
  DrawTextFlags: Integer;
  BkMode, TextAlign: Integer;
begin
  if TextToShow <> '' then
  begin
    Rect := TextRect;
    DrawTextFlags := DT_NOPREFIX or DT_EDITCONTROL or DT_NOCLIP or
      TextAlignFlags[Alignment] or TextLayoutFlags[Layout];
    DC := Canvas.Handle;
    BkMode := SetBkMode(DC, TRANSPARENT);
    TextAlign := SetTextAlign(DC, TA_LEFT or TA_TOP);
    Windows.DrawText(DC, PChar(TextToShow), Length(TextToShow), Rect,
      Owner.DrawTextBiDiModeFlags(DrawTextFlags));
    SetTextAlign(DC, TextAlign);
    SetBkMode(DC, BkMode);
  end;
end;

procedure TGraphNode.DrawBackground(Canvas: TCanvas);
var
  ClipRgn: HRGN;
  Bitmap: TBitmap;
  Graphic: TGraphic;
  ImageRect: TRect;
begin
  if Background.Graphic <> nil then
  begin
    ImageRect.Left := Left + MulDiv(Width, BackgroundMargins.Left, 100);
    ImageRect.Top := Top + MulDiv(Height, BackgroundMargins.Top, 100);
    ImageRect.Right := Left + Width - MulDiv(Width, BackgroundMargins.Right, 100);
    ImageRect.Bottom := Top + Height - MulDiv(Height, BackgroundMargins.Bottom, 100);
    ClipRgn := CreateClipRgn(Canvas);
    try
      SelectClipRgn(Canvas.Handle, ClipRgn);
      try
        Graphic := Background.Graphic;
        Background.OnChange := nil;
        try
          if (Graphic is TMetafile) and (Canvas is TMetafileCanvas) and
             ((ImageRect.Left >= Screen.Width) or (ImageRect.Top >= Screen.Height)) then
          begin // Workaround Windows bug!
            Bitmap := TBitmap.Create;
            try
              Bitmap.Transparent := True;
              Bitmap.TransparentColor := Canvas.Brush.Color;
              Bitmap.Canvas.Brush.Color := Canvas.Brush.Color;
              Bitmap.Width := ImageRect.Right - ImageRect.Left;
              Bitmap.Height := ImageRect.Bottom - ImageRect.Top;
              Bitmap.PixelFormat := pf32bit;
              Bitmap.Canvas.StretchDraw(Rect(0, 0, Bitmap.Width, Bitmap.Height), Graphic);
              Canvas.Draw(ImageRect.Left, ImageRect.Top, Bitmap);
            finally
              Bitmap.Free;
            end;
          end
          else
            Canvas.StretchDraw(ImageRect, Graphic);
        finally
          Background.OnChange := BackgroundChanged;
        end;
      finally
        SelectClipRgn(Canvas.Handle, 0);
      end;
    finally
      DeleteObject(ClipRgn);
    end;
    Canvas.Brush.Style := bsClear;
    DrawBorder(Canvas);
  end;
end;

procedure TGraphNode.DrawControlPoints(Canvas: TCanvas);
var
  Enabled: Boolean;
begin
  Enabled := not Owner.LockNodes and (gnoResizable in NodeOptions);
  DrawControlPoint(Canvas, Point(Left, Top), Enabled);
  DrawControlPoint(Canvas, Point(Left + Width, Top), Enabled);
  DrawControlPoint(Canvas, Point(Left, Top + Height), Enabled);
  DrawControlPoint(Canvas, Point(Left + Width, Top + Height), Enabled);
  DrawControlPoint(Canvas, Point(Left + Width div 2, Top + Height), Enabled);
  DrawControlPoint(Canvas, Point(Left + Width, Top + Height div 2), Enabled);
  DrawControlPoint(Canvas, Point(Left, Top + Height div 2), Enabled);
  DrawControlPoint(Canvas, Point(Left + Width div 2, Top), Enabled);
end;

procedure TGraphNode.DrawHighlight(Canvas: TCanvas);
begin
  DrawBorder(Canvas);
end;

procedure TGraphNode.DrawBody(Canvas: TCanvas);
begin
  DrawBorder(Canvas);
  if gnoShowBackground in NodeOptions then
    DrawBackground(Canvas);
end;

function TGraphNode.UpdateTextPlacement(Recalc: Boolean; dX, dY: Integer): Boolean;
begin
  if Recalc then
    QueryTextRect(fTextRect)
  else
    OffsetRect(fTextRect, dX, dY);
  Result := True;
end;

procedure TGraphNode.Initialize;
begin
  if fRegion <> 0 then
    DeleteObject(fRegion);
  fRegion := CreateRegion;
  inherited Initialize;
end;

procedure TGraphNode.BoundsChanged(dX, dY, dCX, dCY: Integer);
begin
  if (dCX <> 0) or (dCY <> 0) then
  begin
    if fRegion <> 0 then
      DeleteObject(fRegion);
    fRegion := CreateRegion;
  end
  else if (dX <> 0) or (dY <> 0) then
    OffsetRgn(fRegion, dX, dY);
  inherited BoundsChanged(dX, dY, dCX, dCY);
end;

function TGraphNode.GetCenter: TPoint;
begin
  Result.X := Left + Width div 2;
  Result.Y := Top + Height div 2;
end;

function TGraphNode.FixHookAnchor: TPoint;
begin
  Result := Center;
end;

function TGraphNode.RelativeHookAnchor(RefPt: TPoint): TPoint;
var
  Angle: Double;
  Intersects: TPoints;
begin
  Result := FixHookAnchor;
  if not PtInRegion(Region, RefPt.X, RefPt.Y) then
  begin
    Angle := LineSlopeAngle(RefPt, Result);
    Intersects := LinkIntersect(RefPt, Angle);
    try
      if NearestPoint(Intersects, RefPt, Result) < 0 then
        Result := FixHookAnchor;
    finally
      SetLength(Intersects, 0);
    end;
  end;
end;

procedure TGraphNode.CanMoveResize(var NewLeft, NewTop, NewWidth, NewHeight: Integer;
  out CanMove, CanResize: Boolean);
begin
  CanMove := (gnoMovable in NodeOptions);
  CanResize := (gnoResizable in NodeOptions);
  if NewWidth < Owner.MinNodeSize then
    NewWidth := Owner.MinNodeSize;
  if NewHeight < Owner.MinNodeSize then
    NewHeight := Owner.MinNodeSize;
  with Owner.GraphConstraints do
  begin
    if NewLeft < BoundsRect.Left then
      NewLeft := BoundsRect.Left;
    if NewTop < BoundsRect.Top then
      NewTop := BoundsRect.Top;
    if NewLeft + NewWidth > BoundsRect.Right then
      if NewWidth = Width then
        NewLeft := BoundsRect.Right - NewWidth
      else
        NewWidth := BoundsRect.Right - NewLeft;
    if NewTop + NewHeight > BoundsRect.Bottom then
      if NewHeight = Height then
        NewTop := BoundsRect.Bottom - NewHeight
      else
        NewHeight := BoundsRect.Bottom - NewTop;
  end;
  Owner.DoCanMoveResizeNode(Self, NewLeft, NewTop, NewWidth, NewHeight, CanMove, CanResize);
end;

procedure TGraphNode.SetBounds(aLeft, aTop, aWidth, aHeight: Integer);
var
  CanMove, CanResize: Boolean;
  dX, dY, dCX, dCY: Integer;
begin
  CanMoveResize(aLeft, aTop, aWidth, aHeight, CanMove, CanResize);
  if CanMove or CanResize then
  begin
    dX := 0;
    dY := 0;
    if CanMove then
    begin
      dX := aLeft - fLeft;
      fLeft := aLeft;
      dY := aTop - fTop;
      fTop := aTop;
    end;
    dCX := 0;
    dCY := 0;
    if CanResize then
    begin
      dCX := aWidth - fWidth;
      fWidth := aWidth;
      dCY := aHeight - fHeight;
      fHeight := aHeight;
    end;
    if (dX <> 0) or (dY <> 0) or (dCX <> 0) or (dCY <> 0) then
    begin
      BoundsChanged(dX, dY, dCX, dCY);
      Owner.DoNodeMoveResize(Self);
    end;
  end;
end;

procedure TGraphNode.SetBoundsRect(const Rect: TRect);
begin
  with Rect do SetBounds(Left, Top, Right - Left, Bottom - Top);
end;

function TGraphNode.GetBoundsRect: TRect;
begin
  Result.Left := Left;
  Result.Top := Top;
  Result.Right := Left + Width;
  Result.Bottom := Top + Height;
end;

procedure TGraphNode.SetLeft(Value: Integer);
begin
  if osReading in States then
    fLeft := Value
  else if Left <> Value then
    SetBounds(Value, Top, Width, Height);
end;

procedure TGraphNode.SetTop(Value: Integer);
begin
  if osReading in States then
    fTop := Value
  else if Top <> Value then
    SetBounds(Left, Value, Width, Height);
end;

procedure TGraphNode.SetWidth(Value: Integer);
begin
  if osReading in States then
    fWidth := Value
  else if Width <> Value then
    SetBounds(Left, Top, Value, Height);
end;

procedure TGraphNode.SetHeight(Value: Integer);
begin
  if osReading in States then
    fHeight := Value
  else if Height <> Value then
    SetBounds(Left, Top, Width, Value);
end;

procedure TGraphNode.SetAlignment(Value: TAlignment);
begin
  if Alignment <> Value then
  begin
    fAlignment := Value;
    Changed([gcView, gcData, gcText]);
  end;
end;

procedure TGraphNode.SetLayout(Value: TTextLayout);
begin
  if Layout <> Value then
  begin
    fLayout := Value;
    Changed([gcView, gcData, gcText]);
  end;
end;

procedure TGraphNode.SetMargin(Value: Integer);
begin
  if Margin <> Value then
  begin
    fMargin := Value;
    Changed([gcView, gcData, gcText]);
  end;
end;

procedure TGraphNode.SetNodeOptions(Value: TGraphNodeOptions);
begin
  if NodeOptions <> Value then
  begin
    fNodeOptions := Value;
    Changed([gcView, gcData]);
  end;
end;

procedure TGraphNode.SetBackground(Value: TPicture);
begin
  if fBackground <> Value then
    fBackground.Assign(Value);
end;

procedure TGraphNode.SetBackgroundMargins(const Value: TRect);
begin
  if not EqualRect(BackgroundMargins, Value) then
  begin
    fBackgroundMargins := Value;
    Changed([gcView, gcData]);
  end;
end;

procedure TGraphNode.BackgroundChanged(Sender: TObject);
begin
  Changed([gcView, gcData]);
end;

procedure TGraphNode.DefineProperties(Filer: TFiler);
begin
  inherited DefineProperties(Filer);
  Filer.DefineProperty('BackgroundMargins', ReadBackgroundMargins, WriteBackgroundMargins,
    not EqualRect(BackgroundMargins, Rect(0, 0, 0, 0)));
end;

procedure TGraphNode.ReadBackgroundMargins(Reader: TReader);
var
  R: TRect;
begin
  R.Left := Reader.ReadInteger;
  R.Top := Reader.ReadInteger;
  R.Right := Reader.ReadInteger;
  R.Bottom := Reader.ReadInteger;
  BackgroundMargins := R;
end;

procedure TGraphNode.WriteBackgroundMargins(Writer: TWriter);
begin
  with BackgroundMargins do
  begin
    Writer.WriteInteger(Left);
    Writer.WriteInteger(Top);
    Writer.WriteInteger(Right);
    Writer.WriteInteger(Bottom);
  end;
end;

{ TPlygonalNode }

destructor TPolygonalNode.Destroy;
begin
  SetLength(fVertices, 0);
  inherited Destroy;
end;

procedure TPolygonalNode.Initialize;
begin
  DefineVertices(BoundsRect, fVertices);
  inherited Initialize;
end;

procedure TPolygonalNode.BoundsChanged(dX, dY, dCX, dCY: Integer);
begin
  if (dCX <> 0) or (dCY <> 0) then
    DefineVertices(BoundsRect, fVertices)
  else if (dX <> 0) or (dY <> 0) then
    OffsetPoints(fVertices, dX, dY);
  inherited BoundsChanged(dX, dY, dCX, dCY);
end;

function TPolygonalNode.LinkIntersect(const LinkPt: TPoint; const LinkAngle: Double): TPoints;
begin
  Result := IntersectLinePolygon(LinkPt, LinkAngle, Vertices);
end;

function TPolygonalNode.GetCenter: TPoint;
begin
  Result := CenterOfPoints(Vertices);
end;

function TPolygonalNode.CreateRegion: HRGN;
begin
  Result := CreatePolygonRgn(Vertices[0], Length(Vertices), WINDING);
end;

procedure TPolygonalNode.DrawBorder(Canvas: TCanvas);
begin
  Canvas.Polygon(Vertices);
end;

{ TRectangularNode }

procedure TRectangularNode.DefineVertices(const ARect: TRect; var Points: TPoints);
begin
  SetLength(Points, 4);
  Points[0].X := ARect.Left;
  Points[0].Y := ARect.Top;
  Points[1].X := ARect.Right;
  Points[1].Y := ARect.Top;
  Points[2].X := ARect.Right;
  Points[2].Y := ARect.Bottom;
  Points[3].X := ARect.Left;
  Points[3].Y := ARect.Bottom;
end;

{ TRoundRectangularNode }

function TRoundRectangularNode.LinkIntersect(const LinkPt: TPoint; const LinkAngle: Double): TPoints;
var
  S: Integer;
begin
  if Width > Height then S := Width div 4 else S := Height div 4;
  Result := IntersectLineRoundRect(LinkPt, LinkAngle, BoundsRect, S, S);
end;

function TRoundRectangularNode.CreateRegion: HRGN;
var
  S: Integer;
begin
  if Width > Height then S := Width div 4 else S := Height div 4;
  Result := CreateRoundRectRgn(Left, Top, Left + Width + 1, Top + Height + 1, S, S);
end;

procedure TRoundRectangularNode.DrawBorder(Canvas: TCanvas);
var
  S: Integer;
begin
  if Width > Height then S := Width div 4 else S := Height div 4;
  Canvas.RoundRect(Left, Top, Left + Width, Top + Height, S, S);
end;

{ TEllipticNode }

function TEllipticNode.LinkIntersect(const LinkPt: TPoint; const LinkAngle: Double): TPoints;
begin
  Result := IntersectLineEllipse(LinkPt, LinkAngle, BoundsRect);
end;

function TEllipticNode.CreateRegion: HRGN;
begin
  Result := CreateEllipticRgn(Left, Top, Left + Width + 1, Top + Height + 1);
end;

procedure TEllipticNode.DrawBorder(Canvas: TCanvas);
begin
  Canvas.Ellipse(Left, Top, Left + Width, Top + Height);
end;

{ TTriangularNode }

procedure TTriangularNode.QueryMaxTextRect(out Rect: TRect);
var
  R: TRect;
begin
  with Rect do
  begin
    Left := (Vertices[0].X + Vertices[2].X) div 2;
    Top := (Vertices[0].Y + Vertices[2].Y) div 2;
    Right := (Vertices[0].X + Vertices[1].X) div 2;
    Bottom := Vertices[1].Y;
  end;
  inherited QueryMaxTextRect(R);
  IntersectRect(Rect, R);
end;

procedure TTriangularNode.DefineVertices(const ARect: TRect; var Points: TPoints);
begin
  SetLength(Points, 3);
  with ARect do
  begin
    with Points[0] do
    begin
      X := (Left + Right) div 2;
      Y := Top;
    end;
    with Points[1] do
    begin
      X := Right;
      Y := Bottom;
    end;
    with Points[2] do
    begin
      X := Left;
      Y := Bottom;
    end;
  end;
end;

{ TRhomboidalNode }

procedure TRhomboidalNode.QueryMaxTextRect(out Rect: TRect);
var
  R: TRect;
begin
  with Rect do
  begin
    Left := (Vertices[0].X + Vertices[3].X) div 2;
    Top := (Vertices[0].Y + Vertices[3].Y) div 2;
    Right := (Vertices[1].X + Vertices[2].X) div 2;
    Bottom := (Vertices[1].Y + Vertices[2].Y) div 2;
  end;
  inherited QueryMaxTextRect(R);
  IntersectRect(Rect, R);
end;

procedure TRhomboidalNode.DefineVertices(const ARect: TRect; var Points: TPoints);
begin
  SetLength(Points, 4);
  with ARect do
  begin
    with Points[0] do
    begin
      X := (Left + Right) div 2;
      Y := Top;
    end;
    with Points[1] do
    begin
      X := Right;
      Y := (Top + Bottom) div 2;
    end;
    with Points[2] do
    begin
      X := (Left + Right) div 2;
      Y := Bottom;
    end;
    with Points[3] do
    begin
      X := Left;
      Y := (Top + Bottom) div 2;
    end;
  end;
end;

{ TPentagonalNode }

procedure TPentagonalNode.QueryMaxTextRect(out Rect: TRect);
var
  R: TRect;
begin
  with Rect do
  begin
    Left := Vertices[3].X;
    Top := (Vertices[0].Y + Vertices[4].Y) div 2;
    Right := Vertices[2].X;
    Bottom := Vertices[2].Y;
  end;
  inherited QueryMaxTextRect(R);
  IntersectRect(Rect, R);
end;

procedure TPentagonalNode.DefineVertices(const ARect: TRect; var Points: TPoints);
begin
  SetLength(Points, 5);
  with ARect do
  begin
    with Points[0] do
    begin
      X := (Left + Right) div 2;
      Y := Top;
    end;
    with Points[1] do
    begin
      X := Right;
      Y := (Top + Bottom) div 2;
    end;
    with Points[2] do
    begin
      X := Right - (Right - Left) div 4;
      Y := Bottom;
    end;
    with Points[3] do
    begin
      X := Left + (Right - Left) div 4;
      Y := Bottom;
    end;
    with Points[4] do
    begin
      X := Left;
      Y := (Top + Bottom) div 2;
    end;
  end;
end;

{ THexagonalNode }

procedure THexagonalNode.QueryMaxTextRect(out Rect: TRect);
var
  R: TRect;
begin
  with Rect do
  begin
    Left := Vertices[0].X;
    Top := Vertices[0].Y;
    Right := Vertices[3].X;
    Bottom := Vertices[3].Y;
  end;
  inherited QueryMaxTextRect(R);
  IntersectRect(Rect, R);
end;

procedure THexagonalNode.DefineVertices(const ARect: TRect; var Points: TPoints);
begin
  SetLength(Points, 6);
  with ARect do
  begin
    with Points[0] do
    begin
      X := Left + (Right - Left) div 4;
      Y := Top;
    end;
    with Points[1] do
    begin
      X := Right - (Right - Left) div 4;
      Y := Top;
    end;
    with Points[2] do
    begin
      X := Right;
      Y := (Top + Bottom) div 2;
    end;
    with Points[3] do
    begin
      X := Right - (Right - Left) div 4;
      Y := Bottom;
    end;
    with Points[4] do
    begin
      X := Left + (Right - Left) div 4;
      Y := Bottom;
    end;
    with Points[5] do
    begin
      X := Left;
      Y := (Top + Bottom) div 2;
    end;
  end;
end;

{ TGraphConstraints }

constructor TGraphConstraints.Create(AOwner: TSimpleGraph);
begin
  inherited Create;
  fOwner := AOwner;
  fBoundsRect := Rect(0, 0, $0000FFFF, $0000FFFF);
end;

function TGraphConstraints.GetOwner: TPersistent;
begin
  Result := fOwner;
end;

procedure TGraphConstraints.DoChange;
begin
  if Assigned(Owner) then
  begin
    Owner.CalcAutoRange;
    Owner.Invalidate;
  end;
  if Assigned(OnChange) then
    OnChange(Self);
end;

procedure TGraphConstraints.Assign(Source: TPersistent);
begin
  if Source is TGraphConstraints then
    BoundsRect := TGraphConstraints(Source).BoundsRect
  else
    inherited Assign(Source);
end;

procedure TGraphConstraints.SetBounds(aLeft, aTop, aWidth, aHeight: Integer);
begin
  BoundsRect := Bounds(aLeft, aTop, aWidth, aHeight);
end;

function TGraphConstraints.WithinBounds(const Pts: array of TPoint): Boolean;
var
  I: Integer;
begin
  Result := True;
  for I := Low(Pts) to High(Pts) do
    if not PtInRect(BoundsRect, Pts[I]) then
    begin
      Result := False;
      Exit;
    end;
end;

function TGraphConstraints.ConfinePt(var Pt: TPoint): Boolean;
begin
  Result := True;
  if Pt.X < BoundsRect.Left then
  begin
    Pt.X := BoundsRect.Left;
    Result := False;
  end
  else if Pt.X > BoundsRect.Right then
  begin
    Pt.X := BoundsRect.Right;
    Result := False;
  end;
  if Pt.Y < BoundsRect.Top then
  begin
    Pt.Y := BoundsRect.Top;
    Result := False;
  end
  else if Pt.Y > BoundsRect.Bottom then
  begin
    Pt.Y := BoundsRect.Bottom;
    Result := False;
  end;
end;

function TGraphConstraints.ConfineRect(var Rect: TRect): Boolean;
begin
  Result := True;
  if Rect.Left < BoundsRect.Left then
  begin
    Rect.Left := BoundsRect.Left;
    Result := False;
  end;
  if Rect.Right > BoundsRect.Right then
  begin
    Rect.Right := BoundsRect.Right;
    Result := False;
  end;
  if Rect.Top < BoundsRect.Top then
  begin
    Rect.Top := BoundsRect.Top;
    Result := False;
  end;
  if Rect.Bottom > BoundsRect.Bottom then
  begin
    Rect.Bottom := BoundsRect.Bottom;
    Result := False;
  end;
end;

function TGraphConstraints.ConfineOffset(var dX, dY: Integer; Mobility: TObjectSides): Boolean;
begin
  with SourceRect do
  begin
    if (osLeft in Mobility) and (Left + dX < BoundsRect.Left) then
      dX := BoundsRect.Left - Left;
    if (osTop in Mobility) and (Top + dY < BoundsRect.Top) then
      dY := BoundsRect.Top - Top;
    if (osRight in Mobility) and (Right + dX > BoundsRect.Right) then
      dX := BoundsRect.Right - Right;
    if (osBottom in Mobility) and (Bottom + dY > BoundsRect.Bottom) then
      dY := BoundsRect.Bottom - Bottom;
  end;
  Result := (dX <> 0) or (dY <> 0);
end;

procedure TGraphConstraints.SetBoundsRect(const Rect: TRect);
begin
  if not EqualRect(BoundsRect, Rect) then
  begin
    fBoundsRect := Rect;
    DoChange;
  end;
end;

function TGraphConstraints.GetField(Index: Integer): Integer;
begin
  case Index of
    0: Result := BoundsRect.Left;
    1: Result := BoundsRect.Top;
    2: Result := BoundsRect.Right;
    3: Result := BoundsRect.Bottom;
  else
    Result := 0;
  end;
end;

procedure TGraphConstraints.SetField(Index, Value: Integer);
begin
  case Index of
    0: BoundsRect := Rect(Value, MinTop, MaxRight, MaxBottom);
    1: BoundsRect := Rect(MinLeft, Value, MaxRight, MaxBottom);
    2: BoundsRect := Rect(MinLeft, MinTop, Value, MaxBottom);
    3: BoundsRect := Rect(MinLeft, MinTop, MaxRight, Value);
  end;
end;

{ TSimpleGraph }

constructor TSimpleGraph.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := [csCaptureMouse, csClickEvents, csDoubleClicks, csOpaque, csAcceptsControls];
  UndoStorage := TMemoryStream.Create;
  fHorzScrollBar := TGraphScrollBar.Create(Self, sbHorizontal);
  fVertScrollBar := TGraphScrollBar.Create(Self, sbVertical);
  fGraphConstraints := TGraphConstraints.Create(Self);
  fCanvasRecall := TCanvasRecall.Create(nil);
  fObjects := TGraphObjectList.Create;
  fObjects.OnChange := ObjectListChanged;
  fSelectedObjects := TGraphObjectList.Create;
  fSelectedObjects.OnChange := SelectedListChanged;
  fDraggingObjects := TGraphObjectList.Create;
  fDraggingObjects.OnChange := DraggingListChanged;
  fGridSize := 8;
  fGridColor := clGray;
  fShowGrid := True;
  fSnapToGrid := True;
  fLockNodes := False;
  fLockLinks := False;
  fMarkerColor := clBlack;
  fMarkerSize := 3;
  fMinNodeSize := 16;
  fZoom := 100;
  fDefaultKeyMap := True;
  fCommandMode := cmEdit;
  fModified := False;
  fMarkedArea := EmptyRect;
  fClipboardFormats := [cfNative];
  if NodeClassCount > 0 then fDefaultNodeClass := NodeClasses(0);
  if LinkClassCount > 0 then fDefaultLinkClass := LinkClasses(0);

  
  {  }
  FDoubleBuffer := True;  
  Height:=400;
  Width:=600;
  FEditAreaIndex:=0;
  FBkColor:=clWhite;
  FLevel:=0;
  Kp:=1;
  FEditAreaList:=TEditAreaList.Create;
  Font.Name:='Times New Roman';
  Font.Charset:=DEFAULT_CHARSET;
  Font.Color:=clBlack;
  Font.OnChange := FontChanged;
  InsertEditArea;
  Font.Size:=20;

  Memo1 := TMemo.Create(self);
  memo1.Parent := self;
  memo1.Align := alright;
  memo1.Font.Size := 8;
  memo1.ScrollBars := ssVertical;
  memo1.ReadOnly := false;
  memo1.Width := 300;
  memo1.Show;
end;

destructor TSimpleGraph.Destroy;
begin
  Inc(SuspendQueryEvents);
  Inc(UpdateCount);
  fObjects.Free;
  fSelectedObjects.Free;
  fDraggingObjects.Free;
  fGraphConstraints.Free;
  fHorzScrollBar.Free;
  fVertScrollBar.Free;
  fCanvasRecall.Free;
  UndoStorage.Free;
  inherited Destroy;
end;

{$IFNDEF COMPILER5_UP}
procedure TSimpleGraph.WMContextMenu(var Msg: TMessage);
var
  Handled: Boolean;
  MousePos: TPoint;
begin
  Handled := False;
  MousePos.X := LoWord(Msg.LParam);
  MousePos.Y := HiWord(Msg.LParam);
  MousePos := ScreenToClient(MousePos);
  DoContextPopup(MousePos, Handled);
  if Handled then
    Msg.Result := 1
  else
    inherited;
end;
{$ENDIF}

procedure TSimpleGraph.WMPaint(var Msg: TWMPaint);
var
  DC, MemDC: HDC;
  MemBitmap, OldBitmap: HBITMAP;
  PS: TPaintStruct;
  Width, Height: Integer;
  SavedDC: Integer;
begin
  if Msg.DC <> 0 then
    PaintHandler(Msg)
  else
  begin
    DC := BeginPaint(WindowHandle, PS);
    try
      Width := (PS.rcPaint.Right - PS.rcPaint.Left);
      Height := (PS.rcPaint.Bottom - PS.rcPaint.Top);
      MemDC := CreateCompatibleDC(DC);
      MemBitmap := CreateCompatibleBitmap(DC, Width, Height);
      OldBitmap := SelectObject(MemDC, MemBitmap);
      try
        if Transparent then
          CopyParentImage(Self, MemDC, PS.rcPaint.Left, PS.rcPaint.Top)
        else
          FillRect(MemDC, Rect(0, 0, Width, Height), Brush.Handle);
        SavedDC := SaveDC(MemDC);
        try
          AdjustDC(MemDC, @PS.rcPaint.TopLeft);
          PaintWindow(MemDC);
        finally
          RestoreDC(MemDC, SavedDC);
        end;
        if ControlCount > 0 then
        begin
          SavedDC := SaveDC(MemDC);
          try
            SetViewportOrgEx(MemDC, -PS.rcPaint.Left, -PS.rcPaint.Top, nil);
            PaintControls(MemDC, nil);
          finally
            RestoreDC(MemDC, SavedDC);
          end;
        end;
        BitBlt(DC, PS.rcPaint.Left, PS.rcPaint.Top, Width, Height, MemDC, 0, 0, SRCCOPY);
      finally
        SelectObject(MemDC, OldBitmap);
        DeleteObject(MemBitmap);
        DeleteDC(MemDC);
      end;
    finally
      EndPaint(WindowHandle, PS);
    end;
  end;
end;

procedure TSimpleGraph.WMPrint(var Msg: TWMPrint);
var
  Rect: TRect;
  SavedDC: Integer;
begin
  if Visible or not LongBool(Msg.Flags and PRF_CHECKVISIBLE) then
  begin
    if LongBool(Msg.Flags and PRF_ERASEBKGND) then
    begin
      if Transparent then
        CopyParentImage(Self, Msg.DC, 0, 0)
      else
      begin
        GetClipBox(Msg.DC, Rect);
        FillRect(Msg.DC, Rect, Brush.Handle);
      end;
    end;
    if LongBool(Msg.Flags and PRF_CLIENT) then
    begin
      SavedDC := SaveDC(Msg.DC);
      try
        AdjustDC(Msg.DC);
        PaintWindow(Msg.DC);
      finally
        RestoreDC(Msg.DC, SavedDC);
      end;
    end;
    if (ControlCount > 0) and LongBool(Msg.Flags and PRF_CHILDREN) then
    begin
      SavedDC := SaveDC(Msg.DC);
      try
        PaintControls(Msg.DC, nil);
      finally
        RestoreDC(Msg.DC, SavedDC);
      end;
    end;
  end;
end;

procedure TSimpleGraph.WMEraseBkgnd(var Msg: TWMEraseBkgnd);
begin
  Msg.Result := 1;
end;

procedure TSimpleGraph.WMWindowPosChanging(var Msg: TWMWindowPosChanging);
begin
  if Transparent then
    with Msg.WindowPos^ do
      flags := (flags or SWP_NOCOPYBITS) and not SWP_NOREDRAW;
  inherited;
end;

procedure TSimpleGraph.WMSize(var Msg: TWMSize);
begin
  UpdatingScrollBars := True;
  try
    CalcAutoRange;
  finally
    UpdatingScrollBars := False;
  end;
  if HorzScrollBar.Visible or VertScrollBar.Visible then
    UpdateScrollBars;
  inherited;
end;

procedure TSimpleGraph.WMHScroll(var Msg: TWMHScroll);
begin
  if (Msg.ScrollBar = 0) and HorzScrollBar.Visible then
  begin
    HorzScrollBar.ScrollMessage(Msg);
    Invalidate;
  end
  else
    inherited;
end;

procedure TSimpleGraph.WMVScroll(var Msg: TWMVScroll);
begin
  if (Msg.ScrollBar = 0) and VertScrollBar.Visible then
  begin
    VertScrollBar.ScrollMessage(Msg);
    Invalidate;
  end
  else
    inherited;
end;

procedure TSimpleGraph.CNKeyDown(var Msg: TWMKeyDown);
begin
  Mouse.CursorPos := Mouse.CursorPos; // To force cursor update
  if not (DefaultKeyMap and DefaultKeyHandler(Msg.CharCode, KeyDataToShiftState(Msg.KeyData))) then
    inherited;
end;

procedure TSimpleGraph.CNKeyUp(var Msg: TWMKeyUp);
begin
  inherited;
  Mouse.CursorPos := Mouse.CursorPos; // To force cursor update
end;

procedure TSimpleGraph.CMFontChanged(var Msg: TMessage);
var
  I: Integer;
begin
  inherited;
  BeginUpdate;
  try
    for I := 0 to Objects.Count - 1 do
      with Objects[I] do ParentFontChanged;
  finally
    EndUpdate;
  end;
end;

procedure TSimpleGraph.CMBiDiModeChanged(var Msg: TMessage);
var
  Save: Integer;
begin
  Save := Msg.WParam;
  try
    { prevent inherited from calling Invalidate & RecreateWnd }
    if not (Self is TSimpleGraph) then Msg.wParam := 1;
    inherited;
  finally
    Msg.wParam := Save;
  end;
  if HandleAllocated then
  begin
    HorzScrollBar.ChangeBiDiPosition;
    UpdateScrollBars;
  end;
end;

procedure TSimpleGraph.CMMouseLeave(var Msg: TMessage);
begin
  inherited;
  if (GetCapture <> WindowHandle) then
  begin
    RenewObjectAtCursor(nil);
    Screen.Cursor := crDefault;
  end;
end;

procedure TSimpleGraph.CMHintShow(var Msg: TCMHintShow);
var
  HintObject: TGraphObject;
begin
  inherited;
  with Msg.HintInfo^ do
  begin
    with ClientToGraph(CursorPos.X, CursorPos.Y) do
      HintObject := FindObjectAt(X, Y);
    if Assigned(HintObject) then
    begin
      if Assigned(OnInfoTip) or (HintObject.Hint <> '') or (HintObject.Text <> HintObject.TextToShow) then
      begin
        CursorRect := HintObject.VisualRect;
        GPToCP(CursorRect, 2);
        Application.Hint := HintObject.Hint;
        HintStr := GetShortHint(HintObject.Hint);
        if (HintStr = '') and (HintObject.Text <> HintObject.TextToShow) then
          HintStr := HintObject.Text;
        if Assigned(OnInfoTip) then
          OnInfoTip(Self, HintObject, HintStr);
      end;
    end;
  end;
end;

procedure TSimpleGraph.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  with Params.WindowClass do
    style := style and not (CS_HREDRAW or CS_VREDRAW);
end;

procedure TSimpleGraph.CreateWnd;
begin
  inherited CreateWnd;
  if not SysLocale.MiddleEast then
    InitializeFlatSB(WindowHandle);
  UpdateScrollBars;
end;

function TSimpleGraph.DefaultKeyHandler(var Key: Word; Shift: TShiftState): Boolean;
var
  GraphObject: TGraphObject;
  NewPos: Integer;
begin

  Result := False;
  if Assigned(DragSource) then
  begin
    GraphConstraints.SourceRect := DraggingBounds;
    Result := DragSource.KeyPress(Key, Shift);
  end
  else if not (CommandMode in [cmViewOnly, cmPan]) then
  begin
    GraphConstraints.SourceRect := SelectionBounds;
    BeginUpdate;
    try
      GraphObject := SelectedObjects.First;
      while Assigned(GraphObject) do
      begin
        SelectedObjects.Push;
        try
          if GraphObject.KeyPress(Key, Shift) then
            Result := True;
        finally
          SelectedObjects.Pop;
        end;
        GraphObject := SelectedObjects.Next;
      end;
    finally
      EndUpdate;
    end;
  end;
  if not Result then
    case Key of
      VK_TAB:
        if not (CommandMode in [cmViewOnly, cmPan]) then
        begin
          SelectNextObject(ssShift in Shift);
          Result := True;
        end;
      VK_LEFT, VK_RIGHT:
      begin
        with HorzScrollBar do
          if (CommandMode = cmPan) and IsScrollBarVisible then
          begin
            if Key = VK_LEFT then
              NewPos := Position - Increment
            else
              NewPos := Position + Increment;
            if NewPos < 0 then
              Position := 0
            else if NewPos > Range then
              Position := Range
            else
              Position := NewPos;
          end;
        Result := (CommandMode = cmPan);
      end;
      VK_UP, VK_DOWN:
      begin
        with VertScrollBar do
          if (CommandMode = cmPan) and IsScrollBarVisible then
          begin
            if Key = VK_UP then
              NewPos := Position - Increment
            else
              NewPos := Position + Increment;
            if NewPos < 0 then
              Position := 0
            else if NewPos > Range then
              Position := Range
            else
              Position := NewPos;
          end;
        Result := (CommandMode = cmPan);
      end;
    end;
end;

function TSimpleGraph.InsertObjectByMouse(var Pt: TPoint;
  GraphObjectClass: TGraphObjectClass; GridSnap: Boolean): TGraphObject;
var
  ObjectAtPt: TGraphObject;
  Rect: TRect;
begin
  Result := nil;
  if GraphObjectClass.IsLink then
  begin
    ObjectAtPt := FindObjectAt(Pt.X, Pt.Y);
    if Assigned(ObjectAtPt) then
      Result := InsertLink(ObjectAtPt, [Pt], TGraphLinkClass(GraphObjectClass));
    if not Assigned(Result) then
    begin
      if GridSnap then
        Pt := SnapPoint(Pt);
      if GraphConstraints.WithinBounds([Pt]) then
        Result := InsertLink([Pt, Pt], TGraphLinkClass(GraphObjectClass));
    end;
    if Assigned(Result) then
      Pt := TGraphLink(Result).Points[TGraphLink(Result).PointCount - 1];
  end
  else if GraphObjectClass.IsNode then
  begin
    if GridSnap then
      Pt := SnapPoint(Pt);
    if GraphConstraints.WithinBounds([Pt]) then
    begin
      Rect.TopLeft := Pt;
      if SnapToGrid and (MinNodeSize <= GridSize) then
      begin
        Rect.Right := Pt.X + GridSize;
        Rect.Bottom := Pt.Y + GridSize;
      end
      else
      begin
        Rect.Right := Pt.X + MinNodeSize;
        Rect.Bottom := Pt.Y + MinNodeSize;
        if SnapToGrid and ((MinNodeSize mod GridSize) <> 0) then
        begin
          Inc(Rect.Right, GridSize - (MinNodeSize mod GridSize));
          Inc(Rect.Bottom, GridSize - (MinNodeSize mod GridSize));
        end;
      end;
      GraphConstraints.ConfinePt(Rect.BottomRight);
      Result := InsertNode(Rect, TGraphNodeClass(GraphObjectClass));
      if Assigned(Result) then
        Pt := Result.BoundsRect.BottomRight;
    end;
  end;
end;

procedure TSimpleGraph.Print(Canvas: TCanvas; const Rect: TRect);
var
  GraphRect: TRect;
  Metafile: TMetafile;
  RectSize, GraphSize: TPoint;
begin
  GraphRect := GraphBounds;
  if not IsRectEmpty(GraphRect) then
  begin
    GraphSize.X := GraphRect.Right - GraphRect.Left;
    GraphSize.Y := GraphRect.Bottom - GraphRect.Top;
    RectSize.X := Rect.Right - Rect.Left;
    RectSize.Y := Rect.Bottom - Rect.Top;
    if (RectSize.X / GraphSize.X) < (RectSize.Y / GraphSize.Y) then
    begin
      GraphSize.Y := MulDiv(GraphSize.Y, RectSize.X, GraphSize.X);
      GraphSize.X := RectSize.X;
    end
    else
    begin
      GraphSize.X := MulDiv(GraphSize.X, RectSize.Y, GraphSize.Y);
      GraphSize.Y := RectSize.Y;
    end;
    SetRect(GraphRect, 0, 0, GraphSize.X, GraphSize.Y);
    OffsetRect(GraphRect,
      Rect.Left + (RectSize.X - GraphSize.X) div 2,
      Rect.Top + (RectSize.Y - GraphSize.Y) div 2);
    Metafile := GetAsMetafile(Canvas.Handle, Objects);
    try
      Canvas.StretchDraw(GraphRect, Metafile);
    finally
      Metafile.Free;
    end;
  end;
end;

procedure TSimpleGraph.Draw(Canvas: TCanvas);
begin
  DrawObjects(Canvas, Objects);
end;

procedure TSimpleGraph.DrawGrid(Canvas: TCanvas);

  function FirstGridPos(Pos: Integer): Integer;
  var
    M: Integer;
  begin
    M := Pos mod GridSize;
    if M < 0 then
      Result := GridSize + M
    else if M > 0 then
      Result := Pos + GridSize - M
    else if Pos < 0 then
      Result := 0
    else
      Result := Pos;
  end;

var
  DC: HDC;
  Rect: TRect;
  SX, SY: Integer;
  X, Y: Integer;
  DotColor: Integer;
begin
  Rect := Canvas.ClipRect;
  IntersectRect(Rect, GraphConstraints.BoundsRect);
  SX := FirstGridPos(Rect.Left);
  SY := FirstGridPos(Rect.Top);
  DotColor := ColorToRGB(GridColor);
  Canvas.Pen.Mode := pmCopy;
  DC := Canvas.Handle;
  Y := SY;
  while Y < Rect.Bottom do
  begin
    X := SX;
    while X < Rect.Right do
    begin
      SetPixel(DC, X, Y, DotColor);
      Inc(X, GridSize);
    end;
    Inc(Y, GridSize);
  end;
end;

procedure TSimpleGraph.DrawObjects(Canvas: TCanvas; ObjectList: TGraphObjectList);
var
  I: Integer;
begin
  DoBeforeDraw(Canvas);
  CanvasRecall.Reference := Canvas;
  try
    case DrawOrder of
      doNodesOnTop:
      begin
        for I := 0 to ObjectList.Count - 1 do
          with ObjectList[I] do if IsLink then Draw(Canvas);
        for I := 0 to ObjectList.Count - 1 do
          with ObjectList[I] do if IsNode then Draw(Canvas);
      end;
      doLinksOnTop:
      begin
        for I := 0 to ObjectList.Count - 1 do
          with ObjectList[I] do if IsNode then Draw(Canvas);
        for I := 0 to ObjectList.Count - 1 do
          with ObjectList[I] do if IsLink then Draw(Canvas);
      end;
    else
      for I := 0 to ObjectList.Count - 1 do
        ObjectList[I].Draw(Canvas);
    end;
  finally
    CanvasRecall.Reference := nil;
  end;
  DoAfterDraw(Canvas);
end;

procedure TSimpleGraph.DrawEditStates(Canvas: TCanvas);
var
  I: Integer;
begin
  if not HideSelection or Focused then
    for I := 0 to SelectedObjects.Count - 1 do
      with SelectedObjects[I] do
        DrawState(Canvas);
  if ValidMarkedArea and not IsRectEmpty(MarkedArea) then
  begin
    Canvas.Brush.Style := bsClear;
    Canvas.Pen.Mode := pmNot;
    Canvas.Pen.Style := psDot;
    Canvas.Pen.Width := 0;
    with MarkedArea do Canvas.Rectangle(Left, Top, Right, Bottom);
  end;
end;

procedure TSimpleGraph.Paint;
begin
  Canvas.Lock;
  try
    if ShowGrid then DrawGrid(Canvas);
    DrawObjects(Canvas, Objects);
    DrawEditStates(Canvas);
    if csDesigning in ComponentState then
      with Canvas do
      begin
        Brush.Style := bsClear;
        Brush.Color := FBkColor;
        Pen.Style := psInsideFrame;//psDash;
        Pen.Mode := pmCopy;
        Pen.Color := clBlack;
        Pen.Width := 0;
        with ClientRect do Rectangle(Left, Top, Right, Bottom);
      end;
  finally
    Canvas.Unlock;
  end;

  {
  Canvas.Pen.Style := psInsideFrame;
  Canvas.Pen.Color:=clBlack;
  Canvas.Brush.Style := bsClear;
  Canvas.Brush.Color := FBkColor;
  Canvas.Rectangle(0, 0, Width, Height);
  }
end;

procedure TSimpleGraph.ToggleSelection(const Rect: TRect; KeepOld: Boolean;
  GraphObjectClass: TGraphObjectClass);
var
  GraphObject: TGraphObject;
  I: Integer;
begin
  if not Assigned(GraphObjectClass) then
    GraphObjectClass := TGraphObject;
  for I := 0 to Objects.Count - 1 do
  begin
    GraphObject := Objects[I];
    if (GraphObject is GraphObjectClass) and GraphObject.ContainsRect(Rect) then
      GraphObject.Selected := not (KeepOld and GraphObject.Selected)
    else if not KeepOld then
      GraphObject.Selected := False;
  end;
end;

function TSimpleGraph.FindObjectAt(X, Y: Integer;
  LookAfter: TGraphObject = nil): TGraphObject;
var
  TopIndex, I: Integer;
  GraphObject: TGraphObject;
  HT: DWORD;
  Pt: TPoint;
begin
  Result := nil;
  if Assigned(LookAfter) then
    TopIndex := LookAfter.ZOrder
  else
    TopIndex := Objects.Count;
  Pt := Point(X, Y);
  for I := TopIndex - 1 downto 0 do
  begin
    GraphObject := Objects[I];
    if GraphObject <> DragSource then
    begin
      HT := GraphObject.HitTest(Pt);
      if HT <> GHT_NOWHERE then
      begin
        if not Assigned(Result) then
          Result := GraphObject;
        if SelectedObjects.Count = 0 then
          Exit
        else if GraphObject.Selected then
        begin
          if GraphObject = Result then
            Exit
          else if GraphObject.IsLink or ((HT and GHT_BODY_MASK) = 0) then
          begin
            Result := GraphObject;
            Exit;
          end;
        end;
      end;
    end;
  end;
end;

procedure TSimpleGraph.CheckObjectAtCursor(const Pt: TPoint);
begin
  if Assigned(DragSource) then
    RenewObjectAtCursor(DragSource)
  else
    RenewObjectAtCursor(FindObjectAt(Pt.X, Pt.Y));
end;

procedure TSimpleGraph.RenewObjectAtCursor(NewObjectAtCursor: TGraphObject);
begin
  if NewObjectAtCursor <> ObjectAtCursor then
  begin
    if Assigned(ObjectAtCursor) then
      DoObjectMouseLeave(ObjectAtCursor);
    fObjectAtCursor := NewObjectAtCursor;
    if Assigned(ObjectAtCursor) then
      DoObjectMouseEnter(ObjectAtCursor);
    if not Assigned(DragSource) then
      Application.CancelHint;
  end;
end;

procedure TSimpleGraph.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  Pt: TPoint;
  NewObject: TGraphObject;
begin
  if not Focused then SetFocus;
  inherited MouseDown(Button, Shift, X, Y);
  Pt := ClientToGraph(X, Y);
  CheckObjectAtCursor(Pt);
  case CommandMode of
    cmInsertNode, cmInsertLink:
      if Assigned(DragSource) then
        DragSource.MouseDown(Button, Shift, Pt)
      else if (Button = mbLeft) and not (ssDouble in Shift) then
      begin
        NewObject := nil;
        case CommandMode of
          cmInsertNode:
            NewObject := InsertObjectByMouse(Pt, DefaultNodeClass, SnapToGrid xor (ssCtrl in Shift));
          cmInsertLink:
            NewObject := InsertObjectByMouse(Pt, DefaultLinkClass, SnapToGrid xor (ssCtrl in Shift));
        end;
        if Assigned(NewObject) then
        begin
          NewObject.Selected := True;
          NewObject.MouseDown(Button, Shift, Pt);
          if DragSource <> NewObject then
          begin
            CommandMode := cmEdit;
            ObjectChanged(NewObject, [gcData]);
          end
          else
            CursorPos := Pt;
          RenewObjectAtCursor(NewObject);
        end;
      end;
    cmPan:
      if (Button = mbLeft) and not (ssDouble in SHift) then
      begin
        fDragSourcePt.X := X;
        fDragSourcePt.Y := Y;
        Screen.Cursor := crHandGrab
      end;
  else
    if Assigned(ObjectAtCursor) and (CommandMode <> cmViewOnly) and
      (goSelectable in ObjectAtCursor.Options)
    then
      ObjectAtCursor.MouseDown(Button, Shift, Pt)
    else if (Button = mbLeft) and not (ssDouble in Shift) then
    begin
      fDragSourcePt := Pt;
      fDragTargetPt := Pt;
      memo1.Lines.Add('simplegraph mousedown drag? area');
      MarkedArea := MakeRect(fDragSourcePt, fDragTargetPt);
      Screen.Cursor := crCross;
    end;
  end;
end;

procedure TSimpleGraph.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  Pt: TPoint;
  NewPos: Integer;
begin
  Pt := ClientToGraph(X, Y);
  CheckObjectAtCursor(Pt);
  if CommandMode = cmPan then  { ¼Õ¹Ù´Ú }
  begin
    if ssLeft in Shift then
    begin
      with HorzScrollBar do
        if IsScrollBarVisible then
        begin
          NewPos := Position + (fDragSourcePt.X - X);
          if NewPos < 0 then NewPos := 0 else if NewPos > Range then NewPos := Range;
          Position := NewPos;
          fDragSourcePt.X := X;
        end;
      with VertScrollBar do
        if IsScrollBarVisible then
        begin
          NewPos := Position + (fDragSourcePt.Y - Y);
          if NewPos < 0 then NewPos := 0 else if NewPos > Range then NewPos := Range;
          Position := NewPos;
          fDragSourcePt.Y := Y;
        end;
    end
    else
      Screen.Cursor := crHandFlat;
  end
  else if ValidMarkedArea then
  begin
    fDragTargetPt := Pt;
    MarkedArea := MakeRect(fDragSourcePt, fDragTargetPt);
    ScrollInView(fDragTargetPt);
  end
  else
  begin
    if Assigned(ObjectAtCursor) and (CommandMode <> cmViewOnly) then
      ObjectAtCursor.MouseMove(Shift, Pt)
    else if CommandMode in [cmInsertNode, cmInsertLink] then
      Screen.Cursor := crXHair1
    else
      Screen.Cursor := Cursor;
  end;
  inherited MouseMove(Shift, X, Y);
end;

procedure TSimpleGraph.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  Pt: TPoint;
begin
  Pt := ClientToGraph(X, Y);
  CheckObjectAtCursor(Pt);
  if CommandMode = cmPan then
  begin
    if Button = mbLeft then
      Screen.Cursor := crHandFlat;
  end
  else if ValidMarkedArea then
  begin
    if not (ssAlt in Shift) then
    begin
      if CommandMode = cmEdit then
      begin
        if ssCtrl in Shift then
          ToggleSelection(MarkedArea, ssShift in Shift, TGraphNode)
        else
          ToggleSelection(MarkedArea, ssShift in Shift, TGraphObject);
      end;
    end
    else if not IsRectEmpty(MarkedArea) then
      ZoomRect(MarkedArea);
    
    MarkedArea := Rect(MaxInt, MaxInt, -MaxInt, -MaxInt);
    Screen.Cursor := Cursor;
  end
  else
  begin
    if Assigned(ObjectAtCursor) and (CommandMode <> cmViewOnly) then
      ObjectAtCursor.MouseUp(Button, Shift, Pt)
    else
      Screen.Cursor := Cursor;
  end;
  inherited MouseUp(Button, Shift, X, Y);
end;

procedure TSimpleGraph.DoContextPopup(MousePos: TPoint; var Handled: Boolean);
begin
  if not Assigned(DragSource) then
  begin
    if SelectedObjects.Count > 0 then
    begin
      DoObjectContextPopup(SelectedObjects[0], MousePos, Handled);
      if not Handled and Assigned(ObjectPopupMenu) then
      begin
        with ClientToScreen(MousePos) do ObjectPopupMenu.Popup(X, Y);
        Handled := True;
      end;
    end;
    if not Handled then
    begin
      {$IFDEF COMPILER5_UP}
      inherited DoContextPopup(MousePos, Handled);
      {$ELSE}
      if Assigned(fOnContextPopup) then
        fOnContextPopup(Self, MousePos, Handled);
      {$ENDIF}
    end;
  end
  else
    Handled := True;
end;

procedure TSimpleGraph.Click;
begin
  if SelectedObjects.Count > 0 then
    DoObjectClick(SelectedObjects[0])
  else
    inherited Click;
end;

procedure TSimpleGraph.DblClick;
begin
  if not Assigned(DragSource) then
    if SelectedObjects.Count > 0 then
      DoObjectDblClick(SelectedObjects[0])
    else
      inherited DblClick;
end;

procedure TSimpleGraph.DoEnter;
begin
  inherited DoEnter;
  if HideSelection and (SelectedObjects.Count > 0) then
    InvalidateRect(SelectionBounds);
end;

procedure TSimpleGraph.DoExit;
begin
  inherited DoExit;
  if HideSelection and (SelectedObjects.Count > 0) then
    InvalidateRect(SelectionBounds);
end;

function TSimpleGraph.InsertNode(const Bounds: TRect;
  ANodeClass: TGraphNodeClass): TGraphNode;
begin
  if not Assigned(ANodeClass) then
    ANodeClass := DefaultNodeClass;
  try
    Result := ANodeClass.CreateNew(Self, Bounds);
  except
    Result := nil;
  end;
end;

function TSimpleGraph.InsertLink(Source, Target: TGraphObject;
  ALinkClass: TGraphLinkClass): TGraphLink;
begin
  if not Assigned(ALinkClass) then
    ALinkClass := DefaultLinkClass;
  try
    Result := ALinkClass.CreateNew(Self, Source, [], Target)
  except
    Result := nil;
  end;
end;

function TSimpleGraph.InsertLink(Source: TGraphObject; const Pts: array of TPoint;
  ALinkClass: TGraphLinkClass): TGraphLink;
begin
  if not Assigned(ALinkClass) then
    ALinkClass := DefaultLinkClass;
  try
    Result := ALinkClass.CreateNew(Self, Source, Pts, nil);
  except
    Result := nil;
  end;
end;

function TSimpleGraph.InsertLink(const Pts: array of TPoint; Target: TGraphObject;
  ALinkClass: TGraphLinkClass): TGraphLink;
begin
  if not Assigned(ALinkClass) then
    ALinkClass := DefaultLinkClass;
  try
    Result := ALinkClass.CreateNew(Self, nil, Pts, Target);
  except
    Result := nil;
  end;
end;

function TSimpleGraph.InsertLink(const Pts: array of TPoint;
  ALinkClass: TGraphLinkClass): TGraphLink;
begin
  if not Assigned(ALinkClass) then
    ALinkClass := DefaultLinkClass;
  try
    Result := ALinkClass.CreateNew(Self, nil, Pts, nil);
  except
    Result := nil;
  end;
end;

procedure TSimpleGraph.ScrollInView(GraphObject: TGraphObject);
begin
  if Assigned(GraphObject) then
    ScrollInView(GraphObject.SelectedVisualRect);
end;

procedure TSimpleGraph.ScrollInView(const Rect: TRect);
var
  Pt: TPoint;
begin
  Pt := Rect.TopLeft;
  with VisibleBounds do
  begin
    if ((Rect.Right - Rect.Left) <= (Right - Left)) and (Rect.Right > Right) then
      Pt.X := Rect.Right;
    if ((Rect.Bottom - Rect.Top) <= (Bottom - Top)) and (Rect.Bottom > Bottom) then
      Pt.Y := Rect.Bottom;
  end;
  ScrollInView(Pt);
end;

procedure TSimpleGraph.ScrollInView(const Pt: TPoint);
var
  X, Y: Integer;
begin
  X := MulDiv(Pt.X, Zoom, 100);
  Y := MulDiv(Pt.Y, Zoom, 100);
  with HorzScrollBar do
    if IsScrollBarVisible then
    begin
      if X < Position then
        Position := X
      else if X > Position + Self.ClientWidth then
        Position := X - Self.ClientWidth;
    end;
  with VertScrollBar do
    if IsScrollBarVisible then
    begin
      if Y < Position then
        Position := Y
      else if Y > Position + Self.ClientHeight then
        Position := Y - Self.ClientHeight;
    end;
end;

procedure TSimpleGraph.ScrollCenter(GraphObject: TGraphObject);
begin
  ScrollCenter(GraphObject.VisualRect);
end;

procedure TSimpleGraph.ScrollCenter(const Rect: TRect);
begin
  ScrollCenter(CenterOfRect(Rect));
end;

procedure TSimpleGraph.ScrollCenter(const Pt: TPoint);
var
  X, Y: Integer;
begin
  X := MulDiv(Pt.X, Zoom, 100);
  Y := MulDiv(Pt.Y, Zoom, 100);
  with HorzScrollBar do
    if IsScrollBarVisible then
      Position := X - Self.ClientWidth div 2;
  with VertScrollBar do
    if IsScrollBarVisible then
      Position := Y - Self.ClientHeight div 2;
end;

procedure TSimpleGraph.ScrollBy(DeltaX, DeltaY: Integer);
begin
  if WindowHandle <> 0 then
  begin
    SendMessage(WindowHandle, WM_SETREDRAW, 0, 0);
    try
      inherited ScrollBy(DeltaX, DeltaY);
    finally
      SendMessage(WindowHandle, WM_SETREDRAW, 1, 0);
    end;
    Invalidate;
    UpdateWindow(WindowHandle);
  end
  else
    inherited ScrollBy(DeltaX, DeltaY);
end;

function TSimpleGraph.ForEachObject(Callback: TGraphForEachMethod;
  UserData: Integer; Selection: Boolean): Integer;
var
  GraphObject: TGraphObject;
  ObjectList: TGraphObjectList;
begin
  Result := 0;
  if Selection then
    ObjectList := SelectedObjects
  else
    ObjectList := Objects;
  if Assigned(Callback) and (ObjectList.Count > 0) then
  begin
    BeginUpdate;
    try
      GraphObject := ObjectList.First;
      while Assigned(GraphObject) do
      begin
        ObjectList.Push;
        try
          if not Callback(GraphObject, UserData) then
            Break;
        finally
          ObjectList.Pop;
        end;
        GraphObject := ObjectList.Next;
      end;
    finally
      EndUpdate;
    end;
  end;
end;

function TSimpleGraph.FindNextObject(StartIndex: Integer; Inclusive, Backward,
  Wrap: Boolean; GraphObjectClass: TGraphObjectClass): TGraphObject;
var
  I: Integer;
begin
  Result := nil;
  if not Assigned(GraphObjectClass) then
    GraphObjectClass := TGraphObject;
  if Backward then
  begin
    for I := StartIndex - Ord(not Inclusive) downto 0 do
      if Objects[I] is GraphObjectClass then
      begin
        Result := Objects[I];
        Exit;
      end;
    if Wrap then
    begin
      for I := Objects.Count - 1 downto StartIndex + 1 do
        if Objects[I] is GraphObjectClass then
        begin
          Result := Objects[I];
          Exit;
        end;
    end;
  end
  else
  begin
    for I := StartIndex + Ord(not Inclusive) to Objects.Count - 1 do
      if Objects[I] is GraphObjectClass then
      begin
        Result := Objects[I];
        Exit;
      end;
    if Wrap then
    begin
      for I := 0 to StartIndex - 1 do
        if Objects[I] is GraphObjectClass then
        begin
          Result := Objects[I];
          Exit;
        end;
    end;
  end;
end;

function TSimpleGraph.SelectNextObject(Backward: Boolean;
  GraphObjectClass: TGraphObjectClass): Boolean;
var
  Index, I: Integer;
  GraphObject: TGraphObject;
begin
  Result := False;
  if not Assigned(GraphObjectClass) then
    GraphObjectClass := TGraphObject;
  if Objects.Count > 0 then
  begin
    GraphObject := nil;
    for I := 0 to SelectedObjects.Count - 1 do
      if SelectedObjects[I] is GraphObjectClass then
      begin
        GraphObject := SelectedObjects[I];
        Break;
      end;
    repeat
      Index := Objects.IndexOf(GraphObject);
      GraphObject := FindNextObject(Index, False, Backward, True, GraphObjectClass);
    until not Assigned(GraphObject) or (goSelectable in GraphObject.Options);
    if Assigned(GraphObject) then
    begin
      SelectedObjects.Clear;
      GraphObject.Selected := True;
      ScrollInView(GraphObject);
      Result := True;
    end;
  end;
end;

function TSimpleGraph.ObjectsCount(GraphObjectClass: TGraphObjectClass): Integer;
var
  I: Integer;
begin
  if Assigned(GraphObjectClass) then
  begin
    Result := 0;
    for I := 0 to Objects.Count - 1 do
      if Objects[I] is GraphObjectClass then
        Inc(Result);
  end
  else
    Result := Objects.Count;
end;

function TSimpleGraph.SelectedObjectsCount(GraphObjectClass: TGraphObjectClass): Integer;
var
  I: Integer;
begin
  if Assigned(GraphObjectClass) then
  begin
    Result := 0;
    for I := 0 to SelectedObjects.Count - 1 do
      if SelectedObjects[I] is GraphObjectClass then
        Inc(Result);
  end
  else
    Result := SelectedObjects.Count;
end;

procedure TSimpleGraph.BeginUpdate;
begin
  if UpdateCount = 0 then
  begin
    SaveModified := 0;
    SaveRangeChange := False;
    SaveInvalidateRect := EmptyRect;
  end;
  Inc(UpdateCount);
end;

procedure TSimpleGraph.EndUpdate;
begin
  Dec(UpdateCount);
  if (UpdateCount = 0) and not (csDestroying in ComponentState) then
  begin
    if SaveRangeChange then
    begin
      SaveBoundsChange := [Low(TGraphBoundsKind)..High(TGraphBoundsKind)];
      CalcAutoRange;
    end;
    if not IsRectEmpty(SaveInvalidateRect) then
      PerformInvalidate(@SaveInvalidateRect);
    if SaveModified <> 0 then
    begin
      Modified := (SaveModified = 1);
      DoGraphChange;
    end;
  end;
end;

procedure TSimpleGraph.Invalidate;
begin
  if UpdateCount <> 0 then
    SaveInvalidateRect := Rect(0, 0, Screen.Width, Screen.Height)
  else
    PerformInvalidate(nil);
end;

procedure TSimpleGraph.InvalidateRect(const Rect: TRect);
var
  ScreenRect: TRect;
begin
  ScreenRect := Rect;
  GPToCP(ScreenRect, 2);
  Inc(ScreenRect.Right);
  Inc(ScreenRect.Bottom);
  if UpdateCount <> 0 then
  begin
    if IsRectEmpty(SaveInvalidateRect) then
      SaveInvalidateRect := ScreenRect
    else
      UnionRect(SaveInvalidateRect, ScreenRect);
  end
  else
    PerformInvalidate(@ScreenRect);
end;

procedure TSimpleGraph.PerformInvalidate(pRect: PRect);
begin
  if WindowHandle <> 0 then
  begin
    if ControlCount = 0 then
      Windows.InvalidateRect(WindowHandle, pRect, False)
    else
      RedrawWindow(WindowHandle, pRect, 0, RDW_INVALIDATE or RDW_ALLCHILDREN);
  end;
end;

function TSimpleGraph.FindObjectByID(ID: DWORD): TGraphObject;
var
  I: Integer;
begin
  Result := nil;
  for I := Objects.Count - 1 downto 0 do
    if Objects[I].ID = ID then
    begin
      Result := Objects[I];
      Exit;
    end;
end;

procedure TSimpleGraph.Clear;
begin
  if Objects.Count > 0 then
  begin
    BeginUpdate;
    try
      Inc(SuspendQueryEvents);
      try
        Objects.Clear;
      finally
        Dec(SuspendQueryEvents);
      end;
      SaveModified := 2;
    finally
      EndUpdate;
    end;
  end;
  CommandMode := cmEdit;
  HorzScrollBar.Position := 0;
  VertScrollBar.Position := 0;
end;

procedure TSimpleGraph.ClearSelection;
begin
  SelectedObjects.Clear;
end;

function TSimpleGraph.CreateUniqueID(GraphObject: TGraphObject): DWORD;
var
  G: TGraphObject;
  Unique: Boolean;
  ID: DWORD;
  I: Integer;
begin
  if GraphObject.ID <> 0 then
    ID := GraphObject.ID
  else
    ID := Objects.Count + 1;
  repeat
    Unique := True;
    for I := Objects.Count - 1 downto 0 do
    begin
      G := Objects[I];
      if (G <> GraphObject) and (G.ID = ID) then
      begin
        Inc(ID);
        Unique := False;
        Break;
      end;
    end;
  until Unique;
  Result := ID;
end;

function TSimpleGraph.ReadGraphObject(Stream: TStream): TGraphObject;
var
  ClassName: array[0..255] of AnsiChar;
  ClassNameLen: Integer;
  ClassNameStr: String;
  GraphObjectClass: TGraphObjectClass;
begin
  Stream.Read(ClassNameLen, SizeOf(ClassNameLen));
  Stream.Read(ClassName, ClassNameLen);
  ClassNameStr := String(ClassName);
  GraphObjectClass := TGraphObjectClass(FindClass(ClassNameStr));
  Result := GraphObjectClass.CreateFromStream(Self, Stream);
end;

procedure TSimpleGraph.WriteGraphObject(Stream: TStream; GraphObject: TGraphObject);
var
  ClassName: array[0..255] of AnsiChar;
  ClassNameLen: Integer;
begin
  ClassNameLen := Length(GraphObject.ClassName) + 1;
  Stream.Write(ClassNameLen, SizeOf(ClassNameLen));
  StrPCopy(ClassName, AnsiString(GraphObject.ClassName));
  Stream.Write(ClassName, ClassNameLen);
  GraphObject.SaveToStream(Stream);
end;

procedure TSimpleGraph.ReadObjects(Stream: TStream);
var
  OldObjectCount: Integer;
  ObjectCount: Integer;
  I, J, OldID, NewID: Integer;
begin
  BeginUpdate;
  Inc(SuspendQueryEvents);
  try
    OldObjectCount := Objects.Count;
    Stream.Read(ObjectCount, SizeOf(ObjectCount));
    if ObjectCount > 0 then
    begin
      Objects.Capacity := OldObjectCount + ObjectCount;
      for I := 0 to ObjectCount - 1 do
        ReadGraphObject(Stream);
      for I := OldObjectCount to Objects.Count - 1 do
      begin
        OldID := Objects[I].ID;
        NewID := CreateUniqueID(Objects[I]);
        if OldID <> NewID then
          for J := OldObjectCount to Objects.Count - 1 do
            Objects[J].ReplaceID(OldID, NewID);
      end;
      for I := OldObjectCount to Objects.Count - 1 do
        Objects[I].Loaded;
    end;
  finally
    Dec(SuspendQueryEvents);
    EndUpdate;
  end;
end;

procedure TSimpleGraph.WriteObjects(Stream: TStream; ObjectList: TGraphObjectList);
var
  ObjectCount: Integer;
  I: Integer;
begin
  ObjectCount := ObjectList.Count;
  Stream.Write(ObjectCount, SizeOf(ObjectCount));
  for I := 0 to ObjectList.Count - 1 do
    WriteGraphObject(Stream, ObjectList[I]);
end;

procedure TSimpleGraph.RestoreObjects(Stream: TStream);
var
  GraphObject: TGraphObject;
  ObjectCount: Integer;
  I, ID: Integer;
begin
  BeginUpdate;
  Inc(SuspendQueryEvents);
  try
    ObjectCount := Objects.Count;
    Stream.Read(ObjectCount, SizeOf(ObjectCount));
    for I := 0 to ObjectCount - 1 do
    begin
      Stream.Read(ID, SizeOf(ID));
      GraphObject := FindObjectByID(ID);
      GraphObject.LoadFromStream(Stream);
    end;
  finally
    Inc(SuspendQueryEvents);
    EndUpdate;
  end;
end;

procedure TSimpleGraph.BackupObjects(Stream: TStream; ObjectList: TGraphObjectList);
var
  ObjectCount: Integer;
  I, ID: Integer;
begin
  ObjectCount := ObjectList.Count;
  Stream.Write(ObjectCount, SizeOf(ObjectCount));
  for I := 0 to ObjectList.Count - 1 do
  begin
    ID := ObjectList[I].ID;
    Stream.Write(ID, SizeOf(ID));
    ObjectList[I].SaveToStream(Stream);
  end;
end;

function TSimpleGraph.GetObjectsBounds(ObjectList: TGraphObjectList): TRect;
var
  I: Integer;
  AnyFound: Boolean;
  GraphObject: TGraphObject;
begin
  AnyFound := False;
  FillChar(Result, SizeOf(TRect), 0);
  for I := ObjectList.Count - 1 downto 0 do
  begin
    GraphObject := ObjectList[I];
    if GraphObject.Showing then
    begin
      if AnyFound then
        UnionRect(Result, GraphObject.VisualRect)
      else
      begin
        AnyFound := True;
        Result := GraphObject.VisualRect;
      end
    end;
  end;
end;

function TSimpleGraph.GetAsMetafile(RefDC: HDC; ObjectList: TGraphObjectList): TMetafile;
var
  Rect: TRect;
  MetaCanvas: TMetafileCanvas;
begin
  Rect := GetObjectsBounds(ObjectList);
  Result := TMetafile.Create;
  Result.Width := (Rect.Right - Rect.Left) + 1;
  Result.Height := (Rect.Bottom - Rect.Top) + 1;
  MetaCanvas := TMetafileCanvas.Create(Result, RefDC);
  try
    SetViewportOrgEx(MetaCanvas.Handle, -Rect.Left, -Rect.Top, nil);
    DrawObjects(MetaCanvas, ObjectList);
  finally
    MetaCanvas.Free;
  end;
end;

procedure TSimpleGraph.SaveAsMetafile(const Filename: String);
var
  Metafile: TMetafile;
begin
  Metafile := GetAsMetafile(0, Objects);
  try
    Metafile.SaveToFile(Filename);
  finally
    Metafile.Free;
  end;
end;

function TSimpleGraph.GetAsBitmap(ObjectList: TGraphObjectList): TBitmap;
var
  Rect: TRect;
begin
  Rect := GetObjectsBounds(ObjectList);
  Result := TBitmap.Create;
  Result.Width := (Rect.Right - Rect.Left) + 1;
  Result.Height := (Rect.Bottom - Rect.Top) + 1;
  Result.PixelFormat := pf24bit;
  SetViewportOrgEx(Result.Canvas.Handle, -Rect.Left, -Rect.Top, nil);
  DrawObjects(Result.Canvas, ObjectList);
  SetViewportOrgEx(Result.Canvas.Handle, 0, 0, nil);
end;

procedure TSimpleGraph.SaveAsBitmap(const Filename: String);
var
  Bitmap: TBitmap;
begin
  Bitmap := GetAsBitmap(Objects);
  try
    Bitmap.SaveToFile(Filename);
  finally
    Bitmap.Free;
  end;
end;

procedure TSimpleGraph.CopyToGraphic(Graphic: TGraphic);
var
  G: TGraphic;
begin
  if Graphic is TMetafile then
  begin
    G := GetAsMetafile(0, Objects);
    try
      Graphic.Assign(G);
    finally
      G.Free;
    end;
  end
  else
  begin
    G := GetAsBitmap(Objects);
    try
      Graphic.Assign(G);
    finally
      G.Free;
    end;
  end;
end;

procedure TSimpleGraph.LoadFromStream(Stream: TStream);
var
  Signature: DWORD;
begin
  Stream.Read(Signature, SizeOf(Signature));
  if Signature <> StreamSignature then
    raise EGraphStreamError.Create(SStreamContentError);
  BeginUpdate;
  try
    Clear;
    ReadObjects(Stream);
    SaveModified := 2;
  finally
    EndUpdate;
  end;
end;

procedure TSimpleGraph.SaveToStream(Stream: TStream);
begin
  Stream.Write(StreamSignature, SizeOf(StreamSignature));
  WriteObjects(Stream, Objects);
  Modified := False;
end;

procedure TSimpleGraph.MergeFromStream(Stream: TStream; OffsetX, OffsetY: Integer);
var
  Signature: DWORD;
  OldObjectCount, I: Integer;
  ObjectList: TGraphObjectList;
  NewObjectsBounds: TRect;
begin
  Stream.Read(Signature, SizeOf(Signature));
  if Signature <> StreamSignature then
    raise EGraphStreamError.Create(SStreamContentError);
  BeginUpdate;
  try
    SelectedObjects.Clear;
    OldObjectCount := Objects.Count;
    ReadObjects(Stream);
    if OldObjectCount <> Objects.Count then
    begin
      ObjectList := TGraphObjectList.Create;
      try
        ObjectList.Capacity := Objects.Count - OldObjectCount;
        for I := OldObjectCount to Objects.Count - 1 do
          ObjectList.Add(Objects[I]);
        NewObjectsBounds := GetObjectsBounds(ObjectList);
        GraphConstraints.SourceRect := NewObjectsBounds;
        if GraphConstraints.ConfineOffset(OffsetX, OffsetY, [osLeft, osTop, osRight, osBottom]) then
        begin
          Inc(SuspendQueryEvents);
          try
            for I := 0 to ObjectList.Count - 1 do
              ObjectList[I].MoveBy(OffsetX, OffsetY);
          finally
            Dec(SuspendQueryEvents);
          end;
          OffsetRect(NewObjectsBounds, OffsetX, OffsetY);
        end;
      finally
        ObjectList.Free;
      end;
    end;
  finally
    EndUpdate;
  end;
  CommandMode := cmEdit;
  if OldObjectCount <> Objects.Count then
    ScrollInView(NewObjectsBounds);
end;

procedure TSimpleGraph.LoadFromFile(const Filename: String);
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(Filename, fmOpenRead or fmShareDenyWrite);
  try
    LoadFromStream(Stream);
  finally
    Stream.Free;
  end;
end;

procedure TSimpleGraph.SaveToFile(const Filename: String);
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(Filename, fmCreate or fmShareExclusive);
  try
    SaveToStream(Stream);
  finally
    Stream.Free;
  end;
end;

procedure TSimpleGraph.MergeFromFile(const FileName: String; OffsetX, OffsetY: Integer);
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(Filename, fmOpenRead or fmShareDenyWrite);
  try
    MergeFromStream(Stream, OffsetX, OffsetY);
  finally
    Stream.Free;
  end;
end;

procedure TSimpleGraph.CopyToClipboard(Selection: Boolean);
var
  ObjectList: TGraphObjectList;
  Stream: TMemoryHandleStream;
  Metafile: TMetafile;
  Bitmap: TBitmap;
begin
  if Selection then
    ObjectList := SelectedObjects
  else
    ObjectList := Objects;
  if ObjectList.Count > 0 then
  begin
    Clipboard.Open;
    try
      Clipboard.Clear;
      if cfNative in ClipboardFormats then
      begin
        Stream := TMemoryHandleStream.Create(0);
        try
          WriteObjects(Stream, ObjectList);
          Clipboard.SetAsHandle(CF_SIMPLEGRAPH, Stream.Handle);
        finally
          Stream.Free;
        end;
      end;
      if cfMetafile in ClipboardFormats then
      begin
        Metafile := GetAsMetafile(0, ObjectList);
        try
          Clipboard.SetAsHandle(CF_ENHMETAFILE, Metafile.Handle);
          Metafile.Handle := 0;
        finally
          Metafile.Free;
        end;
      end;
      if cfBitmap in ClipboardFormats then
      begin
        Bitmap := GetAsBitmap(ObjectList);
        try
          Bitmap.HandleType := bmDDB;
          Clipboard.SetAsHandle(CF_BITMAP, Bitmap.Handle);
          Bitmap.Handle := 0;
        finally
          Bitmap.Free;
        end;
      end;
    finally
      Clipboard.Close;
    end;
  end;
end;

function TSimpleGraph.PasteFromClipboard: Boolean;
var
  Stream: TMemoryHandleStream;
  I, Count: Integer;
begin
  Result := False;
  if Clipboard.HasFormat(CF_SIMPLEGRAPH) then
  begin
    Clipboard.Open;
    try
      Stream := TMemoryHandleStream.Create(Clipboard.GetAsHandle(CF_SIMPLEGRAPH));
      try
        BeginUpdate;
        try
          SelectedObjects.Clear;
          Count := Objects.Count;
          ReadObjects(Stream);
          SelectedObjects.Capacity := Objects.Count - Count;
          for I := Objects.Count - 1 downto Count do
            Objects[I].Selected := True;
          Result := True;
        finally
          EndUpdate;
        end;
      finally
        Stream.Free;
      end;
    finally
      Clipboard.Close;
    end;
  end;
end;

function TSimpleGraph.GetBoundingRect(Kind: TGraphBoundsKind): TRect;
begin
  if Kind in SaveBoundsChange then
  begin
    case Kind of
      bkGraph:
        SaveBounds[Kind] := GetObjectsBounds(Objects);
      bkSelected:
        SaveBounds[Kind] := GetObjectsBounds(SelectedObjects);
      bkDragging:
        SaveBounds[Kind] := GetObjectsBounds(DraggingObjects);
    end;
    Exclude(SaveBoundsChange, Kind);
  end;
  Result := SaveBounds[Kind];
end;

function TSimpleGraph.GetVisibleBounds: TRect;
begin
  Result := ClientRect;
  CPToGP(Result, 2);
end;

function TSimpleGraph.GetCursorPos: TPoint;
begin
  with ScreenToClient(Mouse.CursorPos) do
    Result := ClientToGraph(X, Y);
end;

procedure TSimpleGraph.SetCursorPos(const Pt: TPoint);
begin
  Mouse.CursorPos := ClientToScreen(GraphToClient(Pt.X, Pt.Y));
end;

procedure TSimpleGraph.SetGridSize(Value: TGridSize);
begin
  if (GridSize <> Value) and
     (Value in [Low(TGridSize).. High(TGridSize)]) then
  begin
    fGridSize := Value;
    if ShowGrid then Invalidate;
  end;
end;

procedure TSimpleGraph.SetGridColor(Value: TColor);
begin
  if GridColor <> Value then
  begin
    fGridColor := Value;
    if ShowGrid then Invalidate;
  end;
end;

procedure TSimpleGraph.SetShowGrid(Value: Boolean);
begin
  if ShowGrid <> Value then
  begin
    fShowGrid := Value;
    Invalidate;
  end;
end;

procedure TSimpleGraph.SetTransparent(Value: Boolean);
begin
  if Transparent <> Value then
  begin
    fTransparent := Value;
    if Transparent then
      ControlStyle := ControlStyle - [csOpaque]
    else
      ControlStyle := ControlStyle + [csOpaque];
    {$IFDEF COMPILER7_UP}
    if Transparent then
      ControlStyle := ControlStyle + [csParentBackground]
    else
      ControlStyle := ControlStyle - [csParentBackground];
    {$ENDIF}
    Invalidate;
  end;
end;

procedure TSimpleGraph.SetShowHiddenObjects(Value: Boolean);
begin
  if ShowHiddenObjects <> Value then
  begin
    fShowHiddenObjects := Value;
    CalcAutoRange;
    Invalidate;
  end;
end;

procedure TSimpleGraph.SetHideSelection(Value: Boolean);
begin
  if HideSelection <> Value then
  begin
    fHideSelection := Value;
    if not Focused and (SelectedObjects.Count > 0) then
      InvalidateRect(SelectionBounds);
  end;
end;

procedure TSimpleGraph.SetLockNodes(Value: Boolean);
begin
  if LockNodes <> Value then
  begin
    fLockNodes := Value;
    Invalidate;
  end;
end;

procedure TSimpleGraph.SetLockLinks(Value: Boolean);
begin
  if LockLinks <> Value then
  begin
    fLockLinks := Value;
    Invalidate;
  end;
end;

procedure TSimpleGraph.SetMarkerColor(Value: TColor);
begin
  if MarkerColor <> Value then
  begin
    fMarkerColor := Value;
    if SelectedObjects.Count > 0 then
      Invalidate;
  end;
end;

procedure TSimpleGraph.SetMarkerSize(Value: TMarkerSize);
begin
  if MarkerSize <> Value then
  begin
    fMarkerSize := Value;
    if SelectedObjects.Count > 0 then
      Invalidate;
  end;
end;

procedure TSimpleGraph.SetZoom(Value: TZoom);
begin
  if Value < Low(TZoom) then
    Value := Low(TZoom)
  else if Value > High(TZoom) then
    Value := High(TZoom);
  if Zoom <> Value then
  begin
    fZoom := Value;
    CalcAutoRange;
    Invalidate;
    DoZoomChange;
  end;
end;

procedure TSimpleGraph.SetDrawOrder(Value: TGraphDrawOrder);
begin
  if DrawOrder <> Value then
  begin
    fDrawOrder := Value;
    Invalidate;
  end;
end;

procedure TSimpleGraph.SetFixedScrollBars(Value: Boolean);
begin
  if FixedScrollBars <> Value then
  begin
    fFixedScrollBars := Value;
    CalcAutoRange;
  end;
end;

procedure TSimpleGraph.SetCommandMode(Value: TGraphCommandMode);
begin
  if CommandMode <> Value then
  begin
    if Assigned(DragSource) then
      DragSource.EndDrag(False);
    fCommandMode := Value;
    if not (CommandMode in [cmPan, cmEdit]) then
      SelectedObjects.Clear;
    CalcAutoRange;
    DoCommandModeChange;
  end;
end;

procedure TSimpleGraph.SetMarkedArea(const Value: TRect);
begin
  if not EqualRect(MarkedArea, Value) then
  begin
    if fValidMarkedArea then
      InvalidateRect(fMarkedArea);
    fMarkedArea := Value;
    fValidMarkedArea := (Value.Left <= Value.Right) and (Value.Top <= Value.Bottom);
    CalcAutoRange;
    if fValidMarkedArea then
      InvalidateRect(fMarkedArea);
  end;
end;

procedure TSimpleGraph.SetGraphConstraints(Value: TGraphConstraints);
begin
  GraphConstraints.Assign(Value);
end;

procedure TSimpleGraph.SetHorzScrollBar(Value: TGraphScrollBar);
begin
  HorzScrollBar.Assign(Value);
end;

procedure TSimpleGraph.SetVertScrollBar(Value: TGraphScrollBar);
begin
  VertScrollBar.Assign(Value);
end;

procedure TSimpleGraph.UpdateScrollBars;
begin
  if not UpdatingScrollBars and HandleAllocated then
  begin
    try
      UpdatingScrollBars := True;
      if VertScrollBar.NeedsScrollBarVisible then
      begin
        HorzScrollBar.Update(False, True);
        VertScrollBar.Update(True, False);
      end
      else if HorzScrollBar.NeedsScrollBarVisible then
      begin
        VertScrollBar.Update(False, True);
        HorzScrollBar.Update(True, False);
      end
      else
      begin
        VertScrollBar.Update(False, False);
        HorzScrollBar.Update(True, False);
      end;
    finally
      UpdatingScrollBars := False;
    end;
  end;
end;

procedure TSimpleGraph.CalcAutoRange;
begin
  HorzScrollBar.CalcAutoRange;
  VertScrollBar.CalcAutoRange;
  if ControlCount > 0 then Realign;
end;

procedure TSimpleGraph.AdjustDC(DC: HDC; Org: PPoint);
begin
  if Assigned(Org) then
    SetViewPortOrgEx(DC, -(Org^.X + HorzScrollBar.Position), -(Org^.Y + VertScrollBar.Position), nil)
  else
    SetViewPortOrgEx(DC, -HorzScrollBar.Position, -VertScrollBar.Position, nil);
  SetMapMode(DC, MM_ANISOTROPIC);
  SetWindowExtEx(DC, 100, 100, nil);
  SetViewPortExtEx(DC, Zoom, Zoom, nil);
end;

procedure TSimpleGraph.GPToCP(var Points; Count: Integer);
var
  MemDC: HDC;
begin
  MemDC := CreateCompatibleDC(0);
  try
    AdjustDC(MemDC);
    LPtoDP(MemDC, Points, Count);
  finally
    DeleteDC(MemDC);
  end;
end;

procedure TSimpleGraph.CPToGP(var Points; Count: Integer);
var
  MemDC: HDC;
begin
  MemDC := CreateCompatibleDC(0);
  try
    AdjustDC(MemDC);
    DPtoLP(MemDC, Points, Count);
  finally
    DeleteDC(MemDC);
  end;
end;

function TSimpleGraph.BeginDragObject(GraphObject: TGraphObject;
  const Pt: TPoint; HT: DWORD): Boolean;
var
  I: Integer;
begin
  Result := False;
  if Assigned(GraphObject) then
  begin
    UndoStorage.Clear;
    fDragSource := GraphObject;
    fDragHitTest := HT;
    fDragSourcePt := Pt;
    fDragTargetPt := Pt;
    if not DragSource.Selected then
    begin
      SelectedObjects.Clear;
      DragSource.Selected := True;
    end;
    DraggingObjects.Clear;
    DraggingObjects.Capacity := SelectedObjects.Count;
    DraggingObjects.Add(DragSource);
    if not (CommandMode in [cmInsertLink, cmInsertNode]) then
    begin
      fDragModified := False;
      UndoStorage.Seek(0, soFromBeginning);
      BackupObjects(UndoStorage, DraggingObjects);
      for I := 0 to SelectedObjects.Count - 1 do
        with SelectedObjects[I] do
          if (DragSource.ID <> ID) and BeginFollowDrag(DragHitTest) then
            DraggingObjects.Add(SelectedObjects[I]);
      DoObjectBeginDrag(GraphObject, HT);
    end
    else
      fDragModified := True;
    Result := True;
  end;
end;

procedure TSimpleGraph.PerformDragBy(dX, dY: Integer);
var
  I: Integer;
  Mobility: TObjectSides;
begin
  if Assigned(DragSource) and ((dX <> 0) or (dY <> 0)) then
  begin
    Mobility := [];
    for I := 0 to DraggingObjects.Count - 1 do
      Mobility := Mobility + DraggingObjects[I].QueryMobility(DragHitTest);
    GraphConstraints.SourceRect := DraggingBounds; //TODO: Fix needed for moving points
    if not GraphConstraints.ConfineOffset(dX, dY, Mobility) then
      Exit;
    BeginUpdate;
    try
      for I := 0 to DraggingObjects.Count - 1 do
        DraggingObjects[I].OffsetHitTest(DragHitTest, dX, dY);
    finally
      EndUpdate;
    end;
    Inc(fDragTargetPt.X, dX);
    Inc(fDragTargetPt.Y, dY);
    ScrollInView(fDragTargetPt);
  end;
end;

procedure TSimpleGraph.EndDragObject(Accept: Boolean);
var
  I: Integer;
  Source: TGraphObject;
begin
  if Assigned(DragSource) then
  begin
    Source := DragSource;
    fDragSource := nil;
    for I := 1 to DraggingObjects.Count - 1 do
      DraggingObjects[I].EndFollowDrag;
    DraggingObjects.Clear;
    if not Accept then
    begin
      fDragModified := False;
      if not (CommandMode in [cmInsertLink, cmInsertNode]) then
      begin
        UndoStorage.Seek(0, soFromBeginning);
        RestoreObjects(UndoStorage);
      end
      else
        Source.Free;
    end;
    UndoStorage.Clear;
    if not (CommandMode in [cmInsertLink, cmInsertNode]) then
      DoObjectEndDrag(Source, DragHitTest, not Accept)
    else
      CommandMode := cmEdit;
    if DragModified then
    begin
      Modified := True;
      DoGraphChange;
    end;
  end;
end;

procedure TSimpleGraph.ObjectChanged(GraphObject: TGraphObject;
  Flags: TGraphChangeFlags);
begin
  if (csDestroying in ComponentState) then Exit;
  if UpdateCount = 0 then
  begin
    if gcPlacement in Flags then
    begin
      SaveBoundsChange := [Low(TGraphBoundsKind)..High(TGraphBoundsKind)];
      CalcAutoRange;
    end;
    if gcData in Flags then
    begin
      if not Assigned(DragSource) then
      begin
        Modified := True;
        DoGraphChange;
      end
      else
        fDragModified := True;
    end;
  end
  else
  begin
    if (gcData in Flags) and not (CommandMode in [cmInsertLink, cmInsertNode]) then
      SaveModified := 1;
    if gcPlacement in Flags then
      SaveRangeChange := True;
  end;
  if gcView in Flags then
    GraphObject.Invalidate;
end;

procedure TSimpleGraph.ObjectListChanged(Sender: TObject;
  GraphObject: TGraphObject; Action: TGraphObjectListAction);
begin
  case Action of
    glAdded:
      if GraphObject.Owner = Self then
      begin
        DoObjectInsert(GraphObject);
        ObjectChanged(GraphObject, [gcView, gcData, gcPlacement]);
      end
      else
        TGraphObjectList(Sender).Remove(GraphObject);
    glRemoved:
      if GraphObject.Owner = Self then
      begin
        if GraphObject = DragSource then
          GraphObject.EndDrag(False)
        else if osDragging in GraphObject.States then
          DraggingObjects.Remove(GraphObject);
        if GraphObject = ObjectAtCursor then
          RenewObjectAtCursor(nil);
        GraphObject.Selected := False;
        DoObjectRemove(GraphObject);
        ObjectChanged(GraphObject, [gcView, gcData, gcPlacement]);
        if not (osDestroying in GraphObject.States) then
          GraphObject.Free;
      end;
    glReordered:
      if GraphObject.Owner = Self then
        ObjectChanged(GraphObject, [gcView, gcData]);
  end;
end;

procedure TSimpleGraph.SelectedListChanged(Sender: TObject;
  GraphObject: TGraphObject; Action: TGraphObjectListAction);
begin
  case Action of
    glAdded:
      if (GraphObject.Owner = Self) and GraphObject.Selected then
      begin
        Include(SaveBoundsChange, bkSelected);
        DoObjectSelect(GraphObject);
      end
      else
        TGraphObjectList(Sender).Remove(GraphObject);
    glRemoved:
      if GraphObject.Owner = Self then
      begin
        GraphObject.Selected := False;
        Include(SaveBoundsChange, bkSelected);
        DoObjectSelect(GraphObject);
      end;
  end;
end;

procedure TSimpleGraph.DraggingListChanged(Sender: TObject;
  GraphObject: TGraphObject; Action: TGraphObjectListAction);
begin
  case Action of
    glAdded:
      if GraphObject.Owner = Self then
        Include(SaveBoundsChange, bkDragging)
      else
        TGraphObjectList(Sender).Remove(GraphObject);
    glRemoved:
      if GraphObject.Owner = Self then
        Include(SaveBoundsChange, bkDragging);
  end;
end;

procedure TSimpleGraph.DoBeforeDraw(ACanvas: TCanvas);
begin
  if Assigned(OnBeforeDraw) then
    OnBeforeDraw(Self, Canvas);
end;

procedure TSimpleGraph.DoAfterDraw(ACanvas: TCanvas);
begin
  if Assigned(OnAfterDraw) then
    OnAfterDraw(Self, Canvas);
end;

procedure TSimpleGraph.DoCommandModeChange;
begin
  if not (csDestroying in ComponentState) and Assigned(fOnCommandModeChange) then
    fOnCommandModeChange(Self);
end;

procedure TSimpleGraph.DoGraphChange;
begin
  if Assigned(fOnGraphChange) then
    fOnGraphChange(Self);
end;

procedure TSimpleGraph.DoZoomChange;
begin
  if Assigned(fOnZoomChange) then
    fOnZoomChange(Self);
end;

procedure TSimpleGraph.DoObjectBeforeDraw(ACanvas: TCanvas; GraphObject: TGraphObject);
begin
  if Assigned(OnObjectBeforeDraw) then
    OnObjectBeforeDraw(Self, GraphObject, ACanvas);
end;

procedure TSimpleGraph.DoObjectAfterDraw(ACanvas: TCanvas; GraphObject: TGraphObject);
begin
  if Assigned(OnObjectAfterDraw) then
    OnObjectAfterDraw(Self, GraphObject, ACanvas);
end;

procedure TSimpleGraph.DoObjectClick(GraphObject: TGraphObject);
begin
  if Assigned(fOnObjectClick) then
    fOnObjectClick(Self, GraphObject);
end;

procedure TSimpleGraph.DoObjectDblClick(GraphObject: TGraphObject);
begin
  if Assigned(fOnObjectDblClick) then
    fOnObjectDblClick(Self, GraphObject);
end;

procedure TSimpleGraph.DoObjectInitInstance(GraphObject: TGraphObject);
begin
  if Assigned(fOnObjectInitInstance) then
    fOnObjectInitInstance(Self, GraphObject);
end;

procedure TSimpleGraph.DoObjectInsert(GraphObject: TGraphObject);
begin
  if Assigned(fOnObjectInsert) then
    fOnObjectInsert(Self, GraphObject);
end;

procedure TSimpleGraph.DoObjectRemove(GraphObject: TGraphObject);
begin
  if Assigned(fOnObjectRemove) then
    fOnObjectRemove(Self, GraphObject);
end;

procedure TSimpleGraph.DoObjectChange(GraphObject: TGraphObject);
begin
  if Assigned(fOnObjectChange) then
    fOnObjectChange(Self, GraphObject);
end;

procedure TSimpleGraph.DoObjectMouseEnter(GraphObject: TGraphObject);
begin
  if Assigned(fOnObjectMouseEnter) then
    fOnObjectMouseEnter(Self, GraphObject);
end;

procedure TSimpleGraph.DoObjectMouseLeave(GraphObject: TGraphObject);
begin
  if Assigned(fOnObjectMouseLeave) then
    fOnObjectMouseLeave(Self, GraphObject);
end;

procedure TSimpleGraph.DoObjectSelect(GraphObject: TGraphObject);
begin
  if Assigned(fOnObjectSelect) then
    fOnObjectSelect(Self, GraphObject);
end;

procedure TSimpleGraph.DoObjectContextPopup(GraphObject: TGraphObject;
  const MousePos: TPoint; var Handled: Boolean);
begin
  if Assigned(fOnObjectContextPopup) then
    fOnObjectContextPopup(Self, GraphObject, MousePos, Handled);
end;

procedure TSimpleGraph.DoObjectBeginDrag(GraphObject: TGraphObject; HT: DWORD);
begin
  if Assigned(fOnObjectBeginDrag) then
    fOnObjectBeginDrag(Self, GraphObject, HT);
end;

procedure TSimpleGraph.DoObjectEndDrag(GraphObject: TGraphObject; HT: DWORD;
  Cancelled: Boolean);
begin
  if Assigned(fOnObjectEndDrag) then
    fOnObjectEndDrag(Self, GraphObject, HT, Cancelled);
end;

procedure TSimpleGraph.DoNodeMoveResize(Node: TGraphNode);
begin
  if Assigned(fOnNodeMoveResize) then
    fOnNodeMoveResize(Self, Node);
end;

procedure TSimpleGraph.DoObjectRead(GraphObject: TGraphObject; Stream: TStream);
begin
  if Assigned(fOnObjectRead) then
    fOnObjectRead(Self, GraphObject, Stream);
end;

procedure TSimpleGraph.DoObjectWrite(GraphObject: TGraphObject; Stream: TStream);
begin
  if Assigned(fOnObjectWrite) then
    fOnObjectWrite(Self, GraphObject, Stream);
end;

procedure TSimpleGraph.DoObjectHook(GraphObject: TGraphObject;
  Link: TGraphLink; Index: Integer);
begin
  if Assigned(fOnObjectHook) then
    fOnObjectHook(Self, GraphObject, Link, Index);
end;

procedure TSimpleGraph.DoObjectUnhook(GraphObject: TGraphObject;
  Link: TGraphLink; Index: Integer);
begin
  if Assigned(fOnObjectUnhook) then
    fOnObjectUnhook(Self, GraphObject, Link, Index);
end;

procedure TSimpleGraph.DoCanHookLink(GraphObject: TGraphObject;
  Link: TGraphLink; Index: Integer; var CanHook: Boolean);
begin
  if (SuspendQueryEvents = 0) and Assigned(fOnCanHookLink) then
    fOnCanHookLink(Self, GraphObject, Link, Index, CanHook);
end;

procedure TSimpleGraph.DoCanLinkObjects(Link: TGraphLink;
  Source, Target: TGraphObject; var CanLink: Boolean);
begin
  if (SuspendQueryEvents = 0) and Assigned(fOnCanLinkObjects) then
    fOnCanLinkObjects(Self, Link, Source, Target, CanLink);
end;

procedure TSimpleGraph.DoCanMoveResizeNode(Node: TGraphNode; var aLeft,
  aTop, aWidth, aHeight: Integer; var CanMove, CanResize: Boolean);
begin
  if (SuspendQueryEvents = 0) and Assigned(fOnCanMoveResizeNode) then
    fOnCanMoveResizeNode(Self, Node, aLeft, aTop, aWidth, aHeight, CanMove, CanResize);
end;

procedure TSimpleGraph.DoCanRemoveObject(GraphObject: TGraphObject; var CanRemove: Boolean);
begin
  if (SuspendQueryEvents = 0) and Assigned(fOnCanRemoveObject) then
    fOnCanRemoveObject(Self, GraphObject, CanRemove);
end;

procedure TSimpleGraph.SnapOffset(const Pt: TPoint; var dX, dY: Integer);
begin
  with SnapPoint(Point(Pt.X + dX, Pt.Y + dY)) do
  begin
    if dX <> 0 then dX := X - Pt.X;
    if dY <> 0 then dY := Y - Pt.Y;
  end;
end;

function TSimpleGraph.SnapPoint(const Pt: TPoint): TPoint;
begin
  Result.X := ((Pt.X + (GridSize div 2)) div GridSize) * GridSize;
  Result.Y := ((Pt.Y + (GridSize div 2)) div GridSize) * GridSize;
end;

function TSimpleGraph.ClientToGraph(X, Y: Integer): TPoint;
begin
  Result.X := X;
  Result.Y := Y;
  CPToGP(Result, 1);
end;

function TSimpleGraph.GraphToClient(X, Y: Integer): TPoint;
begin
  Result.X := X;
  Result.Y := Y;
  GPToCP(Result, 1);
end;

function TSimpleGraph.ScreenToGraph(X, Y: Integer): TPoint;
begin
  with ScreenToClient(Point(X, Y)) do
    Result := ClientToGraph(X, Y);
end;

function TSimpleGraph.GraphToScreen(X, Y: Integer): TPoint;
begin
  Result := ClientToScreen(GraphToClient(X, Y));
end;

function TSimpleGraph.ZoomRect(const Rect: TRect): Boolean;
var
  HZoom, VZoom: Integer;
  CRect: TRect;
begin
  CRect := ClientRect;
  if VertScrollBar.IsScrollBarVisible then
    Dec(CRect.Right, GetSystemMetrics(SM_CXVSCROLL));
  if HorzScrollBar.IsScrollBarVisible then
    Dec(CRect.Bottom, GetSystemMetrics(SM_CYHSCROLL));
  HZoom := MulDiv(100, CRect.Right - CRect.Left, Rect.Right - Rect.Left);
  VZoom := MulDiv(100, CRect.Bottom - CRect.Top, Rect.Bottom - Rect.Top);
  if HZoom < VZoom then
    Zoom := HZoom
  else
    Zoom := VZoom;
  ScrollCenter(Rect);
  Result := (Zoom = HZoom) or (Zoom = VZoom);
end;

function TSimpleGraph.ZoomObject(GraphObject: TGraphObject): Boolean;
begin
  if Assigned(GraphObject) then
    Result := ZoomRect(GraphObject.VisualRect)
  else
    Result := False;
end;

function TSimpleGraph.ZoomSelection: Boolean;
begin
  if SelectedObjects.Count > 0 then
    Result := ZoomRect(SelectionBounds)
  else
    Result := False;
end;

function TSimpleGraph.ZoomGraph: Boolean;
begin
  if Objects.Count > 0 then
    Result := ZoomRect(GraphBounds)
  else
    Result := False;
end;

function TSimpleGraph.ChangeZoom(NewZoom: Integer; Origin: TGraphZoomOrigin): Boolean;
var
  R: TRect;
begin
  Result := False;
  if NewZoom < Low(TZoom) then
    NewZoom := Low(TZoom)
  else if NewZoom > High(TZoom) then
    NewZoom := High(TZoom);
  if Zoom <> NewZoom then
  begin
    case Origin of
      zoTopLeft, zoCenter:
        R := VisibleBounds;
      zoCursor, zoCursorCenter:
        R.TopLeft := CursorPos;
    end;
    fZoom := NewZoom;
    CalcAutoRange;
    case Origin of
      zoTopLeft:
        ScrollInView(R);
      zoCenter:
        ScrollCenter(R);
      zoCursor:
      begin
        R.BottomRight := CursorPos;
        with HorzScrollBar do
          if IsScrollBarVisible then
            Position := Position - MulDiv(R.Right - R.Left, Zoom, 100);
        with VertScrollBar do
          if IsScrollBarVisible then
            Position := Position - MulDiv(R.Bottom - R.Top, Zoom, 100);
      end;
      zoCursorCenter:
        ScrollCenter(R.TopLeft);
    end;
    Invalidate;
    DoZoomChange;
    Result := True;
  end;
end;

function TSimpleGraph.ChangeZoomBy(Delta: Integer; Origin: TGraphZoomOrigin): Boolean;
begin
  Result := ChangeZoom(Zoom + Delta, Origin);
end;

function TSimpleGraph.AlignSelection(Horz: THAlignOption; Vert: TVAlignOption): Boolean;

  function DoHSpaceEqually: Boolean;
  var
    I, J: Integer;
    ObjectList: TGraphObjectList;
    GraphObject: TGraphObject;
    Space, Left, dX, dY: Integer;
  begin
    Result := False;
    ObjectList := TGraphObjectList.Create;
    try
      ObjectList.Capacity := SelectedObjects.Count;
      for I := 0 to SelectedObjects.Count - 1 do
      begin
        GraphObject := SelectedObjects[I];
        for J := 0 to ObjectList.Count - 1 do
          if ObjectList[J].BoundsRect.Left > GraphObject.BoundsRect.Left then
          begin
            ObjectList.Insert(J, GraphObject);
            GraphObject := nil;
            Break;
          end;
        if Assigned(GraphObject) then
          ObjectList.Add(GraphObject);
      end;
      Space := ObjectList[ObjectList.Count - 1].BoundsRect.Right - ObjectList[0].BoundsRect.Left;
      for I := 0 to ObjectList.Count - 1 do
        with ObjectList[I].BoundsRect do
          Dec(Space, Right - Left);
      Space := Space div (ObjectList.Count - 1);
      dY := 0;
      Left := ObjectList[0].BoundsRect.Right + Space;
      for I := 1 to ObjectList.Count - 2 do
      begin
        GraphConstraints.SourceRect := ObjectList[I].BoundsRect;
        dX := Left - ObjectList[I].BoundsRect.Left;
        if GraphConstraints.ConfineOffset(dX, dY, [osLeft, osRight]) and
           ObjectList[I].OffsetHitTest(GHT_CLIENT, dX, dY)
        then
          Result := True;
        Left := ObjectList[I].BoundsRect.Right + Space;
      end;
    finally
      ObjectList.Free;
    end;
  end;

  function DoVSpaceEqually: Boolean;
  var
    I, J: Integer;
    ObjectList: TGraphObjectList;
    GraphObject: TGraphObject;
    Space, Top, dX, dY: Integer;
  begin
    Result := False;
    ObjectList := TGraphObjectList.Create;
    try
      ObjectList.Capacity := SelectedObjects.Count;
      for I := 0 to SelectedObjects.Count - 1 do
      begin
        GraphObject := SelectedObjects[I];
        for J := 0 to ObjectList.Count - 1 do
          if ObjectList[J].BoundsRect.Top > GraphObject.BoundsRect.Top then
          begin
            ObjectList.Insert(J, GraphObject);
            GraphObject := nil;
            Break;
          end;
        if Assigned(GraphObject) then
          ObjectList.Add(GraphObject);
      end;
      Space := ObjectList[ObjectList.Count - 1].BoundsRect.Bottom - ObjectList[0].BoundsRect.Top;
      for I := 0 to ObjectList.Count - 1 do
        with ObjectList[I].BoundsRect do
          Dec(Space, Bottom - Top);
      Space := Space div (ObjectList.Count - 1);
      dX := 0;
      Top := ObjectList[0].BoundsRect.Bottom + Space;
      for I := 1 to ObjectList.Count - 2 do
      begin
        GraphConstraints.SourceRect := ObjectList[I].BoundsRect;
        dY := Top - ObjectList[I].BoundsRect.Top;
        if GraphConstraints.ConfineOffset(dX, dY, [osTop, osBottom]) and
           ObjectList[I].OffsetHitTest(GHT_CLIENT, dX, dY)
        then
          Result := True;
        Top := ObjectList[I].BoundsRect.Bottom + Space;
      end;
    finally
      ObjectList.Free;
    end;
  end;

  function DoOtherAlignment: Boolean;
  var
    I: Integer;
    RefRect, ObjRect: TRect;
    dX, dY: Integer;
  begin
    Result := False;
    RefRect := SelectedObjects[0].BoundsRect;
    for I := 1 to SelectedObjects.Count - 1 do
    begin
      ObjRect := SelectedObjects[I].BoundsRect;
      case Horz of
        haLeft:
          dX := RefRect.Left - ObjRect.Left;
        haCenter:
          dX := CenterOfRect(RefRect).X - CenterOfRect(ObjRect).X;
        haRight:
          dX := RefRect.Right - ObjRect.Right;
      else
        dX := 0;
      end;
      case Vert of
        vaTop:
          dY := RefRect.Top - ObjRect.Top;
        vaCenter:
          dY := CenterOfRect(RefRect).Y - CenterOfRect(ObjRect).Y;
        vaBottom:
          dY := RefRect.Bottom - ObjRect.Bottom;
      else
        dY := 0;
      end;
      GraphConstraints.SourceRect := ObjRect;
      if GraphConstraints.ConfineOffset(dX, dY, [osLeft, osTop, osRight, osBottom]) and
         SelectedObjects[I].OffsetHitTest(GHT_CLIENT, dX, dY)
      then
        Result := True;
    end;
  end;

begin
  Result := False;
  if SelectedObjects.Count > 1 then
  begin
    BeginUpdate;
    try
      if (Horz = haSpaceEqually) and (SelectedObjects.Count > 2) and DoHSpaceEqually then
        Result := True;
      if (Vert = vaSpaceEqually) and (SelectedObjects.Count > 2) and DoVSpaceEqually then
        Result := True;
      if ((Horz <> haSpaceEqually) or (Vert <> vaSpaceEqually)) and DoOtherAlignment then
        Result := True;
    finally
      EndUpdate;
    end;
  end;
end;

function TSimpleGraph.ResizeSelection(Horz: TResizeOption; Vert: TResizeOption): Boolean;
var
  MaxWidth, MaxHeight: Integer;
  MinWidth, MinHeight: Integer;
  dX, dY: Integer;
  ObjRect: TRect;
  I, V: Integer;
begin
  Result := False;
  if SelectedObjects.Count > 1 then
  begin
    MinWidth := MaxInt;
    MaxWidth := 0;
    MinHeight := MaxInt;
    MaxHeight := 0;
    for I := 0 to SelectedObjects.Count - 1 do
      with SelectedObjects[I].BoundsRect do
      begin
        V := Right - Left;
        if V < MinWidth then
          MinWidth := V;
        if V > MaxWidth then
          MaxWidth := V;
        V := Bottom - Top;
        if V < MinHeight then
          MinHeight := V;
        if V > MaxHeight then
          MaxHeight := V;
      end;
    BeginUpdate;
    try
      for I := 0 to SelectedObjects.Count - 1 do
      begin
        ObjRect := SelectedObjects[I].BoundsRect;
        case Horz of
          roNoChange:
            dX := 0;
          roSmallest:
            dX := MinWidth - (ObjRect.Right - ObjRect.Left);
          roLargest:
            dX := MaxWidth - (ObjRect.Right - ObjRect.Left);
        end;
        case Vert of
          roNoChange:
            dY := 0;
          roSmallest:
            dY := MinHeight - (ObjRect.Bottom - ObjRect.Top);
          roLargest:
            dY := MaxHeight - (ObjRect.Bottom - ObjRect.Top);
        end;
        GraphConstraints.SourceRect := ObjRect;
        if GraphConstraints.ConfineOffset(dX, dY, [osRight, osBottom]) and
           SelectedObjects[I].OffsetHitTest(GHT_BOTTOMRIGHT, dX, dY)
        then
          Result := True;
      end;
    finally
      EndUpdate;
    end;
  end;
end;

class procedure TSimpleGraph.Register(ANodeClass: TGraphNodeClass);
begin
  if not Assigned(RegisteredNodeClasses) then
    RegisteredNodeClasses := TList.Create;
  if RegisteredNodeClasses.IndexOf(ANodeClass) < 0 then
  begin
    RegisteredNodeClasses.Add(ANodeClass);
    RegisterClass(ANodeClass);
  end;
end;

class procedure TSimpleGraph.Unregister(ANodeClass: TGraphNodeClass);
begin
  if Assigned(RegisteredNodeClasses) then
  begin
    UnregisterClass(ANodeClass);
    RegisteredNodeClasses.Remove(ANodeClass);
    if RegisteredNodeClasses.Count = 0 then
    begin
      RegisteredNodeClasses.Free;
      RegisteredNodeClasses := nil;
    end;
  end;
end;

class function TSimpleGraph.NodeClassCount: Integer;
begin
  if Assigned(RegisteredNodeClasses) then
    Result := RegisteredNodeClasses.Count
  else
    Result := 0;
end;

class function TSimpleGraph.NodeClasses(Index: Integer): TGraphNodeClass;
begin
  Result := TGraphNodeClass(RegisteredNodeClasses[Index]);
end;

class procedure TSimpleGraph.Register(ALinkClass: TGraphLinkClass);
begin
  if not Assigned(RegisteredLinkClasses) then
    RegisteredLinkClasses := TList.Create;
  if RegisteredLinkClasses.IndexOf(ALinkClass) < 0 then
  begin
    RegisteredLinkClasses.Add(ALinkClass);
    RegisterClass(ALinkClass);
  end;
end;

class procedure TSimpleGraph.Unregister(ALinkClass: TGraphLinkClass);
begin
  if Assigned(RegisteredLinkClasses) then
  begin
    UnregisterClass(ALinkClass);
    RegisteredLinkClasses.Remove(ALinkClass);
    if RegisteredLinkClasses.Count = 0 then
    begin
      RegisteredLinkClasses.Free;
      RegisteredLinkClasses := nil;
    end;
  end;
end;

class function TSimpleGraph.LinkClassCount: Integer;
begin
  if Assigned(RegisteredLinkClasses) then
    Result := RegisteredLinkClasses.Count
  else
    Result := 0;
end;

class function TSimpleGraph.LinkClasses(Index: Integer): TGraphLinkClass;
begin
  Result := TGraphLinkClass(RegisteredLinkClasses[Index]);
end;

procedure Register;
begin
  RegisterComponents('Delphi Area', [TSimpleGraph]);
end;




procedure TSimpleGraph.Change;
begin
  inherited Changed;
  if Assigned(FOnChange) then FOnChange(Self);
end;

procedure TSimpleGraph.InsertEditArea;
begin
  FEditAreaList.Insert(FEditAreaIndex, TEditArea.Create(Self));
  FEditAreaList.Items[FEditAreaIndex].Parent:=Self;
  FEditAreaList.Items[FEditAreaIndex].MainArea:=Self;
  FEditAreaList.Items[FEditAreaIndex].Font:=Font;
  FEditAreaList.Items[FEditAreaIndex].Font.Size:=Round(Font.Size*Kp);
  FEditAreaList.Items[FEditAreaIndex].Index:=FEditAreaIndex;
  FEditAreaList.Items[FEditAreaIndex].RefreshDimensions;
  RefreshEditArea(FEditAreaIndex);
  FEditAreaList.Items[FEditAreaIndex].Active:=True;
  Change;
end;

procedure TSimpleGraph.AddEditArea;
var
  AEditAreaIndex: Integer;
begin
  AEditAreaIndex:=FEditAreaIndex+1;
  FEditAreaList.Insert(AEditAreaIndex, TEditArea.Create(Self));
  FEditAreaList.Items[AEditAreaIndex].Parent:=Self;
  FEditAreaList.Items[AEditAreaIndex].MainArea:=Self;
  FEditAreaList.Items[AEditAreaIndex].Font:=Font;
  FEditAreaList.Items[AEditAreaIndex].Font.Size:=Round(Font.Size*Kp);
  FEditAreaList.Items[AEditAreaIndex].Index:=AEditAreaIndex;
  FEditAreaList.Items[AEditAreaIndex].RefreshDimensions;
  EditAreaIndex:=AEditAreaIndex;
  RefreshEditArea(FEditAreaIndex);
  FEditAreaList.Items[FEditAreaIndex].Active:=True;
  Change;
end;

procedure TSimpleGraph.AddEditArea(Area: TEditArea);
var
  AEditAreaIndex: Integer;
begin
  AEditAreaIndex:=FEditAreaIndex+1;
  FEditAreaList.Insert(AEditAreaIndex, Area);
  FEditAreaList.Items[AEditAreaIndex].Parent:=Self;
  FEditAreaList.Items[AEditAreaIndex].MainArea:=Self;
  FEditAreaList.Items[AEditAreaIndex].Font:=Font;
  FEditAreaList.Items[AEditAreaIndex].Font.Size:=Round(Font.Size*Kp);
  FEditAreaList.Items[AEditAreaIndex].Index:=AEditAreaIndex;
  FEditAreaList.Items[AEditAreaIndex].RefreshDimensions;
  EditAreaIndex:=AEditAreaIndex;
  RefreshEditArea(FEditAreaIndex);
  FEditAreaList.Items[FEditAreaIndex].Active:=True;
  Change;
end;

procedure TSimpleGraph.FontChanged(Sender: TObject);
begin
  RefreshEditArea;
end;

procedure TSimpleGraph.RefreshEditArea(AEditAreaIndex: Integer);
var
  i: Integer;
begin
  for i:=AEditAreaIndex to FEditAreaList.Count-1 do begin
    FEditAreaList.Items[i].Left:=Font.Size div 2;
    FEditAreaList.Items[i].Top:=CalcHeight(i);
    FEditAreaList.Items[i].Font.Assign(Font);
    FEditAreaList.Items[i].Font.Size:=Round(Font.Size*Kp);
    FEditAreaList.Items[i].RefreshDimensions;

    FEditAreaList.Items[i].Index:=i;
    FEditAreaList.Items[i].BkColor:=BkColor;
  end;
end;

function TSimpleGraph.CalcHeight(AIndex: Integer): Integer;
var
  i: Integer;
begin
  Result:=Font.Size;
  for i:=0 to AIndex-1 do
    Inc(Result, FEditAreaList.Items[i].Height+Font.Size);
end;






procedure TSimpleGraph.KeyDown(var Key: Word; Shift: TShiftState);
begin
  if Assigned(ActiveEditArea) then case Key of
    VK_UP:
      ActiveEditArea.Parent.EditAreaUp;
    VK_DOWN:
      ActiveEditArea.Parent.EditAreaDown;
    VK_DELETE: begin
      if ActiveEditArea.IsEmpty then ActiveEditArea.Parent.DeleteEditArea else
      ActiveEditArea.DelEquation(ActiveEditArea.EquationIndex);
    end;
    VK_BACK: begin
      if ActiveEditArea.EquationIndex=0 then begin
        if EditAreaIndex>0 then begin
          EditAreaIndex:=EditAreaIndex-1;
          DeleteEditArea;
        end;
      end else if not ActiveEditArea.IsEmpty then begin
        ActiveEditArea.EquationIndex:=ActiveEditArea.EquationIndex-1;
        ActiveEditArea.DelEquation(ActiveEditArea.EquationIndex);
      end;
    end;
    VK_RETURN: begin
      if ActiveEditArea.EquationIndex=0 then InsertEditArea
      else AddEditArea;
    end;
    VK_HOME:
      ActiveEditArea.EquationIndex:=0;
    VK_END:
      ActiveEditArea.EquationIndex:=ActiveEditArea.EquationList.Count;
    VK_LEFT:
      ActiveEditArea.EquationIndex:=ActiveEditArea.EquationIndex-1;
    VK_RIGHT:
      ActiveEditArea.EquationIndex:=ActiveEditArea.EquationIndex+1;

    VK_NUMPAD0..VK_NUMPAD9, 48..90, 166..228, VK_MULTIPLY, VK_ADD,
    VK_SEPARATOR, VK_SUBTRACT, VK_DECIMAL, VK_DIVIDE:
    begin
      ActiveEditArea.AddEqSimple(GetCharFromVirtualKey(Key)[1]);
      ActiveEditArea.EquationIndex:=ActiveEditArea.EquationIndex+1;
    end;
    //else ShowMessage(IntToStr(Key));
  end;

  inherited KeyDown(Key, Shift);
end;

function TSimpleGraph.GetData: String;
var
  i: Integer;
begin
  Result:='';
  for i:=0 to FEditAreaList.Count-1 do begin
    Result:=Format('%sEditArea(%s)',[Result, FEditAreaList.Items[i].Data]);
  end;
end;

procedure TSimpleGraph.SetData(const Value: String);
var
  i: Integer;
  ExprArray: TExprArray;
begin
  FEditAreaList.Clear;
  FEditAreaIndex:=0;
  ExprArray:=GetExprData(Value);
  for i:=0 to Length(ExprArray)-1 do begin
    if ExprArray[i].ClassName = 'EditArea' then begin
      if FEditAreaList.Count>0 then AddEditArea else InsertEditArea;
      FEditAreaList.Items[i].Data:=ExprArray[i].ExprData;
      //EditAreaIndex:=EditAreaIndex+1;
    end;
  end;
end;

procedure TSimpleGraph.EditAreaDown;
begin
  EditAreaIndex:=EditAreaIndex+1;
  FEditAreaList.Items[FEditAreaIndex].Active:=True;
end;

procedure TSimpleGraph.EditAreaUp;
begin
  EditAreaIndex:=EditAreaIndex-1;
  FEditAreaList.Items[FEditAreaIndex].Active:=True;
end;

procedure TSimpleGraph.RefreshDimensions;
begin
end;

function TSimpleGraph.CalcWidth: Integer;
var
  i: Integer;
begin
  Result:=0;
  for i:=0 to FEditAreaList.Count-1 do
    if FEditAreaList.Items[i].Width>Result then
      Result:=FEditAreaList.Items[i].Width;
end;

procedure TSimpleGraph.SetUpdateState(Updating: Boolean);
begin
  if not Updating then Change;
end;

procedure TSimpleGraph.SetBkColor(AValue: TColor);
var
  i: Integer;
begin
  FBkColor := AValue;
  for i:=0 to FEditAreaList.Count-1 do begin
    FEditAreaList.Items[i].BkColor:=FBkColor;
  end;
  Repaint;
end;



{ TQDSGraphic }

constructor TQDSGraphic.Create(AOwner: TComponent);
begin
  inherited;

end;

function TQDSGraphic.GetExprData(const ExprData: String): TExprArray;
var
  i, ExprCount: Integer;

  function StandOnLetter: Boolean;
  begin
    while (not(AnsiChar(ExprData[i]) in ['a'..'z', 'A'..'Z']))and(i<Length(ExprData)) do Inc(i);
    Result:=(AnsiChar(ExprData[i]) in ['a'..'z', 'A'..'Z']);
  end;
  function GetNextClass: String;
  begin
    Result:='';
    while (AnsiChar(ExprData[i]) in ['a'..'z', 'A'..'Z']) do begin
      Result:=Result+ExprData[i];
      Inc(i);
    end;
    Result:=Trim(Result);
  end;
  function StandOnBracket: Integer;
  begin
    Result:=0;
    while (not(AnsiChar(ExprData[i]) in ['(', ')']))and(i<Length(ExprData)) do Inc(i);
    if ExprData[i]='(' then Result:=1;
    if ExprData[i]=')' then Result:=-1;
  end;
  function GetNextExpr: String;
  var BracketsCount, ExprBegin, ExprEnd: Integer;
  begin
    Result:='';
    BracketsCount:=StandOnBracket;
    ExprBegin:=Succ(i);
    while BracketsCount<>0 do begin
      Inc(i);
      Inc(BracketsCount, StandOnBracket);
    end;
    ExprEnd:=i;
    Result:=Trim(Copy(ExprData, ExprBegin, ExprEnd-ExprBegin));
  end;

begin
  ExprCount:=0;
  SetLength(Result, ExprCount);
  i:=1;
  if Length(ExprData)>0 then while StandOnLetter do begin
    Inc(ExprCount);
    SetLength(Result, ExprCount);
    Result[ExprCount-1].ClassName:=GetNextClass;
    Result[ExprCount-1].ExprData:=GetNextExpr;
  end;
end;

procedure TQDSGraphic.SetBkColor(AValue: TColor);
begin
  FBkColor := AValue;
  Repaint;
end;

{ TEACursor }
constructor TEACursor.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Timer:=TTimer.Create(Self);
  Timer.Interval:=500;
  Timer.OnTimer:=Time;
end;

destructor TEACursor.Destroy;
begin
  Timer.Free;
  inherited Destroy;
end;

function TEACursor.GetParent: TEditArea;
begin
  Result := TEditArea(inherited Parent);
end;

procedure TEACursor.Paint;
begin
  Canvas.Pen.Style := psSolid;
  Canvas.Brush.Style := bsClear;
  Canvas.Brush.Color := clBlack;
  Canvas.Rectangle(0, 0, Width, Height);
end;

procedure TEACursor.PutParent(AValue: TEditArea);
begin
  inherited Parent := AValue;
end;

procedure TEACursor.RefreshDimensions;
begin
  Width:=2;
  Height:=Font.Size;
  RefreshVisible;
end;

procedure TEACursor.RefreshVisible;
begin
  Visible:= not Visible and FComVisible and Parent.MainArea.Enabled;       
end;

procedure TEACursor.SetComVisible(Value: Boolean);
begin
  Timer.Enabled:=Value;
  FComVisible:=Value;
  RefreshVisible;
end;

procedure TEACursor.Time(Sender: TObject);
begin
  RefreshVisible;
end;


{ TEditArea }
constructor TEditArea.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FEquationList:=TEquationList.Create;
  FEquationIndex:=0;
  FBkColor:=clWhite;

  FCursor:=TEACursor.Create(Self);
  FCursor.Parent:=Self;
end;

destructor TEditArea.Destroy;
begin
  FCursor.Free;
  FEquationList.Free;
  if Active then MainArea.ActiveEditArea:=nil;
  inherited Destroy;
end;

procedure TEditArea.AddEqBrackets(kb: TKindBracket);
var TempStr: String;
begin
  TempStr:='Brackets';
  case kb of
    kbRound:   TempStr:=TempStr+'Round';
    kbSquare:  TempStr:=TempStr+'Square';
    kbFigure:  TempStr:=TempStr+'Figure';
    kbCorner:  TempStr:=TempStr+'Corner';
    kbModule:  TempStr:=TempStr+'Module';
    kbDModule: TempStr:=TempStr+'DModule';
  end;
  FEquationList.InsertObject(FEquationIndex, TempStr, TEqBrackets.Create(Self));
  (FEquationList.Items[FEquationIndex] as TEqBrackets).KindBracket:=kb;
  RefreshRecurse;
  MainArea.Change;
end;

procedure TEditArea.AddEqExtSymbol(SymbolCode: Integer);
begin
  FEquationList.InsertObject(FEquationIndex, 'ExtSymbol', TEqExtSymbol.Create(Self));
  (FEquationList.Items[FEquationIndex] as TEqExtSymbol).Symbol:=WideChar(SymbolCode);
  RefreshRecurse;
  MainArea.Change;
end;

procedure TEditArea.AddEqIndex(go: TGroupOptions);
var TempStr: String;
begin
  TempStr:='Index';
  if goIndexTop in go then TempStr:=TempStr+'Top';
  if goIndexBottom in go then TempStr:=TempStr+'Bottom';
  FEquationList.InsertObject(FEquationIndex, TempStr, TEqIndex.Create(Self));
  (FEquationList.Items[FEquationIndex] as TEqIndex).GroupOptions:=go;
  RefreshRecurse;
  MainArea.Change;
end;

procedure TEditArea.AddEqIntegral(go: TGroupOptions; Size: Integer; Ring: Boolean);
var TempStr: String;
begin
  TempStr:='Int';
  if go=[goLimitBottom] then TempStr:=TempStr+'LimitBottom';
  if go=[goIndexBottom] then TempStr:=TempStr+'IndexBottom';
  if go=[goLimitBottom, goLimitTop] then TempStr:=TempStr+'LimitBottomTop';
  if go=[goIndexBottom, goIndexTop] then TempStr:=TempStr+'IndexBottomTop';

  case Size of
    1: TempStr:=TempStr+'One';
    2: TempStr:=TempStr+'Two';
    3: TempStr:=TempStr+'Three';
  end;

  if Ring then TempStr:=TempStr+'Ring';

  FEquationList.InsertObject(FEquationIndex, TempStr, TEqIntegral.Create(Self));

  (FEquationList.Items[FEquationIndex] as TEqIntegral).Ring:=Ring;
  (FEquationList.Items[FEquationIndex] as TEqIntegral).Size:=Size;
  (FEquationList.Items[FEquationIndex] as TEqIntegral).GroupOptions:=go;

  RefreshRecurse;
  MainArea.Change;
end;

procedure TEditArea.AddEqVector(ka: TKindArrow; ae: TAlignEA);
var TempStr: String;
begin
  TempStr:='Vector';
  if kaRight in ka then TempStr:=TempStr+'kaRight';
  if kaLeft in ka then TempStr:=TempStr+'kaLeft';
  if kaDouble in ka then TempStr:=TempStr+'kaDouble';
  case ae of
    aeTop:    TempStr:=TempStr+'aeTop';
    aeBottom: TempStr:=TempStr+'aeBottom';
  end;
  FEquationList.InsertObject(FEquationIndex, TempStr, TEqVector.Create(Self));
  (FEquationList.Items[FEquationIndex] as TEqVector).AlignEA:=ae;
  (FEquationList.Items[FEquationIndex] as TEqVector).KindArrow:=ka;
  RefreshRecurse;
  MainArea.Change;
end;

procedure TEditArea.AddEqSimple(Ch: Char);
begin
  FEquationList.InsertObject(FEquationIndex, 'Simple', TEqSimple.Create(Self));
  (FEquationList.Items[FEquationIndex] as TEqSimple).Ch:=Ch;
  RefreshRecurse;
  MainArea.Change;
end;

procedure TEditArea.AddEqSumma(go: TGroupOptions);
var TempStr: String;
begin
  TempStr:='Sum';
  if go=[goLimitBottom] then TempStr:=TempStr+'LimitBottom';
  if go=[goIndexBottom] then TempStr:=TempStr+'IndexBottom';
  if go=[goLimitBottom, goLimitTop] then TempStr:=TempStr+'LimitBottomTop';
  if go=[goIndexBottom, goIndexTop] then TempStr:=TempStr+'IndexBottomTop';


  FEquationList.InsertObject(FEquationIndex, TempStr, TEqSumma.Create(Self));
  (FEquationList.Items[FEquationIndex] as TEqSumma).GroupOptions:=go;

  RefreshRecurse;
  MainArea.Change;
end;

procedure TEditArea.AddEqMultiply(go: TGroupOptions);
var TempStr: String;
begin
  TempStr:='Multiply';
  if go=[goLimitBottom] then TempStr:=TempStr+'LimitBottom';
  if go=[goIndexBottom] then TempStr:=TempStr+'IndexBottom';
  if go=[goLimitBottom, goLimitTop] then TempStr:=TempStr+'LimitBottomTop';
  if go=[goIndexBottom, goIndexTop] then TempStr:=TempStr+'IndexBottomTop';


  FEquationList.InsertObject(FEquationIndex, TempStr, TEqMultiply.Create(Self));
  (FEquationList.Items[FEquationIndex] as TEqMultiply).GroupOptions:=go;

  RefreshRecurse;
  MainArea.Change;
end;

procedure TEditArea.AddEqIntersection(go: TGroupOptions);
var TempStr: String;
begin
  TempStr:='Intersection';
  if go=[goLimitBottom] then TempStr:=TempStr+'LimitBottom';
  if go=[goIndexBottom] then TempStr:=TempStr+'IndexBottom';
  if go=[goLimitBottom, goLimitTop] then TempStr:=TempStr+'LimitBottomTop';
  if go=[goIndexBottom, goIndexTop] then TempStr:=TempStr+'IndexBottomTop';
  FEquationList.InsertObject(FEquationIndex, TempStr, TEqIntersection.Create(Self));
  (FEquationList.Items[FEquationIndex] as TEqIntersection).GroupOptions:=go;
  RefreshRecurse;
  MainArea.Change;
end;

procedure TEditArea.AddEqJoin(go: TGroupOptions);
var TempStr: String;
begin
  TempStr:='Join';
  if go=[goLimitBottom] then TempStr:=TempStr+'LimitBottom';
  if go=[goIndexBottom] then TempStr:=TempStr+'IndexBottom';
  if go=[goLimitBottom, goLimitTop] then TempStr:=TempStr+'LimitBottomTop';
  if go=[goIndexBottom, goIndexTop] then TempStr:=TempStr+'IndexBottomTop';
  FEquationList.InsertObject(FEquationIndex, TempStr, TEqJoin.Create(Self));
  (FEquationList.Items[FEquationIndex] as TEqJoin).GroupOptions:=go;
  RefreshRecurse;
  MainArea.Change;
end;

procedure TEditArea.AddEqCoMult(go: TGroupOptions);
var TempStr: String;
begin
  TempStr:='CoMult';
  if go=[goLimitBottom] then TempStr:=TempStr+'LimitBottom';
  if go=[goIndexBottom] then TempStr:=TempStr+'IndexBottom';
  if go=[goLimitBottom, goLimitTop] then TempStr:=TempStr+'LimitBottomTop';
  if go=[goIndexBottom, goIndexTop] then TempStr:=TempStr+'IndexBottomTop';
  FEquationList.InsertObject(FEquationIndex, TempStr, TEqCoMult.Create(Self));
  (FEquationList.Items[FEquationIndex] as TEqCoMult).GroupOptions:=go;
  RefreshRecurse;
  MainArea.Change;
end;

procedure TEditArea.AddEqArrow(ka: TKindArrow; ae: TAlignEA);
var TempStr: String;
begin
  TempStr:='Arrow';
  if kaRight in ka then TempStr:=TempStr+'kaRight';
  if kaLeft in ka then TempStr:=TempStr+'kaLeft';
  case ae of
    aeTop:    TempStr:=TempStr+'aeTop';
    aeBottom: TempStr:=TempStr+'aeBottom';
  end;
  FEquationList.InsertObject(FEquationIndex, TempStr, TEqArrow.Create(Self));
  (FEquationList.Items[FEquationIndex] as TEqArrow).AlignEA:=ae;
  (FEquationList.Items[FEquationIndex] as TEqArrow).KindArrow:=ka;

  RefreshRecurse;
  MainArea.Change;
end;

procedure TEditArea.AddEqSquare;
begin
  FEquationList.InsertObject(FEquationIndex, 'Square', TEqSquare.Create(Self));
  RefreshRecurse;
  MainArea.Change;
end;

procedure TEditArea.AddEqDivision;
begin
  FEquationList.InsertObject(FEquationIndex, 'Division', TEqDivision.Create(Self));
  RefreshRecurse;
  MainArea.Change;
end;

procedure TEditArea.AddEqMatrix(km: TKindMatrix; CountEA: Integer);
var TempStr: String;
begin                  
  TempStr:='Matrix';
  case km of
    kmHoriz:    TempStr:=TempStr+'kmHoriz';
    kmVert: TempStr:=TempStr+'kmVert';
    kmSquare: TempStr:=TempStr+'kmSquare';
  end;

  FEquationList.InsertObject(FEquationIndex, TempStr, TEqMatrix.Create(Self));
  (FEquationList.Items[FEquationIndex] as TEqMatrix).KindMatrix:=km;
  (FEquationList.Items[FEquationIndex] as TEqMatrix).CountEA:=CountEA;
  RefreshRecurse;
  MainArea.Change;
end;


function TEditArea.CalcHeight: Integer;
var
  i, SumHeight: Integer;
begin
  Result:=FCursor.Height;
  for i:=0 to EquationList.Count-1 do begin
    SumHeight:=5+Round(EquationList.Items[i].CalcHeight+
      Abs(EquationList.Items[i].CalcHeight/2-EquationList.Items[i].MidLine));
    if Result<SumHeight then
      Result:=SumHeight;
  end;
end;

function TEditArea.CalcWidth(AIndex: Integer): Integer;
var
  i: Integer;
begin
  Result:=0;
  for i:=0 to AIndex-1 do begin
    Result:=Result+FCursor.Width+EquationList.Items[i].CalcWidth;
  end;
end;

procedure TEditArea.DelEquation(AEquationIndex: Integer);
begin
  if (AEquationIndex>=0)and(AEquationIndex<EquationList.Count) then begin
    EquationList.Items[AEquationIndex].Free;
    EquationList.Delete(AEquationIndex);
    RefreshRecurse;
  end;
  MainArea.Change;
end;

function TEditArea.GetData: string;
var
  i: Integer;
begin
  Result:='';
  for i:=0 to FEquationList.Count-1 do begin
    Result:=Format('%s%s(%s)',[Result, FEquationList.Strings[i],FEquationList.Items[i].Data]);
  end;
end;

function TEditArea.GetIsEmpty: Boolean;
begin
  Result:=FEquationList.Count=0;
end;

function TEditArea.GetParent: TEquatStore;
begin
  Result := TEquatStore(inherited Parent);
end;

procedure TEditArea.OnActive;
begin
  if Assigned(MainArea.ActiveEditArea) then if MainArea.ActiveEditArea<>Self then
    MainArea.ActiveEditArea.Active:=False;
  MainArea.ActiveEditArea:=Self;
  Parent.EditAreaIndex:=Index;
  Repaint;
  FCursor.ComVisible:=True;
end;

procedure TEditArea.OnDeactive;
begin
  Repaint;
  FCursor.ComVisible:=False;
end;

procedure TEditArea.Paint;
begin
  if MainArea.Enabled and (FActive or GetIsEmpty) then begin
    Canvas.Pen.Color := clBlack;
    Canvas.Pen.Style := psDot;
  end else begin
    Canvas.Pen.Color := FBkColor;
    Canvas.Pen.Style := psSolid;
  end;
  Canvas.Brush.Style := bsClear;
  Canvas.Brush.Color := FBkColor;
  Canvas.Rectangle(0, 0, Width, Height);
end;

procedure TEditArea.PutParent(AValue: TEquatStore);
begin
  inherited Parent := AValue;
end;

procedure TEditArea.RefreshCursor;
begin
  FCursor.Font:=Font;
  FCursor.RefreshDimensions;
  FCursor.Top:=Round((Height-FCursor.Height)/2);
  FCursor.Left:=CalcWidth(FEquationIndex);
end;

procedure TEditArea.RefreshDimensions;
begin
  Height:=CalcHeight+2;
  if IsEmpty then begin
    Width:=Font.Size;
  end else begin
    Width:=CalcWidth(EquationList.Count)+Font.Size div 3;
    RefreshEquations;
  end;
  RefreshCursor;
end;

procedure TEditArea.RefreshEquations;
var
  i: Integer;
begin
  for i:=0 to FEquationList.Count-1 do begin
    FEquationList.Items[i].Index:=i;
    FEquationList.Items[i].Font:=Font;
    FEquationList.Items[i].BkColor:=FBkColor;
    FEquationList.Items[i].RefreshDimensions;
    FEquationList.Items[i].Level:=Parent.Level+1;
    FEquationList.Items[i].Left:=CalcWidth(i)+FCursor.Width;

    FEquationList.Items[i].Top:=Round(Height/2-FEquationList.Items[i].MidLine);
  end;
end;

procedure TEditArea.RefreshRecurse;
begin
  Parent.RefreshEditArea(Index);
  if Parent.ClassName<>'TSimpleGraph' then begin
    (Parent as TEquation).Parent.RefreshRecurse;
  end;
end;

procedure TEditArea.SetActive(AValue: Boolean);
begin
  FActive := AValue;
  if AValue then OnActive
  else OnDeactive;
end;

procedure TEditArea.SetBkColor(AValue: TColor);
var
  i: Integer;
begin
  FBkColor := AValue;
  for i:=0 to FEquationList.Count-1 do begin
    FEquationList.Items[i].BkColor:=FBkColor;
    FEquationList.Items[i].RefreshDimensions;
  end;
  Repaint;
end;

procedure TEditArea.SetData(const AValue: string);
var
  i: Integer;
  ExprArray: TExprArray;
begin
  for i:=0 to FEquationList.Count-1 do FEquationList.Items[i].Free;
  FEquationList.Clear;
  FEquationIndex:=0;
  ExprArray:=GetExprData(AValue);
  for i:=0 to Length(ExprArray)-1 do begin
    if ExprArray[i].ClassName = 'Simple' then begin
      AddEqSimple(ExprArray[i].ExprData[1]);
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'ExtSymbol' then begin
      AddEqExtSymbol(StrToInt(ExprArray[i].ExprData));
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'IndexTop' then begin
      AddEqIndex([goIndexTop]);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'IndexBottom' then begin
      AddEqIndex([goIndexBottom]);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'IndexTopBottom' then begin
      AddEqIndex([goIndexTop, goIndexBottom]);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'BracketsRound' then begin
      AddEqBrackets(kbRound);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'BracketsSquare' then begin
      AddEqBrackets(kbSquare);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'BracketsFigure' then begin
      AddEqBrackets(kbFigure);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'BracketsCorner' then begin
      AddEqBrackets(kbCorner);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'BracketsModule' then begin
      AddEqBrackets(kbModule);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'BracketsDModule' then begin
      AddEqBrackets(kbDModule);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'IntOne' then begin
      AddEqIntegral([], 1, False);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'IntLimitBottomTopOne' then begin
      AddEqIntegral([goLimitTop, goLimitBottom], 1, False);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'IntIndexBottomTopOne' then begin
      AddEqIntegral([goIndexTop, goIndexBottom], 1, False);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'IntLimitBottomOne' then begin
      AddEqIntegral([goLimitBottom], 1, False);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'IntIndexBottomOne' then begin
      AddEqIntegral([goIndexBottom], 1, False);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'IntTwo' then begin
      AddEqIntegral([], 2, False);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'IntLimitBottomTwo' then begin
      AddEqIntegral([goLimitBottom], 2, False);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'IntIndexBottomTwo' then begin
      AddEqIntegral([goIndexBottom], 2, False);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'IntThree' then begin
      AddEqIntegral([], 3, False);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'IntLimitBottomThree' then begin
      AddEqIntegral([goLimitBottom], 3, False);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'IntIndexBottomThree' then begin
      AddEqIntegral([goIndexBottom], 3, False);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'IntOneRing' then begin
      AddEqIntegral([], 1, True);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'IntLimitBottomOneRing' then begin
      AddEqIntegral([goLimitBottom], 1, True);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'IntIndexBottomOneRing' then begin
      AddEqIntegral([goIndexBottom], 1, True);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'IntTwoRing' then begin
      AddEqIntegral([], 2, True);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'IntLimitBottomTwoRing' then begin
      AddEqIntegral([goLimitBottom], 2, True);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'IntIndexBottomTwoRing' then begin
      AddEqIntegral([goIndexBottom], 2, True);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'IntThreeRing' then begin
      AddEqIntegral([], 3, True);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'IntLimitBottomThreeRing' then begin
      AddEqIntegral([goLimitBottom], 3, True);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'IntIndexBottomThreeRing' then begin
      AddEqIntegral([goIndexBottom], 3, True);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'Sum' then begin
      AddEqSumma([]);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'SumLimitBottom' then begin
      AddEqSumma([goLimitBottom]);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'SumLimitBottomTop' then begin
      AddEqSumma([goLimitTop, goLimitBottom]);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'SumIndexBottom' then begin
      AddEqSumma([goIndexBottom]);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'SumIndexBottomTop' then begin
      AddEqSumma([goIndexTop, goIndexBottom]);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'Multiply' then begin
      AddEqMultiply([]);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'MultiplyLimitBottom' then begin
      AddEqMultiply([goLimitBottom]);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'MultiplyLimitBottomTop' then begin
      AddEqMultiply([goLimitTop, goLimitBottom]);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'MultiplyIndexBottom' then begin
      AddEqMultiply([goIndexBottom]);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'MultiplyBottomTop' then begin
      AddEqMultiply([goIndexTop, goIndexBottom]);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'CoMult' then begin
      AddEqCoMult([]);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'CoMultLimitBottom' then begin
      AddEqCoMult([goLimitBottom]);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'CoMultLimitBottomTop' then begin
      AddEqCoMult([goLimitTop, goLimitBottom]);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'CoMultIndexBottom' then begin
      AddEqCoMult([goIndexBottom]);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'CoMultBottomTop' then begin
      AddEqCoMult([goIndexTop, goIndexBottom]);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'Intersection' then begin
      AddEqIntersection([]);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'IntersectionLimitBottom' then begin
      AddEqIntersection([goLimitBottom]);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'IntersectionLimitBottomTop' then begin
      AddEqIntersection([goLimitTop, goLimitBottom]);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'IntersectionIndexBottom' then begin
      AddEqIntersection([goIndexBottom]);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'IntersectionBottomTop' then begin
      AddEqIntersection([goIndexTop, goIndexBottom]);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'Join' then begin
      AddEqJoin([]);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'JoinLimitBottom' then begin
      AddEqJoin([goLimitBottom]);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'JoinLimitBottomTop' then begin
      AddEqJoin([goLimitTop, goLimitBottom]);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'JoinIndexBottom' then begin
      AddEqJoin([goIndexBottom]);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'JoinBottomTop' then begin
      AddEqJoin([goIndexTop, goIndexBottom]);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;

    if ExprArray[i].ClassName = 'ArrowkaRightaeTop' then begin
      AddEqArrow([kaRight], aeTop);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'ArrowkaLeftaeTop' then begin
      AddEqArrow([kaLeft], aeTop);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'ArrowkaRightkaLeftaeTop' then begin
      AddEqArrow([kaRight, kaLeft], aeTop);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'ArrowkaRightaeBottom' then begin
      AddEqArrow([kaRight], aeBottom);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'ArrowkaLeftaeBottom' then begin
      AddEqArrow([kaLeft], aeBottom);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'ArrowkaRightkaLeftaeBottom' then begin
      AddEqArrow([kaRight, kaLeft], aeBottom);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'Square' then begin
      AddEqSquare;
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'Division' then begin
      AddEqDivision;
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'VectoraeBottom' then begin
      AddEqVector([], aeBottom);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'VectorkaDoubleaeBottom' then begin
      AddEqVector([kaDouble], aeBottom);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'VectoraeTop' then begin
      AddEqVector([], aeTop);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'VectorkaDoubleaeTop' then begin
      AddEqVector([kaDouble], aeTop);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'VectorkaRightaeBottom' then begin
      AddEqVector([kaRight], aeBottom);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'VectorkaLeftaeBottom' then begin
      AddEqVector([kaLeft], aeBottom);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'VectorkaRightkaLeftaeBottom' then begin
      AddEqVector([kaRight, kaLeft], aeBottom);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'VectorkaRightaeTop' then begin
      AddEqVector([kaRight], aeTop);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'VectorkaLeftaeTop' then begin
      AddEqVector([kaLeft], aeTop);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'VectorkaRightkaLeftaeTop' then begin
      AddEqVector([kaRight, kaLeft], aeTop);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'MatrixkmHoriz' then begin
      AddEqMatrix(kmHoriz, 0);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'MatrixkmVert' then begin
      AddEqMatrix(kmVert, 0);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
    if ExprArray[i].ClassName = 'MatrixkmSquare' then begin
      AddEqMatrix(kmSquare, 0);
      FEquationList.Items[FEquationIndex].Data:=ExprArray[i].ExprData;
      EquationIndex:=EquationIndex+1;
    end;
  end;
end;

procedure TEditArea.SetEquationIndex(AValue: Integer);
begin
  if (AValue>=0)and(AValue<=EquationList.Count) then FEquationIndex := AValue;
  RefreshCursor;
end;

procedure TEditArea.SetEquationList(AValue: TEquationList);
begin
  FEquationList := AValue;
end;

procedure TEditArea.WMLButtonDown(var Message: TWMLButtonDown);
begin
  MainArea.SetFocus;
  Active:=True;
end;

{ TEditAreaList }

function TEditAreaList.GetItem(Index: Integer): TEditArea;
begin
  Result := TEditArea(inherited Items[Index]);
end;

procedure TEditAreaList.SetItem(Index: Integer; AValue: TEditArea);
begin
  inherited Items[Index] := AValue;
end;


{ TEquationList }

function TEquationList.GetItem(Index: Integer): TEquation;
begin
  Result := TEquation(inherited Objects[Index]);
end;

procedure TEquationList.PutItem(Index: Integer; AValue: TEquation);
begin
  inherited Objects[Index] := AValue;
end;


{ TEquatStore }

procedure TEquatStore.BeginUpdate;
begin
  if FUpdateCount = 0 then SetUpdateState(True);
  Inc(FUpdateCount);
end;

procedure TEquatStore.DeleteEditArea;
begin
end;

procedure TEquatStore.EditAreaDown;
begin
end;

procedure TEquatStore.EditAreaUp;
begin
end;

procedure TEquatStore.EndUpdate;
begin
  Dec(FUpdateCount);
  if FUpdateCount = 0 then SetUpdateState(False);
end;

procedure TEquatStore.InsertEditArea;
begin
end;

procedure TEquatStore.RefreshEditArea(AEditAreaIndex: Integer = 0);
begin
end;

procedure TEquatStore.SetEditAreaIndex(AValue: Integer);
begin
  if (AValue<>FEditAreaIndex)and(AValue>=0)and(AValue<FEditAreaList.Count) then
    FEditAreaIndex := AValue;
end;

procedure TEquatStore.SetEditAreaList(AValue: TEditAreaList);
begin
  FEditAreaList := AValue;
end;



{ TEquation }
constructor TEquation.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Parent:=AOwner as TEditArea;
  Kp:=1;
end;

function TEquation.CalcHeight: Integer;
begin
  Result := 0;
end;

function TEquation.CalcWidth: Integer;
begin
  Result := 0;
end;

function TEquation.GetData: string;
begin
end;

function TEquation.GetMidLine: Integer;
begin
  Result:=Height div 2;
end;

function TEquation.GetParent: TEditArea;
begin
  Result := TEditArea(inherited Parent);
end;

procedure TEquation.Paint;
begin
end;

procedure TEquation.PutParent(AValue: TEditArea);
begin
  inherited Parent := AValue;
end;

procedure TEquation.SetCanvasFont;
begin
  Canvas.Pen.Style := psSolid;
  Canvas.Pen.Color:=BkColor;
  Canvas.Brush.Style := bsClear;
  Canvas.Brush.Color:=BkColor;
  Canvas.Font.Assign(Font);
end;

procedure TEquation.SetData(const AValue: string);
begin
end;

procedure TEquation.SetUpdateState(Updating: Boolean);
begin
  if not Updating then RefreshEditArea;
end;

procedure TEquation.WMLButtonDown(var Message: TWMLButtonDown);
begin
  Parent.WMLButtonDown(Message);
end;

{ TEqBrackets }

constructor TEqBrackets.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  InsertEditArea;
  RefreshEditArea;
end;

function TEqBrackets.CalcSymbolHeight: Integer;
var
  Sz: TSize;
begin
  SetCanvasFont;
  GetTextExtentPoint32W(Canvas.Handle,@FLSymbol,1,Sz);
  Result:=Sz.cy;
end;

function TEqBrackets.CalcSymbolWidth: Integer;
var
  Sz: TSize;
begin
  SetCanvasFont;
  GetTextExtentPoint32W(Canvas.Handle,@FLSymbol,1,Sz);
  Result:=Sz.cx;
end;

function TEqBrackets.CalcHeight: Integer;
begin
  SetCanvasFont;
  Result:=Max(FEditAreaList.Items[0].Height,CalcSymbolHeight);
end;

function TEqBrackets.CalcWidth: Integer;
begin
  SetCanvasFont;
  Result:=FEditAreaList.Items[0].Width+CalcSymbolWidth*2;
end;

function TEqBrackets.GetCommonHeight: Integer;
begin
  Result:=Max(CalcSymbolHeight,EditAreaList.Items[0].Height);
end;

procedure TEqBrackets.Paint;
var CommonHeight: Integer;
begin
  CommonHeight:=GetCommonHeight;
  Canvas.Rectangle(0, 0, Width, Height);
  TextOutW(Canvas.Handle,0,(CommonHeight-CalcSymbolHeight) div 2,@FLSymbol,1);
  TextOutW(Canvas.Handle,CalcSymbolWidth+FEditAreaList.Items[0].Width,
           (CommonHeight-CalcSymbolHeight) div 2,@FRSymbol,1);
end;

procedure TEqBrackets.RefreshDimensions;
begin
  Height:=CalcHeight;
  Width:=CalcWidth;
end;

procedure TEqBrackets.RefreshEditArea(AEditAreaIndex: Integer = 0);
begin
  FEditAreaList.Items[0].BkColor:=Parent.BkColor;
  FEditAreaList.Items[0].Font:=Font;
  FEditAreaList.Items[0].Font.Size:=Round(Font.Size*Kp);
  FEditAreaList.Items[0].RefreshDimensions;
  FEditAreaList.Items[0].Index:=0;
  FEditAreaList.Items[0].Left:=CalcSymbolWidth;
  FEditAreaList.Items[0].Top:=(GetCommonHeight-FEditAreaList.Items[0].Height) div 2;
  Parent.RefreshEquations;
end;

procedure TEqBrackets.SetKindBracket(AValue: TKindBracket);
begin
  FKindBracket:=AValue;
  case FKindBracket of
    kbRound: begin
      FLSymbol:=WideChar(64830);
      FRSymbol:=WideChar(64831);
    end;
    kbSquare: begin
      FLSymbol:=WideChar(91);
      FRSymbol:=WideChar(93);
    end;
    kbFigure: begin
      FLSymbol:=WideChar(123);
      FRSymbol:=WideChar(125);
    end;
    kbCorner: begin
      FLSymbol:=WideChar(8249);
      FRSymbol:=WideChar(8250);
    end;
    kbModule: begin
      FLSymbol:=WideChar(9474);
      FRSymbol:=WideChar(9474);
    end;
    kbDModule: begin
      FLSymbol:=WideChar(9553);
      FRSymbol:=WideChar(9553);
    end;
  end;
  RefreshEditArea;
end;

procedure TEqBrackets.SetLSymbol(Value: WideChar);
begin
  FLSymbol:=Value;
  Repaint;
end;

procedure TEqBrackets.SetRSymbol(Value: WideChar);
begin
  FRSymbol:=Value;
  Repaint;
end;

{ TEqParent }

constructor TEqParent.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FEditAreaList:=TEditAreaList.Create;
  FEditAreaIndex:=0;
end;

destructor TEqParent.Destroy;
begin
  FEditAreaList.Free;
  inherited;
end;

function TEqParent.GetData: string;
begin
  Result:=Format('EditArea(%s)',[EditAreaList.Items[0].Data]);
end;

procedure TEqParent.InsertEditArea;
begin
  FEditAreaList.Insert(FEditAreaIndex, TEditArea.Create(Self));
  FEditAreaList.Items[FEditAreaIndex].Parent:=Self;
  FEditAreaList.Items[FEditAreaIndex].MainArea:=Parent.MainArea;
  FEditAreaList.Items[FEditAreaIndex].Font:=Font;
  FEditAreaList.Items[FEditAreaIndex].Font.Size:=Round(Font.Size*Kp);
  FEditAreaList.Items[FEditAreaIndex].BkColor:=Parent.BkColor;
  FEditAreaList.Items[FEditAreaIndex].Index:=FEditAreaIndex;
  FEditAreaList.Items[FEditAreaIndex].RefreshDimensions;
  RefreshEditArea(FEditAreaIndex);
  FEditAreaList.Items[FEditAreaIndex].Active:=True;
end;

procedure TEqParent.SetBkColor(AValue: TColor);
var
  i: Integer;
begin
  FBkColor := AValue;
  for i:=0 to FEditAreaList.Count-1 do begin
    FEditAreaList.Items[i].BkColor:=FBkColor;
  end;
  Repaint;
end;

procedure TEqParent.SetData(const AValue: string);
var
  ExprArray: TExprArray;
begin
  FEditAreaIndex:=0;
  ExprArray:=GetExprData(AValue);
  if Length(ExprArray)>0 then begin
    if ExprArray[0].ClassName = 'EditArea' then begin
      FEditAreaList.Items[0].Data:=ExprArray[0].ExprData;
    end;
  end;
end;

{ TEqExtSymbol }

function TEqExtSymbol.CalcHeight: Integer;
var
  Size: TSize;
begin
  SetCanvasFont;
  GetTextExtentPoint32W(Canvas.Handle,@Symbol,1,Size);
  Result:=Size.CY
end;

function TEqExtSymbol.CalcWidth: Integer;
var
  Size: TSize;
begin
  SetCanvasFont;
  GetTextExtentPoint32W(Canvas.Handle,@Symbol,1,Size);
  Result:=Size.CX;
end;

function TEqExtSymbol.GetData: string;
begin
  Result:=IntToStr(Integer(Symbol));
end;

procedure TEqExtSymbol.Paint;
begin
  TextOutW(Canvas.Handle,0,0,@Symbol,1)
end;

procedure TEqExtSymbol.RefreshDimensions;
begin
  Height:=CalcHeight;
  Width:=CalcWidth;
end;

{ TEqIndex }

constructor TEqIndex.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Kp:=0.7;
  FGroupOptions:=[];
end;

function TEqIndex.CalcHeight: Integer;
begin
  Result:=Font.Size div 2;
  if goIndexTop in FGroupOptions then Result:=Result+FIndexTop.Height;
  if goIndexBottom in FGroupOptions then Result:=Result+FIndexBottom.Height;
end;

function TEqIndex.CalcWidth: Integer;
begin
  Result:=0;
  if goIndexTop in FGroupOptions then Result:=FIndexTop.Width;
  if goIndexBottom in FGroupOptions then Result:=Max(Result, FIndexBottom.Width);
end;

procedure TEqIndex.Paint;
begin
  SetCanvasFont;
  Canvas.Rectangle(0, 0, Width, Height);
end;

procedure TEqIndex.RefreshDimensions;
begin
  Height:=CalcHeight;
  Width:=CalcWidth;
end;

procedure TEqIndex.RefreshEA(AEditArea: TEditArea);
begin
  AEditArea.BkColor:=Parent.BkColor;
  AEditArea.Font.Assign(Font);
  AEditArea.Font.Size:=Round(Font.Size*Kp);
  AEditArea.RefreshDimensions;
  AEditArea.Index:=FEditAreaList.IndexOf(AEditArea);
end;

procedure TEqIndex.RefreshEditArea(AEditAreaIndex: Integer = 0);
begin
  if FUpdateCount>0 then Exit;
  if goIndexTop in FGroupOptions then begin
    RefreshEA(FIndexTop);
    FIndexTop.Top:=0;
    FIndexTop.Left:=0;
  end;
  if goIndexBottom in FGroupOptions then begin
    RefreshEA(FIndexBottom);
    FIndexBottom.Top:=Font.Size div 2;
    if goIndexTop in FGroupOptions then FIndexBottom.Top:=FIndexBottom.Top+FIndexTop.Height;
    FIndexBottom.Left:=0;
  end;
  Parent.RefreshEquations;
end;

procedure TEqIndex.SetGroupOptions(const Value: TGroupOptions);
begin
  FGroupOptions := Value;
  BeginUpdate;
  if goIndexTop in FGroupOptions then begin
    InsertEditArea;
    FIndexTop:=EditAreaList.Items[EditAreaIndex];
  end;
  if goIndexBottom in FGroupOptions then begin
    InsertEditArea;
    FIndexBottom:=EditAreaList.Items[EditAreaIndex];
  end;
  EndUpdate;
end;

function TEqIndex.GetData: string;
begin
  Result:='';
  if goIndexBottom in FGroupOptions then Result:=Result+Format('EditArea(%s)',[FIndexBottom.Data]);
  if goIndexTop in FGroupOptions then Result:=Result+Format('EditArea(%s)',[FIndexTop.Data]);
end;

procedure TEqIndex.SetData(const AValue: String);
var
  i: Integer;
  ExprArray: TExprArray;
begin
  ExprArray:=GetExprData(AValue);
  for i:=0 to Length(ExprArray)-1 do begin
    if ExprArray[i].ClassName = 'EditArea' then if i<FEditAreaList.Count then begin
      FEditAreaList.Items[i].Data:=ExprArray[i].ExprData;
    end;
  end;
end;

{ TEqIntegral }

constructor TEqIntegral.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Symbol:=WideChar(8747);
end;

{ TEqGroupOp }

function TEqGroupOp.CalcHeight: Integer;
begin
  Result:=TopMargin+GetCommonHeight;
  if goIndexBottom in FGroupOptions then Result:=Result+FIndexBottom.Height div 2;
  if goLimitBottom in FGroupOptions then Result:=Result+FLimitBottom.Height;
end;                      

function TEqGroupOp.CalcSymbolHeight: Integer;
var
  Sz: TSize;
begin
  SetCanvasFont;
  GetTextExtentPoint32W(Canvas.Handle,@FSymbol,1,Sz);
  Result:=Sz.cy;
end;

function TEqGroupOp.CalcSymbolWidth: Integer;
var
  Sz: TSize;
begin
  SetCanvasFont;
  GetTextExtentPoint32W(Canvas.Handle,@FSymbol,1,Sz);
  Result:=Sz.cx*FSize+FSize;
end;

function TEqGroupOp.CalcWidth: Integer;
begin
  Result:=GetCommonWidth+FEditAreaList.Items[0].Width;
end;

constructor TEqGroupOp.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Symbol:=WideChar(0);
  FGroupOptions:=[];
  FRing:=False;
  FSize:=1;
  FEditAreaIndex:=0;
  InsertEditArea;
end;

function TEqGroupOp.GetCommonHeight: Integer;
begin
  Result:=Max(SymbolHeight,EditAreaList.Items[0].Height);
end;

function TEqGroupOp.GetCommonWidth: Integer;
var EAWidth: Integer;
begin
  Result:=SymbolWidth;
  EAWidth:=0;
  if (goLimitTop in FGroupOptions)or(goLimitBottom in FGroupOptions) then begin
    if goLimitTop in FGroupOptions then EAWidth:=Max(EAWidth, FLimitTop.Width);
    if goLimitBottom in FGroupOptions then EAWidth:=Max(EAWidth, FLimitBottom.Width);
    Result:=Max(Result, EAWidth);
  end;
  if (goIndexTop in FGroupOptions)or(goIndexBottom in FGroupOptions) then begin
    if goIndexTop in FGroupOptions then EAWidth:=Max(EAWidth, FIndexTop.Width);
    if goIndexBottom in FGroupOptions then EAWidth:=Max(EAWidth, FIndexBottom.Width);
    Result:=Result+EAWidth;
  end;
end;

function TEqGroupOp.GetMidLine: Integer;
begin
  Result:=TopMargin+CalcSymbolHeight div 2;
end;

function TEqGroupOp.GetTopMargin: Integer;
begin
  Result:=0;
  if goIndexTop in FGroupOptions then Result:=FIndexTop.Height div 2;
  if goLimitTop in FGroupOptions then Result:=FLimitTop.Height;
end;

function TEqGroupOp.GetSymbolHeight: Integer;
begin
  Result:=CalcSymbolHeight;
end;

function TEqGroupOp.GetSymbolWidth: Integer;
begin
  Result:=CalcSymbolWidth;
end;

procedure TEqGroupOp.Paint;
var
  Sz: TSize;
  SymbolLeft, SymbolTop: Integer;
  procedure DrawSymbol;
  var i: Integer;
  begin
    for i:=0 to FSize-1 do begin
      TextOutW(Canvas.Handle,SymbolLeft+(Sz.cx+1)*i,SymbolTop,@Symbol,1);
    end;
  end;
  procedure DrawRing();
  var MLine: Integer;
  begin
    MLine:=SymbolTop+SymbolHeight div 2;
    Canvas.Pen.Style:=psSolid;
    Canvas.Pen.Width:=Font.Size div 15;
    Canvas.Pen.Color:=Font.Color;
    Canvas.Brush.Style:=bsClear;
    Canvas.Ellipse(SymbolLeft,
                   MLine-Font.Size div 3,
                   SymbolLeft+Sz.cx*FSize+FSize,
                   MLine+Font.Size div 3);
  end;
begin
  SetCanvasFont;
  GetTextExtentPoint32W(Canvas.Handle,@Symbol,1,Sz);
  SymbolLeft:=0;
  if (goLimitTop in FGroupOptions)or(goLimitBottom in FGroupOptions) then
    SymbolLeft:=(GetCommonWidth-SymbolWidth) div 2;
  if (goIndexTop in FGroupOptions)or(goIndexBottom in FGroupOptions) then
    SymbolLeft:=0;
  SymbolTop:=TopMargin+(GetCommonHeight-SymbolHeight) div 2;
  Canvas.Rectangle(0, 0, Width, Height);
  DrawSymbol;
  if FRing then DrawRing;
end;

procedure TEqGroupOp.RefreshDimensions;
begin
  Height:=CalcHeight;
  Width:=CalcWidth;
end;

procedure TEqGroupOp.RefreshEA(AEditArea: TEditArea; AKp: Double);
begin
  AEditArea.BkColor:=Parent.BkColor;
  AEditArea.Font.Assign(Font);
  AEditArea.Font.Size:=Round(Font.Size*Kp*AKp);
  AEditArea.RefreshDimensions;
  AEditArea.Index:=FEditAreaList.IndexOf(AEditArea);
end;

procedure TEqGroupOp.RefreshEditArea(AEditAreaIndex: Integer = 0);
var
  CommonHeight, CommonWidth: Integer;
begin
  if FUpdateCount>0 then Exit;
  if goLimitTop in FGroupOptions then RefreshEA(FLimitTop, 0.8);
  if goLimitBottom in FGroupOptions then RefreshEA(FLimitBottom, 0.8);
  if goIndexTop in FGroupOptions then RefreshEA(FIndexTop, 0.8);
  if goIndexBottom in FGroupOptions then RefreshEA(FIndexBottom, 0.8);
  CommonWidth:=GetCommonWidth;
  RefreshEA(EditAreaList.Items[0], 1);
  CommonHeight:=GetCommonHeight;
  if goLimitTop in FGroupOptions then begin
    FLimitTop.Top:=0;
    FLimitTop.Left:=(CommonWidth-FLimitTop.Width) div 2;
  end;
  if goIndexTop in FGroupOptions then begin
    FIndexTop.Top:=0;
    FIndexTop.Left:=SymbolWidth;
  end;
  if goLimitBottom in FGroupOptions then begin
    FLimitBottom.Top:=TopMargin+CommonHeight;
    FLimitBottom.Left:=(CommonWidth-FLimitBottom.Width) div 2;
  end;
  if goIndexBottom in FGroupOptions then begin
    FIndexBottom.Top:=TopMargin+CommonHeight-FIndexBottom.Height div 2;
    FIndexBottom.Left:=SymbolWidth;
  end;
  EditAreaList.Items[0].Left:=CommonWidth;
  EditAreaList.Items[0].Top:=TopMargin+(CommonHeight-EditAreaList.Items[0].Height) div 2;
  Parent.RefreshEquations;
end;

function TEqGroupOp.GetData: string;
begin
  Result:=Format('EditArea(%s)',[EditAreaList.Items[0].Data]);
  if goLimitBottom in FGroupOptions then Result:=Result+Format('EditArea(%s)',[FLimitBottom.Data]);
  if goLimitTop in FGroupOptions then Result:=Result+Format('EditArea(%s)',[FLimitTop.Data]);
  if goIndexBottom in FGroupOptions then Result:=Result+Format('EditArea(%s)',[FIndexBottom.Data]);
  if goIndexTop in FGroupOptions then Result:=Result+Format('EditArea(%s)',[FIndexTop.Data]);
end;

procedure TEqGroupOp.SetData(const AValue: String);
var
  i: Integer;
  ExprArray: TExprArray;
begin
  ExprArray:=GetExprData(AValue);
  for i:=0 to Length(ExprArray)-1 do begin
    if ExprArray[i].ClassName = 'EditArea' then if i<FEditAreaList.Count then begin
      FEditAreaList.Items[i].Data:=ExprArray[i].ExprData;
    end;
  end;
end;

procedure TEqGroupOp.SetGroupOptions(Value: TGroupOptions);
begin
  FGroupOptions:=Value;
  BeginUpdate;
  FEditAreaIndex:=1;
  if goLimitTop in FGroupOptions then begin
    InsertEditArea;
    FLimitTop:=EditAreaList.Items[EditAreaIndex];
  end;
  if goIndexTop in FGroupOptions then begin
    InsertEditArea;
    FIndexTop:=EditAreaList.Items[EditAreaIndex];
  end;
  if goLimitBottom in FGroupOptions then begin
    InsertEditArea;
    FLimitBottom:=EditAreaList.Items[EditAreaIndex];
  end;
  if goIndexBottom in FGroupOptions then begin
    InsertEditArea;
    FIndexBottom:=EditAreaList.Items[EditAreaIndex];
  end;
  EndUpdate;
  RefreshEditArea;
end;

procedure TEqGroupOp.SetRing(ARing: Boolean);
begin
  FRing := ARing;
  Repaint;
end;

procedure TEqGroupOp.SetSize(ASize: Integer);
begin
  if ASize in [1..3] then FSize:=ASize;
  Repaint;
end;

procedure TEqGroupOp.SetSymbol(Value: WideChar);
begin
  FSymbol := Value;
  Repaint;
end;


{ TEqVector }

function TEqVector.CalcHeight: Integer;
begin
  Result:=FEditAreaList.Items[0].Height+ArrowHeight+7;
end;

function TEqVector.CalcWidth: Integer;
begin
  Result:=FEditAreaList.Items[0].Width;
end;

constructor TEqVector.Create(AOwner: TComponent);
begin
  inherited;
  FKindArrow:=[];
  FAlignEA:=aeTop;
  InsertEditArea;
  RefreshEditArea;
end;

function TEqVector.GetMidLine: Integer;
begin
  Result:=Height div 2;
  case FAlignEA of
    aeTop:     Result:=FEditAreaList.Items[0].Height div 2;
    aeBottom:  Result:=ArrowHeight+4+FEditAreaList.Items[0].Height div 2;
  end;
end;

procedure TEqVector.Paint;
var LineTop: Integer;
  procedure DrawArrow;
  begin
    showmessage('TEqVector.Paint');
    Canvas.Pen.Color := Font.Color;
    Canvas.Pen.Style := psSolid;
    Canvas.Rectangle(0, LineTop, Width, LineTop+LineHeight);
    if kaRight in FKindArrow then begin
      Canvas.MoveTo(Width-15, LineTop - ArrowHeight div 2);
      Canvas.LineTo(Width, LineTop);
      Canvas.MoveTo(Width, LineTop+LineHeight div 2);
      Canvas.LineTo(Width-15, LineTop+LineHeight div 2 + ArrowHeight div 2);
    end;
    if kaLeft in FKindArrow then begin
      Canvas.MoveTo(15, LineTop - ArrowHeight div 2);
      Canvas.LineTo(0, LineTop);
      Canvas.MoveTo(0, LineTop+LineHeight div 2);
      Canvas.LineTo(15, LineTop+LineHeight div 2 + ArrowHeight div 2);
    end;
    if kaDouble in FKindArrow then begin
      Canvas.Rectangle(0, LineTop+ArrowHeight, Width, LineTop+ArrowHeight+LineHeight);
    end;
  end;
begin
  case FAlignEA of
    aeTop:
      if kaDouble in FKindArrow then
        LineTop:=FEditAreaList.Items[0].Height
      else
        LineTop:=FEditAreaList.Items[0].Height+ArrowHeight div 2;
    aeBottom:
      if kaDouble in FKindArrow then
        LineTop:=1
      else
        LineTop:=3;
  end;
  SetCanvasFont;
  Canvas.Rectangle(0, 0, Width, Height);
  DrawArrow;
end;

procedure TEqVector.RefreshDimensions;
begin
  Height:=CalcHeight;
  Width:=CalcWidth;
  ArrowHeight:=Font.Size div 5;
  LineHeight:=Font.Size div 10;
end;

procedure TEqVector.RefreshEditArea(AEditAreaIndex: Integer = 0);
begin
  FEditAreaList.Items[0].BkColor:=Parent.BkColor;
  FEditAreaList.Items[0].Font:=Font;
  FEditAreaList.Items[0].Font.Size:=Round(Font.Size*Kp);
  FEditAreaList.Items[0].RefreshDimensions;
  FEditAreaList.Items[0].Index:=0;
  FEditAreaList.Items[0].Left:=0;
  case FAlignEA of
    aeTop:     FEditAreaList.Items[0].Top:=0;
    aeBottom:  FEditAreaList.Items[0].Top:=ArrowHeight+4;
  end;
  Parent.RefreshEquations;
end;

procedure TEqVector.SetAlignEA(const Value: TAlignEA);
begin
  FAlignEA := Value;
  RefreshEditArea;
end;

procedure TEqVector.SetKindArrow(Value: TKindArrow);
begin
  FKindArrow:=Value;
  RefreshEditArea;
end;


{ TEqSimple }
function TEqSimple.CalcHeight: Integer;
begin
  SetCanvasFont;
  Result:=Canvas.TextHeight(Ch);
end;

function TEqSimple.CalcWidth: Integer;
begin
  SetCanvasFont;
  Result:=Canvas.TextWidth(Ch);
end;

function TEqSimple.GetData: string;
begin
  Result:=Ch;
end;

procedure TEqSimple.Paint;
begin
  Canvas.TextOut(0,0,Ch);
end;

procedure TEqSimple.RefreshDimensions;
begin
  Height:=CalcHeight;
  Width:=CalcWidth;
end;

{ TEqSumma }

constructor TEqSumma.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Symbol:=WideChar(8721);
end;











{ TEqMultiply }

constructor TEqMultiply.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Symbol:=WideChar(8719);
end;

{ TEqIntersection }

constructor TEqIntersection.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Symbol:=WideChar(8745);
end;

{ TEqJoin }

constructor TEqJoin.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Symbol:=WideChar(85);
end;

{ TEqCoMult }

constructor TEqCoMult.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Symbol:=WideChar(1062);
end;

{ TEqArrow }

function TEqArrow.CalcHeight: Integer;
begin
  Result:=FEditAreaList.Items[0].Height+ArrowHeight+7;
end;

function TEqArrow.CalcWidth: Integer;
begin
  Result:=FEditAreaList.Items[0].Width * 2;
end;

constructor TEqArrow.Create(AOwner: TComponent);
begin
  inherited;
  Kp:=0.7;
  FKindArrow:=[];
  FAlignEA:=aeTop;
  InsertEditArea;
  RefreshEditArea;
end;

function TEqArrow.GetMidLine: Integer;
begin
  Result:=Height div 2;
  case FAlignEA of
    aeTop:     Result:=FEditAreaList.Items[0].Height+3;
    aeBottom:  Result:=3;
  end;
end;

procedure TEqArrow.Paint;
var LineTop: Integer;
  procedure DrawArrow;
  begin
    showmessage('TEqArrow.Paint');
    Canvas.Pen.Color := Font.Color;
    Canvas.Pen.Style := psSolid;
    Canvas.Rectangle(0, LineTop, Width, LineTop+LineHeight);
    if kaRight in FKindArrow then begin
      Canvas.MoveTo(Width-15, LineTop - ArrowHeight div 2);
      Canvas.LineTo(Width, LineTop);
      Canvas.MoveTo(Width, LineTop+LineHeight div 2);
      Canvas.LineTo(Width-15, LineTop+LineHeight div 2 + ArrowHeight div 2);
    end;
    if kaLeft in FKindArrow then begin
      Canvas.MoveTo(15, LineTop - ArrowHeight div 2);
      Canvas.LineTo(0, LineTop);
      Canvas.MoveTo(0, LineTop+LineHeight div 2);
      Canvas.LineTo(15, LineTop+LineHeight div 2 + ArrowHeight div 2);
    end;
  end;
begin
  case FAlignEA of
    aeTop:     LineTop:=FEditAreaList.Items[0].Height+ArrowHeight div 2;
    aeBottom:  LineTop:=3;
  end;
  SetCanvasFont;
  Canvas.Rectangle(0, 0, Width, Height);
  DrawArrow;
end;

procedure TEqArrow.RefreshDimensions;
begin
  Height:=CalcHeight;
  Width:=CalcWidth;
  ArrowHeight:=Font.Size div 5;
  LineHeight:=Font.Size div 10;
end;

procedure TEqArrow.RefreshEditArea(AEditAreaIndex: Integer = 0);
begin
  FEditAreaList.Items[0].BkColor:=Parent.BkColor;
  FEditAreaList.Items[0].Font:=Font;
  FEditAreaList.Items[0].Font.Size:=Round(Font.Size*Kp);
  FEditAreaList.Items[0].RefreshDimensions;
  FEditAreaList.Items[0].Index:=0;
  FEditAreaList.Items[0].Left:=(CalcWidth-FEditAreaList.Items[0].Width) div 2;
  case FAlignEA of
    aeTop:     FEditAreaList.Items[0].Top:=0;
    aeBottom:  FEditAreaList.Items[0].Top:=ArrowHeight+4;
  end;
  Parent.RefreshEquations;
end;

procedure TEqArrow.SetAlignEA(const Value: TAlignEA);
begin
  FAlignEA := Value;
  RefreshEditArea;
end;

procedure TEqArrow.SetKindArrow(Value: TKindArrow);
begin
  FKindArrow:=Value;
  Repaint;
end;

{ TEqSquare }

function TEqSquare.CalcHeight: Integer;
begin
  Result:=FEditAreaList.Items[0].Height+LineHeight;
end;

function TEqSquare.CalcWidth: Integer;
begin
  Result:=FEditAreaList.Items[0].Width + GalkaLeft + LineHeight;
end;

constructor TEqSquare.Create(AOwner: TComponent);
begin
  inherited;
  Kp:=0.9;

  InsertEditArea;
  RefreshDimensions;
  RefreshEditArea;
end;

function TEqSquare.GetMidLine: Integer;
begin
  Result:=Height div 2 - LineHeight;
end;

procedure TEqSquare.Paint;

  procedure DrawSquare;
  begin
    showmessage('TEqSquare.Paint');
    Canvas.Pen.Color := Font.Color;
    Canvas.Pen.Style := psSolid;
    Canvas.Pen.Width:=LineHeight;
    Canvas.MoveTo(0, FEditAreaList.Items[0].Height div 2);
    Canvas.LineTo(GalkaLeft div 2, FEditAreaList.Items[0].Height);
    Canvas.LineTo(GalkaLeft, 0);
    Canvas.LineTo(FEditAreaList.Items[0].Width+GalkaLeft+LineHeight, 0);
  end;

begin
  SetCanvasFont;
  Canvas.Rectangle(0, 0, Width, Height);
  DrawSquare;
end;

procedure TEqSquare.RefreshDimensions;
begin
  Height:=CalcHeight;
  Width:=CalcWidth;
  GalkaLeft:=Font.Size div 2;
  LineHeight:=Font.Size div 8;
end;

procedure TEqSquare.RefreshEditArea(AEditAreaIndex: Integer = 0);
begin
  FEditAreaList.Items[0].BkColor:=Parent.BkColor;
  FEditAreaList.Items[0].Font:=Font;
  FEditAreaList.Items[0].Font.Size:=Round(Font.Size*Kp);
  FEditAreaList.Items[0].RefreshDimensions;
  FEditAreaList.Items[0].Index:=0;
  FEditAreaList.Items[0].Left:=GalkaLeft+LineHeight;//(CalcWidth-FEditAreaList.Items[0].Width) div 2;
  FEditAreaList.Items[0].Top:=LineHeight;//+Font.Size div 2;//;ArrowHeight+4;

  Parent.RefreshEquations;
end;


{ TEqDivision }

function TEqDivision.CalcHeight: Integer;
begin
  Result:=FEditAreaList.Items[0].Height+ArrowHeight+FEditAreaList.Items[1].Height;
end;

function TEqDivision.CalcWidth: Integer;
begin
  Result:=Max(FEditAreaList.Items[0].Width, FEditAreaList.Items[1].Width);
end;

constructor TEqDivision.Create(AOwner: TComponent);
begin
  inherited;
  Kp:=0.7;
  BeginUpdate;
  InsertEditArea;
  InsertEditArea;
  EndUpdate;
  RefreshEditArea;
end;

function TEqDivision.GetMidLine: Integer;
begin
  Result:=FEditAreaList.Items[0].Height+ArrowHeight div 2;
end;

procedure TEqDivision.Paint;
var LineTop: Integer;
  procedure DrawArrow;
  begin
    Canvas.Pen.Color := Font.Color;
    Canvas.Pen.Style := psSolid;
    Canvas.Rectangle(0, LineTop, Width, LineTop+LineHeight);
  end;
begin     
  LineTop:=FEditAreaList.Items[0].Height+ArrowHeight div 2;
  SetCanvasFont;
  Canvas.Rectangle(0, 0, Width, Height);
  DrawArrow;
end;

procedure TEqDivision.RefreshDimensions;
begin
  Height:=CalcHeight;
  Width:=CalcWidth;
  ArrowHeight:=Font.Size div 5;
  LineHeight:=Font.Size div 10;
end;

procedure TEqDivision.RefreshEA(AEditArea: TEditArea);
begin
  AEditArea.BkColor:=Parent.BkColor;
  AEditArea.Font:=Font;
  AEditArea.Font.Size:=Round(Font.Size*Kp);
  AEditArea.RefreshDimensions;
  AEditArea.Left:=(CalcWidth-AEditArea.Width) div 2;
end;

procedure TEqDivision.RefreshEditArea(AEditAreaIndex: Integer = 0);
begin
  if FUpdateCount>0 then Exit;
  RefreshEA(FEditAreaList.Items[0]);
  FEditAreaList.Items[0].Top:=0;
  RefreshEA(FEditAreaList.Items[1]);
  FEditAreaList.Items[1].Top:=FEditAreaList.Items[0].Height+ArrowHeight;

  Parent.RefreshEquations;
end;

function TEqDivision.GetData: String;
begin
  Result:=Format('EditArea(%s)',[EditAreaList.Items[0].Data])+Format('EditArea(%s)',[EditAreaList.Items[1].Data]);
end;

procedure TEqDivision.SetData(const AValue: String);
var
  i: Integer;
  ExprArray: TExprArray;
begin
  ExprArray:=GetExprData(AValue);
  for i:=0 to Length(ExprArray)-1 do begin
    if ExprArray[i].ClassName = 'EditArea' then if i<FEditAreaList.Count then begin
      FEditAreaList.Items[i].Data:=ExprArray[i].ExprData;
    end;
  end;
end;


{ TEqMatrix }

function TEqMatrix.CalcHeight: Integer;
var i, dy: Integer;
begin
  Result:=0;
  dy:=GetDY;
  for i:=0 to dy-1 do Result:=Result+GetRowHeight(i)+10;
end;

function TEqMatrix.CalcWidth: Integer;
var i, dx: Integer;
begin
  Result:=0;
  dx:=GetDX;
  for i:=0 to dx-1 do Result:=Result+GetColWidth(i)+10;
end;

constructor TEqMatrix.Create(AOwner: TComponent);
begin
  inherited;
  InsertEditArea;
  FCountEA:=0;
  FKindMatrix:=kmSquare;
end;

function TEqMatrix.GetColWidth(ACol: Integer): Integer;
var i, dx: Integer;
begin
  dx:=GetDX;
  i:=ACol;
  Result:=FEditAreaList.Items[i].Width;
  while i<FCountEA do begin
    Result:=Max(Result, FEditAreaList.Items[i].Width);
    Inc(i, dx);
  end;
end;

function TEqMatrix.GetRowHeight(ARow: Integer): Integer;
var i, dy: Integer;
begin
  dy:=GetDY;
  i:=ARow;
  Result:=FEditAreaList.Items[i].Height;
  while i<FCountEA do begin
    Result:=Max(Result, FEditAreaList.Items[i].Height);
    Inc(i, dy);
  end;
end;

function TEqMatrix.GetData: string;
var i: Integer;
begin
  Result:='';
  for i:=0 to FEditAreaList.Count-1 do Result:=Result+Format('EditArea(%s)',[EditAreaList.Items[i].Data]);
end;

procedure TEqMatrix.SetData(const AValue: String);
var
  i: Integer;
  ExprArray: TExprArray;
begin
  ExprArray:=GetExprData(AValue);
  CountEA:=Length(ExprArray);
  for i:=0 to Length(ExprArray)-1 do begin
    if ExprArray[i].ClassName = 'EditArea' then if i<FEditAreaList.Count then begin
      FEditAreaList.Items[i].Data:=ExprArray[i].ExprData;
    end;
  end;
  Parent.RefreshRecurse;
  Parent.MainArea.Change;
end;

function TEqMatrix.GetDX: Integer;
begin
  Result:=0;
  case FKindMatrix of
    kmHoriz: Result:=FCountEA;
    kmVert:  Result:=1;
    kmSquare: begin
      Result:=Round(Sqrt(FCountEA));
    end;
  end;
end;

function TEqMatrix.GetDY: Integer;
begin
  Result:=0;
  case FKindMatrix of
    kmHoriz:  Result:=1;
    kmVert:   Result:=FCountEA;
    kmSquare: begin
      Result:=Round(Sqrt(FCountEA));
    end;
  end;
end;

function TEqMatrix.GetMidLine: Integer;
begin
  Result:=Height div 2;
end;

procedure TEqMatrix.Paint;
begin
  SetCanvasFont;
  Canvas.Rectangle(0, 0, Width, Height);
end;

procedure TEqMatrix.RefreshDimensions;
begin
  Height:=CalcHeight;
  Width:=CalcWidth;
end;

procedure TEqMatrix.RefreshEditArea(AEditAreaIndex: Integer = 0);
var i,j, dx, dy, CommonHeight, CommonWidth, RowHeight, ColWidth: Integer;
begin
  if FUpdateCount>0 then Exit;
  dx:=GetDX; dy:=GetDY;
  for i:=0 to FCountEA-1 do RefreshEA(FEditAreaList.Items[i]);
  CommonHeight:=0;
  for i:=0 to dy-1 do begin
    RowHeight:=GetRowHeight(i);
    for j:=0 to dx-1 do
      FEditAreaList.Items[i*dx+j].Top:=CommonHeight+(RowHeight-FEditAreaList.Items[i*dx+j].Height) div 2;

    Inc(CommonHeight,RowHeight+10);
  end;
  CommonWidth:=0;
  for j:=0 to dx-1 do begin
    ColWidth:=GetColWidth(j);
    for i:=0 to dy-1 do begin
      FEditAreaList.Items[i*dx+j].Left:=CommonWidth+(ColWidth-FEditAreaList.Items[i*dx+j].Width) div 2;
    end;
    Inc(CommonWidth,ColWidth+10);
  end;

  Parent.RefreshEquations;
end;

procedure TEqMatrix.RefreshEA(AEditArea: TEditArea);
begin
  AEditArea.BkColor:=Parent.BkColor;
  AEditArea.Font.Assign(Font);
  AEditArea.Font.Size:=Round(Font.Size*Kp);
  AEditArea.RefreshDimensions;
  AEditArea.Index:=FEditAreaList.IndexOf(AEditArea);
end;

procedure TEqMatrix.SetKindMatrix(const Value: TKindMatrix);
begin
  FKindMatrix := Value;
  RefreshEditArea;
end;

procedure TEqMatrix.SetCountEA(const Value: Integer);
begin
  FCountEA:=EditAreaList.Count;
  BeginUpdate;
  while FCountEA < Value do begin
    FEditAreaIndex:=FCountEA-1;
    InsertEditArea;
    Inc(FCountEA);
  end;
  EndUpdate;
end;


{ TBezierLink }

procedure TEVSBezierLink.Changed(aFlags : TGraphChangeFlags);
begin
  inherited;
  if gcView in aFlags  then
    FPolyline := GetBezierPolyline(Polyline);
end;

procedure TEVSBezierLink.DrawBody(aCanvas : TCanvas);
var
  vOldPenStyle     :TPenStyle;
  vOldBrushStyle   :TBrushStyle;
  vModifiedPolyline:TPoints;
  vAngle           :Double;
  vPtRect          :TRect;
  vCntr            :Integer;
  vBckPen          :TPen;
begin
  vModifiedPolyline := nil;
  if PointCount = 1 then
  begin
    vPtRect := MakeSquare(Points[0], Pen.Width div 2);
    owner.memo1.Lines.Add('=============================');
    while not IsRectEmpty(vPtRect) do begin
      aCanvas.Ellipse(vPtRect.Left, vPtRect.Top, vPtRect.Right, vPtRect.Bottom);
      InflateRect(vPtRect, -1, -1);
    end;
  end
  else if PointCount >= 2 then
  begin

    if (BeginStyle <> lsNone) or (EndStyle <> lsNone) then begin
      vOldPenStyle := aCanvas.Pen.Style;
      aCanvas.Pen.Style := psSolid;
      try
        if BeginStyle <> lsNone then begin
          if (vModifiedPolyline = nil) then vModifiedPolyline := Copy(Polyline, 0, PointCount);
          vAngle := LineSlopeAngle(Points[1], Points[0]);
          vModifiedPolyline[0] := DrawPointStyle(aCanvas, Points[0],
            vAngle, BeginStyle, BeginSize);
        end;
        if (EndStyle <> lsNone) then begin
          if (vModifiedPolyline = nil) then vModifiedPolyline := Copy(Polyline, 0, PointCount);
          vAngle := LineSlopeAngle(Points[PointCount - 2], Points[PointCount - 1]);
          vModifiedPolyline[PointCount - 1] := DrawPointStyle(aCanvas, Points[PointCount - 1],
            vAngle, EndStyle, EndSize);;
        end;
      finally
        aCanvas.Pen.Style := vOldPenStyle;
      end;
    end;
    
    vOldBrushStyle := aCanvas.Brush.Style;
    vBckPen := TPen.Create;
    vBckPen.Assign(aCanvas.Pen);
    try
      aCanvas.Brush.Style := bsClear;
      if Selected {and ( not Dragging) }then
      begin
        vOldPenStyle := aCanvas.Pen.Style;
        try
          { direction draw  }
          aCanvas.Pen.Style := psDash;
          aCanvas.Polyline([Points[0],Points[1]]);
          aCanvas.Polyline([Points[PointCount -2],Points[PointCount -1]]);
          
          { not usage : In case of a multi bezier draw all the in between control lines too. Has never been tested. }
          vCntr := 2;
          while vCntr < PointCount - 3 do
          begin
            aCanvas.MoveTo(Points[vCntr].X, Points[vCntr].Y);
            aCanvas.LineTo(Points[vCntr+1].X, Points[vCntr+1].Y);
            Inc(vCntr, 1);
          end;
        finally
          aCanvas.Pen.Style := vOldPenStyle;
        end;
      end;

      { Polyline draw }
      if vModifiedPolyline <> nil then begin
        aCanvas.PolyBezier(vModifiedPolyline);
      end else begin
        aCanvas.PolyBezier(Polyline);
      end;
       
    finally
      aCanvas.Brush.Style := vOldBrushStyle;
      aCanvas.Pen.Assign(vBckPen);
      vBckPen.Free;
    end;
  end;
  vModifiedPolyline := nil;
end;

procedure TEVSBezierLink.DrawHighlight(aCanvas: TCanvas);
var
  vPtRect : TRect;
  vFirst,
  vLast   : Integer;
  vPen    : TPen;
begin
  vPen := TPen.Create;
  try
    vPen.Assign(aCanvas.Pen);
    //if Selected then
    //  aCanvas.pen.Color := FSelectedColor;
    if PointCount > 1 then
    begin
      if (MovingPoint >= 0) and (MovingPoint < PointCount) then
      begin
        if MovingPoint > 0 then
          vFirst := MovingPoint - 1
        else
          vFirst := MovingPoint;
        if MovingPoint < PointCount - 1 then
          vLast := MovingPoint + 1
        else
          vLast := MovingPoint;
        aCanvas.PolyBezier(Copy(Polyline, vFirst, vLast - vFirst + 1));
      end
      else
        aCanvas.PolyBezier(Polyline);
    end
    else if PointCount = 1 then
    begin
      vPtRect := MakeSquare(Points[0], aCanvas.Pen.Width);
      aCanvas.Ellipse(vPtRect.Left, vPtRect.Top, vPtRect.Right, vPtRect.Bottom);
    end;
  finally
    aCanvas.Pen.Assign(vPen);
    vPen.Free;
  end;
end;

procedure TEVSBezierLink.MouseDown(aButton: TMouseButton; aShift: TShiftState;
  const aPt: TPoint);
begin
  inherited;
  if Owner.CommandMode = cmInsertLink then
    FCreateByMouse := True;
end;

function TEVSBezierLink.IndexOfNearestLine(const Pt : TPoint;
  Neighborhood : integer) : integer;
var
  I: integer;
  NearestDistance: double;
  Distance: double;
begin
  Result := -1;
  NearestDistance := MaxDouble;
  for I := 0 to Length(FPolyline) - 2 do
  begin
    Distance := DistanceToLine(FPolyline[I], FPolyline[I + 1], Pt);
    if (Trunc(Distance) <= Neighborhood) and (Distance < NearestDistance) then
    begin
      NearestDistance := Distance;
      Result := I;
    end;
  end;
end;

function TEVSBezierLink.RelativeHookAnchor(RefPt : TPoint) : TPoint;
  function ValidAnchor(Index: integer): boolean;
  var
    GraphObject: TGraphObject;
  begin
    GraphObject := HookedObjectOf(Index);
    Result := not Assigned(GraphObject) or GraphObject.IsLink;
  end;

var
  Pt: TPoint;
  Line: integer;
  Index: integer;
begin
  Line := IndexOfNearestLine(RefPt, MaxInt);
  if Line >= 0 then
  begin
    Pt := NearestPointOnLine(FPolyline[Line], FPolyline[Line + 1], RefPt);
    Index := IndexOfPoint(Pt, NeighborhoodRadius);
    if Index < 0 then
      Result := Pt
    else if ValidAnchor(Index) then
      Result := FPolyline[Index]
    else
    begin
      if (Index = 0) and ValidAnchor(Index + 1) then
        Result := FPolyline[Index + 1]
      else if (Index = Length(FPolyline) - 1) and ValidAnchor(Index - 1) then
        Result := FPolyline[Index - 1]
      else
        Result := FixHookAnchor;
    end;
  end
  else if PointCount = 1 then
    Result := fPoints[0]
  else
    Result := RefPt;
end;

procedure TEVSBezierLink.MouseUp(aButton: TMouseButton; aShift: TShiftState;
  const aPt: TPoint);
function PointsEqual ( pt1, PT2:TPoint):Boolean;
begin
  Result := (pt1.X = pt2.X) and (pt1.Y = PT2.Y);
end;
var
  vStartPt, vEndPt : TPoint;
  vmidPt1, vMidPt2 : TPoint;
begin
  inherited;
  if FCreateByMouse then
  begin
    if Assigned(Source) and (PointsEqual(Points[0], TGraphNode(Source).FixHookAnchor)) then
      vStartPt := Points[1]
    else
      vStartPt := points[0];
    if Assigned(Target) and (PointsEqual(Points[PointCount -1],TGraphNode(Target).FixHookAnchor)) then
      vEndPt := Points[PointCount -2]
    else
      vEndPt := Points[PointCount -1];
    vmidPt1.X := (vEndPT.X - vStartPt.X) div 4;
    vmidpt1.y := (vEndPT.Y - vStartPt.Y) div 4;
    vmidpt2.X := vEndPt.X - vmidPt1.x;
    vMidPt2.Y := vEndPt.Y - vmidPt1.Y;
    vmidpt1.X := vStartPt.X + vmidPt1.x;
    vMidPt1.Y := vStartPt.Y + vmidPt1.Y;
    InsertPoint(1, vmidPt1);
    InsertPoint(2, vMidPt2);
    FCreateByMouse := False;
  end;
end;

function TEVSBezierLink.QueryHitTest(const aPt: TPoint): DWORD;
var
  vNeighborhood : Integer;
  vCntr         : Integer;
  vPtCount      : Integer;
begin
  vNeighborhood := NeighborhoodRadius;
  for vCntr := PointCount - 1 downto 0 do
    if PtInRect(MakeSquare(Points[vCntr], vNeighborhood), aPt) then
    begin
      if Selected then
        Result := GHT_POINT or (vCntr shl 16)
      else
        Result := GHT_CLIENT;
      Exit;
    end;
  vPtCount := Length(FPolyline);
  for vCntr := 0 to vPtCount - 2 do
  begin
    if DistanceToLine(FPolyline[vCntr], FPolyline[vCntr + 1], aPt) <= vNeighborhood then
    begin
      if Selected then
        Result := GHT_LINE or (vCntr shl 16) or GHT_CLIENT
      else
        Result := GHT_CLIENT;
      Exit;
    end;
  end;
  if (TextRegion <> 0) and (goShowCaption in Options) and PtInRegion(TextRegion, aPt.X, aPt.Y) then
    Result := GHT_CAPTION or GHT_CLIENT
  else
    Result := GHT_NOWHERE;
end;

procedure TEVSBezierLink.UpdateChangeMode(aHT: DWORD; aShift: TShiftState);
begin
  inherited UpdateChangeMode(aHT, aShift);
  if ChangeMode = lcmInsertPoint then  // hack to disable adding more points to the curve remove once I ficure out how to proccess the addition.
    ChangeMode := lcmMovePolyline;
end;

function TEVSBezierLink.GetBezierPolyline(CPs: array of TPoint): TPoints;
const
  cBezierTolerance = 0.00001;
  half = 0.5;
var
   I, J, ArrayLen, ResultCnt: Integer;
   CtrlPts: array[0..3] of TFloatPoint;

  function FixedPoint(const FP: TFloatPoint): TPoint;
  begin
    Result.X := Round(FP.X * 65536);
    Result.Y := Round(FP.Y * 65536);
  end;

  function FloatPoint(const P: TPoint): TFloatPoint;overload;
  const
    F = 1 / 65536;
  begin
    with P do begin
      Result.X := X * F;
      Result.Y := Y * F;
    end;
  end;

  procedure RecursiveCBezier(const p1, p2, p3, p4: TFloatPoint);
   var
     p12, p23, p34, p123, p234, p1234: TFloatPoint;
   begin
     // assess flatness of curve ...
     // http://groups.google.com/group/comp.graphics.algorithms/tree/browse_frm/thread/d85ca902fdbd746e
     if abs(p1.x + p3.x - 2*p2.x) + abs(p2.x + p4.x - 2*p3.x) +
        abs(p1.y + p3.y - 2*p2.y) + abs(p2.y + p4.y - 2*p3.y) < cBezierTolerance then
     begin
       if ResultCnt = Length(Result) then
         SetLength (Result, Length(Result) + 128);
       Result[ResultCnt] := FixedPoint(p4);
       Inc(ResultCnt);
     end else begin
       p12.X := (p1.X + p2.X) *half;
       p12.Y := (p1.Y + p2.Y) *half;
       p23.X := (p2.X + p3.X) *half;
       p23.Y := (p2.Y + p3.Y) *half;
       p34.X := (p3.X + p4.X) *half;
       p34.Y := (p3.Y + p4.Y) *half;
       p123.X := (p12.X + p23.X) *half;
       p123.Y := (p12.Y + p23.Y) *half;
       p234.X := (p23.X + p34.X) *half;
       p234.Y := (p23.Y + p34.Y) *half;
       p1234.X := (p123.X + p234.X) *half;
       p1234.Y := (p123.Y + p234.Y) *half;
       RecursiveCBezier(p1, p12, p123, p1234);
       RecursiveCBezier(p1234, p234, p34, p4);
     end;
   end;

begin
   //first check that the 'control_points' count is valid ...
   ArrayLen := Length(CPs);
   if (ArrayLen < 4) or ((ArrayLen -1) mod 3 <> 0) then Exit;

   SetLength(Result, 128);
   Result[0] := CPs[0];
   ResultCnt := 1;
   for I := 0 to (ArrayLen div 3)-1 do begin
     for J := 0 to 3 do
       CtrlPts[J] := FloatPoint(CPs[I*3 +J]);
     RecursiveCBezier(CtrlPts[0], CtrlPts[1], CtrlPts[2], CtrlPts[3]);
   end;
   SetLength(Result, ResultCnt);
end;


{ TSplineLink }

procedure TSplineLink.Changed(Flags: TGraphChangeFlags);
begin
  inherited Changed(Flags);
  //if gcView in Flags  then

  //  FControlPoints := GetCatmullromLine(Polyline);
end;

constructor TSplineLink.Create(AOwner: TSimpleGraph);
begin
  inherited;
end;

constructor TSplineLink.CreateNew(AOwner: TSimpleGraph;
  ASource: TGraphObject; const Pts: array of TPoint;
  ATarget: TGraphObject);
begin

end;

destructor TSplineLink.Destroy;
begin

  inherited;
end;

procedure TSplineLink.DrawBody(Canvas: TCanvas);
const
	zoom = 1;
var
  ModifiedPolyline:TPoints;
  Angle:Double;

  I:Integer;
  Pt1, Pt2: TFloatPoint;
  segment: integer;
  len: single;
  count: integer;
  inpoints, outpoints: TFloatPoints;
  rx,ry: integer;

  OldPenStyle     :TPenStyle;
  OldBrushStyle   :TBrushStyle;
  BckPen: TPen;
  PtRect:TRect;
  p1,p2:Tpoint;
  { Points ¸¦ FloatPoints : array of single ·Î }
  function IntPtsToSinglePts(Points: TPoints; cnt:integer): TFloatPoints;
  var
    I:integer;
  begin
    setlength(result, cnt);
    for I:=0 to high(Points) do
      Result[I] := intptTosinglePt(Points[I]);
  end;


begin
  if selected and FCreateByMouse then { when mouse drag, show line }
    inherited DrawBody(canvas);

  ModifiedPolyline := nil;
  if fPointcount <= 2 then exit;    { fPointCount 2°³°¡ µé¾î°¡´Â °æ¿ì interpolateCurve ´Â Ã³¸®ÇÒ¼ö¾øÀ½}

  { Catmull-rom Process }
  fSegmentCount := 20;      // setting
  inpoints :=  IntPtsToSinglePts(fPoints, fPointCount);
  fcatcount:= (fPointCount-1) * (fsegmentcount+1);
  setlength(fcatpoints, fcatcount);
  count := 0;

  OldBrushStyle := Canvas.Brush.Style;
  BckPen := TPen.Create;
  BckPen.Assign(Canvas.Pen);
  Canvas.Brush.Style := bsClear;
  OldPenStyle := Canvas.Pen.Style;
  Canvas.Pen.Style := psSolid;


  for segment:=-1 to High(inpoints)-2 do   { if -3, first, last segment not show  }
  begin
    len:= interpolateCurve(inpoints, segment, outpoints, fsegmentcount, true); // get 10 points on the curve segment
    for I:= 0 to high(outpoints) do
    begin
      rx := round(outpoints[i].x);
      ry := round(outpoints[i].y);

			if (i = 0) and (segment = -1) then
        Canvas.MoveTo(rx, ry)
			else Canvas.LineTo(rx, ry);

      {canvas.pen.Color:= clRed;
      Canvas.Rectangle(rx-3, ry-3, rx+3, ry+3); }

      if count >= fcatcount then   { catmull-rom °è»ê¿¡¼­ ¿©ºÐÀÇ point Ã³¸® }
      begin
        setlength(fcatpoints, fcatcount + 1);
        fcatpoints[fcatcount] := makepoint(rx, ry);
        inc(count);
        fcatcount := count;
        
        //owner.memo1.Lines.Add('over:' + Pointtostring(fcatpoints[fcatcount]));

      end else
      begin
        fcatpoints[count] := makepoint(rx, ry);
        inc(count);
      end;
    end;
  end;

  { Catmull-rom Duplicate Data }
  setlength(fdupcatpoints, fcatcount);
  fdupcatpoints := copy(fcatpoints, 0, fcatcount);
  duplicateremovepoint(fdupcatpoints, fdupcatcount);

  { line begin end style - arrow }
  if (BeginStyle <> lsNone) or (EndStyle <> lsNone) then
  begin
      OldPenStyle := Canvas.Pen.Style;
      Canvas.Pen.Style := psSolid;

      if BeginStyle <> lsNone then begin
          if (ModifiedPolyline = nil) then ModifiedPolyline := Copy(Polyline, 0, PointCount);
          Angle := LineSlopeAngle(Points[1], Points[0]);
          ModifiedPolyline[0] := DrawPointStyle(Canvas, Points[0],Angle, BeginStyle, BeginSize);
      end;
      if (EndStyle <> lsNone) then begin
          if (ModifiedPolyline = nil) then ModifiedPolyline := Copy(fdupcatpoints, 0, fdupcatcount);
          Angle := LineSlopeAngle(fdupcatpoints[fdupcatcount-2], fdupcatpoints[fdupcatcount-1]);
          ModifiedPolyline[fdupcatcount-1] := DrawPointStyle(Canvas, fdupcatpoints[fdupcatcount-1],Angle, EndStyle, EndSize);;
      end;
      Canvas.Pen.Style := OldPenStyle;
  end;

  (*
  //PtRect := BoundsRectofPoints(FPoints);
  QueryVisualRect(PtRect);
  p1 := PtRect.TopLeft;
  p2 := PtRect.BottomRight;
  Canvas.Rectangle(p1.X, p1.Y, p2.X ,p2.Y);
  *)
  
  Canvas.Brush.Style := OldBrushStyle;
  Canvas.Pen.Assign(BckPen);
  BckPen.Free;

  ModifiedPolyline := nil;
end;

//Single dimention catmull-Rom function
function TSplineLink.CatMullRom(a, b, c, d, t: TFloat): TFloat;
begin
    result:=0.5*( 2*b + (c-a)*t +
                ( 2*a - 5*b + 4*c-d)*t*t +
                ( 3*b - a - 3*c + d)*t*t*t );
end;

function TSplineLink.GetPointOnCurve(const p1, p2, p3, p4: TFloatPoint;
  t: TFloat): TFloatPoint;
begin
    Result.x := CatMullRom(p1.x,p2.x,p3.x,p4.x, t);
    Result.y := CatMullRom(p1.y,p2.y,p3.x,p4.y, t);
end;

function TSplineLink.FPtToPt(const FP: TFloatPoint): TPoint;
begin
    Result.X := Round(FP.X * 65536);
    Result.Y := Round(FP.Y * 65536);
end;

function TSplineLink.IntptTosinglept(const P: TPoint): TFloatPoint;
const
    F = 1 / 65536;
begin
    with P do begin
      Result.X := X;// * F;
      Result.Y := Y;// * F;
    end;
end;

function TSplineLink.GetCatmullromLine(CPs: array of TPoint): TPoints;
type
  TVector2f = record
    x, y: TFloat;
  end;

  TVecarr = array of TVector2f;
const
  cBezierTolerance = 0.00001;
  half = 0.5;    
var
  PointLen, ResultCnt, I,J: integer;
  CtrlPts: array[0..3] of TFloatPoint;
begin
  PointLen := Length(CPs);
  if (PointLen < 4) or ((PointLen -1) mod 3 <> 0) then Exit;

  SetLength(Result, 128);
  Result[0] := CPs[0];

  ResultCnt := 1;
  for I := 0 to (PointLen div 3)-1 do begin
    for J := 0 to 3 do
      CtrlPts[J] := IntpttosinglePt(CPs[I*3 +J]);
    //showmessage(inttostr(FixedPoint(CtrlPts[0]).x));

    Result[0] := FPttoPt(GetPointOnCurve(CtrlPts[0], CtrlPts[1], CtrlPts[2], CtrlPts[3],3));
    Result[1] := FPttoPt(GetPointOnCurve(CtrlPts[0], CtrlPts[1], CtrlPts[2], CtrlPts[3],3));
    Result[2] := FPttoPt(GetPointOnCurve(CtrlPts[0], CtrlPts[1], CtrlPts[2], CtrlPts[3],3));
    Result[3] := FPttoPt(GetPointOnCurve(CtrlPts[0], CtrlPts[1], CtrlPts[2], CtrlPts[3],3));
    //RecursiveCBezier(CtrlPts[0], CtrlPts[1], CtrlPts[2], CtrlPts[3]);
  end;
  SetLength(Result, ResultCnt);
   
end;

procedure TSplineLink.MouseDown(Button: TMouseButton; Shift: TShiftState; const Pt: TPoint);
begin
  inherited MouseDown(Button,Shift,Pt);
  if Owner.CommandMode = cmInsertLink then
    FCreateByMouse := True;
end;

function TSplineLink.PointsEqual(pt1, PT2: TPoint): Boolean;
begin
  Result := (pt1.X = pt2.X) and (pt1.Y = PT2.Y);
end;

procedure TSplineLink.MouseUp(Button: TMouseButton; Shift: TShiftState; const Pt: TPoint);
var
  StartPt, EndPt : TPoint;
  midPt1, MidPt2 : TPoint;
  pt1,pt2,pt3,pt4:TPoint;
begin

  inherited mouseup(button, shift,pt);
  if FCreateByMouse then
  begin

    if Assigned(Source) and (PointsEqual(Points[0], TGraphNode(Source).FixHookAnchor)) then
      StartPt := Points[1]
    else
      StartPt := points[0];

    if Assigned(Target) and (PointsEqual(Points[PointCount -1],TGraphNode(Target).FixHookAnchor)) then
      EndPt := Points[PointCount -2]
    else
      EndPt := Points[PointCount -1];

    {0,1,2,3,4,5}
    Pt1.X := (EndPT.X - StartPt.X) div 6;
    Pt1.y := (EndPT.Y - StartPt.Y) div 6;
    Pt2.X := EndPt.X - Pt1.x;
    Pt2.Y := EndPt.Y - Pt1.Y;

    Pt3.X := StartPt.X + Pt1.X + Pt1.X;
    Pt3.Y := StartPt.Y + Pt1.Y + Pt1.Y;

    Pt4.X := Pt3.X + Pt1.X;
    Pt4.Y := Pt3.Y + Pt1.Y;
    
    Pt1.X := StartPt.X + Pt1.x;
    Pt1.Y := StartPt.Y + Pt1.Y;

    AddBreakPoint(Pt1);
    AddBreakPoint(Pt2);
    AddBreakPoint(Pt3);
    AddBreakPoint(Pt4);
    //InsertPoint(5, Pt4);
    FCreateByMouse := False;
  end;
end;

procedure TSplineLink.MouseMove(Shift: TShiftState; const Pt: TPoint);
begin
  inherited MouseMove(Shift, Pt);

  if fCreateByMouse then
  begin
    //Owner.Canvas.MoveTo
  end;
  
end;


procedure TSplineLink.UpdateChangeMode(hit: DWORD; Shift: TShiftState);
begin
  inherited UpdateChangeMode(hit, Shift);
  if ChangeMode = lcmInsertPoint then  // hack to disable adding more points to the curve remove once I ficure out how to proccess the addition.
    ChangeMode := lcmMovePolyline;
end;


{Points: ÇöÁ¦ ¸ðµç Æ÷ÀÎÆ®µé
 segment: ±¸°£  0~ pointcount -3 ¿©±â¼­ -3Àº Ã¹±¸°£, ÀÚÁö¸·±¸°£, pointcount-1 -2
 outputpoint
 amountOfPoints ±¸°£ÀÇ ÃÑ ³ª´©´Â ¼ö
 IsaddLastPoint ¸¶Áö¸·±¸°£¿¡ Æ÷ÀÎÆ®¸¦ ³Ö´Â°¡
 ¸®ÅÏ: ±¸°£±æÀÌ
}
function TSplineLink.interpolateCurve(const points: TFloatPoints;
  segment: integer; var outpoints: TFloatPoints;
  amountOfPoints: integer; IsaddLastPoint: boolean): single;
var
  t0, t1, t2, t3: single;
  segment_length: single;
  t: single;
	A1, A2, A3, B1, B2, C: TFloatPoint;
	first_point_index: integer;
	first_curve_point: integer;
	last_curve_point: integer;
	last_point_idx: integer;
	pointidx: integer;

  function GetT(t: single; p0: TFloatPoint; p1: TFloatPoint): single;
  const alpha = 0.5; //set from 0-1
  var
    a, b, c: single;
  begin
    a := power((p1.x - p0.x), 2.0) + power((p1.y - p0.y), 2.0);
    b := power(a, 0.5);
    c := power(b, alpha);

    result := (c + t);
  end;

begin

	first_point_index:= 0 + segment;
	first_curve_point:= 1 + segment;
	last_curve_point:= 2 + segment;
	last_point_idx:= 3 + segment;

	t0 := 0.0;
	t1 := GetT(t0, points[first_point_index], points[first_curve_point]);
	t2 := GetT(t1, points[first_curve_point], points[last_curve_point]);	
	t3 := GetT(t2, points[last_curve_point], points[last_point_idx]);

  segment_length := ((t2 - t1) / amountOfPoints);

	t := t1;

	setlength(outpoints, amountOfPoints + 1); // expected amout of points (it might not be actual amout in the end, it depends on your curve control points.)
	pointidx:= 0;

  while (true) do
	begin
	
		A1.x := (t1 - t) / (t1 - t0) * points[first_point_index].x + (t - t0) / (t1 - t0) * points[first_curve_point].x;
		A1.y := (t1 - t) / (t1 - t0) * points[first_point_index].y + (t - t0) / (t1 - t0) * points[first_curve_point].y;

		A2.x := (t2 - t) / (t2 - t1) * points[first_curve_point].x + (t - t1) / (t2 - t1) * points[last_curve_point].x;
		A2.y := (t2 - t) / (t2 - t1) * points[first_curve_point].y + (t - t1) / (t2 - t1) * points[last_curve_point].y;

		A3.x := (t3 - t) / (t3 - t2) * points[last_curve_point].x + (t - t2) / (t3 - t2) * points[last_point_idx].x;
		A3.y := (t3 - t) / (t3 - t2) * points[last_curve_point].y + (t - t2) / (t3 - t2) * points[last_point_idx].y;

		B1.x := (t2 - t) / (t2 - t0) * A1.x + (t - t0) / (t2 - t0) * A2.x;
		B1.y := (t2 - t) / (t2 - t0) * A1.y + (t - t0) / (t2 - t0) * A2.y;

		B2.x := (t3 - t) / (t3 - t1) * A2.x + (t - t1) / (t3 - t1) * A3.x;
		B2.y := (t3 - t) / (t3 - t1) * A2.y + (t - t1) / (t3 - t1) * A3.y;

		C.x := (t2 - t) / (t2 - t1) * B1.x + (t - t1) / (t2 - t1) * B2.x;
		C.y := (t2 - t) / (t2 - t1) * B1.y + (t - t1) / (t2 - t1) * B2.y;

		// Add point		
		outpoints[pointidx] := C;
		pointidx:= pointidx + 1; // next point

		t := t + segment_length;

		if not (t < t2) then
    begin
			// add last point.
	  	if IsaddLastPoint = true then begin
				setlength(outpoints, pointidx + 1);
				outpoints[pointidx] := points[last_curve_point];
	   	end else
			  setlength(outpoints, pointidx); // final
	  	break;
		end;
	end;

	result:= t;

end;

function TSplineLink.QueryHitTest(const Pt: TPoint): DWORD;
var
  Neighborhood : Integer;
  I : Integer;
  PtIndex: integer;
  minPt, beforePt, afterPt: TPoint;
begin
  //inherited QueryHitTest(Pt);

  { ¸¶¿ì½º°¡ Point À§¿¡ ÀÖ´ÂÁö °Ë»ç }
  Neighborhood := NeighborhoodRadius;
  for I := PointCount - 1 downto 0 do
    if PtInRect(MakeSquare(Points[I], Neighborhood), Pt) then
    begin
      if Selected then
        Result := GHT_POINT or (I shl 16)
      else
        Result := GHT_CLIENT;
      Exit;
    end;

  { Point°¡ LineÀ§¿¡ ÀÖ´ÂÁö °Ë»ç }
  for I := 0 to Length(fdupcatpoints)-2 do
  begin
    if DistanceToLine(fdupcatpoints[I], fdupcatpoints[I+1], Pt) <= Neighborhood then
    begin
      if Selected then
        Result := GHT_LINE or (I shl 16) or GHT_CLIENT
      else
        Result := GHT_CLIENT;
      Exit;
    end;
  end;
  
  if (TextRegion <> 0) and (goShowCaption in Options) and PtInRegion(TextRegion, Pt.X, Pt.Y) then
    Result := GHT_CAPTION or GHT_CLIENT
  else
    Result := GHT_NOWHERE;
end;

{ movingpoint : point ÀÇ ÀÌµ¿°Å¸® }
procedure TSplineLink.DrawHighlight(Canvas: TCanvas);
var
  PtRect: TRect;
  First,Last: Integer;
  Pen    : TPen;
begin
  //inherited DrawHighlight(Canvas);

  //owner.memo1.Lines.Add('moving point:'+inttostr(MovingPoint));
  Pen := TPen.Create;
  Pen.Assign(Canvas.Pen);
  //if Selected then Canvas.pen.Color := clblue;

  if fdupcatcount > 1 then
  begin
      if (MovingPoint >= 0) and (MovingPoint < fdupcatcount) then
      begin
        if MovingPoint > 0 then
          First := MovingPoint - 1
        else First := MovingPoint;

        if MovingPoint < fdupcatcount - 1 then
          Last := MovingPoint + 1
        else Last := MovingPoint;

        Canvas.PolyBezier(Copy(fdupcatPoints, First, Last - First + 1));  { ÀÌµ¿½ÃÅ´ }
      end
      else
        Canvas.PolyBezier(fdupcatPoints);
  end
  else if PointCount = 1 then
  begin
      PtRect := MakeSquare(fdupcatPoints[0], Canvas.Pen.Width);
      Canvas.Ellipse(PtRect.Left, PtRect.Top, PtRect.Right, PtRect.Bottom);
  end;
  
  Canvas.Pen.Assign(Pen);
  Pen.Free;
end;

function TSplineLink.IndexOfNearestLine(const Pt: TPoint;
  Neighborhood: integer): integer;
var
  I: integer;
  NearestDistance: double;
  Distance: double;
begin
  Result := -1;
  NearestDistance := MaxDouble;
  for I := 0 to Length(fPoints) - 2 do
  begin
    Distance := DistanceToLine(fPoints[I], fPoints[I + 1], Pt);
    if (Trunc(Distance) <= Neighborhood) and (Distance < NearestDistance) then
    begin
      NearestDistance := Distance;
      Result := I;
    end;
  end;
end;

function TSplineLink.RelativeHookAnchor(RefPt: TPoint): TPoint;

  function ValidAnchor(Index: integer): boolean;
  var
    GraphObject: TGraphObject;
  begin
    GraphObject := HookedObjectOf(Index);
    Result := not Assigned(GraphObject) or GraphObject.IsLink;
  end;

var
  Pt: TPoint;
  Line: integer;
  Index: integer;
begin
  Line := IndexOfNearestLine(RefPt, MaxInt);
  if Line >= 0 then
  begin
    Pt := NearestPointOnLine(fPoints[Line], fPoints[Line + 1], RefPt);
    Index := IndexOfPoint(Pt, NeighborhoodRadius);
    if Index < 0 then
      Result := Pt
    else if ValidAnchor(Index) then
      Result := fPoints[Index]
    else
    begin
      if (Index = 0) and ValidAnchor(Index + 1) then
        Result := fPoints[Index + 1]
      else if (Index = Length(fPoints) - 1) and ValidAnchor(Index - 1) then
        Result := fPoints[Index - 1]
      else
        Result := FixHookAnchor;
    end;
  end
  else if PointCount = 1 then
    Result := fPoints[0]
  else
    Result := RefPt;
end;

procedure TSplineLink.QueryVisualRect(out Rect: TRect);
var
  TextRect: TRect;
  Margin: Integer;
  Angle: Double;
  p1, p2:Tpoint;
begin
  //Rect := BoundsRect;    { modify }
  if fCreateByMouse then
    Rect := BoundsRectofPoints(FPoints)
  else
    Rect := BoundsRectofPoints(fdupcatpoints);

  Margin := (Pen.Width div 2) + 1;
  InflateRect(Rect, Margin+10, Margin+10);

  if PointCount >= 2 then
  begin
    if BeginStyle <> lsNone then
    begin
      Angle := LineSlopeAngle(fPoints[1], fPoints[0]);
      UnionRect(Rect, PointStyleRect(fPoints[0], Angle, BeginStyle, BeginSize)); { }
    end;
    if EndStyle <> lsNone then
    begin
      Angle := LineSlopeAngle(fPoints[PointCount - 2], fPoints[PointCount - 1]);
      UnionRect(Rect, PointStyleRect(fPoints[PointCount - 1], Angle, EndStyle, EndSize));
      //Angle := LineSlopeAngle(fdupcatpoints[fdupcatCount - 2], fdupcatpoints[fdupcatCount - 1]);
      //UnionRect(Rect, PointStyleRect(fdupcatpoints[fdupcatCount - 1], Angle, EndStyle, EndSize));
    end;
  end;

  if (TextRegion <> 0) and (goShowCaption in Options) then
  begin
    GetRgnBox(TextRegion, TextRect);
    UnionRect(Rect, TextRect)
  end;
end;


(*
function TSplineLink.nearnumber(list: TIntegerList; x: Integer;
  var index: integer): Integer;
var
  I,m,d,min: integer;
begin
  for I:=0 to list.Count-1 do
  begin
    m := list.Items[I];

   if m > x then
     d := m-x
   else
     d := x-m;
     
   if d<min then
   begin
     min :=d;
     index:=i;
     result :=m;
   end;
  end;

end;

function TSplineLink.nearpoint(Pts: TPoints; P: TPoint;
  var index: integer): TPoint;
var
  I,m,d,min: Integer;
  idx, rx,ry: integer;
begin
  for I:=0 to high(pts) do
  begin
    m:= Pts[I].x;

    if m > P.x then
      d := m-P.X
    else
      d := P.X-m;
    if d<min then
    begin
      min := d;
      idx := i;
      rx := m;
    end;
  end;


end;
*)



function TSplineLink.distancePttoPt(P1, P2: TPoint): double;
var
  a, b, c: single;
begin

  a:= abs(P1.x-P2.x);
  b:= abs(P1.y-P2.y);
  c:= sqr(a)+sqr(b);
  if c > 0 then result:=sqrt(c) else result := 0;

end;

function TSplineLink.distancePttoPt_A(P1, P2: TPoint): double;
begin
  result := Sqrt(Sqr(P2.X - P1.X) + Sqr(P2.Y - P1.Y));
end;

 (*
procedure TSplineLink.DrawState(Canvas: TCanvas);
begin
  inherited DrawState(canvas);
  
  if IsVisibleOn(Canvas) then
  begin
    if Dragging then
    begin
      Canvas.Brush.Style := bsClear;
      Canvas.Pen.Mode := pmNot;
      Canvas.Pen.Style := psSolid;
      if Pen.Width >= 2 then
        Canvas.Pen.Width := (Pen.Width - 1) div 2
      else
        Canvas.Pen.Width := Pen.Width + 2;
      DrawHighlight(Canvas);
    end
    else if Selected then
    begin
      Canvas.Pen.Width := 1;
      Canvas.Pen.Mode := pmCopy;
      Canvas.Pen.Style := psInsideFrame;
      Canvas.Pen.Color := Owner.MarkerColor;
      Canvas.Brush.Style := bsSolid;
      Canvas.Brush.Color := Owner.Color;
      DrawControlPoints(Canvas);
    end;
  end;
end;
*)


{ TBSplineLink }

procedure TBSplineLink.Changed(Flags: TGraphChangeFlags);
begin
  inherited;

end;

constructor TBSplineLink.Create(AOwner: TSimpleGraph);
begin
  inherited;

end;

procedure TBSplineLink.MouseDown(Button: TMouseButton; Shift: TShiftState;
  const Pt: TPoint);
begin
  inherited MouseDown(Button,Shift,Pt);
  if Owner.CommandMode = cmInsertLink then
    FCreateByMouse := True;
end;

procedure TBSplineLink.MouseMove(Shift: TShiftState; const Pt: TPoint);
var
  ptrect: TRect;
  p1,p2: Tpoint;
begin
  inherited MouseMove(Shift, Pt);

  if fCreateByMouse then
  begin

  end;
  
end;

procedure TBSplineLink.MouseUp(Button: TMouseButton; Shift: TShiftState;
  const Pt: TPoint);
var
  midPt1, MidPt2 : TPoint;
  pt1,pt2,pt3,pt4:TPoint;
begin
  inherited mouseup(button, shift,pt);
  if FCreateByMouse then
  begin
    if Assigned(Source) and (PointsEqual(Points[0], TGraphNode(Source).FixHookAnchor)) then
      StartPt := Points[1]
    else
      StartPt := points[0];

    if Assigned(Target) and (PointsEqual(Points[PointCount -1],TGraphNode(Target).FixHookAnchor)) then
      EndPt := Points[PointCount -2]
    else
      EndPt := Points[PointCount -1];

    {0,1,2,3,4,5}
    Pt1.X := (EndPT.X - StartPt.X) div 6;
    Pt1.y := (EndPT.Y - StartPt.Y) div 6;
    Pt2.X := EndPt.X - Pt1.x;
    Pt2.Y := EndPt.Y - Pt1.Y;

    Pt3.X := StartPt.X + Pt1.X + Pt1.X+100;
    Pt3.Y := StartPt.Y + Pt1.Y + Pt1.Y;

    Pt4.X := Pt3.X + Pt1.X;
    Pt4.Y := Pt3.Y + Pt1.Y;
    
    Pt1.X := StartPt.X + Pt1.x;
    Pt1.Y := StartPt.Y + Pt1.Y;

    AddBreakPoint(Pt1);
    AddBreakPoint(Pt2);
    AddBreakPoint(Pt3);
    AddBreakPoint(Pt1);
    //InsertPoint(5, Pt4);
    FCreateByMouse := False;
  end;
end;

initialization
  // Loads Custom Cursors
  Screen.Cursors[crHandFlat] := LoadCursor(HInstance, 'SG_HANDFLAT');
  Screen.Cursors[crHandGrab] := LoadCursor(HInstance, 'SG_HANDGRAB');
  Screen.Cursors[crHandPnt] := LoadCursor(HInstance, 'SG_HANDPNT');
  Screen.Cursors[crXHair1] := LoadCursor(HInstance, 'SG_XHAIR1');
  Screen.Cursors[crXHair2] := LoadCursor(HInstance, 'SG_XHAIR2');
  Screen.Cursors[crXHair3] := LoadCursor(HInstance, 'SG_XHAIR3');
  Screen.Cursors[crXHairLink] := LoadCursor(HInstance, 'SG_XHAIRLINK');
  // Registers Clipboard Format
  CF_SIMPLEGRAPH := RegisterClipboardFormat('Simple Graph Format');
  // Registers Link and Node classes
  TSimpleGraph.Register(TGraphLink);
  TSimpleGraph.Register(TEVSBezierLink);
  TSimpleGraph.Register(TSplineLink);
  TSimpleGraph.Register(TRectangularNode);
  TSimpleGraph.Register(TRoundRectangularNode);
  TSimpleGraph.Register(TEllipticNode);
  TSimpleGraph.Register(TTriangularNode);
  TSimpleGraph.Register(TRhomboidalNode);
  TSimpleGraph.Register(TPentagonalNode);
  TSimpleGraph.Register(THexagonalNode);
finalization
  // Unregisters Link and Node classes
  TSimpleGraph.Unregister(THexagonalNode);
  TSimpleGraph.Unregister(TPentagonalNode);
  TSimpleGraph.Unregister(TRhomboidalNode);
  TSimpleGraph.Unregister(TTriangularNode);
  TSimpleGraph.Unregister(TEllipticNode);
  TSimpleGraph.Unregister(TRoundRectangularNode);
  TSimpleGraph.Unregister(TRectangularNode);
  TSimpleGraph.Unregister(TSplineLink);
  TSimpleGraph.Unregister(TEVSBezierLink);
  TSimpleGraph.Unregister(TGraphLink);
end.
