// Sample code for FX2 USB-2 interface
// (c) fpga4fun.com KNJN LLC - 2006 to 2017

// Example on how to drive the SDRAM from USB-2
// The SDRAM is used in AUTO-PRECHARGE mode with read burst length=2 and CAS latency=2

module SDRAM_16MB(
	FX2_CLK, FX2_FD, FX2_SLRD, FX2_SLWR, FX2_flags, 
	FX2_PA_2, FX2_PA_3, FX2_PA_4, FX2_PA_5, FX2_PA_6, FX2_PA_7,

	SDRAM_CLK,
	SDRAM_CKE,
	SDRAM_WEn, SDRAM_CASn, SDRAM_RASn,
	SDRAM_DQM, 
	SDRAM_BA,
	SDRAM_A,
	SDRAM_DQ
);

input FX2_CLK;
inout [7:0] FX2_FD;
input [2:0] FX2_flags;
output FX2_SLRD, FX2_SLWR;

output FX2_PA_2;
output FX2_PA_3;
output FX2_PA_4;
output FX2_PA_5;
output FX2_PA_6;
input FX2_PA_7;

wire clk = FX2_CLK;
output SDRAM_CLK, SDRAM_CKE, SDRAM_WEn, SDRAM_CASn, SDRAM_RASn;
output SDRAM_BA;
output [1:0] SDRAM_DQM;
output [10:0] SDRAM_A;
inout [15:0] SDRAM_DQ;

////////////////////////////////////////////////////////////////////////////////
// Rename "FX2" ports into "FIFO" ports, to give them more meaningful names
// FX2 USB signals are active low, take care of them now
// Note: You probably don't need to change anything in this section

// FX2 outputs
wire FIFO2_empty = ~FX2_flags[0];	wire FIFO2_data_available = ~FIFO2_empty;
//wire FIFO3_empty = ~FX2_flags[1];	wire FIFO3_data_available = ~FIFO3_empty;
//wire FIFO4_full = ~FX2_flags[2];	wire FIFO4_ready_to_accept_data = ~FIFO4_full;
//wire FIFO5_full = ~FX2_PA_7;		wire FIFO5_ready_to_accept_data = ~FIFO5_full;
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
////////////////////////////////////////////////////////////
reg mem_done;

reg [2:0] FX2_state;
always @(posedge clk)
case(FX2_state)
	3'b000: if( FIFO2_data_available) FX2_state <= 3'b001;  // wait for data packet in FIFO2
	3'b001: if(~FIFO2_data_available) FX2_state <= 3'b100;  // wait until end of data packet
	3'b100: if(mem_done) FX2_state <= 3'b101;  // turnaround cycle, switch to FIFO4
	3'b101: FX2_state <= 3'b110;  // write data to FIFO4
	3'b110: FX2_state <= 3'b111;  // write data to FIFO4
	3'b111: FX2_state <= 3'b000;
	default: FX2_state <= 3'b000;
endcase

assign FIFO_FIFOADR = {FX2_state[2], 1'b0};  // FIFO2 or FIFO4
assign FIFO_RD = (FX2_state==3'b001);

// now write the count back
//assign FIFO_DATAOUT = cnt;
assign FIFO_WR = (FX2_state==3'b101) | (FX2_state==3'b110);
assign FIFO_PKTEND = (FX2_state==3'b111);
assign FIFO_DATAIN_OE = ~FX2_state[2];
assign FIFO_DATAOUT_OE = FIFO_WR;

// count the number of bytes received
wire read_byte = (FX2_state==3'b001) & FIFO2_data_available;
reg [2:0] RxD_addr_reg;
always @(posedge clk) if(read_byte) RxD_addr_reg<=RxD_addr_reg+3'h1; else RxD_addr_reg<=3'h0;

reg [7:0] DataIn [7:0];
always @(posedge clk) if(read_byte) DataIn[RxD_addr_reg] <= FIFO_DATAIN;

//assign FIFO_DATAOUT = DataIn[FX2_state[2:0]];

////////////////////////////////////////////////////////////////////////////////
wire [23:0] mem_addr = {DataIn[2],DataIn[1],DataIn[0]};
wire [15:0] mem_datain = {DataIn[5],DataIn[4]};
wire [15:0] mem_dataout;

wire mem_do = &RxD_addr_reg;
wire mem_rdwr = DataIn[6][0];
wire mem_cmd = DataIn[6][1];

assign FIFO_DATAOUT = FX2_state[0] ? mem_dataout[7:0] : mem_dataout[15:8];

////////////////////////////////////////////////////////////////////////////////
assign SDRAM_CLK = clk;
assign SDRAM_CKE = 1'b1;

wire [2:0] SDRAM_CMD_LOADMODE  = 3'b000;
wire [2:0] SDRAM_CMD_REFRESH   = 3'b001;
wire [2:0] SDRAM_CMD_PRECHARGE = 3'b010;
wire [2:0] SDRAM_CMD_ACTIVE    = 3'b011;
wire [2:0] SDRAM_CMD_WRITE     = 3'b100;
wire [2:0] SDRAM_CMD_READ      = 3'b101;
//wire [2:0] SDRAM_CMD_TERMINATE = 3'b110;
wire [2:0] SDRAM_CMD_NOP       = 3'b111;

reg [2:0] SDRAM_CMD;
assign {SDRAM_RASn, SDRAM_CASn, SDRAM_WEn} = SDRAM_CMD;
reg SDRAM_BA;
reg [1:0] SDRAM_DQM;
reg [10:0] SDRAM_A;
reg SDRAM_DQ_oe;
reg [15:0] SDRAM_DQ_out;
reg [15:0] SDRAM_DQ_in;

reg [3:0] SDRAM_state;
wire SDRAM_state0 = (SDRAM_state==4'b0000);
wire SDRAM_state_write = (SDRAM_state==4'b0010);
wire SDRAM_state_read  = (SDRAM_state==4'b1001);
wire SDRAM_state_read_done = (SDRAM_state==4'b1100);

reg [7:0] refresh_counter;
reg refresh_now;
always @(posedge clk) refresh_counter<=refresh_counter+8'h1;
always @(posedge clk) refresh_now <= (refresh_now ? ~SDRAM_state0 : &refresh_counter);

reg mem_do_now;
always @(posedge clk) mem_do_now <= (mem_do_now ? ~(SDRAM_state0 & ~refresh_now) : mem_do);

always @(posedge clk)
case(SDRAM_state)
	4'b0000: begin 
		if(refresh_now)
		begin
			SDRAM_CMD <= SDRAM_CMD_REFRESH;
			SDRAM_state <= 4'b1101;
		end
		else
		if(mem_do_now & mem_cmd & ~mem_addr[0])
		begin
			SDRAM_CMD <= SDRAM_CMD_PRECHARGE;  // A18 high for all banks precharge
			SDRAM_state <= 4'b1100;
		end
		else
		if(mem_do_now & mem_cmd & mem_addr[0])
		begin
			SDRAM_CMD <= SDRAM_CMD_LOADMODE;  // A[18:8]
			SDRAM_state <= 4'b1100;
		end
		else
		if(mem_do_now & ~mem_cmd)
		begin
			SDRAM_CMD <= SDRAM_CMD_ACTIVE;
			SDRAM_state <= (mem_rdwr ? 4'b1000 : 4'b0001);
		end
		else
		begin
			SDRAM_CMD <= SDRAM_CMD_NOP;
			SDRAM_state <= 4'b0000;
		end
	end

	// write
	4'b0001: begin
		SDRAM_CMD <= SDRAM_CMD_NOP;
		SDRAM_state <= 4'b0010;
	end
	4'b0010: begin
		SDRAM_CMD <= SDRAM_CMD_WRITE;
		SDRAM_state <= 4'b0011;
	end
	4'b0011: begin
		SDRAM_CMD <= SDRAM_CMD_NOP;
		SDRAM_state <= 4'b0100;
	end
	4'b0100: begin
		SDRAM_CMD <= SDRAM_CMD_NOP;
		SDRAM_state <= 4'b0000;
	end

	// read
	4'b1000: begin
		SDRAM_CMD <= SDRAM_CMD_NOP;
		SDRAM_state <= 4'b1001;
	end
	4'b1001: begin
		SDRAM_CMD <= SDRAM_CMD_READ;
		SDRAM_state <= 4'b1010;
	end
	4'b1010: begin
		SDRAM_CMD <= SDRAM_CMD_NOP;
		SDRAM_state <= 4'b1011;
	end
	4'b1011: begin
		SDRAM_CMD <= SDRAM_CMD_NOP;
		SDRAM_state <= 4'b1100;
	end
	4'b1100: begin
		SDRAM_CMD <= SDRAM_CMD_NOP;
		SDRAM_state <= 4'b0000;
	end

	// auto-refresh
	4'b1101: begin
		SDRAM_CMD <= SDRAM_CMD_NOP;
		SDRAM_state <= 4'b1110;
	end
	4'b1110: begin
		SDRAM_CMD <= SDRAM_CMD_NOP;
		SDRAM_state <= 4'b1111;
	end
	4'b1111: begin
		SDRAM_CMD <= SDRAM_CMD_NOP;
		SDRAM_state <= 4'b0000;
	end

	default: begin
		SDRAM_CMD <= SDRAM_CMD_NOP;
		SDRAM_state <= 4'b0000;
	end
endcase

always @(posedge clk)
begin
		if(SDRAM_state0) SDRAM_BA <= mem_addr[19];
		SDRAM_A <= (SDRAM_state0 ? mem_addr[18:8] : {3'b100, mem_addr[7:0]});  // precharge
		SDRAM_DQM <= ((SDRAM_state_read | SDRAM_state_write) ? 2'b00 : 2'b11);
		SDRAM_DQ_oe <= SDRAM_state_write;
		SDRAM_DQ_out <= mem_datain;
		mem_done <= SDRAM_state_write | SDRAM_state_read_done;
		if(SDRAM_state_read_done) SDRAM_DQ_in <= SDRAM_DQ;
end

assign SDRAM_DQ = (SDRAM_DQ_oe ? SDRAM_DQ_out : 16'hZZZZ);
assign mem_dataout = SDRAM_DQ_in;
endmodule