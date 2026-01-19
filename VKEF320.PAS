{ Kefrens Bars for VGA }
{ 5000 cycles in dosbox should be enough }
uses crt;

var
  kefrtab : array[0..399] of integer;
  kefbtab : array[0..399] of integer;
  sintabr : array [0..1023] of integer;
  sintabb : array [0..1023] of integer;
  coppertab : array [0..799] of integer;

  i, j, k : word;
  x, y, z : integer;
  s, t : word;

  address : word;
  color : byte;
  red, green, blue : byte;
  ry, gy, by : integer;
  dry, dgy, dby : integer;

begin
  asm
    mov ax, 13h
    int 10h
    cli
  end;

  { generate palette }
  port[$3c8] := 1;
  for i := 1 to 31 do
  begin
    port[$3c9] := i shl 1;
    port[$3c9] := i shl 1;
    port[$3c9] := i shl 1;
  end;

  port[$3c8] := 64;
  for i := 0 to 63 do
  begin
    port[$3c9] := i and 63;
    port[$3c9] := 0;
    port[$3c9] := 0;
  end;
  for i := 0 to 63 do
  begin
    port[$3c9] := 0;
    port[$3c9] := i and 63;
    port[$3c9] := 0;
  end;
  for i := 0 to 63 do
  begin
    port[$3c9] := 0;
    port[$3c9] := 0;
    port[$3c9] := i and 63;
  end;

  { precalc tables }
  for i := 0 to 399 do begin
    kefrtab[i] := round(160 + 18*sin(2*pi*i/400*2) + 30*sin(2*pi*i/400*3));
    kefbtab[i] := round(160 + 26*sin(2*pi*i/400*2) + 23*sin(2*pi*i/400));
  end;
  for x := 0 to 799 do coppertab[x] := 0;
  for x := -63 to 63 do coppertab[400 + x] := 63 - abs(x);
  for i := 0 to 1023 do begin
    sintabr[i] := round(60*sin(2*2*pi*i/1024));
    sintabb[i] := round(60*sin(4*2*pi*i/1024));
  end;

  { line buffer: 0 offset between scanlines }
  port[$3d4] := $13; port[$3d5] := 0;

  { main loop }
  ry := -100;
  gy := 0;
  by := 100;
  dry := 1;
  dgy := 2;
  dby := 1;
  repeat
    { wait for vsync to begin }
    while (port[$3da] and 8) = 0 do;

    { advance time and clear scanline }
    t := t + 1;
    for i := 0 to 159 do memw[$a000:i shl 1] := 0;

    { calc coppers }
    if (ry = -150) or (ry = 150) then dry := -dry;
    if (gy = -150) or (gy = 150) then dgy := -dgy;
    if (by = -150) or (by = 150) then dby := -dby;
    ry := ry + dry;
    gy := gy + dgy;
    by := by + dby;

    { wait for vsync to end }
    while (port[$3da] and 8) <> 0 do;

    for i := 0 to 399 do
    begin

      { kefrens bars calc sintab index }
      k := (i + t shl 1) mod 400;

      { coppers }
      red := coppertab[200 + i - ry];
      green := coppertab[200 + i - gy];
      blue := coppertab[200 + i - by];
      portw[$3c8] := red shl 8;
      port[$3c9] := green;

      { wait for hsync to begin }
      while (port[$3da] and 1) = 0 do;

      { coppers }
      port[$3c9] := blue;

      { kefrens bars }
      s := t and 1023;
      red := i + t;
      blue := red + 128;
      address := kefrtab[k] + sintabr[s];
      memw[$a000:address] := red shl 8 or red;
      address := kefbtab[k] + sintabb[s];
      memw[$a000:address] := blue shl 8 or blue;

      { wait for hsync to end }
      while (port[$3da] and 1) <> 0 do;

    end;

  { exit loop on key }
  until port[$64] and 1 = 1;

  asm
    sti
    mov ax, 3
    int 10h
  end;
end.