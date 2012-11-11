`timescale 1ns / 1ps

module spi(
	input		SYS_CLK,
	input		SPI_CLK,
	input		SSEL,
	input		MOSI,
	output	MISO,
	input [2047:0] SPI_REG,
	output [2047:1024] COMMAND_REG);
	
	
	reg [2:0] SCKr; // SPI Clock
	reg [2:0] SSELr; // Slave Selec	
	reg [1:0] MOSIr; // Master-Out Slave-In
	reg [15:0] SPI_OUTr;
	reg [2047:0] SPI_REGr = 2048'd0;
	reg [2047:1024] COMMAND_REGr = 1024'd0;
	
	
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
		SPI_REGr[2047:0] <= SPI_REG[2047:0];
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
						10'd41: 	SPI_OUTr <= SPI_REGr[671:656];
						10'd42: 	SPI_OUTr <= SPI_REGr[687:672];
						10'd43: 	SPI_OUTr <= SPI_REGr[703:688];
						10'd44: 	SPI_OUTr <= SPI_REGr[719:704];
						10'd45: 	SPI_OUTr <= SPI_REGr[735:720];
						10'd46: 	SPI_OUTr <= SPI_REGr[751:736];
						10'd47: 	SPI_OUTr <= SPI_REGr[767:752];
						10'd48: 	SPI_OUTr <= SPI_REGr[783:768];
						10'd49: 	SPI_OUTr <= SPI_REGr[799:784];
						10'd50: 	SPI_OUTr <= SPI_REGr[815:800];
						10'd51: 	SPI_OUTr <= SPI_REGr[831:816];
						10'd52: 	SPI_OUTr <= SPI_REGr[847:832];
						10'd53: 	SPI_OUTr <= SPI_REGr[863:848];
						10'd54: 	SPI_OUTr <= SPI_REGr[879:864];
						10'd55: 	SPI_OUTr <= SPI_REGr[895:880];
						10'd56: 	SPI_OUTr <= SPI_REGr[911:896];
						10'd57: 	SPI_OUTr <= SPI_REGr[927:912];
						10'd58: 	SPI_OUTr <= SPI_REGr[943:928];
						10'd59: 	SPI_OUTr <= SPI_REGr[959:944];
						10'd60: 	SPI_OUTr <= SPI_REGr[975:960];
						10'd61: 	SPI_OUTr <= SPI_REGr[991:976];
						10'd62: 	SPI_OUTr <= SPI_REGr[1007:992];
						10'd63: 	SPI_OUTr <= SPI_REGr[1023:1008];
						10'd64: 	SPI_OUTr <= SPI_REGr[1039:1024];
						10'd65: 	SPI_OUTr <= SPI_REGr[1055:1040];
						10'd66: 	SPI_OUTr <= SPI_REGr[1071:1056];
						10'd67: 	SPI_OUTr <= SPI_REGr[1087:1072];
						10'd68: 	SPI_OUTr <= SPI_REGr[1103:1088];
						10'd69: 	SPI_OUTr <= SPI_REGr[1119:1104];
						10'd70: 	SPI_OUTr <= SPI_REGr[1135:1120];
						10'd71: 	SPI_OUTr <= SPI_REGr[1151:1136];
						10'd72: 	SPI_OUTr <= SPI_REGr[1167:1152];
						10'd73: 	SPI_OUTr <= SPI_REGr[1183:1168];
						10'd74: 	SPI_OUTr <= SPI_REGr[1199:1184];
						10'd75: 	SPI_OUTr <= SPI_REGr[1215:1200];
						10'd76: 	SPI_OUTr <= SPI_REGr[1231:1216];
						10'd77: 	SPI_OUTr <= SPI_REGr[1247:1232];
						10'd78: 	SPI_OUTr <= SPI_REGr[1263:1248];
						10'd79: 	SPI_OUTr <= SPI_REGr[1279:1264];
						10'd80: 	SPI_OUTr <= SPI_REGr[1295:1280];
						10'd81: 	SPI_OUTr <= SPI_REGr[1311:1296];
						10'd82: 	SPI_OUTr <= SPI_REGr[1327:1312];
						10'd83: 	SPI_OUTr <= SPI_REGr[1343:1328];
						10'd84: 	SPI_OUTr <= SPI_REGr[1359:1344];
						10'd85: 	SPI_OUTr <= SPI_REGr[1375:1360];
						10'd86: 	SPI_OUTr <= SPI_REGr[1391:1376];
						10'd87: 	SPI_OUTr <= SPI_REGr[1407:1392];
						10'd88: 	SPI_OUTr <= SPI_REGr[1423:1408];
						10'd89: 	SPI_OUTr <= SPI_REGr[1439:1424];
						10'd90: 	SPI_OUTr <= SPI_REGr[1455:1440];
						10'd91: 	SPI_OUTr <= SPI_REGr[1471:1456];
						10'd92: 	SPI_OUTr <= SPI_REGr[1487:1472];
						10'd93: 	SPI_OUTr <= SPI_REGr[1503:1488];
						10'd94: 	SPI_OUTr <= SPI_REGr[1519:1504];
						10'd95: 	SPI_OUTr <= SPI_REGr[1535:1520];
						10'd96: 	SPI_OUTr <= SPI_REGr[1551:1536];
						10'd97: 	SPI_OUTr <= SPI_REGr[1567:1552];
						10'd98: 	SPI_OUTr <= SPI_REGr[1583:1568];
						10'd99: 	SPI_OUTr <= SPI_REGr[1599:1584];
						10'd100: 	SPI_OUTr <= SPI_REGr[1615:1600];
						10'd101: 	SPI_OUTr <= SPI_REGr[1631:1616];
						10'd102: 	SPI_OUTr <= SPI_REGr[1647:1632];
						10'd103: 	SPI_OUTr <= SPI_REGr[1663:1648];
						10'd104: 	SPI_OUTr <= SPI_REGr[1679:1664];
						10'd105: 	SPI_OUTr <= SPI_REGr[1695:1680];
						10'd106: 	SPI_OUTr <= SPI_REGr[1711:1696];
						10'd107: 	SPI_OUTr <= SPI_REGr[1727:1712];
						10'd108: 	SPI_OUTr <= SPI_REGr[1743:1728];
						10'd109: 	SPI_OUTr <= SPI_REGr[1759:1744];
						10'd110: 	SPI_OUTr <= SPI_REGr[1775:1760];
						10'd111: 	SPI_OUTr <= SPI_REGr[1791:1776];
						10'd112: 	SPI_OUTr <= SPI_REGr[1807:1792];
						10'd113: 	SPI_OUTr <= SPI_REGr[1823:1808];
						10'd114: 	SPI_OUTr <= SPI_REGr[1839:1824];
						10'd115: 	SPI_OUTr <= SPI_REGr[1855:1840];
						10'd116: 	SPI_OUTr <= SPI_REGr[1871:1856];
						10'd117: 	SPI_OUTr <= SPI_REGr[1887:1872];
						10'd118: 	SPI_OUTr <= SPI_REGr[1903:1888];
						10'd119: 	SPI_OUTr <= SPI_REGr[1919:1904];
						10'd120: 	SPI_OUTr <= SPI_REGr[1935:1920];
						10'd121: 	SPI_OUTr <= SPI_REGr[1951:1936];
						10'd122: 	SPI_OUTr <= SPI_REGr[1967:1952];
						10'd123: 	SPI_OUTr <= SPI_REGr[1983:1968];
						10'd124: 	SPI_OUTr <= SPI_REGr[1999:1984];
						10'd125: 	SPI_OUTr <= SPI_REGr[2015:2000];
						10'd126: 	SPI_OUTr <= SPI_REGr[2031:2016];
						10'd127: 	SPI_OUTr <= SPI_REGr[2047:2032];
						default: SPI_OUTr[15:0] <= SPI_REGr[15:0];
					endcase
					
					address <= address + 10'd1;
				end
				
				2'b01: begin // write
					state[1:0] <= byte_data_received[15:14];
					SPI_OUTr[15:0] <= 16'h0001;
					
					case(address)
						default: COMMAND_REGr[2047:1024] <= SPI_REGr[2047:1024];
					endcase
				end
			
				default: begin // undefined
					state[1:0] <= byte_data_received[15:14];
					SPI_OUTr[15:0] <= 16'h0003;
					if (byte_data_received[15:14] == 2'b10) begin
						// transition to read
						SPI_OUTr[15:0] <= SPI_REGr[15:0]; // reg 0
						address[9:0] <= 10'd0;
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
