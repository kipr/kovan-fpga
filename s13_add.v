////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 1995-2012 Xilinx, Inc.  All rights reserved.
////////////////////////////////////////////////////////////////////////////////
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor: Xilinx
// \   \   \/     Version: P.28xd
//  \   \         Application: netgen
//  /   /         Filename: s13_add.v
// /___/   /\     Timestamp: Sat Dec 15 16:37:50 2012
// \   \  /  \ 
//  \___\/\___\
//             
// Command	: -w -sim -ofmt verilog /home/josh/got/kovan-fpga/tmp/_cg/s13_add.ngc /home/josh/got/kovan-fpga/tmp/_cg/s13_add.v 
// Device	: 6slx9csg324-2
// Input file	: /home/josh/got/kovan-fpga/tmp/_cg/s13_add.ngc
// Output file	: /home/josh/got/kovan-fpga/tmp/_cg/s13_add.v
// # of Modules	: 1
// Design Name	: s13_add
// Xilinx        : /opt/Xilinx/14.2/ISE_DS/ISE/
//             
// Purpose:    
//     This verilog netlist is a verification model and uses simulation 
//     primitives which may not represent the true implementation of the 
//     device, however the netlist is functionally correct and should not 
//     be modified. This file cannot be synthesized and should only be used 
//     with supported simulation tools.
//             
// Reference:  
//     Command Line Tools User Guide, Chapter 23 and Synthesis and Simulation Design Guide, Chapter 6
//             
////////////////////////////////////////////////////////////////////////////////

`timescale 1 ns/1 ps

module s13_add (
a, b, s
)/* synthesis syn_black_box syn_noprune=1 */;
  input [12 : 0] a;
  input [12 : 0] b;
  output [12 : 0] s;
  
  // synthesis translate_off
  
  wire sig00000001;
  wire sig00000002;
  wire sig00000003;
  wire sig00000004;
  wire sig00000005;
  wire sig00000006;
  wire sig00000007;
  wire sig00000008;
  wire sig00000009;
  wire sig0000000a;
  wire sig0000000b;
  wire sig0000000c;
  wire sig0000000d;
  wire sig0000000e;
  wire sig0000000f;
  wire sig00000010;
  wire sig00000011;
  wire sig00000012;
  wire sig00000013;
  wire sig00000014;
  wire sig00000015;
  wire sig00000016;
  wire sig00000017;
  wire sig00000018;
  wire sig00000019;
  wire sig0000001a;
  GND   blk00000001 (
    .G(sig00000001)
  );
  XORCY   blk00000002 (
    .CI(sig00000001),
    .LI(sig0000000e),
    .O(s[0])
  );
  XORCY   blk00000003 (
    .CI(sig0000000f),
    .LI(sig0000000d),
    .O(s[12])
  );
  XORCY   blk00000004 (
    .CI(sig00000010),
    .LI(sig00000002),
    .O(s[11])
  );
  XORCY   blk00000005 (
    .CI(sig00000011),
    .LI(sig00000003),
    .O(s[10])
  );
  XORCY   blk00000006 (
    .CI(sig00000012),
    .LI(sig00000004),
    .O(s[9])
  );
  XORCY   blk00000007 (
    .CI(sig00000013),
    .LI(sig00000005),
    .O(s[8])
  );
  XORCY   blk00000008 (
    .CI(sig00000014),
    .LI(sig00000006),
    .O(s[7])
  );
  XORCY   blk00000009 (
    .CI(sig00000015),
    .LI(sig00000007),
    .O(s[6])
  );
  XORCY   blk0000000a (
    .CI(sig00000016),
    .LI(sig00000008),
    .O(s[5])
  );
  XORCY   blk0000000b (
    .CI(sig00000017),
    .LI(sig00000009),
    .O(s[4])
  );
  XORCY   blk0000000c (
    .CI(sig00000018),
    .LI(sig0000000a),
    .O(s[3])
  );
  XORCY   blk0000000d (
    .CI(sig00000019),
    .LI(sig0000000b),
    .O(s[2])
  );
  XORCY   blk0000000e (
    .CI(sig0000001a),
    .LI(sig0000000c),
    .O(s[1])
  );
  MUXCY   blk0000000f (
    .CI(sig00000010),
    .DI(a[11]),
    .S(sig00000002),
    .O(sig0000000f)
  );
  MUXCY   blk00000010 (
    .CI(sig00000011),
    .DI(a[10]),
    .S(sig00000003),
    .O(sig00000010)
  );
  MUXCY   blk00000011 (
    .CI(sig00000012),
    .DI(a[9]),
    .S(sig00000004),
    .O(sig00000011)
  );
  MUXCY   blk00000012 (
    .CI(sig00000013),
    .DI(a[8]),
    .S(sig00000005),
    .O(sig00000012)
  );
  MUXCY   blk00000013 (
    .CI(sig00000014),
    .DI(a[7]),
    .S(sig00000006),
    .O(sig00000013)
  );
  MUXCY   blk00000014 (
    .CI(sig00000015),
    .DI(a[6]),
    .S(sig00000007),
    .O(sig00000014)
  );
  MUXCY   blk00000015 (
    .CI(sig00000016),
    .DI(a[5]),
    .S(sig00000008),
    .O(sig00000015)
  );
  MUXCY   blk00000016 (
    .CI(sig00000017),
    .DI(a[4]),
    .S(sig00000009),
    .O(sig00000016)
  );
  MUXCY   blk00000017 (
    .CI(sig00000018),
    .DI(a[3]),
    .S(sig0000000a),
    .O(sig00000017)
  );
  MUXCY   blk00000018 (
    .CI(sig00000019),
    .DI(a[2]),
    .S(sig0000000b),
    .O(sig00000018)
  );
  MUXCY   blk00000019 (
    .CI(sig0000001a),
    .DI(a[1]),
    .S(sig0000000c),
    .O(sig00000019)
  );
  MUXCY   blk0000001a (
    .CI(sig00000001),
    .DI(a[0]),
    .S(sig0000000e),
    .O(sig0000001a)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk0000001b (
    .I0(a[0]),
    .I1(b[0]),
    .O(sig0000000e)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk0000001c (
    .I0(a[1]),
    .I1(b[1]),
    .O(sig0000000c)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk0000001d (
    .I0(a[2]),
    .I1(b[2]),
    .O(sig0000000b)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk0000001e (
    .I0(a[3]),
    .I1(b[3]),
    .O(sig0000000a)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk0000001f (
    .I0(a[4]),
    .I1(b[4]),
    .O(sig00000009)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk00000020 (
    .I0(a[5]),
    .I1(b[5]),
    .O(sig00000008)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk00000021 (
    .I0(a[6]),
    .I1(b[6]),
    .O(sig00000007)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk00000022 (
    .I0(a[7]),
    .I1(b[7]),
    .O(sig00000006)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk00000023 (
    .I0(a[8]),
    .I1(b[8]),
    .O(sig00000005)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk00000024 (
    .I0(a[9]),
    .I1(b[9]),
    .O(sig00000004)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk00000025 (
    .I0(a[10]),
    .I1(b[10]),
    .O(sig00000003)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk00000026 (
    .I0(a[11]),
    .I1(b[11]),
    .O(sig00000002)
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  blk00000027 (
    .I0(a[12]),
    .I1(b[12]),
    .O(sig0000000d)
  );

// synthesis translate_on

endmodule

// synthesis translate_off

`ifndef GLBL
`define GLBL

`timescale  1 ps / 1 ps

module glbl ();

    parameter ROC_WIDTH = 100000;
    parameter TOC_WIDTH = 0;

//--------   STARTUP Globals --------------
    wire GSR;
    wire GTS;
    wire GWE;
    wire PRLD;
    tri1 p_up_tmp;
    tri (weak1, strong0) PLL_LOCKG = p_up_tmp;

    wire PROGB_GLBL;
    wire CCLKO_GLBL;

    reg GSR_int;
    reg GTS_int;
    reg PRLD_int;

//--------   JTAG Globals --------------
    wire JTAG_TDO_GLBL;
    wire JTAG_TCK_GLBL;
    wire JTAG_TDI_GLBL;
    wire JTAG_TMS_GLBL;
    wire JTAG_TRST_GLBL;

    reg JTAG_CAPTURE_GLBL;
    reg JTAG_RESET_GLBL;
    reg JTAG_SHIFT_GLBL;
    reg JTAG_UPDATE_GLBL;
    reg JTAG_RUNTEST_GLBL;

    reg JTAG_SEL1_GLBL = 0;
    reg JTAG_SEL2_GLBL = 0 ;
    reg JTAG_SEL3_GLBL = 0;
    reg JTAG_SEL4_GLBL = 0;

    reg JTAG_USER_TDO1_GLBL = 1'bz;
    reg JTAG_USER_TDO2_GLBL = 1'bz;
    reg JTAG_USER_TDO3_GLBL = 1'bz;
    reg JTAG_USER_TDO4_GLBL = 1'bz;

    assign (weak1, weak0) GSR = GSR_int;
    assign (weak1, weak0) GTS = GTS_int;
    assign (weak1, weak0) PRLD = PRLD_int;

    initial begin
	GSR_int = 1'b1;
	PRLD_int = 1'b1;
	#(ROC_WIDTH)
	GSR_int = 1'b0;
	PRLD_int = 1'b0;
    end

    initial begin
	GTS_int = 1'b1;
	#(TOC_WIDTH)
	GTS_int = 1'b0;
    end

endmodule

`endif

// synthesis translate_on
