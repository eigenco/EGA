uses crt;

var
  x, y, z : word;
  i, j, k : byte;
  r, g, b : word;
  o, p, q : integer;
  color : byte;
  l : byte;

const
  ctab : array[0..63] of byte = (0,8,1,9,16,24,17,25,2,10,3,11,18,26,19,27,
  32,40,33,41,48,56,49,57,34,42,35,43,50,58,51,59,4,12,5,13,20,28,21,29,6,
  14,7,15,22,30,23,31,36,44,37,45,52,60,53,61,38,46,39,47,54,62,55,63);

begin
  asm
    mov ax, 0dh
    int 10h
    cli
  end;
  port[$3c2] := $a3;

  p := 1;
  r := 50;

  o := -1;
  g := 100;

  q := 1;
  b := 150;

  repeat
    color := 0;


    if k < b then
    begin
      j := b - k;
    end
    else
      j := k - b;
    if j < 4 then
      color := color or ctab[3-j];


    if k < g then
    begin
      j := g - k;
    end
    else
      j := k - g;
    if j < 4 then
      color := color or ctab[(3-j) shl 2];

    if k < r then
    begin
      j := r - k;
    end
    else
      j := k - r;
    if j < 4 then
      color := color or ctab[(3-j) shl 4];

    while i <> 1 do i := port[$3da] and 9; { wait for HSYNC to start }

    port[$3c0] := 0;
    port[$3c0] := color;
    port[$3c0] := $20;

    k := k + 1;

    while i = 1 do i := port[$3da] and 9; { wait for HSYNC to end }

    if i = 9 then { VSYNC }
    begin
      while i = 9 do i := port[$3da] and 9; { wait for VSYNC to end }
      k := 0;

      if l = 0 then
      begin
        l := 1;
      end
      else l := 0;

      if l = 0 then
      begin
           r := r + p;
           g := g + o;
           b := b + q;
      end;
      if r = 200-4 then p := -1;
      if r = 4 then p := 1;

      if g = 200-4 then o := -1;
      if g = 4 then o := 1;

      if b = 200-4 then q := -1;
      if b = 4 then q := 1;
    end;
  until port[$64] and 1 = 1; { check for keypress }

  asm
    sti
    mov ax, 3
    int 10h
  end;
end.