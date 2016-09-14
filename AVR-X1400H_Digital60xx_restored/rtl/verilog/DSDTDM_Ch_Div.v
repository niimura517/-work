module DSD_TDM_Channel_Divider(
input in_BCK,
		FrameSync,
		in_Data,
		Protect_EN,
output out_BCK,
		 out_Ch0_Data,
		 out_Ch1_Data,
		 ProtectFlag
);

parameter Ch_Width = 16;	//Bit length per Ch 
parameter Frame_Width = 2 * Ch_Width;

reg [Frame_Width-1:0] RxReg;	//Register for Receiving Data
reg [Ch_Width:0] Ch0_TxReg;	//
reg [Ch_Width:0] Ch1_TxReg;	//
assign out_Ch0_Data = Ch0_TxReg[Ch_Width];
assign out_Ch1_Data = Ch1_TxReg[Ch_Width];

reg [4:0] BitCount;	//For Count FrameWidth
wire TxBCK;
assign TxBCK = BitCount[0];
assign out_BCK = !TxBCK;
reg TxLatch;

wire FullScaleDet_L;
wire FullScaleDet_R;

assign FullScaleDet_L = Protect_EN & ((&RxReg[Frame_Width-1:Frame_Width/2]) | (~|RxReg[Frame_Width-1:Frame_Width/2]));
assign FullScaleDet_R = Protect_EN & ((&RxReg[Frame_Width/2-1:0]) | (~|RxReg[Frame_Width/2-1:0]));
assign ProtectFlag = FullScaleDet_L | FullScaleDet_R;


always@(posedge in_BCK) begin
	RxReg <= {RxReg[Frame_Width-2:0],in_Data};
	BitCount <= FrameSync? 5'b00000:BitCount + 5'b00001;
end

always@(posedge TxLatch) begin
	if(BitCount[4:1] == Ch_Width-1)begin
		Ch0_TxReg <= ProtectFlag? {Ch0_TxReg[Ch_Width-1], 16'h9696} : {Ch0_TxReg[Ch_Width-1], RxReg[Frame_Width-1:Frame_Width/2]};
		Ch1_TxReg <= ProtectFlag? {Ch0_TxReg[Ch_Width-1], 16'h9696} : {Ch1_TxReg[Ch_Width-1], RxReg[Frame_Width/2-1:0]};
	end
	else begin
		Ch0_TxReg <= {Ch0_TxReg[Ch_Width-1:0], 1'b0};
		Ch1_TxReg <= {Ch1_TxReg[Ch_Width-1:0], 1'b0};
	end
end

always@(negedge in_BCK) begin
	TxLatch <= TxBCK;
end

endmodule



