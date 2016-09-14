`timescale 1ps/1ps

module timing_aligner(
	  clk_i
	, dat_i
	, dat_o
	, clr_i
);

//
// Parameters
//
	parameter launchedge = 0;		//Launch Edge selector: negedge(0)/posedge(1)
	parameter latchedge  = 1;		//Latch Edge selector : negedge(0)/posedge(1)
	parameter width = 1;				//Data width: dat_i[width-1:0], dat_o[width-1:0]

//
// I/O Ports
//
	input clk_i;
	input [width-1:0] dat_i;
	output reg [width-1:0] dat_o;
	input clr_i;
	
//
// Internal Wires&Registers
//
	reg [width-1:0] q;
	wire launchclk;
	wire latchclk;

//
// Wire Assign
//	
		assign launchclk = (launchedge) ? clk_i : ~clk_i;
		assign latchclk = (latchedge) ? clk_i : ~clk_i;
		
//
// D-FF
//
	always @ (posedge launchclk or posedge clr_i) begin
		if(clr_i) begin
			q <= 1'b0;
		end
		else begin
			q <= dat_i;
		end
	end
	
	always @ (posedge latchclk or posedge clr_i) begin
		if(clr_i) begin
			dat_o <= 1'b0;
		end
		else begin
			dat_o <= q;
		end
	end
	
endmodule
