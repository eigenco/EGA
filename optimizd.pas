{ stable 60 Hz on 286/8 MHz (0WS) with EGA and 15 kHz 64c monitor }
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
  ik, colork, address : byte;
  pixel : word;
  pix : byte;

  iktab, colorktab, addresstab, pixeltab : pointer;

  color0, color1, red, grn, blu, i0, i1: byte;

  qq, a, b, c, d, f, p, q, r, u, v, x, y, z : byte;
  i, j, k, t : word;
  atab : array [0..255] of integer;
  btab : array [0..255] of integer;
  axtab : array [0..255] of integer;
  colortab : array [0..2047] of byte;
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
  mod14 : array [0..255] of byte;
  ctab0, ctab1 : pointer;

begin
  getmem(ctab0, 256*200);
  getmem(ctab1, 256*200);
  getmem(iktab, 256*200);
  getmem(colorktab, 256*200);
  getmem(addresstab, 256*200);
  getmem(pixeltab, 256*200);

  asm
    mov ax, 3
    int 10h
    cli
  end;

  port[$3c2] := $a3;  { EGA sync for 64 colors }

  for i := 0 to 255 do
    mod14[i] := 2 + (i mod 14);

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
  {for i := 0 to 160 do begin}
  for i := 0 to 255 do begin
    xtab[i] := 215 + round(35*sin(2*pi*i/256));
    ytab[i] := 215 + round(35*cos(2*pi*i/256));
    ztab[i] := 215 - round(35*sin(2*pi*i/256));
    {xtab[i] := 213 + rr0;
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
    rr2 := rr2 + dr2;}
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
    atab[i] := round(23*sin(2*pi*i/256) + 10*sin(2*2*pi*i/256));
    btab[i] := round(40*sin(2*pi*i/256));
    axtab[i] := 80 + round(19*sin(2*pi*i/256) + 17*sin(2*2*pi*i/256));
  end;

  for i := 0 to 63 do begin
    colortab[ 0*64+i] := ega64[i shr 4 shl 4];
    colortab[ 1*64+i] := ega64[i shr 4 shl 4] + ega64[i shr 5];
    colortab[ 2*64+i] := ega64[i shr 4 shl 4] + ega64[i shr 4];
    colortab[ 3*64+i] := ega64[i shr 4 shl 4] + ega64[i shr 5 shl 2];
    colortab[ 4*64+i] := ega64[i shr 4 shl 4] + ega64[i shr 4 shl 2];
    colortab[ 5*64+i] := ega64[i shr 4];
    colortab[ 6*64+i] := ega64[i shr 4] + ega64[i shr 5 shl 2];
    colortab[ 7*64+i] := ega64[i shr 4] + ega64[i shr 4 shl 2];
    colortab[ 8*64+i] := ega64[i shr 4 shl 2];
    colortab[ 9*64+i] := ega64[i shr 4 shl 2] + ega64[i shr 5 shl 4];
    colortab[10*64+i] := ega64[i shr 4 shl 2] + ega64[i shr 4 shl 4];
    colortab[11*64+i] := ega64[i shr 4 shl 2] + ega64[i shr 5];
    colortab[12*64+i] := ega64[i shr 4 shl 2] + ega64[i shr 4];

    colortab[13*64+i] := ega64[i shr 4 shl 4] + ega64[i shr 4 shl 2] + ega64[i shr 5];
    colortab[14*64+i] := ega64[i shr 4 shl 4] + ega64[i shr 4 shl 2] + ega64[i shr 4];

    colortab[15*64+i] := ega64[i shr 4 shl 4] + ega64[i shr 4] + ega64[i shr 4 shl 2];
    colortab[16*64+i] := ega64[i shr 4 shl 4] + ega64[i shr 4] + ega64[i shr 4 shl 2];
  end;

  t := 0;
  for p := 0 to 4 do
  for j := 0 to 7 do
    for k := 0 to 7 do
      for i := 0 to 7 do
      begin
        if t < 2048 then colortab[t] := ega64[i shr 1 shl 4] + ega64[j shr 1 shl 2] + ega64[k shr 1];
        t := t + 1;
      end;

  { precalc coppers }
  memw[$b800:0] := $0c5b;
  memw[$b800:130] := $0c5d;
  for t := 0 to 255 do begin
    memw[$b800:t shr 2 shl 1 + 2] := $0c2e;
    for i := 0 to 319 do top[i] := 0;
    for i := 0 to 199 do begin
      {a := t mod 160;}
      a := t and 255;
      x := xtab[a];
      y := ytab[a];
      z := ztab[a];
      i0 := t and 1 xor (i and 1);
      i1 := i0 xor 1;
      red := i shr 1 + x;
      grn := i shr 1 + y;
      blu := i shr 1 + z;
      mem[seg(ctab0^):i shl 8 or t] := coppertabRA[red] or coppertabGA[grn] or coppertabBA[blu];
      mem[seg(ctab1^):i shl 8 or t] := coppertabRB[red] or coppertabGB[grn] or coppertabBB[blu];

      u := axtab[t and 255] + atab[(i + t shl 1) and 255];
      address := u and $fe;
      b := 2 + (i + t) shr 1 mod 14;
      k := top[address];
      if u and 1 = 0 then pixel := b shl 12 or $de or (k and $0f00)
      else pixel := b shl 8 or $de or (k and $f000);
      top[address] := pixel and $ff00;
      ik := 2 + (i shr 1 + t) mod 14;
      colork := colortab[(i + t shl 2) shr 1 and 2047];

      mem[seg(iktab^):i shl 8 or t] := ik;
      mem[seg(colorktab^):i shl 8 or t] := colork;
      mem[seg(addresstab^):i shl 8 or t] := address;
      mem[seg(pixeltab^):i shl 8 or t] := pixel shr 8;
    end;
  end;

  portw[$3d4] := $13; { configure line buffer }

  repeat
    while (port[$3da] and 8) = 0 do;

    { advance time during vsync }
    t := t + 1;

    { clear scanline during vsync }
    for i := 0 to 79 do begin
      j := i shl 1;
      mem[$b800:j] := $b1;
      mem[$b800:j or 1] := 16;
      top[j] := 0;
    end;

    { wait for vsync to end }
    while (port[$3da] and 8) <> 0 do;

    for i := 0 to 199 do
    begin

      { fetch Kefrens Bars }
      k := i shl 8 or (t and 255);
      ik := mem[seg(iktab^):k];
      colork := mem[seg(colorktab^):k];
      address := mem[seg(addresstab^):k];
      pixel := mem[seg(pixeltab^):k] shl 8 or $de;

      { fetch Copper Bars }
      i0 := t and 1 xor (i and 1);
      {i1 := i0 xor 1;}
      k := i shl 8 or (t and 255);
      color0 := mem[seg(ctab0^):k];
      color1 := mem[seg(ctab1^):k];

      { wait for hsync to begin }
      while (port[$3da] and 1) = 0 do;

      { produce Copper Bars }
      port[$3c0] := i0;
      port[$3c0] := color0;
      {port[$3c0] := i1;}
      port[$3c0] := i0 xor 1;
      port[$3c0] := color1;

      { produce Kefrens Bars }
      port[$3c0] := ik;
      port[$3c0] := colork;
      port[$3c0] := $20;
      memw[$b800:address] := pixel;

      { wait for hsync to end }
      {while (port[$3da] and 1) <> 0 do;} { no time left for this }
    end;
  until port[$64] and 1 = 1;

  freemem(pixeltab, 256*200);
  freemem(addresstab, 256*200);
  freemem(colorktab, 256*200);
  freemem(iktab, 256*200);
  freemem(ctab1, 256*200);
  freemem(ctab0, 256*200);

  asm
    sti
    mov ax, 3
    int 10h
  end;
end.
