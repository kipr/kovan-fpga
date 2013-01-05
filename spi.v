`timescale 1ns / 1ps

module spi(
	input		SYS_CLK,
	input		SPI_CLK,
	input		SSEL,
	input		MOSI,
	output	MISO,
	//input [1039:0] SPI_REG,
	//output [1039:384] COMMAND_REG
	//r0 //JS
	input [7:0] dig_in_val,
	input [9:0] adc_0_in,
	input [9:0] adc_1_in,
	input [9:0] adc_2_in,
	input [9:0] adc_3_in,
	input [9:0] adc_4_in,
	input [9:0] adc_5_in,
	input [9:0] adc_6_in,
	input [9:0] adc_7_in,
	input [9:0] adc_8_in,
	input [9:0] adc_9_in,
	input [9:0] adc_10_in,
	input [9:0] adc_11_in,
	input [9:0] adc_12_in,
	input [9:0] adc_13_in,
	input [9:0] adc_14_in,
	input [9:0] adc_15_in,
	input [9:0] adc_16_in,
	input [0:0] charge_acp_in,
	input [31:0] bemf_0,
	input [31:0] bemf_1,
	input [31:0] bemf_2,
	input [31:0] bemf_3,
	input [15:0] servo_pwm0_high,
	input [15:0] servo_pwm1_high,
	input [15:0] servo_pwm2_high,
	input [15:0] servo_pwm3_high,
	input [7:0] dig_out_val,
	input [7:0] dig_pu,
	input [7:0] dig_oe,
	input [7:0] ana_pu,
	input [11:0] mot_duty0,
	input [11:0] mot_duty1,
	input [11:0] mot_duty2,
	input [11:0] mot_duty3,
	//input [0:0] dig_sample,
	//input [0:0] dig_update,
	input [7:0] mot_drive_code,
	input [4:0] mot_allstop,
	input [0:0] side_button,
	/*
	input [15:0] pid_p_goal_0,
	input [15:0] pid_p_goal_1,
	input [15:0] pid_p_goal_2,
	input [15:0] pid_p_goal_3,
	input [3:0] pid_at_goal,
*/
	output reg [15:0] servo_pwm0_high_new,
	output reg [15:0] servo_pwm1_high_new,
	output reg [15:0] servo_pwm2_high_new,
	output reg [15:0] servo_pwm3_high_new,
	output reg [7:0] dig_out_val_new,
	output reg [7:0] dig_pu_new,
	output reg [7:0] dig_oe_new,
	output reg [7:0] ana_pu_new,
	output reg [11:0] mot_duty0_new,
	output reg [11:0] mot_duty1_new,
	output reg [11:0] mot_duty2_new,
	output reg [11:0] mot_duty3_new,
	//output reg [0:0] dig_sample_new,
	//output reg [0:0] dig_update_new,
	output reg [7:0] mot_drive_code_new,
	output reg [4:0] mot_allstop_new,
	output reg [3:0] mot_bemf_clear_new
	/*
	output reg [15:0] pid_p_goal_0_new,
	output reg [15:0] pid_p_goal_1_new,
	output reg [15:0] pid_p_goal_2_new,
	output reg [15:0] pid_p_goal_3_new
	*/
	);
	
	

	
	
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
					10'd1: 	SPI_OUT_tmp <= {8'd0, dig_in_val[7:0]};//SPI_REGr[31:16];
					10'd2: 	SPI_OUT_tmp <= {6'd0, adc_0_in[9:0]};//SPI_REGr[47:32];
					10'd3: 	SPI_OUT_tmp <= {6'd0, adc_1_in[9:0]};//SPI_REGr[63:48];
					10'd4: 	SPI_OUT_tmp <= {6'd0, adc_2_in[9:0]};//SPI_REGr[79:64];
					10'd5: 	SPI_OUT_tmp <= {6'd0, adc_3_in[9:0]};//SPI_REGr[95:80];
					10'd6: 	SPI_OUT_tmp <= {6'd0, adc_4_in[9:0]};//SPI_REGr[111:96];
					10'd7: 	SPI_OUT_tmp <= {6'd0, adc_5_in[9:0]};//SPI_REGr[127:112];
					10'd8: 	SPI_OUT_tmp <= {6'd0, adc_6_in[9:0]};//SPI_REGr[143:128];
					10'd9: 	SPI_OUT_tmp <= {6'd0, adc_7_in[9:0]};//SPI_REGr[159:144];
					10'd10: 	SPI_OUT_tmp <= {6'd0, adc_8_in[9:0]};//SPI_REGr[175:160];
					10'd11: 	SPI_OUT_tmp <= {6'd0, adc_9_in[9:0]};//SPI_REGr[191:176];
					10'd12: 	SPI_OUT_tmp <= {6'd0, adc_10_in[9:0]};//SPI_REGr[207:192];
					10'd13: 	SPI_OUT_tmp <= {6'd0, adc_11_in[9:0]};//SPI_REGr[223:208];
					10'd14: 	SPI_OUT_tmp <= {6'd0, adc_12_in[9:0]};//SPI_REGr[239:224];
					10'd15: 	SPI_OUT_tmp <= {6'd0, adc_13_in[9:0]};//SPI_REGr[255:240];
					10'd16: 	SPI_OUT_tmp <= {6'd0, adc_14_in[9:0]};//SPI_REGr[271:256];
					10'd17: 	SPI_OUT_tmp <= {6'd0, adc_15_in[9:0]};//SPI_REGr[287:272];
					10'd18: 	SPI_OUT_tmp <= {6'd0, adc_16_in[9:0]};//SPI_REGr[303:288];
					10'd19:	SPI_OUT_tmp <= {15'd0, charge_acp_in};//10'd19: 	[319:304];
					10'd20:	SPI_OUT_tmp <= bemf_0[15:0];//10'd20: 	SPI_OUTr <= SPI_REGr[335:320];
					10'd21:	SPI_OUT_tmp <= bemf_1[15:0];//10'd21: 	SPI_OUTr <= SPI_REGr[351:336];
					10'd22:	SPI_OUT_tmp <= bemf_2[15:0];//10'd22: 	SPI_OUTr <= SPI_REGr[367:352];
					10'd23:	SPI_OUT_tmp <= bemf_3[15:0];//10'd23: 	SPI_OUTr <= SPI_REGr[383:368];
					//10'd24: 	SPI_OUT_tmp <= SPI_REGr[399:384];
					10'd25: 	SPI_OUT_tmp <= servo_pwm0_high;//SPI_REGr[415:400];
					10'd26: 	SPI_OUT_tmp <= servo_pwm1_high;//SPI_REGr[431:416];
					10'd27: 	SPI_OUT_tmp <= servo_pwm2_high;//SPI_REGr[447:432];
					10'd28: 	SPI_OUT_tmp <= servo_pwm3_high;//SPI_REGr[463:448];
					10'd29: 	SPI_OUT_tmp <= {8'd0, dig_out_val};//SPI_REGr[479:464];
					10'd30: 	SPI_OUT_tmp <= {8'd0, dig_pu};//SPI_REGr[495:480];
					10'd31: 	SPI_OUT_tmp <= {8'd0, dig_oe};//SPI_REGr[511:496];
					10'd32: 	SPI_OUT_tmp <= {8'd0, ana_pu};//SPI_REGr[527:512];
					10'd33: 	SPI_OUT_tmp <= {4'd0, mot_duty0};//SPI_REGr[543:528];
					10'd34: 	SPI_OUT_tmp <= {4'd0, mot_duty1};//SPI_REGr[559:544];
					10'd35: 	SPI_OUT_tmp <= {4'd0, mot_duty2};//SPI_REGr[575:560];
					10'd36: 	SPI_OUT_tmp <= {4'd0, mot_duty3};//SPI_REGr[591:576];
					//10'd37: 	SPI_OUT_tmp <= {15'd0, dig_sample};//SPI_REGr[607:592];
					//10'd38: 	SPI_OUT_tmp <= {15'd0, dig_update};//SPI_REGr[623:608];
					10'd39: 	SPI_OUT_tmp <= {8'd0, mot_drive_code};//SPI_REGr[639:624];
					10'd40: 	SPI_OUT_tmp <= {11'd0, mot_allstop}; //SPI_REGr[655:640];
					10'd41:	SPI_OUT_tmp <= bemf_0[31:16];
					10'd42:	SPI_OUT_tmp <= bemf_1[31:16];
					10'd43:	SPI_OUT_tmp <= bemf_2[31:16];
					10'd44:	SPI_OUT_tmp <= bemf_3[31:16];
					10'd45:	SPI_OUT_tmp <= {15'd0, side_button};
					//10'd41:	SPI_OUT_tmp <= pid_p_goal_0;
					//10'd42:	SPI_OUT_tmp <= pid_p_goal_1;
					//10'd43:	SPI_OUT_tmp <= pid_p_goal_2;
					//10'd44:	SPI_OUT_tmp <= pid_p_goal_3;
					//10'd45:	SPI_OUT_tmp <= {12'd0, pid_at_goal};				
				
					default: SPI_OUT_tmp <= 16'd0;//SPI_REGr[15:0];
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
							
					servo_pwm0_high_new 	<= (address == 10'd25) ? byte_data_received[15:0]	: servo_pwm0_high;
					servo_pwm1_high_new 	<= (address == 10'd26) ? byte_data_received[15:0]	: servo_pwm1_high;
					servo_pwm2_high_new 	<= (address == 10'd27) ? byte_data_received[15:0]	: servo_pwm2_high;
					servo_pwm3_high_new 	<= (address == 10'd28) ? byte_data_received[15:0]	: servo_pwm3_high;
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
