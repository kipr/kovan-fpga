/*******************************************************************************
*     This file is owned and controlled by Xilinx and must be used solely      *
*     for design, simulation, implementation and creation of design files      *
*     limited to Xilinx devices or technologies. Use with non-Xilinx           *
*     devices or technologies is expressly prohibited and immediately          *
*     terminates your license.                                                 *
*                                                                              *
*     XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS" SOLELY     *
*     FOR USE IN DEVELOPING PROGRAMS AND SOLUTIONS FOR XILINX DEVICES.  BY     *
*     PROVIDING THIS DESIGN, CODE, OR INFORMATION AS ONE POSSIBLE              *
*     IMPLEMENTATION OF THIS FEATURE, APPLICATION OR STANDARD, XILINX IS       *
*     MAKING NO REPRESENTATION THAT THIS IMPLEMENTATION IS FREE FROM ANY       *
*     CLAIMS OF INFRINGEMENT, AND YOU ARE RESPONSIBLE FOR OBTAINING ANY        *
*     RIGHTS YOU MAY REQUIRE FOR YOUR IMPLEMENTATION.  XILINX EXPRESSLY        *
*     DISCLAIMS ANY WARRANTY WHATSOEVER WITH RESPECT TO THE ADEQUACY OF THE    *
*     IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR           *
*     REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE FROM CLAIMS OF          *
*     INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A    *
*     PARTICULAR PURPOSE.                                                      *
*                                                                              *
*     Xilinx products are not intended for use in life support appliances,     *
*     devices, or systems.  Use in such applications are expressly             *
*     prohibited.                                                              *
*                                                                              *
*     (c) Copyright 1995-2012 Xilinx, Inc.                                     *
*     All rights reserved.                                                     *
*******************************************************************************/

/*******************************************************************************
*     Generated from core with identifier: xilinx.com:ip:c_addsub:11.0         *
*                                                                              *
*     The Xilinx LogiCORE Adder Subtracter can create adders, subtracters,     *
*     and adders/subtracters that operate on signed or unsigned data. In       *
*     fabric, the module supports inputs ranging from 1 to 256 bits wide,      *
*     and outputs ranging from 1 to 258 bits wide.  I/O widths are family      *
*     dependent for dsp48 implementations.                                     *
*******************************************************************************/
// Synthesized Netlist Wrapper
// This file is provided to wrap around the synthesized netlist (if appropriate)

// Interfaces:
//    a_intf
//    clk_intf
//    sclr_intf
//    ce_intf
//    b_intf
//    add_intf
//    c_in_intf
//    bypass_intf
//    sset_intf
//    sinit_intf
//    c_out_intf
//    s_intf

module s16_add (
  a,
  b,
  s
);

  input [15 : 0] a;
  input [15 : 0] b;
  output [15 : 0] s;

  // WARNING: This file provides a module declaration only, it does not support
  //          direct instantiation. Please use an instantiation template (VEO) to
  //          instantiate the IP within a design.

endmodule

