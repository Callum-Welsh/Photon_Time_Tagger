// FlashyMini - Minimal Flashy design
// This is a minimal design: one channel only, no trigger, no frequency counter.
// (c) fpga4fun.com KNJN LLC - 2007 to 2017

// This design demonstrates how to acquire high-speed data from the Flashy board.
// We store the ADC data at high speed into a blockram, and we send it back to the PC at a lower speed.
// The design is very simple. As long as FIFO4 is not full, we trigger, acquire data, and feed the FIFO, 512 bytes at a time.

// Notes:
// This design uses "TaskAck_CrossDomain" available module, available from http://www.fpga4fun.com/CrossClockDomain.html
// With Xilinx FPGAs, we receive junk data at first, not sure why.

// A "FlashyMini.c" file is also provided to display the acquired data

// Define one of the following for Dragon-E or Xylo-E or Saxo-Q (for other boards, leave them commented out)
`define XILINX_E  // for Dragon-E or Xylo-E
//`define SAXO_Q

//////////////////////////////////////////////////
module FlashyMini(
	FX2_CLK, FX2_FD, FX2_SLRD, FX2_SLWR, FX2_flags, 
	FX2_PA_2, FX2_PA_3, FX2_PA_4, FX2_PA_5, FX2_PA_6, FX2_PA_7,

	//LED,
	clk_ADC, ADC_dataA, ADC_DACCTRL,

`ifdef SAXO_Q
	, clk_ADC_out
`endif
	);

input FX2_CLK;	// System clock (24MHz typical)
input clk_ADC;	// Flashy ADC clock (100MHz typical)

`ifdef SAXO_Q
output clk_ADC_out;
`endif

inout [7:0] FX2_FD;
input [2:0] FX2_flags;
output FX2_SLRD, FX2_SLWR;
output FX2_PA_2;
output FX2_PA_3;
output FX2_PA_4;
output FX2_PA_5;
output FX2_PA_6;
input FX2_PA_7;

input [7:0] ADC_dataA;
//input [7:0] ADC_dataB; // second ADC channel

output ADC_DACCTRL;
//output LED;

wire clk = FX2_CLK;
wire clk_acq = clk_ADC;
//wire clk_acq = FX2_CLK;

`ifdef SAXO_Q
assign clk_ADC_out = clk_ADC;
`endif

////////////////////////////////////////////////////////////////////////////////
// Rename "FX2" ports into "FIFO" ports, to give them more meaningful names
// FX2 USB signals are active low, take care of them now
// Note: You probably don't need to change anything in this section

// FX2 outputs
wire FIFO2_empty = ~FX2_flags[0];	wire FIFO2_data_available = ~FIFO2_empty;
wire FIFO3_empty = ~FX2_flags[1];	wire FIFO3_data_available = ~FIFO3_empty;
wire FIFO4_full = ~FX2_flags[2];	wire FIFO4_ready_to_accept_data = ~FIFO4_full;
wire FIFO5_full = ~FX2_PA_7;		wire FIFO5_ready_to_accept_data = ~FIFO5_full;
assign FX2_PA_3 = 1'b1;

// FX2 inputs
wire FIFO_RD, FIFO_WR, FIFO_PKTEND, FIFO_DATAIN_OE, FIFO_DATAOUT_OE;
wire FX2_SLRD = ~FIFO_RD;
wire FX2_SLWR = ~FIFO_WR;
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

assign FIFO_FIFOADR = 2'b10;	// select FIFO4
assign FIFO_RD = 1'b0;			// never read
assign FIFO_DATAIN_OE = 1'b0;			// never read data
assign FIFO_DATAOUT_OE = 1'b1;			// always output data
assign FIFO_PKTEND = 1'b0;

////////////////////////////////////////////////////////////////////////////////
wire StartAcquisition;
wire AcquisitionCompleted;
wire dataout_lastbyte;

reg [1:0] state = 2'b00;
// 00 waiting for FIFO4 to be not full
// 01 acquisition in progress
// 10 sending data to FIFO4
// 11 flushing data pipe to FIFO4

always @(posedge clk)
case(state)
	2'b00: if(StartAcquisition) state<=2'b01;
	2'b01: if(AcquisitionCompleted) state<=2'b10;
	2'b10: if(dataout_lastbyte) state<=2'b11;
	2'b11: if(~FIFO_WR) state<=2'b00;
endcase

// we start acquisition when FIFO4 has space
assign StartAcquisition = FIFO4_ready_to_accept_data & (state==2'b00);

wire Acquiring;
reg [8:0] wraddress;
wire DoneAcquiring = &wraddress;

// start the aquisition in the clk_acq clock domain
TaskAck_CrossDomain TaskAck_AcquireADC(
	.clkA(clk), .TaskStart_clkA(StartAcquisition), .TaskBusy_clkA(), .TaskDone_clkA(AcquisitionCompleted), 
	.clkB(clk_acq), .TaskStart_clkB(), .TaskBusy_clkB(Acquiring), .TaskDone_clkB(DoneAcquiring));

always @(posedge clk_acq) if(Acquiring) wraddress <= wraddress + 9'h1;
reg [8:0] rdaddress;
reg [7:0] ADC_dataA_reg;  always @(posedge clk_acq) ADC_dataA_reg <= ADC_dataA;

// store the acquired data in a blockram
`ifdef XILINX_E
RAM_8x1024_reg ADC_RAM(
	.wr_clk(clk_acq), .data_in(ADC_dataA_reg), .wr_adr(wraddress), .wr_en(Acquiring), 
	.rd_clk(clk), .data_out(FIFO_DATAOUT), .rd_adr(rdaddress), .rd_en(1'b1));
`else
RAM_8x512_reg ADC_RAM(
	.wr_clk(clk_acq), .data_in(ADC_dataA_reg), .wr_adr(wraddress), .wr_en(Acquiring), 
	.rd_clk(clk), .data_out(FIFO_DATAOUT), .rd_adr(rdaddress), .rd_en(1'b1));
`endif

// send back the data to the PC
wire dataout_onebyte = (state==2'b10);
assign dataout_lastbyte = &rdaddress;
always @(posedge clk) if(dataout_onebyte) rdaddress <= rdaddress + 9'h1;

// blockram used has two clock latencies on reads, so delay FIFO_WR by two clocks
reg [1:0] RAMout_pipe; always @(posedge clk) RAMout_pipe <= {RAMout_pipe[0], dataout_onebyte};
assign FIFO_WR = RAMout_pipe[1];

// Minimal ADC DAC-control logic
// Required with some revisions of Flashy that don't work if the DAC is not set to a minimum value
// See the Flashy documentation for more details
wire [7:0] DAC_regdata[3:0];
assign DAC_regdata[0] = 8'b11000000;  // minimum V-range
//assign DAC_regdata[0] = 8'b11111111;  // maximum V-range
assign DAC_regdata[1] = 8'b10000000;  // maximum V-pos
//assign DAC_regdata[1] = 8'b11111111;  // minimum V-pos
assign DAC_regdata[2] = 8'b11000000;
assign DAC_regdata[3] = 8'b10000000;
parameter psdac = 9;
reg [psdac+9:0] DAC_cnt;  always @(posedge clk) DAC_cnt <= DAC_cnt + 1;
wire [15:0] DAC_data = {5'b11111, DAC_cnt[psdac+9:psdac+8], 1'b1, DAC_regdata[DAC_cnt[psdac+9:psdac+8]]};
reg ADC_DACCTRL; always @(posedge clk) ADC_DACCTRL <= &DAC_cnt[psdac+7:psdac+5] & (&DAC_cnt[psdac:psdac-7] ? ~DAC_cnt[psdac-8] : DAC_data[~DAC_cnt[psdac+4:psdac+1]]);

///////////////////////////////////
// invert the LED at each acquisition (otherwise the transfer is too fast to see the LED...)
//reg LED; always @(posedge clk) if(AcquisitionCompleted) LED <= ~LED; 

endmodule
