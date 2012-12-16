`timescale 1ns / 1ps

module spi(
	input		SYS_CLK,
	input		SPI_CLK,
	input		SSEL,
	input		MOSI,
	output	MISO,
	input [1039:0] SPI_REG,
	output [1039:384] COMMAND_REG
	);
	
	
	reg [2:0] SCKr; // SPI Clock
	reg [2:0] SSELr; // Slave Selec	
	reg [1:0] MOSIr; // Master-Out Slave-In
	reg [15:0] SPI_OUTr;
	reg [1039:0] SPI_REGr = 1040'd0;
	reg [1039:384] COMMAND_REGr = {560'd0, 16'd76, 16'd76, 16'd76, 16'd76, 16'h6677};
	
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
	assign COMMAND_REG = COMMAND_REGr;

	// latch inputs
	always @(posedge SYS_CLK) begin
		SCKr <= {SCKr[1:0], SPI_CLK};
		SSELr <= {SSELr[1:0], SSEL};
		MOSIr <= {MOSIr[0], MOSI};
		SPI_REGr[1039:0] <= SPI_REG[1039:0];
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

		if(byte_received) begin

			case(state[1:0])
				2'b10: begin // read
					state[1:0] <=  byte_data_received[15:14];
					
					case(address)
						10'd0: 	SPI_OUTr <= SPI_REGr[15:0];
						10'd1: 	SPI_OUTr <= SPI_REGr[31:16];
						10'd2: 	SPI_OUTr <= SPI_REGr[47:32];
						10'd3: 	SPI_OUTr <= SPI_REGr[63:48];
						10'd4: 	SPI_OUTr <= SPI_REGr[79:64];
						10'd5: 	SPI_OUTr <= SPI_REGr[95:80];
						10'd6: 	SPI_OUTr <= SPI_REGr[111:96];
						10'd7: 	SPI_OUTr <= SPI_REGr[127:112];
						10'd8: 	SPI_OUTr <= SPI_REGr[143:128];
						10'd9: 	SPI_OUTr <= SPI_REGr[159:144];
						10'd10: 	SPI_OUTr <= SPI_REGr[175:160];
						10'd11: 	SPI_OUTr <= SPI_REGr[191:176];
						10'd12: 	SPI_OUTr <= SPI_REGr[207:192];
						10'd13: 	SPI_OUTr <= SPI_REGr[223:208];
						10'd14: 	SPI_OUTr <= SPI_REGr[239:224];
						10'd15: 	SPI_OUTr <= SPI_REGr[255:240];
						10'd16: 	SPI_OUTr <= SPI_REGr[271:256];
						10'd17: 	SPI_OUTr <= SPI_REGr[287:272];
						10'd18: 	SPI_OUTr <= SPI_REGr[303:288];
						10'd19: 	SPI_OUTr <= SPI_REGr[319:304];
						10'd20: 	SPI_OUTr <= SPI_REGr[335:320];
						10'd21: 	SPI_OUTr <= SPI_REGr[351:336];
						10'd22: 	SPI_OUTr <= SPI_REGr[367:352];
						10'd23: 	SPI_OUTr <= SPI_REGr[383:368];
						10'd24: 	SPI_OUTr <= SPI_REGr[399:384];
						10'd25: 	SPI_OUTr <= SPI_REGr[415:400];
						10'd26: 	SPI_OUTr <= SPI_REGr[431:416];
						10'd27: 	SPI_OUTr <= SPI_REGr[447:432];
						10'd28: 	SPI_OUTr <= SPI_REGr[463:448];
						10'd29: 	SPI_OUTr <= SPI_REGr[479:464];
						10'd30: 	SPI_OUTr <= SPI_REGr[495:480];
						10'd31: 	SPI_OUTr <= SPI_REGr[511:496];
						10'd32: 	SPI_OUTr <= SPI_REGr[527:512];
						10'd33: 	SPI_OUTr <= SPI_REGr[543:528];
						10'd34: 	SPI_OUTr <= SPI_REGr[559:544];
						10'd35: 	SPI_OUTr <= SPI_REGr[575:560];
						10'd36: 	SPI_OUTr <= SPI_REGr[591:576];
						10'd37: 	SPI_OUTr <= SPI_REGr[607:592];
						10'd38: 	SPI_OUTr <= SPI_REGr[623:608];
						10'd39: 	SPI_OUTr <= SPI_REGr[639:624];
						10'd40: 	SPI_OUTr <= SPI_REGr[655:640];
						
						default: SPI_OUTr[15:0] <= SPI_REGr[15:0];
					endcase
					
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
					
					SPI_OUTr[15:0] <= byte_data_received[15:0];//echo back the value
					
					case(address)
						10'd24: 	COMMAND_REGr <= {SPI_REGr[1039:400], byte_data_received};
						10'd25: 	COMMAND_REGr <= {SPI_REGr[1039:416], byte_data_received, SPI_REGr[399:384]};
						10'd26: 	COMMAND_REGr <= {SPI_REGr[1039:432], byte_data_received, SPI_REGr[415:384]};
						10'd27: 	COMMAND_REGr <= {SPI_REGr[1039:448], byte_data_received, SPI_REGr[431:384]};
						10'd28: 	COMMAND_REGr <= {SPI_REGr[1039:464], byte_data_received, SPI_REGr[447:384]};
						10'd29: 	COMMAND_REGr <= {SPI_REGr[1039:480], byte_data_received, SPI_REGr[463:384]};
						10'd30: 	COMMAND_REGr <= {SPI_REGr[1039:496], byte_data_received, SPI_REGr[479:384]};
						10'd31: 	COMMAND_REGr <= {SPI_REGr[1039:512], byte_data_received, SPI_REGr[495:384]};
						10'd32: 	COMMAND_REGr <= {SPI_REGr[1039:528], byte_data_received, SPI_REGr[511:384]};
						10'd33: 	COMMAND_REGr <= {SPI_REGr[1039:544], byte_data_received, SPI_REGr[527:384]};
						10'd34: 	COMMAND_REGr <= {SPI_REGr[1039:560], byte_data_received, SPI_REGr[543:384]};
						10'd35: 	COMMAND_REGr <= {SPI_REGr[1039:576], byte_data_received, SPI_REGr[559:384]};
						10'd36: 	COMMAND_REGr <= {SPI_REGr[1039:592], byte_data_received, SPI_REGr[575:384]};
						10'd37: 	COMMAND_REGr <= {SPI_REGr[1039:608], byte_data_received, SPI_REGr[591:384]};
						10'd38: 	COMMAND_REGr <= {SPI_REGr[1039:624], byte_data_received, SPI_REGr[607:384]};
						10'd39: 	COMMAND_REGr <= {SPI_REGr[1039:640], byte_data_received, SPI_REGr[623:384]};
						10'd40: 	COMMAND_REGr <= {SPI_REGr[1039:656], byte_data_received, SPI_REGr[639:384]};
						10'd41: 	COMMAND_REGr <= {SPI_REGr[1039:672], byte_data_received, SPI_REGr[655:384]};
						10'd42: 	COMMAND_REGr <= {SPI_REGr[1039:688], byte_data_received, SPI_REGr[671:384]};
						10'd43: 	COMMAND_REGr <= {SPI_REGr[1039:704], byte_data_received, SPI_REGr[687:384]};
						10'd44: 	COMMAND_REGr <= {SPI_REGr[1039:720], byte_data_received, SPI_REGr[703:384]};
						10'd45: 	COMMAND_REGr <= {SPI_REGr[1039:736], byte_data_received, SPI_REGr[719:384]};
						10'd46: 	COMMAND_REGr <= {SPI_REGr[1039:752], byte_data_received, SPI_REGr[735:384]};
						10'd47: 	COMMAND_REGr <= {SPI_REGr[1039:768], byte_data_received, SPI_REGr[751:384]};
						10'd48: 	COMMAND_REGr <= {SPI_REGr[1039:784], byte_data_received, SPI_REGr[767:384]};
						10'd49: 	COMMAND_REGr <= {SPI_REGr[1039:800], byte_data_received, SPI_REGr[783:384]};
						10'd50: 	COMMAND_REGr <= {SPI_REGr[1039:816], byte_data_received, SPI_REGr[799:384]};
						10'd51: 	COMMAND_REGr <= {SPI_REGr[1039:832], byte_data_received, SPI_REGr[815:384]};
						10'd52: 	COMMAND_REGr <= {SPI_REGr[1039:848], byte_data_received, SPI_REGr[831:384]};
						10'd53: 	COMMAND_REGr <= {SPI_REGr[1039:864], byte_data_received, SPI_REGr[847:384]};
						10'd54: 	COMMAND_REGr <= {SPI_REGr[1039:880], byte_data_received, SPI_REGr[863:384]};
						10'd55: 	COMMAND_REGr <= {SPI_REGr[1039:896], byte_data_received, SPI_REGr[879:384]};
						10'd56: 	COMMAND_REGr <= {SPI_REGr[1039:912], byte_data_received, SPI_REGr[895:384]};
						10'd57: 	COMMAND_REGr <= {SPI_REGr[1039:928], byte_data_received, SPI_REGr[911:384]};
						10'd58: 	COMMAND_REGr <= {SPI_REGr[1039:944], byte_data_received, SPI_REGr[927:384]};
						10'd59: 	COMMAND_REGr <= {SPI_REGr[1039:960], byte_data_received, SPI_REGr[943:384]};
						10'd60: 	COMMAND_REGr <= {SPI_REGr[1039:976], byte_data_received, SPI_REGr[959:384]};
						10'd61: 	COMMAND_REGr <= {SPI_REGr[1039:992], byte_data_received, SPI_REGr[975:384]};
						10'd62: 	COMMAND_REGr <= {SPI_REGr[1039:1008], byte_data_received, SPI_REGr[991:384]};
						10'd63: 	COMMAND_REGr <= {SPI_REGr[1039:1024], byte_data_received, SPI_REGr[1007:384]};
						10'd64: 	COMMAND_REGr <= {byte_data_received, SPI_REGr[1023:384]};
						
						default: COMMAND_REGr[1039:384] <= {SPI_REGr[1039:384]}; // no change
					endcase
					
				end
			
				default: begin // undefined
					state[1:0] <= byte_data_received[15:14];
					SPI_OUTr[15:0] <= 16'h0003;
					
					if (byte_data_received[15:14] == 2'b10) begin
						// transition to read
						SPI_OUTr[15:0] <= SPI_REGr[15:0]; // reg 0
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
