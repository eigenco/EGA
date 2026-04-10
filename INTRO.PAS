{$DEFINE DOSBOXEGA}

{
  This intro is intended to be run on 12 MHz 286 (0WS) with EGA adapter and
  monitor supporting EGA 64 color palette on 15 kHz modes. Approx. 640 KB of
  RAM is required. Adlib is used for playing music. Per scanline panning is
  also utilized. This hardware effect is novel to EGA adapters and won't
  work with VGA.

  Combined effects
  * Kefrens Bars (line bufferring)
  * Textmode "graphics" (160x200) along with regular 640x200 text
  * Textmode character based dithering for "more" colors
  * Per scanline panning
  * Scanline based split screen

  Emulators likely struggle. DOSBox-X 2026.3.29 appears to display
  things mostly correct when configured for machine = ega.
  Although output may be jerky unlike with real HW.

  Files: indy4.bpl, indy4.pal, song.imf
}

{$G-}
uses crt;

const
  { RGB, CMY, K }
  tred:array[0..41] of byte = (0,1,2,3,2,1, 0,0,0,0,0,0, 0,0,0,0,0,0,
                               0,0,0,0,0,0, 0,1,2,3,2,1, 0,1,2,3,2,1,
                               0,1,2,3,2,1);

  tgrn:array[0..41] of byte = (0,0,0,0,0,0, 0,1,2,3,2,1, 0,0,0,0,0,0,
                               0,1,2,3,2,1, 0,0,0,0,0,0, 0,1,2,3,2,1,
                               0,1,2,3,2,1);

  tblu:array[0..41] of byte = (0,0,0,0,0,0, 0,0,0,0,0,0, 0,1,2,3,2,1,
                               0,1,2,3,2,1, 0,1,2,3,2,1, 0,0,0,0,0,0,
                               0,1,2,3,2,1);

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
  f : file;
  data : array [0..8399] of byte;
  message : array[0..2047] of char;
  aa : integer;
  a, b, x, y, z, ik, colork, address, color0, color1, red, grn, blu : byte;
  tt : byte;
  iktab, colorktab, addresstab, pixeltab, ctab0, ctab1 : pointer;
  wtab : array[0..512] of byte;
  pixel, i, j, k, t, ttt, tttt, ttttt : word;
  atab, axtab : array [0..255] of integer;
  colortab : array [0..2047] of byte;
  xtab, ytab, ztab : array [0..255] of word;
  top : array [0..255] of word;
  ccol : byte;
  ccc : byte;
  egapal : array [0..255] of byte;
  imffile : file;
  imf : pointer;
  imflen : word;
  imfpos : word;
  imfpause : word;
  txtpos : word;
  modnum : word;
  xxtab : array [0..1023] of byte;

procedure writeit(data : string);
begin
  for i := 0 to 63 do
  begin
    message[txtpos] := data[i+1];
    txtpos := txtpos + 1;
  end;
end;

procedure writestr(addr : word; offfs : word; c : byte);
begin
  ccol := 1;
  for k := 0 to 63 do
  begin
    memw[segb800:addr] := (c + ccol) shl 8 or ord(message[(k + offfs) mod modnum]);
    addr := addr + 2;
    if k and 3 = 0 then ccol := ccol + 1;
    if ccol > 3 then ccol := 1;
  end;
end;

procedure playimf;
var
  a, b, c : byte;
begin
  c := 0;
  
  if imfpause > 0 then imfpause := imfpause - 1
  else if imfpos < 20000 then {else if imfpos < imflen then}
  begin
    repeat
      port[$388] := mem[seg(imf^):imfpos];
      {
      port[$378] := mem[seg(imf^):imfpos];
      port[$37a] := 5;
      port[$37a] := 1;
      port[$37a] := 5;
      }

      port[$389] := mem[seg(imf^):imfpos+1];
      {
      port[$378] := mem[seg(imf^):imfpos+1];
      port[$37a] := 12;
      port[$37a] := 8;
      port[$37a] := 12;
      }

      imfpos := imfpos + 2;
      imfpause := memw[seg(imf^):imfpos] shr 4;
      imfpos := imfpos + 2;

      c := c + 1;
    until (imfpause > 0) or (c > 20);
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
  txtpos := 0;
  ccol := 1;
  ttt := 0;
  tttt := 0;
  modnum := 11*64;
  writeit('                                                                ');
  writeit('Hardware requirements for this intro are approximately 12 MHz 28');
  writeit('6 (0WS) with EGA display adapter connected to a monitor supporti');
  writeit('ng EGA 6-bit colors in low resolution (15 kHz) EGA modes. Music ');
  writeit('requires AdLib compatible sound card. Around 640 KB of RAM is ne');
  writeit('eded. Most of the required hardware is from 1987 or earlier. It ');
  writeit('is interesting to note that per scanline panning only works on E');
  writeit('GA and is not supported by VGA. VGA is also considerably faster ');
  writeit('with EGA transfer rate typically topping below 500 KB/s while mo');
  writeit('st (S)VGA adapters transfer multiple MB/s.                      ');
  writeit('BTW. This screen is all textmode.                               ');

  { load music }
  assign(imffile, 'song.imf');
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

  { precalc copper bars vertical positions }
  writeln('Precalc follows...');
  write('[1/5] ');
  for i := 0 to 255 do begin
    xtab[i] := 213 + round(16*sin(2*pi*i/256));
    ytab[i] := 213 + round(16*cos(2*pi*i/256));
    ztab[i] := 213 - round(16*sin(2*pi*i/256));
    if i and 3 = 0 then write('.');
  end;
  writeln;

  { precal panning values }
  write('[2/5] ');
  for i := 0 to 511 do begin
    aa := round(3.5 + 4*sin(6*pi*i/64));
    if aa > 7 then aa := 7;
    if aa < 0 then aa := 0;
    wtab[i] := aa;
    if i and 7 = 0 then write('.');
  end;
  writeln;

  { precalc kefrens bars horizontal positions }
  write('[3/5] ');
  for i := 0 to 255 do begin
    atab[i] := round(23*sin(2*pi*i/256) + 10*sin(2*2*pi*i/256));
    axtab[i] := 95 + round(13*sin(2*pi*i/256) + 7*sin(2*2*pi*i/256));
    if i and 3 = 0 then write('.');
  end;
  writeln;

  { precalc kefrens bars colors }
  t := 0;
  for t := 0 to 2047 do begin
    colortab[t] := ega64[tred[t shr 2 mod 42] shl 4];
    colortab[t] := colortab[t] or ega64[tgrn[t shr 2 mod 42] shl 2];
    colortab[t] := colortab[t] or ega64[tblu[t shr 2 mod 42]];
  end;

  { precalc copper and kefrens bars colors and pixels }
  write('[4/5] ');
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
    if t and 3 = 0 then write('.');
  end;
  writeln;

  write('[5/5] ');
  for i := 0 to 1023 do begin
    j := round(3.5 + 2 * sin(2 * pi * i / 17.0) + 2 * sin(2 * pi * i / 21.0));
    xxtab[i] := j;
    if i and 15 = 0 then write('.');
  end;
  writeln;

  { VGA: copy EGA palette from mode 10h to mode 0dh }
{$IFDEF DOSBOXEGA}
  asm
    mov ax, 10h
    int 10h
  end;
  port[$3c7] := 0;
  for i := 0 to 3*64-1 do
    data[i] := port[$3c9];
{$ENDIF}
  asm
    mov ax, 0dh
    int 10h
    cli
  end;
{$IFDEF DOSBOXEGA}
  port[$3c8] := 0;
  for i := 0 to 3*64-1 do
    port[$3c9] := data[i];
{$ENDIF}

  { blank colors }
  i := port[$3da];
  for i := 0 to 15 do
  begin
    port[$3c0] := i;
    port[$3c0] := 0;
  end;
  port[$3c0] := $20;

{$IFDEF DOSBOXEGA}
  portw[$3d4] := $0011;
  portw[$3d4] := $0705;
  portw[$3d4] := $1107;
  portw[$3d4] := $e110;
  portw[$3d4] := $2411;
  portw[$3d4] := $c712;
  portw[$3d4] := $e015;
  portw[$3d4] := $f016;
  portw[$3d4] := $0009;
{$ENDIF}
  port[$3c2] := $a3;    { EGA64 sync }
  portw[$3d4] := $1513; { scanline offset: 336 pixels }

  { open image bitplane data }
  assign(f, 'indy4.bpl'); { 336x200, 4 bitplanes }
  reset(f, 1);

  { load bitplane 0 }
  blockread(f, data, 8400);
  portw[$3c4] := 1 shl 8 or 2;
  for i := 0 to 8399 do
    mem[sega000:i] := data[i];

  { load bitplane 1 }
  blockread(f, data, 8400);
  portw[$3c4] := 2 shl 8 or 2;
  for i := 0 to 8399 do
    mem[sega000:i] := data[i];

  { load bitplane 2 }
  blockread(f, data, 8400);
  portw[$3c4] := 4 shl 8 or 2;
  for i := 0 to 8399 do
    mem[sega000:i] := data[i];

  { load bitplane 3 }
  blockread(f, data, 8400);
  portw[$3c4] := 8 shl 8 or 2;
  for i := 0 to 8399 do
    mem[sega000:i] := data[i];

  close(f);

  { load EGA palette }
  assign(f, 'indy4.pal'); { 16 colors from EGA64 }
  reset(f, 1);
  blockread(f, data, 3*16);
  close(f);

  for k := 0 to 3 do
  begin
    { fade in }
    for j := 0 to 16 do
    begin
      i := port[$3da];
      for i := 0 to 15 do
      begin
        port[$3c0] := i;
        port[$3c0] := ega64[data[3*i+0] * j shr 10 shl 4] or
                      ega64[data[3*i+1] * j shr 10 shl 2] or
                      ega64[data[3*i+2] * j shr 10];
      end;
      port[$3c0] := $20;
      while port[$3da] and 8 = 0 do;
      while port[$3da] and 8 <> 0 do;
    end;

    { fade out }
    for j := 15 downto 0 do
    begin
      i := port[$3da];
      for i := 0 to 15 do
      begin
        port[$3c0] := i;
        port[$3c0] := ega64[data[3*i+0] * j shr 10 shl 4] or
                      ega64[data[3*i+1] * j shr 10 shl 2] or
                      ega64[data[3*i+2] * j shr 10];
      end;
      port[$3c0] := $20;
      while port[$3da] and 8 = 0 do;
      while port[$3da] and 8 <> 0 do;
    end;
  end;

  { fade in }
  for j := 0 to 16 do
  begin
    i := port[$3da];
    for i := 0 to 15 do
    begin
      port[$3c0] := i;
      port[$3c0] := ega64[data[3*i+0] * j shr 10 shl 4] or
                    ega64[data[3*i+1] * j shr 10 shl 2] or
                    ega64[data[3*i+2] * j shr 10];
    end;
    port[$3c0] := $20;
    while port[$3da] and 8 = 0 do;
    while port[$3da] and 8 <> 0 do;
  end;

  t := 0;
  repeat
    { wait for vsync to begin }
    while (port[$3da] and 8) = 0 do;

    { wait for vsync to end }
    while (port[$3da] and 8) <> 0 do;

    t := t + 1;
    for i := 0 to 199 do begin
      x := xxtab[(i+t) and 1023];

      { wait for hsync to begin }
      while (port[$3da] and 1) = 0 do;

      port[$3c0] := $33;
      port[$3c0] := x;

      { wait for hsync to end }
      while (port[$3da] and 1) <> 0 do;
    end;
    playimf;
  until (t = 500) or (port[$64] and 1 = 1);
  i := port[$60];





  { set standard textmode (and clear screen) }
  asm
    mov ax, 3
    int 10h
  end;

  port[$3c2] := $a3; { set EGA64 sync }

  { set EGA200 textmode timings }
{$IFDEF DOSBOXEGA}
  portw[$3d4] := $0011;
  portw[$3d4] := $7000;
  portw[$3d4] := $4f01;
  portw[$3d4] := $5c02;
  portw[$3d4] := $2f03;
  portw[$3d4] := $5f04;
  portw[$3d4] := $0705;
  portw[$3d4] := $0406;
  portw[$3d4] := $1107;
  portw[$3d4] := $0008;
  portw[$3d4] := $0709;
  portw[$3d4] := $060a;
  portw[$3d4] := $070b;
  portw[$3d4] := $e110;
  portw[$3d4] := $2411;
  portw[$3d4] := $c712;
  portw[$3d4] := $2813;
  portw[$3d4] := $0814;
  portw[$3d4] := $e015;
  portw[$3d4] := $f016;
  portw[$3d4] := $a317;
  portw[$3d4] := $ff18;
{$ENDIF}

  { set 8x8 font and prevent interrupts }
  asm
    mov ax, 1102h
    mov bl, 0
    int 10h
    cli
  end;

  { EGA64 sync }
  port[$3c2] := $a3;

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

  { disable cursor and blinking }
  portw[$3d4] := $200a;
  i := port[$3da];
  port[$3c0] := $10; i := port[$3c1];
  port[$3c0] := $10; port[$3c0] := i xor 8;

  { preconfigure some textmode stuff }
  for i := 0 to 80 do begin
    j := i shl 1;
    memw[segb800:j] := $10b1;
    top[j] := 0;
  end;

  t := 0;
  repeat
    if t and 7 = 7 then ttt := ttt + 1;
    writestr(164+16, ttt, 0);

    { wait for vsync to begin }
    while (port[$3da] and 8) = 0 do;

    port[$3c0] := 1; port[$3c0] := 0; port[$3c0] := $20;

    if t and 3 = 3 then tttt := tttt + 1;
    writestr(164+164+16, tttt, 3);

    { advance time during vsync }
    t := t + 1;

    { clear buffer from previous frame }
    for i := 8 to 71 do begin
      j := i shl 1;
      memw[segb800:j] := $10b1;
      top[j] := 0;
    end;

    { wait for vsync to end }
    while (port[$3da] and 8) <> 0 do;

    x := t mod 252;

    { use line buffer }
    portw[$3d4] := $13;

    { generate scanlines }
    for i := 0 to 182 do
    begin
      { wait for hsync to end }
      while (port[$3da] and 1) <> 0 do;

      { fetch Kefrens Bars data }
      k := i shl 8 or (t and 255);
      ik := mem[seg(iktab^):k];
      colork := mem[seg(colorktab^):i shl 8 or x];
      address := mem[seg(addresstab^):k];
      pixel := mem[seg(pixeltab^):k] shl 8 or $de;

      { fetch Copper Bars data }
      a := t and 1 xor (i and 1);
      k := i shl 8 or (t and 255);
      color0 := mem[seg(ctab0^):k];
      color1 := mem[seg(ctab1^):k];

      { horizontal panning }
      port[$3c0] := $33;
      port[$3c0] := wtab[(i+t) and 511];

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
      memw[segb800:address] := pixel;
    end;

    { stop using line buffer and render text normally }
    portw[$3d4] := $2913;

    { wait for hsync to end }
    while (port[$3da] and 1) <> 0 do;

    { panning for the first line of text }
    port[$3c0] := $33;
    port[$3c0] := t and 7;

    { line 183 (1st scroller line 0) }
    while (port[$3da] and 1) = 0 do;
    { configure colors for the first line of text }
    port[$3c0] := 1; port[$3c0] := 56;
    port[$3c0] := 2; port[$3c0] := 7;
    port[$3c0] := 3; port[$3c0] := 63;
    port[$3c0] := $20;
    while (port[$3da] and 1) <> 0 do;

    { line 184 (1st scroller line 1) }
    while (port[$3da] and 1) = 0 do;
    { configure colors for the second line of text }
    port[$3c0] := 4; port[$3c0] := 55;
    port[$3c0] := 5; port[$3c0] := 47;
    port[$3c0] := 6; port[$3c0] := 39;
    port[$3c0] := $20;
    while (port[$3da] and 1) <> 0 do;

    { line 185 (1st scroller line 2) }
    while (port[$3da] and 1) = 0 do;
    while (port[$3da] and 1) <> 0 do;

    { line 186 (1st scroller line 3) }
    while (port[$3da] and 1) = 0 do;
    while (port[$3da] and 1) <> 0 do;

    { line 187 (1st scroller line 4) }
    while (port[$3da] and 1) = 0 do;
    while (port[$3da] and 1) <> 0 do;

    { line 188 (1st scroller line 5) }
    while (port[$3da] and 1) = 0 do;
    while (port[$3da] and 1) <> 0 do;

    { line 189 (1st scroller line 6) }
    while (port[$3da] and 1) = 0 do;
    while (port[$3da] and 1) <> 0 do;

    { line 190 (1st scroller line 7) }
{$IFNDEF DOSBOXEGA}
    while (port[$3da] and 1) = 0 do;
    while (port[$3da] and 1) <> 0 do;
{$ENDIF}

    { line 191 }
    while (port[$3da] and 1) = 0 do;
    { panning for the second line of text }
    port[$3c0] := $33;
    port[$3c0] := t and 3 shl 1;
    while (port[$3da] and 1) <> 0 do;

    { lines 192-199 (2nd scroller lines 0-7) }

    { play adlib music (in sync with display) }
    playimf;
  until port[$64] and 1 = 1;

  { reset adlib }
  for i := 0 to 255 do
  begin
       port[$388] := i;
       port[$389] := 0;
       {
       port[$378] := i;
       port[$37a] := 5;
       port[$37a] := 1;
       port[$37a] := 5;

       port[$378] := 0;
       port[$37a] := 12;
       port[$37a] := 8;
       port[$37a] := 12;
       }
  end;

  { allow interrupts again and go back to standard textmode }
  asm
    sti
    mov ax, 3
    int 10h
  end;

  freemem(pixeltab, 256*200);
  freemem(addresstab, 256*200);
  freemem(colorktab, 256*200);
  freemem(iktab, 256*200);
  freemem(ctab1, 256*200);
  freemem(ctab0, 256*200);
end.