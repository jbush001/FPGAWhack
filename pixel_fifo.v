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
// The pixel FIFO receives all values in parallel and shifts them out one at a time.
// 

module pixel_fifo
	#(parameter NUM_ELEMS = 16,
	parameter ELEM_WIDTH = 16,
	parameter VALUE_IN_WIDTH = NUM_ELEMS * ELEM_WIDTH)

	(input clk,
	input reset,
	output reg almost_empty,
	output reg empty,
	input enqueue,
	input[VALUE_IN_WIDTH - 1:0] value_in,
	input dequeue,
	output[ELEM_WIDTH - 1:0] value_out);

	localparam COUNT_WIDTH = $clog2(NUM_ELEMS) + 1;

	reg[ELEM_WIDTH - 1:0] data[0:NUM_ELEMS - 1];
	reg[COUNT_WIDTH - 1:0] element_count;
	assign value_out = data[0];
	integer i;
	
	initial
	begin
		empty = 1;
		almost_empty = 1;
		element_count = 0;
		for (i = 0; i < NUM_ELEMS; i = i + 1)
			data[i] = 0;
	end
	
	always @(posedge clk, posedge reset)
	begin
		if (reset)
		begin
			element_count <= 0;
			almost_empty <= 0;
			empty <= 1;
			for (i = 0; i < NUM_ELEMS; i = i + 1)
				data[i] = 0;
		end
		else if (enqueue)
		begin
			element_count <= NUM_ELEMS;
			almost_empty <= 0;
			empty <= 0;
			for (i = 0; i < NUM_ELEMS; i = i + 1)
				data[i] <= value_in >> (i * ELEM_WIDTH);
		end
		else if (dequeue)
		begin
			if (element_count == 1)
			begin
				empty <= 1;
				almost_empty <= 0;
			end
			else if (element_count == 2)
				almost_empty <= 1;
			
			if (element_count != 0)
				element_count <= element_count - 1;

			for (i = 0; i < NUM_ELEMS - 1; i = i + 1)
				data[i] <= data[i + 1];
		end
	end
endmodule
