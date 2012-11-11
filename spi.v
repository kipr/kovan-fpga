`timescale 1ns / 1ps

module spi(
	input		SYS_CLK,
	input		SPI_CLK,
	input		SSEL,
	input		MOSI,
	output	MISO,
	input [2047:0] SPI_REG,
	output [2047:1024] COMMAND_REG);
	
	
	reg[2:0] SCKr; // SPI Clock
	reg[2:0] SSELr; // Slave Selec	
	reg[1:0] MOSIr; // Master-Out Slave-In
	reg [15:0] SPI_OUTr;
	assign SPI_OUT = SPI_REG[15:0];
	
	
	reg [5:0] header;
	reg [9:0] data;
	reg [1:0] mode = 2'b00;

	wire SCK_rising_edge = (SCKr[2:1] == 2'b01);
	wire SCK_falling_edge = (SCKr[2:1] == 2'b10);
	wire SSEL_active = ~SSELr[1];  // Active LOW Slave Select
	wire SSEL_start_msg = (SSELr[2:1] == 2'b10);
	wire SSEL_stop_msg  = (SSELr[2:1] == 2'b01); 
	wire MOSI_data = MOSIr[1];

	reg [3:0] bitcnt;	
	reg byte_received; // high when a byte is received
	reg [15:0] byte_data_received;	

	reg [15:0] byte_data_sent;
	
	// our only electrical output
	assign MISO = byte_data_sent[15];


	// latch inputs
	always @(posedge SYS_CLK) begin
		SCKr <= {SCKr[1:0], SPI_CLK};
		SSELr <= {SSELr[1:0], SSEL};
		MOSIr <= {MOSIr[0], MOSI};
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
			SPI_OUTr <= byte_data_received;
			header[5:0] = byte_data_received[15:10];
			data[9:0] = byte_data_received[9:0];
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
