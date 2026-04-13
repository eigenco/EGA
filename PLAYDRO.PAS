{$G-}
uses crt;

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

procedure playdro;
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
          port[$388] := dro_codemap[a];
          port[$389] := b;
        end else
        begin
          port[$38a] := dro_codemap[a and 127];
          port[$38b] := b;
        end;
      dro_pos := dro_pos + 2;
    until dro_pause > 0;
  end;
end;

begin
  { load music }
  assign(dro_file, 'opl3.dro');
  reset(dro_file, 1);
  dro_filesize := filesize(dro_file);
  getmem(dro0, 64000);
  getmem(dro1, dro_filesize-64000);
  blockread(dro_file, dro_codemap, 23); { skip header }
  blockread(dro_file, dro_codemap, 3); { iShortDelayCode, iLongDelayCode, iCodemapLength }
  dro_iShortDelayCode := dro_codemap[0];
  dro_iLongDelayCode := dro_codemap[1];
  dro_iCodemapLength := dro_codemap[2];
  blockread(dro_file, dro_codemap, dro_iCodemapLength);
  blockread(dro_file, dro0^, 64000);
  blockread(dro_file, dro1^, dro_filesize-64000-23-3-dro_iCodemapLength);
  close(dro_file);

  repeat
    playdro;
    delay(1);
  until keypressed;

  { reset adlib }
  for i := 0 to 255 do
  begin
       port[$388] := i;
       port[$389] := 0;
       port[$38a] := i;
       port[$38b] := 0;
  end;

  freemem(dro1, dro_filesize-64000);
  freemem(dro0, 64000);
end.
