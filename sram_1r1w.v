// 
// Copyright 2013 Jeff Bush
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//     http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// 


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
