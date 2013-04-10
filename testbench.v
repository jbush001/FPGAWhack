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
