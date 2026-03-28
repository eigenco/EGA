{
  Tested to work on at least on 12 MHz 286 and EGA adapter with
  lowres EGA64 compatible monitor.

  * EGA64 colors in lowres mode
  * per scanline pel panning
   * This only works on real EGA adapter
   * Can be emulated on DOSBox-X with VGA mode when allow hpel effects = true
  * scanline skip and doubling
}

{$DEFINE DOSBOXX}

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
  g, h : integer;
  i, j, k, p, q, t, x, y, z: word;
  size : longint;
  f : file;
  data : array [0..32767] of byte;
  scanline : array [0..4*320-1] of byte;
  egapal : array [0..255] of byte;
  xtab : array [0..1023] of byte;
  ytab : array [0..1023] of byte;
  ztab : array [0..1023] of word;

begin
  for i := 0 to 1023 do begin
    p := round(3.5 + 3.5 * sin(2 * pi * i / 64.0));
    g := round(0.55 * sin(2 * pi * i / 96.0));
    j := (i + 256) and 1023;
    h := round(6 * sin(2 * pi * j / 96.0));
    xtab[i] := p;
    ytab[i] := 2 * $15 + g * $15;
    ztab[i] := 6 * 42 + h * 42;
  end;

{$IFDEF DOSBOXX}
  { go grab the full EGA palette from mode 10h }
  asm
    mov ax, 10h
    int 10h
  end;
  port[$3c7] := 0;
  for i := 0 to 191 do
    egapal[i] := port[$3c9];
{$ENDIF}

  { program full EGA palette on mode 0dh }
  asm
    mov ax, 0dh
    int 10h
    cli
  end;

{$IFDEF DOSBOXX}
  port[$3c8] := 0;
  for i := 0 to 191 do
    port[$3c9] := egapal[i];
  portw[$3d4] := $0011;
  portw[$3d4] := $0705;
  portw[$3d4] := $1107;
  portw[$3d4] := $e110;
  portw[$3d4] := $2411;
  portw[$3d4] := $c712;
  portw[$3d4] := $e015;
  portw[$3d4] := $f016;
  portw[$3d4] := $0009; { disable double scan }
{$ENDIF}

  { set address offset between adjacent scanlines }
  portw[$3d4] := $1513;

  { set sync polarities for 6-bit colors }
  port[$3c2] := $a3;

  assign(f, 'car.pcx');

  reset(f, 1);
  size := filesize(f);
  blockread(f, data, $80); { headers }

  { palette for 16 color PCXs is at offset 16 of the header }
  for i := 0 to 15 do
    EGA_setpal(i, data[16 + 3 * i + 0] shr 6, data[16 + 3 * i + 1] shr 6,
               data[16 + 3 * i + 2] shr 6);

  blockread(f, data, size - $80);

  { uncompress image data }
  p := 0; { current location in the image data }
  q := 0;
  for x := 0 to 229 do
  begin

    { uncompress one scaline worth of data (4 bitplanes) }
    k := 0;
    repeat
      if data[p] > 191 then
      begin
        j := data[p] and 63;
        p := p + 1;
        for i := 1 to j do
        begin
          scanline[k] := data[p];
          k := k + 1;
        end;
      end
      else
      begin
        scanline[k] := data[p];
        k := k + 1;
      end;
      p := p + 1;
    until k > 159;

    for j := 0 to 1 do begin

    { copy scanline data to video memory }
    portw[$3c4] := 1 shl 8 or 2;
    for i := 0 to 39 do
      mem[$a000:i + q] := scanline[i];
    portw[$3c4] := 2 shl 8 or 2;
    for i := 0 to 39 do
      mem[$a000:i + q] := scanline[i + 40];
    portw[$3c4] := 4 shl 8 or 2;
    for i := 0 to 39 do
      mem[$a000:i + q] := scanline[i + 80];
    portw[$3c4] := 8 shl 8 or 2;
    for i := 0 to 39 do
      mem[$a000:i + q] := scanline[i + 120];
    q := q + 42;
    end;
  end;

  close(f);

  repeat
    { wait for vsync to begin }
    while (port[$3da] and 8) = 0 do;

    t := t + 1;
    z := ztab[t and 1023];
    port[$3d4] := $0c;
    port[$3d5] := hi(z);
    port[$3d4] := $0d;
    port[$3d5] := lo(z);

    { wait for vsync to end }
    while (port[$3da] and 8) <> 0 do;

    for i := 0 to 199 do begin
      z := (i+t) and 1023;
      x := xtab[z];
      y := ytab[z];

      { wait for hsync to begin }
      while (port[$3da] and 1) = 0 do;

      port[$3c0] := $33;
      port[$3c0] := x;
      port[$3d4] := $13;
      port[$3d5] := y;

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
