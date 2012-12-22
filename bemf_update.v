`timescale 1ns / 1ps

module bemf_update(
    input [9:0] bemf_adc_h,
    input [9:0] bemf_adc_l,
    input [1:0] mot_sel_in,
    input in_valid,
    input [19:0] bemf_in,
	 input [19:0] bemf_calib_in,
    input clk,
    output [19:0] bemf_out,
	 output [19:0] bemf_vel_out,
    output [1:0] mot_sel_out,
    output out_valid
    );


	// subtract the high and low side of the motor
	reg [9:0] bemf_sub_in_a_r = 10'd0;
	reg [9:0] bemf_sub_in_b_r = 10'd0;
	wire [19:0] bemf_sub_out;
	s20_sub bemf_sub(
		.a({10'd0, bemf_sub_in_a_r}),
		.b({10'd0, bemf_sub_in_b_r}),
		.s(bemf_sub_out)
	);


	// adjust by the calibration amount
	reg [19:0] calib_sub_in_a_r = 20'd0;
	reg [19:0] calib_sub_in_b_r = 20'd0;
	wire [19:0] calib_sub_out;
	s20_sub calib_sub(
		.a(calib_sub_in_a_r),
		.b(calib_sub_in_b_r),
		.s(calib_sub_out)
	);	
	
	
	// integrate the calibrated back emf readings
	reg [19:0] bemf_integr_in_a_r = 20'd0;
	reg [19:0] bemf_integr_in_b_r = 20'd0;
	wire [19:0] bemf_integr_out;
	s20_add bemf_integr(
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
	
	reg [19:0] bemf_out_r = 20'd0;
	
	reg [19:0] bemf_in_0 = 20'd0;
	reg [19:0] bemf_in_1 = 20'd0;
	
	
	reg [19:0] vel_out_3 = 20'd0;
	
	always @ (posedge clk) begin

		// pipeline stage 0: load inputs
		bemf_sub_in_a_r <= bemf_adc_h;
		bemf_sub_in_b_r <= bemf_adc_l;
		in_valid_0 <= in_valid;
		mot_sel_in_0 <= mot_sel_in;
		bemf_in_0 <= bemf_in;
		
		
		// pipeline stage 1: calculated (bemf_high - bemf_low)
		calib_sub_in_a_r <= bemf_sub_out;
		calib_sub_in_b_r <= bemf_calib_in;
		in_valid_1 <= in_valid_0;
		mot_sel_in_1 <= mot_sel_in_0;
		bemf_in_1 <= bemf_in_0;


	
		// pipeline stage 2: subtracted the calibration info
	
		// deadbanding
		if (calib_sub_out[19] == 1'b1)
			bemf_integr_in_a_r <= (~calib_sub_out > 16'd21) ? calib_sub_out : 20'd0; //negative 
		else
			bemf_integr_in_a_r <= (calib_sub_out > 15'd20) ? calib_sub_out : 20'd0; // positive

		//bemf_integr_in_a_r <= calib_sub_out;
		bemf_integr_in_b_r <= bemf_in_1;
		in_valid_2 <= in_valid_1;	
		mot_sel_in_2 <= mot_sel_in_1;
	
	
		// pipeline stage 3: integrated the calibrated value
		
		vel_out_3 <= bemf_integr_in_a_r;
		bemf_out_r <= bemf_integr_out;
		in_valid_3 <= in_valid_2;
		mot_sel_in_3 <= mot_sel_in_2;
	
	end
	
	assign bemf_out = bemf_out_r;
	assign out_valid = in_valid_3;
	assign mot_sel_out = mot_sel_in_3;
	assign bemf_vel_out = vel_out_3;
	
endmodule
