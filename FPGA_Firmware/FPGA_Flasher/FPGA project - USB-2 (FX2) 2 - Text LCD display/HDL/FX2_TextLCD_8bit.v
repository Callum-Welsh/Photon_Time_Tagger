// Sample code for FX2 USB-2 interface
// (c) fpga4fun.com KNJN LLC - 2015 to 2017

// We control a text LCD in 4bit mode from FX2 USB-2
// Tested with Xylo-E

////////////////////////////////////////////////////////////////////////////////
module FX2_TextLCD(
	FX2_CLK, FX2_FD, FX2_SLRD, FX2_SLWR, FX2_flags,
	FX2_PA_2, FX2_PA_3, FX2_PA_4, FX2_PA_5, FX2_PA_6, FX2_PA_7,

	LCD_RS, LCD_RW, LCD_E, LCD_DB
);

input FX2_CLK;
inout [7:0] FX2_FD;
input [2:0] FX2_flags;
output FX2_SLRD, FX2_SLWR;

//output FX2_PA_0;
//output FX2_PA_1;
output FX2_PA_2;
output FX2_PA_3;
output FX2_PA_4;
output FX2_PA_5;
output FX2_PA_6;
input FX2_PA_7;

output LCD_RS, LCD_RW, LCD_E;
output [7:0] LCD_DB;

////////////////////////////////////////////////////////////////////////////////
// Rename "FX2" ports into "FIFO" ports, to give them more meaningful names
// FX2 USB signals are active low, take care of them now
// Note: You probably don't need to change anything in this section

// FX2 outputs
wire FIFO_CLK = FX2_CLK;

wire FIFO2_empty = ~FX2_flags[0];	wire FIFO2_data_available = ~FIFO2_empty;
wire FIFO3_empty = ~FX2_flags[1];	wire FIFO3_data_available = ~FIFO3_empty;
wire FIFO4_full = ~FX2_flags[2];	wire FIFO4_ready_to_accept_data = ~FIFO4_full;
wire FIFO5_full = ~FX2_PA_7;		wire FIFO5_ready_to_accept_data = ~FIFO5_full;
//assign FX2_PA_0 = 1'b1;
//assign FX2_PA_1 = 1'b1;
assign FX2_PA_3 = 1'b1;

// FX2 inputs
wire FIFO_RD, FIFO_WR, FIFO_PKTEND, FIFO_DATAIN_OE, FIFO_DATAOUT_OE;
assign FX2_SLRD = ~FIFO_RD;
assign FX2_SLWR = ~FIFO_WR;
assign FX2_PA_2 = ~FIFO_DATAIN_OE;
assign FX2_PA_6 = ~FIFO_PKTEND;

wire [1:0] FIFO_FIFOADR;
assign {FX2_PA_5, FX2_PA_4} = FIFO_FIFOADR;

// FX2 bidirectional data bus
wire [7:0] FIFO_DATAIN = FX2_FD;
wire [7:0] FIFO_DATAOUT;
assign FX2_FD = FIFO_DATAOUT_OE ? FIFO_DATAOUT : 8'hZZ;

////////////////////////////////////////////////////////////////////////////////
// So now everything is in positive logic
//	FIFO_RD, FIFO_WR, FIFO_DATAIN, FIFO_DATAOUT, FIFO_DATAIN_OE, FIFO_DATAOUT_OE, FIFO_PKTEND, FIFO_FIFOADR
//	FIFO2_empty, FIFO2_data_available
//	FIFO3_empty, FIFO3_data_available
//	FIFO4_full, FIFO4_ready_to_accept_data
//	FIFO5_full, FIFO5_ready_to_accept_data

////////////////////////////////////////////////////////////////////
assign FIFO_FIFOADR = 2'b00;		// select FIFO2
assign FIFO_DATAIN_OE = 1'b1;			// ask the FX2 to always drive out data to us
assign FIFO_DATAOUT_OE = 1'b0;			// while we never output data

reg state;
always @(posedge FIFO_CLK)
case(state)
	1'b0: if(FIFO2_data_available) state <= 1'b1;	// wait for data
	1'b1: state <= 1'b0;							// read data, go back waiting
endcase

assign FIFO_RD = state;			// read when state=1'b1
assign FIFO_WR = 1'b0;			// never write
assign FIFO_PKTEND = 1'b0;
assign FIFO_DATAOUT = 8'h00;	// never write, this value is not used

reg [7:0] LCD_DB;
always @(posedge FIFO_CLK) if(FIFO_RD) LCD_DB <= FIFO_DATAIN;

reg DataAvailable;
always @(posedge FIFO_CLK) DataAvailable <= FIFO_RD;

wire Received_Escape = DataAvailable & (LCD_DB==0);
wire Received_Data = DataAvailable & (LCD_DB!=0);

// stretch the LCD accesses using a counter
reg [2:0] count;
always @(posedge FIFO_CLK) if(DataAvailable | (count!=0)) count <= count + 3'h1;

// activate LCD_E for 6 clocks, so at 24MHz, that's 6x41.6ns=250ns
reg LCD_E;
always @(posedge FIFO_CLK)
if(LCD_E==0)
  LCD_E <= Received_Data;
else
  LCD_E <= (count!=6);

reg LCD_instruction;
always @(posedge FIFO_CLK)
if(LCD_instruction==0)
  LCD_instruction <= Received_Escape;
else
  LCD_instruction <= (count!=7);

assign LCD_RS = ~LCD_instruction;
assign LCD_RW = 1'b0;	// always write to (and never read from) the LCD

endmodule
