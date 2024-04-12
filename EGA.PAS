uses crt;

var
  x, y : byte;

procedure drawline(y: byte; color: byte);
begin
  portw[$3c4] := color shl 8 or 2;
  for x:=0 to 39 do
    mem[$a000:x+40*y] := 255;
end;


begin
  asm
    mov ax, 0dh
    int 10h
  end;

  for y:=0 to 127 do
    drawline(y, y shr 3);

  { set VS- }
  port[$3c2] := $a3;

  { program colors }
  x := port[$3da];
  port[$3c0] := 1; port[$3c0] := 32;
  port[$3c0] := 2; port[$3c0] := 4;
  port[$3c0] := 3; port[$3c0] := 36;
  port[$3c0] := 4; port[$3c0] := 16;
  port[$3c0] := 5; port[$3c0] := 2;
  port[$3c0] := 6; port[$3c0] := 18;
  port[$3c0] := 7; port[$3c0] := 8;
  port[$3c0] := 8; port[$3c0] := 1;
  port[$3c0] := 9; port[$3c0] := 9;
  port[$3c0] := 10; port[$3c0] := 56;
  port[$3c0] := 11; port[$3c0] := 7;
  port[$3c0] := 12; port[$3c0] := 63;
  port[$3c0] := 13; port[$3c0] := 40;
  port[$3c0] := 14; port[$3c0] := 5;
  port[$3c0] := 15; port[$3c0] := 45;
  port[$3c0] := $20;

  readln;
  asm
    mov ax, 3
    int 10h
  end;
end.