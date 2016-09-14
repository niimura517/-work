module ADC_CLK_GEN(
input MCK_in,
input FS_96_n48,
output MCK_out, BCK_out, LRCK_out
);

reg [8:0] MCKDiv;
wire BCK, LRCK;

assign BCK_out = BCK;
assign LRCK_out = LRCK;

always@(negedge MCK_in)begin
	MCKDiv <= MCKDiv + 1'b1;
end

assign MCK_out = MCK_in;
assign BCK 		= FS_96_n48? MCKDiv[1]:MCKDiv[2];
assign LRCK 	= FS_96_n48? MCKDiv[7]:MCKDiv[8];

endmodule









