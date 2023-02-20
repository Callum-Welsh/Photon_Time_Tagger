// Fast Multisource Pulse Registration System
// Module:
// allclickreg
// Pulse Registration and Time Stamping
// (c) Sergey V. Polyakov 2006-forever
module allclickreg (channel, clk, clear, operate, data, ready);

input [3:0] channel;
input clk;
input clear;
input operate;

reg [26:0] timer;

reg ready;
reg [31:0] data;

output ready; 
output [31:0] data;

always @ (posedge clk)
begin
	if (channel!=3'b0  || (timer==1'b0 && operate))
	begin
		data[26:0] <= timer[26:0];
		data[31] <= (timer==1'b0)?1'b1:1'b0;
		data[30:27] <= channel;
		ready <= 1'b1;
	end
	else
	begin
		ready <= 1'b0;
		data <= 32'b0;
	end	
	timer <= clear?0:timer+1'b1;
end

endmodule