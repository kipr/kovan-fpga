`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    23:32:58 11/10/2012 
// Design Name: 
// Module Name:    dna 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module dna(
	input clk26buf,
	input clk1M,
	input glbl_reset,
	output [55:0] dna_data);

//////////////////////////////////////
  // cheezy low speed clock divider source
  //////////////////////////////////////
   reg [22:0] counter;

   always @(posedge clk26buf) begin
      counter <= counter + 1;
   end
   
   
   ////////////////////////////////
   // serial number
   ////////////////////////////////
   reg 	clk1M_unbuf;
   always @(posedge clk26buf) begin
      clk1M_unbuf <= counter[6];
   end
   
   BUFG clk1M_buf(.I(clk1M_unbuf), .O(clk1M));

   wire dna_reset;
   sync_reset  dna_reset_sync(
			  .clk(clk1M),
			  .glbl_reset(glbl_reset),
			  .reset(dna_reset) );
   
   reg 	dna_pulse;
   reg 	dna_shift;
   wire dna_bit;
   
   DNA_PORT device_dna( .CLK(clk1M), .DIN(1'b0), .DOUT(dna_bit), .READ(dna_pulse), .SHIFT(dna_shift) );
   
   parameter DNA_INIT =    4'b1 << 0;
   parameter DNA_PULSE =   4'b1 << 1;
   parameter DNA_SHIFT =   4'b1 << 2;
   parameter DNA_DONE =    4'b1 << 3;

   parameter DNA_nSTATES = 4;

   reg [(DNA_nSTATES-1):0] DNA_cstate = {{(DNA_nSTATES-1){1'b0}}, 1'b1};
   reg [(DNA_nSTATES-1):0] DNA_nstate;
   reg [5:0] 		   dna_shift_count;

   always @ (posedge clk1M) begin
      if (dna_reset)
	DNA_cstate <= DNA_INIT; 
      else
	DNA_cstate <= DNA_nstate;
   end

   always @ (*) begin
      case (DNA_cstate) //synthesis parallel_case full_case
	DNA_INIT: begin
	   DNA_nstate = DNA_PULSE;
	end
	DNA_PULSE: begin
	   DNA_nstate = DNA_SHIFT;
	end
	DNA_SHIFT: begin
	   // depending on if MSB or LSB first, want to use 56 or 55
	   // especially if serial #'s are linear-incrementing
	   DNA_nstate = (dna_shift_count[5:0] == 6'd55) ? DNA_DONE : DNA_SHIFT;
	end
	DNA_DONE: begin
	   DNA_nstate = DNA_DONE;
	end
      endcase // case (DNA_cstate)
   end
   
   always @ (posedge clk1M) begin
      if( dna_reset ) begin
	   dna_shift_count <= 6'h0;
	   dna_data <= 56'h0;
	   dna_pulse <= 1'b0;
	   dna_shift <= 1'b0;
      end else begin
	 case (DNA_cstate) //synthesis parallel_case full_case
	   DNA_INIT: begin
	      dna_shift_count <= 6'h0;
	      dna_data <= 56'h0;
	      dna_pulse <= 1'b0;
	      dna_shift <= 1'b0;
	   end
	   DNA_PULSE: begin
	      dna_shift_count <= 6'h0;
	      dna_data <= 56'h0;
	      dna_pulse <= 1'b1;
	      dna_shift <= 1'b0;
	   end
	   DNA_SHIFT: begin
	      dna_shift_count <= dna_shift_count + 6'b1;
	      dna_data[55:0] <= {dna_data[54:0],dna_bit};
	      dna_pulse <= 1'b0;
	      dna_shift <= 1'b1;
	   end
	   DNA_DONE: begin
	      dna_shift_count <= dna_shift_count;
	      dna_data[55:0] <= dna_data[55:0];
	      dna_pulse <= 1'b0;
	      dna_shift <= 1'b0;
	   end
	 endcase // case (DNA_cstate)
      end // else: !if( dna_reset )
   end // always @ (posedge clk1M or posedge ~rstbtn_n)



endmodule
