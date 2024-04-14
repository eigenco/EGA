uses crt;

var
  f : file;
  buf : array[0..32767] of byte;
  x, y, z : word;
  i, j, k : byte;
  p, q : integer;

begin
  assign(f, 'fff.lbm');
  reset(f, 1);
  blockread(f, buf, 184, x); { skip header }
  blockread(f, buf, 640*16, x);
  close(f);
  asm
    mov ax, 0dh
    int 10h
    cli
  end;
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
  port[$3c0] := 15; port[$3c0] := 0;  { not used }
  port[$3c0] := $20;

  for y:=0 to 15 do
  begin
    portw[$3c4] := 1 shl 8 or 2;
    for x:=0 to 39 do
      mem[$a000:x+y*40] := buf[x+y*320];
    portw[$3c4] := 2 shl 8 or 2;
    for x:=0 to 39 do
      mem[$a000:x+y*40] := buf[x+y*320+80];
    portw[$3c4] := 4 shl 8 or 2;
    for x:=0 to 39 do
      mem[$a000:x+y*40] := buf[x+y*320+160];
    portw[$3c4] := 8 shl 8 or 2;
    for x:=0 to 39 do
      mem[$a000:x+y*40] := buf[x+y*320+240];
  end;

  for y:=0 to 15 do
  begin
    portw[$3c4] := 1 shl 8 or 2;
    for x:=0 to 39 do
      mem[$a000:x+(y+16)*40] := buf[x+y*320+40];
    portw[$3c4] := 2 shl 8 or 2;
    for x:=0 to 39 do
      mem[$a000:x+(y+16)*40] := buf[x+y*320+80+40];
    portw[$3c4] := 4 shl 8 or 2;
    for x:=0 to 39 do
      mem[$a000:x+(y+16)*40] := buf[x+y*320+160+40];
    portw[$3c4] := 8 shl 8 or 2;
    for x:=0 to 39 do
      mem[$a000:x+(y+16)*40] := buf[x+y*320+240+40];
  end;

  y := 100;
  p := 1;
  repeat
    i := port[$3da] and 8;
    if i=8 then if j=0 then
    begin
      portw[$3c4] := 15 shl 8 or 2;
      for q:=-2 to 2 do
        for x:=0 to 39 do
          mem[$a000:x+(y+q)*40] := 0;
      if y=197 then p := -1;
      if y=34 then p := 1;
      y := y + p;

      portw[$3c4] := 6 shl 8 or 2;
      for x:=0 to 39 do mem[$a000:x+y*40] := 255;
      portw[$3c4] := 7 shl 8 or 2;
      for x:=0 to 39 do
      begin
           mem[$a000:x+(y-1)*40] := 255;
           mem[$a000:x+(y+1)*40] := 255;
      end;
      portw[$3c4] := 14 shl 8 or 2;
      for x:=0 to 39 do
      begin
           mem[$a000:x+(y-2)*40] := 255;
           mem[$a000:x+(y+2)*40] := 255;
      end;
    end;
    j := i;
{
    i := port[$3da] and 9;
    if i=9 then k := 0;
    if i=1 then if j=0 then
    begin
      port[$3c0] := 0;
      port[$3c0] := k and 63;
      port[$3c0] := $20;
      k := k + 1;
    end;
    j := i;
}
  until port[$64] and 1 = 1;

  asm
    sti
    mov ax, 3
    int 10h
  end;
end.