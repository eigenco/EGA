module Top(
	input	clk,
	input	R0, R1,
	input G0, G1,
	input B0, B1,
	input V, H,
	output R0v, R1v,
	output G0v, G1v,
	output B0v, B1v,
	output CSYNC,
	output reg [2:0] led
);

reg [31:0] cnt;
reg        mode;
reg [15:0] Hcnt;
reg [31:0] Vcnt;
reg  [7:0] HSr;
reg  [7:0] VSr;
reg        VD = 1;
reg        HD = 1;

always @(posedge clk)
begin
	if(V==1'b1) if(cnt<40000000) cnt = cnt + 1;
	if(V==1'b0) if(cnt>0) cnt = cnt - 1;
	if(cnt>20000000) mode = 0;
	if(cnt<20000000) mode = 1;
	led[0] = mode;
	led[1] = mode;
	led[2] = mode;
end

always @(posedge clk)
begin
	HSr <= {HSr[6:0], H};
	VSr <= {VSr[6:0], V};
	if(VSr[7:6]==2'b00 && VSr[1:0]==2'b11) Vcnt <= 0;
	else Vcnt <= Vcnt + 1;
	if(HSr[7:6]==2'b00 && HSr[1:0]==2'b11) Hcnt <= 0;
	else Hcnt <= Hcnt + 1;
	if(Vcnt<89700 || Vcnt>780000) VD <= 0;
	else VD <= 1;
	if(Hcnt<610 || Hcnt>2950) HD <= 0;
	else HD <= 1;
end

assign R0v = (mode ? HD & VD : 1) & (mode ? G0 : R0);
assign R1v = (mode ? HD & VD : 1) & R1;
assign G0v = (mode ? HD & VD : 1) & (mode ? (~G0 & R1 & G1 & ~B1 ? 1 : G0) : G0);
assign G1v = (mode ? HD & VD : 1) & (mode ? (~G0 & R1 & G1 & ~B1 ? 0 : G1) : G1);
assign B0v = (mode ? HD & VD : 1) & (mode ? G0 : B0);
assign B1v = (mode ? HD & VD : 1) & B1;
assign CSYNC = (mode ? ~(V^H) : V^H);

endmodule
