// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module my_wide_fifo (
	clock,
	data,
	rdreq,
	wrreq,
	empty,
	full,
	q);

	input	  clock;
	input	[511:0]  data;
	input	  rdreq;
	input	  wrreq;
	output	  empty;
	output	  full;
	output	[511:0]  q;

	scfifo	scfifo_component (
				.rdreq (rdreq),
				.clock (clock),
				.wrreq (wrreq),
				.data (data),
				.empty (empty),
				.q (q),
				.full (full)
				// synopsys translate_off
				,
				.aclr (),
				.almost_empty (),
				.almost_full (),
				.sclr (),
				.usedw ()
				// synopsys translate_on
				);
	defparam
		scfifo_component.add_ram_output_register = "ON",
		scfifo_component.intended_device_family = "Cyclone II",
		scfifo_component.lpm_numwords = 2,
		scfifo_component.lpm_showahead = "ON",
		scfifo_component.lpm_type = "scfifo",
		scfifo_component.lpm_width = 512,
		scfifo_component.lpm_widthu = 1,
		scfifo_component.overflow_checking = "ON",
		scfifo_component.underflow_checking = "ON",
		scfifo_component.use_eab = "ON";


endmodule