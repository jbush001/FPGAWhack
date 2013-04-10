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

module top(
	input clk,
	output vsync_o,
	output hsync_o,
	output [3:0] red_o,
	output [3:0] blue_o,
	output [3:0] green_o);

	wire in_visible_region;
	wire pixel_out;
	wire new_frame;
	wire fifo_almost_empty;
	wire fifo_empty;
	wire[95:0] fifo_in;
	wire[11:0] fifo_out;
	wire pixels_ready;
	wire start_next_batch = pixels_ready && (fifo_almost_empty || fifo_empty)
		&& pixel_out;

	vga_timing_generator vga_timing_generator(
		.clk(clk),
		.vsync_o(vsync_o),
		.hsync_o(hsync_o),
		.in_visible_region(in_visible_region),
		.pixel_out(pixel_out),
		.new_frame(new_frame));

	pixel_fifo #(8, 12) pixel_fifo(
		.clk(clk),
		.reset(new_frame),
		.almost_empty(fifo_almost_empty),
		.empty(fifo_empty),
		.enqueue(start_next_batch),
		.value_in(fifo_in),	
		.dequeue(pixel_out),
		.value_out(fifo_out));

	pixel_processor pixel_processor(
		.clk(clk),
		.new_frame(new_frame),
		.result(fifo_in),
		.start_next_batch(start_next_batch),
		.result_ready(pixels_ready));

	assign red_o = in_visible_region ? fifo_out[11	:8] : 0;	// 15-11
	assign blue_o = in_visible_region ? fifo_out[7:4] : 0;	// 10-5
	assign green_o = in_visible_region ? fifo_out[3:0] : 0; // 4-0

endmodule
