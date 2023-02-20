// Glow two LEDs
// (c) KNJN LLC - fpga4fun.com

module ledglow2(clk, LED);
input clk;
output [1:0] LED;

reg [31:0] cnt;
always @(posedge clk) cnt<=cnt+32'h1;
wire [4:0] cnt5 = cnt[23:19];

reg [4:0] PWM;
wire [4:0] PWM_input = cnt5[4] ? {1'b0, cnt5[3:0]} : (5'h10-cnt5[3:0]);
always @(posedge clk) PWM <= PWM[3:0]+PWM_input;

assign LED[0] = cnt[20] & cnt[22] & cnt[23];
assign LED[1] = PWM[4];
endmodule