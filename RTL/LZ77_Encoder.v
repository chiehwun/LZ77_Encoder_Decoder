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

// Define bit width
parameter Wchar   = 8;	// char  			=>  8 bits
parameter In_len  = 22;	// 2049
parameter rdn_len = 6;  // Redundant length for in_str
parameter Wimg    = 12;	// img_length: 2049 => 12 bits
parameter Wstate  = 3;	// state num        =>  3 bits

// State Definition
parameter 	[Wstate-1:0] 	In_S   = 0;
parameter 	[Wstate-1:0] 	Enc_S0 = 1;
parameter 	[Wstate-1:0] 	Enc_S  = 2;
parameter 	[Wstate-1:0] 	Out_S  = 3;

// Constant
parameter   [Wchar-1:0]	    EndSgn = 8'h24; // Dollar sign: '$' 

// Output register
reg 					valid;
reg 					finish;
reg 		[3:0] 		offset;
reg 		[2:0] 		match_len, temp_match_len;
reg 	 	[Wchar-1:0] char_nxt;

/********** Variables **********/
reg    	  	[Wstate-1:0] 	cur_S, nxt_S;
reg       	[Wchar-1:0] 	in_str [0:In_len + rdn_len - 1]; // [In_len-1:0]
// Index
reg       	[Wimg-1:0] 	char_cnt, sb, lb; // 0 ~ 2048

// Next State Logic
always @(*) begin
	case (cur_S)
		In_S: begin
			if(char_cnt == In_len - 1)
				nxt_S = Enc_S0;
			else
				nxt_S = In_S;
		end
		Enc_S0: begin
			nxt_S = Out_S;
		end
		Enc_S: begin
			nxt_S = Out_S;
		end
		Out_S:   begin
			if(valid)
				nxt_S = Enc_S;
			else
				nxt_S = Out_S;
		end
		default: nxt_S = In_S;
	endcase
end

// State Register
always @(posedge clk) begin
    // Initialize all register
	if(reset) begin
        cur_S     	<= In_S;
		valid     	<= 0;
		finish    	<= 0;
		offset    	<= 4'd0;
		char_nxt  	<= 8'd0;
	end
    else
        cur_S <= nxt_S;
end

// Output Logic
// always @(*) begin
//     case(cur_S)
//         In_S:     offset = 0;
// 		Out_S:    offset = 0;
//         default:  offset = 0;
//     endcase
// end

//  Test Matching Function
parameter sb_test = 10;
parameter lb_test = 13;

// String Matching (Comb. ckt.)
wire [63:0] bundle_s, bundle_l, bundle_xor;
assign bundle_s = {in_str[sb], in_str[sb+1], in_str[sb+2], in_str[sb+3], in_str[sb+4], in_str[sb+5], in_str[sb+6]};
assign bundle_l = {in_str[lb], in_str[lb+1], in_str[lb+2], in_str[lb+3], in_str[lb+4], in_str[lb+5], in_str[lb+6]};
assign bundle_xor = bundle_s ^ bundle_l;
always @(*) begin
	if(reset)
		temp_match_len = 3'd0;
	else begin
		casex(bundle_xor)
		56'h00000000000000: temp_match_len = 7;
		56'h000000000000xx: temp_match_len = 6;
		56'h0000000000xxxx: temp_match_len = 5;
		56'h00000000xxxxxx: temp_match_len = 4;
		56'h000000xxxxxxxx: temp_match_len = 3;
		56'h0000xxxxxxxxxx: temp_match_len = 2;
		56'h00xxxxxxxxxxxx: temp_match_len = 1;
		default: temp_match_len = 0;
		endcase
	end
end
	
// Counter
integer i;
always @(posedge clk) begin
	case(cur_S)
		In_S: begin
			if(reset) begin
				char_cnt <= 13'd0;
				for (i = In_len; i <= In_len + rdn_len; i=i+1)
    				in_str[i] <= 0; // Initialize redundant reg
				sb <= 0;
				lb <= 0;
			end
			else begin
				in_str[char_cnt] <= chardata;
				if(char_cnt > In_len)
					char_cnt = 0;
				else
					char_cnt <= char_cnt + 1;
				sb <= 0;
				lb <= 0;
			end
		end
		Enc_S0: begin


		end
		Enc_S: begin

			sb <= sb_test;
			lb <= lb_test;
		end
		Out_S: begin
			sb <= 0;
			lb <= 0;
			char_cnt <= 0;
		end
		default: begin
			sb <= 0;
			lb <= 0;
			char_cnt <= 0;
		end
	endcase
end
/*
for (s = search_beg; s == look_beg; --s)
{
	for (l = look_beg; l == look_beg - 9; --l)
	{

	}
}
 */
endmodule

