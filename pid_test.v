`timescale 1ns / 1ps


module pid_test;

	// Inputs
	reg [12:0] pos_d;
	reg [12:0] pos;
	reg [12:0] err_prev;
	reg [12:0] int_err_prev;
	reg [12:0] Kp_n;
	reg [7:0] Kp_d;
	reg [12:0] Ki_n;
	reg [7:0] Ki_d;
	reg [12:0] Kd_n;
	reg [7:0] Kd_d;
	reg clk;

	// Outputs
	wire [12:0] pwm;
	wire [12:0] err;
	wire [12:0] int_err;
	wire dir;

	// Instantiate the Unit Under Test (UUT)
	pid uut (
		.pos_d(pos_d), 
		.pos(pos), 
		.err_prev(err_prev), 
		.int_err_prev(int_err_prev), 
		.Kp_n(Kp_n), 
		.Kp_d(Kp_d), 
		.Ki_n(Ki_n), 
		.Ki_d(Ki_d), 
		.Kd_n(Kd_n), 
		.Kd_d(Kd_d), 
		.clk(clk), 
		.pwm(pwm), 
		.err(err), 
		.int_err(int_err), 
		.dir(dir)
	);

	reg [12:0] exp_100;
	reg [12:0] exp_200;
	reg [12:0] exp_300;
	reg [12:0] exp_400;


	initial begin
		exp_100 = 0;
		exp_200 = 0;
		exp_300 = 0;
		exp_400 = 0;
		
		// Initialize Inputs
		pos_d = 100;
		pos = 0;
		err_prev = 0;
		int_err_prev = 0;
		Kp_n = 1;
		Kp_d = 0;
		Ki_n = 0;
		Ki_d = 0;
		Kd_n = 0;
		Kd_d = 0;
		clk = 0;
		

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here

		
		clk = 1; #10; clk = 0; #10;
		clk = 1; #10; clk = 0; #10;
		clk = 1; #10; clk = 0; #10;
		clk = 1; #10; clk = 0; #10;
		clk = 1; #10; clk = 0; #10;
		clk = 1; #10; clk = 0; #10;	
		
		// Add stimulus here
		forever begin
			pos_d = 100;
			err_prev = err;
			exp_100 = err;
			int_err_prev = int_err;
			clk = 1; #10; clk = 0; #10;
			pos_d = 200;
			exp_200 = err;
			clk = 1; #10; clk = 0; #10;
			pos_d = 300;
			exp_300 = err;
			clk = 1; #10; clk = 0; #10;
			pos_d = 400;
			exp_400 = err;
			clk = 1; #10; clk = 0; #10;
			clk = 1; #10; clk = 0; #10;
			clk = 1; #10; clk = 0; #10;
		end

	end
      
endmodule

