// Ethernet 10BASE-T demo code
// (c) fpga4fun.com KNJN LLC - 2004 to 2015
// This design is provided "as is" and without any warranties expressed or implied including but not
// limited to implied warranties of merchantability and fitness for a particular purpose. 
// In no event should the author be liable for any damages whatsoever (including without limitation, 
// damages for loss of business profits, business interruption, loss of business information,
// or any other pecuniary loss) arising out of the use or inability to use this product.

// This design provides an example of UDP/IP transmission and reception.
// * Reception: every time a UDP packet is received, the FPGA checks the packet validity and
//   updates some LEDs (the first bits of the UDP payload are used).
// * Transmission: a packet is sent at regular interval (about every 2 seconds)
//   We send what was received earlier, plus a received packet count.
// This designs uses 1 or 2 clocks
// CLK40 or CLK20: 40MHz or 20MHz
// CLK_USB: 24MHz


// Make sure to set the defines and update all parameters used below

// Uncomment one of the following:
//`define DRAGON
//`define XYLO_E
//`define XYLO_L
//`define XYLO	// Xylo or Xylo-EM

`ifdef DRAGON
`define XILINX		// generate CLK20 from CLK40/2
`define TDm
`endif

`ifdef XYLO_E
`define XILINX		// generate CLK20 from CLK24+DCM
`endif

`ifdef XYLO_L
`define XILINX		// generate CLK20 from CLK24+DCM
`define TDm
`endif

`ifdef XYLO
`define ALTERA		// generate CLK20 from a CLK24+PLL
`define TDm
`endif


/////////////////////////////////////////////////////////////////////////////////////////////////////
module TENBASET(
	input CLK_USB, 
	input Ethernet_RDp,
	output reg Ethernet_TDp, 
	`ifdef TDm output reg Ethernet_TDm, `endif
	`ifdef DRAGON input CLK40, USB_FRDn, inout [7:0] USB_D, `endif
	output reg [1:0] LED
);

// "IP destination" - put the IP of the PC you want to send to
parameter toIP_1 = 8'd192;
parameter toIP_2 = 8'd168;
parameter toIP_3 = 8'd1;
parameter toIP_4 = 8'd100;

// "Physical Address" - put the address of the PC you want send to
parameter toPA = 48'h_BC_5F_F4_3A_72_A9;  // MAC address BC-5F-F4-3A-72-A9

// "myIP" - IP of the FPGA
// Make sure this IP is accessible and not already used on your network
// In doubt, choose an IP which has the same 3 first numbers than other devices on your network, changing the fourth number 
//  with a random number between 1 and 254. Then �Ping� the new IP to make sure it is not in use.
parameter myIP_1 = 8'd192;
parameter myIP_2 = 8'd168;
parameter myIP_3 = 8'd1;
parameter myIP_4 = 8'd17;

// "myPA" - physical address of the FPGA
// It should be unique on your network
// A random number should be fine, since the odds of choosing something already existing on your network are really small
parameter myPA = 48'h_00_12_34_56_78_90;  // MAC address 00-12-34-56-78-90

//////////////////////////////////////////////////////////////////////
// Tx section

// Put here the number of bytes transmitted in the UDP payload
// 18 minimum (smaller UDP payloads are possible but would need to be padded)
// 1472 maximum (1500 bytes = max Ethernet payload - 28 bytes = IP/UDP headers length)
parameter Tx_UDPpayloadlength = 18;

wire clkRx = CLK_USB;  // should be 24MHz
wire clkTx;  // should be 20MHz

`ifdef XILINX
	`ifdef DRAGON	// generate the CLK20 from an external 40MHz oscillator
		reg clk20; always @(posedge CLK40) clk20 <= ~clk20;  // get 20MHz by dividing a 40MHz clock by 2
		BUFG BUFG_clkTx(.O(clkTx), .I(clk20));
	`else
		// generate the CLK20 using the DCM
		DCM_SP #(
			.CLKFX_MULTIPLY(5), // Can be any integer from 2 to 32
			.CLKFX_DIVIDE(6),   // Can be any integer from 1 to 32
			.CLKIN_PERIOD(41.666),  // 24MHz input clock

			.CLKDV_DIVIDE(2.0), // Divide by: 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5,7.0,7.5,8.0,9.0,10.0,11.0,12.0,13.0,14.0,15.0 or 16.0
			.CLKIN_DIVIDE_BY_2("FALSE"), // TRUE/FALSE to enable CLKIN divide by two feature
			.CLKOUT_PHASE_SHIFT("NONE"), // Specify phase shift of NONE, FIXED or VARIABLE
			.CLK_FEEDBACK("1X"),  // Specify clock feedback of NONE, 1X or 2X
			.DESKEW_ADJUST("SYSTEM_SYNCHRONOUS"), // SOURCE_SYNCHRONOUS, SYSTEM_SYNCHRONOUS or an integer from 0 to 15
			.DFS_FREQUENCY_MODE("LOW"),  // HIGH or LOW frequency mode for frequency synthesis
			.DLL_FREQUENCY_MODE("LOW"),  // HIGH or LOW frequency mode for DLL
			.DUTY_CYCLE_CORRECTION("TRUE"), // Duty cycle correction, TRUE or FALSE
			.FACTORY_JF(16'hC080),   // FACTORY JF values
			.PHASE_SHIFT(0),     // Amount of fixed phase shift from -255 to 255
			.STARTUP_WAIT("FALSE")   // Delay configuration DONE until DCM LOCK, TRUE/FALSE
		) DCM_CLK20 (
			.CLKFX(clkTx),   // DCM CLK synthesis out (M/D)
			//.CLK0(CLK0),     // 0 degree DCM CLK output
			//.CLK180(CLK180), // 180 degree DCM CLK output
			//.CLK270(CLK270), // 270 degree DCM CLK output
			//.CLK2X(CLK2X),   // 2X DCM CLK output
			//.CLK2X180(CLK2X180), // 2X, 180 degree DCM CLK out
			//.CLK90(CLK90),   // 90 degree DCM CLK output
			//.CLKDV(CLKDV),   // Divided DCM CLK out (CLKDV_DIVIDE)
			//.CLKFX180(CLKFX180), // 180 degree CLK synthesis out
			//.LOCKED(LOCKED), // DCM LOCK status output
			//.PSDONE(PSDONE), // Dynamic phase adjust done output
			//.STATUS(STATUS), // 8-bit DCM status bits output
			//.CLKFB(CLKFB),   // DCM clock feedback
	
			.CLKIN(CLK_USB),   // Clock input (from IBUFG, BUFG or DCM)
			.PSCLK(1'b0),   // Dynamic phase adjust clock input
			.PSEN(1'b0),     // Dynamic phase adjust enable input
			.PSINCDEC(1'b0), // Dynamic phase adjust increment/decrement
			.RST(1'b0)        // DCM asynchronous reset input
		);
	`endif
`endif
`ifdef ALTERA
	PLL20 PLLclk20(.inclk0(CLK_USB), .c0(clkTx));  // get 20MHz with a PLL
`endif

//////////////////////////////////////////////////////////////////////
// A few declarations used later
reg [13:0] RxBitCount;  // 14 bits are enough for a complete Ethernet frame (1500 bytes = 12000 bits)
wire [13:0] RxBitCount_MinUPDlen = (42+18+4)*8;  // smallest UDP packet has 42 bytes (header) + 18 bytes (payload) + 4 bytes (CRC)
reg [7:0] RxDataByteIn;
wire RxNewByteAvailable;
reg RxGoodPacket;
reg RxPacketReceivedOK;
reg [31:0] RxPacketCount;  always @(posedge clkRx) if(RxPacketReceivedOK) RxPacketCount <= RxPacketCount + 1;
reg [10:0] TxAddress;
wire [7:0] TxData;

// 512 bytes RAM, big enough to store a UPD header (42 bytes) and up to 470 bytes of UDP payload
// The RAM is also used to provide data to transmit
ram8x512 RAM_RxTx(
	.wr_clk(clkRx), .wr_adr(RxBitCount[11:3]), .data_in(RxDataByteIn), .wr_en(RxGoodPacket & RxNewByteAvailable & ~|RxBitCount[13:12]), 
	.rd_clk(clkTx), .rd_adr(TxAddress[8:0]), .data_out(TxData), .rd_en(1'b1));

//////////////////////////////////////////////////////////////////////
// Tx section

// Send a UDP packet roughly every second
reg [23:0] counter; always @(posedge clkTx) counter<=counter+24'h1;
reg StartSending; always @(posedge clkTx) StartSending<=&counter;

// calculate the IP checksum, big-endian style
wire [31:0] IPchecksum1 = 32'h0000C52D + Tx_UDPpayloadlength + 
						(myIP_1<<8)+myIP_2+(myIP_3<<8)+myIP_4+
						(toIP_1<<8)+toIP_2+(toIP_3<<8)+(toIP_4);
wire [31:0] IPchecksum2 = ((IPchecksum1&32'h0000FFFF)+(IPchecksum1>>16));
wire [15:0] IPchecksum = ~((IPchecksum2&32'h0000FFFF)+(IPchecksum2>>16));

wire [15:0] IP_length = 16'h001C + Tx_UDPpayloadlength;
wire [15:0] UDP_length = 16'h0008 + Tx_UDPpayloadlength;

reg [7:0] pkt_data;
always @(posedge clkTx) 
case(TxAddress)
// Ethernet preamble
  11'h7F8: pkt_data <= 8'h55;
  11'h7F9: pkt_data <= 8'h55;
  11'h7FA: pkt_data <= 8'h55;
  11'h7FB: pkt_data <= 8'h55;
  11'h7FC: pkt_data <= 8'h55;
  11'h7FD: pkt_data <= 8'h55;
  11'h7FE: pkt_data <= 8'h55;
  11'h7FF: pkt_data <= 8'hD5;
// Ethernet header
  11'h000: pkt_data <= toPA[47:40];
  11'h001: pkt_data <= toPA[39:32];
  11'h002: pkt_data <= toPA[31:24];
  11'h003: pkt_data <= toPA[23:16];
  11'h004: pkt_data <= toPA[15:8];
  11'h005: pkt_data <= toPA[7:0];
  11'h006: pkt_data <= myPA[47:40];
  11'h007: pkt_data <= myPA[39:32];
  11'h008: pkt_data <= myPA[31:24];
  11'h009: pkt_data <= myPA[23:16];
  11'h00A: pkt_data <= myPA[15:8];
  11'h00B: pkt_data <= myPA[7:0];
// Ethernet type
  11'h00C: pkt_data <= 8'h08;  // IP protocol = 0x08
  11'h00D: pkt_data <= 8'h00;
// IP header
  11'h00E: pkt_data <= 8'h45;  // IP type
  11'h00F: pkt_data <= 8'h00;
  11'h010: pkt_data <= IP_length[15:8];
  11'h011: pkt_data <= IP_length[ 7:0];
  11'h012: pkt_data <= 8'h00;
  11'h013: pkt_data <= 8'h00;
  11'h014: pkt_data <= 8'h00;
  11'h015: pkt_data <= 8'h00;
  11'h016: pkt_data <= 8'h80;  // time to live
  11'h017: pkt_data <= 8'h11;  // UDP = 0x11
  11'h018: pkt_data <= IPchecksum[15:8];
  11'h019: pkt_data <= IPchecksum[ 7:0];
  11'h01A: pkt_data <= myIP_1;
  11'h01B: pkt_data <= myIP_2;
  11'h01C: pkt_data <= myIP_3;
  11'h01D: pkt_data <= myIP_4;
  11'h01E: pkt_data <= toIP_1;
  11'h01F: pkt_data <= toIP_2;
  11'h020: pkt_data <= toIP_3;
  11'h021: pkt_data <= toIP_4;
// UDP header
  11'h022: pkt_data <= 8'h04;
  11'h023: pkt_data <= 8'h00;
  11'h024: pkt_data <= 8'h04;
  11'h025: pkt_data <= 8'h00;
  11'h026: pkt_data <= UDP_length[15:8];
  11'h027: pkt_data <= UDP_length[ 7:0];
  11'h028: pkt_data <= 8'h00;
  11'h029: pkt_data <= 8'h00;

// Payload
// We send what we last received (stored in the blockram)
// with last two bytes sent = the number of received packets
  11'h028+Tx_UDPpayloadlength: pkt_data <= RxPacketCount[15:8];
  11'h029+Tx_UDPpayloadlength: pkt_data <= RxPacketCount[ 7:0];
// remainder of payload comes from the blockram
  default: pkt_data <= TxData;  // from blockram
endcase

// The 10BASE-T's magic
wire [10:0] TxAddress_StartPayload = 11'h02A;
wire [10:0] TxAddress_EndPayload = TxAddress_StartPayload + Tx_UDPpayloadlength;
wire [10:0] TxAddress_EndPacket = TxAddress_EndPayload + 11'h004;  // 4 bytes for CRC

reg [3:0] ShiftCount;
reg SendingPacket;
always @(posedge clkTx) if(StartSending) SendingPacket<=1'h1; else if(ShiftCount==4'd14 && TxAddress==TxAddress_EndPacket) SendingPacket<=1'b0;
always @(posedge clkTx) ShiftCount <= (SendingPacket ? ShiftCount+4'd1 : 4'd15);
wire readram = (ShiftCount==15);
always @(posedge clkTx) if(ShiftCount==15) TxAddress <= (SendingPacket ? TxAddress+11'h01 : 11'h7F8);
reg [7:0] ShiftData; always @(posedge clkTx) if(ShiftCount[0]) ShiftData <= (readram ? pkt_data : {1'b0, ShiftData[7:1]});

// CRC32
reg [31:0] CRC;
reg CRCflush; always @(posedge clkTx) if(CRCflush) CRCflush <= SendingPacket; else if(readram) CRCflush <= (TxAddress==TxAddress_EndPayload);
reg CRCinit; always @(posedge clkTx) if(readram) CRCinit <= (TxAddress==11'h7FF);
wire CRCinput = (CRCflush ? 1'b0 : (ShiftData[0] ^ CRC[31]));
always @(posedge clkTx) if(ShiftCount[0]) CRC <= (CRCinit ? ~0 : ({CRC[30:0],1'b0} ^ ({32{CRCinput}} & 32'h04C11DB7)));

// NLP
reg [16:0] LinkPulseCount; always @(posedge clkTx) LinkPulseCount <= (SendingPacket ? 17'h0 : LinkPulseCount+17'h1);
reg LinkPulse; always @(posedge clkTx) LinkPulse <= &LinkPulseCount[16:1];

// TP_IDL, shift-register and manchester encoder
reg SendingPacketData; always @(posedge clkTx) SendingPacketData <= SendingPacket;
reg [2:0] idlecount; always @(posedge clkTx) if(SendingPacketData) idlecount<=3'h0; else if(~&idlecount) idlecount<=idlecount+3'h1;
wire dataout = (CRCflush ? ~CRC[31] : ShiftData[0]);
reg qo; always @(posedge clkTx) qo <= (SendingPacketData ? ~dataout^ShiftCount[0] : 1'h1);
reg qoe; always @(posedge clkTx) qoe <= SendingPacketData | LinkPulse | (idlecount<6);
`ifdef TDm 
always @(posedge clkTx) Ethernet_TDp <= (qoe ?  qo : 1'b0);
always @(posedge clkTx) Ethernet_TDm <= (qoe ? ~qo : 1'b0);
`else
always @(posedge clkTx) Ethernet_TDp <= (qoe ?  qo : 1'bZ);
`endif

//////////////////////////////////////////////////////////////////////
// Rx section

// Adapt reception automatically to the polarity of the received Manchester signal
reg RxDataPolarity;

// Bit synchronization
reg [2:0] RxInSRp; always @(posedge clkRx) RxInSRp <= {RxInSRp[1:0], Ethernet_RDp ^ RxDataPolarity};
reg [2:0] RxInSRn; always @(negedge clkRx) RxInSRn <= {RxInSRn[1:0], Ethernet_RDp ^ RxDataPolarity};

wire RxInTransition1 = RxInSRp[2] ^ RxInSRn[2];
wire RxInTransition2 = RxInSRn[2] ^ RxInSRp[1];

reg [1:0] RxTransitionCount;
always @(posedge clkRx)
//	if(|RxTransitionCount | RxInTransition1) RxTransitionCount  = RxTransitionCount + 1;
//	if(|RxTransitionCount | RxInTransition2) RxTransitionCount <= RxTransitionCount + 1;
if((RxTransitionCount==0 & RxInTransition1) | RxTransitionCount==1 | RxTransitionCount==2 | (RxTransitionCount==3 & RxInTransition2))
	RxTransitionCount <= RxTransitionCount + 2'h2;
else
if(RxTransitionCount==3 | RxInTransition2)
	RxTransitionCount <= RxTransitionCount + 2'h1;

reg RxNewBitAvailable;
always @(posedge clkRx)
	RxNewBitAvailable <= (RxTransitionCount==2) | (RxTransitionCount==3);

always @(posedge clkRx)
if(RxTransitionCount==2)
	RxDataByteIn <= {RxInSRp[1], RxDataByteIn[7:1]};
else
if(RxTransitionCount==3)
	RxDataByteIn <= {RxInSRn[2], RxDataByteIn[7:1]};

wire RxNewBit = RxDataByteIn[7];

// Rx Byte and Frame synchronizations
wire Rx_end_of_Ethernet_frame;

// First we get 31 preample bits
reg [4:0] RxPreambleBitsCount;
wire RxEnoughPreambleBitsReceived = &RxPreambleBitsCount;

always @(posedge clkRx)
if(Rx_end_of_Ethernet_frame)
	RxPreambleBitsCount <= 5'h0;
else 
if(RxNewBitAvailable) 
begin
	if(RxDataByteIn==8'h55 || RxDataByteIn==~8'h55)  // preamble pattern?
	begin
		if(~RxEnoughPreambleBitsReceived) RxPreambleBitsCount <= RxPreambleBitsCount + 5'h1;
	end
	else
		RxPreambleBitsCount <= 5'h0;
end

// then, we check for the SFD
reg RxFrame;
wire Rx_SFDdetected = RxEnoughPreambleBitsReceived & ~RxFrame & RxNewBitAvailable & (RxDataByteIn==8'hD5 | RxDataByteIn==~8'hD5);

// which marks the beginning of a frame
always @(posedge clkRx)
case(RxFrame)
	1'b0: RxFrame <=  Rx_SFDdetected;
	1'b1: RxFrame <= ~Rx_end_of_Ethernet_frame;
endcase

// so that we can count the incoming bits
always @(posedge clkRx)
if(RxFrame)
begin
	if(RxNewBitAvailable) RxBitCount <= RxBitCount + 14'h1;
end
else
	RxBitCount <= 14'h0;

// If no clock transition is detected for some time, that's the end of the frame
reg [2:0] RxTransitionTimeout;
always @(posedge clkRx) if(RxInTransition1 | RxInTransition2) RxTransitionTimeout<=3'h0; else if(~&RxTransitionCount) RxTransitionTimeout<=RxTransitionTimeout+3'h1;
assign Rx_end_of_Ethernet_frame = &RxTransitionTimeout;

// Invert the incoming data polarity if neccesary
always @(posedge clkRx)
if(Rx_SFDdetected)
	RxDataPolarity <= RxDataPolarity ^ RxDataByteIn[1];

assign RxNewByteAvailable = RxNewBitAvailable & RxFrame & &RxBitCount[2:0];

// Check the CRC32
reg [31:0] RxCRC; always @(posedge clkRx) if(RxNewBitAvailable) RxCRC <= (Rx_SFDdetected ? ~0 : ({RxCRC[30:0],1'b0} ^ ({32{RxNewBit ^ RxCRC[31]}} & 32'h04C11DB7)));
reg RxCRC_CheckNow; always @(posedge clkRx) RxCRC_CheckNow <= RxNewByteAvailable;
reg RxCRC_OK; always @(posedge clkRx) if(RxCRC_CheckNow) RxCRC_OK <= (RxCRC==32'hC704DD7B);

// Check the validity of the packet
always @(posedge clkRx)
if(~RxFrame)
	RxGoodPacket <= 1'h1;
else
if(RxNewByteAvailable)
case(RxBitCount[13:3])
	// verify that the packet MAC address matches our own
	11'h000: if(RxDataByteIn!=myPA[47:40]) RxGoodPacket <= 1'h0;
	11'h001: if(RxDataByteIn!=myPA[39:32]) RxGoodPacket <= 1'h0;
	11'h002: if(RxDataByteIn!=myPA[31:24]) RxGoodPacket <= 1'h0;
	11'h003: if(RxDataByteIn!=myPA[23:16]) RxGoodPacket <= 1'h0;
	11'h004: if(RxDataByteIn!=myPA[15: 8]) RxGoodPacket <= 1'h0;
	11'h005: if(RxDataByteIn!=myPA[ 7: 0]) RxGoodPacket <= 1'h0;
	// verify that's an IP/UDP packet
	11'h00C: if(RxDataByteIn!=8'h08 ) RxGoodPacket <= 1'h0;
	11'h00D: if(RxDataByteIn!=8'h00 ) RxGoodPacket <= 1'h0;
	11'h00E: if(RxDataByteIn!=8'h45 ) RxGoodPacket <= 1'h0;
	11'h017: if(RxDataByteIn!=8'h11 ) RxGoodPacket <= 1'h0;
	// verify that's the destination IP matches our IP
	11'h01E: if(RxDataByteIn!=myIP_1) RxGoodPacket <= 1'h0;
	11'h01F: if(RxDataByteIn!=myIP_2) RxGoodPacket <= 1'h0;
	11'h020: if(RxDataByteIn!=myIP_3) RxGoodPacket <= 1'h0;
	11'h021: if(RxDataByteIn!=myIP_4) RxGoodPacket <= 1'h0;
	default: ;
endcase

wire RxPacketLengthOK = (RxBitCount>=RxBitCount_MinUPDlen);
always @(posedge clkRx) RxPacketReceivedOK <= RxFrame & Rx_end_of_Ethernet_frame & RxCRC_OK & RxPacketLengthOK & RxGoodPacket;

/////////////////////////////////////////////////
reg [1:0] RxLED;	
always @(posedge clkRx) if(RxNewBitAvailable & RxBitCount==14'h150) RxLED[0] <= RxNewBit;	 // the payload starts at byte 0x2A (bit 0x150)
always @(posedge clkRx) if(RxNewBitAvailable & RxBitCount==14'h151) RxLED[1] <= RxNewBit;
always @(posedge clkRx) if(RxPacketReceivedOK) LED <= RxLED;

/////////////////////////////////////////////////
// On Dragon, we can also use USB to monitor the packet count
`ifdef DRAGON
reg [1:0] USB_readcnt;
always @(posedge CLK_USB) if(~USB_FRDn) USB_readcnt <= USB_readcnt + 1;
wire [7:0] USB_readmux = (USB_readcnt==0) ? RxPacketCount[7:0] : (USB_readcnt==1) ? RxPacketCount[15:8] : (USB_readcnt==2) ? RxPacketCount[23:16] : RxPacketCount[31:24];
assign USB_D = (~USB_FRDn ? USB_readmux : 8'hZZ);
`endif
endmodule



//////////////////////////////////////////////////////////////////////////////////////////////////
module ram8x512(
	wr_clk, wr_adr, data_in, wr_en, 
	rd_clk, rd_adr, data_out, rd_en
);
input	[8:0] wr_adr;
input	[7:0] data_in;
input	wr_clk;
input	wr_en;

input	[8:0] rd_adr;
output reg [7:0] data_out;
input	rd_clk;
input	rd_en;

reg [7:0] RAM [511:0];
always @(posedge wr_clk) if(wr_en) RAM[wr_adr] <= data_in;
always @(posedge rd_clk) if(rd_en) data_out <= RAM[rd_adr];
endmodule
