/* Author: rubato Wun
===== Synthesis Result (Fail) =====
Total logic elements:               140,915 / 68,416 ( 206 % )
    Total combinational functions:  124,523 / 68,416 ( 182 % )
    Dedicated logic registers:      16,488 / 68,416 ( 24 % )
Total registers:                    16488
Total memory bits:                  0 / 1,152,000 ( 0 % )
Embedded Multiplier 9-bit elements: 0 / 300 ( 0 % )
===== Time Performance =====
img0: 381,480 ns
img1: 368,130 ns
img2: 186,900 ns
*/
module LZ77_Encoder(clk,reset,chardata,valid,encode,finish,offset,match_len,char_nxt);
input 				clk;
input 				reset;
input 		[7:0] 	chardata;
output  			valid;
output  			encode;
output  			finish;
output 		[3:0] 	offset;
output 		[2:0] 	match_len;
output 	 	[7:0] 	char_nxt;
assign encode = 1;

// Define Width
parameter Wsearch = 9;				// Search buffer	=>  9 chars
parameter Wchar   = 8;				// char  			=>  8 bits
parameter In_len  = 2049;			// 2049 // 22 // 1025
parameter rdn_len = Wsearch - 3;	// Redundant length for in_str
parameter Wimg    = 12;				// img_length: 2049 => 12 bits
parameter Wstate  = 2;				// state 0-3        =>  3 bits

// Constant
parameter   [Wchar-1:0]	    EndSgn = 8'h24; // Dollar sign: '$' 

// Define State
parameter 	[Wstate-1:0] 	In_S   = 0;
parameter 	[Wstate-1:0] 	Enc_S  = 1;
parameter 	[Wstate-1:0] 	Out_S  = 2;
parameter 	[Wstate-1:0] 	Fin_S  = 3;


// Output register
reg 			valid;
reg 			finish;
reg [3:0] 		offset,    ans_offset, c_ml;
reg [2:0] 		match_len, ans_match_len;
reg [Wchar-1:0] char_nxt;

/********** Variables **********/
reg [Wstate-1:0] 	cur_S, nxt_S;
reg [Wchar-1:0]		in_str [0:In_len + rdn_len - 1]; // [In_len-1:0]
reg [Wimg-1:0] 		char_cnt, ans_char_cnt, sb, lb; // Index: 0 - 2048

// Next State Logic
always @(*) begin
	case (cur_S)
		In_S: 	// STATE 0
			nxt_S = (char_cnt == In_len)? Out_S : In_S;
		Enc_S: 	// STATE 2
			nxt_S = (sb + char_cnt+1) < lb ? Enc_S : Out_S;
		Out_S: 	// STATE 3
			nxt_S = in_str[lb + ans_match_len] == EndSgn ? Fin_S : Enc_S;
		Fin_S: 	// STATE 4
			nxt_S = Fin_S;
		default: nxt_S = In_S;
	endcase
end

// State Register
always @(posedge clk) begin
	cur_S <= reset ? In_S : nxt_S;
end

// Output Logic
always @(*) begin
	case (cur_S)
		In_S: begin // STATE 0
			valid     = 0;
			offset    = 0;
			match_len = 0;
			char_nxt  = 0;
			finish    = 0;
		end
		Enc_S: begin // STATE 1
			valid     = 0;
			offset    = 0;
			match_len = 0;
			char_nxt  = 0;
			finish    = 0;
		end
		Out_S: begin // STATE 2
			valid     = 1;
			offset    = ans_offset;
			match_len = ans_match_len;
			char_nxt  = in_str[lb + ans_match_len];
			finish    = 0;
		end
		Fin_S: begin // STATE 3
			valid     = 0;
			offset    = 0;
			match_len = 0;
			char_nxt  = 0;
			finish    = 1;
		end
		default: begin
			valid     = 0;
			offset    = 0;
			match_len = 0;
			char_nxt  = 0;
			finish    = 0;
		end
	endcase
end

//  Test Matching Function
parameter sb_test = 10;
parameter lb_test = 13;

// String Matching (Comb. ckt.)
wire [55:0] bundle_s, bundle_l, bundle_xor;
assign bundle_s = {	in_str[sb + char_cnt],
					in_str[sb + char_cnt + 1],
					in_str[sb + char_cnt + 2],
					in_str[sb + char_cnt + 3],
					in_str[sb + char_cnt + 4],
					in_str[sb + char_cnt + 5],
					in_str[sb + char_cnt + 6]};
assign bundle_l = {	in_str[lb],
					in_str[lb+1],
					in_str[lb+2],
					in_str[lb+3],
					in_str[lb+4],
					in_str[lb+5],
					in_str[lb+6]};
assign bundle_xor = bundle_s ^ bundle_l;
always @(*) begin
	if(reset)
		c_ml = 3'd0;
	else begin
		casex(bundle_xor)
		56'h00000000000000: c_ml = 7;
		56'h000000000000xx: c_ml = 6;
		56'h0000000000xxxx: c_ml = 5;
		56'h00000000xxxxxx: c_ml = 4;
		56'h000000xxxxxxxx: c_ml = 3;
		56'h0000xxxxxxxxxx: c_ml = 2;
		56'h00xxxxxxxxxxxx: c_ml = 1;
		default: 			c_ml = 0;
		endcase
	end
end

// Counter & Encoding
integer i;
// Quartus: Only clk signal can be triggered
always @(posedge clk/* or cur_S*/) begin
	for (i = In_len; i < In_len + rdn_len; i=i+1)
		in_str[i] <= 0; // Initialize redundant reg
	case(cur_S)
		In_S: begin // STATE 0
			sb 		<= 0;
			lb 		<= 0;
			ans_offset <= 0;
			ans_match_len <= 0;
			if(reset)
				char_cnt <= 0;
			else begin
				if(char_cnt == In_len)
					char_cnt <= 0;
				else
					in_str[char_cnt] <= chardata;
					char_cnt <= char_cnt + 12'd1;
			end
		end
		Enc_S: begin // STATE 2
			sb <= sb; // sb_test;
			lb <= lb; // lb_test;
			char_cnt <= 
				char_cnt + (sb + char_cnt + 12'd1 < lb ? 12'd1:12'd0);
			if(c_ml > ans_match_len) begin
				ans_offset <= lb - sb - char_cnt - 12'd1;
				ans_match_len <= c_ml;
			end
		end
		Out_S: begin // STATE 3
			if(lb + ans_match_len - sb < Wsearch)
				sb <= 0;
			else
				sb <= (lb + ans_match_len + 12'd1) - Wsearch;
			lb <= lb + ans_match_len + 12'd1;
			char_cnt <= 0;
			ans_offset <= 0;
			ans_match_len <= 0;
		end
		default: begin
			sb <= 0;
			lb <= 0;
			char_cnt <= 0;
			ans_offset <= 0;
			ans_match_len <= 0;
		end
	endcase
end
endmodule