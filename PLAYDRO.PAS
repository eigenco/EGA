(* {$DEFINE OPL3LPT} *)

{$G-}
uses crt, dos;

var
  i, j, k : word;
  dro0, dro1 : pointer;
  dro_file : file;
  dro_pos : longint;
  dro_pause : word;
  dro_codemap : array [0..127] of byte;
  dro_iShortDelayCode : byte;
  dro_iLongDelayCode : byte;
  dro_iCodemapLength : byte;
  dro_filesize : longint;
  int08save : pointer;

{$F+,S-}
procedure playdro; interrupt;
var
  a, b : byte;
begin
  if dro_pause > 0 then dro_pause := dro_pause - 1
  else
  begin
    repeat
      if dro_pos < 64000 then
      begin
        a := mem[seg(dro0^):dro_pos];
        b := mem[seg(dro0^):dro_pos+1];
      end else
      begin
        a := mem[seg(dro1^):dro_pos-64000];
        b := mem[seg(dro1^):dro_pos-63999];
      end;

      if a = dro_iShortDelayCode then dro_pause := b + 1;
      if a = dro_iLongDelayCode then dro_pause := (b + 1) shl 8;

      if dro_pause = 0 then
        if a < 128 then
        begin
{$IFDEF OPL3LPT}
          port[$378] := dro_codemap[a];
          port[$37a] := 13;
          port[$37a] := 9;
          port[$37a] := 13;
          port[$378] := b;
          port[$37a] := 12;
          port[$37a] := 8;
          port[$37a] := 12;
{$ELSE}
          port[$388] := dro_codemap[a];
          port[$389] := b;
{$ENDIF}
        end else
        begin
{$IFDEF OPL3LPT}
          port[$378] := dro_codemap[a and 127];
          port[$37a] := 5;
          port[$37a] := 1;
          port[$37a] := 5;
          port[$378] := b;
          port[$37a] := 12;
          port[$37a] := 8;
          port[$37a] := 12;
{$ELSE}
          port[$38a] := dro_codemap[a and 127];
          port[$38b] := b;
{$ENDIF}
        end;
      dro_pos := dro_pos + 2;
    until dro_pause > 0;
  end;
  port[$20] := $20;
end;
{$F-,S+}

begin
  clrscr;

  { disable cursor }
  portw[$3d4] := $100a;

  write('Loading music...');

  assign(dro_file, 'opl3.dro');
  reset(dro_file, 1);
  dro_filesize := filesize(dro_file);
  getmem(dro0, 64000);
  getmem(dro1, dro_filesize - 64000);
  blockread(dro_file, dro_codemap, 26);
  dro_iShortDelayCode := dro_codemap[23];
  dro_iLongDelayCode := dro_codemap[24];
  dro_iCodemapLength := dro_codemap[25];
  blockread(dro_file, dro_codemap, dro_iCodemapLength);
  blockread(dro_file, dro0^, 64000);
  blockread(dro_file, dro1^, dro_filesize - 64026 - dro_iCodemapLength);
  close(dro_file);

  writeln('done.');

  port[$21] := 255-3; { ints besides 8 and 9 off }
  getintvec(8, int08save);
  setintvec(8, addr(playdro));

  port[$43] := $36;
  i := 1193182 div 1000;
  port[$40] := lo(i);
  port[$40] := hi(i);

  write('Playing music...');
  repeat
    gotoxy(1,3);
    writeln(dro_pos, ' / ', dro_filesize - 26 - dro_iCodemapLength);
  until keypressed or (dro_pos > dro_filesize - 26 - dro_iCodemapLength);
  writeln('done.');

  port[$43] := $36;
  port[$40] := 0;
  port[$40] := 0;
  setintvec(8, int08save);

  { reset adlib }
  for i := $b0 to $b8 do
  begin
{$IFDEF OPL3LPT}
     port[$378] := i;
     port[$37a] := 13;
     port[$37a] := 9;
     port[$37a] := 13;
     for j := 0 to 5 do k := port[$378];
     port[$378] := 0;
     port[$37a] := 12;
     port[$37a] := 8;
     port[$37a] := 12;
     for j := 0 to 34 do k := port[$378];
{$ELSE}
     port[$388] := i;
     port[$389] := 0;
{$ENDIF}
  end;
  for i := $b0 to $b8 do
  begin
{$IFDEF OPL3LPT}
     port[$378] := i;
     port[$37a] := 5;
     port[$37a] := 1;
     port[$37a] := 5;
     for j := 0 to 5 do k := port[$378];
     port[$378] := 0;
     port[$37a] := 12;
     port[$37a] := 8;
     port[$37a] := 12;
     for j := 0 to 34 do k := port[$378];
{$ELSE}
     port[$38a] := i;
     port[$38b] := 0;
{$ENDIF}
  end;

  freemem(dro1, dro_filesize - 64026 - dro_iCodemapLength);
  freemem(dro0, 64000);

  textmode(3);
end.
