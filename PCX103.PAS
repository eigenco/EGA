uses crt;

procedure EGA_setpal(index, r, g, b : byte);

const
  ega64 : array [0..63] of byte = ( 0,  8,  1,  9, 16, 24, 17, 25,
                                    2, 10,  3, 11, 18, 26, 19, 27,
                                   32, 40, 33, 41, 48, 56, 49, 57,
                                   34, 42, 35, 43, 50, 58, 51, 59,
                                    4, 12,  5, 13, 20, 28, 21, 29,
                                    6, 14,  7, 15, 22, 30, 23, 31,
                                   36, 44, 37, 45, 52, 60, 53, 61,
                                   38, 46, 39, 47, 54, 62, 55, 63);
var
  a : byte;

begin
  a := port[$3da];
  port[$3c0] := index;
  port[$3c0] := ega64[r shl 4] or ega64[g shl 2] or ega64[b];
  port[$3c0] := $20;
end;

var
  g : integer;
  i, j, k, p, q, t, x, y, z: word;
  size : longint;
  f : file;
  pal : array [0..2047] of byte;
  data : array [0..2047] of byte;
  scanline : array [0..2047] of byte;
  egapal : array [0..255] of byte;
  xtab : array [0..1023] of byte;
  ytab : array [0..1023] of byte;
  ztab : array [0..1023] of byte;

begin
  for i := 0 to 1023 do begin
    p := round(3.5 + 2 * sin(2 * pi * i / 17.0) + 2 * sin(2 * pi * i / 21.0));
    g := round(0.7*(sin(2 * pi * i / 23.0) + sin(2 * pi * i / 27.0) + sin(2 * pi * i / 31.0)));
    if g < -2 then g := -2;
    xtab[i] := p;
    ytab[i] := 2 * $15 + g * $15;
  end;

  { go grab the full EGA palette from mode 10h }
  asm
    mov ax, 10h
    int 10h
  end;
  port[$3c7] := 0;
  for i := 0 to 191 do
    egapal[i] := port[$3c9];

  { program full EGA palette on mode 0dh }
  asm
    mov ax, 0dh
    int 10h
    cli
  end;

  portw[$3d4] := $0011;
  portw[$3d4] := $0705;
  portw[$3d4] := $1107;
  portw[$3d4] := $e110;
  portw[$3d4] := $2411;
  portw[$3d4] := $c712;
  portw[$3d4] := $e015;
  portw[$3d4] := $f016;
  portw[$3d4] := $0009; { disable double scan }

  port[$3d4] := $13;
  i := port[$3d5];
  port[$3d4] := $13;
  port[$3d5] := i + 1;

  port[$3c8] := 0;
  for i := 0 to 191 do
    port[$3c9] := egapal[i];

  { set sync polarities so they match EGA 6-bit color modes }
  port[$3c2] := $a3;

  assign(f, 'double.pcx');
  reset(f, 1);
  size := filesize(f);
  blockread(f, pal, $80); { headers }

  { palette for 16 color PCXs is at offset 16 of the header}
  for i := 0 to 15 do
    EGA_setpal(i, 0, 0, 0);

  { uncompress image data }
  q := 0;
  for x := 0 to 447 do
  begin
    { uncompress one scaline worth of data (4 bitplanes) }
    k := 0;
    repeat
      blockread(f, data, 1);
      if data[0] > 191 then
      begin
        j := data[0] and 63;
        blockread(f, data, 1);
        for i := 1 to j do
        begin
          scanline[k] := data[0];
          k := k + 1;
        end;
      end
      else
      begin
        scanline[k] := data[0];
        k := k + 1;
      end;
    until k > 167;

    { copy scanline data to video memory }
    portw[$3c4] := 1 shl 8 or 2;
    for i := 0 to 41 do
      mem[$a000:i + q] := scanline[i];
    portw[$3c4] := 2 shl 8 or 2;
    for i := 0 to 41 do
      mem[$a000:i + q] := scanline[i + 42];
    portw[$3c4] := 4 shl 8 or 2;
    for i := 0 to 41 do
      mem[$a000:i + q] := scanline[i + 84];
    portw[$3c4] := 8 shl 8 or 2;
    for i := 0 to 41 do
      mem[$a000:i + q] := scanline[i + 126];

    q := q + 42;
  end;

  { fade }
  portw[$3d4] := $2a13;

  for k := 0 to 3 do
  begin
  for i := 0 to 10 do
  begin
    for j := 0 to 15 do
      EGA_setpal(j, round(pal[16 + 3 * j + 0] * i / 10.0 ) shr 6,
                    round(pal[16 + 3 * j + 1] * i / 10.0 ) shr 6,
                    round(pal[16 + 3 * j + 2] * i / 10.0 ) shr 6);
    while (port[$3da] and 8) = 0 do;
    while (port[$3da] and 8) <> 0 do;
  end;
  for i := 10 downto 0 do
  begin
    for j := 0 to 15 do
      EGA_setpal(j, round(pal[16 + 3 * j + 0] * i / 10.0 ) shr 6,
                    round(pal[16 + 3 * j + 1] * i / 10.0 ) shr 6,
                    round(pal[16 + 3 * j + 2] * i / 10.0 ) shr 6);
    while (port[$3da] and 8) = 0 do;
    while (port[$3da] and 8) <> 0 do;
  end;
  end;

  for k := 0 to 3 do
  begin
  for i := 0 to 20 do
  begin
    for j := 0 to 15 do
      EGA_setpal(j, round(pal[16 + 3 * j + 0] * i / 20.0 ) shr 6,
                    round(pal[16 + 3 * j + 1] * i / 20.0 ) shr 6,
                    round(pal[16 + 3 * j + 2] * i / 20.0 ) shr 6);
    while (port[$3da] and 8) = 0 do;
    while (port[$3da] and 8) <> 0 do;
  end;
  for i := 20 downto 0 do
  begin
    for j := 0 to 15 do
      EGA_setpal(j, round(pal[16 + 3 * j + 0] * i / 20.0 ) shr 6,
                    round(pal[16 + 3 * j + 1] * i / 20.0 ) shr 6,
                    round(pal[16 + 3 * j + 2] * i / 20.0 ) shr 6);
    while (port[$3da] and 8) = 0 do;
    while (port[$3da] and 8) <> 0 do;
  end;
  end;

  for k := 0 to 1 do
  begin
  for i := 0 to 30 do
  begin
    for j := 0 to 15 do
      EGA_setpal(j, round(pal[16 + 3 * j + 0] * i / 30.0 ) shr 6,
                    round(pal[16 + 3 * j + 1] * i / 30.0 ) shr 6,
                    round(pal[16 + 3 * j + 2] * i / 30.0 ) shr 6);
    while (port[$3da] and 8) = 0 do;
    while (port[$3da] and 8) <> 0 do;
  end;
  for i := 30 downto 0 do
  begin
    for j := 0 to 15 do
      EGA_setpal(j, round(pal[16 + 3 * j + 0] * i / 30.0 ) shr 6,
                    round(pal[16 + 3 * j + 1] * i / 30.0 ) shr 6,
                    round(pal[16 + 3 * j + 2] * i / 30.0 ) shr 6);
    while (port[$3da] and 8) = 0 do;
    while (port[$3da] and 8) <> 0 do;
  end;
  end;



{  for i := 0 to 30 do
  begin
    for j := 0 to 15 do
      EGA_setpal(j, round(pal[16 + 3 * j + 0] * i / 30.0 ) shr 6,
                    round(pal[16 + 3 * j + 1] * i / 30.0 ) shr 6,
                    round(pal[16 + 3 * j + 2] * i / 30.0 ) shr 6);
    while (port[$3da] and 8) = 0 do;
    while (port[$3da] and 8) <> 0 do;
  end;}

  for i := 0 to 50 do
  begin
    for j := 0 to 15 do
      EGA_setpal(j, round(pal[16 + 3 * j + 0] * i / 50.0 ) shr 6,
                    round(pal[16 + 3 * j + 1] * i / 50.0 ) shr 6,
                    round(pal[16 + 3 * j + 2] * i / 50.0 ) shr 6);
    while (port[$3da] and 8) = 0 do;
    while (port[$3da] and 8) <> 0 do;
  end;

  close(f);

  for i := 0 to 100 do
  begin
    while (port[$3da] and 8) = 0 do;
    while (port[$3da] and 8) <> 0 do;
  end;

  z := 500;
  repeat
    { wait for vsync to begin }
    while (port[$3da] and 8) = 0 do;

    if z < 100 then
    for j := 0 to 15 do
      EGA_setpal(j, round(pal[16 + 3 * j + 0] * z / 100.0 ) shr 6,
                    round(pal[16 + 3 * j + 1] * z / 100.0 ) shr 6,
                    round(pal[16 + 3 * j + 2] * z / 100.0 ) shr 6);
    z := z - 1;

    { wait for vsync to end }
    while (port[$3da] and 8) <> 0 do;

    t := t + 1;
    for i := 0 to 199 do begin
      p := (i+t) and 1023;
      q := (i+t) and 1023;
      x := xtab[p];
      y := ytab[q];

      { wait for hsync to begin }
      while (port[$3da] and 1) = 0 do;

      port[$3c0] := $33;
      port[$3c0] := x;
      port[$3d4] := $13;
      port[$3d5] := y;

      { wait for hsync to end }
      while (port[$3da] and 1) <> 0 do;
    end;
    if (z > 100) and (port[$64] and 1 = 1) then z := 100;
  until z = 0;

  asm
    sti
    mov ax, 3
    int 10h
  end;
end.
