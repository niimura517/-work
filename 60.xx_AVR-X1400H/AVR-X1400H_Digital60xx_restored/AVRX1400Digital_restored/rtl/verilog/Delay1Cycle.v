module Delay1Cycle(
input inData, CLK,
output outData, test
);

reg [1:0] Q;
assign outData = Q[1];
assign test = Q[0];

always@(posedge CLK)begin
	Q[0] <= inData;
end

always@(negedge CLK)begin
	Q[1] <= Q[0];
end

endmodule
