module LEGO_Workaround(
input in_BCK,
		in_Fs,
		in_Data,
		Enable,
output BCK_out,
		 out_Fs,
		 out_Data
);

reg Data;
reg Fs;

assign BCK_out = in_BCK;
assign out_Data = Enable? Data:in_Data;
assign out_Fs = Enable? Fs:in_Fs;


always@(negedge in_BCK) begin
	Data <= in_Data;
	Fs <= in_Fs;
end

endmodule











