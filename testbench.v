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

module testbench;
	integer i;

	reg clk;
	wire vsync;
	wire hsync;
	wire[3:0] red;
	wire[3:0] blue;
	wire[3:0] green;

	top top(
		.clk(clk),
		.vsync_o(vsync),
		.hsync_o(hsync),
		.red_o(red),
		.blue_o(blue),
		.green_o(green));
	
	initial
	begin
		$dumpfile("trace.lxt");
		$dumpvars;
	
		clk = 0;
		for (i = 0; i < 400000; i = i + 1)
			#5 clk = !clk;
	end
endmodule
