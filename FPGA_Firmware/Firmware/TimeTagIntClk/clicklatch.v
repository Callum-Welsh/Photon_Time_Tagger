// Fast Multisource Pulse Registration System
// Module:
// clicklatch
// Pulse Edge Detection
// (c) Sergey V. Polyakov 2006-forever
module clicklatch (click, clock, data );

input click;
input clock;

output data;

reg state;
reg data;

always @ (posedge clock)
begin
	if (click == 1'b1 && state == 1'b0 )
	begin
		state = 1'b1;
		data = 1'b1;
	end
	else
	begin
		if (data == 1'b1 )
		begin
			data <=0;
		end
	end
		

		if (click == 1'b0 )
		begin
	 		state <= 1'b0;
		end	
		
end
endmodule