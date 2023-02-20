////////////////////////////////////////////////////////////////////////
// module RAM_8x512_reg
// Dual-port RAM, 8 bits wide, 512 bytes deep, Altera style
// Two clock latencies on reads

module RAM_8x512_reg(
	input wr_clk,
	input [8:0] wr_adr,
	input [7:0] data_in,
	input wr_en,

	input rd_clk,
	input [8:0] rd_adr,
	output reg [7:0] data_out,
	input rd_en
);

lpm_ram_dp RAM(
	.wraddress(wr_adr), .data(data_in), .wrclock(wr_clk), .wren(wr_en), 
	.rdaddress(rd_adr), .q  (data_out), .rdclock(rd_clk), .rdclken(rd_en)//.rden(rd_en)
);
defparam
	RAM.lpm_width = 8,
	RAM.lpm_widthad = 9,
	RAM.rd_en_used = "TRUE",
	RAM.lpm_indata = "REGISTERED",
	RAM.lpm_wraddress_control = "REGISTERED",
	RAM.lpm_rdaddress_control = "REGISTERED",
	RAM.lpm_outdata = "REGISTERED",
	RAM.use_eab = "ON";

endmodule
