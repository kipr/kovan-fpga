`timescale 1ns / 1ps

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
	output pwm,
	output [3:0] MBOT,
	output [3:0] MTOP
	);

	reg [3:0] active_mot = 4'b0000;
	reg [3:0] MBOT_r = 4'b0000;
	reg [3:0] MTOP_r = 4'b0000;
	reg [11:0] count = 12'h0000;
	
	assign MBOT[3:0] = MBOT_r[3:0];
	assign MTOP[3:0] = MTOP_r[3:0];
	
	reg pwm_r;
	assign pwm = pwm_r;
	
	always @ (posedge clk) begin
		if (count > 12'd2600) begin
			count <= 12'h0000;
		end else begin
			count <= count + 12'h00001;
		end
		
		if (count > duty0) begin
			active_mot[0] <= 1'b0;
			MTOP_r[0] <= 1'b0;
			MBOT_r[0] <= 1'b0;	
		end else begin
			active_mot[0] <= 1'b1;
			MTOP_r[0] <= drive_code[7];
			MBOT_r[0] <= drive_code[6];			
		end
				
		if (count > duty1) begin
			active_mot[1] <= 1'b0;
			MTOP_r[1] <= 1'b0; 
			MBOT_r[1] <= 1'b0;		
		end else begin
			active_mot[1] <= 1'b1;
			MTOP_r[1] <= drive_code[5];
			MBOT_r[1] <= drive_code[4];
		end
		
		if (count > duty2) begin
			active_mot[2] <= 1'b0;			
			MTOP_r[2] <= 1'b0;
			MBOT_r[2] <= 1'b0;
		end else begin
			active_mot[2] <= 1'b1;
			MTOP_r[2] <= drive_code[3];
			MBOT_r[2] <= drive_code[2];		
		end
		
		if (count > duty3) begin
			active_mot[3] <= 1'b0;
			MTOP_r[3] <= 1'b0;
			MBOT_r[3] <= 1'b0;
		end else begin
			active_mot[3] <= 1'b1;	
			MTOP_r[3] <= drive_code[1];
			MBOT_r[3] <= drive_code[0];		
					
		end
		
		pwm_r <= MOT_EN && (active_mot[3] | active_mot[2] | active_mot[1] | active_mot[0]); 
	end

endmodule
