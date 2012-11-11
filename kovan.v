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

parameter C3_NUM_DQ_PINS          = 16;   // External memory data width
parameter C3_MEM_ADDR_WIDTH       = 13;   // External memory address width
parameter C3_MEM_BANKADDR_WIDTH   = 3;    // External memory bank address width

// `define HAS_DDR    // comment out to remove DDR interface (does not currently work)

module kovan (
	      // camera IF
	      output wire [7:0] CAM_D,
	      output wire       CAM_HSYNC,  // sync
	      output wire       CAM_VSYNC,  // pix valid / hsync
	      input wire        CAM_MCLKO,  // pixel master clock
	      input wire        CAM_VCLKO,  // pixel clock from CPU
	      output wire       CAM_PCLKI,  // return pixel clock

	      // power management
	      input wire CHG_ACP,           // reports presence of AC power
//	      output wire CHG_SHDN,         // leave floating


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
	      output wire       MOT_EN,
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
	      input wire [5:0]  LCD_SUPP,
	      input wire        LCD_VS,
	      output wire       LCD_CLK_T,  // clock is sourced from the FPGA
	      // for forward compatibility with HDMI-synced streams

	      // SSP interface to the CPU
	      output wire       FPGA_MISO,
	      input wire        FPGA_MOSI,
	      input wire        FPGA_SCLK,
	      input wire        FPGA_SYNC,

	      // I2C interfaces
	      input wire        PWR_SCL,  // we listen on this one
	      inout wire        PWR_SDA,

	      input wire        XI2CSCL,  // our primary interface
	      inout wire        XI2CSDA,

	      // LED
	      output wire       FPGA_LED,

	      
	      input wire       OSC_CLK   // 26 mhz clock from CPU
	      );

   ///////// clock buffers
   wire            clk26;
   wire 	   clk26ibuf;
   wire 	   clk26buf;
   wire 	   clk13buf;
   wire            clk3p2M;
   wire 	   clk208M;
   wire            clk1M;  // wired up in the serial number section
   
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
	
	
	//assign FPGA_MISO = FPGA_MOSI; // loopback testing
	wire [15:0] SPI_OUT;
	reg [63:0][15:0] DATA_REG;
	wire [63:0][15:0] COMMAND_REG;

	// Instantiate the spi link to the pxa166 processor
	spi pxa_spi (
		.SYS_CLK(clk208M), 
		.SPI_CLK(FPGA_SCLK), 
		.SSEL(FPGA_SYNC), 
		.MOSI(FPGA_MOSI), 
		.MISO(FPGA_MISO), 
		.SPI_OUT(SPI_OUT),
		.DATA_REG(DATA_REG),
		.COMMAND_REG(COMMAND_REG)
	);

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
   wire [3:0] adc_chan;
   wire       adc_valid;
   wire       adc_go;

   wire [15:0] mot_pwm_div;
   wire [15:0] mot_pwm_duty;
   wire [7:0]  mot_drive_code;
   wire        mot_allstop;

   wire [23:0] servo_pwm_period;
   wire [23:0] servo0_pwm_pulse;
   wire [23:0] servo1_pwm_pulse;
   wire [23:0] servo2_pwm_pulse;
   wire [23:0] servo3_pwm_pulse;
	
	
   reg [55:0] dna_data;

   robot_iface iface(.clk(clk13buf), .glbl_reset(glbl_reset),
		     .clk_3p2MHz(clk3p2M), .clk_208MHz(clk208M),

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
	     .adc_chan(adc_chan),    // channels 0-7 are for user, 8-15 are for motor current fbk
	     .adc_valid(adc_valid),
	     .adc_go(adc_go),  

	     // motor driver interface
	     .mot_pwm_div(mot_pwm_div),
	     .mot_pwm_duty(mot_pwm_duty),
	     .mot_drive_code(mot_drive_code), // 2 bits/chan, 00 = stop, 01 = forward, 10 = rev, 11 = stop
	     .mot_allstop(mot_allstop),

	     // servo interface
	     .servo_pwm_period(servo_pwm_period), // total period for the servo update
	     .servo0_pwm_pulse(servo0_pwm_pulse), // pulse width in absolute time
	     .servo1_pwm_pulse(servo1_pwm_pulse),
	     .servo2_pwm_pulse(servo2_pwm_pulse),
	     .servo3_pwm_pulse(servo3_pwm_pulse),

	     /////// physical interfaces to outside the chip
	     // motors
	     .MBOT(MBOT[3:0]),
	     .MTOP(MTOP[3:0]),
	     .MOT_EN(MOT_EN),
	     .M_SERVO(M_SERVO[3:0]),

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
   
   
  
   ////////////////////////////////
   // heartbeat
   ////////////////////////////////
   pwm heartbeat(.clk812k(clk1M), .pwmout(blue_led),
		 .bright(12'b0001_1111_1000), .dim(12'b0000_0000_1000) );

   assign FPGA_LED = !blue_led;

   
   assign CAM_PCLKI = 1'b0;
   assign CAM_HSYNC = 1'b0;
   assign CAM_VSYNC = 1'b0;
   //assign FPGA_MISO = 1'b0;
   assign CAM_D[7:0] = 8'b0;
//   assign CHG_SHDN = 1'b0; // leave floating as on-board pulldown does the trick

endmodule // kovan
