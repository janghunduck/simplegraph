unit util;

interface


type
  { Our vector type }
  PVector2f = ^TVector2f;
  TVector2f = record
    x, y: Single;
  end;

  { Circle type }
  PCircle = ^TCircle;
  TCircle = record
    x, y, r: Single;
  end;
  
  //Some vector routines
  function vec2Null(): TVector2f;
  function vec2Make(const X, Y: Single): TVector2f;
  function vec2Add(const V1, V2: TVector2f): TVector2f;
  function vec2Sub(const V1, V2: TVector2f): TVector2f;
  function vec2Length(const V: TVector2f): Single;

  //Circle routines
  function CircleMake(x, y, r: Single): TCircle;
  function CircleHasPt(Circ: TCircle; Pt: TVector2f): Boolean;
  
implementation



//Utility routines

//------------------------------------------------------
//      VECTORS (2D)
//------------------------------------------------------

function vec2Null(): TVector2f;
begin
  Result.X := 0;
  Result.Y := 0;
end;

function vec2Make(const X, Y: Single): TVector2f;
begin
  Result.X := X;
  Result.Y := Y;
end;

function vec2Add(const V1, V2: TVector2f): TVector2f;
begin
  Result.X := V1.X + V2.X;
  Result.Y := V1.Y + V2.Y;
end;

function vec2Sub(const V1, V2: TVector2f): TVector2f;
begin
  Result.X := V1.X - V2.X;
  Result.Y := V1.Y - V2.Y;
end;

function vec2Length(const V: TVector2f): Single;
begin
  Result := Sqrt(V.X*V.X + V.Y*V.Y);
end;

function CircleMake(x, y, r: Single): TCircle;
begin
  Result.x := x;
  Result.y := y;
  Result.r := r;
end;

function CircleHasPt(Circ: TCircle; Pt: TVector2f): Boolean;
begin
  Result := (vec2Length(Vec2Sub( Pt, Vec2Make(Circ.x,Circ.y) )) < Circ.r);
end;



end.
