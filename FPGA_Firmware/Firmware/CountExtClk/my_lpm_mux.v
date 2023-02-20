// Fast Multisource Pulse Registration System
// Module:
// my_lpm_mux
// (c) Sergey V. Polyakov 2006-forever
// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on

module my_lpm_mux (
 datain, sel, result
);

input	[511:0]  datain;
input	[5:0]  sel;
output	[7:0]  result;

wire	[7:0]  result;

	lpm_mux	lpm_mux_component (
				.sel (sel),
				.data (datain),
				.result (result)
				// synopsys translate_off
				,
				.aclr (),
				.clken (),
				.clock ()
				// synopsys translate_on
				);
	defparam
		lpm_mux_component.lpm_size = 64,
		lpm_mux_component.lpm_type = "LPM_MUX",
		lpm_mux_component.lpm_width = 8,
		lpm_mux_component.lpm_widths = 6;
		
endmodule