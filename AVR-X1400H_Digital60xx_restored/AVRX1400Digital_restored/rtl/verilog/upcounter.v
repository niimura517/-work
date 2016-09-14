module upcounter (
	clk_i, dat_o, clr_i
);

//
// parameters
//
parameter width = 10;

//
// I/O
//
	input clk_i;
	output reg [width-1:0] dat_o;
	input clr_i;
	
//
// Internal Wires & Registers
//

		
//
// Module Description
//
	initial begin
		dat_o <= 0;
	end

	always @ (posedge clk_i or posedge clr_i) begin
		if(clr_i)
			dat_o <= 0;
		else
			dat_o <= dat_o + 1'b1;
	end
		
endmodule
