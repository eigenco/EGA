{
  Requirements:
  * EGA display adapter with 15 kHz 64 color compatible monitor
  * 286/10 MHz (1WS) or 286/8 MHz (0WS)
}
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
  a, p, q, r, x, y, z : byte;
  i, j, k, t : word;
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
    mov ax, 3
    int 10h
    cli
  end;
  port[$3c2] := $a3;  { sync for 64 colors }

  { disable cursor }
  port[$3d4] := $0a;
  port[$3d5] := $20;

  { fill screen with 01-pattern }
  for i := 0 to 80*25-1 do
    memw[$b800:i shl 1] := 1 shl 8 or $b1;

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
    if rr1 = 40 then dr1 := -dr1;
    if rr1 = -40 then dr1 := -dr1;
    if rr2 = 40 then dr2 := -dr2;
    if rr2 = -40 then dr2 := -dr2;
    rr0 := rr0 + dr0;
    rr1 := rr1 + dr1;
    rr2 := rr2 + dr2;
  end;

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

  repeat
    while (port[$3da] and 8) = 0 do;
    t := t + 1;
    a := t mod 160;
    x := xtab[a];
    y := ytab[a];
    z := ztab[a];
    while (port[$3da] and 8) <> 0 do;

    for i := 0 to 199 do
    begin
      while (port[$3da] and 1) = 0 do;
      a := t and 1 xor (i and 1);
      p := (i shr 1 + x) mod 200;
      q := (i shr 1 + y) mod 200;
      r := (i shr 1 + z) mod 200;
      port[$3c0] := a;
      port[$3c0] := coppertabRA[p] or coppertabGA[q] or coppertabBA[r];
      port[$3c0] := a xor 1;
      port[$3c0] := coppertabRB[p] or coppertabGB[q] or coppertabBB[r];
      port[$3c0] := $20;
      while (port[$3da] and 1) <> 0 do;
    end;
  until port[$64] and 1 = 1;

  asm
    sti
    mov ax, 3
    int 10h
  end;
end.