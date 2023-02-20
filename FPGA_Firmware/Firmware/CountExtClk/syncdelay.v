// Fast Multisource Pulse Registration System
// Module:
// syncdelay
// (c) Sergey V. Polyakov 2006-forever
module syncdelay (
 myin, clk, myout
);

output myout;
reg myout;

input myin;
input clk;

always @ (posedge clk)
begin
	myout <= myin;
end

endmodule