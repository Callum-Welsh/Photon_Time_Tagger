// Blink two LEDs
// (c) KNJN LLC - fpga4fun.com

module ledblink2(clk, LED);
input clk;
output [1:0] LED;

reg [31:0] cnt;
always @(posedge clk) cnt <= cnt + 32'h1;

assign LED[0] = ~cnt[22] & ~cnt[20];
assign LED[1] = cnt[23];
endmodule