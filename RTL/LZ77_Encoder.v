/* Author: rubato Wun
Total logic elements:               20,091 / 68,416 ( 29 % )
    Total combinational functions:  19,992 / 68,416 ( 29 % )
    Dedicated logic registers:      16,494 / 68,416 ( 24 % )
Total registers:                    16494
Total memory bits:                  0 / 1,152,000 ( 0 % )
Embedded Multiplier 9-bit elements: 0 / 300 ( 0 % )
img0: 443,310 ns
img1: 430,290 ns
img2: 248,610 ns
*/
module LZ77_Encoder(clk,reset,chardata,valid, encode,finish,offset,match_len,char_nxt);
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
parameter [4:0] Wchar = 8;			// char  			 =>  8 bits
parameter [4:0] Search_len = 9;		// Search buffer     =>  9 chars
parameter [4:0] Look_len = 8;		// Look-ahead buffe  =>  8 chars
parameter In_len = 2049 - Look_len;	// 2049 // 22
parameter W_inlen = 12;				// img_length: 2041  => 12 bits
parameter Wstate = 3;				// state 0-4         =>  3 bits

// Constant
parameter   [Wchar-1:0]	    EndSgn = 8'h24; // Dollar sign: '$'

// Define State
parameter 	[Wstate-1:0] 	In_S0   = 0;
parameter 	[Wstate-1:0] 	In_S1   = 1;
parameter 	[Wstate-1:0] 	Enc_S   = 2;
parameter 	[Wstate-1:0] 	Out_S   = 3;
parameter 	[Wstate-1:0] 	Shift_S = 4;
parameter 	[Wstate-1:0] 	Fin_S   = 5;

// Output register
reg 			valid;
reg 			finish;
reg [3:0] 		offset,    ans_offset;
reg [2:0] 		match_len, ans_match_len, c_ml;
reg [Wchar-1:0] char_nxt;

/********** Variables **********/
reg [Wstate-1:0] 	cur_S, nxt_S, ctrl_sig;
reg [Wchar-1:0]		sl_buf [0:Search_len+Look_len-1]; // search & look-ahead buffer
reg [Wchar-1:0]		in_str [0:In_len-1]; // search & look-ahead buffer
reg [W_inlen-1:0] 	i;                   // Index: 0 - 2040
reg [4:0]           sl_ind;              // Index: 0 - 16

// Next State Logic
always @(*) begin
    case (cur_S)
        In_S0:   nxt_S = (sl_ind == (Search_len + Look_len) - 1)?        In_S1 : In_S0;
        In_S1:   nxt_S = (i == In_len)?                                  Out_S : In_S1;
        Enc_S:   nxt_S = (sl_ind == Search_len - 1)?                     Out_S : Enc_S;
        Out_S:   nxt_S = (sl_buf[Search_len + ans_match_len] == EndSgn)? Fin_S : Shift_S;
        Shift_S: nxt_S = (ans_match_len == 0)?                           Enc_S : Shift_S;
        Fin_S:   nxt_S = Fin_S;
        default: nxt_S = In_S0;
    endcase
end

// State Register
always @(posedge clk) begin
    cur_S <= reset ? In_S0 : nxt_S;
end

// Output Logic
always @(*) begin
    ctrl_sig  = cur_S;
    case (cur_S)
        Out_S: begin
            valid     = 1;
            offset    = ans_offset;
            match_len = ans_match_len;
            char_nxt  = sl_buf[Search_len + ans_match_len];
            finish    = 0;
        end
        Fin_S: begin
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

// String Matching (Comb. ckt.)
// match_len: 0-7
wire [55:0] bundle_s, bundle_l, bundle_xor;
assign bundle_s = { sl_buf[sl_ind],
                    sl_buf[sl_ind + 1],
                    sl_buf[sl_ind + 2],
                    sl_buf[sl_ind + 3],
                    sl_buf[sl_ind + 4],
                    sl_buf[sl_ind + 5],
                    sl_buf[sl_ind + 6]};
assign bundle_l = { sl_buf[9],
                    sl_buf[10],
                    sl_buf[11],
                    sl_buf[12],
                    sl_buf[13],
                    sl_buf[14],
                    sl_buf[15]};
assign bundle_xor = bundle_s ^ bundle_l;
always @(*) begin
    if (reset)
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

// Datapath: Encoding
// Quartus: Only clk signal can be triggered
integer j;
always @(posedge clk) begin
    case(ctrl_sig)
        In_S0: begin
            ans_offset     <= 0;
            ans_match_len  <= 0;
            sl_buf[sl_ind] <= chardata;
            i <= 0;
            if (reset)
                sl_ind <= Search_len;
            else
                sl_ind <= sl_ind + 5'd1;
            for(j = 0; j < Search_len; j = j + 1)
                sl_buf[j] = EndSgn;
        end
        In_S1: begin
            ans_offset    <= 0;
            ans_match_len <= 0;
            sl_ind        <= 0;
            in_str[i]     <= chardata;
            i <= i + 12'd1;
        end
        Enc_S: begin
            if(c_ml > ans_match_len) begin
                ans_offset    <= 4'd8 - sl_ind[3:0];   // Search_len - 1 - sl_ind
                ans_match_len <= c_ml;
            end
            sl_ind <= sl_ind + 5'd1;
        end
        Out_S: begin
            sl_ind <= 0;
        end
        Shift_S: begin
            for(j = 0; j < (Search_len + Look_len) - 1; j = j + 1)
                sl_buf[j] <= sl_buf[j + 1];
            sl_buf[(Search_len + Look_len) - 1] <= in_str[0];
            for(j = 0; j < In_len - 1; j = j + 1)
                in_str[j] <= in_str[j + 1];
            if(ans_match_len > 0)
                ans_match_len <= ans_match_len - 3'd1;
            else begin
                sl_ind        <= 0;
                ans_offset    <= 0;
                ans_match_len <= 0;
            end
        end
        default: begin
            sl_ind        <= 0;
            ans_offset    <= 0;
            ans_match_len <= 0;
        end
    endcase
end
endmodule
