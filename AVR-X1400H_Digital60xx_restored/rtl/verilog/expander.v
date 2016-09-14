module expander (
	  dat_i
	, dat_o
	, clk_i
	, ncs_i
);

//
// parameters
//
	parameter width = 48;

//
// I/O
//
	input dat_i;
	output reg [width-1:0] dat_o;
	input clk_i;
	input ncs_i;
	
//
// Internal Wires & Registers
//
	reg [width-1:0] r;
	
//
// Module Description
//
	always @ (posedge clk_i) begin
		if(!ncs_i) begin
			r <= {r[width-2:0], dat_i};
		end
	end
	
	always @ (posedge ncs_i)
		dat_o <= r;
		
endmodule
	