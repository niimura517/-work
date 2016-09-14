//-----------------------------------------------------------
// Module      : PCM Audio/Mute Clock Syncronized Exchange Unit
// Version     : 1.2
// Data        : 2014.02.21
// Author      : A.Sasaki
//-----------------------------------------------------------

module clk_sync_exchanger(
	  a_mck_i
	, a_bck_i
	, a_lrck_i
	, m_mck_i
	, m_bck_i
	, m_lrck_i
	, nrst_i
	, mute_i
	, mck_o
	, bck_o
	, lrck_o
	, nclkmute_o
	, ndatmute_o
);

//
// Parameters
//
	parameter USE_MUTE_BCK_AND_LRCK = "no";	// "yse": Need 3 mute clocks(m_mck_i, m_bck_i, m_lrck_i).
															// "no" : Use 1 mute clock(m_mck_i) only. m_bck and m_lrck make from internal Divider. m_bck_i&m_lrck_i is ignored.
															//        In this mode, output mute clock is mck=128fs. So if m_mck_i=24.576MHz, m_bck=12.288MHz, m_lrck=192kHz
	
	parameter clk_mute_delay_cnt_width = 10;	// Delay time count between Audio Data to Mute Data change time and Audio Clock to Mute Clock. 
															// Timing is counted by m_lrck. After 2^clk_mute_delay_cnt_width count, clks mute in. 
	
//
// I/O Ports
//
	input a_mck_i;				// Master Clock for play
	input a_bck_i;				// Bit Clock for play
	input a_lrck_i;			// Word Clock for play
	input m_mck_i;				// Master Clock for mute
	input m_bck_i;				// Bit Clock for mute
	input m_lrck_i;			// Word Clock for mute
	input nrst_i;				// Negative reset control
	input mute_i;				// Mute flag
	
	output mck_o;				// Selected Master Clock 
	output bck_o;				// Selected Bit Clock
	output lrck_o;				// Selected Word Clock
	output nclkmute_o;		// Clock Select Flag(0: Mute, 1: Play)
	output reg ndatmute_o;	// Data Select Flag(0: Mute, 1: Play)
	
//
// Wires, Registers and Assignment
//
	reg [6:0] m_mck_div;		// Divided mute master clock
	wire m_bck = (USE_MUTE_BCK_AND_LRCK=="yes") ? m_bck_i : m_mck_div[0];		// internal mute bit clock
	wire m_lrck = (USE_MUTE_BCK_AND_LRCK=="yes") ? m_lrck_i : m_mck_div[6];		// internal mute word clock
	reg [clk_mute_delay_cnt_width:0] d_cnt;
	wire clk_mute_flag = d_cnt[clk_mute_delay_cnt_width];			// Clock Select Flag
	wire dat_mute_flag = mute_i;											// Data Select Flag
	
//
// Components
//

	// Mute Clock Divider
	initial begin
		m_mck_div <= 0;
		clk_launch_q <= 1'b1;
		clk_latch_q <= 1'b1;
		dat_launch_q <= 1'b1;
		dat_latch_q <= 1'b1;
		ndatmute_o <= 1'b0;
		//nclkmute_o <= 1'b0;
		ndatmute_o <= 1'b0;
	end
	always @ (negedge m_mck_i or negedge nrst_i) begin
		if(!nrst_i) begin
			m_mck_div <= 0;
		end
		else if(USE_MUTE_BCK_AND_LRCK=="no") begin
			m_mck_div <= m_mck_div + 1'b1;
		end
	end
	
	// Clock mute in flag delay Block
	always @ (posedge m_lrck or negedge mute_i) begin
		if(!mute_i) begin
			d_cnt <= 0;
		end
		else if(mute_i & ~d_cnt[clk_mute_delay_cnt_width] & nrst_i) begin
			d_cnt <= d_cnt + 1'b1;
		end
	end
	
	// Clock Sync CLK Exchange Block
	reg clk_launch_q;					// Launch D-FF Output
	reg clk_latch_q;					// Latch D-FF Output
	wire clk_launch_clk = (nclkmute_o) ? a_lrck_i : m_lrck;	// Launch Clock Select
	wire clk_latch_clk = (nclkmute_o) ? m_lrck : a_lrck_i;	// Latch Clock Select
	wire mux_a_lrck = (!clk_launch_q) ? a_lrck_i : 1'b0;	// At same time changing launch_q, temporaly lrck_o(=1'b0) generate
	wire mux_m_lrck = (!clk_launch_q) ? 1'b0 : m_lrck;
	
	always @ (negedge clk_launch_clk or negedge nrst_i) begin
		if(!nrst_i) begin
			clk_launch_q <= 1'b0;
		end
		else begin
			clk_launch_q <= clk_mute_flag;
		end
	end
	always @ (negedge clk_latch_clk or negedge nrst_i) begin
		if(!nrst_i) begin
			clk_latch_q <= 1'b0;
		end
		else begin
			clk_latch_q <= clk_launch_q;
		end
	end
	assign nclkmute_o = ~clk_latch_q & nrst_i;
	assign mck_o = (nclkmute_o) ? a_mck_i : m_mck_i;
	assign bck_o = (nclkmute_o) ? a_bck_i : m_bck;
	wire mux_lrck = (nclkmute_o) ? mux_a_lrck : mux_m_lrck;
	assign lrck_o = (nclkmute_o) ? mux_lrck : m_lrck;
	
	// Clock Sync DAT Exchange Block
	wire ndatmute;
	reg dat_launch_q;					// Launch D-FF Output
	reg dat_launch_q2;					// Launch D-FF Output
	reg dat_latch_q;					// Latch D-FF Output
	wire dat_launch_clk = (ndatmute) ? a_lrck_i : m_lrck;	// Launch Clock Select
	wire dat_latch_clk = (ndatmute) ? m_lrck : a_lrck_i;	// Latch Clock Select
	
	always @ (negedge dat_launch_clk or negedge nrst_i) begin
		if(!nrst_i) begin
			dat_launch_q <= 1'b1;
		end
		else begin
			dat_launch_q <= dat_mute_flag;
		end
	end
	always @ (negedge dat_latch_clk or negedge nrst_i) begin
		if(!nrst_i) begin
			dat_latch_q <= 1'b0;
		end
		else begin
			dat_latch_q <= dat_launch_q;
		end
	end
	assign ndatmute = ~dat_latch_q & nrst_i;
	always @ (posedge a_bck_i or negedge nrst_i) begin
		if(!nrst_i) begin
			dat_launch_q2 <= 1'b0;
		end
		else begin
			dat_launch_q2 <= dat_launch_q;
		end
	end
	always @ (negedge a_bck_i or negedge nrst_i) begin
		if(!nrst_i) begin
			ndatmute_o <= 1'b0;
		end
		else begin
			ndatmute_o <= ndatmute & ~dat_launch_q2;
		end
	end
	
endmodule

	
	
	
