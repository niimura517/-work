module ADC_FS_Manager(
input [1:0]INFSSEL,
input AD, CLK,
output FS_96_n48
);

reg FS96;
initial FS96 = 1'b0;
assign FS_96_n48 = FS96;

wire INFs;
assign INFs = (INFSSEL == 2'b10)? 1'b1:1'b0;

always@(posedge CLK) begin
	if(AD)
		FS96 <= INFs;
end

endmodule

