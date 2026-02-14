var
  a : byte;
begin
  port[$22] := $4d;
  a := port[$23];
  port[$22] := $4d;
  port[$23] := a and $8f;

  port[$22] := $41;
  port[$23] := 4; { (4) Bus Clock = PROCCLK/2, def = 2 }
end.