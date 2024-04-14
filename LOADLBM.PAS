uses crt;

var
  f : file;
  buf : array[0..32767] of byte;
  x, y : word;
  i, j : byte;

begin
  assign(f, 'gfx.dat');
  reset(f, 1);
  blockread(f, buf, 32000, x);
  close(f);
  asm
    mov ax, 10h
    int 10h
  end;
  i := port[$3da];
  port[$3c0] := 1; port[$3c0] := 63;
  port[$3c0] := 2; port[$3c0] := 54;
  port[$3c0] := 3; port[$3c0] := 26;
  port[$3c0] := 4; port[$3c0] := 26;
  port[$3c0] := 5; port[$3c0] := 7;
  port[$3c0] := 6; port[$3c0] := 36;
  port[$3c0] := 7; port[$3c0] := 7;
  port[$3c0] := 8; port[$3c0] := 43;
  port[$3c0] := 9; port[$3c0] := 57;
  port[$3c0] := 10; port[$3c0] := 20;
  port[$3c0] := 11; port[$3c0] := 4;
  port[$3c0] := 12; port[$3c0] := 39;
  port[$3c0] := 13; port[$3c0] := 56;
  port[$3c0] := 14; port[$3c0] := 56;
  port[$3c0] := 15; port[$3c0] := 7;
  for y:=0 to 199 do
  begin
    portw[$3c4] := 1 shl 8 or 2;
    for x:=0 to 39 do
      mem[$a000:x+y*80] := buf[x+y*160];
    portw[$3c4] := 2 shl 8 or 2;
    for x:=0 to 39 do
      mem[$a000:x+y*80] := buf[x+y*160+40];
    portw[$3c4] := 4 shl 8 or 2;
    for x:=0 to 39 do
      mem[$a000:x+y*80] := buf[x+y*160+80];
    portw[$3c4] := 8 shl 8 or 2;
    for x:=0 to 39 do
      mem[$a000:x+y*80] := buf[x+y*160+120];
  end;
  readln;
  asm
    mov ax, 3
    int 10h
  end;
end.