//TTL outputs
//(c) 2014 Joffrey Peters

module TTLOutputs(
 PCINSTRUCTION, TTLOUTPUTS, FX2_Clk
);
//
input [7:0] PCINSTRUCTION;
input FX2_Clk;
output [1:0] TTLOUTPUTS;

reg [1:0] TTLOUTPUTS;
reg [3:0] state;
reg [2:0] latch; //0 will be instruction latch, 1 will be pulse latch for ch. 0, 2 will be pulse latch for ch. 1.

always @(posedge FX2_Clk)

	begin
		if(~latch[0] & PCINSTRUCTION[4])
			begin
				latch[0] <= 1'b1; //instruction latch
				if(PCINSTRUCTION[6])
					begin
						TTLOUTPUTS[0] = 1'b1; //pulse TTL0
						latch[1] = 1'b1; //ch. 0 pulse latch
					end
				if(PCINSTRUCTION[7])
					begin
						TTLOUTPUTS[1] = 1; //pulse TTL1
						latch[2] = 1'b1; //ch. 1 pulse latch
					end
			end
		else if(~latch[0] & PCINSTRUCTION[5])
			begin
				latch[0] <=1'b1;
				if(PCINSTRUCTION[6])
					begin
						TTLOUTPUTS[0] <= ~TTLOUTPUTS[0]; //toggle TTL0
					end	
				if(PCINSTRUCTION[7])
					begin
						TTLOUTPUTS[1] <= ~TTLOUTPUTS[1]; //toggle TTL1
					end
			end
		else
			begin
				if(latch[1])
					begin
						TTLOUTPUTS[0] = 1'b0;
						latch[1] = 1'b0;
					end
				
				if(latch[2])
					begin
						TTLOUTPUTS[1] = 1'b0;
						latch[2] = 1'b0;
					end
				if(~PCINSTRUCTION[4] & ~PCINSTRUCTION[5]) latch[0] <= 1'b0; //instruction latch off
			end
	end
	
	

//this isn't right, because TTLOUTPUTS isn't a wire.
//assign TTLOUTPUTS[0] = (state==4'b0001 || state==4'b0100 && ~TTLOUTPUTS[0] || state==4'b0000 && TTLOUTPUTS[0])? 1: 0;  //set to 1 if pulsing, or toggling from zero, or leave high if toggled high and doing nothing
//assign TTLOUTPUTS[1] = (state==4'b0010 || state==4'b1000 && ~TTLOUTPUTS[1] || state==4'b0000 && TTLOUTPUTS[1])? 1: 0;

endmodule
//