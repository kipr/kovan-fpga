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

	// power management
	input wire CHG_ACP,           // reports presence of AC power
	//output wire CHG_SHDN,         // leave floating


	// i/o controller digital interfaces
	output wire [1:0] DIG_ADC_CS,
	output wire       DIG_ADC_IN,
	input wire        DIG_ADC_OUT,
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

	// optional uart to outside world
	input wire        EXT_TO_HOST_UART, // for now we're a fly on the wall
	input wire        HOST_TO_EXT_UART,

	// infrared receiver 
	input wire        IR_RX,

	// switch
	input wire        INPUT_SW0,

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
	input wire [5:0]  LCD_B,  // note no truncation of data in
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

	// I2C interfaces
	input wire        PWR_SCL,  // we listen on this one
	inout wire        PWR_SDA,

	// LED
	output wire       FPGA_LED,
	
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
   wire		clk1M;  // wired up in the serial number section
   
   assign clk26 = OSC_CLK;
   IBUFG clk26buf_ibuf(.I(clk26), .O(clk26ibuf));
   BUFG clk26buf_buf (.I(clk26ibuf), .O(clk26buf));

   
   ////////// reset
   reg   	   glbl_reset; // to be used sparingly
   wire            glbl_reset_edge;
   reg 		   glbl_reset_edge_d;

   always @(posedge clk1M) begin
      glbl_reset_edge_d <= glbl_reset_edge;
      glbl_reset <= !glbl_reset_edge_d & glbl_reset_edge; // just pulse reset for one cycle of the slowest clock in the system
   end
   
   ////////// loop-throughs
   // lcd runs at a target of 6.41 MHz (156 ns cycle time)
   // i.e., 408 x 262 x 60 Hz (408 is total H width, 320 active, etc.)
   wire            qvga_clkgen_locked;
   
   clk_wiz_v3_2_qvga qvga_clkgen( .CLK_IN1(clk26buf),
				  .clk_out6p4(clk_qvga),
				  .clk_out13(clk13buf),
				  .clk_out3p25(clk3p2M), // note: a slight overclock (about 2%)
				  .clk_out208(clk208M),
				  .RESET(glbl_reset),
				  .LOCKED(qvga_clkgen_locked) );
   
   reg 	[5:0]	   lcd_pipe_b;
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
			  .glbl_reset(glbl_reset || !qvga_clkgen_locked),
			  .reset(lcd_reset) );
			  
   always @(posedge clk_qvga) begin
      // TODO: assign timing constraints to ensure hold times met for LCD
      lcd_pipe_b[5:0] <= LCD_B[5:0];
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

   wire [9:0] adc_in;
   //wire [3:0] adc_chan;
   wire       adc_valid;
   wire       adc_go;

   wire [11:0] mot_duty0;
	wire [11:0] mot_duty1;
	wire [11:0] mot_duty2;   
	wire [11:0] mot_duty3;

   wire [7:0]  mot_drive_code;
   wire        mot_allstop;

   wire [23:0] servo_pwm_period;
   wire [23:0] servo0_pwm_pulse;
   wire [23:0] servo1_pwm_pulse;
   wire [23:0] servo2_pwm_pulse;
   wire [23:0] servo3_pwm_pulse;
	
	
	
	// neutral servo positions at startup
	reg [687:0] SPI_REG = 688'd0;
	reg [687:0] SPI_REG_p = 688'd0;
	
	wire [687:384] COMMAND_REG;

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

	reg [11:0] mot_duty0_r = 12'd0;
	reg [11:0] mot_duty1_r = 12'd0;
	reg [11:0] mot_duty2_r = 12'd0;
	reg [11:0] mot_duty3_r = 12'd0;
	
	reg [23:0] servo_pwm0_r = 24'd0;
	reg [23:0] servo_pwm1_r = 24'd0;
	reg [23:0] servo_pwm2_r = 24'd0;
	reg [23:0] servo_pwm3_r = 24'd0;
	
	assign mot_duty0 = mot_duty0_r;
	assign mot_duty1 = mot_duty1_r;
	assign mot_duty2 = mot_duty2_r;
	assign mot_duty3 = mot_duty3_r;

	assign servo0_pwm_pulse = servo_pwm0_r;
	assign servo1_pwm_pulse = servo_pwm1_r;
	assign servo2_pwm_pulse = servo_pwm2_r;
	assign servo3_pwm_pulse = servo_pwm3_r;

	
	always @(posedge clk208M) begin
	
		SPI_REG[15:0] <= 16'h4A53;				
		SPI_REG[687:16] <= SPI_REG_p[687:16];

		SPI_REG_p[31:16] <= {8'h00, dig_out_val};	// r01
		SPI_REG_p[41:32]   <= adc_0_in[9:0];			// r02
		SPI_REG_p[57:48]   <= adc_1_in[9:0];			// r03
		SPI_REG_p[73:64]   <= adc_2_in[9:0];			// r04
		SPI_REG_p[89:80]   <= adc_3_in[9:0];			// r05
		SPI_REG_p[105:96]  <= adc_4_in[9:0];			// r06
		SPI_REG_p[121:112] <= adc_5_in[9:0];			// r07
		SPI_REG_p[137:128] <= adc_6_in[9:0];			// r08
		SPI_REG_p[153:144] <= adc_7_in[9:0];			// r09
		SPI_REG_p[169:160] <= adc_8_in[9:0];			// r10
		SPI_REG_p[185:176] <= adc_9_in[9:0];			// r11
		SPI_REG_p[201:192] <= adc_10_in[9:0];			// r12
		SPI_REG_p[217:208] <= adc_11_in[9:0];			// r13
		SPI_REG_p[233:224] <= adc_12_in[9:0];			// r14
		SPI_REG_p[249:240] <= adc_13_in[9:0];			// r15
		SPI_REG_p[265:256] <= adc_14_in[9:0];			// r16
		SPI_REG_p[281:272] <= adc_15_in[9:0];			// r17
		SPI_REG_p[297:288] <= adc_16_in[9:0];			// r18
		servo_pwm0_r[23:8] <= SPI_REG[415:400];	// r25
		servo_pwm1_r[23:8] <= SPI_REG[431:416];	// r26
		servo_pwm2_r[23:8] <= SPI_REG[447:432];	// r27
		servo_pwm3_r[23:8] <= SPI_REG[463:448];	// r28
		dig_out_val_r <= SPI_REG[471:464];	// r29
		
		SPI_REG_p[687:384] <= COMMAND_REG[687:384];//COMMAND_REG[1023:384];
	end	
		
	
	always @(posedge clk26buf) begin
		mot_duty0_r[11:0] <= SPI_REG[539:528];			// r33
		mot_duty1_r[11:0] <= SPI_REG[555:544];			// r34
		mot_duty2_r[11:0] <= SPI_REG[571:560];			// r35
		mot_duty3_r[11:0] <= SPI_REG[587:576];			// r36	

	end


	assign dig_out_val[7:0] = dig_out_val_r[7:0];   	// pipeline
	assign dig_pu[7:0] = SPI_REG[487:480];					// r30
	assign dig_oe[7:0] = SPI_REG[503:496];					// r31
	assign ana_pu[7:0] = SPI_REG[519:512];					// r32
	assign servo_pwm_period[23:0] =  24'h03F7A0;
	
	assign dig_sample = SPI_REG[592];// r37
	assign dig_update = SPI_REG[608];// r38				
	assign mot_drive_code[7:0] = SPI_REG[631:624];	// r39
	assign mot_allstop = SPI_REG[640];	// r40
	
	wire [3:0] adc_chan;
		
	spi pxa_spi (
		.SYS_CLK(clk208M), 
		.SPI_CLK(FPGA_SCLK), 
		.SSEL(FPGA_SYNC), 
		.MOSI(FPGA_MOSI), 
		.MISO(FPGA_MISO), 
		.SPI_REG(SPI_REG),
		.COMMAND_REG(COMMAND_REG)
	);


	quad_motor motor_controller (
		.clk(clk26buf),
		.MOT_EN(!mot_all_stop),
		.duty0(mot_duty0),
		.duty1(mot_duty1),
		.duty2(mot_duty2),
		.duty3(mot_duty3),
		.drive_code(mot_drive_code),
		.pwm(MOT_PWM),
		.MBOT(MBOT[3:0]),
		.MTOP(MTOP[3:0])
	);

	auto_adc_updater adc_updater(
		.clk3p2M(clk3p2M),
		.adc_in(adc_in),
		.adc_valid(adc_valid),
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

   assign M_SERVO[0] = !m_servo_out[0]; // invert to compensate inverting level converters
   assign M_SERVO[1] = !m_servo_out[1];
   assign M_SERVO[2] = !m_servo_out[2];
   assign M_SERVO[3] = !m_servo_out[3];

	
   robot_iface iface(
		.clk(clk13buf), 
		.glbl_reset(glbl_reset),
		.clk_3p2MHz(clk3p2M), 
		.clk_208MHz(clk208M),

		// digital i/o block
		.dig_out_val(dig_out_val),
		.dig_oe(dig_oe),
		.dig_pu(dig_pu),
		.ana_pu(ana_pu),
		.dig_in_val(dig_in_val),
		.dig_val_good(dig_val_good), // output value is valid when high
		.dig_busy(dig_busy),    // chain is busy when high
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
 
	pwm heartbeat(
		.clk812k(clk1M), 
		.pwmout(blue_led),
		.bright(12'b0001_1111_1000), 
		.dim(12'b0000_0000_1000) 
	);

   assign FPGA_LED = !blue_led;

endmodule // kovan
