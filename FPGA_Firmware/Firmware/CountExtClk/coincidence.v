// Fast Multisource Pulse Registration System
// Module:
// summator
// Summator with synchronious clear input (readout_clear)
// Last sum is kept at the output until the next synchronious readout_clear is recieved
// (c) Sergey V. Polyakov 2006-forever
module coincidence (
	channel, clk, clear, enable,
	stats
);

input [3:0] channel;
input clear;
input clk;
input enable;

output [511:0] stats;
reg    [511:0] stats;

//initial
//begin
//	stats <= 512'b0;
//end

always @ (posedge clk)
	begin
		if (clear)
		  begin
			stats[47:0] = enable;
			stats[79:48] = enable*channel[0];
			stats[111:80] = enable*channel[1];
			stats[143:112] = enable*channel[2];
			stats[175:144] = enable*channel[3];
			
			stats[207:176] = enable*(channel[0]&channel[1]?1'b1:1'b0);
			stats[239:208] = enable*(channel[0]&channel[2]?1'b1:1'b0);
			stats[271:240] = enable*(channel[0]&channel[3]?1'b1:1'b0);
			stats[303:272] = enable*(channel[1]&channel[2]?1'b1:1'b0);
			stats[335:304] = enable*(channel[1]&channel[3]?1'b1:1'b0);
			stats[367:336] = enable*(channel[2]&channel[3]?1'b1:1'b0);
			stats[399:368] = enable*(channel[0]&channel[1]&channel[2]?1'b1:1'b0);
			stats[431:400] = enable*(channel[0]&channel[1]&channel[3]?1'b1:1'b0);
			stats[463:432] = enable*(channel[0]&channel[2]&channel[3]?1'b1:1'b0);
			stats[495:464] = enable*(channel[1]&channel[2]&channel[3]?1'b1:1'b0);
			stats[511:496] = enable*(channel[0]&channel[1]&channel[2]&channel[3]?1'b1:1'b0);
		  end
		else
		  begin
			stats[47:0] = enable*stats[47:0]+enable;
			stats[79:48] = enable*stats[79:48]+channel[0];
			stats[111:80] = enable*stats[111:80]+channel[1];
			stats[143:112] = enable*stats[143:112]+channel[2];
			stats[175:144] = enable*stats[175:144]+channel[3];
			
			stats[207:176] = enable*stats[207:176]+(channel[0]&channel[1]?1'b1:1'b0);
			stats[239:208] = enable*stats[239:208]+(channel[0]&channel[2]?1'b1:1'b0);
			stats[271:240] = enable*stats[271:240]+(channel[0]&channel[3]?1'b1:1'b0);
			stats[303:272] = enable*stats[303:272]+(channel[1]&channel[2]?1'b1:1'b0);
			stats[335:304] = enable*stats[335:304]+(channel[1]&channel[3]?1'b1:1'b0);
			stats[367:336] = enable*stats[367:336]+(channel[2]&channel[3]?1'b1:1'b0);
			stats[399:368] = enable*stats[399:368]+(channel[0]&channel[1]&channel[2]?1'b1:1'b0);
			stats[431:400] = enable*stats[431:400]+(channel[0]&channel[1]&channel[3]?1'b1:1'b0);
			stats[463:432] = enable*stats[463:432]+(channel[0]&channel[2]&channel[3]?1'b1:1'b0);
			stats[495:464] = enable*stats[495:464]+(channel[1]&channel[2]&channel[3]?1'b1:1'b0);
			stats[511:496] = enable*stats[511:496]+(channel[0]&channel[1]&channel[2]&channel[3]?1'b1:1'b0);
		  end
	end
endmodule