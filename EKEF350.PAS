{ Kefrens Bars on EGA 640x350.16 with 64 colors }
{       (requires compatible EGA monitor)       }
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
  a, b, c, g, r : byte;
  i, j, k : word;
  p, q, s, t, u, v, w, x, y, z : word;
  atab : array [0..349] of word;
  btab : array [0..349] of word;
  Y1, Z1, Y2, Z2 : array [0..2] of word;
  coppertab : array [0..349] of word; { 11 }
  sintabC : array [0..1023] of integer;
  sintab50 : array [0..1023] of integer;
  r1, r2, r3, g1, g2, g3, b1, b2, b3 : byte;

begin
  asm
    mov ax, 10h
    int 10h
    cli
  end;
  portw[$3d4] := $13; { 0 scanline offset (line buffer) }

  for i := 0 to 349 do begin
    atab[i] := round(320.0 + 14.0*cos(2*pi*i/350*2) + 24.0*sin(2*pi*i/350*3));
    btab[i] := round(320.0 + 20.0*sin(2*pi*i/350*2) + 18.0*cos(2*pi*i/350*1));
  end;

  for i := 0 to 1023 do begin
    sintab50[i] := round(60*sin(2*pi*i/1024));
    sintabC[i] := round(40*sin(2*pi*i/1024));
  end;

  coppertab[$0] := ega64[0 shl 4];
  coppertab[$1] := ega64[1 shl 4];
  coppertab[$2] := ega64[2 shl 4];
  coppertab[$3] := ega64[3 shl 4];
  coppertab[$4] := ega64[2 shl 4];
  coppertab[$5] := ega64[1 shl 4];

  coppertab[$6] := ega64[0 shl 2];
  coppertab[$7] := ega64[1 shl 2];
  coppertab[$8] := ega64[2 shl 2];
  coppertab[$9] := ega64[3 shl 2];
  coppertab[10] := ega64[2 shl 2];
  coppertab[11] := ega64[1 shl 2];

  coppertab[12] := ega64[0];
  coppertab[13] := ega64[1];
  coppertab[14] := ega64[2];
  coppertab[15] := ega64[3];
  coppertab[16] := ega64[2];
  coppertab[17] := ega64[1];

  coppertab[18] := ega64[0 shl 4] or ega64[0];
  coppertab[19] := ega64[1 shl 4] or ega64[1];
  coppertab[20] := ega64[2 shl 4] or ega64[2];
  coppertab[21] := ega64[3 shl 4] or ega64[3];
  coppertab[22] := ega64[2 shl 4] or ega64[2];
  coppertab[23] := ega64[1 shl 4] or ega64[1];

  coppertab[24] := ega64[0 shl 4] or ega64[0 shl 2];
  coppertab[25] := ega64[1 shl 4] or ega64[1 shl 2];
  coppertab[26] := ega64[2 shl 4] or ega64[2 shl 2];
  coppertab[27] := ega64[3 shl 4] or ega64[3 shl 2];
  coppertab[28] := ega64[2 shl 4] or ega64[2 shl 2];
  coppertab[29] := ega64[1 shl 4] or ega64[1 shl 2];

  coppertab[30] := ega64[0 shl 2] or ega64[0];
  coppertab[31] := ega64[1 shl 2] or ega64[1];
  coppertab[32] := ega64[2 shl 2] or ega64[2];
  coppertab[33] := ega64[3 shl 2] or ega64[3];
  coppertab[34] := ega64[2 shl 2] or ega64[2];
  coppertab[35] := ega64[1 shl 2] or ega64[1];

  coppertab[36] := ega64[0 shl 4] or ega64[0 shl 2] or ega64[0];
  coppertab[37] := ega64[1 shl 4] or ega64[1 shl 2] or ega64[1];
  coppertab[38] := ega64[2 shl 4] or ega64[2 shl 2] or ega64[2];
  coppertab[39] := ega64[3 shl 4] or ega64[3 shl 2] or ega64[3];
  coppertab[40] := ega64[2 shl 4] or ega64[2 shl 2] or ega64[2];
  coppertab[41] := ega64[1 shl 4] or ega64[1 shl 2] or ega64[1];

  r1 := ega64[1 shl 4];
  r2 := ega64[2 shl 4];
  r3 := ega64[3 shl 4];
  g1 := ega64[1 shl 2];
  g2 := ega64[2 shl 2];
  g3 := ega64[3 shl 2];
  b1 := ega64[1];
  b2 := ega64[2];
  b3 := ega64[3];

  setcolor(1, 1, 0, 0); { red }
  setcolor(2, 2, 0, 0);
  setcolor(3, 3, 0, 0);
  setcolor(4, 0, 1, 0); { green }
  setcolor(5, 0, 2, 0);
  setcolor(6, 0, 3, 0);
  setcolor(7, 0, 0, 1); { blue }
  setcolor(8, 0, 0, 2);
  setcolor(9, 0, 0, 3);
  setcolor(10, 1, 0, 1); { magenta }
  setcolor(11, 2, 0, 2);
  setcolor(12, 3, 0, 3);
  setcolor(13, 1, 1, 1); { white }
  setcolor(14, 2, 2, 2);
  setcolor(15, 3, 3, 3);

  { write mode 2 }
  portw[$3ce] := $0205;
  portw[$3ce] := 8;

  repeat
    while (port[$3da] and 8) = 0 do; { wait for vsync to begin }

    { advance time and clear memory during vsync }
    t := t + 1;
    portw[$3cf] := 255;
    for i := 0 to 39 do
      memw[$a000:i shl 1] := 0;

    { calculate coppers }
    for k := 150 to 349 do coppertab[k] := 0;

    k := 250 + sintabC[t shl 2 and 1023];
    coppertab[k - 4] := r1;
    coppertab[k - 3] := r1;
    coppertab[k - 2] := r2;
    coppertab[k - 1] := r2;
    coppertab[k] := r3;
    coppertab[k + 1] := r3;
    coppertab[k + 2] := r2;
    coppertab[k + 3] := r2;
    coppertab[k + 4] := r1;
    coppertab[k + 5] := r1;

    k := 250 + sintabC[t shl 1 and 1023];
    coppertab[k - 4] := coppertab[k - 4] or g1;
    coppertab[k - 3] := coppertab[k - 3] or g1;
    coppertab[k - 2] := coppertab[k - 2] or g2;
    coppertab[k - 1] := coppertab[k - 1] or g2;
    coppertab[k] := coppertab[k] or g3;
    coppertab[k + 1] := coppertab[k + 1] or g3;
    coppertab[k + 2] := coppertab[k + 2] or g2;
    coppertab[k + 3] := coppertab[k + 3] or g2;
    coppertab[k + 4] := coppertab[k + 4] or g1;
    coppertab[k + 5] := coppertab[k + 5] or g1;

    k := 250 + sintabC[t*3 and 1023];
    coppertab[k - 4] := coppertab[k - 4] or b1;
    coppertab[k - 3] := coppertab[k - 3] or b1;
    coppertab[k - 2] := coppertab[k - 2] or b2;
    coppertab[k - 1] := coppertab[k - 1] or b2;
    coppertab[k] := coppertab[k] or b3;
    coppertab[k + 1] := coppertab[k + 1] or b3;
    coppertab[k + 2] := coppertab[k + 2] or b2;
    coppertab[k + 3] := coppertab[k + 3] or b2;
    coppertab[k + 4] := coppertab[k + 4] or b1;
    coppertab[k + 5] := coppertab[k + 5] or b1;

    while (port[$3da] and 8) <> 0 do; { wait for vsync to end }

    for i := 0 to 349 do
    begin

      { compute stuff during visible part of the scanline }
      u := (i + t) mod 350;
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

      b := 1 + ((t shl 1 + i) shr 2) mod 15;

      while (port[$3da] and 1) = 0 do; { wait for hsync to begin }

      if i < 150 then begin
        port[$3c0] := 0;
        port[$3c0] := coppertab[(i + t) mod 150];
        port[$3c0] := $20;
      end else begin
        port[$3c0] := 0;
        port[$3c0] := coppertab[150 + i mod 150];
        port[$3c0] := $20;
      end;

      { write pixels during hsync }
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

      while (port[$3da] and 1) <> 0 do; { wait for hsync to end }
    end;
  until port[$64] and 1 = 1;

  asm
    sti
    mov ax, 3
    int 10h
  end;
end.