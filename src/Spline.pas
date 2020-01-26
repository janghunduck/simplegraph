unit Spline;

interface

uses
  Windows, Messages, Classes, Graphics, Controls, StdCtrls, Forms, Menus,
  ExtCtrls, Contnrs, simplegraph, sgutil;

type
  TPoints = array of TPoint;

  TCustomControlPoint = class
  private
    fCanvas: TCanvas;
    fVector: TVector2f;
    fRadius: Single;
    fColor:  TColor;
    function GetCircle(): TCircle;
  public
    constructor Create(points: Tobjectlist;ACanvas: TCanvas; AX, AY, ARadius: Single);
    destructor Destroy(); override;

    procedure Draw(); virtual; abstract;

    property Canvas: TCanvas read fCanvas;
    property Vector: TVector2f read fVector write fVector;
    property Color: TColor read fColor write fColor;
    property Radius: Single read fRadius;
    property Circle: TCircle read GetCircle;
  end;

  TControlPoint = class(TCustomControlPoint)
  public
    procedure Draw(); override;
  end;


  TCustomCurve = class(TGraphObject)
  private
    fCanvas:        TCanvas;
    fColor:         TColor;
    fPoints:        array of TCustomControlPoint;
    
    function GetPointOnCurve(t: Single): TVector2f;  virtual; abstract;
    function GetControlPoint(I: Integer): TCustomControlPoint;
    function GetControlPointCount: Integer;
    procedure SetControlPoint(I: Integer; const Value: TCustomControlPoint);
  public
    constructor Create(points:Tobjectlist; ACanvas: TCanvas; ACreatePoints: Boolean = True); virtual;
    destructor Destroy(); override;

    procedure Draw(ASegments: Integer = 20);

    property Curve[t: Single]: TVector2f read GetPointOnCurve;
    property ControlPoints[I: Integer]: TCustomControlPoint read GetControlPoint write SetControlPoint;
    property ControlPointCount: Integer read GetControlPointCount;
    property Color: TColor read fColor write fColor;
  end;


  TCurveClass = class of TCustomCurve;
  TCompositeCurve = class(TGraphObject) {ÇÕ¼º °î¼±}
  private
    fCurves:  TObjectList;
    fPoints:  array of TCustomControlPoint;

    function GetControlPoint(I: Integer): TCustomControlPoint;
    function GetControlPointCount: Integer;
    function GetCurveCount: Integer;
    procedure SetControlPoint(I: Integer; const Value: TCustomControlPoint);
    function GetCurve(I: Integer): TCustomCurve;
  public
    constructor Create(graph: TSimpleGraph;points:Tobjectlist;  ACanvas: TCanvas; ACurveClass: TCurveClass; ACurveCount: Integer);
    destructor Destroy(); override;

    procedure Draw();

    property ControlPoints[I: Integer]: TCustomControlPoint read GetControlPoint write SetControlPoint;
    property ControlPointCount: Integer read GetControlPointCount;
    property Curves[I: Integer]: TCustomCurve read GetCurve;
    property CurveCount: Integer read GetCurveCount;
  end;
  
  TCatmullRomCurve = class(TCustomCurve)
  private
    fOwner: TSimpleGraph;
    function CatMullRom(a, b, c, d, t: Single): Single;
    function GetPointOnCurve(t: Single): TVector2f; override;
  public
    constructor Create(points:Tobjectlist; ACanvas: TCanvas; ACreatePoints: Boolean = True); override;
  end;

implementation


{ TCustomControlPoint }

constructor TCustomControlPoint.Create(points: Tobjectlist; ACanvas: TCanvas; AX, AY, ARadius: Single);
begin
  fCanvas := ACanvas;
  fVector := Vec2Make(AX, AY);
  fRadius := ARadius;
  fColor := clRed;

  //Add to global points list
  points.Add(Self);
end;

destructor TCustomControlPoint.Destroy;
begin
  //Remove from global points list
  //points.Remove(Self);

  inherited;
end;

function TCustomControlPoint.GetCircle: TCircle;
begin
  with Result do
  begin
    x := fVector.x;
    y := fVector.y;
    r := fRadius;
  end;
end;

{ TControlPoint }

procedure TControlPoint.Draw;
begin
  with fCanvas do
  begin
    Pen.Color := fColor;
    Rectangle(Bounds( Round(Vector.X-fRadius), Round(Vector.Y-fRadius),
                      Round(fRadius*2), Round(fRadius*2) ));
  end;
end;

{ TCustomCurve }

constructor TCustomCurve.Create(points:Tobjectlist; ACanvas: TCanvas; ACreatePoints: Boolean = True);
begin
  fCanvas := ACanvas;
end;

destructor TCustomCurve.Destroy;
begin
  fPoints := nil;
  inherited;
end;

procedure TCustomCurve.Draw(ASegments: Integer);
var
  I:        Integer;
  Pt1, Pt2: TVector2f;
begin
  //Draw curve
  with fCanvas do
  begin
    Pen.Color := fColor;
    Pen.Width := 2;

    //Get first point
    Pt1 := GetPointOnCurve(0.0);
    MoveTo( Round(Pt1.x), Round(Pt1.y) );

    for I := 0 to ASegments - 1 do
    begin
      Pt2 := GetPointOnCurve( (I+1) / ASegments );
      LineTo( Round(Pt2.x), Round(Pt2. y) );
      Pt1 := Pt2;
    end;

    Pen.Width := 1;
  end;

  //Finally, draw control points
  for I := 0 to ControlPointCount - 1 do
    ControlPoints[I].Draw();
end;

function TCustomCurve.GetControlPoint(I: Integer): TCustomControlPoint;
begin
  if (I >= 0) and (I < Length(fPoints)) then
    Result := fPoints[I]
  else
    Result := nil;
end;

function TCustomCurve.GetControlPointCount: Integer;
begin
  Result := Length(fPoints);
end;

procedure TCustomCurve.SetControlPoint(I: Integer; const Value: TCustomControlPoint);
begin
  if (I >= 0) and (I < Length(fPoints)) then
    fPoints[I] := Value;
end;

{ TCatmullRomCurve }

constructor TCatmullRomCurve.Create(points:Tobjectlist; ACanvas: TCanvas; ACreatePoints: Boolean = True);

//constructor TCatmullRomCurve.Create(points:Tobjectlist;ACanvas: TCanvas; ACreatePoints: Boolean = True);
var
  I: Integer;
begin
  inherited;

  SetLength(fPoints, 4);
  if ACreatePoints then
    for I := 0 to 3 do
      fPoints[I] := TControlPoint.Create(points,fCanvas, 0, 0, 4);
end;

function TCatmullRomCurve.GetPointOnCurve(t: Single): TVector2f;
begin
  Result.x := CatMullRom(fPoints[0].Vector.x,
                         fPoints[1].Vector.x,
                         fPoints[2].Vector.x,
                         fPoints[3].Vector.x, t);
  Result.y := CatMullRom(fPoints[0].Vector.y,
                         fPoints[1].Vector.y,
                         fPoints[2].Vector.y,
                         fPoints[3].Vector.y, t);
end;

//Single dimention catmull-Rom function
function TCatmullRomCurve.CatMullRom(a, b, c, d, t: Single): Single;
begin
   result:=0.5*( 2*b + (c-a)*t +
               ( 2*a - 5*b + 4*c-d)*t*t +
               ( 3*b - a - 3*c + d)*t*t*t );
end;


{ TCompositeCurve }

//WARNING: This class can only use Curve types that consist of 4 control points per segment!!!
constructor TCompositeCurve.Create(graph: TSimpleGraph;points:Tobjectlist; ACanvas: TCanvas; ACurveClass: TCurveClass; ACurveCount: Integer);
var
  I: Integer;
begin
//self.Owner := graph;
  fCurves := TObjectList.Create();
  SetLength(fPoints, ACurveCount + 3 );

  for I := 0 to ACurveCount - 1 do
    fCurves.Add( ACurveClass.Create(points, ACanvas, False ) );
end;

destructor TCompositeCurve.Destroy;
begin
  fCurves.Free();
  fPoints := nil;
  inherited;
end;

procedure TCompositeCurve.Draw;
var
  I: Integer;
begin
  for I := 0 to fCurves.Count - 1 do
    TCustomCurve(fCurves[I]).Draw();
end;

function TCompositeCurve.GetControlPoint(I: Integer): TCustomControlPoint;
begin
  if (I >= 0) and (I < ControlPointCount) then
    Result := TCustomControlPoint(fPoints[I])
  else
    Result := nil;
end;

function TCompositeCurve.GetControlPointCount: Integer;
begin
  Result := Length(fPoints);
end;

function TCompositeCurve.GetCurve(I: Integer): TCustomCurve;
begin
  if (I >= 0) and (I < CurveCount) then
    Result := TCustomCurve(fCurves[I])
  else
    Result := nil;
end;

function TCompositeCurve.GetCurveCount: Integer;
begin
  Result := fCurves.Count;
end;

procedure TCompositeCurve.SetControlPoint(I: Integer; const Value: TCustomControlPoint);
var
  J: Integer;
  K: Integer;
begin
  if (I >= 0) and (I < ControlPointCount) then
  begin
    fPoints[I] := Value;

    for J := 0 to CurveCount - 1 do
      for K := 0 to 3 do
        if (J + K = I)  then
          Curves[J].ControlPoints[K] := Value;
  end;
end;


end.
