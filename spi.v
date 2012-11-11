`timescale 1ns / 1ps

module spi(
	input		SYS_CLK,
	input		SPI_CLK,
	input		SSEL,
	input		MOSI,
	output	MISO,
	output [15:0]	SPI_OUT,
	input [63:0][15:0] DATA_REG,
	output [63:0][15:0] COMMAND_REG);
	
	reg[2:0] SCKr;
	
	// SPI Clock
	always @(posedge SYS_CLK) begin
		SCKr <= {SCKr[1:0], SPI_CLK};
	end

	wire SCK_rising_edge = (SCKr[2:1] == 2'b01);
	wire SCK_falling_edge = (SCKr[2:1] == 2'b10);
	

	// Slave Select
	reg[2:0] SSELr;
	
	always @(posedge SYS_CLK) begin
		SSELr <= {SSELr[1:0], SSEL};
	end

	wire SSEL_active = ~SSELr[1];  // Active LOW Slave Select
	wire SSEL_start_msg = (SSELr[2:1] == 2'b10);
	//wire SSEL_stop_msg  = (SSELr[2:1] == 2'b01); 


	// Master-Out Slave-In
	reg[1:0] MOSIr;
	
	always @(posedge SYS_CLK) begin
		MOSIr <= {MOSIr[0], MOSI};
	end
	
	wire MOSI_data = MOSIr[1];
	
	
	/////////////////   RECEIVING   /////////////////////
	
	reg [3:0] bitcnt;
	
	reg byte_received; // high when a byte is received
	reg [15:0] byte_data_received;
	reg [5:0] header;
	reg [9:0] data;
	
	
	always @(posedge SYS_CLK) begin
		if (~SSEL_active)
			bitcnt <= 4'b0000;
		else if (SCK_falling_edge) begin
			bitcnt <= bitcnt + 4'b0001;

			// MSb first 
			byte_data_received <= {byte_data_received[14:0], MOSI_data};
		end
	end

	always @(posedge SYS_CLK) begin
		byte_received <= SSEL_active && (bitcnt==4'b1111) &&  SCK_falling_edge; // 
	end
	
	reg [15:0] SPI_OUTr;
	assign SPI_OUT = SPI_OUTr;
	
	always @(posedge SYS_CLK) begin
		if(byte_received) begin
			SPI_OUTr <= byte_data_received;
			header[5:0] = byte_data_received[15:10];
			data[9:0] = byte_data_received[9:0];
		end
	end
	
	/////////////////////////////////////////////////////

	
	
	
	
	
	//////////////////   Sending   //////////////////////	
	
	reg [15:0] byte_data_sent;
	
	
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
	
	
	assign MISO = byte_data_sent[15];
	
	/////////////////////////////////////////////////////

endmodule
