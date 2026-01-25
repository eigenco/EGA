{ Kefrens Bars with Coppers }
{ EGA 320x200.16, 64 hardware colors }
{ Fake 343 color coppers (dithering) }

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
  a, b, c, d, p, q, r, x, y, z : byte;
  i, j, k, t, u, v, w : word;
  atab : array [0..199] of word;
  btab : array [0..199] of word;
  Y1, Z1, Y2, Z2 : array [0..2] of word;
  sintab50 : array [0..1023] of integer;
  rr0, rr1, rr2, rr3 : integer;
  dr0, dr1, dr2, dr3 : integer;
  xtab : array [0..255] of word;
  ytab : array [0..255] of word;
  ztab : array [0..255] of word;
  coppertabRA : array [0..199] of word;
  coppertabRB : array [0..199] of word;
  coppertabGA : array [0..199] of word;
  coppertabGB : array [0..199] of word;
  coppertabBA : array [0..199] of word;
  coppertabBB : array [0..199] of word;

begin
  asm
    mov ax, 0dh
    int 10h
    cli
  end;
  port[$3c2] := $a3;  { EGA sync for 64 colors }
  portw[$3d4] := $13; { use line buffer, i.e. 0 scanline offset }

  { horizontal dislpacement tables for Kefrens Bars }
  for i := 0 to 199 do begin
    atab[i] := round(160.0 + 14.0*cos(2*pi*i/200*2) + 24.0*sin(2*pi*i/200*3));
    btab[i] := round(160.0 + 20.0*sin(2*pi*i/200*2) + 18.0*cos(2*pi*i/200*1));
  end;

  { sine tables for Kefrens Bars }
  for i := 0 to 1023 do
    sintab50[i] := round(50*sin(2*pi*i/1024));

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

  { color palette for Kefrens Bars }
  setcolor(2, 1, 0, 0);
  setcolor(3, 2, 0, 0);
  setcolor(4, 3, 0, 0);
  setcolor(5, 0, 1, 0);
  setcolor(6, 0, 2, 0);
  setcolor(7, 0, 3, 0);
  setcolor(8, 0, 0, 1);
  setcolor(9, 0, 0, 2);
  setcolor(10, 0, 0, 3);
  setcolor(11, 2, 0, 2);
  setcolor(12, 3, 0, 3);
  setcolor(13, 1, 1, 1);
  setcolor(14, 2, 2, 2);
  setcolor(15, 3, 3, 3);

  { write mode 2 }
  portw[$3ce] := $0205;
  portw[$3ce] := 8;

  { prepare dithering pattern }
  portw[$3cf] := 128 + 32 + 8 + 2;
  for i := 0 to 319 do begin
    a := i shr 3;
    b := mem[$a000:a];
    mem[$a000:a] := i and 1;
  end;

  repeat
    { wait for vsync to begin }
    while (port[$3da] and 8) = 0 do;

    { advance time during vsync }
    t := t + 1;

    { fetch copper related parameters during vsync }
    a := t mod 160;
    {a := 0;}
    x := xtab[a];
    y := ytab[a];
    z := ztab[a];

    { clear scanline during vsync }
    portw[$3cf] := 255;
    for i := 4 to 15 do
      memw[$a000:i shl 1] := 0;
    portw[$3cf] := 128 + 32 + 8 + 2;
    for i := 32 to 319-32 do begin
      a := i shr 3;
      b := mem[$a000:a];
      mem[$a000:a] := i and 1;
    end;

    { wait for vsync to end }
    while (port[$3da] and 8) <> 0 do;

    for i := 0 to 199 do
    begin

      { compute Kefrens Bars during visible part of the scanline }
      u := (i + t) mod 200;
      v := atab[u] + sintab50[(t shl 2) and 1023];
      w := btab[u] + sintab50[(t shl 3) and 1023];
      Y1[0] := v;
      Y1[1] := v + 1;
      Y1[2] := v + 2;
      Z1[0] := Y1[0] shr 3;
      Z1[1] := Y1[1] shr 3;
      Z1[2] := Y1[2] shr 3;
      Y2[0] := w;
      Y2[1] := w + 1;
      Y2[2] := w + 2;
      Z2[0] := Y2[0] shr 3;
      Z2[1] := Y2[1] shr 3;
      Z2[2] := Y2[2] shr 3;
      b := 2 + ((t shl 1 + i) shr 2) mod 14;

      { wait for hsync to begin }
      while (port[$3da] and 1) = 0 do;

      { produce Copper Bar palettes }
      a := t and 1 xor (i and 1);
      p := (i shr 1 + x) mod 200;
      q := (i shr 1 + y) mod 200;
      r := (i shr 1 + z) mod 200;
      port[$3c0] := a;
      port[$3c0] := coppertabRA[p] or coppertabGA[q] or coppertabBA[r];
      port[$3c0] := a xor 1;
      port[$3c0] := coppertabRB[p] or coppertabGB[q] or coppertabBB[r];
      port[$3c0] := $20;

      { write Kefrens Bar pixels }
      portw[$3cf] := 128 shr (Y1[0] and 7);
      a := mem[$a000:Z1[0]];
      mem[$a000:Z1[0]] := b;

      portw[$3cf] := 128 shr (Y1[1] and 7);
      a := mem[$a000:Z1[1]];
      mem[$a000:Z1[1]] := b;

      portw[$3cf] := 128 shr (Y1[2] and 7);
      a := mem[$a000:Z1[2]];
      mem[$a000:Z1[2]] := b;

      portw[$3cf] := 128 shr (Y2[0] and 7);
      a := mem[$a000:Z2[0]];
      mem[$a000:Z2[0]] := b;

      portw[$3cf] := 128 shr (Y2[1] and 7);
      a := mem[$a000:Z2[1]];
      mem[$a000:Z2[1]] := b;

      portw[$3cf] := 128 shr (Y2[2] and 7);
      a := mem[$a000:Z2[2]];
      mem[$a000:Z2[2]] := b;

      { wait for hsync to end }
      while (port[$3da] and 1) <> 0 do;
    end;
  until port[$64] and 1 = 1;

  asm
    sti
    mov ax, 3
    int 10h
  end;
end.