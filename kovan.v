////////////////////////////////////////////////
// Copyright (c) 2012, Andrew "bunnie" Huang  
// (bunnie _aht_ bunniestudios "dote" com)
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//     Redistributions of source code must retain the above copyright
//     notice, this list of conditions and the following disclaimer.
//     Redistributions in binary form must reproduce the above copyright
//     notice, this list of conditions and the following disclaimer in
//     the documentation and/or other materials provided with the
//     distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
////////////////////////////////////////////////
  
`timescale 1 ns / 1 ps

module kovan (

	input wire INPUT_SW0,

	// power management
	input wire CHG_ACP,           	// reports presence of AC power
	//output wire CHG_SHDN,         // leave floating

	// i/o controller digital interfaces
	input wire        DIG_ADC_OUT,
	output wire [1:0] DIG_ADC_CS,
	output wire       DIG_ADC_IN,
	output wire       DIG_ADC_SCLK,
	output wire       DIG_ADC_CLR,
	output wire       DIG_IN,
	input wire        DIG_OUT,
	output wire       DIG_RCLK,
	output wire       DIG_SAMPLE,
	output wire       DIG_SCLK,
	output wire       DIG_SRLOAD,
	output wire       DIG_CLR_N,

	// motor direct drive interfaces
	output wire [3:0] MBOT,
	output wire [3:0] MTOP,
	output wire       MOT_PWM,
	output wire [3:0] M_SERVO,

	// audio pass-through
	input wire        I2S_CDCLK0, // master reference clock to audio PLL
	output wire       I2S_CDCLK1,
	output wire       I2S_CLK0,   // return sample clock to CPU
	input wire        I2S_CLK1,
	input wire        I2S_DI0,    // audio data to playback
	output wire       I2S_DI1,
	output wire       I2S_DO0,    // audio data from record
	input wire        I2S_DO1,
	output wire       I2S_LRCLK0, // left/right clock to codec
	input wire        I2S_LRCLK1,

	// LCD output to display
	output wire [7:3] LCDO_B,  // note truncation of blue channel
	output wire [7:2] LCDO_G,
	output wire [7:2] LCDO_R,
	output wire       LCDO_DEN,
	output wire       LCDO_DOTCLK,
	output wire       LCDO_HSYNC,
	output wire       LCDO_RESET_N,
	output wire       LCDO_VSYNC,

	// LCD input from CPU
	input wire [5:1]  LCD_B,  // note no truncation of data in
	input wire [5:0]  LCD_G,
	input wire [5:0]  LCD_R,
	input wire        LCD_DEN,
	input wire        LCD_HS,
	//input wire [5:0]  LCD_SUPP,
	input wire        LCD_VS,
	output wire       LCD_CLK_T,  // clock is sourced from the FPGA

	// SSP interface to the CPU
	output wire       FPGA_MISO,
	input wire        FPGA_MOSI,
	input wire        FPGA_SCLK,
	input wire        FPGA_SYNC,

	output wire			ADC_BATT_SEL,

	input wire       OSC_CLK   // 26 mhz clock from CPU
	);

   ///////// clock buffers
   wire		clk26;
   wire		clk26ibuf;
   wire		clk26buf;
   wire		clk13buf;
   wire		clk3p2M;
   wire		clk208M;
	//wire		clk104M;
   wire		clk1M = 1'b0;  // wired up in the serial number section
   
   assign clk26 = OSC_CLK;
   IBUFG clk26buf_ibuf(.I(clk26), .O(clk26ibuf));
   BUFG clk26buf_buf (.I(clk26ibuf), .O(clk26buf));

   
   ////////// loop-throughs
   // lcd runs at a target of 6.41 MHz (156 ns cycle time)
   // i.e., 408 x 262 x 60 Hz (408 is total H width, 320 active, etc.)
   wire            qvga_clkgen_locked;
   
	clk_wiz_v3_2_qvga qvga_clkgen( .CLK_IN1(clk26buf),
			  .clk_out6p4(clk_qvga),
			  .clk_out13(clk13buf),
			  .clk_out3p25(clk3p2M), // note: a slight overclock (about 2%)
			  .clk_out208(clk208M),
			  //.clk_out104(clk104M),
			  .RESET(1'b0),//.RESET(glbl_reset),
			  .LOCKED(qvga_clkgen_locked) );
				  
				  
   reg 	[5:1]	   lcd_pipe_b;
   reg 	[5:0]	   lcd_pipe_r;
   reg 	[5:0]	   lcd_pipe_g;
   reg 		   lcd_pipe_den;
   reg 		   lcd_hsync;
   reg 		   lcd_vsync;
   reg 		   lcd_reset_n;
   reg 		   lcd_pipe_hsync;
   reg 		   lcd_pipe_vsync;
   wire 	   lcd_reset;

   sync_reset  qvga_reset(
			  .clk(clk_qvga),
			  .glbl_reset(!qvga_clkgen_locked),
			  //.glbl_reset(glbl_reset || !qvga_clkgen_locked),
			  .reset(lcd_reset) );
			  
   always @(posedge clk_qvga) begin
      // TODO: assign timing constraints to ensure hold times met for LCD
      lcd_pipe_b[5:1] <= LCD_B[5:1];
      lcd_pipe_g[5:0] <= LCD_G[5:0];
      lcd_pipe_r[5:0] <= LCD_R[5:0];
      lcd_pipe_den <= LCD_DEN;
      lcd_pipe_hsync <= LCD_HS;
      lcd_pipe_vsync <= LCD_VS;
      lcd_reset_n <= !lcd_reset;
   end
	
	//reg adc_batt_sel_r = 0;
	//assign ADC_BATT_SEL = adc_batt_sel_r;
	
   assign LCDO_B[7:3] = lcd_pipe_b[5:1];
   assign LCDO_G[7:2] = lcd_pipe_g[5:0];
   assign LCDO_R[7:2] = lcd_pipe_r[5:0];
   assign LCDO_DEN = lcd_pipe_den;
   assign LCDO_HSYNC = lcd_pipe_hsync;
   assign LCDO_VSYNC = lcd_pipe_vsync;
   assign LCDO_RESET_N = lcd_reset_n;

   // low-skew clock mirroring to an output pin requires this hack
   ODDR2 qvga_clk_to_lcd (.D0(1'b1), .D1(1'b0), 
			  .C0(clk_qvga), .C1(!clk_qvga), 
			  .Q(LCDO_DOTCLK), .CE(1'b1), .R(1'b0), .S(1'b0) );

   ODDR2 qvga_clk_to_cpu (.D0(1'b1), .D1(1'b0), 
			 .C0(clk_qvga), .C1(!clk_qvga), 
			 .Q(LCD_CLK_T), .CE(1'b1), .R(1'b0), .S(1'b0) );


   ///////////////////////////////////////////
   // audio pass-through -- unbuffurred, unregistered for now
   assign I2S_CDCLK1 = I2S_CDCLK0;
   assign I2S_CLK0 = I2S_CLK1;
   assign I2S_DI1 = I2S_DI0;
   assign I2S_DO0 = I2S_DO1;
   assign I2S_LRCLK0 = I2S_LRCLK1;
   
   ///////////////////////////////////////////
   // motor control unit
   wire [7:0] dig_out_val;
   wire [7:0] dig_oe;
   wire [7:0] dig_pu;
   wire [7:0] ana_pu;
   wire [7:0] dig_in_val;
   wire       dig_val_good;
   wire       dig_busy;
   wire       dig_sample;
   wire       dig_update;

	reg [7:0] dig_in_val_old = 8'd0;
	reg [7:0] dig_in_val_new = 8'd0;
	

   wire [9:0] adc_in;
   wire [3:0] adc_chan;
   wire       adc_valid;
   wire       adc_go;

   wire [11:0] mot_duty0;
	wire [11:0] mot_duty1;
	wire [11:0] mot_duty2;   
	wire [11:0] mot_duty3;

   wire [7:0]  mot_drive_code;
   wire [4:0]  mot_allstop;

   wire [23:0] servo_pwm_period;
   wire [23:0] servo0_pwm_pulse;
   wire [23:0] servo1_pwm_pulse;
   wire [23:0] servo2_pwm_pulse;
   wire [23:0] servo3_pwm_pulse;
	
	// neutral servo positions at startup
	//reg [1039:0] SPI_REG = 1040'd0;
	//reg [1039:0] SPI_REG_p = 1040'd0;
	
	wire [1039:384] COMMAND_REG;

	reg [7:0] dig_out_val_r = 8'h00;

   wire [9:0] adc_0_in;
   wire [9:0] adc_1_in;
   wire [9:0] adc_2_in;
   wire [9:0] adc_3_in;
   wire [9:0] adc_4_in;
   wire [9:0] adc_5_in;
   wire [9:0] adc_6_in;
   wire [9:0] adc_7_in;
   wire [9:0] adc_8_in;
   wire [9:0] adc_9_in;
   wire [9:0] adc_10_in;
   wire [9:0] adc_11_in;
   wire [9:0] adc_12_in;
   wire [9:0] adc_13_in;
   wire [9:0] adc_14_in;
   wire [9:0] adc_15_in;
   wire [9:0] adc_16_in;
	
	reg [9:0] adc_0_old;
   reg [9:0] adc_1_old;
   reg [9:0] adc_2_old;
   reg [9:0] adc_3_old;
   reg [9:0] adc_4_old;
   reg [9:0] adc_5_old;
   reg [9:0] adc_6_old;
   reg [9:0] adc_7_old;
   reg [9:0] adc_8_old;
   reg [9:0] adc_9_old;
   reg [9:0] adc_10_old;
   reg [9:0] adc_11_old;
   reg [9:0] adc_12_old;
   reg [9:0] adc_13_old;
   reg [9:0] adc_14_old;
   reg [9:0] adc_15_old;
   reg [9:0] adc_16_old;
	
	reg [9:0] adc_0_new;
   reg [9:0] adc_1_new;
   reg [9:0] adc_2_new;
   reg [9:0] adc_3_new;
   reg [9:0] adc_4_new;
   reg [9:0] adc_5_new;
   reg [9:0] adc_6_new;
   reg [9:0] adc_7_new;
   reg [9:0] adc_8_new;
   reg [9:0] adc_9_new;
   reg [9:0] adc_10_new;
   reg [9:0] adc_11_new;
   reg [9:0] adc_12_new;
   reg [9:0] adc_13_new;
   reg [9:0] adc_14_new;
   reg [9:0] adc_15_new;
   reg [9:0] adc_16_new;
	
	wire [35:0] bemf_0;
   wire [35:0] bemf_1;
   wire [35:0] bemf_2;
   wire [35:0] bemf_3;
	
	reg [35:0] bemf_0_r;
   reg [35:0] bemf_1_r;
   reg [35:0] bemf_2_r;
   reg [35:0] bemf_3_r;
	
	
	reg [35:0] bemf_0_r_208M = 36'd0;
   reg [35:0] bemf_1_r_208M = 36'd0;
   reg [35:0] bemf_2_r_208M = 36'd0;
   reg [35:0] bemf_3_r_208M = 36'd0;
	
	reg [35:0] bemf_0_calib = 36'd0;
   reg [35:0] bemf_1_calib = 36'd0;
   reg [35:0] bemf_2_calib = 36'd0;
   reg [35:0] bemf_3_calib = 36'd0;
	

	reg [35:0] mot_duty0_old = 36'd0;
	reg [35:0] mot_duty1_old = 36'd0;
	reg [35:0] mot_duty2_old = 36'd0;
	reg [35:0] mot_duty3_old = 36'd0;
	
	reg [23:8] servo_pwm0_old = 16'd0;
	reg [23:8] servo_pwm1_old = 16'd0;
	reg [23:8] servo_pwm2_old = 16'd0;
	reg [23:8] servo_pwm3_old = 16'd0;
	
	
	wire [15:0] mot_duty0_new;
	wire [15:0] mot_duty1_new;
	wire [15:0] mot_duty2_new;
	wire [15:0] mot_duty3_new;
	
	wire [23:8] servo_pwm0_new;
	wire [23:8] servo_pwm1_new;
	wire [23:8] servo_pwm2_new;
	wire [23:8] servo_pwm3_new;
	
	reg [7:0] dig_out_val_old = 8'd0;
	reg [7:0] dig_pu_old = 8'd0;
	reg [7:0] dig_oe_old = 8'd0;
	reg [7:0] ana_pu_old = 8'd0;
	reg [0:0] dig_sample_old = 1'd0;
	reg [0:0] dig_update_old = 1'd0;
	reg [7:0] mot_drive_code_old = 8'd0;
	reg [4:0] mot_allstop_old = 5'd0;
	
	wire [7:0] dig_out_val_new;
	wire [7:0] dig_pu_new;
	wire [7:0] dig_oe_new;
	wire [7:0] ana_pu_new;
	reg [0:0] dig_sample_new;
	reg [0:0] dig_update_new;
	wire [7:0] mot_drive_code_new;
	wire [4:0] mot_allstop_new;


	assign mot_duty0 = mot_duty0_new;
	assign mot_duty1 = mot_duty1_new;
	assign mot_duty2 = mot_duty2_new;
	assign mot_duty3 = mot_duty3_new;

	assign servo0_pwm_pulse = {servo_pwm0_old, 8'd0};
	assign servo1_pwm_pulse = {servo_pwm1_old, 8'd0};
	assign servo2_pwm_pulse = {servo_pwm2_old, 8'd0};
	assign servo3_pwm_pulse = {servo_pwm3_old, 8'd0};

	
	// TODO: new or old?
	assign dig_out_val = dig_out_val_old;
	assign dig_oe = dig_oe_old;
	assign dig_pu = dig_pu_old;
	assign ana_pu = ana_pu_old;
	
	assign dig_sample = dig_sample_old;
	assign dig_update = dig_update_old;
	
	
	assign mot_drive_code[7:6] = mot_drive_code_old[7:6];
	assign mot_drive_code[5:4] = mot_drive_code_old[5:4];
	assign mot_drive_code[3:2] = mot_drive_code_old[3:2];
	assign mot_drive_code[1:0] = mot_drive_code_old[1:0];
	
	assign mot_allstop = mot_allstop_old;

	assign bemf_0 = bemf_0_r_208M;
	assign bemf_1 = bemf_1_r_208M;
	assign bemf_2 = bemf_2_r_208M;
	assign bemf_3 = bemf_3_r_208M;

	wire bemf_sensing;
	reg bemf_sensing_r = 1'd0;
	assign bemf_sensing = bemf_sensing_r;

	reg side_button_new = 1'd0;
	reg side_button_old = 1'd0;

	always @ (posedge clk208M) begin
		side_button_new <= INPUT_SW0;
		
		side_button_old <= side_button_new;
		
		mot_duty0_old <= mot_duty0_new;
		mot_duty1_old <= mot_duty1_new;
		mot_duty2_old <= mot_duty2_new;
		mot_duty3_old <= mot_duty3_new;
		
		servo_pwm0_old <= servo_pwm0_new;
		servo_pwm1_old <= servo_pwm1_new;
		servo_pwm2_old <= servo_pwm2_new;
		servo_pwm3_old <= servo_pwm3_new;
		
		dig_out_val_old <= dig_out_val_new;
		dig_pu_old <= dig_pu_new;
		dig_oe_old <= dig_oe_new;
		ana_pu_old <= ana_pu_new;
		dig_sample_old <= dig_sample_new;
		dig_update_old <= dig_update_new;
		mot_drive_code_old <= mot_drive_code_new;
		mot_allstop_old <= mot_allstop_new;
		
		//bemf_calib_cmd_old <= bemf_calib_cmd_new;
	
		bemf_0_r_208M <= bemf_0_r;
		bemf_1_r_208M <= bemf_1_r;
		bemf_2_r_208M <= bemf_2_r;
		bemf_3_r_208M <= bemf_3_r;
		
		adc_0_new <= adc_0_in;
		adc_1_new <= adc_1_in;
		adc_2_new <= adc_2_in;
		adc_3_new <= adc_3_in;
		adc_4_new <= adc_4_in;
		adc_5_new <= adc_5_in;
		adc_6_new <= adc_6_in;
		adc_7_new <= adc_7_in;
		adc_8_new <= adc_8_in;
		adc_9_new <= adc_9_in;
		adc_10_new <= adc_10_in;
		adc_11_new <= adc_11_in;
		adc_12_new <= adc_12_in;
		adc_13_new <= adc_13_in;
		adc_14_new <= adc_14_in;
		adc_15_new <= adc_15_in;
		adc_16_new <= adc_16_in;
		
		adc_0_old <= adc_0_new;
		adc_1_old <= adc_1_new;
		adc_2_old <= adc_2_new;
		adc_3_old <= adc_3_new;
		adc_4_old <= adc_4_new;
		adc_5_old <= adc_5_new;
		adc_6_old <= adc_6_new;
		adc_7_old <= adc_7_new;
		adc_8_old <= adc_8_new;
		adc_9_old <= adc_9_new;
		adc_10_old <= adc_10_new;
		adc_11_old <= adc_11_new;
		adc_12_old <= adc_12_new;
		adc_13_old <= adc_13_new;
		adc_14_old <= adc_14_new;
		adc_15_old <= adc_15_new;
		adc_16_old <= adc_16_new;
		
		dig_in_val_new <= dig_in_val;
		dig_in_val_old <= dig_in_val_new;

	end


	assign servo_pwm_period[23:0] =  24'h03F7A0;
/*
	wire [35:0] bemf_vel_out;
	reg [35:0] vel_mot_0 = 20'd0;
	reg [35:0] vel_mot_1 = 20'd0;
	reg [35:0] vel_mot_2 = 20'd0;
	reg [35:0] vel_mot_3 = 20'd0;
*/
	reg [9:0] bemf_adc_h = 10'd0;
	reg [9:0] bemf_adc_l = 10'd0;
	reg [1:0] bemf_mot_sel_in = 2'd0;
	reg bemf_in_valid = 1'd0;
	reg [35:0] bemf_in = 36'd0;
	reg [35:0] bemf_calib_in = 36'd0;

	wire [1:0] bemf_mot_sel_out;
	wire bemf_out_valid;
	wire [35:0] bemf_out;

	reg [15:0] bemf_counter = 16'd0; // can count for up to ~20mS
	reg [2:0] bemf_state = 3'd0;
	

	always @(posedge clk3p2M) begin

		if (bemf_out_valid) begin
			case(bemf_mot_sel_out)
			2'd0: begin
				bemf_0_r <= bemf_out;
				//vel_mot_0 <= bemf_vel_out;
			end
			2'd1: begin 
				bemf_1_r <= bemf_out;
				//vel_mot_1 <= bemf_vel_out;
			end
			2'd2: begin
				bemf_2_r <= bemf_out;
				//vel_mot_2 <= bemf_vel_out;
			end
			2'd3: begin
				bemf_3_r <= bemf_out;
				//vel_mot_3 <= bemf_vel_out;
			end
			endcase
		end

		// BEMF: FSM		
		case(bemf_state)		

			
		// Turn all motors off and wait ~600uS +
		3'd0: begin
			bemf_counter <= bemf_counter + 1'd1;
			bemf_in_valid <= 1'd0;
			bemf_sensing_r <= 1'd0;
			
			if (bemf_counter > 3200) // 1mS
				bemf_state <= bemf_state + 1'd1;
			else
				bemf_state <= bemf_state;
		end
		
		// update adc values
		3'd1: begin
			bemf_counter <= bemf_counter + 1'd1;
			bemf_in_valid <= 1'd0;
			bemf_sensing_r <= 1'd1;

			if (bemf_counter > 12800) // 4mS
				bemf_state <= bemf_state + 1'd1;
			else
				bemf_state <= bemf_state;
		end		
		
		// call update bemf_0
		3'd2: begin
			bemf_counter <= bemf_counter + 1'd1;
			bemf_state <= bemf_state + 1'd1;
			bemf_adc_h <= adc_9_in;
			bemf_adc_l <= adc_8_in;
			bemf_mot_sel_in <= 2'd0;
			bemf_in_valid <= 1'd1;
			bemf_in <= bemf_0;
			bemf_sensing_r <= 1'd0;
			bemf_calib_in <= bemf_0_calib;
		end
		
		
		// call update bemf_1
		3'd3: begin
			bemf_counter <= bemf_counter + 1'd1;
			bemf_state <= bemf_state + 1'd1;
			bemf_adc_h <= adc_11_in;
			bemf_adc_l <= adc_10_in;
			bemf_mot_sel_in <= 2'd1;
			bemf_in_valid <= 1'd1;
			bemf_in <= bemf_1;
			bemf_calib_in <= bemf_1_calib;
		end
		
		
		// call update bemf_2
		3'd4: begin
			bemf_counter <= bemf_counter + 1'd1;
			bemf_state <= bemf_state + 1'd1;
			bemf_adc_h <= adc_13_in;
			bemf_adc_l <= adc_12_in;
			bemf_mot_sel_in <= 2'd2;
			bemf_in_valid <= 1'd1;
			bemf_in <= bemf_2;
			bemf_calib_in <= bemf_2_calib;
		end
		
		
		// call update bemf_3
		3'd5: begin
			bemf_counter <= bemf_counter + 1'd1;
			bemf_state <= bemf_state + 1'd1;
			bemf_adc_h <= adc_15_in;
			bemf_adc_l <= adc_14_in;
			bemf_mot_sel_in <= 2'd3;
			bemf_in_valid <= 1'd1;
			bemf_in <= bemf_3;
			bemf_calib_in <= bemf_3_calib;
		end
		
	
		// wait and update bemf registers
		3'd6: begin
			bemf_in_valid <= 1'd0;
			
			if (bemf_counter < 64000) begin
				//bemf_state <= bemf_state + 1'd1;
				bemf_counter <= bemf_counter + 1'd1;
			end else begin
				bemf_state <= 3'd0;
				bemf_counter <= 16'd0;
			end
		end
		
		default: begin
			bemf_state <= 3'd0;
			bemf_sensing_r <= 1'd0;
			bemf_counter <= 16'd0;
		end
		endcase
	end

	bemf_update bemf_single_update(
	 .bemf_adc_h(bemf_adc_h),
    .bemf_adc_l(bemf_adc_l),
    .mot_sel_in(bemf_mot_sel_in),
    .in_valid(bemf_in_valid),
    .bemf_in(bemf_in),
	 .bemf_calib_in(bemf_calib_in),
    .clk(clk3p2M),
    .bemf_out(bemf_out),
	 //.bemf_vel_out(bemf_vel_out),
    .mot_sel_out(bemf_mot_sel_out),
    .out_valid(bemf_out_valid)
	);

	spi pxa_spi (

		// Clocks
		.SYS_CLK(clk208M), 
		.SPI_CLK(FPGA_SCLK), 

		// SPI Wires
		.SSEL(FPGA_SYNC), 
		.MOSI(FPGA_MOSI), 
		.MISO(FPGA_MISO), 

		// Read-Only Registers
		.dig_in_val(dig_in_val_old),
		.adc_0_in(adc_0_old),
		.adc_1_in(adc_1_old),
		.adc_2_in(adc_2_old),
		.adc_3_in(adc_3_old),
		.adc_4_in(adc_4_old),
		.adc_5_in(adc_5_old),
		.adc_6_in(adc_6_old),
		.adc_7_in(adc_7_old),
		.adc_8_in(adc_8_old),
		.adc_9_in(adc_9_old),
		.adc_10_in(adc_10_old),
		.adc_11_in(adc_11_old),
		.adc_12_in(adc_12_old),
		.adc_13_in(adc_13_old),
		.adc_14_in(adc_14_old),
		.adc_15_in(adc_15_old),
		.adc_16_in(adc_16_old),
		.charge_acp_in(CHG_ACP),
		.bemf_0(bemf_0_r_208M[35:4]),
	   .bemf_1(bemf_1_r_208M[35:4]),
		.bemf_2(bemf_2_r_208M[35:4]),
		.bemf_3(bemf_3_r_208M[35:4]),
		.servo_pwm0_high(servo_pwm0_old),
		.servo_pwm1_high(servo_pwm1_old),
		.servo_pwm2_high(servo_pwm2_old),
		.servo_pwm3_high(servo_pwm3_old),
		.dig_out_val(dig_out_val_old),
		.dig_pu(dig_pu_old),
		.dig_oe(dig_oe_old),
		.ana_pu(ana_pu_old),
		.mot_duty0(mot_duty0_old),
		.mot_duty1(mot_duty1_old),
		.mot_duty2(mot_duty2_old),
		.mot_duty3(mot_duty3_old),
		//.dig_sample(dig_sample_old),
		//.dig_update(dig_update_old),
		.mot_drive_code(mot_drive_code_old),
		.mot_allstop(mot_allstop_old),
		.side_button(side_button_old),

		.servo_pwm0_high_new(servo_pwm0_new),
		.servo_pwm1_high_new(servo_pwm1_new),
		.servo_pwm2_high_new(servo_pwm2_new),
		.servo_pwm3_high_new(servo_pwm3_new),
		.dig_out_val_new(dig_out_val_new),
		.dig_pu_new(dig_pu_new),
		.dig_oe_new(dig_oe_new),
		.ana_pu_new(ana_pu_new),
		.mot_duty0_new(mot_duty0_new),
		.mot_duty1_new(mot_duty1_new),
		.mot_duty2_new(mot_duty2_new),
		.mot_duty3_new(mot_duty3_new),
		//.dig_sample_new(dig_sample_new),
		//.dig_update_new(dig_update_new),
		.mot_drive_code_new(mot_drive_code_new),
		.mot_allstop_new(mot_allstop_new)
	);

	quad_motor motor_controller (
		.clk(clk26buf),
		.MOT_EN(!mot_allstop[0]),
		.duty0(mot_duty0[11:0]),
		.duty1(mot_duty1[11:0]),
		.duty2(mot_duty2[11:0]),
		.duty3(mot_duty3[11:0]),
		.drive_code(mot_drive_code),
		.bemf_sensing(bemf_sensing),
		.pwm(MOT_PWM),
		.MBOT(MBOT[3:0]),
		.MTOP(MTOP[3:0])
	);

	auto_adc_updater adc_updater(
		.clk3p2M(clk3p2M),
		.adc_in(adc_in),
		.adc_valid(adc_valid),
		.bemf_sensing(bemf_sensing),
		.adc_go(adc_go),
		.adc_chan(adc_chan),
		.adc_0_in(adc_0_in),
		.adc_1_in(adc_1_in),
		.adc_2_in(adc_2_in),
		.adc_3_in(adc_3_in),
		.adc_4_in(adc_4_in),
		.adc_5_in(adc_5_in),
		.adc_6_in(adc_6_in),
		.adc_7_in(adc_7_in),
		.adc_8_in(adc_8_in),
		.adc_9_in(adc_9_in),
		.adc_10_in(adc_10_in),
		.adc_11_in(adc_11_in),
		.adc_12_in(adc_12_in),
		.adc_13_in(adc_13_in),
		.adc_14_in(adc_14_in),
		.adc_15_in(adc_15_in),
		.adc_16_in(adc_16_in),
		.adc_batt_sel(ADC_BATT_SEL)
    );


   reg [3:0] m_servo_out;
   wire [3:0] m_servo_out_r;

	always @ (posedge clk26buf) begin
		m_servo_out <= m_servo_out_r;
	end
	
   servo_pwm servo0_chan (
		.clk(clk13buf),
		.period(servo_pwm_period),
		.pulse(servo0_pwm_pulse),
		.pwm_output(m_servo_out_r[0])
	);

   servo_pwm servo1_chan (
		.clk(clk13buf),
		.period(servo_pwm_period),
		.pulse(servo1_pwm_pulse),
		.pwm_output(m_servo_out_r[1])
	);

   servo_pwm servo2_chan (
		.clk(clk13buf),
		.period(servo_pwm_period),
		.pulse(servo2_pwm_pulse),
		.pwm_output(m_servo_out_r[2])
	);

   servo_pwm servo3_chan (
		.clk(clk13buf),
		.period(servo_pwm_period),
		.pulse(servo3_pwm_pulse),
		.pwm_output(m_servo_out_r[3])
	);

	assign M_SERVO[0] = mot_allstop[1] & !m_servo_out[0];
	assign M_SERVO[1] = mot_allstop[2] & !m_servo_out[1];
	assign M_SERVO[2] = mot_allstop[3] & !m_servo_out[2];
	assign M_SERVO[3] = mot_allstop[4] & !m_servo_out[3];

	
	
	reg [2:0] dig_update_state = 2'd0; 
	reg [11:0] dig_update_counter = 16'd0;
	
	always @(posedge clk3p2M) begin
	
		case(dig_update_state)
			// update = 1
			2'd0: begin
				if (dig_update_counter > 200) begin
					dig_update_state <= dig_update_state + 2'd1;
				end else begin
					dig_update_state <= dig_update_state;
				end
				
				dig_update_new <= 1'd1;
				dig_update_counter <= dig_update_counter + 12'd1;
			end
			
			// update = 0
			2'd1: begin
				if (dig_update_counter > 300) begin
					dig_update_state <= dig_update_state + 2'd1;
				end else begin
					dig_update_state <= dig_update_state;				
				end
				dig_update_new <= 1'd0;
				dig_update_counter <= dig_update_counter + 12'd1;
			end
			
			// sample = 0
			2'd2: begin
				if (dig_update_counter > 400) begin
					dig_update_state <= dig_update_state + 2'd1;
				end else begin
					dig_update_state <= dig_update_state;				
				end
				dig_sample_new <= 1'd0;
				dig_update_counter <= dig_update_counter + 12'd1;
			end
			
			// sample = 1
			2'd3: begin
			
				if (dig_update_counter > 3200) begin 
					dig_update_state <= 2'd0;
					dig_update_counter <= 12'd0;
				end else begin
					dig_update_counter <= dig_update_counter + 12'd1;
					dig_update_state <= 2'd0;
				end
				
				dig_sample_new <= 1'd1;
			end
			
		endcase
	end
	
	
	
   robot_iface iface(
		.clk(clk13buf),		
		.clk_3p2MHz(clk3p2M), 
		.glbl_reset(1'b0), //.glbl_reset(glbl_reset),
		
		// digital i/o block
		.dig_out_val(dig_out_val),
		.dig_oe(dig_oe),
		.dig_pu(dig_pu),
		.ana_pu(ana_pu),
		.dig_in_val(dig_in_val),
		.dig_sample(dig_sample),  // samples input on rising edge
		.dig_update(dig_update),  // updates chain on rising edge

		// ADC interface
		.adc_in(adc_in),
		.adc_chan(adc_chan),    // ch 0-7 for user, 8-15 for mot current fbk
		.adc_valid(adc_valid),
		.adc_go(adc_go),  

		// analog interface
		.DIG_ADC_CS(DIG_ADC_CS),
		.DIG_ADC_IN(DIG_ADC_IN),
		.DIG_ADC_OUT(DIG_ADC_OUT),
		.DIG_ADC_SCLK(DIG_ADC_SCLK),

		// digital interface
		.DIG_IN(DIG_IN),
		.DIG_OUT(DIG_OUT),
		.DIG_RCLK(DIG_RCLK),
		.DIG_SAMPLE(DIG_SAMPLE),
		.DIG_SCLK(DIG_SCLK),
		.DIG_SRLOAD(DIG_SRLOAD),
		.DIG_CLR_N(DIG_CLR_N)
	);

endmodule // kovan
