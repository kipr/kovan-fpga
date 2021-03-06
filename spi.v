`timescale 1ns / 1ps



module spi(
SYS_CLK, 
SPI_CLK, 
SSEL, 
MOSI, 
MISO,
dig_in_val, 
adc_0_in, 
adc_1_in,
adc_2_in,
adc_3_in,
adc_4_in,
adc_5_in,
adc_6_in,
adc_7_in,
adc_8_in,
adc_9_in,
adc_10_in,
adc_11_in,
adc_12_in,
adc_13_in,
adc_14_in,
adc_15_in,
adc_16_in,
charge_acp_in,
bemf_0,
bemf_1,
bemf_2,
bemf_3,
servo_pwm0_low,
servo_pwm1_low,
servo_pwm2_low,
servo_pwm3_low,
dig_out_val,
dig_pu,
dig_oe,
ana_pu,
mot_duty0,
mot_duty1,
mot_duty2,
mot_duty3,
mot_drive_code,
mot_allstop,
side_button,
	
servo_pwm0_low_new,
servo_pwm1_low_new,
servo_pwm2_low_new,
servo_pwm3_low_new,
dig_out_val_new,
dig_pu_new,
dig_oe_new,
ana_pu_new,
mot_duty0_new,
mot_duty1_new,
mot_duty2_new,
mot_duty3_new,
mot_drive_code_new,
mot_allstop_new,
mot_bemf_clear_new
);


	// NOTE: Do not change these here
	// change the *_DEFAULT parameters in kovan.v
	parameter SERVO_PWM0_LOW_START = 16'd0;
	parameter SERVO_PWM1_LOW_START = 16'd0;
	parameter SERVO_PWM2_LOW_START = 16'd0;
	parameter SERVO_PWM3_LOW_START = 16'd0;
	parameter DIG_OUT_VAL_START = 8'd0;
	parameter DIG_PU_START = 8'hFF;
	parameter DIG_OE_START = 8'd0;
	parameter ANA_PU_START = 8'hFF;
	parameter MOT_DUTY0_START = 12'd0;
	parameter MOT_DUTY1_START = 12'd0;
	parameter MOT_DUTY2_START = 12'd0;
	parameter MOT_DUTY3_START = 12'd0;
	parameter MOT_DRIVE_CODE_START = 8'd0;
	parameter MOT_ALLSTOP_START = 5'd0;
	parameter MOT_BEMF_CLEAR_START = 4'd0;

	input		SYS_CLK;
	input		SPI_CLK;
	input		SSEL;
	input		MOSI;
	output	MISO;

	input [7:0] dig_in_val;
	input [9:0] adc_0_in;
	input [9:0] adc_1_in;
	input [9:0] adc_2_in;
	input [9:0] adc_3_in;
	input [9:0] adc_4_in;
	input [9:0] adc_5_in;
	input [9:0] adc_6_in;
	input [9:0] adc_7_in;
	input [9:0] adc_8_in;
	input [9:0] adc_9_in;
	input [9:0] adc_10_in;
	input [9:0] adc_11_in;
	input [9:0] adc_12_in;
	input [9:0] adc_13_in;
	input [9:0] adc_14_in;
	input [9:0] adc_15_in;
	input [9:0] adc_16_in;
	input [0:0] charge_acp_in;
	input [31:0] bemf_0;
	input [31:0] bemf_1;
	input [31:0] bemf_2;
	input [31:0] bemf_3;
	input [15:0] servo_pwm0_low;
	input [15:0] servo_pwm1_low;
	input [15:0] servo_pwm2_low;
	input [15:0] servo_pwm3_low;
	input [7:0] dig_out_val;
	input [7:0] dig_pu;
	input [7:0] dig_oe;
	input [7:0] ana_pu;
	input [11:0] mot_duty0;
	input [11:0] mot_duty1;
	input [11:0] mot_duty2;
	input [11:0] mot_duty3;
	input [7:0] mot_drive_code;
	input [4:0] mot_allstop;
	input [0:0] side_button;
	

	output reg [15:0] servo_pwm0_low_new = SERVO_PWM0_LOW_START;
	output reg [15:0] servo_pwm1_low_new = SERVO_PWM1_LOW_START;
	output reg [15:0] servo_pwm2_low_new = SERVO_PWM2_LOW_START;
	output reg [15:0] servo_pwm3_low_new = SERVO_PWM3_LOW_START;
	output reg [7:0] dig_out_val_new = DIG_OUT_VAL_START;
	output reg [7:0] dig_pu_new = DIG_PU_START;
	output reg [7:0] dig_oe_new = DIG_OE_START;
	output reg [7:0] ana_pu_new = ANA_PU_START;
	output reg [11:0] mot_duty0_new = MOT_DUTY0_START;
	output reg [11:0] mot_duty1_new = MOT_DUTY1_START;
	output reg [11:0] mot_duty2_new = MOT_DUTY2_START;
	output reg [11:0] mot_duty3_new = MOT_DUTY3_START;
	output reg [7:0] mot_drive_code_new = MOT_DRIVE_CODE_START;
	output reg [4:0] mot_allstop_new = MOT_ALLSTOP_START;
	output reg [3:0] mot_bemf_clear_new = MOT_BEMF_CLEAR_START;

	
	
	reg [2:0] SCKr; // SPI Clock
	reg [2:0] SSELr; // Slave Selec	
	reg [1:0] MOSIr; // Master-Out Slave-In
	reg [15:0] SPI_OUTr;
	reg [15:0] SPI_OUT_tmp;
	//reg [1039:0] SPI_REGr = 1040'd0;
	//reg [1039:384] COMMAND_REGr = {560'd0, 16'd76, 16'd76, 16'd76, 16'd76, 16'h6677};
	
	reg [1:0] state = 2'b00;
	reg [9:0] address = 10'b00;

	wire SCK_rising_edge = (SCKr[2:1] == 2'b01);
	wire SCK_falling_edge = (SCKr[2:1] == 2'b10);
	wire SSEL_active = ~SSELr[1]; // Active LOW Slave Select
	wire SSEL_start_msg = (SSELr[2:1] == 2'b10);
	wire SSEL_stop_msg  = (SSELr[2:1] == 2'b01); 
	wire MOSI_data = MOSIr[1];

	reg [3:0] bitcnt;	
	reg byte_received; // high when a byte is received
	reg [15:0] byte_data_received;	
	reg [15:0] byte_data_sent;
	
	// our only electrical output
	assign MISO = byte_data_sent[15];
//	assign COMMAND_REG = COMMAND_REGr;

	// latch inputs
	always @(posedge SYS_CLK) begin
		SCKr <= {SCKr[1:0], SPI_CLK};
		SSELr <= {SSELr[1:0], SSEL};
		MOSIr <= {MOSIr[0], MOSI};
		//SPI_REGr[1039:0] <= SPI_REG[1039:0]; // TODO?
	end
	
	
	///// Receiving data
	always @(posedge SYS_CLK) begin
	
		if (~SSEL_active)
			bitcnt <= 4'b0000;
		else if (SCK_falling_edge) begin
			bitcnt <= bitcnt + 4'b0001;
			byte_data_received <= {byte_data_received[14:0], MOSI_data};// MSb 1st
		end
		
		byte_received <= SSEL_active && (bitcnt==4'b1111) &&  SCK_falling_edge;


			case(address)
					10'd0: 	SPI_OUT_tmp <= 16'h4A53;//SPI_REGr[15:0];  //JS
					10'd1: 	SPI_OUT_tmp <= {8'd0, dig_in_val[7:0]};
					10'd2: 	SPI_OUT_tmp <= {6'd0, adc_0_in[9:0]};
					10'd3: 	SPI_OUT_tmp <= {6'd0, adc_1_in[9:0]};
					10'd4: 	SPI_OUT_tmp <= {6'd0, adc_2_in[9:0]};
					10'd5: 	SPI_OUT_tmp <= {6'd0, adc_3_in[9:0]};
					10'd6: 	SPI_OUT_tmp <= {6'd0, adc_4_in[9:0]};
					10'd7: 	SPI_OUT_tmp <= {6'd0, adc_5_in[9:0]};
					10'd8: 	SPI_OUT_tmp <= {6'd0, adc_6_in[9:0]};
					10'd9: 	SPI_OUT_tmp <= {6'd0, adc_7_in[9:0]};
					10'd10: 	SPI_OUT_tmp <= {6'd0, adc_8_in[9:0]};
					10'd11: 	SPI_OUT_tmp <= {6'd0, adc_9_in[9:0]};
					10'd12: 	SPI_OUT_tmp <= {6'd0, adc_10_in[9:0]};
					10'd13: 	SPI_OUT_tmp <= {6'd0, adc_11_in[9:0]};
					10'd14: 	SPI_OUT_tmp <= {6'd0, adc_12_in[9:0]};
					10'd15: 	SPI_OUT_tmp <= {6'd0, adc_13_in[9:0]};
					10'd16: 	SPI_OUT_tmp <= {6'd0, adc_14_in[9:0]};
					10'd17: 	SPI_OUT_tmp <= {6'd0, adc_15_in[9:0]};
					10'd18: 	SPI_OUT_tmp <= {6'd0, adc_16_in[9:0]};
					10'd19:	SPI_OUT_tmp <= {15'd0, charge_acp_in};
					10'd20:	SPI_OUT_tmp <= bemf_0[15:0];
					10'd21:	SPI_OUT_tmp <= bemf_1[15:0];
					10'd22:	SPI_OUT_tmp <= bemf_2[15:0];
					10'd23:	SPI_OUT_tmp <= bemf_3[15:0];
					//10'd24: 
					10'd25: 	SPI_OUT_tmp <= servo_pwm0_low;
					10'd26: 	SPI_OUT_tmp <= servo_pwm1_low;
					10'd27: 	SPI_OUT_tmp <= servo_pwm2_low;
					10'd28: 	SPI_OUT_tmp <= servo_pwm3_low;
					10'd29: 	SPI_OUT_tmp <= {8'd0, dig_out_val};
					10'd30: 	SPI_OUT_tmp <= {8'd0, dig_pu};
					10'd31: 	SPI_OUT_tmp <= {8'd0, dig_oe};
					10'd32: 	SPI_OUT_tmp <= {8'd0, ana_pu};
					10'd33: 	SPI_OUT_tmp <= {4'd0, mot_duty0};
					10'd34: 	SPI_OUT_tmp <= {4'd0, mot_duty1};
					10'd35: 	SPI_OUT_tmp <= {4'd0, mot_duty2};
					10'd36: 	SPI_OUT_tmp <= {4'd0, mot_duty3};
					//10'd37:
					//10'd38: 
					10'd39: 	SPI_OUT_tmp <= {8'd0, mot_drive_code};
					10'd40: 	SPI_OUT_tmp <= {11'd0, mot_allstop};
					10'd41:	SPI_OUT_tmp <= bemf_0[31:16];
					10'd42:	SPI_OUT_tmp <= bemf_1[31:16];
					10'd43:	SPI_OUT_tmp <= bemf_2[31:16];
					10'd44:	SPI_OUT_tmp <= bemf_3[31:16];
					10'd45:	SPI_OUT_tmp <= {15'd0, side_button};
					//10'd41:
					//10'd42:
					//10'd43:
					//10'd44:
					//10'd45:		
				
					default: SPI_OUT_tmp <= 16'd0;
				endcase
					

		if(byte_received) begin


			SPI_OUTr <= SPI_OUT_tmp;

			case(state[1:0])
				2'b10: begin // read
					state[1:0] <=  byte_data_received[15:14];
				
	
					
					if (byte_data_received[15:14] == 2'b01)
						// transition to write
						address[9:0] <= byte_data_received[9:0];
					else
						// read next reg
						address <= address + 10'd1;


				end
				
				2'b01: begin // write
					state[1:0] <= 2'b00; // single write for now, go back to undef state
					address <= 10'd0;
							
					servo_pwm0_low_new 	<= (address == 10'd25) ? byte_data_received[15:0]	: servo_pwm0_low;
					servo_pwm1_low_new 	<= (address == 10'd26) ? byte_data_received[15:0]	: servo_pwm1_low;
					servo_pwm2_low_new 	<= (address == 10'd27) ? byte_data_received[15:0]	: servo_pwm2_low;
					servo_pwm3_low_new 	<= (address == 10'd28) ? byte_data_received[15:0]	: servo_pwm3_low;
					dig_out_val_new 		<= (address == 10'd29) ? byte_data_received[7:0] 	: dig_out_val;
					dig_pu_new 				<= (address == 10'd30) ? byte_data_received[7:0] 	: dig_pu;
					dig_oe_new				<= (address == 10'd31) ? byte_data_received[7:0] 	: dig_oe;
					ana_pu_new 				<= (address == 10'd32) ? byte_data_received[7:0] 	: ana_pu;
					mot_duty0_new 			<= (address == 10'd33) ? byte_data_received[11:0] 	: mot_duty0; 
					mot_duty1_new 			<= (address == 10'd34) ? byte_data_received[11:0] 	: mot_duty1;
					mot_duty2_new 			<= (address == 10'd35) ? byte_data_received[11:0] 	: mot_duty2;
					mot_duty3_new 			<= (address == 10'd36) ? byte_data_received[11:0] 	: mot_duty3;
					//dig_sample_new 		<= (address == 10'd37) ? byte_data_received[0:0] 	: dig_sample;
					//dig_update_new 		<= (address == 10'd38) ? byte_data_received[0:0] 	: dig_update;
					mot_drive_code_new 	<= (address == 10'd39) ? byte_data_received[7:0] 	: mot_drive_code;
					mot_allstop_new 		<= (address == 10'd40) ? byte_data_received[4:0] 	: mot_allstop;
					//pid_p_goal_0_new		<= (address == 10'd41) ? byte_data_received[15:0]	: pid_p_goal_0;
					//pid_p_goal_1_new		<= (address == 10'd42) ? byte_data_received[15:0]	: pid_p_goal_1;
					//pid_p_goal_2_new		<= (address == 10'd43) ? byte_data_received[15:0]	: pid_p_goal_2;
					//pid_p_goal_3_new		<= (address == 10'd44) ? byte_data_received[15:0]	: pid_p_goal_3;
					mot_bemf_clear_new	<= (address == 10'd46) ? byte_data_received[3:0] : 4'd0;
		
				end
			
				default: begin // undefined
					state[1:0] <= byte_data_received[15:14];
					
					if (byte_data_received[15:14] == 2'b10) begin
						// transition to read
						address[9:0] <= 10'd1; // already queued reg 0, reg 1 is next
					end else if (byte_data_received[15:14] == 2'b01) begin
						// transition to write
						address[9:0] <= byte_data_received[9:0];
					end
					
				end
			endcase
		end
	end	
	
	
	/////	Sending data
	always @(posedge SYS_CLK) begin

		if (SSEL_start_msg)
				byte_data_sent <= SPI_OUTr;
		else if (SCK_rising_edge) begin
			if (bitcnt == 4'b0000)
				byte_data_sent <= 16'h0000;
			else
				byte_data_sent <= {byte_data_sent[14:0], 1'b0};
		end
	end
	
endmodule
