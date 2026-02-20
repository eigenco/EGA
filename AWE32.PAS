(* 
  Plays built-in ROM samples on Sound Blaster AWE32.
  Reads and writes to wavetable synth DRAM.
  Assumes having been initialized (UNISOUND v0.82a).
  Assumes: SET BLASTER=A220 I5 D1 H5 P330 E620 T6
*)
uses crt;

procedure writehex(h : word);
const
  hex : array[0..15] of char = '0123456789ABCDEF';
begin
  write(hex[h shr 12 and 15], hex[h shr 8 and 15], hex[h shr 4 and 15], hex[h and 15]);
end;

procedure writehexln(h : word);
begin
  writehex(h);
  writeln;
end;

procedure AWE_memw(address : longint; data : word);
begin
  portw[$e22] := 160; portw[$a20] := $80;
  portw[$e22] := 96; portw[$620] := 0; portw[$622] := 0;
  portw[$e22] := 192; portw[$620] := 0; portw[$622] := 0;
  portw[$e22] := 224; portw[$620] := 0; portw[$622] := 0;
  portw[$e22] := 32; portw[$620] := 0; portw[$622] := $4000;
  portw[$e22] := 0; portw[$620] := 0; portw[$622] := $4000;
  portw[$e22] := 0; portw[$a20] := 0; portw[$a22] := $0600;

  portw[$e22] := 32+22;
  portw[$a20] := address and 65535;
  portw[$a22] := address shr 16;
  portw[$e22] := 32+26;
  portw[$a20] := data;
end;

function AWE_memr(address : longint) : word;
var
  a : word;
begin
  portw[$e22] := 160; portw[$a20] := $80;
  portw[$e22] := 96; portw[$620] := 0; portw[$622] := 0;
  portw[$e22] := 192; portw[$620] := 0; portw[$622] := 0;
  portw[$e22] := 224; portw[$620] := 0; portw[$622] := 0;
  portw[$e22] := 32; portw[$620] := 0; portw[$622] := $4000;
  portw[$e22] := 0; portw[$620] := 0; portw[$622] := $4000;
  portw[$e22] := 0; portw[$a20] := 0; portw[$a22] := $0400;

  portw[$e22] := 32+20;
  portw[$a20] := address and 65535;
  portw[$a22] := address shr 16;
  portw[$e22] := 32+26;
  a := portw[$a20];
  AWE_memr := portw[$a20];
end;

begin
  clrscr;

  AWE_memw($200000, $dead);
  writehexln(AWE_memr(0));
  writehexln(AWE_memr($200000));

  portw[$e22] := 4 shl 5; portw[$a20] := $8000; { ENV/ENVVOL }
  portw[$e22] := 4 shl 5; portw[$a22] := $7f7f; { ENV/ATKHLDV }
  portw[$e22] := 0 shl 5; portw[$e20] := $d000; { ENV/IP: initial pitch }

  { OSC/CCCA: start address }
  portw[$e22] := 0 shl 5;
  portw[$a20] := $0000;
  portw[$a22] := $0000;

  { OSC/PSST: loop start address }
  portw[$e22] := 6 shl 5;
  portw[$620] := $0000;
  portw[$622] := $0008;

  { OSC/CSL: loop end address }
  portw[$e22] := 7 shl 5;
  portw[$620] := $0001;
  portw[$622] := $0008;

  { ENVGEN/DCYSUSV: volume envelope sustain and decay }
  portw[$e22] := 5 shl 5;
  portw[$a20] := $7f7f;
end.
