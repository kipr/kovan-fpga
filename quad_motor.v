`timescale 1ns / 1ps
/*
4 motors
10 khz
16 bit precision
1 shared pwm

[A,B] 	= function
------------------
 10  	= forward
 01  	= reverse
 11  	= brake
 00  	= idle

     ____      ____
    |    |    |    |
____|    |____|    |


// The problem is we one have 1 pwm
// So we must strobe the pwm and turn some singals on/off.....
*/



module quad_motor(
	input clk,
	input MOT_EN,
	input [11:0] duty0,
	input [11:0] duty1,
	input [11:0] duty2,
	input [11:0] duty3,
	input [7:0] drive_code,
	input bemf_sensing,
	output pwm,
	output [3:0] MBOT,
	output [3:0] MTOP
	);

	reg [3:0] active_mot = 4'b0000;
	reg [3:0] MBOT_r = 4'b0000;
	reg [3:0] MTOP_r = 4'b0000;
	reg [16:0] count = 17'h0000;
	
	assign MBOT[3:0] = MTOP_r[3:0];
	assign MTOP[3:0] = MBOT_r[3:0];
	
	reg pwm_r;
	assign pwm = pwm_r;
	
	reg pwm_dbg = 1'd0;
	
	reg stall_m0 = 1'd0;
	reg stall_m1 = 1'd0;
	reg stall_m2 = 1'd0;
	reg stall_m3 = 1'd0;
	
	
	always @ (posedge clk) begin
		
		if (count[16:5] > 12'd2600) begin
			count <= 17'd0;
		end else begin
			count <= count + 17'd1;
		end
		
		active_mot[0] <= (count[16:5] > duty0) ? 1'd0 : 1'd1;
		active_mot[1] <= (count[16:5] > duty1) ? 1'd0 : 1'd1;
		active_mot[2] <= (count[16:5] > duty2) ? 1'd0 : 1'd1;
		active_mot[3] <= (count[16:5] > duty3) ? 1'd0 : 1'd1;
		
		
		MTOP_r[0] <= drive_code[7];
		MBOT_r[0] <= drive_code[6];
		MTOP_r[1] <= drive_code[5];
		MBOT_r[1] <= drive_code[4];
		MTOP_r[2] <= drive_code[3];
		MBOT_r[2] <= drive_code[2];
		MTOP_r[3] <= drive_code[1];
		MBOT_r[3] <= drive_code[0];
		
		stall_m0 <= (bemf_sensing || count[16:5] > duty0);
		stall_m1 <= (bemf_sensing || count[16:5] > duty1);
		stall_m2 <= (bemf_sensing || count[16:5] > duty2);
		stall_m3 <= (bemf_sensing || count[16:5] > duty3);

		
		MTOP_r[0] <= (stall_m0) ? 1'd0 : drive_code[7];
		MBOT_r[0] <= (stall_m0) ? 1'd0 : drive_code[6];
		MTOP_r[1] <= (stall_m1) ? 1'd0 : drive_code[5];
		MBOT_r[1] <= (stall_m1) ? 1'd0 : drive_code[4];
		MTOP_r[2] <= (stall_m2) ? 1'd0 : drive_code[3];
		MBOT_r[2] <= (stall_m2) ? 1'd0 : drive_code[2];
		MTOP_r[3] <= (stall_m3) ? 1'd0 : drive_code[1];
		MBOT_r[3] <= (stall_m3) ? 1'd0 : drive_code[0];

		pwm_r <= MOT_EN;// &&(active_mot[3] | active_mot[2] | active_mot[1] | active_mot[0]);
	end

endmodule
