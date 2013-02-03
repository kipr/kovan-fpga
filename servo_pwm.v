module servo_pwm(
		 input wire clk, // 26 MHz
		 input wire [23:0] period,
		 input wire [23:0] pulse,
		 output wire pwm_output);
   
   reg [23:0]	period_cnt = 24'd0;
   reg			pwm_state = 1'b0;
	
   always @(posedge clk) begin
      if( period_cnt[23:0] >= period[23:0] ) begin
			period_cnt <= 24'h0;
      end else begin
			period_cnt <= period_cnt + 1'b1;
      end
   end // always @ (posedge clk or posedge reset)

   always @(posedge clk) begin
      if(pulse < period_cnt) begin
			pwm_state <= 0;
      end else begin
			pwm_state <= 1;
      end
   end // always @ (posedge clk or posedge reset)

   assign pwm_output = pwm_state;
   
endmodule // servo_pwm

