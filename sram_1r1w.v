
module sram_1r1w
	#(parameter DATA_WIDTH = 32,
	parameter SIZE = 1024,
	parameter ADDR_WIDTH = $clog2(SIZE))

	(input						clk,
	input [ADDR_WIDTH - 1:0]	rd_addr,
	output reg[DATA_WIDTH - 1:0] rd_data = 0,
	input						wr_enable,
	input [ADDR_WIDTH - 1:0]	wr_addr,
	input [DATA_WIDTH - 1:0]	wr_data);
	
	reg[DATA_WIDTH - 1:0] data[0:SIZE - 1];
	integer	i;

	initial
	begin
		for (i = 0; i < SIZE; i = i + 1)
			data[i] = 0;
			
		rd_data = 0;
		$readmemh("microcode.hex", data);
	end

	always @(posedge clk)
	begin
		if (wr_enable)
			data[wr_addr] <= wr_data;	

		if (wr_addr == rd_addr && wr_enable)
			rd_data <= wr_data;
		else
			rd_data <= data[rd_addr];
	end
endmodule
