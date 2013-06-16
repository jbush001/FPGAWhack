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


module pixel_processor
	#(parameter NUM_PIXELS = 8,
	parameter PIXEL_WIDTH = 12,
	parameter OUTPUT_WIDTH = NUM_PIXELS * PIXEL_WIDTH)

	(input clk,
	input new_frame,
	input start_next_batch,
	output[OUTPUT_WIDTH - 1:0] result,
	output result_ready);

	localparam INSTRUCTION_WIDTH = 46;

	reg[3:0] pc;
	wire[INSTRUCTION_WIDTH - 1:0] instruction;
	reg[31:0] y_coord;
	reg[31:0] f_number;

	genvar lane;
	generate
		for (lane = 0; lane < NUM_PIXELS; lane = lane + 1)
		begin : pixel_compute
			reg[31:0] x_coord = 0;
			
			always @(posedge clk)
			begin
				if (new_frame || (end_of_line && start_next_batch))
					x_coord <= lane;
				else if (start_next_batch)
					x_coord <= x_coord + NUM_PIXELS;
			end

			pixel_alu pixel_alu0(
				.clk(clk),
				.instruction(instruction),
				.x_coord(x_coord),
				.y_coord(y_coord),
				.f_number(f_number),
				.output_value(result[lane * PIXEL_WIDTH+:PIXEL_WIDTH]));
		end
	endgenerate

	localparam MAX_INSTRUCTIONS = NUM_PIXELS * 2;

	sram_1r1w #(INSTRUCTION_WIDTH, MAX_INSTRUCTIONS) instruction_mem(
		.clk(clk),
		.rd_addr(pc),
		.rd_data(instruction),
		.wr_enable(0),
		.wr_addr(0),
		.wr_data({INSTRUCTION_WIDTH{1'b0}}));
	
	initial
	begin
		pc = 0;
		y_coord = 0;
		f_number = 0;
	end

	assign result_ready = pc == MAX_INSTRUCTIONS - 1;
	wire end_of_line = pixel_compute[0].x_coord == 640 - NUM_PIXELS;

	always @(posedge clk)
	begin
		if (new_frame || start_next_batch)
			pc <= 5'd0;
		else if (!result_ready)
			pc <= pc + 1;

		if (new_frame)
		begin
			f_number <= f_number + 1;
			y_coord <= 0;
		end
		else if (end_of_line && start_next_batch)
			y_coord <= y_coord + 1;
	end
endmodule
