module lpm_and_wrapper (
	result, data
);

//
// Parameters
//
	parameter width = 1;
	parameter size = 1;

//
// I/O
//
	input [(size*width)-1:0] data;
	output [width-1:0] result;
	
//
// Modules
//
	lpm_and #(
		  .lpm_width(width)
		, .lpm_size(size)
	) lpm_and (
		  .data(data)
		, .result(result)
	);
	
endmodule
