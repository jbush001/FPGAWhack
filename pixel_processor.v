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
	parameter OUTPUT_WIDTH = NUM_PIXELS * 12)

	(input clk,
	input new_frame,
	input start_next_batch,
	output[OUTPUT_WIDTH - 1:0] result,
	output result_ready);

	localparam INSTRUCTION_WIDTH = 49;

	reg[3:0] micro_pc;
	wire[INSTRUCTION_WIDTH - 1:0] instruction;
	reg[31:0] x_coord0;
	reg[31:0] x_coord1;
	reg[31:0] x_coord2;
	reg[31:0] x_coord3;
	reg[31:0] x_coord4;
	reg[31:0] x_coord5;
	reg[31:0] x_coord6;
	reg[31:0] x_coord7;
	reg[31:0] y_coord;
	reg[31:0] f_number;

	pixel_alu pixel_alu0(
		.clk(clk),
		.instruction(instruction),
		.x_coord(x_coord0),
		.y_coord(y_coord),
		.f_number(f_number),
		.output_value(result[11:0]));

	pixel_alu pixel_alu1(
		.clk(clk),
		.instruction(instruction),
		.x_coord(x_coord1),
		.y_coord(y_coord),
		.f_number(f_number),
		.output_value(result[23:12]));

	pixel_alu pixel_alu2(
		.clk(clk),
		.instruction(instruction),
		.x_coord(x_coord2),
		.y_coord(y_coord),
		.f_number(f_number),
		.output_value(result[35:24]));

	pixel_alu pixel_alu3(
		.clk(clk),
		.instruction(instruction),
		.x_coord(x_coord3),
		.y_coord(y_coord),
		.f_number(f_number),
		.output_value(result[47:36]));

	pixel_alu pixel_alu4(
		.clk(clk),
		.instruction(instruction),
		.x_coord(x_coord4),
		.y_coord(y_coord),
		.f_number(f_number),
		.output_value(result[59:48]));

	pixel_alu pixel_alu5(
		.clk(clk),
		.instruction(instruction),
		.x_coord(x_coord5),
		.y_coord(y_coord),
		.f_number(f_number),
		.output_value(result[71:60]));

	pixel_alu pixel_alu6(
		.clk(clk),
		.instruction(instruction),
		.x_coord(x_coord6),
		.y_coord(y_coord),
		.f_number(f_number),
		.output_value(result[83:72]));

	pixel_alu pixel_alu7(
		.clk(clk),
		.instruction(instruction),
		.x_coord(x_coord7),
		.y_coord(y_coord),
		.f_number(f_number),
		.output_value(result[95:84]));

	sram_1r1w #(INSTRUCTION_WIDTH, 16) microcode_mem(
		.clk(clk),
		.rd_addr(micro_pc),
		.rd_data(instruction),
		.wr_enable(0),
		.wr_addr(4'd0),
		.wr_data({INSTRUCTION_WIDTH{1'b0}}));
	
	initial
	begin
		micro_pc = 0;
		y_coord = 0;
		x_coord0 = 0;
		x_coord1 = 0;
		x_coord2 = 0;
		x_coord3 = 0;
		x_coord4 = 0;
		x_coord5 = 0;
		x_coord6 = 0;
		x_coord7 = 0;
		f_number = 0;
	end

	assign result_ready = micro_pc == 4'b1111;
	wire end_of_line = x_coord0 == 640 - NUM_PIXELS;

	always @(posedge clk)
	begin
		if (new_frame || start_next_batch)
			micro_pc <= 5'd0;
		else if (!result_ready)
			micro_pc <= micro_pc + 1;

		if (new_frame)
		begin
			f_number <= f_number + 1;
			y_coord <= 0;
		end
		else if (end_of_line && start_next_batch)
			y_coord <= y_coord + 1;
	
		if (new_frame || (end_of_line && start_next_batch))
		begin
			x_coord0 <= 0;
			x_coord1 <= 1;
			x_coord2 <= 2;
			x_coord3 <= 3;
			x_coord4 <= 4;
			x_coord5 <= 5;
			x_coord6 <= 6;
			x_coord7 <= 7;
		end
		else if (start_next_batch)
		begin
			x_coord0 <= x_coord0 + 8;
			x_coord1 <= x_coord1 + 8;
			x_coord2 <= x_coord2 + 8;
			x_coord3 <= x_coord3 + 8;
			x_coord4 <= x_coord4 + 8;
			x_coord5 <= x_coord5 + 8;
			x_coord6 <= x_coord6 + 8;
			x_coord7 <= x_coord7 + 8;
		end
	end
endmodule
