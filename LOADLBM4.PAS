uses crt;

var
  f : file;
  buf : array[0..32767] of byte;
  x, y, z : word;
  i, j, k : byte;

procedure drawcop(y : word);
begin
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

  drawcop(60);
  drawcop(80);
  drawcop(100);
  drawcop(120);
  drawcop(140);
  drawcop(160);

  repeat
    while i <> 1 do i := port[$3da] and 9; { wait for HSYNC to start }

    if k=70 then { green }
    begin
      port[$3c0] := 6; port[$3c0] := 18;
      port[$3c0] := 7; port[$3c0] := 2;
      port[$3c0] := 14; port[$3c0] := 16;
      port[$3c0] := $20;
    end;

    if k=90 then { blue }
    begin
      port[$3c0] :=  6; port[$3c0] := 9;
      port[$3c0] :=  7; port[$3c0] := 1;
      port[$3c0] := 14; port[$3c0] := 8;
      port[$3c0] := $20;
    end;

    if k=110 then { magenta, RGB:101 }
    begin
      port[$3c0] := 6; port[$3c0] := 45;
      port[$3c0] := 7; port[$3c0] := 5;
      port[$3c0] := 14; port[$3c0] := 40;
      port[$3c0] := $20;
    end;

    if k=130 then { yellow, RGB:110 }
    begin
      port[$3c0] := 6; port[$3c0] := 54;
      port[$3c0] := 7; port[$3c0] := 6;
      port[$3c0] := 14; port[$3c0] := 48;
      port[$3c0] := $20;
    end;

    if k=150 then { cyan, RGB:011 }
    begin
      port[$3c0] := 6; port[$3c0] := 27;
      port[$3c0] := 7; port[$3c0] := 3;
      port[$3c0] := 14; port[$3c0] := 24;
      port[$3c0] := $20;
    end;
{
    if k=170 then
    begin
      port[$3c0] := 0; port[$3c0] := 24;
      port[$3c0] := $20;
    end;
    if k=171 then
    begin
      port[$3c0] := 0; port[$3c0] := 0;
      port[$3c0] := $20;
    end;
}
    k := k + 1;

    while i = 1 do i := port[$3da] and 9; { wait for HSYNC to end }

    if i = 9 then { VSYNC }
    begin
         k := 0;

         { reds }
         port[$3c0] := 0; port[$3c0] := 0;
         port[$3c0] := 6; port[$3c0] := 36;
         port[$3c0] := 7; port[$3c0] := 4;
         port[$3c0] := 14; port[$3c0] := 32;
         port[$3c0] := $20;
    end;
  until port[$64] and 1 = 1; { check for keypress }

  asm
    sti
    mov ax, 3
    int 10h
  end;
end.