
//
// Contains register file and ALU to compute value for a single pixel
//

module pixel_alu(
	input				clk,
	input[48:0]			instruction,
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

	localparam REG_X = 4'd8;
	localparam REG_Y = 4'd9;
	localparam REG_F = 4'd10;
	localparam REG_RESULT = 4'd11;

	reg[31:0] registers[0:7];

	wire[3:0] dest = instruction[48:45];
	wire[3:0] srca = instruction[44:41];
	wire[3:0] srcb = instruction[40:37];
	wire[3:0] operation = instruction[36:33];
	wire use_const = instruction[32];
	wire[31:0] const_val = instruction[31:0];
	reg[31:0] operand1;
	reg[31:0] operand2;
	reg[31:0] result;
	integer i;

	initial
	begin
		output_value = 0;
		for (i = 0; i < 8; i = i + 1)
			registers[i] = 0;
	end

	always @*
	begin
		casez (srca)
			4'b0???: operand1 = registers[srca[2:0]];
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
				4'b0???: operand2 = registers[srcb[2:0]];
				REG_X:   operand2 = x_coord;
				REG_Y:   operand2 = y_coord;
				REG_F:   operand2 = f_number;
				default: operand2 = 32'dX;
			endcase
		end
	end

	always @*
	begin
		case (operation)
			OP_AND:  result = operand1 & operand2;
			OP_XOR:  result = operand1 ^ operand2;
			OP_OR:   result = operand1 | operand2;
			OP_ADD:  result = operand1 + operand2;
			OP_SUB:  result = operand1 - operand2;
			OP_MUL:  result = operand1 * operand2;
			OP_SHL:  result = operand1 << operand2;
			OP_SHR:  result = operand1 >> operand2;
			OP_MOV:  result = operand2;
			default: result = 32'dX;
		endcase
	end

	always @(posedge clk)
	begin
		registers[dest] <= result;
		if (dest == REG_RESULT)
			output_value <= { result[23:20], result[15:12], result[7:4] };
	end
endmodule

