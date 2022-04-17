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
parameter In_len  = 22;			// 2049 // 22
parameter rdn_len = Wsearch - 3;	// Redundant length for in_str
parameter Wimg    = 12;				// img_length: 2049 => 12 bits
parameter Wstate  = 3;				// state 0-4        =>  3 bits

// Constant
parameter   [Wchar-1:0]	    EndSgn = 8'h24; // Dollar sign: '$' 

// Define State
parameter 	[Wstate-1:0] 	In_S   = 0;
parameter 	[Wstate-1:0] 	Out_S0 = 1;
parameter 	[Wstate-1:0] 	Enc_S  = 2;
parameter 	[Wstate-1:0] 	Out_S  = 3;
parameter 	[Wstate-1:0] 	Fin_S  = 4;


// Output register
reg 			valid;
reg 			finish;
reg [3:0] 		offset,    ans_offset;
reg [2:0] 		match_len, ans_match_len;
reg [Wchar-1:0] char_nxt,  ans_char_nxt;

/********** Variables **********/
reg [Wstate-1:0] 	cur_S, nxt_S;
reg [Wchar-1:0]		in_str [0:In_len + rdn_len - 1]; // [In_len-1:0]
reg [Wimg-1:0] 		char_cnt, sb, sb_prob, lb; // Index: 0 - 2048

// Next State Logic
always @(*) begin
	case (cur_S)
		In_S: begin // STATE 0
			nxt_S = (char_cnt == In_len)? Out_S0 : In_S;
		end
		Out_S0: begin // STATE 1
			nxt_S = Enc_S;
		end
		Enc_S: begin // STATE 2
			nxt_S = (sb + char_cnt+1) < lb ? Enc_S : Out_S;
		end
		Out_S: begin // STATE 3
			nxt_S = Enc_S;
		end
		Fin_S: begin // STATE 4
			nxt_S = Fin_S;
		end
		default: nxt_S = In_S;
	endcase
end

// State Register
always @(posedge clk) begin
    // Initialize all register
	if(reset) begin
        cur_S <= In_S;
	end
    else
        cur_S <= nxt_S;
end

// Output Logic
always @(*) begin
	case (cur_S)
		In_S: begin // STATE 0
			offset    = 0;
			match_len = 0;
			char_nxt  = 0;
			valid     = 0;
			finish    = 0;
		end
		Out_S0: begin // STATE 1
			offset    = 0;
			match_len = 0;
			char_nxt  = in_str[0];
			valid     = 1;
			finish    = 0;
		end
		Enc_S: begin // STATE 2
			valid     = 0;//sb_prob < lb ? 0 : 1;
			offset    = 0;
			match_len = match_len;
			char_nxt  = 0;
			finish    = 0;
		end
		Out_S: begin // STATE 3
			offset    = lb - sb - char_cnt - 1;
			match_len = ans_match_len;
			char_nxt  = in_str[lb + ans_match_len];
			valid     = 1;
			finish    = 0;
		end
		Fin_S: begin // STATE 4
			offset    = 0;
			match_len = 0;
			char_nxt  = 0;
			valid     = 0;
			finish    = 1;
		end
		default: begin
			offset    = 0;
			match_len = 0;
			char_nxt  = 0;
			valid     = 0;
			finish    = 0;
		end
	endcase
end

//  Test Matching Function
parameter sb_test = 10;
parameter lb_test = 13;

// String Matching (Comb. ckt.)
wire [63:0] bundle_s, bundle_l, bundle_xor;
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
		ans_match_len = 3'd0;
	else begin
		casex(bundle_xor)
		56'h00000000000000: ans_match_len = 7;
		56'h000000000000xx: ans_match_len = 6;
		56'h0000000000xxxx: ans_match_len = 5;
		56'h00000000xxxxxx: ans_match_len = 4;
		56'h000000xxxxxxxx: ans_match_len = 3;
		56'h0000xxxxxxxxxx: ans_match_len = 2;
		56'h00xxxxxxxxxxxx: ans_match_len = 1;
		default: 			ans_match_len = 0;
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
			sb_prob <= 0;
			lb 		<= 0;
			if(reset)
				char_cnt <= 0;
			else begin
				if(char_cnt == In_len)
					char_cnt <= 0;
				else
					in_str[char_cnt] <= chardata;
					char_cnt <= char_cnt + 1;
			end
		end
		Out_S0: begin // STATE 1
			sb 		 <= 0;
			sb_prob  <= 0;
			lb 		 <= 1;
			char_cnt <= 0;
			ans_offset <= 0;
		end
		Enc_S: begin // STATE 2
			sb <= sb; // sb_test;
			lb <= lb; // lb_test;
			ans_offset <= offset;
			char_cnt <= char_cnt + (sb + char_cnt+1 < lb ? 1:0);
			// sb_prob <= sb + char_cnt; // char_cnt(old)
		end
		Out_S: begin // STATE 3
			if(lb + match_len - sb < Wsearch) // lb(old)
				sb <= 0;
			else
				sb <= sb + match_len;
			lb <= lb + match_len;
			char_cnt <= 0;
		end
		default: begin
			sb <= 0;
			lb <= 0;
			char_cnt <= 0;
		end
	endcase
end
endmodule

