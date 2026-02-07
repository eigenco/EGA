uses crt, dos;
const
  ega64 : array [0..63] of byte = ( 0,  8,  1,  9, 16, 24, 17, 25,
                                    2, 10,  3, 11, 18, 26, 19, 27,
                                   32, 40, 33, 41, 48, 56, 49, 57,
                                   34, 42, 35, 43, 50, 58, 51, 59,
                                    4, 12,  5, 13, 20, 28, 21, 29,
                                    6, 14,  7, 15, 22, 30, 23, 31,
                                   36, 44, 37, 45, 52, 60, 53, 61,
                                   38, 46, 39, 47, 54, 62, 55, 63);
var
  p, q, r : byte;
  a, b, c : integer;
  x, y, z, zoom : real;
  f : file;
  buf : array[0..1023] of byte;
  spr : array[0..16*16-1] of byte;
  i, j, k : word;
  pos : longint;

procedure putpixel(x, y : word; c : byte);
var
  addr : word;
begin
  addr := x and $fe or 1 + y shl 7 + y shl 5;
  if x and 1 = 0 then mem[$b800:addr] := mem[$b800:addr] and $0f or (c shl 4)
  else mem[$b800:addr] := mem[$b800:addr] and $f0 or c;
end;

var
  costab : array[0..255] of integer;
  sintab : array[0..255] of integer;

begin
  for i := 0 to 255 do begin
    costab[i] := round(256*cos(2*pi*i/256));
    sintab[i] := round(256*sin(2*pi*i/256));
  end;


  clrscr;

  i := port[$3da];
  port[$3c0] := $10; i := port[$3c1];
  port[$3c0] := $10; port[$3c0] := i xor 8;
  portw[$3d4] := $200a;
  portw[$3d4] := $0109;
  port[$3c2] := $a3;

  i := port[$3da];
  port[$3c0] := 0; port[$3c0] := 0;   { 000000 black }
  port[$3c0] := 1; port[$3c0] := 63;  { FFFFFF white }
  port[$3c0] := 2; port[$3c0] := 54;  { FFFF00 yellow }
  port[$3c0] := 3; port[$3c0] := 24;  { 005555 green }
  port[$3c0] := 4; port[$3c0] := 10;  { 00AA55 green }
  port[$3c0] := 5; port[$3c0] := 7;   { AAAAAA CGA-light-gray }
  port[$3c0] := 6; port[$3c0] := 36;  { FF0000 red }
  port[$3c0] := 7; port[$3c0] := 4;   { AA0000 }
  port[$3c0] := 8; port[$3c0] := 43;  { 55AAFF "aqua" }
  port[$3c0] := 9; port[$3c0] := 57;  { 5555FF CGA-blue }
  port[$3c0] := 10; port[$3c0] := 20; { AA5500 CGA-brown }
  port[$3c0] := 11; port[$3c0] := 4;  { AA0000 CGA-dark-red }
  port[$3c0] := 12; port[$3c0] := 46; { FFAA55 "skin" }
  port[$3c0] := 13; port[$3c0] := 56; { 555555 CGA-dark-gray }
  port[$3c0] := 14; port[$3c0] := 32; { 550000 }
  port[$3c0] := 15; port[$3c0] := 0;
  port[$3c0] := $20;

  assign(f, 'gfx.bmp');
  reset(f, 1);
  blockread(f, buf, 10);
  blockread(f, pos, 4);
  seek(f, pos);
  blockread(f, buf, 16*8);
  close(f);

  for i := 0 to 7999 do
    memw[$b800:i shl 1] := $00de;

  for j := 0 to 15 do
      for i := 0 to 15 do begin
        if i and 1 = 0 then spr[i+j*16] := buf[i shr 1 + 8 * j] shr 4
        else spr[i+j*16] := buf[i shr 1 + 8 * j] and 15;
      end;

  p := 0;
  repeat
    p := p + 4;
    for b := -45 to 45 do
      for a := -45 to 45 do begin
        i := 8 + (a * costab[p] shr 8 - b * sintab[p] shr 8);
        j := 8 + (a * sintab[p] shr 8 + b * costab[p] shr 8);
        putpixel(80 + a, 50 + b, spr[(i + j shl 4) and 255])
      end;
  until keypressed;
  asm
    mov ax, 3
    int 10h
  end;
end.