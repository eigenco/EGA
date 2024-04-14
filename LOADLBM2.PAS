uses crt;

var
  f : file;
  buf : array[0..32767] of byte;
  x, y, z : word;
  i, j, k : byte;

begin
  assign(f, 'fff.lbm');
  reset(f, 1);
  blockread(f, buf, 184, x); { skip header }
  blockread(f, buf, 640*16, x);
  close(f);
  asm
    mov ax, 10h
    int 10h
  end;
  i := port[$3da];
  port[$3c0] := 0; port[$3c0] := 0;   { 000000 black }
  port[$3c0] := 1; port[$3c0] := 63;  { FFFFFF white }
  port[$3c0] := 2; port[$3c0] := 54;  { FFFF00 yellow }
  port[$3c0] := 3; port[$3c0] := 24;  { 005555 green }
  port[$3c0] := 4; port[$3c0] := 10;  { 00AA55 green }
  port[$3c0] := 5; port[$3c0] := 7;   { AAAAAA CGA-light-gray }
  port[$3c0] := 6; port[$3c0] := 36;  { FF0000 red }
  port[$3c0] := 7; port[$3c0] := 0;   { not used }
  port[$3c0] := 8; port[$3c0] := 43;  { 55AAFF "aqua" }
  port[$3c0] := 9; port[$3c0] := 57;  { 5555FF CGA-blue }
  port[$3c0] := 10; port[$3c0] := 20; { AA5500 CGA-brown }
  port[$3c0] := 11; port[$3c0] := 4;  { AA0000 CGA-dark-red }
  port[$3c0] := 12; port[$3c0] := 46; { FFAA55 "skin" }
  port[$3c0] := 13; port[$3c0] := 56; { 555555 CGA-dark-gray }
  port[$3c0] := 14; port[$3c0] := 0;  { not used }
  port[$3c0] := 15; port[$3c0] := 63; { not used }
  for y:=0 to 15 do
  begin
    portw[$3c4] := 1 shl 8 or 2;
    for x:=0 to 79 do
      mem[$a000:x+y*80] := buf[x+y*320];
    portw[$3c4] := 2 shl 8 or 2;
    for x:=0 to 79 do
      mem[$a000:x+y*80] := buf[x+y*320+80];
    portw[$3c4] := 4 shl 8 or 2;
    for x:=0 to 79 do
      mem[$a000:x+y*80] := buf[x+y*320+160];
    portw[$3c4] := 8 shl 8 or 2;
    for x:=0 to 79 do
      mem[$a000:x+y*80] := buf[x+y*320+240];
  end;
  readln;
  asm
    mov ax, 3
    int 10h
  end;
end.