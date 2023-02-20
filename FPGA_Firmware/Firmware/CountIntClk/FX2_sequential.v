// Fast Multisource Pulse Registration System
// Module:
// Flexible, 3-fifo multidirectional FX2 USB-2 interface
// (c) Sergey V. Polyakov 2006-forever

module FX2_sequential(
	FX2_CLK, FX2_FD, FX2_SLRD, FX2_SLWR, FX2_flags, 
	FX2_PA_2, FX2_PA_3, FX2_PA_4, FX2_PA_5, FX2_PA_6, FX2_PA_7, 
	FPGA_WORD, FPGA_WORD_AVAILIABLE, FPGA_WORD_ACCEPTED, PCINSTRUCTION, LENGTH, REQUEST_LENGTH, DEBUG0, DEBUG1
);
//************************************************************************
//FPGA interface
//************************************************************************
input [7:0] FPGA_WORD;
input FPGA_WORD_AVAILIABLE;
input [15:0] LENGTH;
output FPGA_WORD_ACCEPTED; 
output [7:0] PCINSTRUCTION;
output REQUEST_LENGTH;
//************************************************************************
//FIFO interface
//************************************************************************
input FX2_CLK;
inout [7:0] FX2_FD;
input [2:0] FX2_flags; //0:fifo2 data availible; 1:fifo3 data availible; 2:fifo4 not full; 
output FX2_SLRD, FX2_SLWR;

output FX2_PA_2;//fpga->fifo data accept
output FX2_PA_3;//always up
output FX2_PA_4;//fifo address (odd/even)
output FX2_PA_5;//fifo address (higher bit)
output FX2_PA_6;//fifo packet end
input FX2_PA_7; //fifo5 not full

output DEBUG0; //debug channel
output DEBUG1; //debug channel


wire DEBUG0;
wire DEBUG1;
// Rename "FX2" ports into "FIFO" ports, to give them more meaningful names
// FX2 USB signals are active low, take care of them now
// Note: You probably don't need to change anything in this section

// FX2 outputs
wire FIFO_CLK = FX2_CLK;
wire FIFO2_empty = ~FX2_flags[0];	wire FIFO2_data_available = ~FIFO2_empty;
wire FIFO3_empty = ~FX2_flags[1];	wire FIFO3_data_available = ~FIFO3_empty;
wire FIFO4_full = ~FX2_flags[2];	wire FIFO4_ready_to_accept_data = ~FIFO4_full;
wire FIFO5_full = ~FX2_PA_7;		wire FIFO5_ready_to_accept_data = ~FIFO5_full;
assign FX2_PA_3 = 1'b1;

// Wires associated with bidirectional protocol
wire FPGA_WORD_ACCEPTED;
wire [7:0] FIFO_DATAOUT;
wire FIFO_WR;
wire FIFO_DATAOUT_OE;

// Wires associated with packet length monitoring and reporting via FIFO5
wire REQUEST_LENGTH;
wire [7:0] FIFO5;


// FX2 inputs
wire FIFO_RD,  FIFO_PKTEND, FIFO_DATAIN_OE; //, FIFO_DATAOUT_OE, FIFO_WR;
wire FX2_SLRD = ~FIFO_RD;
wire FX2_SLWR = ~FIFO_WR;
assign FX2_PA_2 = ~FIFO_DATAIN_OE;
assign FX2_PA_6 = ~FIFO_PKTEND;

wire [1:0] FIFO_FIFOADR;
assign {FX2_PA_5, FX2_PA_4} = FIFO_FIFOADR; //4b'10** = FIFO4;  00 = FIFO2; 11 = FIFO5;

// FX2 bidirectional data bus
wire [7:0] FIFO_DATAIN = FX2_FD;
assign FX2_FD = FIFO_DATAOUT_OE ? FIFO_DATAOUT : 8'hZZ;

////////////////////////////////////////////////////////////////////////////////
// Here we wait until we receive some data from either PC or FPGA (default is FPGA).
// If PC speaks, send an end_packet to its fifo to let it grab the collected data.
// Whenever FPGA is ready to transmit data, and the FIFO is not busy talking to PC, 
// accept FPGA's data and signal this back to FPGA

reg [3:0] state;
reg [7:0] mycount;

always @(posedge FIFO_CLK)
case(state)
	4'b0101: if (FIFO2_data_available) state <= 4'b0001;  // do nothing but listen for the computer 

	4'b0001:
		begin              
			mycount <= 8'b0;
			state <= 4'b0011; // wait for turnaround to read 1 byte from PC 
		end
			 
	4'b0011: if (FIFO2_empty) //If byte transfer from PC has been completed, interpret the command byte
	
		begin
			if(FIFO_DATAIN[4] | FIFO_DATAIN[5]) //pulse or toggle
				begin
					if (~FIFO_DATAIN[0] && ~FIFO_DATAIN[1] && ~FIFO_DATAIN[2] && ~FIFO_DATAIN[3]) state <= 4'b0101; //go back to start if just pulse/toggle
					else state <= 4'b0100; // after the data from PC, turnaround to fifo4 to send the 64 bytes 
				end
			else state <= 4'b0100; //no pulse/toggle -> continue with data transmission
		end
	
	4'b0100:
			//begin
				//if(FIFO_DATAIN[4]||FIFO_DATAIN[5]) state <= 4'b0101;
				//else
				begin
					#2 state <= 4'b0111;                      // wait 2 cycles for turnaround to send the 64 bytes
				end
			//end
			
	4'b0111: ////////////////////////////////////////////////
			begin
				if ( mycount < 8'b01000000 ) //64
					begin
						mycount <= mycount + ( ((FPGA_WORD_AVAILIABLE)&&(FIFO2_empty)&&(FIFO4_ready_to_accept_data))? 1'b1:1'b0 );
					end
		      else
					begin
						state <=4'b0110;     // write all 64 bytes of FPGA data to FIFO4 as it comes
					end
			end
			
	4'b0110: state <= 4'b1100;           // transmit an end-packet fifo4 

	4'b1100: state <= 4'b1101;                            //wait (data counter)
	4'b1101: state <= 4'b1110;                            //transmit a higher byte (data counter)
	4'b1110: state <= 4'b1111;                            //transmit a lower byte  (data counter)
	4'b1111: state <= 4'b0101; 						      //transmit an end-packet (data counter) & finish the cycle

	default: state <= 4'b0101;

endcase

assign FIFO_FIFOADR = {state[2], state[3]};  		      // FIFO2 or FIFO4 or FIFO5

//transmit info from PC to FPGA
assign FIFO_RD = (state==4'b0011);
assign PCINSTRUCTION[7:0] = (state==4'b0011)? FIFO_DATAIN[7:0]: 8'b0;
assign FIFO_DATAIN_OE = ~state[2];

//transmit info from FPGA to PC
assign FPGA_WORD_ACCEPTED = (state==4'b0111)&&(FPGA_WORD_AVAILIABLE)&&(FIFO2_empty)&&(FIFO4_ready_to_accept_data);//&&~FIFO_DATAIN[4]&&~FIFO_DATAIN[5];
assign FIFO5 = (state==4'b1101)? LENGTH[15:8] : LENGTH[7:0];
assign FIFO_DATAOUT = (state==4'b0111)? FPGA_WORD : FIFO5;
assign FIFO_WR = ((state==4'b0111)&&(FPGA_WORD_AVAILIABLE)&&(FIFO2_empty)&&(FIFO4_ready_to_accept_data)) || state==4'b1101 || state==4'b1110;
assign FIFO_DATAOUT_OE = ((state==4'b0111)&&(FPGA_WORD_AVAILIABLE)&&(FIFO2_empty)&&(FIFO4_ready_to_accept_data)) || state==4'b1101 || state==4'b1110;
assign FIFO_PKTEND = (state==4'b1111) || ( (state==4'b0110) ); //&& (LENGTH < 16'b0000001000000000) ) ;

//request length of the data collected prior to computers data query
assign REQUEST_LENGTH = state==4'b0100;
//debugging
assign DEBUG0 = state==4'b0100;
assign DEBUG1 = mycount[1];

endmodule

/* stuff commented out that I don't want to get rid of just yet
	4'b0111: 
			begin
				if (FIFO2_data_available) state <= 4'b0001;
		        else if (FIFO4_full) state <=4'b0101;     // listen to PC at FIFO2 write all FPGA data to FIFO4 as it comes
			end
	4'b0101: if (FIFO2_data_available) state <= 4'b0001;
	        else 
			if (~FIFO4_full) state <=4'b0111;             // do nothing but listen for the computer but if FIFO4 gets emptied, send more
	4'b0001: state <= 4'b0011;                            // wait for turnaround to read 1 byte from PC and send REQUEST_LENGTH from FIFO counter

	4'b0011: if (~FIFO2_data_available) state <= 4'b1100; // after the data from PC turnaround to fifo5 to send the data counter
	4'b1100: state <= 4'b1101;                            //wait (data counter)
	4'b1101: state <= 4'b1110;                            //transmit a higher byte (data counter)
	4'b1110: state <= 4'b1111;                            //transmit a lower byte  (data counter)
	4'b1111: state <= 4'b0100; 						      //transmit an end-packet (data counter)

	4'b0100: begin
				#2 state <= 4'b0110;                      // wait for turnaround to transmit an end-packet
			end
	4'b0110: if (~FIFO4_full) state <= 4'b0111;           // transmit an end-packet and return to listen/transmit
			else state <= 4'b0101;					      // but if FIFO4 is full return to idle
	default: state <= 4'b0111;
*/