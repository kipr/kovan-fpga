`timescale 1ns / 1ps

module auto_adc_updater(
	input clk3p2M,
	input [9:0] adc_in,
	input adc_valid,
	input bemf_sensing,
	output adc_go,
	output [3:0] adc_chan,
	output [9:0] adc_0_in,
	output [9:0] adc_1_in,
	output [9:0] adc_2_in,
	output [9:0] adc_3_in,
	output [9:0] adc_4_in,
	output [9:0] adc_5_in,
	output [9:0] adc_6_in,
	output [9:0] adc_7_in,
	output [9:0] adc_8_in,
	output [9:0] adc_9_in,
	output [9:0] adc_10_in,
	output [9:0] adc_11_in,
	output [9:0] adc_12_in,
	output [9:0] adc_13_in,
	output [9:0] adc_14_in,
	output [9:0] adc_15_in,
	output [9:0] adc_16_in,
	output adc_batt_sel
    );
	 
	
	reg [9:0] adc_0_in_r = 10'd0;
	reg [9:0] adc_1_in_r = 10'd0;
	reg [9:0] adc_2_in_r = 10'd0;
	reg [9:0] adc_3_in_r = 10'd0;
	reg [9:0] adc_4_in_r = 10'd0;
	reg [9:0] adc_5_in_r = 10'd0;
	reg [9:0] adc_6_in_r = 10'd0;
	reg [9:0] adc_7_in_r = 10'd0;
	reg [9:0] adc_8_in_r = 10'd0;
	reg [9:0] adc_9_in_r = 10'd0;
	reg [9:0] adc_10_in_r = 10'd0;
	reg [9:0] adc_11_in_r = 10'd0;
	reg [9:0] adc_12_in_r = 10'd0;
	reg [9:0] adc_13_in_r = 10'd0;
	reg [9:0] adc_14_in_r = 10'd0;
	reg [9:0] adc_15_in_r = 10'd0;
	reg [9:0] adc_16_in_r = 10'd0;
	reg adc_batt_sel_r = 1'b0;
	
	assign adc_0_in = adc_0_in_r;
	assign adc_1_in = adc_1_in_r;
	assign adc_2_in = adc_2_in_r;
	assign adc_3_in = adc_3_in_r;
	assign adc_4_in = adc_4_in_r;
	assign adc_5_in = adc_5_in_r;
	assign adc_6_in = adc_6_in_r;
	assign adc_7_in = adc_7_in_r;
	assign adc_8_in = adc_8_in_r;
	assign adc_9_in = adc_9_in_r;
	assign adc_10_in = adc_10_in_r;
	assign adc_11_in = adc_11_in_r;
	assign adc_12_in = adc_12_in_r;
	assign adc_13_in = adc_13_in_r;
	assign adc_14_in = adc_14_in_r;
	assign adc_15_in = adc_15_in_r;
	assign adc_16_in = adc_16_in_r;

	assign adc_batt_sel = adc_batt_sel_r;
	
	


	reg [1:0] auto_adc_state = 2'b00;

	reg [6:0] adc_chan_r = 7'd0;
	reg adc_go_r = 0;

	assign adc_chan[3:0] = adc_chan_r[5:2];//assign adc_chan[3:0] = SPI_REG[659:656];	// r41
	assign adc_go = adc_go_r;//assign adc_go = SPI_REG[672];	// r42
	reg [15:0] adc_timeout = 16'd0;

	// adc auto update
	always @(posedge clk3p2M) begin
	

		case(auto_adc_state) 
			2'b00: begin
				adc_batt_sel_r <= adc_chan_r[6];
				adc_go_r <= 0;
				adc_chan_r <= adc_chan_r;
				auto_adc_state <= auto_adc_state + 2'b01;
			end
			
			2'b01: begin
				adc_go_r <= 1;
				adc_chan_r <= adc_chan_r;
				auto_adc_state <= auto_adc_state + 2'b01;
			end
			
			2'b10: begin
				adc_go_r <= 0;
				adc_chan_r <= adc_chan_r;
				auto_adc_state <= auto_adc_state + 2'b01;
				adc_timeout <= 16'd0;
			end
			
			2'b11: begin
				// waiting for adc_valid
				if (adc_timeout > 16'hfff0) begin
					adc_go_r <= 0;
					adc_chan_r <= adc_chan_r;
					adc_timeout <= 16'h0000;
					auto_adc_state <= 2'b00;
				end else begin
					adc_timeout <= adc_timeout + 16'h0001;
					adc_go_r <= 0;
					if (adc_valid) begin
						if (adc_chan_r[1:0] == 2'b11) begin 
							case (adc_chan_r[6:2]) 
								5'd0: adc_0_in_r <= adc_in;
								5'd1: adc_1_in_r <= adc_in;
								5'd2: adc_2_in_r <= adc_in;
								5'd3: adc_3_in_r <= adc_in;
								5'd4: adc_4_in_r <= adc_in;
								5'd5: adc_5_in_r <= adc_in;
								5'd6: adc_6_in_r <= adc_in;
								5'd7: adc_7_in_r <= adc_in; 
								5'd8: if (bemf_sensing) adc_8_in_r <= adc_in;
								5'd9: if (bemf_sensing) adc_9_in_r <= adc_in;
								5'd10: if (bemf_sensing) adc_10_in_r <= adc_in;
								5'd11: if (bemf_sensing) adc_11_in_r <= adc_in;
								5'd12: if (bemf_sensing) adc_12_in_r <= adc_in;
								5'd13: if (bemf_sensing) adc_13_in_r <= adc_in;
								5'd14: if (bemf_sensing) adc_14_in_r <= adc_in;
								5'd15: if (bemf_sensing) adc_15_in_r <= adc_in;
								5'd16: adc_16_in_r <= adc_in;
								default:;
							endcase
						end
						// back to start state
						auto_adc_state <= 2'b00;
						
						// next channel to be sampled
						if (adc_chan_r[6:2] < 17)  begin
							adc_chan_r <= adc_chan_r + 7'd1;
						end else begin
							adc_chan_r <= 7'd0;
						end

					end else begin
						//stay in state
						auto_adc_state <= 2'b11; 
						adc_chan_r <= adc_chan_r;
					end
				end // adc no time out
			end // case 11
			
			default: begin
				auto_adc_state <= 0;
				adc_go_r <= 0;
			end
		endcase

	end
	
endmodule
