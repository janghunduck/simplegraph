unit UsefulUtils;

interface

uses Windows, Messages, SysUtils, Classes, Graphics, Controls, StdCtrls, Forms, Menus,
  ExtCtrls, Contnrs, Dialogs;


  function GetCharFromVirtualKey(AKey: Word): string;
  function GetCharFromVirtualKey2(Key: Word): Char;
  function GetString(const Index: String) : String;
  function IntToStrZero(Value: Integer; Size: Integer): String;

  //function GetBezierPolyline(Control_Points: array of TPoint): TPoints;

implementation

function GetCharFromVirtualKey(AKey: Word): string;
var
  KeyboardState: Windows.TKeyboardState; // keyboard state codes
const
  MAPVK_VK_TO_VSC = 0;  // parameter passed to MapVirtualKey
begin
  Windows.GetKeyboardState(KeyboardState);
  SetLength(Result, 2); // max number of returned chars
  case Windows.ToAscii(
    AKey,
    Windows.MapVirtualKey(AKey, MAPVK_VK_TO_VSC),
    KeyboardState,
    @Result[1],
    0
  ) of
    0: Result := '';         // no translation available
    1: SetLength(Result, 1); // single char returned
    2: {Do nothing};         // two chars returned: leave Length(Result) = 2
    else Result := '';       // probably dead key
  end;
end;

function GetCharFromVirtualKey2(Key: Word): Char;
var
   keyboardState: TKeyboardState;
   asciiResult: Integer;
begin
   GetKeyboardState(keyboardState) ;

   asciiResult := ToAscii(Key, MapVirtualKey(Key, 0), keyboardState, @Result, 0) ;
   case asciiResult of
     0: Result := #0;
     1:;
     2:;
     else
       Result := #0;
   end;
end;

function GetString(const Index: String) : String;
var
  buffer : array[0..255] of Char;
  ls : integer;
begin
  Result := '';
  ls := LoadString(hInstance, StrToInt(Index), buffer, sizeof(buffer));
  if ls <> 0 then Result := buffer;
end;

function IntToStrZero(Value: Integer; Size: Integer): String;
begin
  Result:=IntToStr(Value);
  while Length(Result)<Size do Result:='0'+Result;
end;
(*
function GetBezierPolyline(Control_Points: array of TPoint): TPoints;
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
   ArrayLen := Length(Control_Points);
   if (ArrayLen < 4) or ((ArrayLen -1) mod 3 <> 0) then Exit;

   SetLength(Result, 128);
   Result[0] := Control_Points[0];
   ResultCnt := 1;
   for I := 0 to (ArrayLen div 3)-1 do begin
     for J := 0 to 3 do
       CtrlPts[J] := FloatPoint(Control_Points[I*3 +J]);
     RecursiveCBezier(CtrlPts[0], CtrlPts[1], CtrlPts[2], CtrlPts[3]);
   end;
   SetLength(Result, ResultCnt);
end;
*)
end.
 