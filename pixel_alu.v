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


//
// Contains register file and ALU to compute value for a single pixel
//

module pixel_alu(
	input				clk,
	input[45:0]			instruction,
	input[31:0] 		x_coord,
	input[31:0]			y_coord,
	input[31:0]			f_number,
	output reg[11:0] 	output_value);

	localparam OP_AND = 0;
	localparam OP_XOR = 1;
	localparam OP_OR = 2;
	localparam OP_ADD = 3;
	localparam OP_SUB = 4;
	localparam OP_MUL = 5;
	localparam OP_SHL = 6;
	localparam OP_SHR = 7;
	localparam OP_MOV = 8;
	localparam OP_EQ = 9;
	localparam OP_NEQ = 10;
	localparam OP_GT = 11;
	localparam OP_GTE = 12;
	localparam OP_LT = 13;
	localparam OP_LTE = 14;

	localparam REG_X = 4'd4;
	localparam REG_Y = 4'd5;
	localparam REG_F = 4'd6;
	localparam REG_RESULT = 4'd7;

	reg[31:0] registers[0:3];

	wire[2:0] dest = instruction[45:43];
	wire[2:0] srca = instruction[42:40];
	wire[2:0] srcb = instruction[39:37];
	wire[3:0] operation = instruction[36:33];
	wire use_const = instruction[32];
	wire[31:0] const_val = instruction[31:0];
	reg[31:0] operand1;
	reg[31:0] operand2;
	reg[31:0] result;
	wire[31:0] difference;
	wire equal;
	wire less;
	integer i;

	initial
	begin
		output_value = 0;
		for (i = 0; i < 4; i = i + 1)
			registers[i] = 0;
	end

	always @*
	begin
		casez (srca)
			3'b0??: operand1 = registers[srca[1:0]];
			REG_X:   operand1 = x_coord;
			REG_Y:   operand1 = y_coord;
			REG_F:   operand1 = f_number;
			default: operand1 = 32'dX;
		endcase

		if (use_const)
			operand2 = const_val;
		else 
		begin
			casez (srcb)
				3'b0??: operand2 = registers[srcb[1:0]];
				REG_X:   operand2 = x_coord;
				REG_Y:   operand2 = y_coord;
				REG_F:   operand2 = f_number;
				default: operand2 = 32'dX;
			endcase
		end
	end

	assign difference = operand1 - operand2;
	assign equal = difference == 0;
	assign less = difference[31];	// Difference is negative

	always @*
	begin
		case (operation)
			OP_AND:  result = operand1 & operand2;
			OP_XOR:  result = operand1 ^ operand2;
			OP_OR:   result = operand1 | operand2;
			OP_ADD:  result = operand1 + operand2;
			OP_SUB:  result = difference;
			OP_MUL:  result = operand1 * operand2;
			OP_SHL:  result = operand1 << operand2;
			OP_SHR:  result = operand1 >> operand2;
			OP_MOV:  result = operand2;
			OP_EQ:   result = equal;
			OP_NEQ:  result = !equal;
			OP_GT:   result = !equal && !less;
			OP_GTE:  result = !less;
			OP_LT:   result = less;
			OP_LTE:  result = less || equal;
			default: result = 32'dX;
		endcase
	end

	always @(posedge clk)
	begin
		if (!dest[2])
			registers[dest[2:0]] <= result;

		if (dest == REG_RESULT)
			output_value <= { result[23:20], result[15:12], result[7:4] };
	end
endmodule

