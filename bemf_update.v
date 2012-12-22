`timescale 1ns / 1ps

module bemf_update(
    input [9:0] bemf_adc_h,
    input [9:0] bemf_adc_l,
    input [1:0] mot_sel_in,
    input in_valid,
    input [15:0] bemf_in,
	 input [15:0] bemf_calib_in,
    input clk,
    output [15:0] bemf_out,
    output [1:0] mot_sel_out,
    output out_valid
    );


	// subtract the high and low side of the motor
	reg [9:0] bemf_sub_in_a_r = 10'd0;
	reg [9:0] bemf_sub_in_b_r = 10'd0;
	wire [15:0] bemf_sub_out;
	s16_sub bemf_sub(
		.a({6'd0, bemf_sub_in_a_r}),
		.b({6'd0, bemf_sub_in_b_r}),
		.s(bemf_sub_out)
	);


	// adjust by the calibration amount
	reg [15:0] calib_sub_in_a_r = 16'd0;
	reg [15:0] calib_sub_in_b_r = 16'd0;
	wire [15:0] calib_sub_out;
	s16_sub calib_sub(
		.a(calib_sub_in_a_r),
		.b(calib_sub_in_b_r),
		.s(calib_sub_out)
	);	
	
	
	// integrate the calibrated back emf readings
	reg [15:0] bemf_integr_in_a_r = 16'd0;
	reg [15:0] bemf_integr_in_b_r = 16'd0;
	wire [15:0] bemf_integr_out;
	s16_add bemf_integr(
		.a(bemf_integr_in_a_r),
		.b(bemf_integr_in_b_r),
		.s(bemf_integr_out)
	);
	

	reg [1:0] mot_sel_in_0 = 2'd0;
	reg [1:0] mot_sel_in_1 = 2'd0;
	reg [1:0] mot_sel_in_2 = 2'd0;
	reg [1:0] mot_sel_in_3 = 2'd0;
	
	reg in_valid_0 = 1'd0;
	reg in_valid_1 = 1'd0;
	reg in_valid_2 = 1'd0;
	reg in_valid_3 = 1'd0;
	
	reg [15:0] bemf_out_r = 16'd0;
	
	always @ (posedge clk) begin

		// pipeline stage 0: load inputs
		bemf_sub_in_a_r <= bemf_adc_h;
		bemf_sub_in_b_r <= bemf_adc_l;
		in_valid_0 <= in_valid;
		mot_sel_in_0 <= mot_sel_in;
		
		
		// pipeline stage 1: calculated (bemf_high - bemf_low)
		calib_sub_in_a_r <= bemf_sub_out;
		calib_sub_in_b_r <= bemf_calib_in;
		in_valid_1 <= in_valid_0;
		mot_sel_in_1 <= mot_sel_in_0;

	
		// pipeline stage 2: subtracted the calibration info
		bemf_integr_in_a_r <= calib_sub_out;
		bemf_integr_in_b_r <= bemf_in;
		in_valid_2 <= in_valid_1;	
		mot_sel_in_2 <= mot_sel_in_1;
	
	
		// pipeline stage 3: integrated the calibrated value
		bemf_out_r <= bemf_integr_out;
		in_valid_3 <= in_valid_2;
		mot_sel_in_3 <= mot_sel_in_2;
	
	end
	
	assign bemf_out = bemf_out_r;
	assign out_valid = in_valid_3;
	assign mot_sel_out = mot_sel_in_3;
	
endmodule
