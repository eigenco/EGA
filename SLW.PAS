{ A sort of Kefrens Bar with 3 dithered RGB copper bars and AdLib music }
{ * stable 60 Hz on 286/8 MHz (0WS) with standard EGA }
{ * monitor is required to support 64 colors on 15 kHz modes }
uses crt;

const
  {adlib_delays : array [0..1] of byte = (6 - 1, 35 - 1); { OPL2 }
  {adlib_delays : array [0..1] of byte = (1 - 1, 9 - 1); { OPL3 }
  adlib_delays : array [0..1] of byte = (0, 0);
  ega64 : array [0..63] of byte = ( 0,  8,  1,  9, 16, 24, 17, 25,
                                    2, 10,  3, 11, 18, 26, 19, 27,
                                   32, 40, 33, 41, 48, 56, 49, 57,
                                   34, 42, 35, 43, 50, 58, 51, 59,
                                    4, 12,  5, 13, 20, 28, 21, 29,
                                    6, 14,  7, 15, 22, 30, 23, 31,
                                   36, 44, 37, 45, 52, 60, 53, 61,
                                   38, 46, 39, 47, 54, 62, 55, 63);
  dithr0 : array [0..11] of byte = ( 0, 0, 32, 32, 4, 4, 36, 36, 4, 4, 32, 32 );
  dithr1 : array [0..11] of byte = ( 0, 32, 32, 4, 4, 36, 36, 4, 4, 32, 32, 0 );
  dithg0 : array [0..11] of byte = ( 0, 0, 16, 16, 2, 2, 18, 18, 2, 2, 16, 16 );
  dithg1 : array [0..11] of byte = ( 0, 16, 16, 2, 2, 18, 18, 2, 2, 16, 16, 0 );
  dithb0 : array [0..11] of byte = ( 0, 0, 8, 8, 1, 1, 9, 9, 1, 1, 8, 8 );
  dithb1 : array [0..11] of byte = ( 0, 8, 8, 1, 1, 9, 9, 1, 1, 8, 8, 0 );

var
  a, b, x, y, z, ik, colork, address, color0, color1, red, grn, blu : byte;
  iktab, colorktab, addresstab, pixeltab, ctab0, ctab1 : pointer;
  pixel, i, j, k, t : word;
  atab, axtab : array [0..255] of integer;
  colortab : array [0..2047] of byte;
  xtab, ytab, ztab : array [0..255] of word;
  top : array [0..255] of word;

  imffile : file;
  imf : pointer;
  imflen : word;
  imfpos : word;
  imfpause : word;

procedure playimf;
var
  a, b : byte;
begin
  if imfpause > 0 then imfpause := imfpause - 1
  else if imfpos < imflen then
  begin
    repeat
      port[$388] := mem[seg(imf^):imfpos]; for a := 0 to adlib_delays[0] do b := port[$388];
      port[$389] := mem[seg(imf^):imfpos+1]; for a := 0 to adlib_delays[1] do b := port[$388];
      imfpos := imfpos + 2;
      imfpause := memw[seg(imf^):imfpos] shr 4;
      imfpos := imfpos + 2;
    until imfpause > 0;
  end else imfpos := 0;
end;


procedure setcolor(index, r, g, b : byte);
begin
  a := port[$3da];
  port[$3c0] := index;
  port[$3c0] := ega64[b] or ega64[g shl 2] or ega64[r shl 4];
  port[$3c0] := $20;
end;

begin
  assign(imffile, 'song14.imf');
  reset(imffile, 1);
  blockread(imffile, imflen, 2);
  getmem(imf, imflen);
  blockread(imffile, imf^, imflen);
  close(imffile);

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

  port[$3c2] := $a3;  { EGA64 sync }

  { disable blinking }
  i := port[$3da];
  port[$3c0] := $10; i := port[$3c1];
  port[$3c0] := $10; port[$3c0] := i xor 8;

  { disable cursor }
  portw[$3d4] := $200a;

  { precalc copper bars vertical positions }
  for i := 0 to 255 do begin
    xtab[i] := 215 + round(35*sin(2*pi*i/256));
    ytab[i] := 215 + round(35*cos(2*pi*i/256));
    ztab[i] := 215 - round(35*sin(2*pi*i/256));
    write('.');
  end;

  { precalc kefrens bars horizontal positions }
  for i := 0 to 255 do begin
    atab[i] := round(23*sin(2*pi*i/256) + 10*sin(2*2*pi*i/256));
    axtab[i] := 80 + round(19*sin(2*pi*i/256) + 17*sin(2*2*pi*i/256));
    write('.');
  end;

  { precalc kefrens bars colors }
  t := 0;
  for a := 0 to 4 do begin
    for j := 0 to 7 do
      for k := 0 to 7 do
        for i := 0 to 7 do
        begin
          if t < 2048 then colortab[t] := ega64[i shr 1 shl 4] + ega64[j shr 1 shl 2] + ega64[k shr 1];
          t := t + 1;
        end;
    write('.');
  end;

  { precalc copper and kefrens bars colors and pixels }
  for t := 0 to 255 do begin
    for i := 0 to 255 do top[i] := 0;
    for i := 0 to 199 do begin
      { coppers }
      a := t and 255;
      x := xtab[a];
      y := ytab[a];
      z := ztab[a];
      red := i shr 1 + x;
      grn := i shr 1 + y;
      blu := i shr 1 + z;
      if red < 12 then x := dithr0[red] else x := 0;
      if grn < 12 then y := dithg0[grn] else y := 0;
      if blu < 12 then z := dithb0[blu] else z := 0;
      mem[seg(ctab0^):i shl 8 or t] := x  or y or z;
      if red < 12 then x := dithr1[red] else x := 0;
      if grn < 12 then y := dithg1[grn] else y := 0;
      if blu < 12 then z := dithb1[blu] else z := 0;
      mem[seg(ctab1^):i shl 8 or t] := x or y or z;

      { kefrens }
      a := axtab[t and 255] + atab[(i + t shl 1) and 255];
      address := a and $fe;
      b := 2 + (i + t) shr 1 mod 14;
      k := top[address];
      if a and 1 = 0 then pixel := b shl 12 or $de or (k and $0f00)
      else pixel := b shl 8 or $de or (k and $f000);
      top[address] := pixel and $ff00;
      ik := 2 + (i shr 1 + t) mod 14;
      colork := colortab[(i + t shl 2) shr 1 and 2047];
      mem[seg(iktab^):i shl 8 or t] := ik;
      mem[seg(colorktab^):i shl 8 or t] := colork;
      mem[seg(addresstab^):i shl 8 or t] := address;
      mem[seg(pixeltab^):i shl 8 or t] := pixel shr 8;
    end;
    write('.');
  end;

  portw[$3d4] := $13; { configure line buffer }

  { configure color palette }
  setcolor($0, 0, 0, 0); { used by copper }
  setcolor($1, 0, 0, 0); { used by copper }
  setcolor($2, 1, 0, 0); { rest are used for kefrens }
  setcolor($3, 2, 0, 0);
  setcolor($4, 3, 0, 0);
  setcolor($5, 0, 1, 0);
  setcolor($6, 0, 2, 0);
  setcolor($7, 0, 3, 0);
  setcolor($8, 0, 0, 1);
  setcolor($9, 0, 0, 2);
  setcolor($a, 0, 0, 3);
  setcolor($b, 1, 1, 1);
  setcolor($c, 2, 2, 2);
  setcolor($d, 3, 3, 3);
  setcolor($e, 0, 3, 3);
  setcolor($f, 3, 0, 3);

  t := 0;
  repeat
    { wait for vsync to begin }
    while (port[$3da] and 8) = 0 do;

    { advance time during vsync }
    t := t + 1;

    { clear scanline during vsync }
    for i := 0 to 79 do begin
      j := i shl 1;
      memw[$b800:j] := $10b1;
      top[j] := 0;
    end;

    { wait for vsync to end }
    while (port[$3da] and 8) <> 0 do;

    { generate scanlines }
    for i := 0 to 199 do
    begin

      { fetch Kefrens Bars data }
      k := i shl 8 or (t and 255);
      ik := mem[seg(iktab^):k];
      colork := mem[seg(colorktab^):k];
      address := mem[seg(addresstab^):k];
      pixel := mem[seg(pixeltab^):k] shl 8 or $de;

      { fetch Copper Bars data }
      a := t and 1 xor (i and 1);
      k := i shl 8 or (t and 255);
      color0 := mem[seg(ctab0^):k];
      color1 := mem[seg(ctab1^):k];

      { wait for hsync to begin }
      while (port[$3da] and 1) = 0 do;

      { produce Copper Bars }
      port[$3c0] := a;
      port[$3c0] := color0;
      port[$3c0] := a xor 1;
      port[$3c0] := color1;

      { produce Kefrens Bars }
      port[$3c0] := ik;
      port[$3c0] := colork;
      port[$3c0] := $20;
      memw[$b800:address] := pixel;

      { wait for hsync to end }
      while (port[$3da] and 1) <> 0 do; { comment on 8 MHz (0WS) and slower }
    end;
    playimf;
  until port[$64] and 1 = 1;

  asm
    sti
    mov ax, 3
    int 10h
  end;

  { reset adlib }
  for i := 0 to 255 do
  begin
       port[$388] := i; for j := 0 to 5 do k := port[$388];
       port[$389] := 0; for j := 0 to 5 do k := port[$388];
  end;

  freemem(pixeltab, 256*200);
  freemem(addresstab, 256*200);
  freemem(colorktab, 256*200);
  freemem(iktab, 256*200);
  freemem(ctab1, 256*200);
  freemem(ctab0, 256*200);
  freemem(imf, imflen);
end.
