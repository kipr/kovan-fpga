`timescale 1ns / 1ps

module pid(
    input [12:0] pos_d,
	 input [12:0] pos,
	 input [12:0] vel_d,
	 input [12:0] vel,
	 input [12:0] err_prev,
	 input [12:0] int_err_prev,
	 input [12:0] Kp_n,
	 input [7:0] Kp_d,
	 input [12:0] Ki_n,
	 input [7:0] Ki_d,
	 input [12:0] Kd_n,
	 input [7:0] Kd_d,
	 input [1:0] pid_motor_id_in,
	 input pid_in_valid,
	 input clk,
	 output [11:0] pwm,
	 output [12:0] err,
	 output [12:0] int_err,
	 output [1:0] drive_code,
	 output [1:0] pid_motor_id_out,
	 output pid_out_valid
    );
	 

	// get position error
	reg [12:0] err_sub_in_a_r;
	reg [12:0] err_sub_in_b_r;
	wire [12:0] err_sub_out;
	s13_sub err_sub(
		.a(err_sub_in_a_r),
		.b(err_sub_in_b_r),
		.s(err_sub_out)
	);
	
	
	// get velocity error
	reg [12:0] vel_err_sub_in_a_r;
	reg [12:0] vel_err_sub_in_b_r;
	wire [12:0] vel_err_sub_out;
	s13_sub vel_err_sub(
		.a(vel_err_sub_in_a_r),
		.b(vel_err_sub_in_b_r),
		.s(vel_err_sub_out)
	);
	
	// integrate the error
	reg [12:0] int_err_in_a_r;
	reg [12:0] int_err_in_b_r;
	wire [12:0] int_err_out;
	s13_add int_err_add(
		.a(int_err_in_a_r),
		.b(int_err_in_b_r),
		.s(int_err_out)
	);

	// calculate the derivite of error
	reg [12:0] d_err_in_a_r;
	reg [12:0] d_err_in_b_r;
	wire [12:0] d_err_out;
	s13_sub d_err_sub(
		.a(d_err_in_a_r),
		.b(d_err_in_b_r),
		.s(d_err_out)
	);


	// Proportional Term
	reg [12:0] kp_mult_in_a_r;
	reg [12:0] kp_mult_in_b_r;
	wire [25:0] kp_num_mult_out;
	s13_mult kp_numer_mult(
		.a(kp_mult_in_a_r),
		.b(kp_mult_in_b_r),
		.p(kp_num_mult_out)
	);


	//wire [12:0] kp_contrib;
	//reg [12:0] kp_contrib_data;
	//assign kp_contrib[12:0] = kp_contrib_data[12:0];
	//wire kp_valid;
	

	// Integral term
	reg [12:0] ki_mult_in_a_r;
	reg [12:0] ki_mult_in_b_r;
	wire [25:0] ki_num_mult_out;	
	s13_mult ki_numer_mult(
		.a(ki_mult_in_a_r),
		.b(ki_mult_in_b_r),
		.p(ki_num_mult_out)
	);

	//wire [12:0] ki_contrib;
	//reg [12:0] ki_contrib_data;

	//assign ki_contrib[12:0] = ki_contrib_data[12:0];
	//wire ki_valid;
	
	
	
	// Derivitive term
	reg [12:0] kd_mult_in_a_r;
	reg [12:0] kd_mult_in_b_r;
	wire [25:0] kd_num_mult_out;
   
	s13_mult kd_numer_mult(
		.a(kd_mult_in_a_r),
		.b(kd_mult_in_b_r),
		.p(kd_num_mult_out)
	);
	
	//wire [12:0] kd_contrib;
	//reg [12:0] kd_contrib_data;
	//assign kd_contrib[12:0] = kd_contrib_data[12:0];


	// Combine PD terms
	reg [12:0] pd_add_in_a;
	reg [12:0] pd_add_in_b;
	wire [12:0] pd_add_out;
	
	s13_add pd_add(
		.a(pd_add_in_a),
		.b(pd_add_in_b),
		.s(pd_add_out)
	);
	
	
	// Combine PID terms
	reg [12:0] pid_add_in_a;
	reg [12:0] pid_add_in_b;
	wire [12:0] pid_add_out;

	s13_add pid_add(
		.a(pid_add_in_a),
		.b(pid_add_in_b),
		.s(pid_add_out)
	);
	
	
	// pipeline registers
	
	reg [12:0] err_prev_0;
		
	reg [12:0] err_1;
	reg [12:0] err_2;
	reg [12:0] err_3;
	reg [12:0] err_4;
	reg [12:0] err_r;
	
	reg [12:0] int_err_2;
	reg [12:0] int_err_3;
	reg [12:0] int_err_4;	
	reg [12:0] int_err_r;
	
	reg [12:0] Kp_n_0;
	reg [12:0] Kp_n_1;
	
	reg [12:0] Ki_n_0;	
	reg [12:0] Ki_n_1;
	
	reg [12:0] Kd_n_0;
	reg [12:0] Kd_n_1;

	reg [7:0] Kp_d_0;
	reg [7:0] Kp_d_1;
	reg [7:0] Kp_d_2;
	
	reg [7:0] Ki_d_0;
	reg [7:0] Ki_d_1;
	reg [7:0] Ki_d_2;
		
	reg [7:0] Kd_d_0;
	reg [7:0] Kd_d_1;
	reg [7:0] Kd_d_2;
	
	reg [12:0] ki_contrib;
	
	reg [12:0] pid_out;
	
	reg close_enough_1;
	reg close_enough_2;
	
	reg [1:0] pid_motor_id_in_0;
	reg [1:0] pid_motor_id_in_1;
	reg [1:0] pid_motor_id_in_2;
	reg [1:0] pid_motor_id_in_3;
	reg [1:0] pid_motor_id_in_4;
	reg [1:0] pid_motor_id_in_5;
	
	reg pid_in_valid_0 = 1'b0;
	reg pid_in_valid_1 = 1'b0;
	reg pid_in_valid_2 = 1'b0;
	reg pid_in_valid_3 = 1'b0;
	reg pid_in_valid_4 = 1'b0;
	reg pid_in_valid_5 = 1'b0;
	

	always @ (posedge clk) begin
	

		// pipeline stage 0: load initial inputs
		err_sub_in_a_r <= pos_d;
		err_sub_in_b_r <= pos;	

		vel_err_sub_in_a_r <= vel_d;
		vel_err_sub_in_b_r <= vel;
		err_prev_0 <= err_prev;

		Kp_n_0 <= Kp_n;
		Ki_n_0 <= Ki_n;
		Kd_n_0 <= Kd_n;
		
		Kp_d_0 <= Kp_d;
		Ki_d_0 <= Ki_d;
		Kd_d_0 <= Kd_d;
		
		pid_motor_id_in_0 <= pid_motor_id_in;
		pid_in_valid_0 <= pid_in_valid;
		

	
		// pipeline stage 1: calculate position errors
		err_1 <= vel_err_sub_out;

		int_err_in_a_r <= int_err_prev;
		int_err_in_b_r <= vel_err_sub_out; // err_1

		d_err_in_a_r <= vel_err_sub_out; // err_1
		d_err_in_b_r <= err_prev_0; // err_prev_1

		Kp_n_1 <= Kp_n_0;
		Ki_n_1 <= Ki_n_0;
		Kd_n_1 <= Kd_n_0;
		
		Kp_d_1 <= Kp_d_0;
		Ki_d_1 <= Ki_d_0;
		Kd_d_1 <= Kd_d_0;


		pid_motor_id_in_1 <= pid_motor_id_in_0;
		pid_in_valid_1 <= pid_in_valid_0;


		// pipeline stage 2:  integrate err, calc err deriv
		int_err_2 <= int_err_out;
		//d_err_2 <= d_err_out;
		err_2 <= err_1;

		kp_mult_in_a_r <= Kp_n_1;
		kp_mult_in_b_r <= err_1;
		ki_mult_in_a_r <= Ki_n_1;
		ki_mult_in_b_r <= int_err_out;
		kd_mult_in_a_r <= Kd_n_1;
		kd_mult_in_b_r <= d_err_out;
		
		Kp_d_2 <= Kp_d_1;
		Ki_d_2 <= Ki_d_1;
		Kd_d_2 <= Kd_d_1;
		
		pid_motor_id_in_2 <= pid_motor_id_in_1;
		pid_in_valid_2 <= pid_in_valid_1;



		
		// pipeline stage 3: multiply by K_* numerators, lookup table based on denom to get value
		//                   handle division/shifting by K_* denominator
		err_3 <= err_2;
		int_err_3 <= int_err_2;
		pid_motor_id_in_3 <= pid_motor_id_in_2;
		pid_in_valid_3 <= pid_in_valid_2;
		
		case (Kp_d_2)
			8'd0:    pd_add_in_a <= kp_num_mult_out[12:0]; 
			8'd1:    pd_add_in_a <= kp_num_mult_out[13:1]; 
			8'd2:    pd_add_in_a <= kp_num_mult_out[14:2];
			8'd4:    pd_add_in_a <= kp_num_mult_out[15:3];
			8'd8:    pd_add_in_a <= kp_num_mult_out[16:4];
			8'd16:   pd_add_in_a <= kp_num_mult_out[17:5];
			8'd32:   pd_add_in_a <= kp_num_mult_out[18:6];
			8'd64:   pd_add_in_a <= kp_num_mult_out[19:7];
			8'd128:  pd_add_in_a <= kp_num_mult_out[20:8];
			default: pd_add_in_a <= kp_num_mult_out[12:0];
		endcase
		
		case (Ki_d_2)
			8'd0:    ki_contrib <= ki_num_mult_out[12:0]; 
			8'd1:    ki_contrib <= ki_num_mult_out[13:1]; 
			8'd2:    ki_contrib <= ki_num_mult_out[14:2];
			8'd4:    ki_contrib <= ki_num_mult_out[15:3];
			8'd8:    ki_contrib <= ki_num_mult_out[16:4];
			8'd16:   ki_contrib <= ki_num_mult_out[17:5];
			8'd32:   ki_contrib <= ki_num_mult_out[18:6];
			8'd64:   ki_contrib <= ki_num_mult_out[19:7];
			8'd128:  ki_contrib <= ki_num_mult_out[20:8];
			default: ki_contrib <= ki_num_mult_out[12:0];
		endcase
		
		case (Kd_d_2)
			8'd0:    pd_add_in_b <= kd_num_mult_out[12:0]; 
			8'd1:    pd_add_in_b <= kd_num_mult_out[13:1]; 
			8'd2:    pd_add_in_b <= kd_num_mult_out[14:2];
			8'd4:    pd_add_in_b <= kd_num_mult_out[15:3];
			8'd8:    pd_add_in_b <= kd_num_mult_out[16:4];
			8'd16:   pd_add_in_b <= kd_num_mult_out[17:5];
			8'd32:   pd_add_in_b <= kd_num_mult_out[18:6];
			8'd64:   pd_add_in_b <= kd_num_mult_out[19:7];
			8'd128:  pd_add_in_b <= kd_num_mult_out[20:8];
			default: pd_add_in_b <= kd_num_mult_out[12:0];
		endcase



		// pipeline stage 4: compute PD sum
		err_4 <= err_3;
		int_err_4 <= int_err_3;
		pid_add_in_a[12:0] <= pd_add_out[12:0];
		pid_add_in_b[12:0] <= ki_contrib[12:0];
		pid_motor_id_in_4 <= pid_motor_id_in_3;
		pid_in_valid_4 <= pid_in_valid_3;



		// pipeline stage 5: compute PID sum (PD + I)
		err_r <= err_4;
		int_err_r <= int_err_4;
		pid_out <= pid_add_out;
		pid_motor_id_in_5 <= pid_motor_id_in_4;
		pid_in_valid_5 <= pid_in_valid_4;
	
	end

	
	// outputs
	assign pwm = (pid_out[12]) ? ~pid_out[11:0] : pid_out[11:0]; // drops a bit in negative case
	assign err = err_r;
	assign int_err = int_err_r;
	assign drive_code = {!pid_out[12],pid_out[12]};
	assign pid_motor_id_out = pid_motor_id_in_5;
	assign pid_out_valid = pid_in_valid_5;
endmodule
