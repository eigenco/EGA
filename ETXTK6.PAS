{ EGA 640x200 textmode Kerfrens Bars and dithered Copper Bars }
{ Requirements: }
{ * EGA display adapter with 15 kHz 64 color compatible monitor }
{ * 286/10 MHz (0WS) or 286/16 MHz (1WS) }
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
  a, b, c, d, p, q, r, u, v, x, y, z : byte;
  i, j, k, t : word;
  atab : array [0..255] of integer;
  btab : array [0..255] of integer;
  axtab : array [0..255] of integer;
  Y1, Z1, Y2, Z2 : array [0..2] of word;
  utab, vtab, sintab : array [0..1023] of integer;
  rr0, rr1, rr2, rr3 : integer;
  dr0, dr1, dr2, dr3 : integer;
  xtab : array [0..255] of word;
  ytab : array [0..255] of word;
  ztab : array [0..255] of word;
  coppertabRA : array [0..255] of word;
  coppertabRB : array [0..255] of word;
  coppertabGA : array [0..255] of word;
  coppertabGB : array [0..255] of word;
  coppertabBA : array [0..255] of word;
  coppertabBB : array [0..255] of word;
  top : array [0..255] of word;

begin
  asm
    mov ax, 3
    int 10h
    cli
  end;
  port[$3c2] := $a3;  { EGA sync for 64 colors }
  portw[$3d4] := $13; { use line buffer, i.e. 0 scanline offset }

  { disable blinking background }
  i := port[$3da];
  port[$3c0] := $10;
  i := port[$3c1];
  port[$3c0] := $10;
  port[$3c0] := i xor 8;

  { disable cursor }
  port[$3d4] := $0a;
  port[$3d5] := $20;

  for i := 0 to 79 do begin
    mem[$b800:i shl 1] := $b1;
    mem[$b800:i shl 1 or 1] := 1 shl 4;
  end;

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
    xtab[i] := 213 + rr0;
    ytab[i] := 213 + rr1;
    ztab[i] := 213 + rr2;
    if rr0 = 44 then dr0 := -dr0;
    if rr0 = -36 then dr0 := -dr0;
    if rr1 = 44 then dr1 := -dr1;
    if rr1 = -36 then dr1 := -dr1;
    if rr2 = 44 then dr2 := -dr2;
    if rr2 = -36 then dr2 := -dr2;
    rr0 := rr0 + dr0;
    rr1 := rr1 + dr1;
    rr2 := rr2 + dr2;
  end;

  { color palette for Kefrens Bars }
  setcolor(0, 0, 0, 0);
  setcolor(1, 0, 0, 0);
  setcolor(2, 1, 0, 0);
  setcolor(3, 2, 0, 0);
  setcolor(4, 3, 0, 0);
  setcolor(5, 0, 1, 0);
  setcolor(6, 0, 2, 0);
  setcolor(7, 0, 3, 0);
  setcolor(8, 0, 0, 1);
  setcolor(9, 0, 0, 2);
  setcolor(10, 0, 0, 3);
  setcolor(11, 1, 1, 1);
  setcolor(12, 2, 2, 2);
  setcolor(13, 3, 3, 3);
  setcolor(14, 0, 3, 3);
  setcolor(15, 3, 0, 3);

  { horizontal tables for Kefrens Bars }
  for i := 0 to 255 do begin
    atab[i] := round(100*sin(2*2*pi*i/256) + 100*sin(3*2*pi*i/256));
    btab[i] := round(100*sin(5*2*pi*i/256));
    axtab[i] := 80 + round(20*sin(2*pi*i/256) + 30*sin(2*2*pi*i/256));
  end;

  repeat
    portw[$3d4] := $13;
    while (port[$3da] and 8) = 0 do;

    { advance time during vsync }
    t := t + 1;

    { fetch copper related parameters during vsync }
    a := t mod 160;
    x := xtab[a];
    y := ytab[a];
    z := ztab[a];

    { clear scanline during vsync }
    for i := 0 to 79 do begin
      mem[$b800:i shl 1] := $b1;
      mem[$b800:i shl 1 or 1] := 1 shl 4;
      top[i shl 1] := 0;
    end;

    { wait for vsync to end }
    while (port[$3da] and 8) <> 0 do;

    for i := 0 to 182 do
    begin

      { compute Kefrens Bars during visible part of the scanline }
      u := axtab[t and 255] + (atab[(i + t) and 255] + btab[(i + t shr 1) and 255]) shr 5;
      a := u and $fe;
      b := 2 + (i + t shl 1) shr 3 mod 14;
      k := top[a];
      if u and 1 = 0 then j := b shl 12 or $de or (k and $0f00)
      else j := b shl 8 or $de or (k and $f000);
      top[a] := j and $ff00;

      { wait for hsync to begin }
      while (port[$3da] and 1) = 0 do;

      { produce Kefrens Bars pixels }
      memw[$b800:a] := j;

      { produce Copper Bar palettes }
      a := t and 1 xor (i and 1);
      p := (i shr 1 + x) and 255;
      r := (i shr 1 + z) and 255;
      port[$3c0] := a;
      port[$3c0] := coppertabRA[p] or coppertabBA[r];
      port[$3c0] := a xor 1;
      port[$3c0] := coppertabRB[p] or coppertabBB[r];
      port[$3c0] := $20;

      { wait for hsync to end }
      while (port[$3da] and 1) <> 0 do;
    end;

    portw[$3d4] := $8013;
    memw[$b800:72] := $0c4d;
    memw[$b800:74] := $0c6f;
    memw[$b800:76] := $0c64;
    memw[$b800:78] := $0c65;
    memw[$b800:82] := $0c33;
    memw[$b800:84] := $0c68;
  until port[$64] and 1 = 1;

  asm
    sti
    mov ax, 3
    int 10h
  end;
end.