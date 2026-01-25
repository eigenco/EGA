uses crt;

const
  ega64 : array [0..63] of byte = ( 0,  8,  1,  9, 16, 24, 17, 25,
                                    2, 10,  3, 11, 18, 26, 19, 27,
                                   32, 40, 33, 41, 48, 56, 49, 57,
                                   34, 42, 35, 43, 50, 58, 51, 59,
                                    4, 12,  5, 13, 20, 28, 21, 29,
                                    6, 14,  7, 15, 22, 30, 23, 31,
                                   36, 44, 37, 45, 52, 60, 53, 61,
                                   38, 46, 39, 47, 54, 62, 55, 63);

procedure setcolor(index, r, g, b : byte);
var
  a, color : byte;
begin
  color := ega64[b];
  color := color or ega64[g shl 2];
  color := color or ega64[r shl 4];
  a := port[$3da];
  port[$3c0] := index;
  port[$3c0] := color;
  port[$3c0] := $20;
end;

var
  af, xf0, yf0, xf1, yf1 : real;
  ry, gy, by : integer;
  dry, dgy, dby : integer;
  a, b, c : byte;
  mirror_state : byte;
  r_state, g_state, b_state :byte;
  x1, x2, x3 : byte;
  y1, y2, y3 : byte;
  x, y, z : integer;
  i, j, k : integer;
  t, s : word;
  p, q : longint;
  offset, xpos, ypos, dx, dy : longint;
  clrs : array[0..3] of byte;
  clrs2 : array[0..3] of byte;
  offset_table : array[0..255] of longint;
  o0, o1, o2, o3 : real;

  rr0, rr1, rr2, rr3 : integer;
  dr0, dr1, dr2, dr3 : integer;
  xtab : array [0..255] of word;
  ytab : array [0..255] of word;
  ztab : array [0..255] of word;
  coppertabRA : array [0..199] of byte;
  coppertabRB : array [0..199] of byte;
  coppertabGA : array [0..199] of byte;
  coppertabGB : array [0..199] of byte;
  coppertabBA : array [0..199] of byte;
  coppertabBB : array [0..199] of byte;
  pp, qq, rr, xx, yy, zz : byte;

  coppetabAr : array [0..199] of byte;
  coppetabBr : array [0..199] of byte;
  coppetabAg : array [0..199] of byte;
  coppetabBg : array [0..199] of byte;
  coppetabAb : array [0..199] of byte;
  coppetabBb : array [0..199] of byte;

begin
  randomize;

  asm
    mov ax, 0dh
    int 10h
    cli
  end;
  port[$3c2] := $a3;

  for x := 0 to 15 do
    setcolor(x, 0, 0, 0);

  { used by background coppers }
  setcolor(0, 0, 0, 0);
  setcolor(1, 0, 0, 0);

  { used by mirror coppers }
  setcolor(2, 0, 0, 0);
  setcolor(3, 0, 0, 0);

  { used by mirror }
  setcolor(4, 0, 0, 0);
  setcolor(5, 1, 1, 1);
  setcolor(6, 2, 2, 2);
  setcolor(7, 3, 3, 3);

  { write mode 2 }
  portw[$3ce] := $0205;
  portw[$3ce] := 8;

  { prepare dithering pattern }
  portw[$3cf] := 128 + 32 + 8 + 2;
  for p := 0 to 4*65536-1 do begin
    a := mem[$a000:p shr 1];
    mem[$a000:p shr 1] := p and 1;
  end;

  { mirror frame color table }
  clrs[0] := 0;
  clrs[1] := ega64[1] or ega64[1 shl 2] or ega64[1 shl 4];
  clrs[2] := ega64[2] or ega64[2 shl 2] or ega64[2 shl 4];
  clrs[3] := ega64[3] or ega64[3 shl 2] or ega64[3 shl 4];

  clrs2[0] := 0;
  clrs2[1] := ega64[1] or ega64[1 shl 4];
  clrs2[2] := ega64[2] or ega64[2 shl 4];
  clrs2[3] := ega64[3] or ega64[3 shl 4];

  { coppertabs tables for RGB dithering }
  coppertabRA[$0] := ega64[0 shl 4];
  coppertabRB[$0] := ega64[0 shl 4];
  coppertabRA[$1] := ega64[0 shl 4];
  coppertabRB[$1] := ega64[1 shl 4];
  coppertabRA[$2] := ega64[1 shl 4];
  coppertabRB[$2] := ega64[1 shl 4];
  coppertabRA[$3] := ega64[1 shl 4];
  coppertabRB[$3] := ega64[2 shl 4];
  coppertabRA[$4] := ega64[2 shl 4];
  coppertabRB[$4] := ega64[2 shl 4];
  coppertabRA[$5] := ega64[2 shl 4];
  coppertabRB[$5] := ega64[3 shl 4];
  coppertabRA[$6] := ega64[3 shl 4];
  coppertabRB[$6] := ega64[3 shl 4];
  coppertabRA[$7] := ega64[3 shl 4];
  coppertabRB[$7] := ega64[2 shl 4];
  coppertabRA[$8] := ega64[2 shl 4];
  coppertabRB[$8] := ega64[2 shl 4];
  coppertabRA[$9] := ega64[2 shl 4];
  coppertabRB[$9] := ega64[1 shl 4];
  coppertabRA[10] := ega64[1 shl 4];
  coppertabRB[10] := ega64[1 shl 4];
  coppertabRA[11] := ega64[1 shl 4];
  coppertabRB[11] := ega64[0 shl 4];

  coppertabGA[$0] := ega64[0 shl 2];
  coppertabGB[$0] := ega64[0 shl 2];
  coppertabGA[$1] := ega64[0 shl 2];
  coppertabGB[$1] := ega64[1 shl 2];
  coppertabGA[$2] := ega64[1 shl 2];
  coppertabGB[$2] := ega64[1 shl 2];
  coppertabGA[$3] := ega64[1 shl 2];
  coppertabGB[$3] := ega64[2 shl 2];
  coppertabGA[$4] := ega64[2 shl 2];
  coppertabGB[$4] := ega64[2 shl 2];
  coppertabGA[$5] := ega64[2 shl 2];
  coppertabGB[$5] := ega64[3 shl 2];
  coppertabGA[$6] := ega64[3 shl 2];
  coppertabGB[$6] := ega64[3 shl 2];
  coppertabGA[$7] := ega64[3 shl 2];
  coppertabGB[$7] := ega64[2 shl 2];
  coppertabGA[$8] := ega64[2 shl 2];
  coppertabGB[$8] := ega64[2 shl 2];
  coppertabGA[$9] := ega64[2 shl 2];
  coppertabGB[$9] := ega64[1 shl 2];
  coppertabGA[10] := ega64[1 shl 2];
  coppertabGB[10] := ega64[1 shl 2];
  coppertabGA[11] := ega64[1 shl 2];
  coppertabGB[11] := ega64[0 shl 2];

  coppertabBA[$0] := ega64[0 shl 0];
  coppertabBB[$0] := ega64[0 shl 0];
  coppertabBA[$1] := ega64[0 shl 0];
  coppertabBB[$1] := ega64[1 shl 0];
  coppertabBA[$2] := ega64[1 shl 0];
  coppertabBB[$2] := ega64[1 shl 0];
  coppertabBA[$3] := ega64[1 shl 0];
  coppertabBB[$3] := ega64[2 shl 0];
  coppertabBA[$4] := ega64[2 shl 0];
  coppertabBB[$4] := ega64[2 shl 0];
  coppertabBA[$5] := ega64[2 shl 0];
  coppertabBB[$5] := ega64[3 shl 0];
  coppertabBA[$6] := ega64[3 shl 0];
  coppertabBB[$6] := ega64[3 shl 0];
  coppertabBA[$7] := ega64[3 shl 0];
  coppertabBB[$7] := ega64[2 shl 0];
  coppertabBA[$8] := ega64[2 shl 0];
  coppertabBB[$8] := ega64[2 shl 0];
  coppertabBA[$9] := ega64[2 shl 0];
  coppertabBB[$9] := ega64[1 shl 0];
  coppertabBA[10] := ega64[1 shl 0];
  coppertabBB[10] := ega64[1 shl 0];
  coppertabBA[11] := ega64[1 shl 0];
  coppertabBB[11] := ega64[0 shl 0];


  for i := 0 to 199 do begin
    {j := i mod 12;}
    if i < 12 then j := i mod 12
    else j := 13;
    if j = 0 then begin
        coppetabAr[i] := 0;
        coppetabBr[i] := 0;
        coppetabAg[i] := 0;
        coppetabBg[i] := 0;
        coppetabAb[i] := 0;
        coppetabBb[i] := 0;
    end;
    if j = 1 then begin
        coppetabAr[i] := ega64[1 shl 0];
        coppetabBr[i] := ega64[0 shl 0];
        coppetabAg[i] := ega64[1 shl 2];
        coppetabBg[i] := ega64[0 shl 2];
        coppetabAb[i] := ega64[1 shl 4];
        coppetabBb[i] := ega64[0 shl 4];
      end;
    if j = 2 then begin
        coppetabAr[i] := ega64[1 shl 0];
        coppetabBr[i] := ega64[1 shl 0];
        coppetabAg[i] := ega64[1 shl 2];
        coppetabBg[i] := ega64[1 shl 2];
        coppetabAb[i] := ega64[1 shl 4];
        coppetabBb[i] := ega64[1 shl 4];
      end;
    if j = 3 then begin
        coppetabAr[i] := ega64[2 shl 0];
        coppetabBr[i] := ega64[1 shl 0];
        coppetabAg[i] := ega64[2 shl 2];
        coppetabBg[i] := ega64[1 shl 2];
        coppetabAb[i] := ega64[2 shl 4];
        coppetabBb[i] := ega64[1 shl 4];
      end;
    if j = 4 then begin
        coppetabAr[i] := ega64[2 shl 0];
        coppetabBr[i] := ega64[2 shl 0];
        coppetabAg[i] := ega64[2 shl 2];
        coppetabBg[i] := ega64[2 shl 2];
        coppetabAb[i] := ega64[2 shl 4];
        coppetabBb[i] := ega64[2 shl 4];
      end;
    if j = 5 then begin
        coppetabAr[i] := ega64[3 shl 0];
        coppetabBr[i] := ega64[2 shl 0];
        coppetabAg[i] := ega64[3 shl 2];
        coppetabBg[i] := ega64[2 shl 2];
        coppetabAb[i] := ega64[3 shl 4];
        coppetabBb[i] := ega64[2 shl 4];
      end;
    if j = 6 then begin
        coppetabAr[i] := ega64[3 shl 0];
        coppetabBr[i] := ega64[3 shl 0];
        coppetabAg[i] := ega64[3 shl 2];
        coppetabBg[i] := ega64[3 shl 2];
        coppetabAb[i] := ega64[3 shl 4];
        coppetabBb[i] := ega64[3 shl 4];
      end;
    if j = 7 then begin
        coppetabAr[i] := ega64[2 shl 0];
        coppetabBr[i] := ega64[3 shl 0];
        coppetabAg[i] := ega64[2 shl 2];
        coppetabBg[i] := ega64[3 shl 2];
        coppetabAb[i] := ega64[2 shl 4];
        coppetabBb[i] := ega64[3 shl 4];
    end;
    if j = 8 then begin
        coppetabAr[i] := ega64[2 shl 0];
        coppetabBr[i] := ega64[2 shl 0];
        coppetabAg[i] := ega64[2 shl 2];
        coppetabBg[i] := ega64[2 shl 2];
        coppetabAb[i] := ega64[2 shl 4];
        coppetabBb[i] := ega64[2 shl 4];
    end;
    if j = 9 then begin
        coppetabAr[i] := ega64[1 shl 0];
        coppetabBr[i] := ega64[2 shl 0];
        coppetabAg[i] := ega64[1 shl 2];
        coppetabBg[i] := ega64[2 shl 2];
        coppetabAb[i] := ega64[1 shl 4];
        coppetabBb[i] := ega64[2 shl 4];
    end;
    if j = 10 then begin
        coppetabAr[i] := ega64[1 shl 0];
        coppetabBr[i] := ega64[1 shl 0];
        coppetabAg[i] := ega64[1 shl 2];
        coppetabBg[i] := ega64[1 shl 2];
        coppetabAb[i] := ega64[1 shl 4];
        coppetabBb[i] := ega64[1 shl 4];
    end;
    if j = 11 then begin
        coppetabAr[i] := ega64[0 shl 0];
        coppetabBr[i] := ega64[1 shl 0];
        coppetabAg[i] := ega64[0 shl 2];
        coppetabBg[i] := ega64[1 shl 2];
        coppetabAb[i] := ega64[0 shl 4];
        coppetabBb[i] := ega64[1 shl 4];
    end;
  end;

  { copper bar vertical displacement tables }
  rr0 :=   0; dr0 := 1;
  rr1 := -20; dr1 := -1;
  rr2 :=  20; dr2 := 1;
  for i := 0 to 160 do begin
    xtab[i] := 157 + rr0;
    ytab[i] := 157 + rr1;
    ztab[i] := 157 + rr2;

    if rr0 = 40 then dr0 := -dr0;
    if rr0 = -40 then dr0 := -dr0;
    rr0 := rr0 + dr0;

    if rr1 = 40 then dr1 := -dr1;
    if rr1 = -40 then dr1 := -dr1;
    rr1 := rr1 + dr1;

    if rr2 = 40 then dr2 := -dr2;
    if rr2 = -40 then dr2 := -dr2;
    rr2 := rr2 + dr2;
  end;

  for y := 0 to 199 do
    for x := 0 to 319 do begin
      p := 255 - x;
      p := p * p;
      q := 55 - y;
      q := q * q;
      a := 2 + x and 1;
      if p + q < 2700 then
      asm
        mov ah, 0ch
        mov al, a
        xor bh, bh
        mov cx, x
        mov dx, y
        int 10h
      end;
    end;

  setcolor(8, 0, 0, 0);
  setcolor(9, 1, 0, 1);
  setcolor(10, 2, 0, 2);
  setcolor(11, 3, 0, 3);
  for y := 8 to 105 do begin
    b := 0;
    for x := 253-4 to 258+4 do begin
      if b= 0 then a := 8;
      if b= 1 then if y and 1 = 0 then a := 8 else a:= 9;
      if b= 2 then a := 9;
      if b= 3 then if y and 1 = 0 then a := 9 else a:= 10;
      if b= 4 then a := 10;
      if b= 5 then if y and 1 = 0 then a := 10 else a:= 11;
      if b= 6 then a := 11;
      if b= 7 then if y and 1 = 1 then a := 10 else a:= 11;
      if b= 8 then a := 10;
      if b= 9 then if y and 1 = 1 then a := 9 else a:= 10;
      if b=10 then a := 9;
      if b=11 then if y and 1 = 1 then a := 8 else a:= 9;
      if b=12 then a := 8;
      b := b + 1;
      asm
        mov ah, 0ch
        mov al, a
        xor bh, bh
        mov cx, x
        mov dx, y
        int 10h
      end;
    end;
  end;

  af := 1/3600*2*Pi;
  xf0 := 1;
  yf0 := 0;
  for k := 0 to 3600-1 do
  begin
    xf1 := xf0 - af*yf0;
    yf1 := yf0 + af*xf0;
    for s := 8 to 15 do begin
    i := 255 + round((40+s)*xf1);
    j := 55 + round((40+s)*yf1);
    a := 4 + k shr (7 + (3-s) shr 2) and 3;
    asm
      mov ah, 0ch
      mov al, a
      xor bh, bh
      mov cx, i
      mov dx, j
      int 10h
    end;
    end;
    xf0 := xf1;
    yf0 := yf1;
  end;

  for i := 0 to 255 do begin
    offset_table[i] := round(95.0 + 103.0 * sin(2*pi*i/256));
    offset_table[i] := offset_table[i] + 256*1024*1024 - 320*44 + 320*round(42.0 * sin(2*2*pi*i/256));
  end;

  repeat
    offset := offset_table[t and 255];

    t := t + 1;

    { fetch copper related parameters during vsync }
    {a := t mod 160;}
    xx := xtab[a];
    yy := ytab[a];
    zz := ztab[a];

    { rotate mirror frame colors }
    if t and 3 = 0 then
      for x := 8 to 11 do begin
        port[$3c0] := x;
        port[$3c0] := clrs2[(x + t shr 2) and 3];
      end;

    if t and 1 = 0 then begin
      for x := 4 to 7 do begin
        port[$3c0] := x;
        port[$3c0] := clrs[(x + t shr 1) and 3];
      end;
      port[$3c0] := $20;
    end;

    { wait for vsync to end }
    while (port[$3da] and 8) <> 0 do;

    for i := 0 to 199 do
    begin
      while (port[$3da] and 1) = 0 do;

      { produce Copper Bar palettes }
      a := t and 1 xor (i and 1);
      b := i shr 1;
      pp := (b + xx) mod 200;
      qq := (b + yy) mod 200;
      rr := (b + zz) mod 200;
      port[$3c0] := a;
      port[$3c0] := coppertabRA[pp] or coppertabGA[qq] or coppertabBA[rr];
      port[$3c0] := a xor 1;
      port[$3c0] := coppertabRB[pp] or coppertabGB[qq] or coppertabBB[rr];

      port[$3c0] := a or 2;
      port[$3c0] := coppetabAr[(i + t shr 1) mod 24] or coppetabAg[(i + t) mod 20] or coppetabAb[(i + t) mod 18];
      port[$3c0] := a xor 1 or 2;
      port[$3c0] := coppetabBr[(i + t shr 1) mod 24] or coppetabBg[(i + t) mod 20] or coppetabBb[(i + t) mod 18];

      port[$3c0] := $20;

      while (port[$3da] and 1) <> 0 do;
    end;
    port[$3d4] := $0c; port[$3d5] := hi(offset shr 3);
    port[$3d4] := $0d; port[$3d5] := lo(offset shr 3);
    while (port[$3da] and 8) = 0 do;
    port[$3c0] := $33; port[$3c0] := offset and 7;
  until port[$64] and 1 = 1;

  asm
    mov ax, 3h
    int 10h
  end;
end.
